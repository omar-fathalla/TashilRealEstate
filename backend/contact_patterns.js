/**
 * Phone-number shapes shared by the marketplace sanitizer (backend/index.js) and
 * firestore.rules, so both reject exactly the same text. firestore.rules embeds the
 * output of `rulesPhonePatterns()`; `npm run gen:contact-rules` rewrites it and
 * test/contact_patterns.test.js fails when the two drift apart.
 *
 * A phone number is matched by shape, never as "any long digit run":
 *  - trunk zero:  0 + 8-10 digits (EG/UAE mobiles and landlines), e.g. 050 123 4567
 *  - bare mobile: EG 1[0125]xxxxxxxx (10 digits) or UAE 5[024568]xxxxxxx (9 digits)
 *  - country code without +: 971..., 20 1[0125]...
 *  - explicit +/00 international prefix followed by 8-14 digits
 * Digits may be grouped; each group after the first holds at least 3 digits, so dates
 * (2026-01-15), years (2015 2016 2017), and 1/1/2026 never read as one number, and
 * thousands-style groupings of three (1.500.000.000, 100 000 000) are excluded. The
 * letter O counts as zero only inside a digit run: a match always starts and ends on a
 * real digit. Digits of any script (\p{N}), full-width and circled forms included.
 */

const THOUSANDS_GROUP_LIMIT = 3;
const MAX_PARTS = 3;
const MIN_PART = 3;

// First code point (digit zero) of the decimal-digit blocks of the scripts used around the
// UAE and Egypt, plus other Indic and Southeast Asian blocks and full-width digits.
const DECIMAL_DIGIT_ZEROS = [
  0x660, 0x6f0, 0x7c0, 0x966, 0x9e6, 0xa66, 0xae6, 0xb66, 0xbe6, 0xc66, 0xce6, 0xd66, 0xde6,
  0xe50, 0xed0, 0xf20, 0x1040, 0x17e0, 0x1810, 0xff10,
];

// Code points that are the digit k in some script. Used for the literal prefix digits.
function digitCodePoints(k) {
  const cps = [0x30 + k, ...DECIMAL_DIGIT_ZEROS.map((zero) => zero + k)];
  for (let block = 0; block < 5; block += 1) cps.push(0x1d7ce + block * 10 + k);
  if (k === 0) {
    cps.push(0x2070, 0x2080, 0x24ea, 0x24ff);
  } else {
    cps.push(0x2080 + k, 0x2460 + k - 1, 0x24f5 + k - 1, 0x2776 + k - 1, 0x2780 + k - 1, 0x278a + k - 1);
    cps.push(k === 1 ? 0xb9 : k === 2 ? 0xb2 : k === 3 ? 0xb3 : 0x2070 + k);
  }
  return cps;
}

/** Digit value of a non-ASCII digit-like code point, or -1 (used by the sanitizer's fold). */
const EXTRA_DIGIT_VALUES = new Map();
for (let k = 0; k <= 9; k += 1) {
  for (const cp of digitCodePoints(k)) EXTRA_DIGIT_VALUES.set(cp, k);
}

function compositions(sumMin, sumMax) {
  const result = [];
  const walk = (parts, sum) => {
    if (parts.length >= 2 && sum >= sumMin && sum <= sumMax) result.push(parts);
    if (parts.length >= MAX_PARTS) return;
    for (let size = MIN_PART; sum + size <= sumMax; size += 1) walk([...parts, size], sum + size);
  };
  walk([], 0);
  return result;
}

const SEPARATOR_CODE_POINTS = [
  0x20, [9, 13], 0xa0, 0x1680, [0x2000, 0x200f], 0x2028, 0x2029, 0x202f, 0x205f, 0x2060, 0x3000, 0xfeff,
  0x2e, 0x2d, 0x2f, 0x5f, 0x5c, 0x28, 0x29, 0x7e, [0x2010, 0x2015], 0x2212, 0xfe63,
  0xff0d, 0xff0e, 0xff0f, 0xff3f, 0xff3c, 0xff08, 0xff09,
];

function makeCh(target) {
  return (cp) => (target === "js" ? `\\u{${cp.toString(16)}}` : `\\x{${cp.toString(16)}}`);
}

// Digit and letter sets are written with literal characters in the rules to stay inside
// firestore.rules' 4096-character limit per regular expression.
function makeLiteralCh(target) {
  const escaped = makeCh(target);
  if (target === "js") return escaped;
  return (cp) => (/[0-9A-Za-z]/.test(String.fromCodePoint(cp)) || cp >= 0x80 ? String.fromCodePoint(cp) : escaped(cp));
}

function makeSet(target, literal = false) {
  const ch = literal ? makeLiteralCh(target) : makeCh(target);
  return (items) => `[${items.map((i) => (Array.isArray(i) ? `${ch(i[0])}-${ch(i[1])}` : ch(i))).join("")}]`;
}

/**
 * The rules collapse every run of these characters (spaces, dashes, dots, slashes,
 * underscores, backslashes, parentheses, wide variants, invisible spaces) to one `~`
 * before matching, so one spaced separator such as " - " is a single separator.
 */
function rulesSeparatorPattern() {
  return `${makeSet("re2")(SEPARATOR_CODE_POINTS)}+`;
}

function buildPhoneSource(target) {
  const ch = makeLiteralCh(target);
  const set = makeSet(target, true);
  const sepSet = makeSet(target);
  const zeroOrO = [...digitCodePoints(0), 0x4f, 0x6f, 0xff2f, 0xff4f];
  const digitSet = (...ks) => set(ks.flatMap((k) => digitCodePoints(k)));

  const D = "\\p{N}";
  const X = `[\\p{N}${[0x4f, 0x6f, 0xff2f, 0xff4f].map(ch).join("")}]`;
  const S = target === "js" ? `(?:${sepSet(SEPARATOR_CODE_POINTS)}+)` : "~";
  const OPEN = target === "js" ? `(?:${sepSet([0x28, 0xff08])}${S}?)?` : "";
  const PLUS = sepSet([0x2b, 0xff0b]);

  const quant = (token, n) => (n === 1 ? token : `${token}{${n}}`);
  const group = (n) => (n === 1 ? D : n === 2 ? `${D}${D}` : `${D}${quant(X, n - 2)}${D}`);
  const groupRange = (lo, hi) => `${D}${X}{${lo - 2},${hi - 2}}${D}`;
  const tail = (m) => (m === 0 ? "" : m === 1 ? D : `${quant(X, m - 1)}${D}`);

  // Rest of a number after its first group: one group of lo..hi digits, or 2-3 groups.
  const rest = (firstLength, lo, hi) => {
    const options = [`${S}${groupRange(Math.max(lo, 2), hi)}`];
    for (const parts of compositions(lo, hi)) {
      const thousands = firstLength <= THOUSANDS_GROUP_LIMIT && parts.every((p) => p === MIN_PART);
      if (!thousands) options.push(parts.map((p) => `${S}${group(p)}`).join(""));
    }
    return `(?:${options.join("|")})`;
  };

  // Trunk zero, then 8-10 digits: one run, or a short first group (area/operator code)
  // followed by groups of 3+ digits.
  const zero = digitSet(0);
  const trunkForms = [`${X}{7,9}${D}`];
  for (let a = 1; a <= 3; a += 1) trunkForms.push(`${tail(a)}${rest(1 + a, 8 - a, 10 - a)}`);
  const trunkSource = `${OPEN}${zero}(?:${trunkForms.join("|")})`;

  // Mobile numbers written without a trunk zero or country code: a two-digit operator
  // prefix, `total - 2` more digits, grouped after the first 2-5 digits.
  const bare = (firstDigit, secondDigits, total) => {
    const second = set([...secondDigits.flatMap((k) => digitCodePoints(k)), 0x4f, 0x6f, 0xff2f, 0xff4f]);
    const options = [`${quant(X, total - 3)}${D}`];
    for (let b = 0; b <= 3; b += 1) options.push(`${tail(b)}${rest(2 + b, total - 2 - b, total - 2 - b)}`);
    return `${digitSet(firstDigit)}${second}(?:${options.join("|")})`;
  };
  const egMobile = bare(1, [0, 1, 2, 5], 10);
  const uaeMobile = bare(5, [0, 2, 4, 5, 6, 8], 9);

  const cc971Forms = [groupRange(8, 9)];
  for (let a = 1; a <= 4; a += 1) cc971Forms.push(`${tail(a)}${rest(a, 8 - a, 9 - a)}`);
  const cc971Source = `${digitSet(9)}${digitSet(7)}${digitSet(1)}${S}?(?:${cc971Forms.join("|")})`;

  // 20 1[0125]xxxxxxxx: the group after the country code must not look like a year, so
  // "2015 2016 2017" stays text while "2010 1234 5678" is a number.
  const nonYear4 = [
    `(?:[03-9]|[^${ch(0)}-${ch(0x7f)}\\P{N}])${X}{2}${D}`,
    `1[0-8]${X}${D}`,
    `2[1-9]${X}${D}`,
  ].join("|");
  const cc20Source = `${digitSet(2)}${digitSet(0)}${digitSet(1)}${set([...zeroOrO, ...digitCodePoints(1), ...digitCodePoints(2), ...digitCodePoints(5)])}${S}?(?:${nonYear4})${S}?${group(4)}`;

  const plusSource = `${PLUS}${S}?(?:${X}${S}?){8,14}${D}`;
  const doubleZeroSource = `${zero}${set(zeroOrO)}${S}?(?:${X}${S}?){8,14}${D}`;

  const alternatives = [
    trunkSource,
    egMobile,
    uaeMobile,
    cc971Source,
    cc20Source,
    plusSource,
    doubleZeroSource,
  ];
  return alternatives;
}

const JS_PHONE_SOURCE = `(?:${buildPhoneSource("js").join("|")})`;

/** One RE2 pattern per phone family (each must stay under the rules' 4096-character limit). */
function rulesPhonePatterns() {
  return buildPhoneSource("rules").map((alt) => `(?s)^(?:.*[^\\p{N}])?${alt}(?:[^\\p{N}].*)?$`);
}

/** The same patterns, escaped for single-quoted firestore.rules string literals. */
function rulesPhoneLiterals() {
  return rulesPhonePatterns().map((pattern) => pattern.replace(/\\/g, "\\\\"));
}

function rulesSeparatorLiteral() {
  return rulesSeparatorPattern().replace(/\\/g, "\\\\");
}

const PHONE_PATTERN = new RegExp(`(?<![\\p{N}])${JS_PHONE_SOURCE}(?![\\p{N}])`, "gu");

module.exports = {
  PHONE_PATTERN,
  EXTRA_DIGIT_VALUES,
  rulesPhonePatterns,
  rulesSeparatorPattern,
  rulesPhoneLiterals,
  rulesSeparatorLiteral,
};
