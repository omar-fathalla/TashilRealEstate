/**
 * Stricter contact detection for the text a person types into a request (viewing or rental
 * request message, and the requester name). TAQ-133.
 *
 * It adds to the shared containsContact() (phones, emails, messaging links, @handles) the
 * circumventions that need a person to type deliberately: digits spelled out as words, an email
 * written with spaces or the words "at" and "dot", and generic links. It is used only by the
 * request callables: those reject the text and keep nothing, so a rare false positive costs one
 * retry. The marketplace sanitizer and firestore.rules keep the shared patterns unchanged, and
 * the false-positive corpus for listings is not touched.
 */
const { containsContact, foldForContactMatching } = require("./contact_filter");

const DIGIT_WORDS = new Map([
  ["zero", 0], ["oh", 0], ["one", 1], ["two", 2], ["three", 3], ["four", 4], ["five", 5], ["six", 6], ["seven", 7], ["eight", 8], ["nine", 9],
  ["صفر", 0], ["واحد", 1], ["واحدة", 1], ["اثنين", 2], ["اتنين", 2], ["اثنان", 2], ["ثلاثة", 3], ["ثلاث", 3], ["تلاتة", 3], ["اربعة", 4], ["أربعة", 4], ["اربع", 4], ["أربع", 4],
  ["خمسة", 5], ["خمس", 5], ["ستة", 6], ["سته", 6], ["ست", 6], ["سبعة", 7], ["سبع", 7], ["ثمانية", 8], ["تمانية", 8], ["ثمان", 8], ["ثماني", 8], ["تسعة", 9], ["تسع", 9],
  ["शून्य", 0], ["जीरो", 0], ["एक", 1], ["दो", 2], ["तीन", 3], ["चार", 4], ["पांच", 5], ["पाँच", 5], ["छह", 6], ["छः", 6], ["छे", 6], ["सात", 7], ["आठ", 8], ["नौ", 9],
]);

// A run of spelled-out digits (and digit groups between them) this long is a phone number: the
// shortest number a request accepts has 7 digits.
const MIN_SPELLED_DIGITS = 7;

function tokens(text) {
  return text.toLowerCase().split(/[\s\-_.,;:|/\\()[\]{}'"!?،؛]+/u).filter(Boolean);
}

/** True when a run of digit words and digit groups adds up to a phone-length number. */
function hasSpelledOutNumber(text) {
  let words = 0;
  let digits = 0;
  const finish = () => {
    const found = words >= 2 && digits >= MIN_SPELLED_DIGITS;
    words = 0;
    digits = 0;
    return found;
  };
  for (const raw of tokens(foldForContactMatching(text).folded)) {
    if (DIGIT_WORDS.has(raw)) {
      words += 1;
      digits += 1;
    } else if (/^[0-9]{1,4}$/.test(raw) && words > 0) {
      digits += raw.length;
    } else if (finish()) {
      return true;
    }
  }
  return finish();
}

const TLDS = "com|net|org|info|biz|co|io|me|ae|eg|app|online|site|xyz|ly|gl|us|uk|in|sa|qa|kw|edu|gov";
const SP = String.raw`[\s\u00a0\u2000-\u200f\u2028\u2029\u202f\u3000\ufeff]*`;
const SP1 = String.raw`[\s\u00a0\u2000-\u200f\u2028\u2029\u202f\u3000\ufeff]+`;
const LABEL = "[a-z0-9-]+";
// name @ host . tld, with spaces around the @ and the dot, or the word "dot"; a real @ or the
// words "at" ... "dot" are required, and the ending must be a real top-level domain.
const SPACED_EMAIL = new RegExp(
  `[a-z0-9._%+-]+${SP}(?:[@＠﹫]|[\\[({]${SP}at${SP}[\\])}])${SP}${LABEL}(?:(?:${SP}\\.${SP}|${SP1}dot${SP1}|${SP}[\\[({]${SP}dot${SP}[\\])}]${SP})${LABEL})*(?:${SP}\\.${SP}|${SP1}dot${SP1}|${SP}[\\[({]${SP}dot${SP}[\\])}]${SP})(?:${TLDS})(?![a-z0-9])`,
  "iu",
);
const WORD_EMAIL = new RegExp(
  `[a-z0-9._%+-]+${SP1}at${SP1}${LABEL}(?:${SP1}dot${SP1}${LABEL})*${SP1}dot${SP1}(?:${TLDS})(?![a-z0-9])`,
  "iu",
);
const GENERIC_LINK = /(?:\bhttps?:\/\/|\bwww\s*\.\s*[a-z0-9-]|\bftp:\/\/)/iu;
const BARE_DOMAIN = new RegExp(`(?<![a-z0-9@.-])[a-z0-9][a-z0-9-]*(?:\\.[a-z0-9-]+)*\\.(?:${TLDS})(?![a-z0-9-])`, "iu");

function hasLooseEmailOrLink(text) {
  const { folded } = foldForContactMatching(text);
  return SPACED_EMAIL.test(folded) || WORD_EMAIL.test(folded) || GENERIC_LINK.test(folded) || BARE_DOMAIN.test(folded);
}

/** True when request text hides a contact: everything containsContact() finds, plus the loose forms. */
function containsContactInRequestText(text) {
  if (typeof text !== "string" || text === "") return false;
  return containsContact(text) || hasSpelledOutNumber(text) || hasLooseEmailOrLink(text);
}

module.exports = { containsContactInRequestText, hasSpelledOutNumber, hasLooseEmailOrLink };
