"use strict";

// The stricter check for an agency's own name and about text (TAQ-198, 201, 207, 208, 209, 210).
// It runs the request filter (request_text_filter.js), then the agency checks below on a
// normalised copy. firestore.rules (agencyTextFree) runs the same agency checks for direct
// Agencies/{id} writes. The lists are exported as RULES_FRAGMENTS and
// test/agency_text_filter.test.js checks that firestore.rules holds them verbatim.
//
// Normalisation (both sides): lower case; Latin accents removed (zeró, ć); invisible characters
// removed (zero-width, soft hyphen, combining grapheme joiner, variation selectors); Unicode full
// stops (。 ． ｡ ﹒ ․) to '.'; a middle dot, bullet, Arabic decimal separator or Urdu full stop
// between two letters or digits to '.' (x·com, x٫com); أ/إ/آ/ٱ to ا and ى to ي; harakat and tatweel
// removed; "[.]", "(.)", "[dot]", "(dot)" to '.'.
//
// Phone: every run that is not letters, digits or marks is a separator. Each token becomes a
// marker: a number word '#' (English incl. tens, 'o', 'double'; French; Spanish; Hindi; Urdu;
// Arabic incl. tens, with an optional و/ف prefix), a single digit '%', a connector (and/et/y/و)
// '&'. A connector counts only next to a number word. Seven markers in a row is a phone. Digit
// groups of two or more digits never count ("Open 24/7 365, one-stop shop" passes).
//
// Domain:
//   - a word, a dot glued to it (or spaced before it), then two letters of a Latin, Cyrillic,
//     Greek or Armenian script, math or enclosed letters (x.shop, x.соm, x.cօm, x.ⓒⓞⓜ), an Arabic
//     ending (x.مصر), or a known ending spelled with spaces (x.c om, x . c o m);
//   - a dot followed by a space, or a spaced middle dot/bullet, before an ending that is not also
//     an everyday word (x. com, x · com; not "Dubai. In 2005" or "Since 2005. Info");
//   - "dot", "نقطة" or "دوت" between a word and an ending, with spaces, - or _ or glued
//     (x dot com, x-dot-com, xdotcom, x نقطة كوم); "www" as a word (www.x, www x com).
//   Exempt (TAQ-208/210): a known abbreviation (P.O, Dr, Eng, Sh, Mr, Mrs, Ms, Co, Inc, Ltd, No,
//   Jr, Sr; not St) before a dot when three or more letters follow and they are not a known
//   ending (Dr.Ahmed, Co.LLC, P.O.Box, Eng.Ahmed, Sh.Zayed pass; dr.tv, co.za, ltd.realty,
//   Dr.com do not); and a place name that is not a TLD after the dot (Cairo.Egypt). St.Regis
//   stays refused.

const { contactKind, foldForContactMatching } = require("./contact_filter");
const { containsContactInRequestText, hasSpelledOutNumber } = require("./request_text_filter");

// Number words, lower case and already normalised.
const NUMBER_WORDS = [
  "zero", "oh", "o", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
  "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
  "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety", "hundred", "double", "triple",
  "un", "une", "deux", "trois", "quatre", "cinq", "sept", "huit", "neuf", "dix", "onze", "douze",
  "cero", "uno", "una", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez",
  "शून्य", "जीरो", "एक", "दो", "तीन", "चार", "पांच", "पाँच", "छह", "छः", "छे", "सात", "आठ", "नौ",
  "ایک", "دو", "تین", "چار", "پانچ", "چھ", "سات", "اٹھ", "نو",
];
// Arabic number words; each also matches with a و or ف prefix.
const ARABIC_NUMBER_WORDS = [
  "صفر", "زيرو", "واحد", "واحده", "واحدة", "اثنين", "اتنين", "اثنان", "ثلاثه", "ثلاثة", "ثلاث", "تلاته", "تلاتة", "تلات", "تلاث",
  "اربعه", "اربعة", "اربع", "خمسه", "خمسة", "خمس", "سته", "ستة", "ست", "سبعه", "سبعة", "سبع",
  "ثمانيه", "ثمانية", "ثماني", "ثمان", "تمانيه", "تمانية", "تماني", "تمان", "تمنيه", "تمنية", "تسعه", "تسعة", "تسع",
  "عشره", "عشرة", "عشر", "عشرين", "عشرون", "ثلاثين", "ثلاثون", "تلاتين", "اربعين", "اربعون", "خمسين", "خمسون",
  "ستين", "ستون", "سبعين", "سبعون", "ثمانين", "ثمانون", "تمانين", "تسعين", "تسعون",
  "اثنا", "اثني", "حداشر", "احداشر", "اتناشر", "اطناشر", "تلتاشر", "تلطاشر", "اربعتاشر", "اربعطاشر", "خمستاشر",
  "خمسطاشر", "ستاشر", "سطاشر", "سبعتاشر", "سبعطاشر", "تمنتاشر", "تمانتاشر", "تمنطاشر", "تسعتاشر", "تسعطاشر",
];
const NUMBER_WORD_PATTERN = `(?:${NUMBER_WORDS.join("|")}|[وف]?(?:${ARABIC_NUMBER_WORDS.join("|")}))`;
// Teens and tens stand for two digits ("صفر خمسة صفر حداشر اتناشر تلتاشر" is 050111213), so they
// count twice; they are also in the lists above.
const TWO_DIGIT_WORD_PATTERN = "(?:ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|dix|onze|douze|diez"
  + "|[وف]?(?:عشره|عشرة|عشر|عشرين|عشرون|ثلاثين|ثلاثون|تلاتين|اربعين|اربعون|خمسين|خمسون|ستين|ستون|سبعين|سبعون|ثمانين|ثمانون|تمانين|تسعين|تسعون"
  + "|حداشر|احداشر|اتناشر|اطناشر|تلتاشر|تلطاشر|اربعتاشر|اربعطاشر|خمستاشر|خمسطاشر|ستاشر|سطاشر|سبعتاشر|سبعطاشر|تمنتاشر|تمانتاشر|تمنطاشر|تسعتاشر|تسعطاشر))";
const GLUED_PATTERN = "(?:zero|oh|one|two|three|four|five|six|seven|eight|nine){7,}";
const CONNECTOR_PATTERN = "(?:and|et|y|و)";

const spaced = (list) => `(?:${list.map((t) => t.split("").join(" ?")).join("|")})`;
const TLDS = ["com", "net", "org", "info", "biz", "co", "io", "me", "ae", "eg", "app", "online", "site", "xyz",
  "ly", "gl", "us", "uk", "in", "sa", "qa", "kw", "edu", "gov", "shop", "store"];
// A known ending, each letter optionally followed by one space ("c om", "c o m").
const SPACED_TLD_PATTERN = spaced(TLDS);
// Endings that are not also everyday words, for the forms that look like a sentence ("x. com",
// "x · com", "x point com"). uk, edu and gov start real sentences ("Dubai. UK investors"), so they
// count there only in lower case (LOWER_CASE_TLD_PATTERN, checked on the original case).
const STRICT_TLD_PATTERN = spaced(["com", "org", "biz", "io", "xyz", "ae", "eg", "sa", "qa", "kw", "ly"]);
const LOWER_CASE_TLD_PATTERN = "(?:uk|edu|gov)";
// Endings a comma glued between two words turns into a domain ("x,com").
const COMMA_TLD_PATTERN = "(?:com|org|biz|xyz)";
// Endings refused after an abbreviation even with three or more letters ("ltd.realty", "Dr.com").
const ABBREVIATION_TLD_PATTERN = `(?:${SPACED_TLD_PATTERN.slice(3, -1)}|realty|website|estate|properties|property|rentals|agency|club|tech|pro|top|world|live)`;
// Endings that are also words in a company name (Co.LLC, Jr.Homes, Co.Ltd): refused after an
// abbreviation only when written in lower case, as a typed domain is (co.llc, dr.homes, eng.dev).
const ABBREVIATION_WORD_TLD_PATTERN = "(?:homes|house|apartments|villas|land|immo|city|group|global|dev|cloud|space|ltd|llc|inc|company|realestate)";
const ARABIC_TLD_PATTERN = "(?:مصر|امارات|الامارات|السعوديه|السعودية|سعودي|قطر|الاردن|عمان|البحرين|الكويت|المغرب|الجزائر|تونس|فلسطين|سوريه|سورية|شبكه|شبكة|موقع|كوم|عرب)";
const SPOKEN_ARABIC_TLD_PATTERN = "(?:كوم|نت|اورج)";
const DOT_WORD_PATTERN = "(?:dot|d0t|نقطة|نقطه|دوت)";
// "point" and "punto" are everyday words, so only before an ending that is not ("x point com").
const POINT_WORD_PATTERN = "(?:point|punto)";
const ABBREVIATION_PATTERN = "(?:p[.] ?o|dr|eng|sh|mrs|mr|ms|co|inc|ltd|no|jr|sr)";
// Place names after a dot that are not TLDs, so "Cairo.Egypt" is an address, not a domain.
const PLACE_PATTERN = "(?:egypt|cairo|giza|alexandria|uae|sharjah|ajman|fujairah)";

const SPACE = "[\\s\\u00a0\\u2000-\\u200a\\u202f\\u3000]";
// Code points shared with the rules: characters removed before matching (combining marks,
// invisibles, harakat, tatweel), dots used in place of '.', and letter-like symbols (math
// alphanumerics; parenthesized, circled and squared letters) the rules can't fold to Latin.
const INVISIBLES = [[0x300, 0x36f], 0xad, 0x180e, [0x200b, 0x200f], [0x2060, 0x2064], [0xfe00, 0xfe0f], 0xfeff,
  [0x64b, 0x65f], 0x670, 0x640];
const UNICODE_FULL_STOPS = [0x3002, 0xff61, 0xfe52, 0xff0e, 0x2024];
const ALT_DOTS = [0xb7, 0x2022, 0x2219, 0x22c5, 0x2027, 0x66b, 0x6d4, 0x30fb, 0xff65,
  0x2e31, 0xa78f, 0x25cf, 0x25e6, 0x2d9, 0x318d, 0x1427, 0xb0];
const ENCLOSED_LETTERS = [[0x249c, 0x24e9], [0x1f130, 0x1f189]];
const LETTER_SYMBOLS = [[0x1d400, 0x1d7ff], ...ENCLOSED_LETTERS];
const hex = (c) => c.toString(16);
const jsClass = (items) => items.map((i) => (Array.isArray(i) ? `\\u{${hex(i[0])}}-\\u{${hex(i[1])}}` : `\\u{${hex(i)}}`)).join("");
// As written inside a firestore.rules string literal ('\\x{b7}').
const rulesClass = (items) => items.map((i) => (Array.isArray(i) ? `\\\\x{${hex(i[0])}}-\\\\x{${hex(i[1])}}` : `\\\\x{${hex(i)}}`)).join("");
const ALT_DOT = `[${jsClass(ALT_DOTS)}]`;
const LETTERLIKE = `[\\p{Script=Latin}\\p{Script=Cyrillic}\\p{Script=Greek}\\p{Script=Armenian}\\p{Script=Coptic}\\p{Script=Cherokee}\\p{Script=Lisu}${jsClass(LETTER_SYMBOLS)}]`;
const LABEL = `[\\p{L}\\p{N}${jsClass(ENCLOSED_LETTERS)}-]`;
const re = (source) => new RegExp(source, "u");
const reAll = (source) => new RegExp(source, "gu");

const INVISIBLE = reAll(`[${jsClass(INVISIBLES)}]`);
const FULL_STOP = reAll(`[${jsClass(UNICODE_FULL_STOPS)}]`);
// A middle dot, bullet or similar glued between two words is a dot only before an ending that is
// not a word ("x·com"); otherwise it separates words ("Buy·Sell·Rent", "Delta·Info", "London·UK").
const GLUED_ALT_DOT = reAll(`([\\p{L}\\p{N}])${ALT_DOT}(${STRICT_TLD_PATTERN}(?:[^\\p{L}]|$))`);
// Before NFKC, which would turn some of these into other characters (˙ -> space, ⒞ -> "(c)"):
// every dot-like character to U+00B7, parenthesized letters to plain ones.
const ANY_ALT_DOT = reAll(ALT_DOT);
const PARENTHESIZED = /[\u249c-\u24b5]/gu;
const GLUED_COMMA = reAll(`([\\p{L}\\p{N}]),(${COMMA_TLD_PATTERN}(?:[^\\p{L}]|$))`);

/** The text with invisibles removed and Unicode full stops as '.', case kept (rules: c). */
function casedAgencyText(text) {
  return String(text).replace(INVISIBLE, "").replace(FULL_STOP, ".");
}

/** Lower case, accents and invisibles removed, dots and Arabic letter variants unified. */
function normaliseAgencyText(text) {
  const plain = String(text).replace(ANY_ALT_DOT, "\u00b7")
    .replace(PARENTHESIZED, (c) => String.fromCharCode(0x61 + c.charCodeAt(0) - 0x249c))
    .normalize("NFKD").replace(/[\u0300-\u036f]/gu, "")
    .normalize("NFKC")
    .replace(INVISIBLE, "");
  return foldForContactMatching(plain).folded
    .toLowerCase()
    .replace(/ø/gu, "o")
    .replace(/ı/gu, "i")
    .replace(FULL_STOP, ".")
    .replace(GLUED_ALT_DOT, "$1.$2")
    .replace(GLUED_COMMA, "$1.$2")
    .replace(/[أإآٱ]/gu, "ا")
    .replace(/ى/gu, "ي")
    .replace(reAll(`[\\[({]${SPACE}*(?:[.]|dot)${SPACE}*[\\])}]`), ".");
}

/** The marker string the phone check reads: '#' number word, '%' single digit, '&' connector. */
function numberMarkers(normal) {
  return `  ${normal.replace(reAll(`[\\u20e3${jsClass(ALT_DOTS)}]`), " ").replace(/[^\p{L}\p{N}\p{M}]+/gu, "  ")}  `
    .replace(reAll(` ${TWO_DIGIT_WORD_PATTERN} `), " ## ")
    .replace(reAll(` ${NUMBER_WORD_PATTERN} `), " # ")
    .replace(/ \p{Nd} /gu, " % ")
    .replace(reAll(` ${CONNECTOR_PATTERN} `), " & ")
    .replace(/\s+/gu, "")
    .replace(/#&/g, "#")
    .replace(/&#/g, "#");
}

const NUMBER_RUN = /[#%]{7}/;
const GLUED = re(GLUED_PATTERN);

const END = "(?![\\p{L}])";
const DOT_FORM = "(?:[.]| +[.] ?)";
const DOMAIN = re(`${LABEL}${DOT_FORM}(?:${LETTERLIKE}{2}|${ARABIC_TLD_PATTERN}|${SPACED_TLD_PATTERN}${END})`);
const SPACE_AFTER_DOT = re(`[\\p{L}\\p{N}](?:[.] +| *${ALT_DOT} *)${STRICT_TLD_PATTERN}${END}`);
const WORD_DOT = re(`[\\p{L}\\p{N}][ _-]*${DOT_WORD_PATTERN}[ _-]*(?:${SPACED_TLD_PATTERN}|${SPOKEN_ARABIC_TLD_PATTERN})${END}`);
const POINT_WORD = re(`[\\p{L}\\p{N}][ _-]*${POINT_WORD_PATTERN}[ _-]*${STRICT_TLD_PATTERN}${END}`);
// On the original case (casedAgencyText):
const LOWER_CASE_SPACE_AFTER_DOT = re(`[\\p{L}\\p{N}](?:[.] +| *${ALT_DOT} *)${LOWER_CASE_TLD_PATTERN}${END}`);
// With the i flag for the abbreviation; the ending must then be lower case (rules: (?i:abbr)[.]ending).
const ABBREVIATION_WORD_DOMAIN = new RegExp(`[^\\p{L}\\p{N}]${ABBREVIATION_PATTERN}[.](${ABBREVIATION_WORD_TLD_PATTERN})${END}`, "giu");
// Letters typed for digits next to a digit ("O5O l234567"): O -> 0, l and I -> 1, then the phone
// check runs again. A letter after a digit becomes " 0"/" 1" (rules can't write "$1" then a digit).
const LETTER_DIGITS = [[/[oO](\p{Nd})/gu, "0$1"], [/[lI](\p{Nd})/gu, "1$1"], [/(\p{Nd})[oO]/gu, "$1 0"], [/(\p{Nd})[lI]/gu, "$1 1"]];

function lettersAsDigits(text) {
  return LETTER_DIGITS.reduce((out, [pattern, sub]) => out.replace(pattern, sub), text);
}

/** The domain-like fragment in the original case, or "" (lower-case-only endings). */
function casedDomainIn(cased) {
  const m = cased.match(LOWER_CASE_SPACE_AFTER_DOT);
  if (m) return wordAround(cased, m.index, m[0].length).toLowerCase();
  for (const a of ` ${cased}`.matchAll(ABBREVIATION_WORD_DOMAIN)) {
    if (a[1] === a[1].toLowerCase()) return wordAround(` ${cased}`, a.index, a[0].length).toLowerCase();
  }
  return "";
}
const WWW = /(?:^|[^\p{L}\p{N}])www(?:[^\p{L}\p{N}]|$)/u;
const ABBREVIATION = reAll(`([^\\p{L}\\p{N}])${ABBREVIATION_PATTERN}[.](\\p{L}{3})`);
const PLACE = reAll(`[.](${PLACE_PATTERN})(?=[^\\p{L}\\p{N}.-]|$)`);
const ABBREVIATION_DOMAIN = re(`[^\\p{L}\\p{N}]${ABBREVIATION_PATTERN}${DOT_FORM}${ABBREVIATION_TLD_PATTERN}${END}`);

/** The domain-like fragment of normalised text, or "". */
function domainIn(normal) {
  const text = ` ${normal.replace(reAll(`${SPACE}+`), " ")}`;
  const exempted = text.replace(ABBREVIATION, "$1  $2").replace(PLACE, " $1");
  for (const pattern of [DOMAIN, SPACE_AFTER_DOT, WORD_DOT, POINT_WORD, WWW]) {
    const m = exempted.match(pattern);
    if (m) return wordAround(exempted, m.index, m[0].length);
  }
  const m = text.match(ABBREVIATION_DOMAIN);
  return m ? wordAround(text, m.index, m[0].length) : "";
}

// The match widened to the words it touches, for the error message: "t.re" -> "st.regis".
function wordAround(text, start, length) {
  let from = start;
  let to = start + length;
  while (from < to && !/[\p{L}\p{N}]/u.test(text[from])) from += 1;
  while (from > 0 && /[\p{L}\p{N}-]/u.test(text[from - 1])) from -= 1;
  while (to < text.length && /[\p{L}\p{N}\p{M}]/u.test(text[to])) to += 1;
  return text.slice(from, to).trim();
}

/**
 * What an agency name or about text is refused for, or null when it is clean:
 * { kind: "phone" | "link" | "email" | "contact", match }. match is the website-like fragment for
 * "link" when the agency check found it; "contact" is a loose email or link the request filter
 * found.
 */
function agencyTextFinding(text) {
  if (typeof text !== "string" || !text) return null;
  const normal = normaliseAgencyText(text);
  const kind = contactKind(text) || contactKind(normal);
  const digits = lettersAsDigits(text);
  if (kind === "phone" || NUMBER_RUN.test(numberMarkers(normal)) || GLUED.test(normal) || hasSpelledOutNumber(text)
    || (digits !== text && contactKind(digits) === "phone")) {
    return { kind: "phone", match: "" };
  }
  if (kind === "email") return { kind: "email", match: "" };
  const domain = domainIn(normal) || casedDomainIn(casedAgencyText(text));
  if (domain) return { kind: "link", match: domain };
  if (kind === "link") return { kind: "link", match: "" };
  if (containsContactInRequestText(text) || containsContactInRequestText(normal)) return { kind: "contact", match: "" };
  return null;
}

/** True when an agency name or about text holds a phone, link, email or domain in any form we know. */
function containsContactInAgencyText(text) {
  return agencyTextFinding(text) !== null;
}

module.exports = {
  containsContactInAgencyText,
  agencyTextFinding,
  normaliseAgencyText,
  numberMarkers,
  RULES_FRAGMENTS: {
    NUMBER_WORD_PATTERN, TWO_DIGIT_WORD_PATTERN, GLUED_PATTERN, CONNECTOR_PATTERN, SPACED_TLD_PATTERN, STRICT_TLD_PATTERN,
    LOWER_CASE_TLD_PATTERN, COMMA_TLD_PATTERN, ABBREVIATION_TLD_PATTERN,
    ABBREVIATION_WORD_TLD_PATTERN, ARABIC_TLD_PATTERN, SPOKEN_ARABIC_TLD_PATTERN, DOT_WORD_PATTERN,
    POINT_WORD_PATTERN, ABBREVIATION_PATTERN, PLACE_PATTERN,
    INVISIBLES_RULES: rulesClass(INVISIBLES), FULL_STOPS_RULES: rulesClass(UNICODE_FULL_STOPS),
    ALT_DOTS_RULES: rulesClass(ALT_DOTS), LETTER_SYMBOLS_RULES: rulesClass(LETTER_SYMBOLS),
    ENCLOSED_LETTERS_RULES: rulesClass(ENCLOSED_LETTERS),
  },
};
