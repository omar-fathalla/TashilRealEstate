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

test("M-1: any rental status other than available takes a live listing offline (is_published false, not vacant)", async () => {
  for (const rentalStatus of ["rented", "maintenance", "reserved"]) {
    await ownerWrites("ownerA", "listing-r", privateListing());
    assert.equal((await publicDoc("listing-r")).is_published, true);
    await ownerWrites("ownerA", "listing-r", privateListing({ rentalStatus }));
    const pub = await publicDoc("listing-r");
    assert.equal(pub.is_published, false, rentalStatus);
    assert.equal(pub.status, rentalStatus === "rented" ? "rented" : "unavailable", rentalStatus);
  }
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

// --- TAQ-91: Investor and Admin cannot publish; moderation flags survive owner edits ---

test("TAQ-91: an Investor's or an Admin's draft never reaches the marketplace", async () => {
  await db.doc("Users/invP").set({ role: "Investor" });
  await db.doc("Users/admP").set({ role: "Admin" });
  await admin.auth().createUser({ uid: "invC" });
  await admin.auth().setCustomUserClaims("invC", { role: "Investor" });
  await admin.auth().createUser({ uid: "admC" });
  await admin.auth().setCustomUserClaims("admC", { role: "Admin" });
  for (const uid of ["invP", "admP", "invC", "admC"]) {
    await ownerWrites(uid, `${uid}-1`, privateListing());
    assert.equal(await publicDoc(`${uid}-1`), null, uid);
  }
  await db.doc("Properties/inv-live").set({ id: "inv-live", owner_id: "invP", is_published: true, status: "vacant", titles: { en: "x" } });
  await ownerWrites("invP", "inv-live", privateListing());
  assert.equal((await publicDoc("inv-live")).is_published, false);
});

async function hideByModeration(propertyId, { preHidePublished = true } = {}) {
  await db.doc(`PropertyModeration/${propertyId}`).set({ hidden: true, pre_hide_published: preHidePublished, updated_by: "admin1" });
  await db.doc(`Properties/${propertyId}`).set({ moderation_hidden: true, is_published: false }, { merge: true });
}

async function reconcile(propertyId, { deleted = false, wasHidden = false } = {}) {
  const after = await db.doc(`PropertyModeration/${propertyId}`).get();
  await fns.reconcilePropertyModeration.run({
    params: { propertyId },
    data: {
      before: wasHidden ? { exists: true, get: (field) => (field === "hidden" ? true : undefined) } : null,
      after: deleted ? { exists: false, get: () => undefined } : after,
    },
  });
}

/** What an Admin's restore does: the moderation doc says hidden:false, then the trigger runs. */
async function liftByModeration(propertyId, { preHidePublished }) {
  await db.doc(`PropertyModeration/${propertyId}`).set({ hidden: false, pre_hide_published: preHidePublished, updated_by: "admin1" });
  await db.doc(`Properties/${propertyId}`).set({ moderation_hidden: false }, { merge: true });
  await reconcile(propertyId, { wasHidden: true });
}

test("TAQ-91: a listing hidden or verified by a moderator keeps those flags when its owner edits it", async () => {
  await ownerWrites("ownerA", "mod-1", privateListing());
  assert.equal((await publicDoc("mod-1")).verified, false);
  await db.doc("Properties/mod-1").set({ verified: true }, { merge: true });
  await hideByModeration("mod-1");

  await ownerWrites("ownerA", "mod-1", privateListing({ titles: { en: "Edited by owner" } }));
  const pub = await publicDoc("mod-1");
  assert.equal(pub.titles.en, "Edited by owner");
  assert.equal(pub.verified, true);
  assert.equal(pub.moderation_hidden, true);
  assert.equal(pub.is_published, false, "the owner cannot republish a listing moderation hid");

  await db.doc("PropertyModeration/mod-1").set({ hidden: false, pre_hide_published: true, updated_by: "admin1" });
  await ownerWrites("ownerA", "mod-1", privateListing());
  const lifted = await publicDoc("mod-1");
  assert.equal(lifted.is_published, true);
  assert.equal(lifted.moderation_hidden, false);
});

test("TAQ-91 (UT a): deleting the public doc and then editing the private doc does not republish a hidden listing", async () => {
  await ownerWrites("ownerA", "ut-a1", privateListing());
  await hideByModeration("ut-a1");
  // The rules refuse this delete for an owner (admin_investor_rules.test.js); the trigger must
  // hold even if the public doc is gone for any other reason.
  await db.doc("Properties/ut-a1").delete();
  assert.equal(await publicDoc("ut-a1"), null);

  await ownerWrites("ownerA", "ut-a1", privateListing({ titles: { en: "Edited after delete" } }));
  const pub = await publicDoc("ut-a1");
  assert.equal(pub.is_published, false);
  assert.equal(pub.moderation_hidden, true);
  assert.equal(pub.titles.en, "Edited after delete");
});

test("TAQ-91 (UT a): deleting and recreating the private doc with the same id does not republish a hidden listing", async () => {
  await ownerWrites("ownerA", "ut-a2", privateListing());
  await hideByModeration("ut-a2");

  await ownerWrites("ownerA", "ut-a2", null);
  let pub = await publicDoc("ut-a2");
  assert.ok(pub, "the hidden public doc is kept when its owner deletes the private doc");
  assert.equal(pub.is_published, false);
  assert.equal(pub.moderation_hidden, true);

  await ownerWrites("ownerA", "ut-a2", privateListing({ titles: { en: "Recreated" } }));
  pub = await publicDoc("ut-a2");
  assert.equal(pub.is_published, false);
  assert.equal(pub.moderation_hidden, true);
  assert.equal(pub.titles.en, "Recreated");
});

test("TAQ-91 (UT a): both bypasses together (public doc deleted, private doc recreated) stay hidden", async () => {
  await ownerWrites("ownerA", "ut-a3", privateListing());
  await hideByModeration("ut-a3");
  await db.doc("Properties/ut-a3").delete();
  await ownerWrites("ownerA", "ut-a3", null);
  await ownerWrites("ownerA", "ut-a3", privateListing());
  const pub = await publicDoc("ut-a3");
  assert.equal(pub.is_published, false);
  assert.equal(pub.moderation_hidden, true);
});

test("TAQ-91 (QA a): a missing moderation doc means not hidden, and a new id is a new listing", async () => {
  await ownerWrites("ownerA", "ut-a4", privateListing());
  await hideByModeration("ut-a4");
  await ownerWrites("ownerA", "ut-a4", null);
  await ownerWrites("ownerA", "ut-a4-new", privateListing());
  const fresh = await publicDoc("ut-a4-new");
  assert.equal(fresh.is_published, true);
  assert.equal(fresh.moderation_hidden, false);

  await db.doc("PropertyModeration/ut-a4").delete();
  await ownerWrites("ownerA", "ut-a4", privateListing());
  assert.equal((await publicDoc("ut-a4")).is_published, true);
});

test("TAQ-91 (UT a): a hidden listing of another owner is not reachable by reusing its id", async () => {
  await ownerWrites("ownerA", "ut-a5", privateListing());
  await hideByModeration("ut-a5");
  await ownerWrites("ownerB", "ut-a5", privateListing({ titles: { en: "Scam" } }));
  const pub = await publicDoc("ut-a5");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.is_published, false);
});

test("TAQ-91: writing a moderation hide takes a still-live public doc offline", async () => {
  await ownerWrites("ownerA", "rec-1", privateListing());
  await db.doc("PropertyModeration/rec-1").set({ hidden: true, pre_hide_published: true, updated_by: "admin1" });
  await reconcile("rec-1");
  const pub = await publicDoc("rec-1");
  assert.equal(pub.is_published, false);
  assert.equal(pub.moderation_hidden, true);
});

test("TAQ-91: lifting a hold on a listing that was not live before the hide keeps it offline", async () => {
  await ownerWrites("ownerA", "rec-2", privateListing({ isPublished: false }));
  await db.doc("Properties/rec-2").set({ id: "rec-2", owner_id: "ownerA", is_published: false, moderation_hidden: true, status: "vacant" });
  await db.doc("PropertyModeration/rec-2").set({ hidden: false, pre_hide_published: false, updated_by: "admin1" });
  await reconcile("rec-2", { wasHidden: true });
  const pub = await publicDoc("rec-2");
  assert.equal(pub.moderation_hidden, false);
  assert.equal(pub.is_published, false);
  await db.doc("PropertyModeration/rec-2").delete();
  await reconcile("rec-2", { deleted: true });
  await reconcile("no-public-doc");
  assert.equal(await publicDoc("no-public-doc"), null);
});

// --- TAQ-98: a restore never republishes a stale public doc ---

async function liveThenHidden(id, { price = 9000 } = {}) {
  await ownerWrites("ownerA", id, privateListing({ pricePerMonth: price }));
  assert.equal((await publicDoc(id)).is_published, true);
  await hideByModeration(id, { preHidePublished: true });
}

test("TAQ-98: restoring a valid listing republishes it from the owner's current private doc", async () => {
  await liveThenHidden("r1");
  await ownerWrites("ownerA", "r1", privateListing({ pricePerMonth: 9500, titles: { en: "Edited while hidden" } }));
  assert.equal((await publicDoc("r1")).is_published, false, "still hidden while the hold lasts");
  await liftByModeration("r1", { preHidePublished: true });
  const pub = await publicDoc("r1");
  assert.equal(pub.is_published, true);
  assert.equal(pub.moderation_hidden, false);
  assert.equal(pub.pricePerMonth, 9500, "the price comes from the private doc, not the stale public one");
  assert.equal(pub.titles.en, "Edited while hidden");
});

test("TAQ-98 repro: published at 9000, hidden, restored, then the owner sets the price to 0 - nothing can bring it back at 9000", async () => {
  await liveThenHidden("r2");
  await liftByModeration("r2", { preHidePublished: true });
  assert.equal((await publicDoc("r2")).is_published, true);

  await ownerWrites("ownerA", "r2", privateListing({ pricePerMonth: 0 }));
  let pub = await publicDoc("r2");
  assert.equal(pub.is_published, false, "the sync takes it offline");
  assert.equal(pub.pricePerMonth, 9000, "and leaves the stale public price (why the rules must not let anyone republish it)");

  // The only client path back online was an is_published-only Admin update; the rules now refuse
  // it (admin_investor_rules.test.js). Even a hide and restore cycle cannot republish it:
  await hideByModeration("r2", { preHidePublished: false });
  await liftByModeration("r2", { preHidePublished: false });
  pub = await publicDoc("r2");
  assert.equal(pub.is_published, false);
});

test("TAQ-98: a restore does not republish while the private doc has a zero or invalid rent", async () => {
  for (const [id, pricePerMonth] of [["r3a", 0], ["r3b", -5], ["r3c", "free"], ["r3d", null]]) {
    await liveThenHidden(id);
    await ownerWrites("ownerA", id, privateListing({ pricePerMonth }));
    await liftByModeration(id, { preHidePublished: true });
    const pub = await publicDoc(id);
    assert.equal(pub.is_published, false, id);
    assert.equal(pub.moderation_hidden, false, id);
    assert.equal(pub.pricePerMonth, 9000, `${id}: nothing rewrote the stale price into a live doc`);
  }
});

test("TAQ-98: a restore does not republish while the private doc is unpublished, rented, missing or the owner lost the role", async () => {
  await liveThenHidden("r4a");
  await ownerWrites("ownerA", "r4a", privateListing({ isPublished: false }));
  await liftByModeration("r4a", { preHidePublished: true });
  assert.equal((await publicDoc("r4a")).is_published, false);

  await liveThenHidden("r4b");
  await ownerWrites("ownerA", "r4b", privateListing({ rentalStatus: "rented" }));
  await liftByModeration("r4b", { preHidePublished: true });
  assert.equal((await publicDoc("r4b")).is_published, false);

  await liveThenHidden("r4c");
  await db.doc("Users/ownerA/properties/r4c").delete();
  await liftByModeration("r4c", { preHidePublished: true });
  assert.equal((await publicDoc("r4c")).is_published, false);

  await db.doc("Users/ownerC").set({ role: "Owner" });
  await ownerWrites("ownerC", "r4d", privateListing());
  await hideByModeration("r4d", { preHidePublished: true });
  await db.doc("Users/ownerC").set({ role: "Investor" });
  await liftByModeration("r4d", { preHidePublished: true });
  const pub = await publicDoc("r4d");
  assert.equal(pub.is_published, false, "the owner no longer holds a publishing role");
  assert.equal(pub.owner_id, "ownerC");
});

test("TAQ-98: a restore never publishes what was not live before the hide, even if the private doc wants to be", async () => {
  await ownerWrites("ownerA", "r5", privateListing());
  await db.doc("Properties/r5").set({ is_published: false }, { merge: true });
  await hideByModeration("r5", { preHidePublished: false });
  await liftByModeration("r5", { preHidePublished: false });
  assert.equal((await publicDoc("r5")).is_published, false);
});

test("TAQ-98: a moderation doc written again (still not hidden) does not republish anything", async () => {
  await liveThenHidden("r6");
  await liftByModeration("r6", { preHidePublished: true });
  await db.doc("Properties/r6").set({ is_published: false }, { merge: true });
  await db.doc("PropertyModeration/r6").set({ hidden: false, pre_hide_published: true, updated_by: "admin1" });
  await reconcile("r6", { wasHidden: false });
  assert.equal((await publicDoc("r6")).is_published, false);
});

test("TAQ-98: a deleted moderation doc lifts the hold but, with no pre-hide value, publishes nothing", async () => {
  await liveThenHidden("r7");
  await db.doc("PropertyModeration/r7").delete();
  await reconcile("r7", { deleted: true, wasHidden: true });
  const pub = await publicDoc("r7");
  assert.equal(pub.moderation_hidden, false);
  assert.equal(pub.is_published, false);
});

test("TAQ-98: a hold re-applied after the lift cannot be undone by a stale lift event", async () => {
  await liveThenHidden("r8");
  await db.doc("PropertyModeration/r8").set({ hidden: false, pre_hide_published: true, updated_by: "admin1" });
  await db.doc("PropertyModeration/r8").set({ hidden: true, pre_hide_published: true, updated_by: "admin1" });
  await reconcile("r8", { wasHidden: true });
  assert.equal((await db.doc("PropertyModeration/r8").get()).get("hidden"), true);
  const pub = await publicDoc("r8");
  assert.equal(pub.is_published, false);
  assert.equal(pub.moderation_hidden, true);
});

test("TAQ-91: the backfill script adds a moderation doc for listings hidden before PropertyModeration existed", async () => {
  const { backfill } = require("../scripts/backfill_property_moderation");
  await ownerWrites("ownerA", "legacy-hidden", privateListing());
  await db.doc("Properties/legacy-hidden").set({ moderation_hidden: true, is_published: false }, { merge: true });
  await ownerWrites("ownerA", "visible", privateListing());
  await ownerWrites("ownerA", "already", privateListing());
  await db.doc("Properties/already").set({ moderation_hidden: true, is_published: false }, { merge: true });
  await db.doc("PropertyModeration/already").set({ hidden: true, pre_hide_published: true, updated_by: "admin1" });

  const dry = await backfill(db);
  assert.deepEqual(dry.missing, ["legacy-hidden"]);
  assert.equal((await db.doc("PropertyModeration/legacy-hidden").get()).exists, false, "a dry run writes nothing");

  await backfill(db, { apply: true });
  const created = (await db.doc("PropertyModeration/legacy-hidden").get()).data();
  assert.equal(created.hidden, true);
  assert.equal(created.pre_hide_published, false);
  assert.equal((await db.doc("PropertyModeration/visible").get()).exists, false);
  assert.equal((await db.doc("PropertyModeration/already").get()).get("pre_hide_published"), true, "existing docs are untouched");
  assert.deepEqual((await backfill(db)).missing, []);

  // the hold now survives the UT bypass
  await db.doc("Properties/legacy-hidden").delete();
  await ownerWrites("ownerA", "legacy-hidden", privateListing());
  assert.equal((await publicDoc("legacy-hidden")).is_published, false);
});
