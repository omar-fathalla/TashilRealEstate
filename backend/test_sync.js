const assert = require("assert");

// Test runner for Backend Sanitization & Sync Logic
console.log("🚀 Starting Backend Zero-Leakage Sanitization Tests...\n");

const { sanitizeForMarketplace } = require("./index.js");

// Mock Owner Property Record containing private & sensitive PII
const rawOwnerProperty = {
  id: "prop-luxury-penthouse-01",
  countryCode: "AE",
  currencyCode: "AED",
  titles: {
    ar: "بنتهاوس فاخر في وسط دبي",
    en: "Luxury Penthouse in Downtown Dubai",
    hi: "डाउनटाउन दुबई में लक्जरी पेंटहाउस",
  },
  descriptions: {
    ar: "إطلالة بانورامية على برج خليفة ونافورة دبي",
    en: "Panoramic views of Burj Khalifa and Dubai Fountain",
    hi: "बुर्ज खलीफा और दुबई फाउंटेन के मनोरम दृश्य",
  },
  locations: {
    ar: "وسط مدينة دبي، دبي",
    en: "Downtown Dubai, Dubai",
    hi: "डाउनटाउन दुबई, दुबई",
  },
  cityCode: "dubai",
  propertyTypeCode: "penthouse",
  unitNumber: "PH-4502", // SENSITIVE: Private Flat/Unit number
  buildingName: "The Address Downtown",
  pricePerMonth: 35000,
  bedrooms: 3,
  bathrooms: 4,
  areaSqM: 320,
  image: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750",
  imageUrls: [
    "https://images.unsplash.com/photo-1512917774080-9991f1c4c750",
    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9",
  ],
  isPublished: true,
  rentalStatus: "available",
  // --- HIGHLY SENSITIVE / PRIVATE FIELDS ---
  tenantName: "Mr. John Doe (VIP)",
  tenantPhone: "+971 50 123 4567",
  leaseStartDate: "2026-01-01T00:00:00.000Z",
  leaseEndDate: "2026-12-31T00:00:00.000Z",
  installments: [
    { id: "inst-1", amount: 35000, status: "paid", dueDate: "2026-01-01" },
    { id: "inst-2", amount: 35000, status: "paid", dueDate: "2026-02-01" },
  ],
  notes: "Private Landlord internal note: Negotiated 5% discount, tenant requested early access.",
};

const ownerId = "owner-sheikh-zayed-001";
const sanitized = sanitizeForMarketplace(rawOwnerProperty, ownerId, rawOwnerProperty.id);

// --- TEST 1: STRICT ZERO-LEAKAGE VERIFICATION ---
console.log("Checking Test 1: Sensitive Fields Stripping...");
assert.strictEqual(sanitized.tenantName, undefined, "❌ LEAK DETECTED: tenantName was NOT stripped!");
assert.strictEqual(sanitized.tenantPhone, undefined, "❌ LEAK DETECTED: tenantPhone was NOT stripped!");
assert.strictEqual(sanitized.leaseStartDate, undefined, "❌ LEAK DETECTED: leaseStartDate was NOT stripped!");
assert.strictEqual(sanitized.leaseEndDate, undefined, "❌ LEAK DETECTED: leaseEndDate was NOT stripped!");
assert.strictEqual(sanitized.installments, undefined, "❌ LEAK DETECTED: installments array was NOT stripped!");
assert.strictEqual(sanitized.unitNumber, undefined, "❌ LEAK DETECTED: unitNumber was NOT stripped!");
assert.strictEqual(sanitized.notes, undefined, "❌ LEAK DETECTED: notes was NOT stripped!");
console.log("✅ Test 1 Passed: All private landlord/tenant PII stripped successfully.\n");

// --- TEST 2: PUBLIC MARKETING METADATA INTEGRITY ---
console.log("Checking Test 2: Public Marketing Metadata Preservation...");
assert.strictEqual(sanitized.id, "prop-luxury-penthouse-01");
assert.strictEqual(sanitized.owner_id, "owner-sheikh-zayed-001");
assert.strictEqual(sanitized.countryCode, "AE");
assert.strictEqual(sanitized.currencyCode, "AED");
assert.strictEqual(sanitized.cityCode, "dubai");
assert.strictEqual(sanitized.pricePerMonth, 35000);
assert.strictEqual(sanitized.bedrooms, 3);
assert.strictEqual(sanitized.bathrooms, 4);
assert.strictEqual(sanitized.areaSqM, 320);
assert.strictEqual(sanitized.is_published, true);
assert.strictEqual(sanitized.status, "vacant");

// Verify Trilingual titles & descriptions
assert.strictEqual(sanitized.titles.ar, "بنتهاوس فاخر في وسط دبي");
assert.strictEqual(sanitized.titles.en, "Luxury Penthouse in Downtown Dubai");
assert.strictEqual(sanitized.titles.hi, "डाउनटाउन दुबई में लक्जरी पेंटहाउस");
assert.strictEqual(sanitized.imageUrls.length, 2);
console.log("✅ Test 2 Passed: Public metadata and trilingual strings preserved with 100% fidelity.\n");

// --- TEST 3: GRACEFUL FALLBACK HANDLING ---
console.log("Checking Test 3: Fallback handling for flat string titles...");
const flatProperty = {
  id: "flat-prop-02",
  title: "شقة استوديو في القاهرة الجديدة",
  description: "تشطيب سوبر لوكس",
  location: "التجمع الخامس، القاهرة",
  pricePerMonth: "12000",
  image: "https://example.com/studio.jpg",
};
const flatSanitized = sanitizeForMarketplace(flatProperty, "owner-cairo-02", "flat-prop-02");
assert.strictEqual(flatSanitized.titles.ar, "شقة استوديو في القاهرة الجديدة");
assert.strictEqual(flatSanitized.titles.en, "شقة استوديو في القاهرة الجديدة");
assert.strictEqual(flatSanitized.pricePerMonth, 12000);
assert.strictEqual(flatSanitized.currencyCode, "EGP");
assert.strictEqual(flatSanitized.imageUrls[0], "https://example.com/studio.jpg");
console.log("✅ Test 3 Passed: Graceful fallback handled flawlessly.\n");

console.log("🎉 ALL TESTS PASSED SUCCESSFULLY! ZERO DATA LEAKAGE CONFIRMED.");
