"use strict";

// The stricter check for an agency's own name and about text (TAQ-198, TAQ-201, TAQ-207, TAQ-208).
// It runs the request filter (request_text_filter.js), then the agency checks below on a normalised
// copy. firestore.rules (agencyTextFree) runs the same agency checks for direct Agencies/{id}
// writes. The word, ending and abbreviation lists are exported and test/agency_text_filter.test.js
// checks that firestore.rules holds them verbatim, so the two cannot drift apart.
//
// Normalisation (both sides): lower case; Unicode full stops (。 ． ｡ ﹒ ․) to '.'; أ/إ/آ/ٱ to ا and
// ى to ي; harakat, tatweel and zero-width characters removed; "[.]", "(.)", "[dot]", "(dot)" to '.'.
//
// Phone: every run of characters that are not letters, digits or marks is a separator (so – · ~ |
// + / and keycap marks are too). Each token becomes a marker: a number word '#', a single digit
// '%', a connector ("and", "et", "و") '&'. A connector counts only next to a number word ("zero and
// five"); "6 and 7" still breaks the run. Seven markers in a row is a phone. Digit groups of two or
// more digits never count, so "Open 24/7 365, one-stop shop" passes (TAQ-208).
//
// Domain: a word, a dot glued to it (or a dot with spaces before it), then two letters of a
// Latin, Cyrillic or Greek script ("x.shop", "x.соm"), an Arabic country or generic ending
// ("x.مصر"), or a known ending spelled with spaces ("x.c om", "x . c o m"). A known abbreviation
// before the dot (P.O, Dr, Mr, Mrs, Ms, Co, Inc, Ltd, No, Jr, Sr; not St) is exempt unless a known
// ending follows: "P.O.Box", "Dr.Ahmed" and "Co.LLC" pass, "Dr.com" and "St.Regis" do not. Also
// "www." and "x dot com".

const { contactKind, foldForContactMatching } = require("./contact_filter");
const { containsContactInRequestText, hasSpelledOutNumber } = require("./request_text_filter");

// Number words, lower case and already normalised. Arabic words also match with a و or ف prefix.
const NUMBER_WORDS = [
  "zero", "oh", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
  "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
  "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety",
  "zéro", "un", "une", "deux", "trois", "quatre", "cinq", "sept", "huit", "neuf", "dix", "onze", "douze",
  "शून्य", "जीरो", "एक", "दो", "तीन", "चार", "पांच", "पाँच", "छह", "छः", "छे", "सात", "आठ", "नौ",
];
const ARABIC_NUMBER_WORDS = [
  "صفر", "واحد", "واحده", "واحدة", "اثنين", "اتنين", "اثنان", "ثلاثه", "ثلاثة", "ثلاث", "تلاته", "تلاتة", "تلات", "تلاث",
  "اربعه", "اربعة", "اربع", "خمسه", "خمسة", "خمس", "سته", "ستة", "ست", "سبعه", "سبعة", "سبع",
  "ثمانيه", "ثمانية", "ثماني", "ثمان", "تمانيه", "تمانية", "تماني", "تمان", "تسعه", "تسعة", "تسع",
];
const NUMBER_WORD_PATTERN = `(?:${NUMBER_WORDS.join("|")}|[وف]?(?:${ARABIC_NUMBER_WORDS.join("|")}))`;
const GLUED_PATTERN = "(?:zero|oh|one|two|three|four|five|six|seven|eight|nine){7,}";
const CONNECTOR_PATTERN = "(?:and|et|و)";

const TLDS = ["com", "net", "org", "info", "biz", "co", "io", "me", "ae", "eg", "app", "online", "site", "xyz",
  "ly", "gl", "us", "uk", "in", "sa", "qa", "kw", "edu", "gov", "shop", "store"];
// A known ending, each letter optionally followed by one space ("c om", "c o m").
const SPACED_TLD_PATTERN = `(?:${TLDS.map((t) => t.split("").join(" ?")).join("|")})`;
const ARABIC_TLD_PATTERN = "(?:مصر|امارات|الامارات|السعوديه|السعودية|سعودي|قطر|الاردن|عمان|البحرين|الكويت|المغرب|الجزائر|تونس|فلسطين|سوريه|سورية|شبكه|شبكة|موقع|كوم|عرب)";
const ABBREVIATION_PATTERN = "(?:p[.] ?o|dr|mrs|mr|ms|co|inc|ltd|no|jr|sr)";

const SPACE = "[\\s\\u00a0\\u2000-\\u200a\\u202f\\u3000]";
const re = (source) => new RegExp(source, "u");
const reAll = (source) => new RegExp(source, "gu");

/** Lower case, Unicode dots to '.', Arabic letter variants unified, harakat/tatweel/zero-width removed. */
function normaliseAgencyText(text) {
  const plain = String(text).normalize("NFKC").replace(/[\u200b-\u200f\u2060\ufeff]/gu, "");
  return foldForContactMatching(plain).folded
    .toLowerCase()
    .replace(/[\u3002\uff61\ufe52\uff0e\u2024]/gu, ".")
    .replace(/[\u064b-\u065f\u0670\u0640]/gu, "")
    .replace(/[أإآٱ]/gu, "ا")
    .replace(/ى/gu, "ي")
    .replace(reAll(`[\\[({]${SPACE}*(?:[.]|dot)${SPACE}*[\\])}]`), ".");
}

/** The marker string the phone check reads: '#' number word, '%' single digit, '&' connector. */
function numberMarkers(normal) {
  return `  ${normal.replace(/[\u20e3\ufe0e\ufe0f]/gu, " ").replace(/[^\p{L}\p{N}\p{M}]+/gu, "  ")}  `
    .replace(reAll(` ${NUMBER_WORD_PATTERN} `), " # ")
    .replace(/ \p{Nd} /gu, " % ")
    .replace(reAll(` ${CONNECTOR_PATTERN} `), " & ")
    .replace(/\s+/gu, "")
    .replace(/#&/g, "#")
    .replace(/&#/g, "#");
}

const NUMBER_RUN = /[#%]{7}/;
const GLUED = re(GLUED_PATTERN);

const ENDING = `(?:[\\p{Script=Latin}\\p{Script=Cyrillic}\\p{Script=Greek}]{2}|${ARABIC_TLD_PATTERN}|${SPACED_TLD_PATTERN}(?!\\p{L}))`;
const DOT_FORM = "(?:[.]| +[.] ?)";
const DOMAIN = re(`[\\p{L}\\p{N}-]${DOT_FORM}${ENDING}`);
const ABBREVIATION = reAll(`[^\\p{L}\\p{N}]${ABBREVIATION_PATTERN}[.]`);
const ABBREVIATION_DOMAIN = re(`[^\\p{L}\\p{N}]${ABBREVIATION_PATTERN}${DOT_FORM}${SPACED_TLD_PATTERN}(?!\\p{L})`);
const WORD_DOT = re(`[\\p{L}\\p{N}] +dot +${SPACED_TLD_PATTERN}(?!\\p{L})`);
const WWW = /(?:^|[^\p{L}\p{N}])www ?[.]/u;

/** The domain-like fragment of normalised text, or "". */
function domainIn(normal) {
  const text = ` ${normal.replace(reAll(`${SPACE}+`), " ")}`;
  const exempted = text.replace(ABBREVIATION, "  ");
  for (const pattern of [DOMAIN, WORD_DOT, WWW]) {
    const m = exempted.match(pattern);
    if (m) return wordAround(text, m.index, m[0].length);
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
 * found (e.g. "name at host dot com").
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
    NUMBER_WORD_PATTERN, GLUED_PATTERN, CONNECTOR_PATTERN, SPACED_TLD_PATTERN, ARABIC_TLD_PATTERN, ABBREVIATION_PATTERN,
  },
};
