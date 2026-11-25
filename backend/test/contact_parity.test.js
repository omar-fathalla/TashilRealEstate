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
  // A SuperAdmin create needs the owner's private doc, so the creates below reach the contact filter.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "Users/owner/properties/prop-1"), { owner_id: "owner", isPublished: true });
  });
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

const arabicIndic = (text) => text.replace(/[0-9]/g, (d) => String.fromCharCode(0x660 + Number(d)));

// Each entry is checked as written, inside Arabic text, and with Arabic-Indic digits.
function variants(texts) {
  return texts.flatMap((text) => [text, `اتصل ${text} الآن`, arabicIndic(text)]);
}

async function expectCaught(texts) {
  const ref = doc(root(), "Properties/prop-1");
  for (const text of texts) {
    const out = sanitized(text);
    assert.notEqual(out, text.trim(), `not stripped: ${JSON.stringify(text)}`);
    await rejected(ref, listingWith({ buildingName: text }), JSON.stringify(text));
    await assertSucceeds(setDoc(ref, listingWith({ buildingName: out })), `sanitized ${JSON.stringify(text)} -> ${JSON.stringify(out)}`);
  }
}

async function expectFree(texts) {
  const ref = doc(root(), "Properties/prop-1");
  for (const text of texts) {
    assert.equal(sanitized(text), text.trim(), `changed: ${JSON.stringify(text)}`);
    await assertSucceeds(setDoc(ref, listingWith({ buildingName: text })), JSON.stringify(text));
  }
}

test("TAQ-63: phone numbers split into 1-2 digit groups are caught", async () => {
  await expectCaught(variants([
    "0 1 0 1 2 3 4 5 6 7 8",
    "010 12 34 56 78",
    "01 01 23 45 67 8",
    "10 12 34 56 78",
    "050 123 456 7",
    "5 0 1 2 3 4 5 6 7",
    "0 0 2 0 1 0 1 2 3 4 5 6 7 8",
  ]));
  assert.equal(sanitized("Call 010 12 34 56 78 now"), "Call  now");
  assert.equal(sanitized("Call 0 1 0 1 2 3 4 5 6 7 8 now"), "Call  now");
});

test("TAQ-63: prices, dates, years and UAE 3-3-3 groups stay free", async () => {
  await expectFree([
    ...variants([
      "501 234 567",
      "1.500.000.000",
      "100 000 000",
      "15,000,000",
      "15000000",
      "2026-01-15",
      "1/1/2026",
      "15 01 2026",
      "01/01/2026 10:30",
      "2015 2016 2017",
      "3 2 150",
    ]),
    "شقة بسعر ١٥٠٠٠٠٠٠ جنيه",
    "الإيجار ١٬٥٠٠٬٠٠٠ جنيه",
    "السعر ١٫٥ مليون",
  ]);
});

test("TAQ-64: long reference numbers are treated as contacts (no keyword exemption)", async () => {
  await expectCaught([
    "RERA 1234567890",
    "Serial 1234567890",
    "Permit 0501234567",
    "Permit No. 501234567",
    "رقم القطعة ١٠١٢٣٤٥٦٧٨",
    "رقم ٥٠١٢٣٤٥٦٧",
  ]);
});

test("TAQ-64: short reference numbers, prices and areas stay free", async () => {
  await expectFree([
    "رقم القطعة 1234",
    "Permit 7134-2025",
    "صك 4567891",
    "Price 15,000,000 EGP, area 250 m2",
    "السعر ١٥٬٠٠٠٬٠٠٠ جنيه، المساحة ٢٥٠ متر",
  ]);
});

test("TAQ-65: punctuation separators, keycap emoji and l/I for one are caught", async () => {
  await expectCaught([
    "010,1234,5678",
    "050|123|4567",
    "010:1234:5678",
    "+20*10*1234*5678",
    "050·123·4567",
    "050•123•4567",
    "010#1234#5678",
    "010'1234'5678",
    "٠١٠٬١٢٣٤٬٥٦٧٨",
    "010 x 1234 x 5678",
    "010 + 1234 + 5678",
    "0\uFE0F\u20E35\uFE0F\u20E30\uFE0F\u20E31\uFE0F\u20E32\uFE0F\u20E33\uFE0F\u20E34\uFE0F\u20E35\uFE0F\u20E36\uFE0F\u20E37\uFE0F\u20E3",
    "0l0l2345678",
    "0I012345678",
    "0ｌ0ｌ2345678",
    "010a1234b5678",
  ]);
  assert.equal(sanitized("Call 0l0l2345678 now"), "Call  now");
});

test("TAQ-65: ordinary punctuation, multiplication and sums stay free", async () => {
  await expectFree([
    "1,500,000",
    "15,000,000 AED",
    "10 x 12",
    "3x4",
    "10:30",
    "#12",
    "Apt #1203",
    "2 + 1 rooms",
    "5 * 4",
    "Hello world",
    "Ilala Towers, level 10",
  ]);
});

test("TAQ-65: messaging and social links and @handles are caught", async () => {
  await expectCaught([
    "Join t.me/tashil_deals",
    "https://t.me/tashil",
    "telegram.me/tashil",
    "telegram.dog/tashil",
    "Chat on wa.me/201012345678x",
    "WA.ME/abc",
    "https://api.whatsapp.com/send?phone=x",
    "chat.whatsapp.com/AbCdEf",
    "whatsapp.com/send?phone=x",
    "www.instagram.com/tashil",
    "instagr.am/p/x",
    "facebook.com/tashil",
    "fb.me/tashil",
    "fb.com/tashil",
    "m.me/tashil",
    "snapchat.com/add/tashil",
    "tiktok.com/@tashil",
    "x.com/tashil",
    "Twitter.com/tashil",
    "linkedin.com/in/tashil",
    "Follow @tashil.homes",
    "@tashil_homes",
    "(@tashil)",
    "تابعنا @tashil_eg",
  ]);
  assert.equal(sanitized("Join t.me/tashil_deals now"), "Join  now");
  assert.equal(sanitized("Follow @tashil_homes today"), "Follow  today");
});

test("TAQ-65: domains, prices with @ and the word email stay free", async () => {
  await expectFree([
    "example.com",
    "@ 5000 AED",
    "price@5000",
    "email me",
    "Visit tashilaqar.com",
    "Inbox.com and box.com",
    "Meet @ the entrance",
  ]);
});

// TAQ-69 (F-A): lists of prices, sizes and times were read as one long number.
const COMBINED_NUMBERS = [
  "Price 1,500,000 | 10 x 12 | 10:30",
  "Price 1,500,000 | 10x12 | 10:30",
  "Prices 100,000, 120,000, 150,000",
  "From 750,000, 900,000, 1,100,000",
  "1,500,000 | 2,000,000 | 2,500,000",
  "Units 10, 12, 34, 56, 78",
  "Price 1,500,000 | Apt #1203 | 3 BR",
];

test("TAQ-69: free text that combines several numbers stays unchanged in the sanitizer and the rules", async () => {
  await expectFree([...COMBINED_NUMBERS, ...COMBINED_NUMBERS.map(arabicIndic)]);
  const ref = doc(root(), "Properties/prop-1");
  for (const text of COMBINED_NUMBERS) {
    const descriptions = { ar: `شقة ${text}`, en: text, hi: `फ्लैट ${text}` };
    const out = sanitizeForMarketplace({ pricePerMonth: 9000, descriptions, titles: descriptions }, "owner", "prop-1");
    assert.deepEqual(out.descriptions, descriptions, JSON.stringify(text));
    assert.deepEqual(out.titles, descriptions, JSON.stringify(text));
    await assertSucceeds(setDoc(ref, listingWith({ descriptions, titles: descriptions })), JSON.stringify(text));
  }
});

test("TAQ-69: thousands groups are one token, and list separators end a number", async () => {
  await expectFree([
    "1,500,000|2,000,000|2,500,000",
    "Price 1 500 000 10 x 12 10:30",
    "Price ₹10,00,00,000",
    "₹1,50,00,000 to ₹2,00,00,000",
    "Rent 15,000,000 EGP; deposit 50,000!",
    "Units 10, 12, 34, 56, 78, 90",
    "Floors 3 | 4 | 5 | 6",
  ]);
  await expectCaught(variants([
    "Prices 100,000, 0501234567",
    "Units 10, 010 1234 5678",
    "1,500,000 | 050 123 4567",
    "10,12,34,56,78",
    "01,01,23,45,678",
  ]));
  assert.equal(sanitized("Price 1,500,000 | call 050 123 4567"), "Price 1,500,000 | call");
});

test("TAQ-66: 010 12 345 678 and 01 012 345 678 are caught, in any digits", async () => {
  await expectCaught(variants(["010 12 345 678", "01 012 345 678"]));
  assert.equal(sanitized("Call 010 12 345 678 now"), "Call  now");
  assert.equal(sanitized("اتصل ٠١ ٠١٢ ٣٤٥ ٦٧٨ الآن"), "اتصل  الآن");
});

test("TAQ-69: a plain @word is text; real-looking handles and handles after a messaging keyword are caught", async () => {
  await expectFree([
    "Stay @home",
    "Stay @home.",
    "meet @ 5pm",
    "Work @office, relax @home",
    "Size X: Large",
    "WhatsApp group available",
    "Follow the signs to the lobby",
  ]);
  await expectCaught([
    "Stay @home2",
    "IG @home",
    "Telegram @tashil",
    "DM @owner",
    "X @tashil",
    "IG: x",
    "Insta: tashil",
    "Telegram tashil_deals",
    "تابعنا @tashil",
  ]);
  assert.equal(sanitized("Stay @home with IG @tashil"), "Stay @home with IG");
});

test("TAQ-69: extra separators, letter O after l, zero-width links and YouTube/Threads profiles are caught", async () => {
  await expectCaught([
    ..."; = ^ ! & % $ \" [ ] { } < > ?".split(" ").map((sep) => `010${sep}1234${sep}5678`),
    "0lO 1234 5678",
    "t\u200B.me/tashil",
    "t.\u200Dme/tashil",
    "wa\u2060.me/201012345678",
    "youtube.com/@tashil",
    "https://m.youtube.com/channel/UC123",
    "threads.net/@tashil",
    "www.threads.com/@tashil",
  ]);
  await expectFree([
    "Discount 10% for 12 months",
    "Price $1,500,000 (negotiable)?",
    "Units [10] [12] [34]",
    "Tour on youtube.com/watch?v=abc",
  ]);
});

test("TAQ-63: a max-size listing (4000-character descriptions) is evaluated within the rules' limits", async () => {
  const ref = doc(root(), "Properties/prop-1");
  const sentence = "Spacious flat of 120 m2 on floor 12, price 1.500.000 EGP, built 2015, ready 2026-01-15. ";
  const description = sentence.repeat(Math.ceil(4000 / sentence.length)).slice(0, 4000);
  assert.equal(description.length, 4000);
  const sanitizedDescription = sanitizeForMarketplace({ pricePerMonth: 9000, descriptions: { en: description } }, "owner", "prop-1").descriptions.en;
  assert.equal(sanitizedDescription, description.trim());
  const full = {
    titles: { ar: "ش".repeat(200), en: "T".repeat(200), hi: "ह".repeat(200) },
    descriptions: { ar: description, en: description, hi: description },
    locations: { ar: "م".repeat(300), en: "L".repeat(300), hi: "स".repeat(300) },
    amenitiesMap: {
      ar: Array.from({ length: 30 }, (_, i) => `ميزة ${i}`),
      en: Array.from({ length: 30 }, (_, i) => `Feature ${i}`),
      hi: Array.from({ length: 30 }, (_, i) => `सुविधा ${i}`),
    },
    buildingName: "B".repeat(200),
  };
  await assertSucceeds(setDoc(ref, listingWith(full)));
  await rejected(ref, listingWith({ ...full, descriptions: { ...full.descriptions, en: `${description.slice(0, 3980)} 010 12 34 56 78` } }), "phone at the end of a 4000-character description");
});

// TAQ-72: § ¦ ¤ are the filter's own markers and ¶ ` ´ look like them; typed in a listing
// they are separators like any other.
test("TAQ-72: phones split by § ¶ ¦ ¤ ` or ´ are caught in the sanitizer and the rules, in any digits", async () => {
  const seps = ["\u00a7", "\u00b6", "\u00a6", "\u00a4", "`", "\u00b4"];
  await expectCaught(variants([
    "010§1234§5678",
    "050§123§4567",
    "+20§10§1234§5678",
    "+971§50§123§4567",
    ...seps.map((sep) => `010${sep}1234${sep}5678`),
    ...seps.map((sep) => `050${sep}123${sep}4567`),
    "010 § 1234 § 5678",
    "010§§1234``5678",
  ]));
  assert.equal(sanitized("Call 010§1234§5678 now"), "Call  now");
  assert.equal(sanitized("اتصل ٠٥٠¶١٢٣¶٤٥٦٧ الآن"), "اتصل  الآن");
});

test("TAQ-72: prices, handles, dates, permits and clause marks with § or ¶ stay free", async () => {
  await expectFree([
    "Price 1,500,000 | Apt #1203 | 3 BR",
    "Stay @home",
    "meet @ 5pm",
    "Lease 1/1/2026 31/12/2026",
    "Available 2026-01-15 2026-06-30",
    "Permit 7134-2025",
    "RERA permit 7134",
    "Section §12 of the lease",
    "Clause §3.2, ¶4",
    "Units 10§12§34",
    "Use the `Book viewing` button",
    "Price 1,500,000 § 2,000,000",
  ]);
});
