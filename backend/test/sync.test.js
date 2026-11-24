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

// --- TAQ-49: the trigger only publishes for Owners and AgencyAdmins ---

test("TAQ-49: a Tenant's private listing is never published", async () => {
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await ownerWrites("tenantT", "tenant-listing", privateListing());
  assert.equal(await publicDoc("tenant-listing"), null);
});

test("TAQ-49: a Tenant's existing public listing is concealed on the next sync", async () => {
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await db.doc("Properties/tenant-listing").set({ id: "tenant-listing", owner_id: "tenantT", is_published: true, status: "vacant" });
  await ownerWrites("tenantT", "tenant-listing", privateListing());
  const pub = await publicDoc("tenant-listing");
  assert.equal(pub.is_published, false);
  assert.equal(pub.owner_id, "tenantT");
});

test("TAQ-49: an elevated role written into the profile does not allow publishing", async () => {
  await db.doc("Users/fakeAgent").set({ role: "AgencyAdmin" });
  await db.doc("Users/noRole").set({ full_name: "No Role" });
  await ownerWrites("fakeAgent", "fake-1", privateListing());
  await ownerWrites("noRole", "norole-1", privateListing());
  await ownerWrites("ghost", "ghost-1", privateListing());
  assert.equal(await publicDoc("fake-1"), null);
  assert.equal(await publicDoc("norole-1"), null);
  assert.equal(await publicDoc("ghost-1"), null);
});

test("TAQ-49: Owner and AgencyAdmin custom claims can publish", async () => {
  await admin.auth().createUser({ uid: "claimOwner" });
  await admin.auth().setCustomUserClaims("claimOwner", { role: "Owner" });
  await admin.auth().createUser({ uid: "claimAgent" });
  await admin.auth().setCustomUserClaims("claimAgent", { role: "AgencyAdmin", agency_id: "agency-1" });
  // A Tenant claim wins over an Owner profile.
  await admin.auth().createUser({ uid: "claimTenant" });
  await admin.auth().setCustomUserClaims("claimTenant", { role: "Tenant" });
  await db.doc("Users/claimTenant").set({ role: "Owner" });

  await ownerWrites("claimOwner", "c-owner", privateListing());
  await ownerWrites("claimAgent", "c-agent", privateListing());
  await ownerWrites("claimTenant", "c-tenant", privateListing());
  assert.equal((await publicDoc("c-owner")).is_published, true);
  assert.equal((await publicDoc("c-agent")).is_published, true);
  assert.equal(await publicDoc("c-tenant"), null);
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

// --- TAQ-51: the trigger is the only writer of public listings ---

test("TAQ-51: the trigger publishes a listing id nobody could claim first", async () => {
  await ownerWrites("ownerA", "fresh-id", privateListing());
  const pub = await publicDoc("fresh-id");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.is_published, true);
});

test("TAQ-51: agency attribution comes from the AgencyAdmin's claims, not the private doc", async () => {
  await admin.auth().createUser({ uid: "agent1" });
  await admin.auth().setCustomUserClaims("agent1", { role: "AgencyAdmin", agency_id: "agency-1" });

  await ownerWrites("agent1", "agency-listing", privateListing({ agency_id: "agency-2" }));
  await ownerWrites("ownerA", "owner-listing", privateListing({ agency_id: "agency-1", agencyId: "agency-1" }));
  assert.equal((await publicDoc("agency-listing")).agency_id, "agency-1");
  assert.equal("agency_id" in (await publicDoc("owner-listing")), false);
});

// --- TAQ-52: the trigger validates listing values ---

test("TAQ-52: a listing without a positive rent is not published", async () => {
  await ownerWrites("ownerA", "neg-price", privateListing({ pricePerMonth: -500 }));
  await ownerWrites("ownerA", "no-price", privateListing({ pricePerMonth: 0 }));
  assert.equal(await publicDoc("neg-price"), null);
  assert.equal(await publicDoc("no-price"), null);

  await ownerWrites("ownerA", "listing-a", privateListing());
  await ownerWrites("ownerA", "listing-a", privateListing({ pricePerMonth: -1 }));
  assert.equal((await publicDoc("listing-a")).is_published, false);
});

test("TAQ-52: owners cannot set rating or featured; moderated values survive republishing", async () => {
  await ownerWrites("ownerA", "listing-a", privateListing({ rating: 999, isFeatured: true }));
  let pub = await publicDoc("listing-a");
  assert.equal(pub.rating, 5);
  assert.equal(pub.isFeatured, false);

  await db.doc("Properties/listing-a").update({ rating: 3.5, isFeatured: true });
  await ownerWrites("ownerA", "listing-a", privateListing({ rating: 5, isFeatured: false, pricePerMonth: 9500 }));
  pub = await publicDoc("listing-a");
  assert.equal(pub.rating, 3.5);
  assert.equal(pub.isFeatured, true);
  assert.equal(pub.pricePerMonth, 9500);
});

test("TAQ-52: unsafe images and contact details never reach the catalog", async () => {
  await ownerWrites("ownerA", "listing-a", privateListing({
    buildingName: "Tower 0501234567",
    imageUrls: ["javascript:alert(1)", "http://evil.example.com/a.jpg", "assets/images/properties/prop_eg_6_1.jpg"],
  }));
  const pub = await publicDoc("listing-a");
  assert.equal(pub.buildingName, "Tower");
  assert.deepEqual(pub.imageUrls, ["assets/images/properties/prop_eg_6_1.jpg"]);
});

// --- TAQ-55: an unpublished private listing never creates a public doc ---

test("TAQ-55: an unpublished listing from any user does not create /Properties/{id}", async () => {
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await ownerWrites("tenantT", "squat-1", privateListing({ isPublished: false }));
  await ownerWrites("ownerB", "squat-2", privateListing({ isPublished: false }));
  await ownerWrites("ownerB", "squat-3", privateListing({ rentalStatus: "rented" }));
  await ownerWrites("ghost", "squat-4", privateListing({ isPublished: false }));
  for (const id of ["squat-1", "squat-2", "squat-3", "squat-4"]) {
    assert.equal(await publicDoc(id), null, `${id} must not exist`);
  }
});

test("TAQ-55: a placeholder attempt does not block the real owner's later publish", async () => {
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await ownerWrites("tenantT", "contested", privateListing({ isPublished: false }));
  await ownerWrites("ownerB", "contested", privateListing({ isPublished: false }));

  await ownerWrites("ownerA", "contested", privateListing({ titles: { en: "Real owner" } }));
  const pub = await publicDoc("contested");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.is_published, true);
  assert.equal(pub.titles.en, "Real owner");
});

test("TAQ-55: unpublishing or deleting an unowned id never creates or removes anything", async () => {
  await ownerWrites("ownerB", "nothing-1", privateListing({ isPublished: false }));
  await ownerWrites("ownerB", "nothing-1", null);
  assert.equal(await publicDoc("nothing-1"), null);
});

test("TAQ-55: legacy placeholders left by non-owners are replaced by a real publish", async () => {
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await db.doc("Properties/legacy-tenant").set({
    owner_id: "tenantT", is_published: false, status: "unavailable",
  });
  await db.doc("Properties/legacy-owner-stub").set({
    owner_id: "ownerB", is_published: false, status: "unavailable",
  });
  await db.doc("Properties/legacy-tenant-content").set({
    id: "legacy-tenant-content", owner_id: "tenantT", is_published: false, status: "unavailable", titles: { en: "Junk" },
  });

  await ownerWrites("ownerA", "legacy-tenant", privateListing());
  await ownerWrites("ownerA", "legacy-owner-stub", privateListing());
  await ownerWrites("ownerA", "legacy-tenant-content", privateListing());
  for (const id of ["legacy-tenant", "legacy-owner-stub", "legacy-tenant-content"]) {
    const pub = await publicDoc(id);
    assert.equal(pub.owner_id, "ownerA", id);
    assert.equal(pub.is_published, true, id);
  }
});

test("TAQ-55: a real owner's hidden listing cannot be taken over by another owner", async () => {
  await ownerWrites("ownerA", "hidden-a", privateListing());
  await ownerWrites("ownerA", "hidden-a", privateListing({ isPublished: false }));
  assert.equal((await publicDoc("hidden-a")).is_published, false);

  await ownerWrites("ownerB", "hidden-a", privateListing({ titles: { en: "Takeover" } }));
  const pub = await publicDoc("hidden-a");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.is_published, false);
  assert.notEqual(pub.titles.en, "Takeover");

  await ownerWrites("ownerA", "hidden-a", privateListing({ titles: { en: "Back again" } }));
  const again = await publicDoc("hidden-a");
  assert.equal(again.is_published, true);
  assert.equal(again.titles.en, "Back again");
});

test("TAQ-55: a published listing can never be replaced as a placeholder", async () => {
  await ownerWrites("ownerA", "live-a", privateListing());
  await db.doc("Properties/live-bare").set({ owner_id: "ownerB", is_published: true, status: "vacant" });
  await ownerWrites("ownerA", "live-bare", privateListing());
  assert.equal((await publicDoc("live-bare")).owner_id, "ownerB");
  await ownerWrites("ownerB", "live-a", privateListing({ titles: { en: "Scam" } }));
  assert.equal((await publicDoc("live-a")).owner_id, "ownerA");
});
