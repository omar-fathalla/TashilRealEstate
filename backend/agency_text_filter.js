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
  "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety", "double", "triple",
  "un", "une", "deux", "trois", "quatre", "cinq", "sept", "huit", "neuf", "dix", "onze", "douze",
  "cero", "uno", "una", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez",
  "शून्य", "जीरो", "एक", "दो", "तीन", "चार", "पांच", "पाँच", "छह", "छः", "छे", "सात", "आठ", "नौ",
  "ایک", "دو", "تین", "چار", "پانچ", "چھ", "سات", "اٹھ", "نو",
];
// Arabic number words; each also matches with a و or ف prefix.
const ARABIC_NUMBER_WORDS = [
  "صفر", "واحد", "واحده", "واحدة", "اثنين", "اتنين", "اثنان", "ثلاثه", "ثلاثة", "ثلاث", "تلاته", "تلاتة", "تلات", "تلاث",
  "اربعه", "اربعة", "اربع", "خمسه", "خمسة", "خمس", "سته", "ستة", "ست", "سبعه", "سبعة", "سبع",
  "ثمانيه", "ثمانية", "ثماني", "ثمان", "تمانيه", "تمانية", "تماني", "تمان", "تمنيه", "تمنية", "تسعه", "تسعة", "تسع",
  "عشره", "عشرة", "عشر", "عشرين", "عشرون", "ثلاثين", "ثلاثون", "تلاتين", "اربعين", "اربعون", "خمسين", "خمسون",
  "ستين", "ستون", "سبعين", "سبعون", "ثمانين", "ثمانون", "تمانين", "تسعين", "تسعون",
];
const NUMBER_WORD_PATTERN = `(?:${NUMBER_WORDS.join("|")}|[وف]?(?:${ARABIC_NUMBER_WORDS.join("|")}))`;
const GLUED_PATTERN = "(?:zero|oh|one|two|three|four|five|six|seven|eight|nine){7,}";
const CONNECTOR_PATTERN = "(?:and|et|y|و)";

const spaced = (list) => `(?:${list.map((t) => t.split("").join(" ?")).join("|")})`;
const TLDS = ["com", "net", "org", "info", "biz", "co", "io", "me", "ae", "eg", "app", "online", "site", "xyz",
  "ly", "gl", "us", "uk", "in", "sa", "qa", "kw", "edu", "gov", "shop", "store"];
// A known ending, each letter optionally followed by one space ("c om", "c o m").
const SPACED_TLD_PATTERN = spaced(TLDS);
// Endings that are not also everyday words, for the forms that look like a sentence ("x. com").
const STRICT_TLD_PATTERN = spaced(["com", "org", "biz", "io", "xyz", "ae", "eg", "sa", "qa", "kw", "ly", "uk", "edu", "gov"]);
// Endings refused after an abbreviation even with three or more letters ("ltd.realty", "Dr.com").
const ABBREVIATION_TLD_PATTERN = `(?:${SPACED_TLD_PATTERN.slice(3, -1)}|realty|website|estate|properties|property|rentals|agency|club|tech|pro|top|world|live)`;
const ARABIC_TLD_PATTERN = "(?:مصر|امارات|الامارات|السعوديه|السعودية|سعودي|قطر|الاردن|عمان|البحرين|الكويت|المغرب|الجزائر|تونس|فلسطين|سوريه|سورية|شبكه|شبكة|موقع|كوم|عرب)";
const SPOKEN_ARABIC_TLD_PATTERN = "(?:كوم|نت|اورج)";
const DOT_WORD_PATTERN = "(?:dot|نقطة|نقطه|دوت)";
const ABBREVIATION_PATTERN = "(?:p[.] ?o|dr|eng|sh|mrs|mr|ms|co|inc|ltd|no|jr|sr)";
// Place names after a dot that are not TLDs, so "Cairo.Egypt" is an address, not a domain.
const PLACE_PATTERN = "(?:egypt|cairo|giza|alexandria|uae|sharjah|ajman|fujairah)";

const SPACE = "[\\s\\u00a0\\u2000-\\u200a\\u202f\\u3000]";
// Code points shared with the rules: dots used in place of '.', and letter-like symbols (math
// alphanumerics, circled and squared letters) the rules can't fold to Latin.
const ALT_DOTS = [0xb7, 0x2022, 0x2219, 0x22c5, 0x2027, 0x66b, 0x6d4, 0x30fb, 0xff65];
const LETTER_SYMBOLS = [[0x1d400, 0x1d7ff], [0x24b6, 0x24e9], [0x1f130, 0x1f189]];
const hex = (c) => c.toString(16);
const jsClass = (items) => items.map((i) => (Array.isArray(i) ? `\\u{${hex(i[0])}}-\\u{${hex(i[1])}}` : `\\u{${hex(i)}}`)).join("");
// As written inside a firestore.rules string literal ('\\x{b7}').
const rulesClass = (items) => items.map((i) => (Array.isArray(i) ? `\\\\x{${hex(i[0])}}-\\\\x{${hex(i[1])}}` : `\\\\x{${hex(i)}}`)).join("");
const ALT_DOT = `[${jsClass(ALT_DOTS)}]`;
const LETTERLIKE = `[\\p{Script=Latin}\\p{Script=Cyrillic}\\p{Script=Greek}\\p{Script=Armenian}${jsClass(LETTER_SYMBOLS)}]`;
const LABEL = `[\\p{L}\\p{N}${jsClass(LETTER_SYMBOLS.slice(1))}-]`;
const re = (source) => new RegExp(source, "u");
const reAll = (source) => new RegExp(source, "gu");

const GLUED_ALT_DOT = reAll(`([\\p{L}\\p{N}])${ALT_DOT}([\\p{L}\\p{N}])`);

/** Lower case, accents and invisibles removed, dots and Arabic letter variants unified. */
function normaliseAgencyText(text) {
  const plain = String(text).normalize("NFKD").replace(/[\u0300-\u036f]/gu, "")
    .replace(/[\u00ad\u180e\u200b-\u200f\u2060-\u2064\ufe00-\ufe0f\ufeff]/gu, "")
    .normalize("NFKC");
  return foldForContactMatching(plain).folded
    .toLowerCase()
    .replace(/ø/gu, "o")
    .replace(/ı/gu, "i")
    .replace(/[\u3002\uff61\ufe52\uff0e\u2024]/gu, ".")
    .replace(GLUED_ALT_DOT, "$1.$2")
    .replace(GLUED_ALT_DOT, "$1.$2")
    .replace(/[\u064b-\u065f\u0670\u0640]/gu, "")
    .replace(/[أإآٱ]/gu, "ا")
    .replace(/ى/gu, "ي")
    .replace(reAll(`[\\[({]${SPACE}*(?:[.]|dot)${SPACE}*[\\])}]`), ".");
}

/** The marker string the phone check reads: '#' number word, '%' single digit, '&' connector. */
function numberMarkers(normal) {
  return `  ${normal.replace(/[\u20e3]/gu, " ").replace(/[^\p{L}\p{N}\p{M}]+/gu, "  ")}  `
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
const WWW = /(?:^|[^\p{L}\p{N}])www(?:[^\p{L}\p{N}]|$)/u;
const ABBREVIATION = reAll(`([^\\p{L}\\p{N}])${ABBREVIATION_PATTERN}[.](\\p{L}{3})`);
const PLACE = reAll(`[.](${PLACE_PATTERN})(?=[^\\p{L}\\p{N}.-]|$)`);
const ABBREVIATION_DOMAIN = re(`[^\\p{L}\\p{N}]${ABBREVIATION_PATTERN}${DOT_FORM}${ABBREVIATION_TLD_PATTERN}${END}`);

/** The domain-like fragment of normalised text, or "". */
function domainIn(normal) {
  const text = ` ${normal.replace(reAll(`${SPACE}+`), " ")}`;
  const exempted = text.replace(ABBREVIATION, "$1  $2").replace(PLACE, " $1");
  for (const pattern of [DOMAIN, SPACE_AFTER_DOT, WORD_DOT, WWW]) {
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
  if (kind === "phone" || NUMBER_RUN.test(numberMarkers(normal)) || GLUED.test(normal) || hasSpelledOutNumber(text)) {
    return { kind: "phone", match: "" };
  }
  if (kind === "email") return { kind: "email", match: "" };
  const domain = domainIn(normal);
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
    NUMBER_WORD_PATTERN, GLUED_PATTERN, CONNECTOR_PATTERN, SPACED_TLD_PATTERN, STRICT_TLD_PATTERN,
    ABBREVIATION_TLD_PATTERN, ARABIC_TLD_PATTERN, SPOKEN_ARABIC_TLD_PATTERN, DOT_WORD_PATTERN,
    ABBREVIATION_PATTERN, PLACE_PATTERN,
    ALT_DOTS_RULES: rulesClass(ALT_DOTS), LETTER_SYMBOLS_RULES: rulesClass(LETTER_SYMBOLS),
  },
};
