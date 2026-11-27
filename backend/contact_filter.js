/**
 * Contact detection shared by the marketplace sanitizer (index.js, which removes contacts from a
 * listing) and the request callables (requests.js, which reject them). TAQ-117.
 */
const { phoneSpans, linkSpans, EXTRA_DIGIT_VALUES } = require("./contact_patterns");

// Mirrored by contactFree() in firestore.rules. Phones, messaging links and @handles use the
// shared patterns in contact_patterns.js. Emails are matched after folding look-alike
// characters (full-width forms, invisible characters). Only the matched span is removed and
// other text is left exactly as written.
//  - Email: @ may be written [at], (at), {at}, or with spaces around it; dots may be [dot].
const EMAIL_AT = String.raw`\s*(?:@|[\[({]\s*at\s*[\])}])\s*`;
const EMAIL_DOT = String.raw`(?:\.|\s*[\[({]\s*dot\s*[\])}]\s*)`;
const EMAIL_LABEL = "[A-Za-z0-9-]+";
const EMAIL_PATTERN = new RegExp(
  `[A-Za-z0-9._%+-]+${EMAIL_AT}${EMAIL_LABEL}(?:${EMAIL_DOT}${EMAIL_LABEL})*${EMAIL_DOT}[A-Za-z]{2,}`,
  "gi",
);
const INVISIBLE = /^\p{Cf}$/u;
const DECIMAL_DIGIT = /^\p{Nd}$/u;

function isDecimalDigit(codePoint) {
  return codePoint >= 0 && DECIMAL_DIGIT.test(String.fromCodePoint(codePoint));
}

/** The ASCII digit value of any decimal digit (Devanagari, Arabic-Indic, styled, ...), or -1. */
function digitValue(codePoint) {
  if (EXTRA_DIGIT_VALUES.has(codePoint)) return EXTRA_DIGIT_VALUES.get(codePoint);
  if (!isDecimalDigit(codePoint)) return -1;
  let start = codePoint;
  while (isDecimalDigit(start - 1)) start -= 1;
  return (codePoint - start) % 10;
}

function foldCodePoint(ch) {
  if (INVISIBLE.test(ch)) return " ";
  const value = digitValue(ch.codePointAt(0));
  if (value >= 0) return String(value);
  const normalized = ch.normalize("NFKC");
  if (normalized.length === 1 && normalized.charCodeAt(0) < 0x80) return normalized;
  // One UTF-16 unit per code point keeps folded offsets aligned with `offsets` below.
  return ch.length === 1 ? ch : "\uFFFD";
}

/** One folded UTF-16 unit per code point of `text`, plus the original offset of each. */
function foldForContactMatching(text) {
  let folded = "";
  const offsets = [];
  let index = 0;
  for (const ch of text) {
    offsets.push(index);
    folded += foldCodePoint(ch);
    index += ch.length;
  }
  offsets.push(text.length);
  return { folded, offsets };
}

function removeSpans(text, spans) {
  if (spans.length === 0) return text;
  let result = "";
  let cursor = 0;
  for (const [start, end] of [...spans].sort((a, b) => a[0] - b[0])) {
    if (end <= cursor) continue;
    result += text.slice(cursor, Math.max(cursor, start));
    cursor = end;
  }
  return result + text.slice(cursor);
}

function matchSpans(text, pattern) {
  return [...text.matchAll(pattern)].map((m) => [m.index, m.index + m[0].length]);
}

function removeEmails(text) {
  const { folded, offsets } = foldForContactMatching(text);
  return removeSpans(text, matchSpans(folded, EMAIL_PATTERN).map(([start, end]) => [offsets[start], offsets[end]]));
}

function removeLinks(text) {
  return removeSpans(text, linkSpans(text));
}

function stripContacts(text) {
  let current = text;
  // Removing a contact can join the text around it into a new one, so repeat until stable.
  for (let pass = 0; pass < 4; pass += 1) {
    const cleaned = removeLinks(removeEmails(removeSpans(current, phoneSpans(current))));
    if (cleaned === current) break;
    current = cleaned;
  }
  return current;
}

function hasEmail(text) {
  const { folded } = foldForContactMatching(text);
  return matchSpans(folded, EMAIL_PATTERN).length > 0;
}

/** True when `text` holds a phone number, an email, a messaging link or an @handle. */
function containsContact(text) {
  if (typeof text !== "string" || text === "") return false;
  return phoneSpans(text).length > 0 || linkSpans(text).length > 0 || hasEmail(text);
}

/** Which kind of contact containsContact() finds first: "phone", "link", "email", or "" (TAQ-208). */
function contactKind(text) {
  if (typeof text !== "string" || text === "") return "";
  if (phoneSpans(text).length > 0) return "phone";
  if (linkSpans(text).length > 0) return "link";
  return hasEmail(text) ? "email" : "";
}

module.exports = { stripContacts, containsContact, contactKind, foldForContactMatching };
