const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs,
  serverTimestamp,
  writeBatch,
  deleteField,
} = require("firebase/firestore");

// TAQ-91: the Admin (platform staff) and Investor roles in firestore.rules.

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test",
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

const CLAIMS = {
  admin: { role: "Admin" },
  superAdmin: { role: "SuperAdmin" },
  investor: { role: "Investor" },
  owner: { role: "Owner" },
  agency: { role: "AgencyAdmin", agency_id: "agency-1" },
};

function as(uid, claims) {
  return testEnv.authenticatedContext(uid, claims || {}).firestore();
}

async function seed(docPath, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), docPath), data);
  });
}

const live = {
  id: "live",
  owner_id: "ownerA",
  countryCode: "AE",
  currencyCode: "AED",
  titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" },
  pricePerMonth: 9000,
  status: "vacant",
  is_published: true,
};

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed("Users/ownerA", { user_id: "ownerA", role: "Owner", email: "a@x.test", iban: "AE070331234567890123456", national_id: "784-1990-1234567-1" });
  await seed("Users/ownerA/properties/live", { owner_id: "ownerA", tenant_name: "Private Tenant" });
  await seed("Users/investor1", { user_id: "investor1", role: "Investor" });
  await seed("Users/admin1", { user_id: "admin1", role: "Admin" });
  await seed("Properties/live", live);
  await seed("Properties/hidden", { ...live, id: "hidden", is_published: false, moderation_hidden: true });
  await seed("PropertyModeration/hidden", { hidden: true, pre_hide_published: true, updated_by: "admin1" });
  await seed("Properties/rented", { ...live, id: "rented", is_published: false, moderation_hidden: true, status: "rented" });
  await seed("PropertyModeration/rented", { hidden: true, pre_hide_published: true, updated_by: "admin1" });
  await seed("Properties/hiddenDraft", { ...live, id: "hiddenDraft", is_published: false, moderation_hidden: true });
  await seed("PropertyModeration/hiddenDraft", { hidden: true, pre_hide_published: false, updated_by: "admin1" });
  await seed("Properties/draft", { ...live, id: "draft", is_published: false, status: "unavailable" });
  await seed("Agencies/agency-1", { name: "Agency One", verified_badge: false });
  await seed("Agencies/agency-1/private/bank", { iban: "AE070331234567890123456" });
  await seed("Leases/lease-1", { owner_id: "ownerA", tenant_id: "tenantA", agency_id: "agency-1" });
  await seed("Invoices/inv-1", { owner_id: "ownerA", tenant_id: "tenantA", agency_id: "agency-1" });
  await seed("Maintenance/m-1", { owner_id: "ownerA", tenant_id: "tenantA", agency_id: "agency-1", status: "open", title: "Leak" });
  await seed("Telemetry_Crashes/c-1", { message: "boom", isFatal: false, platform: "web" });
  await seed("AiRateLimits/uid_x", { minuteCount: 1 });
});

// --- Investor: signup and no escalation ---

test("TAQ-91: signup can pick Owner, Tenant or Investor, and nothing above them", async () => {
  for (const role of ["Owner", "Tenant", "Investor"]) {
    await assertSucceeds(setDoc(doc(as(`new-${role}`), `Users/new-${role}`), { user_id: `new-${role}`, role }));
  }
  for (const role of ["Admin", "SuperAdmin", "AgencyAdmin", "investor", "Broker", ""]) {
    await assertFails(setDoc(doc(as("mallory"), "Users/mallory"), { user_id: "mallory", role }));
  }
});

test("TAQ-91: an Investor cannot change their role, add an agency or flag themselves verified", async () => {
  const me = as("investor1");
  for (const role of ["Owner", "Tenant", "Admin", "SuperAdmin", "AgencyAdmin"]) {
    await assertFails(updateDoc(doc(me, "Users/investor1"), { role }));
  }
  await assertFails(updateDoc(doc(me, "Users/investor1"), { agency_id: "agency-1" }));
  await assertFails(updateDoc(doc(me, "Users/investor1"), { verified: true }));
  await assertSucceeds(updateDoc(doc(me, "Users/investor1"), { full_name: "Inv Estor" }));
});

test("TAQ-91: a profile that says Admin grants nothing without the claim", async () => {
  const me = as("admin1");
  await assertFails(updateDoc(doc(me, "Properties/live"), { verified: true, updated_at: serverTimestamp() }));
  await assertFails(getDoc(doc(me, "Properties/draft")));
  await assertFails(getDoc(doc(me, "Telemetry_Crashes/c-1")));
});

test("TAQ-91: a claimed Investor is an Investor even if the profile says Owner", async () => {
  await seed("Users/mixed", { role: "Owner" });
  const me = as("mixed", CLAIMS.investor);
  await assertFails(setDoc(doc(me, "Users/mixed/properties/p1"), { owner_id: "mixed" }));
});

// --- Investor: what they can and cannot reach ---

test("TAQ-91: an Investor reads published listings, agencies and nothing private", async () => {
  const me = as("investor1", CLAIMS.investor);
  await assertSucceeds(getDoc(doc(me, "Properties/live")));
  await assertSucceeds(getDocs(query(collection(me, "Properties"), where("is_published", "==", true))));
  await assertSucceeds(getDoc(doc(me, "Agencies/agency-1")));
  await assertSucceeds(getDoc(doc(me, "Users/investor1")));
  await assertFails(getDoc(doc(me, "Properties/draft")));
  await assertFails(getDoc(doc(me, "Properties/hidden")));
  await assertFails(getDocs(query(collection(me, "Properties"), where("is_published", "==", false))));
  await assertFails(getDoc(doc(me, "Users/ownerA")));
  await assertFails(getDoc(doc(me, "Users/ownerA/properties/live")));
  await assertFails(getDoc(doc(me, "Agencies/agency-1/private/bank")));
});

test("TAQ-91: an Investor has no access to leases, invoices, maintenance, telemetry or quotas", async () => {
  for (const claims of [CLAIMS.investor, undefined]) {
    const me = as("investor1", claims);
    await assertFails(getDoc(doc(me, "Leases/lease-1")));
    await assertFails(getDocs(collection(me, "Leases")));
    await assertFails(getDoc(doc(me, "Invoices/inv-1")));
    await assertFails(getDoc(doc(me, "Maintenance/m-1")));
    await assertFails(getDocs(collection(me, "Maintenance")));
    await assertFails(getDoc(doc(me, "Telemetry_Crashes/c-1")));
    await assertFails(getDoc(doc(me, "AiRateLimits/uid_x")));
  }
});

test("TAQ-91: an Investor cannot publish, edit or delete listings, nor create private drafts", async () => {
  for (const claims of [CLAIMS.investor, undefined]) {
    const me = as("investor1", claims);
    await assertFails(setDoc(doc(me, "Properties/inv-listing"), { ...live, id: "inv-listing", owner_id: "investor1" }));
    await assertFails(updateDoc(doc(me, "Properties/live"), { pricePerMonth: 1 }));
    await assertFails(deleteDoc(doc(me, "Properties/live")));
    await assertFails(setDoc(doc(me, "Users/investor1/properties/p1"), { owner_id: "investor1", isPublished: true }));
  }
});

test("TAQ-91: an Investor cannot create leases, invoices, maintenance requests or agencies", async () => {
  const me = as("investor1", CLAIMS.investor);
  await assertFails(setDoc(doc(me, "Leases/l2"), { owner_id: "investor1", tenant_id: "investor1", agency_id: "agency-1" }));
  await assertFails(setDoc(doc(me, "Invoices/i2"), { owner_id: "investor1" }));
  await assertFails(setDoc(doc(me, "Maintenance/m2"), { tenant_id: "investor1", status: "open" }));
  await assertFails(setDoc(doc(me, "Agencies/agency-x"), { name: "Mine" }));
});

// --- Admin: moderation ---

test("TAQ-91: an Admin can see every listing, including unpublished and hidden ones", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const id of ["live", "hidden", "rented", "draft"]) await assertSucceeds(getDoc(doc(me, `Properties/${id}`)));
  await assertSucceeds(getDocs(query(collection(me, "Properties"), where("is_published", "==", false))));
});

const stamp = () => serverTimestamp();

/**
 * What the app's Admin dashboard writes: the moderation doc and the public doc in one batch. A hide
 * takes the listing offline; a restore only lifts the flag (the server republishes, see
 * sync.test.js), so no client write ever sets is_published to true.
 */
function moderate(ctx, id, { hidden, preHidePublished, publicChange }) {
  const batch = writeBatch(ctx);
  batch.set(doc(ctx, `PropertyModeration/${id}`), {
    hidden,
    pre_hide_published: preHidePublished,
    updated_by: ctx._uid,
    updated_at: stamp(),
  });
  const change = publicChange || (hidden ? { is_published: false, moderation_hidden: true } : { moderation_hidden: false });
  batch.update(doc(ctx, `Properties/${id}`), { ...change, updated_at: stamp() });
  return batch.commit();
}

function admin(uid = "admin1") {
  const ctx = as(uid, CLAIMS.admin);
  ctx._uid = uid;
  return ctx;
}

test("TAQ-91: an Admin can verify and unverify a listing", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { verified: true, updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { verified: false, updated_at: serverTimestamp() }));
});

test("TAQ-91 (UT a/c): a hide writes the moderation doc together with the public doc and records is_published", async () => {
  const me = admin();
  await assertSucceeds(moderate(me, "live", { hidden: true, preHidePublished: true, isPublished: false }));
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const mod = (await getDoc(doc(ctx.firestore(), "PropertyModeration/live"))).data();
    assert.equal(mod.hidden, true);
    assert.equal(mod.pre_hide_published, true);
    assert.equal(mod.updated_by, "admin1");
    const pub = (await getDoc(doc(ctx.firestore(), "Properties/live"))).data();
    assert.equal(pub.is_published, false);
    assert.equal(pub.moderation_hidden, true);
    assert.equal("pre_hide_published" in pub, false, "the pre-hide value is not stored on the public doc");
  });
});

test("TAQ-91 (UT c): hiding a never-published listing records false, and a restore cannot publish it", async () => {
  await seed("Properties/offline", { ...live, id: "offline", is_published: false });
  const me = admin();
  await assertFails(moderate(me, "offline", { hidden: true, preHidePublished: true }));
  await assertSucceeds(moderate(me, "offline", { hidden: true, preHidePublished: false }));
  await assertFails(moderate(me, "offline", { hidden: false, preHidePublished: false, publicChange: { is_published: true, moderation_hidden: false } }));
  await assertSucceeds(moderate(me, "offline", { hidden: false, preHidePublished: false }));
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    assert.equal((await getDoc(doc(ctx.firestore(), "Properties/offline"))).data().is_published, false);
  });
});

test("TAQ-91 (UT c): a restore cannot rewrite the stored pre-hide value", async () => {
  const me = admin();
  await assertFails(moderate(me, "hiddenDraft", { hidden: false, preHidePublished: true }));
  await assertSucceeds(moderate(me, "hiddenDraft", { hidden: false, preHidePublished: false }));
  await assertFails(moderate(admin(), "hidden", { hidden: false, preHidePublished: false }));
  await assertSucceeds(moderate(admin(), "hidden", { hidden: false, preHidePublished: true }));
});

// --- TAQ-98: a restore (or any visibility change) cannot republish a stale public doc ---

/** The UT repro: published at 9000, hidden, restored, then the owner sets the price to 0. The sync
 *  takes the listing offline but leaves the public price at 9000. */
async function seedStaleOffline(id = "stale") {
  await seed(`Properties/${id}`, { ...live, id, is_published: false, moderation_hidden: false, pricePerMonth: 9000 });
  await seed(`PropertyModeration/${id}`, { hidden: false, pre_hide_published: true, updated_by: "admin1" });
  await seed(`Users/ownerA/properties/${id}`, { owner_id: "ownerA", isPublished: true, rentalStatus: "available", pricePerMonth: 0 });
}

test("TAQ-98: an Admin cannot republish a stale public doc with an is_published-only update", async () => {
  await seedStaleOffline();
  const me = admin();
  await assertFails(updateDoc(doc(me, "Properties/stale"), { is_published: true, updated_at: stamp() }));
  await assertFails(updateDoc(doc(me, "Properties/stale"), { is_published: true }));
  await assertFails(updateDoc(doc(me, "Properties/stale"), { is_published: true, moderation_hidden: false, updated_at: stamp() }));
});

test("TAQ-98: a SuperAdmin cannot republish a stale public doc directly either", async () => {
  await seedStaleOffline();
  const root = as("root", CLAIMS.superAdmin);
  await assertFails(updateDoc(doc(root, "Properties/stale"), { is_published: true, updated_at: stamp() }));
  await assertFails(updateDoc(doc(root, "Properties/stale"), { is_published: true, moderation_hidden: false, updated_at: stamp() }));
  await assertFails(setDoc(doc(root, "Properties/stale"), { ...live, id: "stale", moderation_hidden: true, is_published: true }));
});

test("TAQ-98: a batch with a moderation write still cannot set is_published to true", async () => {
  await seedStaleOffline();
  for (const me of [admin(), Object.assign(as("root", CLAIMS.superAdmin), { _uid: "root" })]) {
    for (const hidden of [false, true]) {
      await assertFails(moderate(me, "stale", { hidden, preHidePublished: true, publicChange: { is_published: true, moderation_hidden: hidden } }));
    }
  }
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    assert.equal((await getDoc(doc(ctx.firestore(), "Properties/stale"))).data().is_published, false);
  });
});

test("TAQ-98: visibility flags only change in the same batch as a PropertyModeration write", async () => {
  await seedStaleOffline();
  const me = admin();
  // moderation_hidden alone, no moderation write in the request
  await assertFails(updateDoc(doc(me, "Properties/stale"), { moderation_hidden: true, updated_at: stamp() }));
  await assertFails(updateDoc(doc(me, "Properties/live"), { is_published: false, updated_at: stamp() }));
  await assertFails(updateDoc(doc(me, "Properties/live"), { is_published: false, moderation_hidden: true, updated_at: stamp() }));
  // a moderation write that happened earlier (stale updated_at) does not count
  await seed("PropertyModeration/live", { hidden: true, pre_hide_published: true, updated_by: "admin1", updated_at: new Date("2026-01-01") });
  await assertFails(updateDoc(doc(me, "Properties/live"), { is_published: false, moderation_hidden: true, updated_at: stamp() }));
  // the moderation write for a different listing does not count
  const batch = writeBatch(me);
  batch.set(doc(me, "PropertyModeration/hiddenDraft"), { hidden: true, pre_hide_published: false, updated_by: "admin1", updated_at: stamp() });
  batch.update(doc(me, "Properties/stale"), { moderation_hidden: true, updated_at: stamp() });
  await assertFails(batch.commit());
  // while the matching batch is accepted
  await assertSucceeds(moderate(me, "stale", { hidden: true, preHidePublished: false }));
});

test("TAQ-98: the moderation doc and the public mirror must agree in the batch", async () => {
  const me = admin();
  await assertFails(moderate(me, "live", { hidden: true, preHidePublished: true, publicChange: { is_published: false, moderation_hidden: false } }));
  await assertFails(moderate(me, "live", { hidden: false, preHidePublished: false, publicChange: { is_published: false, moderation_hidden: true } }));
  await assertSucceeds(moderate(me, "hidden", { hidden: false, preHidePublished: true }));
});

test("TAQ-98: a SuperAdmin hide and restore also go through the moderation batch", async () => {
  const root = Object.assign(as("root", CLAIMS.superAdmin), { _uid: "root" });
  await assertSucceeds(moderate(root, "live", { hidden: true, preHidePublished: true }));
  await assertSucceeds(moderate(root, "live", { hidden: false, preHidePublished: true }));
  await assertSucceeds(updateDoc(doc(root, "Properties/live"), { rating: 4, verified: true, updated_at: stamp() }));
});

test("TAQ-91 (QA a): the public doc cannot be hidden or restored without the matching moderation doc", async () => {
  const me = admin();
  await assertFails(updateDoc(doc(me, "Properties/live"), { is_published: false, moderation_hidden: true, updated_at: stamp() }));
  await assertFails(updateDoc(doc(me, "Properties/live"), { is_published: false, updated_at: stamp() }));
  await assertFails(updateDoc(doc(me, "Properties/hidden"), { is_published: true, moderation_hidden: false, updated_at: stamp() }));
  await assertFails(updateDoc(doc(me, "Properties/hidden"), { is_published: true, updated_at: stamp() }));
  await assertFails(updateDoc(doc(me, "Properties/live"), { moderation_hidden: true, updated_at: stamp() }));
  // a hide recorded without the public doc change is allowed by the rules; reconcilePropertyModeration
  // (tested in sync.test.js) then takes the public doc offline
  const batch = writeBatch(me);
  batch.set(doc(me, "PropertyModeration/live"), { hidden: true, pre_hide_published: true, updated_by: "admin1", updated_at: stamp() });
  batch.update(doc(me, "Properties/live"), { verified: true, updated_at: stamp() });
  await assertSucceeds(batch.commit());
});

test("TAQ-91 (QA a): Admin writes to the moderation doc are limited to its four fields, and only SuperAdmin deletes", async () => {
  const me = admin();
  const base = { hidden: true, pre_hide_published: true, updated_by: "admin1", updated_at: stamp() };
  await assertFails(setDoc(doc(me, "PropertyModeration/live"), { ...base, note: "x" }));
  await assertFails(setDoc(doc(me, "PropertyModeration/live"), { ...base, hidden: "yes" }));
  await assertFails(setDoc(doc(me, "PropertyModeration/live"), { ...base, updated_by: "someone-else" }));
  await assertFails(setDoc(doc(me, "PropertyModeration/live"), { ...base, updated_at: new Date(0) }));
  await assertFails(setDoc(doc(me, "PropertyModeration/live"), { ...base, pre_hide_published: false }), "must match the live public doc");
  await assertFails(setDoc(doc(me, "PropertyModeration/ghost"), base), "no public doc to hide");
  await assertFails(setDoc(doc(me, "PropertyModeration/live"), { ...base, hidden: false }), "a first write must be a hide");
  await assertSucceeds(setDoc(doc(me, "PropertyModeration/live"), base));
  await assertFails(updateDoc(doc(me, "PropertyModeration/live"), { pre_hide_published: false, updated_by: "admin1", updated_at: stamp() }));
  await assertFails(deleteDoc(doc(me, "PropertyModeration/live")));
  await assertSucceeds(getDoc(doc(me, "PropertyModeration/live")));
  await assertSucceeds(deleteDoc(doc(as("root", CLAIMS.superAdmin), "PropertyModeration/hidden")));
});

test("TAQ-91 (QA a): owners, agencies, tenants, investors and visitors cannot touch PropertyModeration", async () => {
  const base = { hidden: false, pre_hide_published: false, updated_by: "ownerA", updated_at: stamp() };
  const actors = [
    as("ownerA", CLAIMS.owner),
    as("agent", CLAIMS.agency),
    as("tenantA", { role: "Tenant" }),
    as("investor1", CLAIMS.investor),
    as("stranger"),
    testEnv.unauthenticatedContext().firestore(),
  ];
  for (const me of actors) {
    await assertFails(getDoc(doc(me, "PropertyModeration/hidden")));
    await assertFails(getDocs(collection(me, "PropertyModeration")));
    // creating it first for their own listing, to pre-empt a moderator
    await assertFails(setDoc(doc(me, "PropertyModeration/live"), base));
    await assertFails(setDoc(doc(me, "PropertyModeration/live"), { ...base, hidden: true, pre_hide_published: true }));
    await assertFails(setDoc(doc(me, "PropertyModeration/new-id"), base));
    // lifting or rewriting the hold
    await assertFails(updateDoc(doc(me, "PropertyModeration/hidden"), { hidden: false }));
    await assertFails(setDoc(doc(me, "PropertyModeration/hidden"), base));
    await assertFails(deleteDoc(doc(me, "PropertyModeration/hidden")));
  }
});

test("TAQ-91 (UT a): an owner or agency cannot delete the public doc of a moderation-hidden listing", async () => {
  const owner = as("ownerA", CLAIMS.owner);
  const agency = as("agent", CLAIMS.agency);
  await seed("Properties/hidden", { ...live, id: "hidden", is_published: false, moderation_hidden: true, agency_id: "agency-1" });
  await assertFails(deleteDoc(doc(owner, "Properties/hidden")));
  await assertFails(deleteDoc(doc(agency, "Properties/hidden")));
  await assertFails(deleteDoc(doc(owner, "Properties/hiddenDraft")));
  // the mirror flag on the public doc is not what protects it: the moderation doc is
  await seed("Properties/hiddenMirrorOnly", { ...live, id: "hiddenMirrorOnly", is_published: false, moderation_hidden: true });
  await assertSucceeds(deleteDoc(doc(owner, "Properties/hiddenMirrorOnly")));
  // an ordinary listing can still be removed by its owner and by the platform
  await assertSucceeds(deleteDoc(doc(owner, "Properties/live")));
  await assertSucceeds(deleteDoc(doc(as("root", CLAIMS.superAdmin), "Properties/hidden")));
});

test("TAQ-91 (UT a): lifting the hold makes the owner's delete possible again", async () => {
  await assertSucceeds(moderate(admin(), "hidden", { hidden: false, preHidePublished: true, isPublished: true }));
  await assertSucceeds(deleteDoc(doc(as("ownerA", CLAIMS.owner), "Properties/hidden")));
});

test("TAQ-91 (QA a): an owner recreating the private doc under a NEW id is a new listing, with no moderation", async () => {
  const owner = as("ownerA", CLAIMS.owner);
  await assertSucceeds(setDoc(doc(owner, "Users/ownerA/properties/brand-new"), { owner_id: "ownerA", isPublished: true }));
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    assert.equal((await getDoc(doc(ctx.firestore(), "PropertyModeration/brand-new"))).exists(), false);
  });
  // ...but an owner can only create the private doc; the public doc is written by the sync trigger.
  await assertFails(setDoc(doc(owner, "Properties/brand-new"), { ...live, id: "brand-new" }));
});

test("TAQ-91: an Admin cannot edit listing content, ownership or ratings, create or delete listings", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const change of [
    { pricePerMonth: 1 },
    { owner_id: "admin1" },
    { agency_id: "agency-1" },
    { rating: 5 },
    { isFeatured: true },
    { titles: { en: "Hacked" } },
    { status: "rented" },
    { verified: "yes" },
    { phone: "+201001234567" },
  ]) {
    await assertFails(updateDoc(doc(me, "Properties/live"), { ...change, updated_at: serverTimestamp() }));
  }
  await assertFails(updateDoc(doc(me, "Properties/live"), { verified: true, updated_at: new Date(0) }));
  await assertFails(setDoc(doc(me, "Properties/admin-made"), { ...live, id: "admin-made" }));
  await assertFails(deleteDoc(doc(me, "Properties/live")));
  await assertFails(deleteDoc(doc(me, "Properties/draft")));
});

// --- Admin: users and agencies are read-only and never expose IBAN or national ID ---

test("TAQ-91: an Admin cannot read user profiles or owner private data (IBAN, national ID)", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(getDoc(doc(me, "Users/ownerA")));
  await assertFails(getDocs(collection(me, "Users")));
  await assertFails(getDoc(doc(me, "Users/ownerA/properties/live")));
  await assertFails(getDocs(collection(me, "Users/ownerA/properties")));
  await assertFails(getDoc(doc(me, "Agencies/agency-1/private/bank")));
  await assertSucceeds(getDoc(doc(me, "Users/admin1")));
});

test("TAQ-91: an Admin cannot create, edit or delete users, or write any role or claim field", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(updateDoc(doc(me, "Users/ownerA"), { full_name: "x" }));
  await assertFails(updateDoc(doc(me, "Users/ownerA"), { role: "SuperAdmin" }));
  await assertFails(deleteDoc(doc(me, "Users/ownerA")));
  await assertFails(setDoc(doc(me, "Users/newcomer"), { user_id: "newcomer", role: "SuperAdmin" }));
  await assertFails(setDoc(doc(me, "Users/newcomer"), { user_id: "newcomer", role: "Admin" }));
  await assertFails(setDoc(doc(me, "Users/newcomer"), { user_id: "newcomer", role: "Owner" }));
});

test("TAQ-91: an Admin cannot escalate itself", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const change of [
    { role: "SuperAdmin" },
    { role: "AgencyAdmin" },
    { role: "Owner" },
    { agency_id: "agency-1" },
    { isSuperAdmin: true },
    { customClaims: { role: "SuperAdmin" } },
    { claims: { role: "SuperAdmin" } },
    { Role: "SuperAdmin" },
    { verified: true },
  ]) {
    await assertFails(updateDoc(doc(me, "Users/admin1"), change));
  }
  await assertFails(setDoc(doc(me, "Users/admin1"), { user_id: "admin1", role: "SuperAdmin" }));
  await assertFails(deleteDoc(doc(me, "Users/admin1")));
});

test("TAQ-91: an Admin can read agencies but cannot create, edit, verify or delete them", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(getDoc(doc(me, "Agencies/agency-1")));
  await assertFails(setDoc(doc(me, "Agencies/agency-2"), { name: "New" }));
  await assertFails(updateDoc(doc(me, "Agencies/agency-1"), { name: "Renamed" }));
  await assertFails(updateDoc(doc(me, "Agencies/agency-1"), { verified_badge: true }));
  await assertFails(deleteDoc(doc(me, "Agencies/agency-1")));
  await assertFails(setDoc(doc(me, "Agencies/agency-1/private/bank"), { iban: "x" }));
});

// --- Admin: leases, payments, settings ---

test("TAQ-91: an Admin has no access to leases, invoices or rate-limit counters", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(getDoc(doc(me, "Leases/lease-1")));
  await assertFails(getDocs(collection(me, "Leases")));
  await assertFails(setDoc(doc(me, "Leases/l2"), { owner_id: "x", agency_id: "agency-1" }));
  await assertFails(updateDoc(doc(me, "Leases/lease-1"), { tenant_id: "admin1" }));
  await assertFails(deleteDoc(doc(me, "Leases/lease-1")));
  await assertFails(getDoc(doc(me, "Invoices/inv-1")));
  await assertFails(setDoc(doc(me, "Invoices/i2"), { owner_id: "x" }));
  await assertFails(getDoc(doc(me, "AiRateLimits/uid_x")));
  await assertFails(setDoc(doc(me, "AiRateLimits/uid_x"), { minuteCount: 0 }));
});

test("TAQ-91: an Admin gets nothing from collections the rules do not name (settings, config, secrets)", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const p of ["Settings/system", "RemoteConfig/app", "Config/payments", "PaymentConfig/gateway", "Secrets/gemini", "MarketIndices/EG"]) {
    await assertFails(getDoc(doc(me, p)));
    await assertFails(setDoc(doc(me, p), { value: 1 }));
  }
});

// --- Admin: reports and maintenance escalations ---

test("TAQ-91: an Admin can read crash reports but not change or delete them", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(getDoc(doc(me, "Telemetry_Crashes/c-1")));
  await assertSucceeds(getDocs(collection(me, "Telemetry_Crashes")));
  await assertFails(updateDoc(doc(me, "Telemetry_Crashes/c-1"), { message: "x" }));
  await assertFails(deleteDoc(doc(me, "Telemetry_Crashes/c-1")));
});

test("TAQ-91: an Admin can read and escalate maintenance requests, and only change the escalation fields", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(getDoc(doc(me, "Maintenance/m-1")));
  await assertSucceeds(getDocs(collection(me, "Maintenance")));
  await assertSucceeds(updateDoc(doc(me, "Maintenance/m-1"), { status: "escalated", escalated: true, resolution_note: "Sent to agency", updated_at: serverTimestamp() }));
  await assertFails(updateDoc(doc(me, "Maintenance/m-1"), { tenant_id: "admin1" }));
  await assertFails(updateDoc(doc(me, "Maintenance/m-1"), { owner_id: "admin1" }));
  await assertFails(updateDoc(doc(me, "Maintenance/m-1"), { title: "Rewritten" }));
  await assertFails(deleteDoc(doc(me, "Maintenance/m-1")));
  await assertFails(setDoc(doc(me, "Maintenance/m2"), { tenant_id: "admin1", status: "open" }));
});

test("TAQ-91: maintenance requests stay with their parties and staff", async () => {
  await assertSucceeds(getDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/m-1")));
  await assertSucceeds(getDoc(doc(as("ownerA", CLAIMS.owner), "Maintenance/m-1")));
  await assertSucceeds(getDoc(doc(as("agent", CLAIMS.agency), "Maintenance/m-1")));
  await assertSucceeds(getDoc(doc(as("root", CLAIMS.superAdmin), "Maintenance/m-1")));
  await assertFails(getDoc(doc(as("stranger", CLAIMS.owner), "Maintenance/m-1")));
  await assertFails(getDoc(doc(as("stranger", { role: "Tenant" }), "Maintenance/m-1")));
  await assertFails(getDoc(doc(as("stranger"), "Maintenance/m-1")));
  const request = { lease_id: "lease-1", tenant_id: "tenantA", owner_id: "ownerA", agency_id: "agency-1", status: "open" };
  await assertSucceeds(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/m2"), request));
  await assertFails(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/m3"), { ...request, tenant_id: "someoneElse" }));
});

// --- TAQ-91 UT (b): a maintenance request must match a lease that links its parties ---

test("TAQ-91 (UT b): a maintenance create must match the lease's tenant, owner and agency", async () => {
  const tenant = as("tenantA", { role: "Tenant" });
  const owner = as("ownerA", CLAIMS.owner);
  const ok = { lease_id: "lease-1", tenant_id: "tenantA", owner_id: "ownerA", agency_id: "agency-1", status: "open" };
  await assertSucceeds(setDoc(doc(tenant, "Maintenance/ok-t"), ok));
  await assertSucceeds(setDoc(doc(owner, "Maintenance/ok-o"), ok));

  // tenant mismatched: the caller names some other tenant
  await assertFails(setDoc(doc(tenant, "Maintenance/bad-t"), { ...ok, tenant_id: "tenantB" }));
  await assertFails(setDoc(doc(owner, "Maintenance/bad-t2"), { ...ok, tenant_id: "tenantB" }));
  // owner mismatched: the tenant addresses a request to an unrelated owner
  await assertFails(setDoc(doc(tenant, "Maintenance/bad-o"), { ...ok, owner_id: "ownerB" }));
  await assertFails(setDoc(doc(owner, "Maintenance/bad-o2"), { ...ok, owner_id: "ownerB" }));
  // agency mismatched, missing or invented
  await assertFails(setDoc(doc(tenant, "Maintenance/bad-a"), { ...ok, agency_id: "agency-2" }));
  await assertFails(setDoc(doc(tenant, "Maintenance/bad-a2"), { lease_id: "lease-1", tenant_id: "tenantA", owner_id: "ownerA", status: "open" }));
  await seed("Leases/lease-noagency", { owner_id: "ownerA", tenant_id: "tenantA" });
  await assertSucceeds(setDoc(doc(tenant, "Maintenance/ok-na"), { lease_id: "lease-noagency", tenant_id: "tenantA", owner_id: "ownerA", status: "open" }));
  await assertFails(setDoc(doc(tenant, "Maintenance/bad-a3"), { lease_id: "lease-noagency", tenant_id: "tenantA", owner_id: "ownerA", agency_id: "agency-1", status: "open" }));
});

test("TAQ-91 (UT b): a maintenance create needs a real lease and a caller who is its tenant or owner", async () => {
  const ok = { lease_id: "lease-1", tenant_id: "tenantA", owner_id: "ownerA", agency_id: "agency-1", status: "open" };
  await assertFails(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/n1"), { ...ok, lease_id: "no-such-lease" }));
  await assertFails(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/n3"), { ...ok, lease_id: "" }));
  await assertFails(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/n4"), { ...ok, lease_id: 5 }));
  await assertFails(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/n5"), { tenant_id: "tenantA", owner_id: "ownerA", status: "open" }));
  // someone who is neither party names the real parties of a real lease
  await assertFails(setDoc(doc(as("stranger", { role: "Tenant" }), "Maintenance/n6"), ok));
  await assertFails(setDoc(doc(as("stranger", CLAIMS.owner), "Maintenance/n7"), ok));
  await assertFails(setDoc(doc(as("agent", CLAIMS.agency), "Maintenance/n8"), ok));
  // roles without maintenance access, and the Investor posing as the lease's tenant
  await seed("Leases/lease-inv", { owner_id: "ownerA", tenant_id: "investor1" });
  await assertFails(setDoc(doc(as("investor1", CLAIMS.investor), "Maintenance/n9"), { lease_id: "lease-inv", tenant_id: "investor1", owner_id: "ownerA", status: "open" }));
  await assertFails(setDoc(doc(as("admin1", CLAIMS.admin), "Maintenance/n10"), ok));
  await assertFails(setDoc(doc(testEnv.unauthenticatedContext().firestore(), "Maintenance/n11"), ok));
  await assertSucceeds(setDoc(doc(as("root", CLAIMS.superAdmin), "Maintenance/n12"), { tenant_id: "x", owner_id: "y" }));
});

// --- SuperAdmin keeps full access ---

test("TAQ-91: a SuperAdmin still has full access", async () => {
  const me = as("root", CLAIMS.superAdmin);
  await assertSucceeds(getDoc(doc(me, "Users/ownerA")));
  await assertSucceeds(getDoc(doc(me, "Leases/lease-1")));
  await assertSucceeds(getDoc(doc(me, "Agencies/agency-1/private/bank")));
  await assertSucceeds(getDoc(doc(me, "Telemetry_Crashes/c-1")));
  await assertSucceeds(updateDoc(doc(me, "Agencies/agency-1"), { verified_badge: true }));
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { rating: 4, isFeatured: true, verified: true, updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(me, "Maintenance/m-1"), { title: "Changed" }));
});

test("TAQ-91: Owner, Tenant and AgencyAdmin behaviour is unchanged", async () => {
  const owner = as("ownerA", CLAIMS.owner);
  await assertSucceeds(getDoc(doc(owner, "Users/ownerA/properties/live")));
  await assertSucceeds(setDoc(doc(owner, "Users/ownerA/properties/p2"), { owner_id: "ownerA" }));
  await assertFails(getDoc(doc(as("tenantA", { role: "Tenant" }), "Leases/lease-2")));
  await assertSucceeds(getDoc(doc(as("tenantA", { role: "Tenant" }), "Leases/lease-1")));
  await assertSucceeds(getDoc(doc(as("agent", CLAIMS.agency), "Leases/lease-1")));
});

// --- TAQ-101: staff edits of a large, sync-shaped listing stay inside the 1000-expression budget ---

const BUDGET_PROJECT = process.env.GCLOUD_PROJECT || "demo-tashil-test";
const bigImage = (n) => `https://firebasestorage.googleapis.com/v0/b/${BUDGET_PROJECT}.firebasestorage.app/o/listings%2Fbig%2Fphoto-${n}-with-a-long-descriptive-name.jpg?alt=media&token=0a1b2c3d-aaaa-bbbb-cccc-0123456789ab`;
const words = (n, w) => Array.from({ length: n }, (_, i) => w[i % w.length]).join(" ").slice(0, n);

// The largest listing syncOwnerPropertyToMarketplace can write: every text field at its cap, 30
// amenities in each language, 20 images, agency attribution and every optional field present.
const bigListing = {
  id: "big",
  owner_id: "ownerA",
  agency_id: "agency-1",
  countryCode: "AE",
  currencyCode: "AED",
  titles: { ar: words(200, ["شقة", "فاخرة", "مطلة", "على", "البحر"]), en: words(200, ["Luxury", "sea", "view", "flat"]), hi: words(200, ["शानदार", "समुद्र", "दृश्य", "फ्लैट"]) },
  descriptions: { ar: words(4000, ["شقة", "واسعة", "بإطلالة", "رائعة"]), en: words(4000, ["Spacious", "bright", "apartment", "with", "balcony"]), hi: words(4000, ["विशाल", "उज्ज्वल", "अपार्टमेंट"]) },
  locations: { ar: words(300, ["دبي", "مارينا", "برج"]), en: words(300, ["Dubai", "Marina", "Tower"]), hi: words(300, ["दुबई", "मरीना", "टावर"]) },
  cityCode: "dubai",
  propertyTypeCode: "apartment",
  buildingName: words(200, ["Marina", "Tower", "Two"]),
  pricePerMonth: 9000,
  bedrooms: 3,
  bathrooms: 2,
  areaSqM: 185.5,
  image: bigImage(0),
  imageUrls: Array.from({ length: 20 }, (_, i) => bigImage(i)),
  amenitiesMap: { ar: Array(30).fill("مسبح خاص"), en: Array(30).fill("Private pool"), hi: Array(30).fill("निजी पूल") },
  isFurnished: true,
  agencyNames: { ar: "تسهيل", en: "Tashil", hi: "तशील" },
  agencyPhone: "+971 4 123 4567",
  rating: 4,
  isFeatured: false,
  is_published: true,
  status: "vacant",
  updated_at: new Date("2026-01-01T00:00:00Z"),
  verified: false,
  moderation_hidden: false,
};

function superAdmin(uid = "root") {
  const ctx = as(uid, CLAIMS.superAdmin);
  ctx._uid = uid;
  return ctx;
}

async function seedBig() {
  await seed("Users/ownerA/properties/big", { owner_id: "ownerA", isPublished: true });
  await seed("Properties/big", bigListing);
}

const STAFF_EDITS = [
  ["rating", { rating: 4.5 }],
  ["title (dotted path)", { "titles.en": "x" }],
  ["price", { pricePerMonth: 9100 }],
  ["verify", { verified: true }],
  ["featuring", { isFeatured: true }],
  ["status", { status: "rented" }],
  ["description (dotted path)", { "descriptions.en": "A short new description" }],
  ["images", { imageUrls: Array.from({ length: 20 }, (_, i) => bigImage(i + 100)) }],
];

for (const [name, change] of STAFF_EDITS) {
  test(`TAQ-101: a SuperAdmin can edit the ${name} of a maximum-size listing`, async () => {
    await seedBig();
    const me = as("root", CLAIMS.superAdmin);
    await assertSucceeds(updateDoc(doc(me, "Properties/big"), { ...change, updated_at: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(me, "Properties/big"), change));
  });
}

test("TAQ-101: the /admin verify toggle works for SuperAdmin and Admin on a maximum-size listing", async () => {
  await seedBig();
  for (const me of [as("root", CLAIMS.superAdmin), as("admin1", CLAIMS.admin)]) {
    await assertSucceeds(updateDoc(doc(me, "Properties/big"), { verified: true, updated_at: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(me, "Properties/big"), { verified: false, updated_at: serverTimestamp() }));
  }
});

test("TAQ-101: a hide and a restore of a maximum-size listing work for SuperAdmin and Admin", async () => {
  for (const me of [superAdmin(), admin()]) {
    await testEnv.clearFirestore();
    await seedBig();
    await assertSucceeds(moderate(me, "big", { hidden: true, preHidePublished: true, isPublished: false }));
    await assertSucceeds(moderate(me, "big", { hidden: false, preHidePublished: true }));
  }
});

test("TAQ-101: an Admin still cannot edit content on a maximum-size listing", async () => {
  await seedBig();
  const me = as("admin1", CLAIMS.admin);
  for (const [, change] of STAFF_EDITS.filter(([name]) => name !== "verify")) {
    await assertFails(updateDoc(doc(me, "Properties/big"), { ...change, updated_at: serverTimestamp() }));
  }
});

test("TAQ-101: the cheap SuperAdmin edit path still validates the keys it changes", async () => {
  await seedBig();
  const me = as("root", CLAIMS.superAdmin);
  const ref = doc(me, "Properties/big");
  const bad = [
    { rating: 6 }, { rating: -1 }, { rating: "5" },
    { pricePerMonth: 0 }, { pricePerMonth: -5 }, { pricePerMonth: "9000" },
    { areaSqM: 0 }, { bedrooms: 101 }, { bathrooms: -1 },
    { isFeatured: "yes" }, { verified: 1 }, { isFurnished: "no" },
    { status: "draft" }, { countryCode: "US" }, { currencyCode: "EGP" },
    { "titles.en": "x".repeat(201) },
    { "descriptions.en": "x".repeat(4001) },
    { "locations.en": "x".repeat(301) },
    { "titles.fr": "bonjour" },
    { "titles.en": "call 0501234567" },
    { "descriptions.en": "write me at me@example.com" },
    { "locations.en": "wa.me/971501234567" },
    { buildingName: "@owner_handle" },
    { amenitiesMap: { ar: Array(31).fill("x"), en: [], hi: [] } },
    { amenitiesMap: { ar: ["0 5 0 1 2 3 4 5 6 7"], en: [], hi: [] } },
    { image: "https://evil.example/a.jpg" },
    { image: "a.jpg b.jpg" },
    { imageUrls: Array.from({ length: 21 }, (_, i) => bigImage(i)) },
    { imageUrls: ["https://evil.example/a.jpg"] },
    { imageUrls: "a.jpg" },
    { agencyPhone: "1".repeat(31) },
    { phone: "+971501234567" },
    { whatsapp: "x" },
    { tenant_name: "x" },
    { owner_id: "mallory" },
    { id: "other" },
    { updated_at: "yesterday" },
  ];
  for (const change of bad) {
    await assertFails(updateDoc(ref, change), JSON.stringify(change).slice(0, 80));
  }
});

test("TAQ-101: visibility still cannot change outside the moderation batch, with any mix of keys", async () => {
  await seedBig();
  for (const me of [as("root", CLAIMS.superAdmin), as("admin1", CLAIMS.admin)]) {
    const ref = doc(me, "Properties/big");
    await assertFails(updateDoc(ref, { is_published: false }));
    await assertFails(updateDoc(ref, { moderation_hidden: true }));
    await assertFails(updateDoc(ref, { moderation_hidden: true, is_published: true }));
    await assertFails(updateDoc(ref, { is_published: false, rating: 3 }));
    await assertFails(updateDoc(ref, { moderation_hidden: true, pricePerMonth: 1 }));
  }
});

test("TAQ-101: SuperAdmin cannot create a public doc while moderation holds it hidden, so delete and recreate fails", async () => {
  await seed("Users/ownerA/properties/held", { owner_id: "ownerA", isPublished: true });
  await seed("Properties/held", { ...live, id: "held", is_published: false, moderation_hidden: true });
  await seed("PropertyModeration/held", { hidden: true, pre_hide_published: true, updated_by: "admin1" });
  const me = as("root", CLAIMS.superAdmin);
  await assertSucceeds(deleteDoc(doc(me, "Properties/held")));
  await assertFails(setDoc(doc(me, "Properties/held"), { ...live, id: "held" }));
  await assertFails(setDoc(doc(me, "Properties/held"), { ...live, id: "held", is_published: false, moderation_hidden: false }));
  // once the hold is lifted the id is an ordinary one again
  await assertSucceeds(updateDoc(doc(me, "PropertyModeration/held"), { hidden: false, pre_hide_published: true, updated_by: "root", updated_at: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(me, "Properties/held"), { ...live, id: "held" }));
});

test("TAQ-101: a SuperAdmin create needs the owner's private doc, and owner_id must be that owner", async () => {
  await seed("Users/ownerA/properties/p1", { owner_id: "ownerA", isPublished: true });
  const me = as("root", CLAIMS.superAdmin);
  await assertFails(setDoc(doc(me, "Properties/nopriv"), { ...live, id: "nopriv" }));
  await assertFails(setDoc(doc(me, "Properties/p1"), { ...live, id: "p1", owner_id: "ownerB" }));
  await assertFails(setDoc(doc(me, "Properties/p1"), { ...live, id: "p1", owner_id: "" }));
  await assertSucceeds(setDoc(doc(me, "Properties/p1"), { ...live, id: "p1", owner_id: "ownerA" }));
});

test("TAQ-101: a SuperAdmin can create a maximum-size listing", async () => {
  await seed("Users/ownerA/properties/big", { owner_id: "ownerA", isPublished: true });
  const me = as("root", CLAIMS.superAdmin);
  await assertSucceeds(setDoc(doc(me, "Properties/big"), { ...bigListing, updated_at: serverTimestamp() }));
});

test("TAQ-101: Admin and owners still cannot create a listing", async () => {
  await seed("Users/ownerA/properties/p2", { owner_id: "ownerA", isPublished: true });
  for (const me of [as("admin1", CLAIMS.admin), as("ownerA", CLAIMS.owner)]) {
    await assertFails(setDoc(doc(me, "Properties/p2"), { ...live, id: "p2" }));
  }
});

// --- TAQ-103: agencyNames, agencyPhone, agency_id, titles and image refs on SuperAdmin edits ---

test("TAQ-103: a SuperAdmin cannot put contact info, oversize or wrongly typed values into agencyNames", async () => {
  await seedBig();
  const ref = doc(as("root", CLAIMS.superAdmin), "Properties/big");
  for (const agencyNames of [
    { en: "Call 01012345678" },
    { en: "0 1 0 1 2 3 4 5 6 7 8" },
    { ar: "wa.me/201012345678" },
    { hi: "mail me@example.com" },
    { en: "x".repeat(50000) },
    { en: "x".repeat(201) },
    { en: 5 },
    { en: ["Tashil"] },
    { en: null },
    { fr: "Tashil" },
    { en: "Tashil", phone: "x" },
    5,
    "Tashil",
    ["Tashil"],
    true,
  ]) {
    await assertFails(updateDoc(ref, { agencyNames, updated_at: serverTimestamp() }), JSON.stringify(agencyNames).slice(0, 60));
  }
  await assertFails(updateDoc(ref, { "agencyNames.en": "Call 01012345678" }));
  await assertFails(updateDoc(ref, { "agencyNames.en": "x".repeat(50000) }));
  await assertSucceeds(updateDoc(ref, { agencyNames: { ar: "تسهيل للعقارات", en: "Tashil Real Estate", hi: "तशील रियल एस्टेट" }, updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, { "agencyNames.en": "Tashil Properties" }));
  await assertSucceeds(updateDoc(ref, { agencyNames: deleteField() }));
});

test("TAQ-103: a SuperAdmin create validates agencyNames the same way", async () => {
  await seed("Users/ownerA/properties/an1", { owner_id: "ownerA", isPublished: true });
  const ref = doc(as("root", CLAIMS.superAdmin), "Properties/an1");
  const base = { ...live, id: "an1" };
  for (const agencyNames of [{ en: "Call 01012345678" }, { en: "x".repeat(50000) }, { en: 5 }, { fr: "x" }, 5]) {
    await assertFails(setDoc(ref, { ...base, agencyNames }), JSON.stringify(agencyNames).slice(0, 60));
  }
  await assertSucceeds(setDoc(ref, { ...base, agencyNames: { ar: "تسهيل", en: "Tashil", hi: "तशील" } }));
});

test("TAQ-103: agencyPhone and agency_id are shape-checked on SuperAdmin edits", async () => {
  await seedBig();
  const ref = doc(as("root", CLAIMS.superAdmin), "Properties/big");
  for (const change of [
    { agencyPhone: "call me on whatsapp" },
    { agencyPhone: "wa.me/201012345678" },
    { agencyPhone: "1".repeat(31) },
    { agencyPhone: 971501234567 },
    { agencyPhone: ["+971 4 123 4567"] },
    { agency_id: 5 },
    { agency_id: "a/b" },
    { agency_id: "agency 1" },
    { agency_id: "a".repeat(129) },
    { agency_id: "Call 01012345678" },
  ]) {
    await assertFails(updateDoc(ref, change), JSON.stringify(change).slice(0, 60));
  }
  await assertSucceeds(updateDoc(ref, { agencyPhone: "+971 (4) 123-4567", agency_id: "agency-2" }));
  await assertSucceeds(updateDoc(ref, { agencyPhone: "" , agency_id: "" }));
});

test("TAQ-103: titles cannot be deleted, and an image ref with a space is rejected on edit and create", async () => {
  await seedBig();
  const ref = doc(as("root", CLAIMS.superAdmin), "Properties/big");
  await assertFails(updateDoc(ref, { titles: deleteField() }));
  await assertSucceeds(updateDoc(ref, { titles: { en: "Still here" } }));
  await assertFails(updateDoc(ref, { imageUrls: [`${bigImage(1)} ${bigImage(2)}`] }));
  await assertFails(updateDoc(ref, { imageUrls: ["a.jpg b.jpg"] }));
  await assertFails(updateDoc(ref, { image: "a.jpg b.jpg" }));
  await assertSucceeds(updateDoc(ref, { imageUrls: [bigImage(1), bigImage(2)], image: bigImage(1) }));
  await seed("Users/ownerA/properties/img1", { owner_id: "ownerA", isPublished: true });
  const create = doc(as("root", CLAIMS.superAdmin), "Properties/img1");
  await assertFails(setDoc(create, { ...live, id: "img1", imageUrls: ["a.jpg b.jpg"] }));
  await assertFails(setDoc(create, { ...live, id: "img1", imageUrls: [`${bigImage(1)} ${bigImage(2)}`] }));
  await assertSucceeds(setDoc(create, { ...live, id: "img1", imageUrls: [bigImage(1), bigImage(2)] }));
});

// Minimal docs: each denial below is decided by the rule, not by the expression budget. The same
// doc is accepted for a SuperAdmin whose owner has a private doc, so the only difference is the actor.
test("TAQ-103: minimal public docs are denied to every non-staff actor and accepted for a SuperAdmin", async () => {
  await seed("Users/ownerA/properties/min1", { owner_id: "ownerA", isPublished: false });
  await seed("Users/stranger", { role: "Owner" });
  const mini = { id: "min1", owner_id: "ownerA", is_published: false, status: "unavailable" };
  const actors = [
    as("ownerA", CLAIMS.owner),
    as("ownerA"),
    as("stranger"),
    as("tenantX", { role: "Tenant" }),
    as("agent", CLAIMS.agency),
    as("inv", CLAIMS.investor),
    as("admin1", CLAIMS.admin),
    testEnv.unauthenticatedContext().firestore(),
  ];
  for (const me of actors) {
    await assertFails(setDoc(doc(me, "Properties/min1"), mini));
    await assertFails(setDoc(doc(me, "Properties/min1"), { is_published: false }, { merge: true }));
  }
  await assertSucceeds(setDoc(doc(as("root", CLAIMS.superAdmin), "Properties/min1"), mini));
  for (const me of actors) {
    await assertFails(updateDoc(doc(me, "Properties/min1"), { status: "vacant" }));
    await assertFails(setDoc(doc(me, "Properties/min1"), { ...mini, status: "vacant" }, { merge: true }));
  }
  await assertSucceeds(updateDoc(doc(as("root", CLAIMS.superAdmin), "Properties/min1"), { status: "vacant" }));
});

// --- TAQ-104: a live public doc needs a private listing its owner has published ---

test("TAQ-104: a SuperAdmin cannot create a live public doc for an unpublished private listing", async () => {
  const me = as("root", CLAIMS.superAdmin);
  await seed("Users/ownerA/properties/np1", { owner_id: "ownerA", isPublished: false });
  await seed("Users/ownerA/properties/np2", { owner_id: "ownerA" });
  await seed("Users/ownerA/properties/np3", { owner_id: "ownerA", isPublished: true, rentalStatus: "rented" });
  await seed("Users/ownerA/properties/np4", { owner_id: "ownerA", isPublished: "true" });
  for (const id of ["np1", "np2", "np3", "np4"]) {
    await assertFails(setDoc(doc(me, `Properties/${id}`), { ...live, id }), id);
    await assertFails(setDoc(doc(me, `Properties/${id}`), { ...live, id, is_published: "true" }), id);
  }
  // created unpublished, it is fine, and it stays unpublished: no write can set is_published true
  for (const id of ["np1", "np2", "np3", "np4"]) {
    await assertSucceeds(setDoc(doc(me, `Properties/${id}`), { ...live, id, is_published: false }), id);
    await assertFails(updateDoc(doc(me, `Properties/${id}`), { is_published: true }), id);
  }
});

test("TAQ-104: a live create still works for a published, available private listing, and not for another owner's", async () => {
  const me = as("root", CLAIMS.superAdmin);
  await seed("Users/ownerA/properties/ok1", { owner_id: "ownerA", isPublished: true, rentalStatus: "available" });
  await seed("Users/ownerB/properties/ok2", { owner_id: "ownerB", isPublished: true });
  await assertSucceeds(setDoc(doc(me, "Properties/ok1"), { ...live, id: "ok1" }));
  // ok2's private doc belongs to ownerB; claiming ownerA for it finds no private doc
  await assertFails(setDoc(doc(me, "Properties/ok2"), { ...live, id: "ok2", owner_id: "ownerA" }));
  await assertSucceeds(setDoc(doc(me, "Properties/ok2"), { ...live, id: "ok2", owner_id: "ownerB" }));
});

test("TAQ-104: Admin and the moderation batch are unchanged", async () => {
  await seedBig();
  await assertSucceeds(moderate(superAdmin(), "big", { hidden: true, preHidePublished: true, isPublished: false }));
  await assertFails(setDoc(doc(superAdmin(), "Properties/big"), { ...bigListing, updated_at: serverTimestamp() }));
});
