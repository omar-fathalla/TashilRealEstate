"use strict";

// The stricter check for an agency's own name and about text (TAQ-198, 201, 207-216, 219-232).
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
// groups of two or more digits never count ("Open 24/7 365, one-stop shop" passes), except one
// 0NN group per run (three digits, "050 twelve thirty four"; not "Units 001 002 003", TAQ-219).
// A comma before a teen or tens word breaks a run (TAQ-215) unless the run starts with a zero
// word or a 0NN group; such a run counts tens as two digits (TAQ-221).
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
// Teens stand for two digits ("صفر خمسة صفر حداشر اتناشر تلتاشر" is 050111213), so they count
// twice; they are also in the lists above. Tens count once (TAQ-215: "nineteen ninety eight",
// "Twenty Twenty Twenty-One"), and so does عشر/عشرة, which follows a unit word ("ثلاثة عشر").
const TWO_DIGIT_WORD_PATTERN = "(?:eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|onze|douze"
  + "|[وف]?(?:حداشر|احداشر|اتناشر|اطناشر|تلتاشر|تلطاشر|اربعتاشر|اربعطاشر|خمستاشر|خمسطاشر|ستاشر|سطاشر|سبعتاشر|سبعطاشر|تمنتاشر|تمانتاشر|تمنطاشر|تسعتاشر|تسعطاشر))";
// Teens and tens: a comma before one of these breaks a number-word run (TAQ-215: "ninety eight,
// twenty years", "Eleven, twelve, thirteen"); a comma between single digits ("zero five zero, one
// two three") does not.
const TENS_WORD_PATTERN = "(?:ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|dix|onze|douze|vingt|trente|quarante|cinquante|soixante|diez|veinte|treinta|cuarenta|cincuenta"
  + "|[وف]?(?:عشره|عشرة|عشر|عشرين|عشرون|ثلاثين|ثلاثون|تلاتين|اربعين|اربعون|خمسين|خمسون|ستين|ستون|سبعين|سبعون|ثمانين|ثمانون|تمانين|تسعين|تسعون"
  + "|حداشر|احداشر|اتناشر|اطناشر|تلتاشر|تلطاشر|اربعتاشر|اربعطاشر|خمستاشر|خمسطاشر|ستاشر|سطاشر|سبعتاشر|سبعطاشر|تمنتاشر|تمانتاشر|تمنطاشر|تسعتاشر|تسعطاشر))";
// Zero words. A run that starts with one ("zero five zero, twelve, thirty four") is a phone even
// when commas split it (TAQ-221), so they get their own marker '*'.
const ZERO_WORD_PATTERN = "(?:zero|oh|o|cero|शून्य|जीरो|[وف]?(?:صفر|زيرو))";
// Every decimal zero (ASCII, Arabic-Indic ٠, Eastern Arabic ۰, Devanagari ०, full-width, ...): the
// server folds digits to ASCII first, the rules can't, so a 0NN group is matched with these on both
// sides (TAQ-225: "٠٥٠ اتناشر تلاتين اربعة").
const ZERO_DIGITS = [
  0x30, 0x660, 0x6f0, 0x7c0, 0x966, 0x9e6, 0xa66, 0xae6, 0xb66, 0xbe6, 0xc66, 0xce6, 0xd66, 0xde6, 0xe50,
  0xed0, 0xf20, 0x1040, 0x1090, 0x17e0, 0x1810, 0x1946, 0x19d0, 0x1a80, 0x1a90, 0x1b50, 0x1bb0, 0x1c40,
  0x1c50, 0xa620, 0xa8d0, 0xa900, 0xa9d0, 0xa9f0, 0xaa50, 0xabf0, 0xff10, 0x104a0, 0x10d30, 0x10d40, 0x11066,
  0x110f0, 0x11136, 0x111d0, 0x112f0, 0x11450, 0x114d0, 0x11650, 0x116c0, 0x116d0, 0x116da, 0x11730, 0x118e0,
  0x11950, 0x11bf0, 0x11c50, 0x11d50, 0x11da0, 0x11de0, 0x11f50, 0x16130, 0x16a60, 0x16ac0, 0x16b50, 0x16d70,
  0x1ccf0, 0x1d7ce, 0x1d7d8, 0x1d7e2, 0x1d7ec, 0x1d7f6, 0x1e140, 0x1e2f0, 0x1e4f0, 0x1e5f1, 0x1e950, 0x1fbf0,
];
// Commas (Latin, full-width, ideographic, Arabic, Arabic thousands separator).
const COMMAS = [0x2c, 0xff0c, 0x3001, 0x60c, 0x66c];
const GLUED_PATTERN = "(?:zero|oh|one|two|three|four|five|six|seven|eight|nine){7,}";
const CONNECTOR_PATTERN = "(?:and|et|y|و)";

const spaced = (list) => `(?:${list.map((t) => t.split("").join(" ?")).join("|")})`;
const TLDS = ["com", "net", "org", "info", "biz", "co", "io", "me", "ae", "eg", "app", "online", "site", "xyz",
  "ly", "gl", "us", "uk", "in", "sa", "qa", "kw", "edu", "gov", "shop", "store"];
// A known ending, each letter optionally followed by one space ("c om", "c o m").
const SPACED_TLD_PATTERN = spaced(TLDS);
// Endings that are not words or country codes, for the forms that look like a sentence or a
// separator ("x. com", "x · com", "x·com"), in any case.
const STRICT_TLD_PATTERN = spaced(["com", "org", "biz", "xyz"]);
// Country codes and endings that start real sentences or close a separator list ("Dubai. UK
// investors", "Dubai · Abu Dhabi · AE", TAQ-211/214): they count only in lower case, checked on
// the original case (x. uk, x · ae, x·sa refused).
const LOWER_CASE_TLD_PATTERN = "(?:uk|edu|gov|ae|eg|sa|qa|kw|ly|io)";
// After "point"/"punto", lower case only ("x point com", "x point net"; not "Point Commercial").
const POINT_TLD_PATTERN = "(?:com|org|biz|xyz)";
// Endings that are also words or codes ("selling point net yields", TAQ-220): after "point" only
// at the end of the text or before punctuation, not before another word; a hyphen and a letter
// continue the word only in a known compound ("point net-zero homes", TAQ-224/227/228).
const POINT_WORDLIKE_TLD_PATTERN = "(?:net|io|ae|eg|sa|qa|kw|ly)";
// Words that make a real compound after one of those endings and a hyphen or dash ("point
// net-zero homes", "net‑worth"; TAQ-224/227). Any other hyphenated word stays a domain form
// ("x point net-call us", "x point io-today", TAQ-228).
const COMPOUND_TAIL_PATTERN = "(?:zero|worth|lease|leases|yield|yields|income|area|return|returns|rent|rents|rental|price|prices|profit|profits|metering|positive|negative|gain|gains|cost|costs|value|values|carbon)";
// Hyphen-minus and U+2010-U+2015 (hyphen, non-breaking hyphen, figure dash, en dash, em dash, bar).
const HYPHENS = [0x2d, [0x2010, 0x2015]];
// After a comma, lower case only: glued before these, or spaced before com ("x,com", "x, com",
// "x、com"); "Sales,Com", "Info,Biz Bay" and "Gross,net yields" pass. net is left out: "Gross,net".
const COMMA_TLD_PATTERN = "(?:com|org|biz|xyz)";
// Endings refused after an abbreviation even with three or more letters ("ltd.realty", "Dr.com").
const ABBREVIATION_TLD_PATTERN = `(?:${SPACED_TLD_PATTERN.slice(3, -1)}|realty|website|estate|properties|property|rentals|agency|club|tech|pro|top|world|live)`;
// Endings that are also words in a company name (Co.LLC, Jr.Homes, Co.Ltd): refused after an
// abbreviation only when written in lower case, as a typed domain is (co.llc, dr.homes, eng.dev).
const ABBREVIATION_WORD_TLD_PATTERN = "(?:homes|house|apartments|villas|land|immo|city|group|global|dev|cloud|space|ltd|llc|inc|company|realestate|rent|vip)";
const ARABIC_TLD_PATTERN = "(?:مصر|امارات|الامارات|السعوديه|السعودية|سعودي|قطر|الاردن|عمان|البحرين|الكويت|المغرب|الجزائر|تونس|فلسطين|سوريه|سورية|شبكه|شبكة|موقع|كوم|عرب)";
const SPOKEN_ARABIC_TLD_PATTERN = "(?:كوم|نت|اورج)";
const DOT_WORD_PATTERN = "(?:dot|d0t|d[.]o[.]t|نقطة|نقطه|دوت)";
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
  0x2e31, 0xa78f, 0x25cf, 0x25e6, 0x2d9, 0x318d, 0x1427, 0xb0, 0x2218];
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
const COMMA = `[${jsClass(COMMAS)}]`;
const ZERO_GROUP = reAll(` [${jsClass(ZERO_DIGITS)}]\\p{Nd}\\p{Nd} `);
// A comma and space between a word and a teen or tens word breaks a number-word run (TAQ-215).
// A comma, a spaced hyphen or dash, or a slash between a word and a teen or tens word breaks a
// number-word run ('!', TAQ-215/226); so does "and" ('^', TAQ-226: "Zero and twelve and twenty
// four"). Each is applied twice, because a match takes the letter the next one needs.
const WORD_COMMA = reAll(`(\\p{L})(?:${COMMA}\\s+|\\s+[${jsClass(HYPHENS)}]\\s+|\\s*/\\s*)(${TENS_WORD_PATTERN}(?:[^\\p{L}]|$))`);
// A comma, spaced dash or slash before a units word ('|', TAQ-232): it closes a digit group in the
// zero checks, so "zero, six, twelve" is a list, not the "zero six" phone start.
const UNIT_COMMA = reAll(`(\\p{L})(?:${COMMA}\\s+|\\s+[${jsClass(HYPHENS)}]\\s+|\\s*/\\s*)(${NUMBER_WORD_PATTERN}(?:[^\\p{L}]|$))`);
// "and"/"or" (also after a comma, and Arabic او) before a teen or tens word; Arabic و before a tens
// word after a comma ("، وستين") or after another tens word ("اربعين وخمسين"), but not after a units
// word, where it builds one number ("اربعة وعشرين" is 24). TAQ-230.
const WORD_AND = reAll(`(\\p{L})${COMMA}?\\s+(?:and|et|y|or|ou|او)\\s+(${TENS_WORD_PATTERN}(?:[^\\p{L}]|$))`);
const WORD_AND_COMMA_WAW = reAll(`(\\p{L})${COMMA}\\s*و\\s*(${TENS_WORD_PATTERN}(?:[^\\p{L}]|$))`);
const WORD_AND_TENS_WAW = reAll(`(^|[^\\p{L}])(${TENS_WORD_PATTERN})\\s+و\\s*(${TENS_WORD_PATTERN}(?:[^\\p{L}]|$))`);
const COMPOUND_HYPHEN = new RegExp(`[${jsClass(HYPHENS)}](${COMPOUND_TAIL_PATTERN}(?:[^\\p{L}]|$))`, "giu");

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
    .replace(/[أإآٱ]/gu, "ا")
    .replace(/ى/gu, "ي")
    .replace(reAll(`[\\[({]${SPACE}*(?:[.]|dot)${SPACE}*[\\])}]`), ".");
}

/**
 * The marker string the phone check reads: '#' number word ('##' a teen), '+' a tens word, '*'
 * zero word, '%' single digit, '~' a 0NN group (three digits), '&' connector, '!' a comma before a teen or tens
 * word (TAQ-215).
 */
function numberMarkers(normal) {
  return `  ${normal.replace(WORD_AND, "$1 andbrk $2").replace(WORD_AND, "$1 andbrk $2")
    .replace(WORD_AND_COMMA_WAW, "$1 andbrk $2").replace(WORD_AND_COMMA_WAW, "$1 andbrk $2")
    .replace(WORD_AND_TENS_WAW, "$1$2 andbrk $3").replace(WORD_AND_TENS_WAW, "$1$2 andbrk $3")
    .replace(WORD_COMMA, "$1 brk $2").replace(WORD_COMMA, "$1 brk $2")
    .replace(UNIT_COMMA, "$1 ubrk $2").replace(UNIT_COMMA, "$1 ubrk $2").replace(reAll(`[\\u20e3${jsClass(ALT_DOTS)}]`), " ").replace(/[^\p{L}\p{N}\p{M}]+/gu, "  ")}  `
    .replace(/ brk /gu, " ! ")
    .replace(/ andbrk /gu, " ^ ")
    .replace(/ ubrk /gu, " | ")
    .replace(reAll(` ${TWO_DIGIT_WORD_PATTERN} `), " ## ")
    .replace(reAll(` ${TENS_WORD_PATTERN} `), " + ")
    .replace(reAll(` ${ZERO_WORD_PATTERN} `), " * ")
    .replace(reAll(` ${NUMBER_WORD_PATTERN} `), " # ")
    .replace(ZERO_GROUP, " ~ ")
    .replace(/ \p{Nd} /gu, " % ")
    .replace(reAll(` ${CONNECTOR_PATTERN} `), " & ")
    .replace(/\s+/gu, "")
    .replace(/([#*+])&/g, "$1")
    .replace(/&([#*+])/g, "$1");
}

// Seven digit markers in a row, a tens word counting once (TAQ-215: "nineteen ninety eight"). A
// 0NN group counts as three digits once in a run, so "Units 001 002 003" is not a phone (TAQ-219).
const NUMBER_RUN_PATTERN = "(?:[#%*+]{7}|[#%*+]~[#%*+]{3}|[#%*+]{2}~[#%*+]{2}|[#%*+]{3}~[#%*+]|[#%*+]{4}~)";
// A run that starts like a phone is read with each tens word as two digits ('+' -> '==') and with
// commas, dashes and "and" ('!', '^') not breaking it (TAQ-221: "zero five zero, twelve, thirty
// four", "صفر خمسة صفر، عشرين، تلاتين، اربعين"). Starting like a phone means a 0NN group, or a zero
// word glued to another single digit word, digit or 0NN group ("zero five", "oh five", "صفر خمسة",
// "five zero").
// A comma before a units word ('|') does not break a run that has started, but a zero word and a
// units word with a comma between them ("zero, six") do not start one (TAQ-232).
const ZERO_RUN_PATTERN = "(?:[*][#%*~](?:[!^|]?[#%*=]){5}|[#%][*](?:[!^|]?[#%*=]){5}|~(?:[!^|]?[#%*=]){4})";
// A lone zero word followed by a comma or dash (TAQ-223/226: "Zero, twelve, twenty four and thirty
// six month plans") is a phone only when the list spells exactly 9-11 digits, counted as digits
// (TAQ-229): a units word 1, a teen or a plain tens word 2, a tens word with its unit 2 ("thirty
// four", "اربعة وعشرين"). A unit right before a tens word is paired first, so Arabic groups side by side
// ("اربعة وتلاتين، ستة وخمسين") are read 34 56, not 3 46 5 (TAQ-231); a comma or dash before a
// tens word ('!') closes a group, so English "thirty four, fifty six" pairs as before. A list that closes with "and"/"or"/و before its last item ('^') is a plan,
// not a phone ("... forty eight and sixty months", "اربعين وخمسين في المية"; TAQ-230).
// A lone zero then a comma before a units word ("zero, six, twelve, eighteen, twenty four months")
// is read the same way (TAQ-232).
const LONE_ZERO_RUN_PATTERN = "[*][!|](?:[!|]?[#%*=]){8,10}(?:[^#%*=!|^]|[!|](?:[^#%*=^]|$)|$)";
const NUMBER_RUN = re(NUMBER_RUN_PATTERN);
const ZERO_RUN = re(ZERO_RUN_PATTERN);
const LONE_ZERO_RUN = re(LONE_ZERO_RUN_PATTERN);
const hasNumberRun = (markers) => NUMBER_RUN.test(markers.replace(/[|]/g, ""))
  || ZERO_RUN.test(markers.replace(/[+]/g, "=="))
  || LONE_ZERO_RUN.test(markers.replace(/#[+]/g, "==").replace(/[+]#/g, "==").replace(/[+]/g, "=="));
const GLUED = re(GLUED_PATTERN);

const END = "(?![\\p{L}])";
const DOT_FORM = "(?:[.]| +[.] ?)";
const DOMAIN = re(`${LABEL}${DOT_FORM}(?:${LETTERLIKE}{2}|${ARABIC_TLD_PATTERN}|${SPACED_TLD_PATTERN}${END})`);
const SPACE_AFTER_DOT = re(`[\\p{L}\\p{N}](?:[.] +| *${ALT_DOT} *)${STRICT_TLD_PATTERN}${END}`);
const WORD_DOT = re(`[\\p{L}\\p{N}][ _-]*${DOT_WORD_PATTERN}[ _-]*(?:${SPACED_TLD_PATTERN}|${SPOKEN_ARABIC_TLD_PATTERN})${END}`);
// On the original case (casedAgencyText):
const LOWER_CASE_SPACE_AFTER_DOT = re(`[\\p{L}\\p{N}](?:[.] +| *${ALT_DOT} *)${LOWER_CASE_TLD_PATTERN}${END}`);
const POINT_WORD = re(`[\\p{L}\\p{N}][ _-]*${POINT_WORD_PATTERN}[ _-]*(?:${POINT_TLD_PATTERN}(?:[^\\p{L}]|$)|${POINT_WORDLIKE_TLD_PATTERN}\\s*(?:[^\\p{L}\\s]|$))`);
const COMMA_DOMAIN = re(`[\\p{L}\\p{N}](?:${COMMA}${COMMA_TLD_PATTERN}| ?${COMMA} ?com)${END}`);
// With the i flag for the abbreviation; the ending must then be lower case (rules: (?i:abbr)[.]ending).
const ABBREVIATION_WORD_DOMAIN = new RegExp(`[^\\p{L}\\p{N}]${ABBREVIATION_PATTERN}[.](${ABBREVIATION_WORD_TLD_PATTERN})${END}`, "giu");
// Letters typed for digits next to a digit ("O5O l234567", "0S0 1234567"): O -> 0, l and I -> 1,
// S before a digit -> 5, then the phone check runs again. A letter after a digit becomes " 0"/" 1"
// (rules can't write "$1" then a digit); S after a digit is left alone ("1990s").
const LETTER_DIGITS = [[/[oO](\p{Nd})/gu, "0$1"], [/[lI](\p{Nd})/gu, "1$1"], [/[sS](\p{Nd})/gu, "5$1"],
  [/(\p{Nd})[oO]/gu, "$1 0"], [/(\p{Nd})[lI]/gu, "$1 1"]];

function lettersAsDigits(text) {
  return LETTER_DIGITS.reduce((out, [pattern, sub]) => out.replace(pattern, sub), text);
}

/** The domain-like fragment in the original case, or "" (lower-case-only endings). */
function casedDomainIn(cased) {
  // A known compound after a hyphen is a word ("net-zero"); the point check reads it with a space.
  const compounds = cased.replace(COMPOUND_HYPHEN, " $1");
  for (const [pattern, text] of [[LOWER_CASE_SPACE_AFTER_DOT, cased], [POINT_WORD, compounds], [COMMA_DOMAIN, cased]]) {
    const m = text.match(pattern);
    if (m) return wordAround(text, m.index, m[0].length).toLowerCase();
  }
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
  const digits = lettersAsDigits(text);
  if (kind === "phone" || hasNumberRun(numberMarkers(normal)) || GLUED.test(normal) || hasSpelledOutNumber(text)
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
    NUMBER_WORD_PATTERN, TWO_DIGIT_WORD_PATTERN, TENS_WORD_PATTERN, ZERO_WORD_PATTERN, NUMBER_RUN_PATTERN, ZERO_RUN_PATTERN, LONE_ZERO_RUN_PATTERN, GLUED_PATTERN, CONNECTOR_PATTERN, SPACED_TLD_PATTERN, STRICT_TLD_PATTERN,
    LOWER_CASE_TLD_PATTERN, POINT_TLD_PATTERN, POINT_WORDLIKE_TLD_PATTERN, COMPOUND_TAIL_PATTERN, COMMA_TLD_PATTERN, ABBREVIATION_TLD_PATTERN,
    ABBREVIATION_WORD_TLD_PATTERN, ARABIC_TLD_PATTERN, SPOKEN_ARABIC_TLD_PATTERN, DOT_WORD_PATTERN,
    POINT_WORD_PATTERN, ABBREVIATION_PATTERN, PLACE_PATTERN,
    INVISIBLES_RULES: rulesClass(INVISIBLES), FULL_STOPS_RULES: rulesClass(UNICODE_FULL_STOPS),
    ALT_DOTS_RULES: rulesClass(ALT_DOTS), LETTER_SYMBOLS_RULES: rulesClass(LETTER_SYMBOLS),
    ENCLOSED_LETTERS_RULES: rulesClass(ENCLOSED_LETTERS), COMMAS_RULES: rulesClass(COMMAS),
    ZERO_DIGITS_RULES: rulesClass(ZERO_DIGITS), HYPHENS_RULES: rulesClass(HYPHENS),
  },
};
