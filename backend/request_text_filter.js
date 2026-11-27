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
  ["تلات", 3], ["تلاث", 3], ["تمان", 8], ["تماني", 8],
  ["शून्य", 0], ["जीरो", 0], ["एक", 1], ["दो", 2], ["तीन", 3], ["चार", 4], ["पांच", 5], ["पाँच", 5], ["छह", 6], ["छः", 6], ["छे", 6], ["सात", 7], ["आठ", 8], ["नौ", 9],
]);

// A run of spelled-out digits (and digit groups between them) this long is a phone number: the
// shortest number a request accepts has 7 digits.
const MIN_SPELLED_DIGITS = 7;

function tokens(text) {
  return text.toLowerCase().split(/[\s\-_.,;:|/\\()[\]{}'"!?،؛]+/u).filter(Boolean);
}

// Egyptian spelling ends these words with ه where the dictionary has ة (خمسه, تلاته, تمانيه):
// fold a final ه to ة before the lookup (TAQ-167).
const foldTaMarbuta = (word) => word.replace(/ه$/u, "ة");

const ENGLISH_DIGIT_WORDS = [...DIGIT_WORDS.keys()].filter((w) => /^[a-z]+$/.test(w));

/** How many English digit words a token is made of when written with no spaces ("zerofive"), or 0. */
function joinedDigitWords(token) {
  if (!/^[a-z]{4,}$/.test(token)) return 0;
  const best = new Array(token.length + 1).fill(-1);
  best[0] = 0;
  for (let i = 0; i < token.length; i += 1) {
    if (best[i] < 0) continue;
    for (const word of ENGLISH_DIGIT_WORDS) {
      if (token.startsWith(word, i) && best[i] + 1 > best[i + word.length]) best[i + word.length] = best[i] + 1;
    }
  }
  return best[token.length] >= 2 ? best[token.length] : 0;
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
    const joined = joinedDigitWords(raw);
    if (DIGIT_WORDS.has(raw) || DIGIT_WORDS.has(foldTaMarbuta(raw))) {
      words += 1;
      digits += 1;
    } else if (joined) {
      words += joined;
      digits += joined;
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
// A dot written as ".", " dot ", "(dot)" or "(.)" (TAQ-167), each with optional spaces.
const DOT = `(?:${SP}\\.${SP}|${SP1}dot${SP1}|${SP}[\\[({]${SP}(?:dot|\\.)${SP}[\\])}]${SP})`;
// name @ host . tld, with spaces around the @ and the dot, or the word "dot"; a real @ or the
// words "at" ... "dot" are required, and the ending must be a real top-level domain.
const SPACED_EMAIL = new RegExp(
  `[a-z0-9._%+-]+${SP}(?:[@＠﹫]|[\\[({]${SP}at${SP}[\\])}])${SP}${LABEL}(?:${DOT}${LABEL})*${DOT}(?:${TLDS})(?![a-z0-9])`,
  "iu",
);
const WORD_EMAIL = new RegExp(
  `[a-z0-9._%+-]+${SP1}at${SP1}${LABEL}(?:${SP1}dot${SP1}${LABEL})*${SP1}dot${SP1}(?:${TLDS})(?![a-z0-9])`,
  "iu",
);
const GENERIC_LINK = /(?:\bhttps?:\/\/|\bwww\s*\.\s*[a-z0-9-]|\bftp:\/\/)/iu;
const BARE_DOMAIN = new RegExp(`(?<![a-z0-9@.-])[a-z0-9][a-z0-9-]*(?:\\.[a-z0-9-]+)*\\.(${TLDS})(?![a-z0-9-])(/)?`, "giu");
// A bare domain without an @ written with a spelled or bracketed dot, or a dot with spaces on
// both sides: "example dot com", "example (.) com", "example . com" (TAQ-167).
const WORDED_DOMAIN = new RegExp(
  `(?<![a-z0-9-])${LABEL}(?:${SP1}dot${SP1}|${SP}[\\[({]${SP}(?:dot|\\.)${SP}[\\])}]${SP}|${SP1}\\.${SP1})(${TLDS})(?![a-z0-9-])`,
  "giu",
);

// "photos.In the evening": a missing space after a full stop puts a capitalised word where a
// TLD would be. A capitalised TLD (In, Me, Co) is read as a sentence, unless a path follows;
// lowercase and all-caps TLDs are still domains (TAQ-166).
const isSentenceStart = (tld) => /^[A-Z][a-z]+$/.test(tld);

function hasDomain(folded, pattern) {
  for (const m of folded.matchAll(pattern)) {
    if (m[2] === "/" || !isSentenceStart(m[1])) return true;
  }
  return false;
}

function hasLooseEmailOrLink(text) {
  const { folded } = foldForContactMatching(text);
  return (
    SPACED_EMAIL.test(folded) ||
    WORD_EMAIL.test(folded) ||
    GENERIC_LINK.test(folded) ||
    hasDomain(folded, BARE_DOMAIN) ||
    hasDomain(folded, WORDED_DOMAIN)
  );
}

/** True when request text hides a contact: everything containsContact() finds, plus the loose forms. */
function containsContactInRequestText(text) {
  if (typeof text !== "string" || text === "") return false;
  return containsContact(text) || hasSpelledOutNumber(text) || hasLooseEmailOrLink(text);
}

module.exports = { containsContactInRequestText, hasSpelledOutNumber, hasLooseEmailOrLink };
