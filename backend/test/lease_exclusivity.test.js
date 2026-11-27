// TAQ-110: one live lease per property (M-1) and leases only on a property the owner has and the
// agency manages (M-2). Leases are created by createLease, activated only by respondToLeaseOffer
// under PropertyLeaseLocks/{propertyId}, and the lock is released when the lease leaves active.
const test = require("node:test");
const assert = require("node:assert/strict");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

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
test.after(() => {
  for (const [k, v] of Object.entries(savedEnv)) {
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
});

const fns = require("../index");
const leases = require("../leases");
const payments = require("../payments");
const { audit, resolveTarget } = require("../scripts/audit_leases");

const db = getFirestore();
const projectId = process.env.GCLOUD_PROJECT;
const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

async function user(uid, claims) {
  await getAuth().createUser({ uid });
  if (claims) await getAuth().setCustomUserClaims(uid, claims);
}

const realFetch = payments.deps.fetch;
let nextOrder;
test.after(() => {
  payments.deps.fetch = realFetch;
  leases.deps.now = () => Date.now();
});

test.beforeEach(async () => {
  Object.assign(process.env, ENV);
  leases.deps.now = () => Date.now();
  nextOrder = 7000;
  payments.deps.fetch = async () => {
    nextOrder += 1;
    return { ok: true, status: 201, json: async () => ({ id: `int_${nextOrder}`, intention_order_id: nextOrder, client_secret: `cs_${nextOrder}` }) };
  };
  await clearAll();
  // ownerA lets privately; ag1owner is agency ag1's account; ownerB is someone else.
  await user("ownerA", { role: "Owner" });
  await user("ownerB", { role: "Owner" });
  await user("ag1owner", { role: "AgencyAdmin", agency_id: "ag1" });
  for (const t of ["tenantA", "tenantB", "tenantC"]) {
    await user(t, { role: "Tenant" });
    await db.doc(`Users/${t}`).set({ role: "Tenant", full_name: `Name ${t}` });
  }
  await db.doc("Users/ownerA/properties/propA").set({ title: "Flat A", countryCode: "AE" });
  await db.doc("Users/ownerB/properties/propB").set({ title: "Villa B", countryCode: "EG" });
  await db.doc("Users/ag1owner/properties/propG").set({ titles: { en: "Agency Tower" }, countryCode: "AE", agency_id: "ag1" });
  await db.doc("Users/ag1owner/properties/propNoAgency").set({ title: "Unmanaged", countryCode: "AE" });
  for (const [id, owner] of [["propA", "ownerA"], ["propB", "ownerB"], ["propG", "ag1owner"], ["propNoAgency", "ag1owner"]]) {
    await db.doc(`PropertyOwners/${id}`).set({ owner_id: owner });
  }
});

const ownerA = () => caller("ownerA", { role: "Owner" });
const ag1 = () => caller("ag1admin", { role: "AgencyAdmin", agency_id: "ag1" });
const ag2 = () => caller("ag2admin", { role: "AgencyAdmin", agency_id: "ag2" });
const sa = () => caller("root", { role: "SuperAdmin" });

const input = (extra = {}) => ({ propertyId: "propA", tenantId: "tenantA", startDate: "2026-01-01", endDate: "2099-12-31", monthlyRent: 5000, sendOffer: true, ...extra });
const create = (data = input(), auth = ownerA()) => fns.createLease.run({ data, auth });
const respond = (leaseId, decision, tenant) => fns.respondToLeaseOffer.run({ data: { leaseId, decision }, auth: caller(tenant, { role: "Tenant" }) });
const lease = async (id) => (await db.doc(`Leases/${id}`).get()).data();
const lock = async (propertyId) => (await db.doc(`PropertyLeaseLocks/${propertyId}`).get()).data();

async function reason(promise, code, expected) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    if (expected) assert.equal(err.details && err.details.reason, expected);
    return true;
  });
}

/** Runs the release trigger the way Firestore would for a write to Leases/{id}. */
async function writeLease(id, write) {
  const before = await db.doc(`Leases/${id}`).get();
  await write(db.doc(`Leases/${id}`));
  const after = await db.doc(`Leases/${id}`).get();
  return fns.releasePropertyLeaseLock.run({ params: { leaseId: id }, data: { before, after } });
}

// --- createLease ---

test("TAQ-110: an owner creates an offer on their own property; parties, terms and country come from the server", async () => {
  const r = await create(input({ ownerId: "ownerB", status: "active", agency_id: "ag1" }));
  assert.equal(r.status, "pending_tenant_approval");
  const l = await lease(r.leaseId);
  assert.equal(l.owner_id, "ownerA");
  assert.equal(l.tenant_id, "tenantA");
  assert.equal(l.agency_id, "");
  assert.equal(l.property_id, "propA");
  assert.equal(l.status, "pending_tenant_approval");
  assert.equal(l.country_code, "AE");
  assert.equal(l.monthly_rent, 5000);
  assert.deepEqual(l.financialTerms, { monthlyRent: 5000 });
  assert.equal(l.property_title, "Flat A");
  assert.equal(l.tenant_name, "Name tenantA");
  assert.equal((await create(input({ sendOffer: false }))).status, "draft");
  assert.equal(await lock("propA"), undefined, "creating does not take the lock; acceptance does");
});

test("TAQ-110 M-2: no lease for a foreign owner's property, a nonexistent property or a property the agency does not manage", async () => {
  await reason(create(input({ propertyId: "propB" })), "failed-precondition", "property_not_found");
  await reason(create(input({ propertyId: "ghost" })), "failed-precondition", "property_not_found");
  await reason(create(input({ propertyId: "propA", ownerId: "ag1owner" }), ag1()), "failed-precondition", "property_not_found");
  await reason(create(input({ propertyId: "propB", ownerId: "ownerB" }), ag1()), "permission-denied", "property_not_managed");
  await reason(create(input({ propertyId: "propG", ownerId: "ag1owner" }), ag2()), "permission-denied", "property_not_managed");
  await reason(create(input({ propertyId: "propNoAgency", ownerId: "ag1owner" }), ag1()), "failed-precondition", "property_not_managed");
  await reason(create(input({ propertyId: "ghost", ownerId: "ag1owner" }), ag1()), "failed-precondition", "property_not_found");
  await reason(create(input({ propertyId: "propA", ownerId: "ownerB" }), sa()), "failed-precondition", "property_not_found");
  assert.equal((await db.collection("Leases").where("property_id", "in", ["propA", "ghost", "propNoAgency"]).get()).size, 0);
  const ok = await create(input({ propertyId: "propG", ownerId: "ag1owner" }), ag1());
  assert.equal((await lease(ok.leaseId)).agency_id, "ag1");
});

test("TAQ-110: an owner cannot lease a property an agency manages; the agency does", async () => {
  await db.doc("Users/ownerA/properties/propA").set({ agency_id: "ag1" }, { merge: true });
  await reason(create(), "failed-precondition", "property_agency_managed");
});

test("TAQ-110: the tenant must be a tenant account, and nobody else may call createLease", async () => {
  await reason(create(input({ tenantId: "ownerB" })), "failed-precondition", "tenant_not_found");
  await reason(create(input({ tenantId: "nobody" })), "failed-precondition", "tenant_not_found");
  await reason(create(input({ tenantId: "ownerA" })), "invalid-argument");
  for (const auth of [caller("tenantA", { role: "Tenant" }), caller("adm", { role: "Admin" }), caller("inv", { role: "Investor" })]) {
    await reason(create(input(), auth), "permission-denied");
  }
  await reason(fns.createLease.run({ data: input() }), "unauthenticated");
});

test("TAQ-110: rent <= 0, NaN, Infinity or text, and bad dates are refused by createLease", async () => {
  for (const monthlyRent of [0, -1, NaN, Infinity, "5000", 1e10, undefined]) {
    await reason(create(input({ monthlyRent })), "invalid-argument");
  }
  for (const dates of [{ startDate: "2026-02-30" }, { endDate: "2025-12-31" }, { endDate: "2026-01-01" }, { startDate: undefined }]) {
    await reason(create(input(dates)), "invalid-argument");
  }
  assert.equal((await db.collection("Leases").get()).size, 0);
});

// --- respondToLeaseOffer and the lock ---

test("TAQ-110 M-1: parallel acceptances of offers on one property have exactly one winner", async () => {
  const offers = [];
  for (const t of ["tenantA", "tenantB", "tenantC"]) offers.push([(await create(input({ tenantId: t }))).leaseId, t]);
  const results = await Promise.allSettled(offers.map(([id, t]) => respond(id, "approve", t)));
  const won = results.filter((r) => r.status === "fulfilled");
  assert.equal(won.length, 1);
  for (const r of results.filter((x) => x.status === "rejected")) {
    // A loser that hit raw contention is told the same thing, or to retry (TAQ-141).
    assert.ok(["failed-precondition", "aborted"].includes(r.reason.code), `${r.reason.code}: ${r.reason.message}`);
    assert.ok(["property_already_leased", "try_again"].includes(r.reason.details.reason), String(r.reason.details && r.reason.details.reason));
  }
  const statuses = await Promise.all(offers.map(async ([id]) => (await lease(id)).status));
  assert.equal(statuses.filter((s) => s === "active").length, 1);
  const winner = offers[statuses.indexOf("active")][0];
  assert.equal((await lock("propA")).lease_id, winner);
  assert.equal((await db.collection("Leases").where("property_id", "==", "propA").where("status", "==", "active").get()).size, 1);
});

test("TAQ-110: a second offer on a leased property cannot be created or accepted", async () => {
  const first = (await create()).leaseId;
  const second = (await create(input({ tenantId: "tenantB" }))).leaseId;
  await respond(first, "approve", "tenantA");
  await reason(respond(second, "approve", "tenantB"), "failed-precondition", "property_already_leased");
  assert.equal((await lease(second)).status, "pending_tenant_approval");
  await reason(create(input({ tenantId: "tenantC" })), "failed-precondition", "property_already_leased");
  assert.equal((await respond(second, "reject", "tenantB")).status, "rejected", "the tenant can still decline");
});

test("TAQ-110: only the lease's tenant answers, only while pending, and approval re-checks the property", async () => {
  const id = (await create()).leaseId;
  await reason(respond(id, "approve", "tenantB"), "permission-denied");
  await reason(fns.respondToLeaseOffer.run({ data: { leaseId: id, decision: "approve" }, auth: ownerA() }), "permission-denied");
  await reason(fns.respondToLeaseOffer.run({ data: { leaseId: id, decision: "maybe" }, auth: caller("tenantA") }), "invalid-argument");
  const draft = (await create(input({ sendOffer: false, tenantId: "tenantB" }))).leaseId;
  await reason(respond(draft, "approve", "tenantB"), "failed-precondition", "not_pending");
  await db.doc("Users/ownerA/properties/propA").delete();
  await reason(respond(id, "approve", "tenantA"), "failed-precondition", "property_not_found");
  await db.doc("Users/ownerA/properties/propA").set({ title: "Flat A", countryCode: "AE", agency_id: "ag1" });
  await reason(respond(id, "approve", "tenantA"), "failed-precondition", "property_agency_managed");
  await db.doc("Users/ownerA/properties/propA").set({ title: "Flat A", countryCode: "AE" });
  await db.doc(`Leases/${id}`).update({ monthly_rent: 0, financialTerms: { monthlyRent: 0 } });
  await reason(respond(id, "approve", "tenantA"), "failed-precondition", "rent_invalid");
  await db.doc(`Leases/${id}`).update({ monthly_rent: 5000, financialTerms: { monthlyRent: 5000 }, end_date: "2020-01-31", start_date: "2020-01-01" });
  await reason(respond(id, "approve", "tenantA"), "failed-precondition", "offer_expired");
  assert.equal(await lock("propA"), undefined);
});

test("TAQ-110: an agency offer is accepted only while the agency still manages the property", async () => {
  const id = (await create(input({ propertyId: "propG", ownerId: "ag1owner" }), ag1())).leaseId;
  await getAuth().setCustomUserClaims("ag1owner", { role: "AgencyAdmin", agency_id: "ag2" });
  await reason(respond(id, "approve", "tenantA"), "failed-precondition", "property_not_managed");
  await getAuth().setCustomUserClaims("ag1owner", { role: "AgencyAdmin", agency_id: "ag1" });
  await db.doc("Users/ag1owner/properties/propG").update({ agency_id: "ag2" });
  await reason(respond(id, "approve", "tenantA"), "failed-precondition", "property_not_managed");
  await db.doc("Users/ag1owner/properties/propG").update({ agency_id: "ag1" });
  assert.equal((await respond(id, "approve", "tenantA")).status, "active");
  assert.equal((await lock("propG")).agency_id, "ag1");
});

// --- release and re-lease ---

test("TAQ-110: terminating, expiring or deleting the active lease releases the lock, and the property can be let again", async () => {
  for (const end of [
    (ref) => ref.update({ status: "terminated" }),
    (ref) => ref.update({ status: "expired" }),
    (ref) => ref.update({ status: "rejected" }),
    (ref) => ref.delete(),
  ]) {
    const id = (await create()).leaseId;
    await respond(id, "approve", "tenantA");
    assert.equal((await lock("propA")).lease_id, id);
    assert.equal(await writeLease(id, (ref) => ref.update({ notes: "still active" })), null, "an active-to-active write keeps the lock");
    assert.equal((await lock("propA")).lease_id, id);
    assert.equal(await writeLease(id, end), true);
    assert.equal(await lock("propA"), undefined);
  }
  const next = (await create(input({ tenantId: "tenantB" }))).leaseId;
  assert.equal((await respond(next, "approve", "tenantB")).status, "active");
  assert.equal((await lock("propA")).lease_id, next);
});

test("TAQ-110: the release trigger never removes a lock held by another lease", async () => {
  const id = (await create()).leaseId;
  await respond(id, "approve", "tenantA");
  await db.doc("Leases/old").set({ status: "active", property_id: "propA", owner_id: "ownerA", tenant_id: "tenantB", agency_id: "" });
  assert.equal(await writeLease("old", (ref) => ref.update({ status: "terminated" })), false);
  assert.equal((await lock("propA")).lease_id, id);
});

test("TAQ-110: a lock whose lease ran past its end date, or was ended without the trigger, is taken over", async () => {
  const id = (await create()).leaseId;
  await respond(id, "approve", "tenantA");
  await db.doc(`Leases/${id}`).update({ end_date: "2026-01-31" });
  leases.deps.now = () => Date.UTC(2026, 1, 1, 0, 0, 1);
  const next = (await create(input({ tenantId: "tenantB", startDate: "2026-02-01", endDate: "2027-01-31" }))).leaseId;
  assert.equal((await respond(next, "approve", "tenantB")).status, "active", "the old lease is past its end date");
  assert.equal((await lock("propA")).lease_id, next);

  leases.deps.now = () => Date.now();
  await db.doc(`Leases/${next}`).update({ status: "terminated" });
  const third = (await create(input({ tenantId: "tenantC" }))).leaseId;
  assert.equal((await respond(third, "approve", "tenantC")).status, "active", "a stale lock from a terminated lease");
  assert.equal((await lock("propA")).lease_id, third);
});

test("TAQ-110: the date range ends on the whole end day, and a future-start lease is live", async () => {
  const { leaseLiveState } = require("../lease_state");
  const l = { status: "active", start_date: "2030-01-01", end_date: "2030-12-31" };
  assert.equal(leaseLiveState(l, Date.UTC(2026, 0, 1)).live, true);
  assert.equal(leaseLiveState(l, Date.UTC(2030, 11, 31, 23, 59, 59)).live, true);
  assert.equal(leaseLiveState(l, Date.UTC(2031, 0, 1)).live, false);
  assert.equal(leaseLiveState({ ...l, status: "terminated" }, Date.UTC(2026, 0, 1)).live, false);
});

// --- the property is marked rented on activation (Q3) ---

const silo = async (uid, id) => (await db.doc(`Users/${uid}/properties/${id}`).get()).data();

test("TAQ-110: activation marks the private property rented and unpublished, in the same transaction as the lock", async () => {
  await db.doc("Users/ownerA/properties/propA").set({ isPublished: true, rentalStatus: "available" }, { merge: true });
  const id = (await create()).leaseId;
  const other = (await create(input({ tenantId: "tenantB" }))).leaseId;
  assert.equal((await silo("ownerA", "propA")).rentalStatus, "available", "an offer alone does not rent the property");
  await respond(id, "approve", "tenantA");
  const p = await silo("ownerA", "propA");
  assert.equal(p.rentalStatus, "rented");
  assert.equal(p.isPublished, false);
  assert.equal(p.title, "Flat A", "other fields are untouched");
  await reason(respond(other, "approve", "tenantB"), "failed-precondition", "property_already_leased");
  assert.equal((await silo("ownerA", "propA")).rentalStatus, "rented");
  await reason(create(input({ tenantId: "tenantC" })), "failed-precondition", "property_already_leased");
  await respond(other, "reject", "tenantB");
  assert.equal((await silo("ownerA", "propA")).rentalStatus, "rented");
});

test("TAQ-110: a rejected offer leaves the property as it was", async () => {
  await db.doc("Users/ownerA/properties/propA").set({ isPublished: true, rentalStatus: "available" }, { merge: true });
  const id = (await create()).leaseId;
  await respond(id, "reject", "tenantA");
  assert.deepEqual([(await silo("ownerA", "propA")).rentalStatus, (await silo("ownerA", "propA")).isPublished], ["available", true]);
});

test("TAQ-110: releasing the lock returns the property to available and does not republish it", async () => {
  for (const end of [(ref) => ref.update({ status: "terminated" }), (ref) => ref.update({ status: "expired" }), (ref) => ref.delete()]) {
    await db.doc("Users/ownerA/properties/propA").set({ isPublished: true, rentalStatus: "available" }, { merge: true });
    const id = (await create()).leaseId;
    await respond(id, "approve", "tenantA");
    assert.equal(await writeLease(id, (ref) => ref.update({ notes: "x" })), null);
    assert.equal((await silo("ownerA", "propA")).rentalStatus, "rented", "an active-to-active write changes nothing");
    assert.equal(await writeLease(id, end), true);
    const p = await silo("ownerA", "propA");
    assert.equal(p.rentalStatus, "available");
    assert.equal(p.isPublished, false, "the owner publishes again; nothing does it for them");
  }
});

test("TAQ-110: releasing leaves a status the owner set by hand, and a lock another lease took over", async () => {
  const id = (await create()).leaseId;
  await respond(id, "approve", "tenantA");
  await db.doc("Users/ownerA/properties/propA").update({ rentalStatus: "maintenance" });
  assert.equal(await writeLease(id, (ref) => ref.update({ status: "terminated" })), true);
  assert.equal((await silo("ownerA", "propA")).rentalStatus, "maintenance");

  const a = (await create(input({ tenantId: "tenantB" }))).leaseId;
  await reason(respond(a, "approve", "tenantB"), "failed-precondition", "property_not_available");
  await db.doc("Users/ownerA/properties/propA").update({ rentalStatus: "available" });
  await respond(a, "approve", "tenantB");
  await db.doc("Leases/old").set({ status: "active", property_id: "propA", owner_id: "ownerA", tenant_id: "tenantC", agency_id: "" });
  assert.equal(await writeLease("old", (ref) => ref.update({ status: "terminated" })), false);
  assert.equal((await silo("ownerA", "propA")).rentalStatus, "rented", "a lease that does not hold the lock cannot free the property");
});

// --- payments follow the same lock ---

test("TAQ-110: a second active lease on a property cannot take payments; the lock holder can", async () => {
  const id = (await create()).leaseId;
  await respond(id, "approve", "tenantA");
  await db.doc("Leases/forged").set({
    status: "active", property_id: "propA", owner_id: "ownerA", tenant_id: "tenantB", agency_id: "",
    country_code: "AE", monthly_rent: 5000, financialTerms: { monthlyRent: 5000 }, start_date: "2026-01-01", end_date: "2099-12-31",
  });
  await reason(fns.createRentPaymentIntent.run({ data: { leaseId: "forged" }, auth: caller("tenantB") }), "failed-precondition", "lease_not_verified");
  await reason(fns.recordManualPayment.run({ data: { leaseId: "forged", method: "cash", reference: "r1", paidOn: new Date().toISOString().slice(0, 10) }, auth: ownerA() }), "failed-precondition", "lease_not_verified");
  assert.equal((await fns.createRentPaymentIntent.run({ data: { leaseId: id }, auth: caller("tenantA") })).status, "pending");
});

test("TAQ-110: an older active lease without a lock claims it on first payment, once its property checks pass", async () => {
  const base = { status: "active", owner_id: "ownerA", agency_id: "", country_code: "AE", monthly_rent: 5000, financialTerms: { monthlyRent: 5000 }, start_date: "2026-01-01", end_date: "2099-12-31" };
  await db.doc("Leases/legacy").set({ ...base, property_id: "propA", tenant_id: "tenantA" });
  await db.doc("Leases/ghost").set({ ...base, property_id: "nope", tenant_id: "tenantB" });
  await db.doc("Leases/foreign").set({ ...base, owner_id: "ownerA", property_id: "propB", tenant_id: "tenantC" });
  assert.equal((await fns.createRentPaymentIntent.run({ data: { leaseId: "legacy" }, auth: caller("tenantA") })).status, "pending");
  assert.equal((await lock("propA")).lease_id, "legacy");
  await reason(fns.createRentPaymentIntent.run({ data: { leaseId: "ghost" }, auth: caller("tenantB") }), "failed-precondition", "property_not_found");
  await reason(fns.createRentPaymentIntent.run({ data: { leaseId: "foreign" }, auth: caller("tenantC") }), "failed-precondition", "property_not_found");
  assert.equal(await lock("nope"), undefined);
  assert.equal(await lock("propB"), undefined);
});

// --- the dry-run audit ---

test("TAQ-110: the lease audit only reads, refuses production, and lists what the checks would refuse", async () => {
  assert.throws(() => resolveTarget("qa-fake-prod-xyz"), /Refusing/);
  assert.throws(() => resolveTarget("some-other-project"), /Refusing/);
  assert.equal(resolveTarget("tashil-aqar-dev"), "tashil-aqar-dev");
  assert.equal(resolveTarget("demo-tashil-test"), "demo-tashil-test");

  const base = { status: "active", agency_id: "", country_code: "AE", monthly_rent: 5000, start_date: "2026-01-01", end_date: "2099-12-31" };
  await db.doc("Leases/a1").set({ ...base, owner_id: "ownerA", tenant_id: "tenantA", property_id: "propA" });
  await db.doc("Leases/a2").set({ ...base, owner_id: "ownerA", tenant_id: "tenantB", property_id: "propA" });
  await db.doc("Leases/ghost").set({ ...base, owner_id: "ownerA", tenant_id: "tenantC", property_id: "nope", status: "draft" });
  await db.doc("Leases/agency").set({ ...base, owner_id: "ownerA", tenant_id: "tenantC", property_id: "propA", agency_id: "ag1", status: "terminated" });
  await db.doc("Leases/norent").set({ ...base, owner_id: "ag1owner", tenant_id: "tenantC", property_id: "propNoAgency", agency_id: "ag1", monthly_rent: 0, status: "draft" });
  await db.doc("Leases/noprop").set({ ...base, owner_id: "ownerA", tenant_id: "tenantC", property_id: "", status: "draft" });
  await db.doc("PropertyLeaseLocks/propA").set({ lease_id: "a1", property_id: "propA" });
  const before = (await db.collection("Leases").get()).docs.map((d) => JSON.stringify(d.data())).sort();
  const locksBefore = (await db.collection("PropertyLeaseLocks").get()).size;

  const report = await audit(db, getAuth());
  assert.equal(report.leases, 6);
  assert.equal(report.liveLeases, 2);
  assert.deepEqual(report.multipleLiveLeases, [{ property_id: "propA", leaseIds: ["a1", "a2"] }]);
  assert.deepEqual(report.lockHeldByOther.map((x) => x.leaseId), ["a2"]);
  assert.deepEqual(report.liveWithoutLock, []);
  assert.deepEqual(report.propertyMissing.map((x) => x.leaseId), ["ghost"]);
  assert.deepEqual(report.agencyMismatch.map((x) => x.leaseId).sort(), ["agency", "norent"]);
  assert.deepEqual(report.rentInvalid.map((x) => x.leaseId), ["norent"]);
  assert.deepEqual(report.partiesMissing.map((x) => x.leaseId), ["noprop"]);
  assert.deepEqual(report.agencyPropertiesWithoutAgencyId.map((x) => x.property_id), ["propNoAgency"]);
  assert.deepEqual(report.statusCounts, { active: 2, draft: 3, terminated: 1 });
  assert.equal(report.registryEntries, 4);
  assert.deepEqual(report.unregisteredIds, []);
  assert.deepEqual(report.lockOwnerNotRegistered, [], "a1 is ownerA's lease and ownerA holds propA");
  assert.deepEqual(report.rentalStatusAll, { "(unset)": 4 });
  assert.deepEqual(report.rentalStatusLiveLeased, { "(unset)": 1 });

  const after = (await db.collection("Leases").get()).docs.map((d) => JSON.stringify(d.data())).sort();
  assert.deepEqual(after, before, "the audit writes nothing");
  assert.equal((await db.collection("PropertyLeaseLocks").get()).size, locksBefore);
});

// --- TAQ-141: contention on the accept path ---

async function withContendedTransactions(failures, run) {
  const original = db.runTransaction.bind(db);
  let remaining = failures;
  let calls = 0;
  db.runTransaction = (...args) => {
    calls += 1;
    if (remaining > 0) {
      remaining -= 1;
      return Promise.reject(Object.assign(new Error("10 ABORTED: Too much contention on these documents. Please try again."), { code: 10 }));
    }
    return original(...args);
  };
  try {
    return await run(() => calls);
  } finally {
    delete db.runTransaction;
  }
}

test("TAQ-141: an accept that loses to contention is retried and then succeeds", async () => {
  const id = (await create()).leaseId;
  await withContendedTransactions(2, async (calls) => {
    assert.equal((await respond(id, "approve", "tenantA")).status, "active");
    assert.equal(calls(), 3);
  });
  assert.equal((await lease(id)).status, "active");
  assert.equal((await lock("propA")).lease_id, id);
});

test("TAQ-141: raw contention with another live lease on the property becomes property_already_leased", async () => {
  const first = (await create()).leaseId;
  const second = (await create(input({ tenantId: "tenantB" }))).leaseId;
  await respond(first, "approve", "tenantA");
  await withContendedTransactions(99, async () => {
    await reason(respond(second, "approve", "tenantB"), "failed-precondition", "property_already_leased");
  });
  assert.equal((await lease(second)).status, "pending_tenant_approval");
});

test("TAQ-141: raw contention on a free property gives a retry-friendly answer and changes nothing", async () => {
  const id = (await create()).leaseId;
  await withContendedTransactions(99, async () => {
    await reason(respond(id, "approve", "tenantA"), "aborted", "try_again");
  });
  assert.equal((await lease(id)).status, "pending_tenant_approval");
  assert.equal(await lock("propA"), undefined);
  assert.equal((await respond(id, "approve", "tenantA")).status, "active", "a later attempt works");
});

test("TAQ-141: only contention is retried; other errors and refusals pass straight through", async () => {
  assert.equal(leases.isContention(Object.assign(new Error("boom"), { code: 10 })), true);
  assert.equal(leases.isContention(Object.assign(new Error("3 INVALID_ARGUMENT: the transaction was aborted"), { code: 3 })), true);
  assert.equal(leases.isContention(Object.assign(new Error("bad field"), { code: 3 })), false);
  assert.equal(leases.isContention(new Error("plain")), false);
  let attempts = 0;
  await assert.rejects(leases.retryOnContention(async () => { attempts += 1; throw new Error("plain"); }, () => "x"), /plain/);
  assert.equal(attempts, 1);
  const id = (await create()).leaseId;
  await reason(respond(id, "approve", "tenantB"), "permission-denied");
});
