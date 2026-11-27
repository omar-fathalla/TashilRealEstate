// TAQ-133: the stricter contact check for request text (message and requester name).
const test = require("node:test");
const assert = require("node:assert/strict");
const { containsContactInRequestText, hasSpelledOutNumber } = require("../request_text_filter");
const { containsContact } = require("../contact_filter");
const LISTING_CORPUS = require("./fixtures/listing_number_corpus");

const LOOSE_CONTACTS = [
  "zero five zero one two three four five six seven",
  "call me zero five zero 123 4567",
  "Oh Five Oh - one two three - four five six seven",
  "qa @ example . com",
  "qa@example dot com",
  "qa at example dot com",
  "qa [at] example [dot] co",
  "see https://example.org/flat",
  "www.example.com",
  "www . example",
  "write to example.com",
  "QA qa.user@example.com 0501234567",
  "صفر خمسة صفر واحد اثنين ثلاثة اربعة خمسة ستة",
  "शून्य पांच शून्य एक दो तीन चार पांच छह",
];

const CLEAN = [
  "After 6pm",
  "Saturday 5pm please",
  "Family of 3, moving in on 2026-07-01",
  "I need two bedrooms and one bathroom",
  "one two three please",
  "see you @ home . Thanks",
  "Meet at noon. Dot",
  "Is the unit on the 5th floor with 2 bedrooms?",
  "I will arrive at 5 pm. Com on in",
  "at the .net framework meeting",
  "e.g. 3 bedrooms, a.m. visit",
  "Rent is 15,000 and the deposit is one two",
  "أفضل موعد مساء السبت",
  "मैं शनिवार को आ सकता हूँ",
  "Ahmed Ali",
  "",
];

test("TAQ-133: spelled-out digits, spaced or worded emails, generic links and bare domains are contacts", () => {
  for (const text of LOOSE_CONTACTS) assert.equal(containsContactInRequestText(text), true, text);
});

test("TAQ-133: the shared contact filter is unchanged (those forms are not in the listing patterns)", () => {
  assert.equal(containsContact("qa@example dot com"), false);
  assert.equal(containsContact("www.example.com"), false);
});

test("TAQ-133: everything the shared filter rejects is still rejected", () => {
  for (const text of ["call 0501234567", "+971 50 123 4567", "owner@example.com", "wa.me/971501234567", "@someone_99"]) {
    assert.equal(containsContactInRequestText(text), true, text);
  }
});

test("TAQ-133: ordinary messages, dates, prices and short digit words are not flagged", () => {
  for (const text of CLEAN) assert.equal(containsContactInRequestText(text), false, text);
  assert.equal(containsContactInRequestText(undefined), false);
  assert.equal(containsContactInRequestText(42), false);
});

test("TAQ-133: a short run of digit words is not a phone number", () => {
  assert.equal(hasSpelledOutNumber("one two three four five six"), false);
  assert.equal(hasSpelledOutNumber("one two three four five six seven"), true);
});

// --- TAQ-166 / TAQ-167 ---

test("TAQ-166: a missing space after a full stop is not a domain", () => {
  for (const text of [
    "I liked the photos.In the evening I can visit",
    "Please call back later.Me and my wife are free",
    "We are a family.Co-signer available? we can bring one.Co",
    "Let me know.Us two are students",
  ]) {
    assert.equal(containsContactInRequestText(text), false, text);
  }
  // Lowercase or all-caps endings, or a path, are still domains.
  for (const text of ["write to example.com", "EXAMPLE.COM", "see Example.Com/flat", "photos.in"]) {
    assert.equal(containsContactInRequestText(text), true, text);
  }
});

test("TAQ-167: Egyptian spellings, bracketed dots, worded and spaced bare domains and joined digit words are contacts", () => {
  for (const text of [
    "صفر واحد صفر خمسه تلاته اربعه سته سبعه تمانيه تسعه",
    "واحده اتنين تلات اربعه خمسه سته سبعه",
    "qa@example (.) com",
    "qa@example [.] com",
    "example dot com",
    "example (dot) com",
    "example (.) com",
    "example . com",
    "zerofivezeroonetwothreefourfivesix",
  ]) {
    assert.equal(containsContactInRequestText(text), true, text);
  }
  for (const text of ["someone told me", "nineteen people", "فيه خمسه أشخاص", "انا جاي الساعه تسعه", "at the .net framework meeting", "Meet at noon. Dot"]) {
    assert.equal(containsContactInRequestText(text), false, text);
  }
});

test("TAQ-133: no false positives on the listing corpus (same verdict as the shared filter)", () => {
  for (const row of Object.values(LISTING_CORPUS)) {
    assert.equal(containsContactInRequestText(row), containsContact(row), row);
  }
});
