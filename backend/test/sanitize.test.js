const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-tashil-test";
const { sanitizeForMarketplace } = require("../index");

const BUCKET = `${process.env.GCLOUD_PROJECT}.appspot.com`;
const PROJECT_IMAGE = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/listings%2Fprop-1%2Fliving.jpg?alt=media&token=abc`;

const PUBLIC_FIELDS = [
  "id", "owner_id", "countryCode", "currencyCode", "titles", "descriptions", "locations",
  "cityCode", "propertyTypeCode", "buildingName", "pricePerMonth", "bedrooms", "bathrooms",
  "areaSqM", "image", "imageUrls", "amenitiesMap", "isFurnished", "agencyNames", "agencyPhone",
  "rating", "isFeatured", "is_published", "status", "updated_at", "verified", "moderation_hidden",
].sort();

const ownerProperty = {
  id: "prop-1",
  countryCode: "AE",
  currencyCode: "EGP",
  titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट", ownerPhone: "+971500000001" },
  descriptions: { ar: "وصف", en: "Description", hi: "विवरण", tenant: { name: "T" } },
  locations: { ar: "دبي مارينا", en: "Dubai Marina", hi: "दुबई मरीना" },
  cityCode: "dubai",
  pricePerMonth: 9000,
  imageUrls: [
    PROJECT_IMAGE,
    "https://images.unsplash.com/photo-1",
    "https://firebasestorage.googleapis.com/v0/b/demo.appspot.com/o/users%2Fowner%2Femirates-id.jpg?alt=media",
    "http://insecure.example.com/a.jpg",
    "blob:https://tashilaqar.com/1234",
    "data:application/pdf;base64,AAAA",
    "data:image/jpeg;base64,/9j/AAAA",
    "assets/images/properties/prop_eg_6_1.jpg",
  ],
  amenitiesMap: { ar: ["مسبح"], en: ["Pool", 42], hi: ["पूल"], secret: ["x"] },
  agencyNames: { ar: "رقم المالك 0501234567", en: "Owner direct", hi: "x" },
  agencyPhone: "+971500000001",
  ownerPhone: "+971500000001",
  ownerEmail: "owner@example.com",
  tenantName: "Tenant",
  tenantPhone: "+971500000002",
  unitNumber: "PH-4502",
  installments: [{ amount: 9000 }],
  archivedInstallments: [],
  leaseStartDate: "2026-01-01",
  notes: "private",
  iban: "AE070331234567890123456",
  isPublished: true,
  rentalStatus: "available",
};

test("TAQ-18: only allowlisted fields reach the public listing", () => {
  const out = sanitizeForMarketplace(ownerProperty, "owner", "prop-1");
  assert.deepEqual(Object.keys(out).sort(), PUBLIC_FIELDS);
});

test("TAQ-18: nested localized maps keep only ar/en/hi strings", () => {
  const out = sanitizeForMarketplace(ownerProperty, "owner", "prop-1");
  assert.deepEqual(Object.keys(out.titles).sort(), ["ar", "en", "hi"]);
  assert.deepEqual(Object.keys(out.descriptions).sort(), ["ar", "en", "hi"]);
  assert.deepEqual(out.amenitiesMap, { ar: ["مسبح"], en: ["Pool"], hi: ["पूल"] });
  assert.doesNotMatch(JSON.stringify(out), /\+971500000001|\+971500000002|owner@example\.com|PH-4502|AE0703/);
});

test("TAQ-18: owner-supplied contact data is replaced with the platform contact", () => {
  const out = sanitizeForMarketplace(ownerProperty, "owner", "prop-1");
  assert.equal(out.agencyPhone, "+20 100 123 4567");
  assert.equal(out.agencyNames.en, "Tashil Property Management");
});

test("TAQ-18: private storage paths and non-image references are dropped", () => {
  const out = sanitizeForMarketplace(ownerProperty, "owner", "prop-1");
  assert.deepEqual(out.imageUrls, [
    PROJECT_IMAGE,
    "data:image/jpeg;base64,/9j/AAAA",
    "assets/images/properties/prop_eg_6_1.jpg",
  ]);
  assert.equal(out.image, PROJECT_IMAGE);
});

test("TAQ-47: the firestore.rules listing allowlist matches the sanitizer", () => {
  const rules = fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8");
  const body = rules.match(/function publicListingFields\(\)\s*\{\s*return \[([\s\S]*?)\];/);
  assert.ok(body, "publicListingFields() not found in firestore.rules");
  const allowlist = [...body[1].matchAll(/'([^']+)'/g)].map((m) => m[1]).sort();
  assert.deepEqual(allowlist, [...PUBLIC_FIELDS, "agency_id"].sort());
});

test("TAQ-18: currency always follows the country", () => {
  assert.equal(sanitizeForMarketplace(ownerProperty, "owner", "prop-1").currencyCode, "AED");
  assert.equal(sanitizeForMarketplace({ countryCode: "EG", currencyCode: "AED" }, "o", "p").currencyCode, "EGP");
});

// --- TAQ-52: listing values are validated before they reach the catalog ---

test("TAQ-52: images must come from this project's Storage bucket or the app bundle", () => {
  const out = sanitizeForMarketplace({
    pricePerMonth: 9000,
    imageUrls: [
      "javascript:alert(1)",
      "http://evil.example.com/a.jpg",
      "https://images.unsplash.com/photo-1",
      "https://firebasestorage.googleapis.com/v0/b/other-project.appspot.com/o/a.jpg?alt=media",
      `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/kyc%2Fpassport.jpg?alt=media`,
      `https://storage.googleapis.com/${BUCKET}/users/owner/id.jpg`,
      "assets/../../secrets.png",
      "data:image/svg+xml;base64,PHN2Zz4=",
      `https://storage.googleapis.com/${BUCKET}/listings/front.webp`,
      PROJECT_IMAGE,
      "prop_eg_6_1.jpg",
    ],
  }, "owner", "prop-1");
  assert.deepEqual(out.imageUrls, [
    `https://storage.googleapis.com/${BUCKET}/listings/front.webp`,
    PROJECT_IMAGE,
    "prop_eg_6_1.jpg",
  ]);
});

test("TAQ-52: rating and featured flag cannot be set by the owner", () => {
  const out = sanitizeForMarketplace({ pricePerMonth: 9000, rating: 999, isFeatured: true }, "owner", "prop-1");
  assert.equal(out.rating, 5);
  assert.equal(out.isFeatured, false);
  const moderated = sanitizeForMarketplace(
    { pricePerMonth: 9000, rating: 1, isFeatured: false },
    "owner", "prop-1", { current: { rating: 4.2, isFeatured: true } },
  );
  assert.equal(moderated.rating, 4.2);
  assert.equal(moderated.isFeatured, true);
  assert.equal(sanitizeForMarketplace({ pricePerMonth: 1 }, "o", "p", { current: { rating: 999 } }).rating, 5);
});

test("TAQ-52: numbers are positive and bounded", () => {
  const out = sanitizeForMarketplace({ pricePerMonth: -500, areaSqM: -10, bedrooms: -1, bathrooms: 1e9 }, "o", "p");
  assert.equal(out.pricePerMonth, 0);
  assert.equal(out.areaSqM, 100);
  assert.equal(out.bedrooms, 1);
  assert.equal(out.bathrooms, 100);
  assert.equal(sanitizeForMarketplace({ pricePerMonth: "abc" }, "o", "p").pricePerMonth, 0);
  assert.equal(sanitizeForMarketplace({ pricePerMonth: 12500 }, "o", "p").pricePerMonth, 12500);
});

test("TAQ-52: phone numbers and emails are removed from free text", () => {
  const out = sanitizeForMarketplace({
    pricePerMonth: 9000,
    buildingName: "Marina Tower call 0501234567",
    titles: { ar: "شقة للتواصل ٠١٠٠١٢٣٤٥٦٧", en: "Flat, WhatsApp +971 50 123 4567", hi: "फ्लैट owner@example.com" },
    descriptions: { ar: "السعر 15000000 جنيه", en: "Contact me at a.b-c@mail.co.uk now", hi: "विवरण" },
    locations: { ar: "دبي", en: "Dubai (050) 123-4567", hi: "दुबई" },
  }, "o", "p");
  assert.equal(out.buildingName, "Marina Tower call");
  assert.equal(out.titles.ar, "شقة للتواصل");
  assert.equal(out.titles.en, "Flat, WhatsApp");
  assert.equal(out.titles.hi, "फ्लैट");
  assert.equal(out.descriptions.ar, "السعر 15000000 جنيه");
  assert.equal(out.descriptions.en, "Contact me at  now");
  assert.equal(out.locations.en, "Dubai");
});

test("TAQ-63/TAQ-65: short digit groups, punctuation separators and messaging links are removed", () => {
  const out = sanitizeForMarketplace({
    pricePerMonth: 9000,
    buildingName: "Tower 010 12 34 56 78",
    titles: { ar: "شقة ٠١٠٬١٢٣٤٬٥٦٧٨", en: "Flat 050|123|4567 sea view", hi: "फ्लैट t.me/owner" },
    descriptions: { ar: "السعر ١٬٥٠٠٬٠٠٠ جنيه", en: "Price 1.500.000.000 EGP, ready 01/01/2026 10:30", hi: "@owner_hi संपर्क" },
    locations: { ar: "دبي", en: "Dubai 501 234 567", hi: "दुबई" },
  }, "o", "p");
  assert.equal(out.buildingName, "Tower");
  assert.equal(out.titles.ar, "شقة");
  assert.equal(out.titles.en, "Flat  sea view");
  assert.equal(out.titles.hi, "फ्लैट");
  assert.equal(out.descriptions.ar, "السعر ١٬٥٠٠٬٠٠٠ جنيه");
  assert.equal(out.descriptions.en, "Price 1.500.000.000 EGP, ready 01/01/2026 10:30");
  assert.equal(out.descriptions.hi, "संपर्क");
  assert.equal(out.locations.en, "Dubai 501 234 567");
});

test("TAQ-52: the published status is always vacant and strings are bounded", () => {
  const out = sanitizeForMarketplace({ pricePerMonth: 9000, status: "sold", buildingName: "x".repeat(500) }, "o", "p");
  assert.equal(out.status, "vacant");
  assert.equal(out.buildingName.length, 200);
});
