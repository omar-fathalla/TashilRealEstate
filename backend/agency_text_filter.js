"use strict";

// TAQ-201: the stricter check for an agency's own name and about text. It runs the request filter
// (request_text_filter.js), then also refuses what that filter lets through on purpose because
// tenants write it in ordinary sentences, but an agency name has no need for:
//   - any word ending in a dot and two or more Latin letters with no space after the dot
//     ("x.shop", "x.Me", "x .com", "x。com"), or a dot spaced on both sides ("x . com");
//   - a spelled-out phone that mixes single digits and digit words, or joins them with '+', '/',
//     '×' or '*' ("0 five 0 one 2 three 4", "zero+five+...");
//   - Arabic digit words written with hamza or alef-maqsura ("أثنين", "ثمانى").
// firestore.rules (agencyTextFree) mirrors the same checks for direct Agencies/{id} writes.

const { foldForContactMatching } = require("./contact_filter");
const { containsContactInRequestText, DIGIT_WORDS, foldTaMarbuta } = require("./request_text_filter");

const MIN_SPELLED_DIGITS = 7;

/** Unicode full stops to '.', Arabic alef/yaa variants to their plain letter, harakat and tatweel removed. */
function normaliseAgencyText(text) {
  return foldForContactMatching(String(text).normalize("NFKC")).folded
    .replace(/[\u3002\uff61\ufe52\uff0e\u2024]/gu, ".")
    .replace(/[\u064b-\u065f\u0670\u0640]/gu, "")
    .replace(/[أإآٱ]/gu, "ا")
    .replace(/ى/gu, "ي");
}

// A Latin ending of 2+ letters straight after a dot ("x.shop", "x .com"), or after a dot spaced on
// both sides ("x . com"). "Marina. Commercial", "L.L.C", "Ph.D" and "3.5" stay allowed.
const AGENCY_DOMAIN = /[\p{L}\p{N}-](?:\.|\s+\.\s+|\s+\.)[a-z]{2,}(?!\p{L})/iu;

const SEPARATORS = /[\s\-_.,;:|/\\()[\]{}'"!?،؛+×*]+/u;

// After normaliseAgencyText: "أثنين" is "اثنين" and "ثمانى" is "ثماني", both in DIGIT_WORDS.
const digitWord = (token) => DIGIT_WORDS.has(token) || DIGIT_WORDS.has(foldTaMarbuta(token));

/** Seven or more digits written as a run of digit words and digits, with at least one word. */
function hasMixedSpelledNumber(text) {
  let words = 0;
  let digits = 0;
  const finish = () => {
    const found = words >= 1 && digits >= MIN_SPELLED_DIGITS;
    words = 0;
    digits = 0;
    return found;
  };
  for (const token of text.toLowerCase().split(SEPARATORS).filter(Boolean)) {
    if (digitWord(token)) {
      words += 1;
      digits += 1;
    } else if (/^[0-9]{1,4}$/.test(token)) {
      digits += token.length;
    } else if (finish()) {
      return true;
    }
  }
  return finish();
}

/** True when an agency name or about text holds a phone, link, email or domain in any form we know. */
function containsContactInAgencyText(text) {
  if (typeof text !== "string" || !text) return false;
  if (containsContactInRequestText(text)) return true;
  const normal = normaliseAgencyText(text);
  return containsContactInRequestText(normal) || AGENCY_DOMAIN.test(normal) || hasMixedSpelledNumber(normal);
}

module.exports = { containsContactInAgencyText, normaliseAgencyText };
