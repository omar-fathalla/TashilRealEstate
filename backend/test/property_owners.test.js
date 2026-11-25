// TAQ-110 N-1: the property owner registry. A property id belongs to the first landlord who
// creates it (PropertyOwners/{id}). Another owner's doc under the same id is flagged id_conflict and
// never syncs, publishes, leases or takes payments; leases fail closed on unregistered ids; a lock
// held by a lease of an owner the registry does not name can be taken over.
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const ENV = {
  PAYMENTS_ENABLED: "true",
  PAYMOB_SECRET_KEY: "fake-secret-key",
  PAYMOB_PUBLIC_KEY: "fake-public-key",
  PAYMOB_HMAC_SECRET: "fake-hmac-secret",
  PAYMOB_INTEGRATION_ID: "12345",
  PAYMOB_NOTIFICATION_URL: "https://example.test/paymobWebhook",
};
const savedEnv = Object.fromEntries(Object.keys(ENV).map((k) => [k, process.env[k]]));

const fns = require("../index");
const leases = require("../leases");
const payments = require("../payments");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });
const realFetch = payments.deps.fetch;

test.after(() => {
  payments.deps.fetch = realFetch;
  leases.deps.now = () => Date.now();
  for (const [k, v] of Object.entries(savedEnv)) {
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
});

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

async function user(uid, role) {
  await admin.auth().createUser({ uid });
  await admin.auth().setCustomUserClaims(uid, { role });
  await db.doc(`Users/${uid}`).set({ role, full_name: `Name ${uid}` });
}

test.beforeEach(async () => {
  Object.assign(process.env, ENV);
  leases.deps.now = () => Date.now();
  let order = 5000;
  payments.deps.fetch = async () => {
    order += 1;
    return { ok: true, status: 201, json: async () => ({ id: `int_${order}`, intention_order_id: order, client_secret: `cs_${order}` }) };
  };
  await clearAll();
  // ownerA is the real owner, ownerB the squatter.
  await user("ownerA", "Owner");
  await user("ownerB", "Owner");
  for (const t of ["tenantA", "tenantB"]) await user(t, "Tenant");
});

const listing = (extra = {}) => ({
  isPublished: true,
  rentalStatus: "available",
  countryCode: "AE",
  titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" },
  pricePerMonth: 9000,
  ...extra,
});

const siloRef = (uid, id) => db.doc(`Users/${uid}/properties/${id}`);

/** Writes (or deletes) a private property doc, then runs the sync trigger as Firestore would. */
async function ownerWrites(uid, id, data) {
  const ref = siloRef(uid, id);
  const before = await ref.get();
  if (data) await ref.set(data);
  else await ref.delete();
  const after = await ref.get();
  return runSync(uid, id, before, after);
}

const runSync = (uid, id, before, after) =>
  fns.syncOwnerPropertyToMarketplace.run({ params: { ownerId: uid, propertyId: id }, data: { before, after } });

const doc = async (path) => {
  const snap = await db.doc(path).get();
  return snap.exists ? snap.data() : null;
};
const registry = async (id) => (await doc(`PropertyOwners/${id}`) || {}).owner_id || "";
const flagged = async (uid, id) => (await doc(`Users/${uid}/properties/${id}`) || {}).id_conflict === true;

const offer = (owner, propertyId, tenantId = "tenantA", extra = {}) => fns.createLease.run({
  data: { propertyId, tenantId, startDate: "2026-01-01", endDate: "2099-12-31", monthlyRent: 5000, sendOffer: true, ...extra },
  auth: caller(owner, { role: "Owner" }),
});
const respond = (leaseId, tenant) => fns.respondToLeaseOffer.run({ data: { leaseId, decision: "approve" }, auth: caller(tenant, { role: "Tenant" }) });
const payIntent = (leaseId, tenant) => fns.createRentPaymentIntent.run({ data: { leaseId }, auth: caller(tenant, { role: "Tenant" }) });
const manualPay = (leaseId, owner) => fns.recordManualPayment.run({
  data: { leaseId, method: "cash", reference: "r1", paidOn: new Date().toISOString().slice(0, 10) },
  auth: caller(owner, { role: "Owner" }),
});

async function reason(promise, code, expected) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    if (expected) assert.equal(err.details && err.details.reason, expected);
    return true;
  });
}

async function leaseAndActivate(owner, propertyId, tenant = "tenantA") {
  const { leaseId } = await offer(owner, propertyId, tenant);
  assert.equal((await respond(leaseId, tenant)).status, "active");
  return leaseId;
}

/** A lease written straight to Firestore, the way a pre-registry squatter could have left one. */
async function forgedActiveLease(id, owner, propertyId, tenant = "tenantB") {
  await db.doc(`Leases/${id}`).set({
    owner_id: owner, tenant_id: tenant, agency_id: "", property_id: propertyId, status: "active",
    start_date: "2026-01-01", end_date: "2099-12-31", monthly_rent: 5000, financialTerms: { monthlyRent: 5000 }, country_code: "AE",
  });
}

// --- claiming ---

test("TAQ-110 N-1: the first landlord to create an id registers it; tenants never do", async () => {
  await ownerWrites("ownerA", "fresh-1", listing());
  assert.equal(await registry("fresh-1"), "ownerA");
  assert.equal((await doc("Properties/fresh-1")).owner_id, "ownerA");
  const reg = await doc("PropertyOwners/fresh-1");
  assert.equal(reg.property_id, "fresh-1");
  assert.equal(reg.claimed_by, "create");
  await ownerWrites("tenantA", "tenant-id", listing({ isPublished: false }));
  assert.equal(await registry("tenant-id"), "", "a tenant's doc claims nothing");
});

// --- squatting ---

test("TAQ-110 N-1: squatting a public id flags the squatter's doc; the listing and the owner's leases are untouched", async () => {
  await ownerWrites("ownerA", "pub-1", listing());
  await ownerWrites("ownerB", "pub-1", listing({ titles: { en: "Scam" }, pricePerMonth: 1 }));
  assert.equal(await flagged("ownerB", "pub-1"), true);
  assert.equal(await registry("pub-1"), "ownerA");
  const pub = await doc("Properties/pub-1");
  assert.equal(pub.owner_id, "ownerA");
  assert.equal(pub.titles.en, "Apartment");
  const alert = await doc("AdminAlerts/property_id_conflict_pub-1_ownerB");
  assert.equal(alert.type, "PROPERTY_ID_CONFLICT");
  assert.equal(alert.registered_owner_id, "ownerA");
  assert.equal(alert.claimant_id, "ownerB");

  await reason(offer("ownerB", "pub-1"), "failed-precondition", "property_id_conflict");
  await ownerWrites("ownerB", "pub-1", listing({ titles: { en: "Scam 2" }, isPublished: false }));
  await ownerWrites("ownerB", "pub-1", null);
  const after = await doc("Properties/pub-1");
  assert.equal(after.titles.en, "Apartment");
  assert.equal(after.is_published, true, "neither updates nor a delete of the squatter's doc touch the listing");
  await leaseAndActivate("ownerA", "pub-1");
  assert.equal((await doc("PropertyLeaseLocks/pub-1")).owner_id, "ownerA");
});

test("TAQ-110 N-1: squatting a private-only id flags the squatter's doc and the owner still leases it", async () => {
  await ownerWrites("ownerA", "priv-1", listing({ isPublished: false }));
  assert.equal(await doc("Properties/priv-1"), null);
  assert.equal(await registry("priv-1"), "ownerA");
  await ownerWrites("ownerB", "priv-1", listing());
  assert.equal(await flagged("ownerB", "priv-1"), true);
  assert.equal(await doc("Properties/priv-1"), null, "the squatter cannot publish the id");
  await reason(offer("ownerB", "priv-1"), "failed-precondition", "property_id_conflict");
  await leaseAndActivate("ownerA", "priv-1");
});

test("TAQ-110 N-1: a guessable id taken before the owner saves leaves the owner flagged; a new id works", async () => {
  const guessable = "prop-1767225600000";
  await ownerWrites("ownerB", guessable, listing({ isPublished: false }));
  assert.equal(await registry(guessable), "ownerB");
  await ownerWrites("ownerA", guessable, listing());
  assert.equal(await flagged("ownerA", guessable), true);
  assert.equal(await doc(`Properties/${guessable}`), null);
  await reason(offer("ownerA", guessable), "failed-precondition", "property_id_conflict");

  const retry = db.collection("Users").doc("ownerA").collection("properties").doc().id;
  assert.ok(retry.length >= 20);
  await ownerWrites("ownerA", retry, listing());
  assert.equal(await registry(retry), "ownerA");
  assert.equal((await doc(`Properties/${retry}`)).owner_id, "ownerA");
  await leaseAndActivate("ownerA", retry);
  await reason(offer("ownerB", retry), "failed-precondition", "property_not_found");
});

test("TAQ-110 N-1: two owners creating one id before either trigger runs (rules saw no registry) end with one owner", async () => {
  for (let i = 0; i < 4; i += 1) {
    const id = `race-${i}`;
    const a = siloRef("ownerA", id);
    const b = siloRef("ownerB", id);
    const [beforeA, beforeB] = await Promise.all([a.get(), b.get()]);
    await Promise.all([a.set(listing({ titles: { en: "A" } })), b.set(listing({ titles: { en: "B" } }))]);
    const [afterA, afterB] = await Promise.all([a.get(), b.get()]);
    const runs = [() => runSync("ownerA", id, beforeA, afterA), () => runSync("ownerB", id, beforeB, afterB)];
    if (i % 2) runs.reverse();
    await Promise.all(runs.map((r) => r()));

    const winner = await registry(id);
    assert.ok(["ownerA", "ownerB"].includes(winner), id);
    const loser = winner === "ownerA" ? "ownerB" : "ownerA";
    assert.equal(await flagged(winner, id), false, id);
    assert.equal(await flagged(loser, id), true, id);
    const pub = await doc(`Properties/${id}`);
    assert.equal(pub.owner_id, winner, id);
    assert.equal(pub.titles.en, winner === "ownerA" ? "A" : "B", id);
    await reason(offer(loser, id), "failed-precondition", "property_id_conflict");
  }
});

// --- id_conflict ---

test("TAQ-110 N-1: an id_conflict doc never syncs, publishes, leases or pays, even for the registered owner", async () => {
  await ownerWrites("ownerA", "flag-1", listing());
  const lease = await leaseAndActivate("ownerA", "flag-1");
  await siloRef("ownerA", "flag-1").update({ id_conflict: true });
  await ownerWrites("ownerA", "flag-1", { ...listing({ titles: { en: "Changed" } }), id_conflict: true });
  assert.equal((await doc("Properties/flag-1")).titles.en, "Apartment", "a flagged doc does not sync");
  await reason(offer("ownerA", "flag-1", "tenantB"), "failed-precondition", "property_id_conflict");
  await reason(payIntent(lease, "tenantA"), "failed-precondition", "property_id_conflict");
  await reason(manualPay(lease, "ownerA"), "failed-precondition", "property_id_conflict");

  await ownerWrites("ownerA", "flag-new", { ...listing(), id_conflict: true });
  assert.equal(await registry("flag-new"), "", "a doc created flagged claims nothing");
  assert.equal(await doc("Properties/flag-new"), null);
});

test("TAQ-110 N-1: a squatter's lease on a flagged doc takes no payments", async () => {
  await ownerWrites("ownerA", "pub-2", listing());
  await ownerWrites("ownerB", "pub-2", listing());
  await forgedActiveLease("evil", "ownerB", "pub-2");
  await reason(payIntent("evil", "tenantB"), "failed-precondition", "property_id_conflict");
  await reason(manualPay("evil", "ownerB"), "failed-precondition", "property_id_conflict");
  assert.equal(await doc("PropertyLeaseLocks/pub-2"), null);
});

// --- fail closed before the backfill ---

test("TAQ-110 N-1: an unregistered id cannot be leased or paid until the backfill registers it; it still syncs", async () => {
  await siloRef("ownerA", "legacy-1").set(listing());
  await forgedActiveLease("legacy-lease", "ownerA", "legacy-1", "tenantA");
  await reason(offer("ownerA", "legacy-1", "tenantB"), "failed-precondition", "property_not_registered");
  await reason(payIntent("legacy-lease", "tenantA"), "failed-precondition", "property_not_registered");
  await reason(manualPay("legacy-lease", "ownerA"), "failed-precondition", "property_not_registered");

  const before = await siloRef("ownerA", "legacy-1").get();
  await siloRef("ownerA", "legacy-1").set(listing({ titles: { en: "Legacy" } }));
  await runSync("ownerA", "legacy-1", before, await siloRef("ownerA", "legacy-1").get());
  assert.equal((await doc("Properties/legacy-1")).titles.en, "Legacy", "a doc older than the registry keeps syncing");
  assert.equal(await registry("legacy-1"), "", "an update never claims; only a create or the backfill does");

  await db.doc("PropertyOwners/legacy-1").set({ owner_id: "ownerA", property_id: "legacy-1" });
  assert.equal((await payIntent("legacy-lease", "tenantA")).status, "pending");
});

test("TAQ-110 N-1: deleting a property keeps its id; the same owner re-creates it, nobody else can", async () => {
  await ownerWrites("ownerA", "del-1", listing());
  await ownerWrites("ownerA", "del-1", null);
  assert.equal(await registry("del-1"), "ownerA");
  assert.equal(await doc("Properties/del-1"), null);
  await ownerWrites("ownerB", "del-1", listing({ titles: { en: "B" } }));
  assert.equal(await flagged("ownerB", "del-1"), true);
  assert.equal(await doc("Properties/del-1"), null);
  await ownerWrites("ownerA", "del-1", listing({ titles: { en: "Back" } }));
  assert.equal(await flagged("ownerA", "del-1"), false);
  assert.equal((await doc("Properties/del-1")).titles.en, "Back");
});

// --- locks ---

test("TAQ-110 N-1: a lock left by an attacker's lease is taken over by the registered owner's lease", async () => {
  await ownerWrites("ownerA", "victim-1", listing());
  await siloRef("ownerB", "victim-1").set(listing({ id_conflict: true }));
  await forgedActiveLease("evil", "ownerB", "victim-1");
  await db.doc("PropertyLeaseLocks/victim-1").set({ lease_id: "evil", property_id: "victim-1", owner_id: "ownerB", tenant_id: "tenantB", agency_id: "" });

  const id = await leaseAndActivate("ownerA", "victim-1");
  const lock = await doc("PropertyLeaseLocks/victim-1");
  assert.equal(lock.lease_id, id);
  assert.equal(lock.owner_id, "ownerA");
  assert.equal((await doc("Users/ownerA/properties/victim-1")).rentalStatus, "rented");
});

test("TAQ-110 N-1: releasing a squatter's lock never changes the owner's property", async () => {
  await ownerWrites("ownerA", "victim-2", listing({ rentalStatus: "rented", isPublished: false }));
  await siloRef("ownerB", "victim-2").set(listing({ rentalStatus: "rented", id_conflict: true }));
  await forgedActiveLease("evil", "ownerB", "victim-2");
  await db.doc("PropertyLeaseLocks/victim-2").set({ lease_id: "evil", property_id: "victim-2", owner_id: "ownerB", tenant_id: "tenantB", agency_id: "" });

  const before = await db.doc("Leases/evil").get();
  await db.doc("Leases/evil").update({ status: "terminated" });
  const after = await db.doc("Leases/evil").get();
  assert.equal(await fns.releasePropertyLeaseLock.run({ params: { leaseId: "evil" }, data: { before, after } }), true);
  assert.equal(await doc("PropertyLeaseLocks/victim-2"), null);
  assert.equal((await doc("Users/ownerA/properties/victim-2")).rentalStatus, "rented");
  assert.equal((await doc("Users/ownerB/properties/victim-2")).rentalStatus, "rented", "a flagged doc is not touched either");
});

test("TAQ-110 N-1: parallel acceptances on a registered property still have exactly one winner", async () => {
  await ownerWrites("ownerA", "par-1", listing());
  const offers = [];
  for (const t of ["tenantA", "tenantB"]) offers.push([(await offer("ownerA", "par-1", t)).leaseId, t]);
  const results = await Promise.allSettled(offers.map(([id, t]) => respond(id, t)));
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  const lost = results.find((r) => r.status === "rejected");
  assert.equal(lost.reason.details.reason, "property_already_leased");
});

// --- N-4 and rent precision ---

test("TAQ-110 N-4: an offer is accepted only on an available, vacant or unset property", async () => {
  for (const [i, status] of ["maintenance", "rented", "Unavailable", "reserved"].entries()) {
    const id = `n4-bad-${i}`;
    await ownerWrites("ownerA", id, listing({ rentalStatus: status, isPublished: false }));
    const { leaseId } = await offer("ownerA", id);
    await reason(respond(leaseId, "tenantA"), "failed-precondition", "property_not_available");
    assert.equal(await doc(`PropertyLeaseLocks/${id}`), null);
    assert.equal((await doc(`Leases/${leaseId}`)).status, "pending_tenant_approval");
  }
  for (const [i, status] of ["available", "vacant", " Available ", "", undefined].entries()) {
    const id = `n4-ok-${i}`;
    const data = listing({ isPublished: false });
    if (status === undefined) delete data.rentalStatus;
    else data.rentalStatus = status;
    await ownerWrites("ownerA", id, data);
    await leaseAndActivate("ownerA", id);
  }
});

test("TAQ-110: createLease refuses rent with more than 2 decimals", async () => {
  await ownerWrites("ownerA", "rent-1", listing());
  for (const monthlyRent of [4999.999, 0.001, 1234.5671]) {
    await reason(offer("ownerA", "rent-1", "tenantA", { monthlyRent }), "invalid-argument", "rent_precision");
  }
  for (const monthlyRent of [4999.99, 4999.9, 0.1 + 0.2, 1e9]) {
    const { leaseId } = await offer("ownerA", "rent-1", "tenantA", { monthlyRent });
    assert.equal((await doc(`Leases/${leaseId}`)).monthly_rent, Math.round(monthlyRent * 100) / 100);
  }
});
