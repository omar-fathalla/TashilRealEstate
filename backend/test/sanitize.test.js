const test = require("node:test");
const assert = require("node:assert/strict");
const { sanitizeForMarketplace } = require("../index");

const PUBLIC_FIELDS = [
  "id", "owner_id", "countryCode", "currencyCode", "titles", "descriptions", "locations",
  "cityCode", "propertyTypeCode", "buildingName", "pricePerMonth", "bedrooms", "bathrooms",
  "areaSqM", "image", "imageUrls", "amenitiesMap", "isFurnished", "agencyNames", "agencyPhone",
  "rating", "isFeatured", "is_published", "status", "updated_at",
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
    "https://images.unsplash.com/photo-1",
    "data:image/jpeg;base64,/9j/AAAA",
    "assets/images/properties/prop_eg_6_1.jpg",
  ]);
  assert.equal(out.image, "https://images.unsplash.com/photo-1");
});

test("TAQ-18: currency always follows the country", () => {
  assert.equal(sanitizeForMarketplace(ownerProperty, "owner", "prop-1").currencyCode, "AED");
  assert.equal(sanitizeForMarketplace({ countryCode: "EG", currencyCode: "AED" }, "o", "p").currencyCode, "EGP");
});
