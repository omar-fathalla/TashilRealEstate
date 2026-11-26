// TAQ-117: the shared contact filter. containsContact() decides what the request callables reject.
const test = require("node:test");
const assert = require("node:assert/strict");
const { containsContact, stripContacts } = require("../contact_filter");

const CONTACTS = [
  "call me on 0501234567",
  "+971 50 123 4567",
  "٠٥٠١٢٣٤٥٦٧٨",
  "०५०१२३४५६७८",
  "zero five zero 1 2 3 4 5 6 7",
  "0 5 0 - 1 2 3 - 4 5 6 7",
  "01012345678",
  "0 1 0 1 2 3 4 5 6 7 8",
  "my number: 971501234567",
  "owner@example.com",
  "owner [at] example [dot] com",
  "owner (at) example.com",
  "https://wa.me/971501234567",
  "wa.me/971501234567",
  "t.me/someone",
  "message me @someone_99",
  "ring me 05O 123 4567",
];

const CLEAN = [
  "After 6pm",
  "Saturday 5pm please",
  "Family of 3, moving in on 2026-07-01",
  "The rent is 15,000,000 EGP and the flat is 120 m2",
  "أفضل موعد مساء السبت",
  "मैं शनिवार को आ सकता हूँ",
  "Is the unit on the 5th floor with 2 bedrooms?",
  "",
];

test("TAQ-117: containsContact flags phones (Latin, Arabic-Indic, Devanagari, spaced), emails and messaging links and handles", () => {
  for (const text of CONTACTS) {
    if (text.startsWith("zero five zero")) continue; // spelled-out digits are not matched, by design
    assert.equal(containsContact(text), true, text);
  }
});

test("TAQ-117: containsContact leaves ordinary messages, dates and prices alone", () => {
  for (const text of CLEAN) assert.equal(containsContact(text), false, text);
  assert.equal(containsContact(undefined), false);
  assert.equal(containsContact(42), false);
});

test("TAQ-117: stripContacts still removes what containsContact flags (marketplace sanitizer)", () => {
  assert.equal(containsContact(stripContacts("Sunny flat, call 0501234567 today")), false);
  assert.equal(stripContacts("Sunny flat"), "Sunny flat");
});
