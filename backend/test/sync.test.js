const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;

async function clearEmulators() {
  await Promise.all([
    fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" }),
    fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" }),
  ]);
}

function privateListing(extra = {}) {
  return {
    isPublished: true,
    rentalStatus: "available",
    countryCode: "AE",
    titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" },
    pricePerMonth: 9000,
    ...extra,
  };
}

/** Writes Users/{ownerId}/properties/{propertyId} (or deletes it) and runs the trigger on it. */
async function ownerWrites(ownerId, propertyId, data) {
  const ref = db.doc(`Users/${ownerId}/properties/${propertyId}`);
  if (data) await ref.set(data);
  else await ref.delete();
  const after = await ref.get();
  await fns.syncOwnerPropertyToMarketplace.run({
    params: { ownerId, propertyId },
    data: { before: null, after },
  });
}

async function publicDoc(propertyId) {
  const snap = await db.doc(`Properties/${propertyId}`).get();
  return snap.exists ? snap.data() : null;
}

test.beforeEach(async () => {
  await clearEmulators();
  await db.doc("Users/ownerA").set({ role: "Owner" });
  await db.doc("Users/ownerB").set({ role: "Owner" });
});

// --- TAQ-46: the sync trigger cannot hijack another owner's public listing ---

test("TAQ-46: an owner publishes and updates their own listing", async () => {
  await ownerWrites("ownerA", "listing-a", privateListing());
  let pub = await publicDoc("listing-a");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.titles.en, "Apartment");

  await ownerWrites("ownerA", "listing-a", privateListing({ titles: { en: "Renovated" }, pricePerMonth: 9500 }));
  pub = await publicDoc("listing-a");
  assert.equal(pub.titles.en, "Renovated");
  assert.equal(pub.pricePerMonth, 9500);
});

test("TAQ-46: another owner cannot overwrite a listing by reusing its id", async () => {
  await ownerWrites("ownerA", "listing-a", privateListing());

  await ownerWrites("ownerB", "listing-a", privateListing({ titles: { en: "Scam" }, pricePerMonth: 1 }));
  const pub = await publicDoc("listing-a");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.titles.en, "Apartment");
  assert.equal(pub.pricePerMonth, 9000);
  assert.equal(pub.is_published, true);
});

test("TAQ-46: another owner cannot conceal a listing by reusing its id", async () => {
  await ownerWrites("ownerA", "listing-a", privateListing());

  await ownerWrites("ownerB", "listing-a", privateListing({ isPublished: false }));
  const pub = await publicDoc("listing-a");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.is_published, true);
});

test("TAQ-46: deleting a decoy does not delete the real owner's listing", async () => {
  await ownerWrites("ownerA", "listing-a", privateListing());
  await ownerWrites("ownerB", "listing-a", privateListing({ titles: { en: "Decoy" } }));

  await ownerWrites("ownerB", "listing-a", null);
  const pub = await publicDoc("listing-a");
  assert.ok(pub, "ownerA's public listing must survive");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.titles.en, "Apartment");
});

test("TAQ-46: a listing without an owner (seed or SuperAdmin catalog) cannot be claimed", async () => {
  await db.doc("Properties/catalog-1").set({ id: "catalog-1", is_published: true, status: "vacant", titles: { en: "Catalog" } });

  await ownerWrites("ownerB", "catalog-1", privateListing({ titles: { en: "Mine now" } }));
  assert.equal((await publicDoc("catalog-1")).titles.en, "Catalog");
  await ownerWrites("ownerB", "catalog-1", null);
  assert.ok(await publicDoc("catalog-1"));
});

test("TAQ-46: the owner can still conceal and delete their own listing", async () => {
  await ownerWrites("ownerA", "listing-a", privateListing());

  await ownerWrites("ownerA", "listing-a", privateListing({ rentalStatus: "rented" }));
  let pub = await publicDoc("listing-a");
  assert.equal(pub.is_published, false);
  assert.equal(pub.status, "rented");

  await ownerWrites("ownerA", "listing-a", null);
  pub = await publicDoc("listing-a");
  assert.equal(pub, null);
});
