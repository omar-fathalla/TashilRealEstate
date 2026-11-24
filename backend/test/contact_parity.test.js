const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, setDoc } = require("firebase/firestore");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-tashil-test";
const { sanitizeForMarketplace } = require("../index");

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT,
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
});

function styled(digits, zeroCodePoint) {
  return [...digits].map((d) => String.fromCodePoint(zeroCodePoint + Number(d))).join("");
}

// TAQ-56: every entry hides a phone number or an email address.
const CONTACTS = [
  // Phones: the earlier forms still count.
  "Call 0501234567",
  "Call +971 50 123 4567",
  "Flat (050) 123-4567",
  "رقمي ٠١٠٠١٢٣٤٥٦٧",
  "संपर्क ۰۵۰۱۲۳۴۵۶۷۸",
  // Phones with no leading zero, and country codes without +.
  "Call 1012345678",
  "Call 1112345678",
  "Call 201012345678",
  "Call 2010 1234 5678",
  "WhatsApp 971501234567",
  "Call 971 50 123 4567",
  // Separators: wide, slash, underscore, backslash, dashes, dots.
  "Call 0100\u3000123\u30004567",
  "Call 0100\u00A0123\u00A04567",
  "Call 0100/123/4567",
  "Call 0100_123_4567",
  "Call 0100\\123\\4567",
  "Call 0100\u2013123\u20134567",
  "Call 0100.123.4567",
  // Full-width digits, and the letter O in place of zero.
  "Call ０１０１２３４５６７８",
  "Call ＋２０１０１２３４５６７８",
  "Call O1O12345678",
  "Call 01OO1234567",
  "Call 0O1O123456",
  // Invisible characters inside the number, and numbers on a later line.
  "Call 0100\u200B123\u200B4567",
  "Intro line\nCall 0501234567",
  // TAQ-56 (N-5): a dash with spaces around it is one separator, and so are similar spaced ones.
  "Tel: 010 - 1234 - 5678",
  "Tel: 010 \u2013 1234 \u2013 5678",
  "Tel: 010 . 1234 . 5678",
  "Tel: 010 / 1234 / 5678",
  "Tel: 0100 - 123 - 4567",
  "Call +971 - 50 - 123 - 4567",
  "Call 050 - 123 - 4567",
  "Call 0100 -- 123 -- 4567",
  "Call ( 050 ) 123 - 4567",
  // TAQ-59: phone shapes without a trunk zero, and the phone next to ordinary words.
  "Call 01012345678 or email",
  "Boo 0501234567 Too",
  "Call 501234567",
  "Call 2010 1234 5678",
  "Call 00971 50 123 4567",
  "Call 00201012345678",
  // TAQ-60: digits of other scripts, styled digits, newline separators, circled digits.
  "संपर्क ०५०१२३४५६७८ अभी",
  "Call ०५० १२३ ४५६७",
  `Call ${styled("0501234567", 0x1d7ce)}`,
  `Call ${styled("0501234567", 0x1d7d8)}`,
  `Call ${styled("0501234567", 0x1d7e2)}`,
  `Call ${styled("01012345678", 0x1d7ec)}`,
  `Call ${styled("01012345678", 0x1d7f6)}`,
  "Call 0501\n234567",
  "Call 0100\n123\n4567",
  "Call 0100\r\n123\r\n4567",
  "Call ⓪⑤⓪①②③④⑤⑥⑦",
  "Call ①⓪①②③④⑤⑥⑦⑧",
  // Emails.
  "Mail owner@example.com",
  "Mail owner [at] example.com",
  "Mail owner (at) example.com",
  "Mail owner{at}example.com",
  "Mail owner [AT] example [dot] com",
  "Mail owner (at) example (dot) com",
  "Mail owner＠example.com",
  "Mail ｏｗｎｅｒ＠ｅｘａｍｐｌｅ．ｃｏｍ",
  "Mail owner @ example.com",
  "Mail owner\u3000@\u3000example.com",
  "Mail owner @example.co.uk",
  "Mail owner@ example.com",
  "Intro line\nMail owner@example.com",
];

// Ordinary listing text must stay as written.
const CLEAN = [
  "Price 15000000 EGP",
  "15000000",
  "Spacious 3 bedroom flat, 1200 sqm, floor 12",
  "Unit 1405, building 2, 150 m2",
  "Rent 15,000,000 EGP per year",
  "Rent 15 000 000 EGP per year",
  "Available from 2026-11-23",
  "Built in 2019, renovated 2024",
  "Parking for 2 cars, 4 minutes to the metro",
  "Open 9 - 5, call the office",
  "Room 101 on level 3, tower B",
  "Foo Boo Zoo Moo Too",
  "Price 500 000 EGP, deposit 50 000",
  "Meet @ the entrance at 5pm",
  "Valid until 12/31/2026",
  "شقة واسعة بسعر ١٥٠٠٠٠٠٠ جنيه",
  "सुंदर फ्लैट, क्षेत्रफल 1200 वर्ग मीटर",
  "Email us through the platform (at your convenience)",
  "0123456 sqm", // 7 digits
  "Ref 12345678", // 8 digits
  // TAQ-59: lists of dates, years, and numbers are not one phone number.
  "Available 2026-01-15 2026-06-30",
  "Lease 1/1/2026 31/12/2026",
  "3 2 120 15000",
  "Year 2015 2016 2017",
  "Price 1.500.000.000 EGP",
  "Studio 100 000 000",
  "Zoo 15000000 EGP",
  "15,000,000",
  "15.000.000",
  "1,500,000,000 AED",
  "Area 120 130 140 150",
  "Built 2015, 2016, 2017 and 2018",
  "Floors 1 2 3 4 5 6 7 8 9",
  "Rooms 3 4 5 6 and 150 200 250",
  "२०२६-०१-१५ से उपलब्ध",
  "Date 15/01/2026 to 30/06/2026",
  "Tel: 010 - 12",
];

function listingWith(extra) {
  return {
    id: "prop-1",
    owner_id: "owner",
    countryCode: "AE",
    currencyCode: "AED",
    titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" },
    pricePerMonth: 9000,
    status: "vacant",
    is_published: true,
    ...extra,
  };
}

async function rejected(ref, data, label) {
  try {
    await assertFails(setDoc(ref, data));
  } catch (err) {
    assert.fail(`the rules accepted ${label}`);
  }
}

function root() {
  return testEnv.authenticatedContext("root", { role: "SuperAdmin" }).firestore();
}

function sanitized(text) {
  return sanitizeForMarketplace({ pricePerMonth: 9000, buildingName: text }, "owner", "prop-1").buildingName;
}

test("TAQ-56: the sanitizer removes every obfuscated phone number and email", () => {
  for (const text of CONTACTS) {
    const out = sanitized(text);
    assert.notEqual(out, text.trim(), `not stripped: ${JSON.stringify(text)}`);
    assert.doesNotMatch(out, /\p{N}{4}|@|\[at\]|\(at\)/iu, `left behind: ${JSON.stringify(text)} -> ${JSON.stringify(out)}`);
    assert.ok(out.length < text.length, `not shortened: ${JSON.stringify(text)}`);
  }
});

test("TAQ-56: the sanitizer leaves prices, areas, and ordinary text untouched", () => {
  for (const text of CLEAN) {
    assert.equal(sanitized(text), text.trim(), JSON.stringify(text));
  }
});

test("TAQ-56: the rules reject every obfuscated phone number and email", async () => {
  const ref = doc(root(), "Properties/prop-1");
  for (const text of CONTACTS) {
    await rejected(ref, listingWith({ buildingName: text }), JSON.stringify(text));
    await rejected(ref, listingWith({ descriptions: { ar: "وصف", en: text, hi: "विवरण" } }), JSON.stringify(text));
  }
});

test("TAQ-56: the rules accept prices, areas, and ordinary text", async () => {
  const ref = doc(root(), "Properties/prop-1");
  for (const text of CLEAN) {
    await assertSucceeds(setDoc(ref, listingWith({ buildingName: text })), JSON.stringify(text));
    await assertSucceeds(setDoc(ref, listingWith({ descriptions: { ar: "وصف", en: text, hi: "विवरण" } })), JSON.stringify(text));
  }
});

test("TAQ-56: sanitizer output is always accepted by the rules", async () => {
  const ref = doc(root(), "Properties/prop-1");
  for (const text of CONTACTS) {
    await assertSucceeds(setDoc(ref, listingWith({ buildingName: sanitized(text) })), JSON.stringify(text));
  }
});

test("TAQ-56: digits in separate fields are not joined into a phone number", async () => {
  const ref = doc(root(), "Properties/prop-1");
  await assertSucceeds(setDoc(ref, listingWith({
    titles: { ar: "12345", en: "67890", hi: "12345" },
    buildingName: "67890",
    cityCode: "1",
    propertyTypeCode: "23456789",
  })));
});

test("TAQ-59: only the phone number is removed, never the letters next to it", () => {
  assert.equal(sanitized("Call 01012345678 or email"), "Call  or email");
  assert.equal(sanitized("Boo 0501234567 Too"), "Boo  Too");
  assert.equal(sanitized("Zoo 15000000 EGP"), "Zoo 15000000 EGP");
  assert.equal(sanitized("Call O1O12345678 now"), "Call O now");
  assert.equal(sanitized("Tel: 010 - 1234 - 5678"), "Tel:");
  assert.equal(sanitized("Studio 100 000 000 Zoo"), "Studio 100 000 000 Zoo");
});

test("TAQ-60: digits of any script are matched like ASCII digits in the sanitizer and the rules", async () => {
  const ref = doc(root(), "Properties/prop-1");
  const variants = [
    "०५०१२३४५६७८",
    styled("0501234567", 0x1d7ce),
    styled("0501234567", 0x1d7d8),
    styled("0501234567", 0x1d7e2),
    styled("0501234567", 0x1d7ec),
    styled("0501234567", 0x1d7f6),
    "০৫০১২৩৪৫৬৭৮",
    "๐๕๐๑๒๓๔๕๖๗",
  ];
  for (const digits of variants) {
    const text = `Call ${digits} now`;
    assert.equal(sanitized(text), "Call  now", JSON.stringify(text));
    await rejected(ref, listingWith({ buildingName: text }), JSON.stringify(text));
  }
});

test("TAQ-60: a number split by newlines or circled digits is rejected by the rules too", async () => {
  const ref = doc(root(), "Properties/prop-1");
  for (const text of ["Call 0501\n234567", "Call 0100\n123\n4567", "Call ⓪⑤⓪①②③④⑤⑥⑦"]) {
    assert.notEqual(sanitized(text), text);
    await rejected(ref, listingWith({ buildingName: text }), JSON.stringify(text));
  }
});
