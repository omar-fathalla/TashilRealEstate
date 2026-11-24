/**
 * Contact patterns shared by the marketplace sanitizer (backend/index.js) and
 * firestore.rules, so both reject exactly the same text. firestore.rules embeds the
 * generated block (`npm run gen:contact-rules`); test/contact_patterns.test.js fails when
 * the two drift apart. The sanitizer runs the very same RE2 sources, translated to JS.
 *
 * Text is first normalized by a fixed list of replace() steps (NORMALIZE_STEPS):
 *  - keycap and emoji joiners (U+FE0F, U+20E3, U+200D) are dropped,
 *  - a comma followed by a space, a " | " with spaces around it, and the edges of a
 *    comma-grouped amount (1,500,000 or 1,50,00,000) become `§`, which no phone crosses,
 *  - " x " between numbers, "+" after a digit, and one ASCII letter between digits act as
 *    separators,
 *  - every run of separator characters (spaces, dashes, dots, slashes, commas, colons, |, *,
 *    #, apostrophes, middle dots, Arabic thousands/decimal marks, invisible characters, ...)
 *    becomes one `~`.
 * Phones are then matched by shape on that text, and again after MERGE_STEPS join 1-2 digit
 * groups to their neighbours (so "010 12 34 56 78" reads as one number):
 *  - trunk zero:  0 + 8-10 digits (EG/UAE mobiles and landlines), e.g. 050 123 4567
 *  - bare mobile: EG 1[0125]xxxxxxxx (10 digits) or UAE 5[024568]xxxxxxx (9 digits)
 *  - country code without +: 971..., 20 1[0125]...
 *  - explicit +/00 international prefix followed by 8-14 digits
 * Groups after the first hold at least 3 digits, so dates and year lists never read as one
 * number, and thousands-style groupings (1.500.000.000, 100 000 000, UAE 501 234 567) are
 * excluded; MERGE_STEPS never join a leading 1-2 digit group to a following 3-digit group for
 * the same reason. The letters O/o and l/I (and their full-width forms) count as 0 and 1 only
 * inside a digit run: a match always starts and ends on a real digit. Digits of any script
 * (\p{N}), full-width and circled forms included.
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

const IGNORABLE_CODE_POINTS = [0xfe0e, 0xfe0f, 0x20e3, 0x200d];

const SEPARATOR_CODE_POINTS = [
  0x20, [9, 13], 0xa0, 0xad, 0x61c, 0x1680, 0x180e, [0x2000, 0x200f], 0x2028, 0x2029, [0x202a, 0x202f],
  0x205f, [0x2060, 0x2064], [0x2066, 0x206f], 0x3000, 0xfeff,
  0x2e, 0x2d, 0x2f, 0x5f, 0x5c, 0x28, 0x29, 0x7e, [0x2010, 0x2015], 0x2212, 0xfe63,
  0x2c, 0x7c, 0x3a, 0x2a, 0x23, 0x27, 0xb7, 0x2022, 0x66b, 0x66c,
  0xff0d, 0xff0e, 0xff0f, 0xff3f, 0xff3c, 0xff08, 0xff09, 0xff0c, 0xff1a, 0xff5c,
];

// Spaces around the " x " separator.
const SPACE_CODE_POINTS = [[9, 13], 0x20, 0xa0, [0x2000, 0x200a], 0x202f, 0x3000];

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

const ZERO_LETTERS = [0x4f, 0x6f, 0xff2f, 0xff4f]; // O o Ｏ ｏ
const ONE_LETTERS = [0x6c, 0x49, 0xff4c, 0xff29]; // l I ｌ Ｉ

function buildPhoneSource() {
  const target = "re2";
  const ch = makeLiteralCh(target);
  const set = makeSet(target, true);
  const sepSet = makeSet(target);
  const zeroOrO = [...digitCodePoints(0), ...ZERO_LETTERS];
  const digitSet = (...ks) => set(ks.flatMap((k) => digitCodePoints(k)));

  const D = "\\p{N}";
  const X = `[\\p{N}${[...ZERO_LETTERS, ...ONE_LETTERS].map(ch).join("")}]`;
  const S = "~";
  const PLUS = sepSet([0x2b, 0xff0b]);

  const quant = (token, n) => (n === 1 ? token : `${token}{${n}}`);
  const group = (n) => (n === 1 ? D : n === 2 ? `${D}${D}` : `${D}${quant(X, n - 2)}${D}`);
  const groupRange = (lo, hi) => `${D}${X}{${lo - 2},${hi - 2}}${D}`;
  const tail = (m) => (m === 0 ? "" : m === 1 ? D : `${quant(X, m - 1)}${D}`);

  // Rest of a number after its first group: one group of lo..hi digits, or 2-3 groups.
  // `keepThousands` lists group counts for which all-3-digit groups still read as a phone.
  const rest = (firstLength, lo, hi, keepThousands = []) => {
    const options = [`${S}${groupRange(Math.max(lo, 2), hi)}`];
    for (const parts of compositions(lo, hi)) {
      const thousands = firstLength <= THOUSANDS_GROUP_LIMIT && parts.every((p) => p === MIN_PART)
        && !keepThousands.includes(parts.length);
      if (!thousands) options.push(parts.map((p) => `${S}${group(p)}`).join(""));
    }
    return `(?:${options.join("|")})`;
  };

  // Trunk zero, then 8-10 digits: one run, or a first group of up to 7 digits (010 12 345 678
  // once short groups are merged) followed by groups. No EG/UAE operator or area code starts
  // with 0, so the digit after the trunk zero is never a real 0 (the trailing zeros of
  // 1 500 000 never start a number). 0X DDD DDD DDD is an 11-digit EG mobile, not a
  // thousands grouping, because no amount starts with 0.
  const zero = digitSet(0);
  const afterTrunk = set([...[1, 2, 3, 4, 5, 6, 7, 8, 9].flatMap((k) => digitCodePoints(k)), ...ZERO_LETTERS, ...ONE_LETTERS]);
  const trunkForms = [`${X}{6,8}${D}`];
  for (let a = 1; a <= 7; a += 1) trunkForms.push(`${tail(a - 1)}${rest(1 + a, 8 - a, 10 - a, a === 1 ? [3] : [])}`);
  const trunkSource = `${zero}${afterTrunk}(?:${trunkForms.join("|")})`;

  // Mobile numbers written without a trunk zero or country code: a two-digit operator
  // prefix, `total - 2` more digits, grouped after the first 2-5 digits.
  const bare = (firstDigit, secondDigits, total) => {
    const letters = secondDigits.includes(0) ? ZERO_LETTERS : [];
    const second = set([...secondDigits.flatMap((k) => digitCodePoints(k)), ...letters, ...(secondDigits.includes(1) ? ONE_LETTERS : [])]);
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
    `${digitSet(0, 3, 4, 5, 6, 7, 8, 9)}${X}{2}${D}`,
    `${digitSet(1)}${digitSet(0, 1, 2, 3, 4, 5, 6, 7, 8)}${X}${D}`,
    `${digitSet(2)}${digitSet(1, 2, 3, 4, 5, 6, 7, 8, 9)}${X}${D}`,
  ].join("|");
  const cc20Source = `${digitSet(2)}${digitSet(0)}${digitSet(1)}${set([...zeroOrO, ...ONE_LETTERS, ...digitCodePoints(1), ...digitCodePoints(2), ...digitCodePoints(5)])}${S}?(?:${nonYear4})${S}?${group(4)}`;

  const plusSource = `${PLUS}${S}?(?:${X}${S}?){8,14}${D}`;
  // 00 + country code: country codes never start with 0, so "000 10 12" is not a number.
  const countryStart = set([...[1, 2, 3, 4, 5, 6, 7, 8, 9].flatMap((k) => digitCodePoints(k)), ...ONE_LETTERS]);
  const doubleZeroSource = `${zero}${set(zeroOrO)}${S}?${countryStart}${S}?(?:${X}${S}?){7,13}${D}`;

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

const RE2 = { set: makeSet("re2"), ch: makeCh("re2"), literalSet: makeSet("re2", true) };
const N = "\\p{N}";

// Ends a phone candidate: list items are never one number.
const BREAK = "\u00a7";
const COMMAS = [0x2c, 0x66c, 0xff0c];
const NONZERO_DIGIT = RE2.literalSet([1, 2, 3, 4, 5, 6, 7, 8, 9].flatMap((k) => digitCodePoints(k)));
// 1,500,000 and the Indian 1,50,00,000: one token, fenced off from the numbers around it.
const THOUSANDS_STEP = (() => {
  const comma = RE2.set(COMMAS);
  const notDigitOrComma = `[^${N}${COMMAS.map(RE2.ch).join("")}]`;
  const token = `${NONZERO_DIGIT}(?:${N}{0,2}(?:${comma}${N}{3})+|${N}?(?:${comma}${N}{2})+${comma}${N}{3})`;
  return [
    `(^|${notDigitOrComma}|[^${N}]${comma})(${token})(${notDigitOrComma}|${comma}[^${N}]|${comma}$|$)`,
    `$1${BREAK}$2${BREAK}$3`,
  ];
})();

/** replace() steps, in order: [RE2 pattern, replacement]. `$n` refers to capture group n. */
const NORMALIZE_STEPS = [
  [RE2.set(IGNORABLE_CODE_POINTS), ""],
  [`${RE2.set(SPACE_CODE_POINTS)}*${RE2.set(COMMAS)}${RE2.set(SPACE_CODE_POINTS)}+`, BREAK],
  [`${RE2.set(SPACE_CODE_POINTS)}+${RE2.set([0x7c, 0xff5c])}${RE2.set(SPACE_CODE_POINTS)}+`, BREAK],
  // Twice: replace() never overlaps, and neighbouring tokens share the character between them.
  THOUSANDS_STEP,
  THOUSANDS_STEP,
  [`${RE2.set(SPACE_CODE_POINTS)}+[xX${RE2.ch(0xd7)}]${RE2.set(SPACE_CODE_POINTS)}+`, " "],
  [`(${N})${RE2.set(SPACE_CODE_POINTS)}*${RE2.set([0x2b, 0xff0b])}`, "$1~"],
  // Any ASCII letter except O/o and l/I, which read as digits instead.
  [`(${N})[A-HJ-NP-Za-km-np-z](${N})`, "$1~$2"],
  [`${RE2.set(SEPARATOR_CODE_POINTS)}+`, "~"],
];

// Joins 1-2 digit groups to their neighbours: every `~` next to a short group is removed.
// A leading 1-2 digit group followed by a 3-digit group is first protected with `¦`
// (thousands: 1.500.000.000). Short groups are then marked with `¤`; replace() never overlaps
// matches, and adjacent short groups alternate, so marking runs twice.
const MARK = "\u00a4";
const PROTECT = "\u00a6";
const MERGE_STEPS = [
  [`(^~?|[^~${N}]~?)(${N}{1,2})~(${N}{3}(?:[^${N}]|$))`, `$1$2${PROTECT}$3`],
  [`(^|[^${N}${MARK}])(${N}{1,2})([^${N}]|$)`, `$1${MARK}$2$3`],
  [`(^|[^${N}${MARK}])(${N}{1,2})([^${N}]|$)`, `$1${MARK}$2$3`],
  [`~?${MARK}(${N}{1,2})~?`, "$1"],
];

const PHONE_ALTERNATIVES = buildPhoneSource();

/** One RE2 pattern per phone family (each must stay under the rules' 4096-character limit). */
function rulesPhonePatterns() {
  return PHONE_ALTERNATIVES.map((alt) => `(?s)^(?:.*[^\\p{N}])?${alt}(?:[^\\p{N}].*)?$`);
}

// Messaging and social links, with or without scheme and www.
const LINK_DOMAINS = [
  "t.me", "telegram.me", "telegram.dog", "wa.me", "api.whatsapp.com", "chat.whatsapp.com",
  "whatsapp.com/send", "instagram.com", "instagr.am", "facebook.com", "fb.me", "fb.com", "m.me",
  "snapchat.com", "tiktok.com", "x.com", "twitter.com", "linkedin.com/in",
];
const LINK_SOURCE = `(?:https?://)?(?:www[.])?(?:${LINK_DOMAINS.map((d) => d.replace(/\./g, "[.]")).join("|")})`;
const LINK_BEFORE_CHARS = "A-Za-z0-9.@-";
const LINK_AFTER_CHARS = "A-Za-z0-9-";
// @handle at the start of the text or after a space or opening bracket/quote (not an email).
const HANDLE_BEFORE = RE2.set([...SPACE_CODE_POINTS, 0x28, 0x5b, 0x7b, 0x22, 0x27]);
const HANDLE_SOURCE = "@[A-Za-z][A-Za-z0-9._]{2,}";

function rulesLinkPatterns() {
  return [
    `(?si)^(?:.*[^${LINK_BEFORE_CHARS}])?${LINK_SOURCE}(?:[^${LINK_AFTER_CHARS}].*)?$`,
    `(?s)^(?:.*${HANDLE_BEFORE})?${HANDLE_SOURCE}.*$`,
  ];
}

const escapeRulesLiteral = (pattern) => pattern.replace(/\\/g, "\\\\");

// RE2 and JS (with the `u` flag) agree on everything used above except the \x{...} escape.
const toJs = (re2) => re2.replace(/\\x\{/g, "\\u{");

const JS_NORMALIZE_STEPS = NORMALIZE_STEPS.map(([pattern, replacement]) => [new RegExp(toJs(pattern), "gud"), replacement]);
const JS_MERGE_STEPS = MERGE_STEPS.map(([pattern, replacement]) => [new RegExp(toJs(pattern), "gud"), replacement]);
const PHONE_PATTERN = new RegExp(`(?<!\\p{N})(?:${PHONE_ALTERNATIVES.map(toJs).join("|")})(?!\\p{N})`, "gu");
const LINK_PATTERN = new RegExp(`(?<![${LINK_BEFORE_CHARS}])${LINK_SOURCE}(?![${LINK_AFTER_CHARS}])\\S*`, "giu");
const HANDLE_PATTERN = new RegExp(`(?<=^|${toJs(HANDLE_BEFORE)})${HANDLE_SOURCE}`, "gu");

/**
 * Text with the original [start, end) span behind each UTF-16 unit, so a match found after
 * normalization can be removed from the text exactly as written.
 */
function mappedText(text) {
  const starts = [];
  const ends = [];
  for (let i = 0; i < text.length; i += 1) {
    starts.push(i);
    ends.push(i + 1);
  }
  return { text, starts, ends };
}

/** String.replace() on mapped text; `$n` group copies keep their source spans. */
function mappedReplace(source, regex, replacement) {
  const tokens = replacement.match(/\$\d|[^$]/g) || [];
  let text = "";
  const starts = [];
  const ends = [];
  let cursor = 0;
  const copy = (from, to) => {
    text += source.text.slice(from, to);
    starts.push(...source.starts.slice(from, to));
    ends.push(...source.ends.slice(from, to));
  };
  for (const match of source.text.matchAll(regex)) {
    const matchEnd = match.index + match[0].length;
    copy(cursor, match.index);
    const spanStart = source.starts[match.index];
    const spanEnd = matchEnd > match.index ? source.ends[matchEnd - 1] : spanStart;
    for (const token of tokens) {
      if (token.length === 2) {
        const indices = match.indices[Number(token[1])];
        if (indices) copy(indices[0], indices[1]);
      } else {
        text += token;
        starts.push(spanStart);
        ends.push(spanEnd);
      }
    }
    cursor = matchEnd;
  }
  copy(cursor, source.text.length);
  return { text, starts, ends };
}

/** The two views the phone shapes are matched on: separators collapsed, and short groups merged. */
function phoneViews(text) {
  let collapsed = mappedText(text);
  for (const [regex, replacement] of JS_NORMALIZE_STEPS) collapsed = mappedReplace(collapsed, regex, replacement);
  let merged = collapsed;
  for (const [regex, replacement] of JS_MERGE_STEPS) merged = mappedReplace(merged, regex, replacement);
  return [collapsed, merged];
}

/** [start, end) spans of `text` that hold a phone number, as the rules would see it. */
function phoneSpans(text) {
  const spans = [];
  for (const view of phoneViews(text)) {
    for (const match of view.text.matchAll(PHONE_PATTERN)) {
      let start = view.starts[match.index];
      const end = view.ends[match.index + match[0].length - 1];
      // Take an opening parenthesis around the area code along: "(050) 123 4567".
      while (start > 0 && /[\s(（]/u.test(text[start - 1]) && text.slice(0, start).trimEnd().endsWith("(")) start -= 1;
      spans.push([start, end]);
    }
  }
  return spans;
}

module.exports = {
  PHONE_PATTERN,
  LINK_PATTERN,
  HANDLE_PATTERN,
  EXTRA_DIGIT_VALUES,
  NORMALIZE_STEPS,
  MERGE_STEPS,
  phoneSpans,
  phoneViews,
  rulesPhonePatterns,
  rulesLinkPatterns,
  escapeRulesLiteral,
};
