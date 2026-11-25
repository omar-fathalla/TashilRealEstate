// TAQ-112: viewing requests and rental applications are written by the server only.
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");
const requests = require("../requests");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;

const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });
const visitor = () => caller("visitor");

async function expectCode(promise, code) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    return true;
  });
}

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

const listing = (extra = {}) => ({
  owner_id: "owner",
  agency_id: "agency-1",
  countryCode: "AE",
  is_published: true,
  moderation_hidden: false,
  pricePerMonth: 8000,
  titles: { ar: "شقة المارينا", en: "Marina Apartment", hi: "मरीना अपार्टमेंट" },
  ...extra,
});

let clock;
test.beforeEach(async () => {
  await clearAll();
  clock = Date.UTC(2026, 5, 15, 12, 0, 0);
  requests.deps.now = () => clock;
  await Promise.all([
    db.doc("Users/owner").set({ role: "Owner" }),
    db.doc("Users/visitor").set({ role: "Tenant" }),
    db.doc("Users/investor").set({ role: "Investor" }),
    db.doc("Users/other").set({ role: "Owner" }),
    db.doc("Properties/p1").set(listing()),
    db.doc("Properties/hidden").set(listing({ is_published: false })),
    db.doc("Properties/held").set(listing({ moderation_hidden: true })),
    db.doc("Properties/noowner").set(listing({ owner_id: "" })),
    db.doc("Users/owner/properties/p1").set({ title: "Marina Apartment" }),
  ]);
});
test.after(() => {
  requests.deps.now = () => Date.now();
});

const view = (data = {}, auth = visitor()) =>
  fns.requestViewing.run({ data: { listingId: "p1", name: "Sara Ali", phone: "+971 50 123 4567", ...data }, auth });
const apply = (data = {}, auth = visitor()) =>
  fns.applyForRental.run({ data: { listingId: "p1", name: "Sara Ali", phone: "+971501234567", ...data }, auth });

// --- requestViewing ---

test("TAQ-112: a signed-in visitor requests a viewing; parties come from the listing and the owner is notified", async () => {
  const result = await view({
    message: "  After 6pm  ",
    preferredDate: "2026-06-20",
    owner_id: "someone-else",
    agency_id: "agency-9",
    status: "confirmed",
    requester_id: "other",
  });
  assert.equal(result.status, "pending");
  const doc = (await db.collection("ViewingRequests").doc(result.requestId).get()).data();
  assert.equal(doc.listing_id, "p1");
  assert.equal(doc.owner_id, "owner");
  assert.equal(doc.agency_id, "agency-1");
  assert.equal(doc.requester_id, "visitor");
  assert.equal(doc.requester_name, "Sara Ali");
  assert.equal(doc.requester_phone, "+971501234567");
  assert.equal(doc.message, "After 6pm");
  assert.equal(doc.preferred_date, "2026-06-20");
  assert.equal(doc.status, "pending");
  assert.equal(doc.country_code, "AE");
  assert.equal(doc.listing_titles.en, "Marina Apartment");
  const note = (await db.doc(`Users/owner/notifications/viewing_${result.requestId}`).get()).data();
  assert.equal(note.type, "viewing_request");
  assert.equal(note.recipientId, "owner");
  assert.equal(note.read, false);
  assert.ok(note.title.ar && note.title.en && note.title.hi);
  assert.doesNotMatch(note.body.ar, /[A-Za-z]/, "Arabic copy stays pure");
});

test("TAQ-112: viewing requests need a real sign-in", async () => {
  await expectCode(fns.requestViewing.run({ data: { listingId: "p1", name: "Sara", phone: "+971501234567" } }), "unauthenticated");
  const anon = caller("anon1", { firebase: { sign_in_provider: "anonymous" } });
  await expectCode(view({}, anon), "unauthenticated");
  assert.equal((await db.collection("ViewingRequests").get()).size, 0);
});

test("TAQ-112: the listing must be live", async () => {
  for (const listingId of ["hidden", "held", "noowner", "missing"]) {
    await assert.rejects(view({ listingId }), (e) => e.code === "failed-precondition" && e.details.reason === "listing_not_live", listingId);
  }
  for (const listingId of [undefined, "", 5, "a/b", "x".repeat(201)]) await expectCode(view({ listingId }), "invalid-argument");
  assert.equal((await db.collection("ViewingRequests").get()).size, 0);
});

test("TAQ-112: name, phone, message and date are validated", async () => {
  for (const name of [undefined, "", " ", "A", 5]) await expectCode(view({ name }), "invalid-argument");
  for (const phone of [undefined, "", "abc", "12345", "+1234567890123456", "050-abc-1234", 5]) await expectCode(view({ phone }), "invalid-argument");
  await expectCode(view({ message: 5 }), "invalid-argument");
  for (const preferredDate of ["2026-13-01", "20-06-2026", "2026-06-10", "2027-06-20", 5]) await expectCode(view({ preferredDate }), "invalid-argument");
  assert.equal((await db.collection("ViewingRequests").get()).size, 0);
  const long = await view({ message: "x".repeat(900), name: "N".repeat(300) });
  const doc = (await db.collection("ViewingRequests").doc(long.requestId).get()).data();
  assert.equal(doc.message.length, 500);
  assert.equal(doc.requester_name.length, 100);
});

test("TAQ-112: an owner or the listing's agency cannot request a viewing of their own listing", async () => {
  await expectCode(view({}, caller("owner")), "failed-precondition");
  await expectCode(view({}, caller("agent1", { role: "AgencyAdmin", agency_id: "agency-1" })), "failed-precondition");
  assert.ok((await view({}, caller("other"))).requestId, "another owner may ask to view");
});

test("TAQ-112: one pending viewing request per listing per user; a new one is allowed after an answer", async () => {
  const first = await view();
  await assert.rejects(view(), (e) => e.code === "already-exists" && e.details.reason === "duplicate_pending");
  await fns.respondToViewingRequest.run({ data: { requestId: first.requestId, decision: "declined" }, auth: caller("owner") });
  assert.ok((await view()).requestId);
  assert.equal((await db.collection("ViewingRequests").get()).size, 2);
});

test("TAQ-112: viewing requests are rate limited per user", async () => {
  await db.doc("Properties/p2").set(listing());
  await db.doc("Properties/p3").set(listing());
  await db.doc("Properties/p4").set(listing());
  await view({ listingId: "p1" });
  await view({ listingId: "p2" });
  await view({ listingId: "p3" });
  await assert.rejects(view({ listingId: "p4" }), (e) => e.code === "resource-exhausted" && e.details.retry === "minute");
  clock += 61 * 1000;
  assert.ok((await view({ listingId: "p4" })).requestId);
  await view({ listingId: "p1" }).catch(() => {});
  assert.ok((await db.collection("ViewingRequests").get()).size <= 4);
  // Another user is not affected.
  await db.doc("Users/v2").set({ role: "Tenant" });
  assert.ok((await view({ listingId: "p1" }, caller("v2"))).requestId);
});

test("TAQ-112: the daily limit stops a user who stays under the per-minute limit", async () => {
  for (let i = 0; i < 20; i += 1) {
    await db.doc(`Properties/d${i}`).set(listing());
    await view({ listingId: `d${i}` });
    clock += 61 * 1000;
  }
  await db.doc("Properties/d20").set(listing());
  await assert.rejects(view({ listingId: "d20" }), (e) => e.code === "resource-exhausted" && e.details.retry === "day");
  clock += 24 * 60 * 60 * 1000;
  assert.ok((await view({ listingId: "d20" })).requestId);
});

// --- respondToViewingRequest ---

test("TAQ-112: the owner confirms a viewing and the requester is notified", async () => {
  const { requestId } = await view();
  const result = await fns.respondToViewingRequest.run({ data: { requestId, decision: "confirmed", note: "Saturday 5pm" }, auth: caller("owner") });
  assert.equal(result.status, "confirmed");
  const doc = (await db.doc(`ViewingRequests/${requestId}`).get()).data();
  assert.equal(doc.status, "confirmed");
  assert.equal(doc.response_note, "Saturday 5pm");
  assert.equal(doc.responded_by, "owner");
  const note = (await db.doc(`Users/visitor/notifications/viewing_${requestId}_confirmed`).get()).data();
  assert.equal(note.type, "viewing_confirmed");
  assert.equal(note.recipientId, "visitor");
  assert.doesNotMatch(note.body.ar, /[A-Za-z]/);
});

test("TAQ-112: the managing agency and SuperAdmin respond; everyone else is denied", async () => {
  const a = await view();
  await expectCode(fns.respondToViewingRequest.run({ data: { requestId: a.requestId, decision: "confirmed" }, auth: caller("agent2", { role: "AgencyAdmin", agency_id: "agency-2" }) }), "permission-denied");
  await expectCode(fns.respondToViewingRequest.run({ data: { requestId: a.requestId, decision: "confirmed" }, auth: caller("other") }), "permission-denied");
  await expectCode(fns.respondToViewingRequest.run({ data: { requestId: a.requestId, decision: "confirmed" }, auth: visitor() }), "permission-denied");
  await expectCode(fns.respondToViewingRequest.run({ data: { requestId: a.requestId, decision: "confirmed" }, auth: caller("adm", { role: "Admin" }) }), "permission-denied");
  await expectCode(fns.respondToViewingRequest.run({ data: { requestId: a.requestId, decision: "confirmed" } }), "unauthenticated");
  assert.equal((await db.doc(`ViewingRequests/${a.requestId}`).get()).get("status"), "pending");
  await fns.respondToViewingRequest.run({ data: { requestId: a.requestId, decision: "confirmed" }, auth: caller("agent1", { role: "AgencyAdmin", agency_id: "agency-1" }) });
  await db.doc("Users/v3").set({ role: "Tenant" });
  const c = await view({}, caller("v3"));
  await fns.respondToViewingRequest.run({ data: { requestId: c.requestId, decision: "declined" }, auth: caller("sa", { role: "SuperAdmin" }) });
  assert.equal((await db.doc(`ViewingRequests/${c.requestId}`).get()).get("status"), "declined");
});

test("TAQ-112: a viewing request is answered once, with a valid decision", async () => {
  const { requestId } = await view();
  for (const decision of ["pending", "approved", "", undefined]) {
    await expectCode(fns.respondToViewingRequest.run({ data: { requestId, decision }, auth: caller("owner") }), "invalid-argument");
  }
  await fns.respondToViewingRequest.run({ data: { requestId, decision: "declined" }, auth: caller("owner") });
  await assert.rejects(fns.respondToViewingRequest.run({ data: { requestId, decision: "confirmed" }, auth: caller("owner") }), (e) => e.details.reason === "not_pending");
  await expectCode(fns.respondToViewingRequest.run({ data: { requestId: "nope", decision: "confirmed" }, auth: caller("owner") }), "not-found");
  assert.equal((await db.doc(`ViewingRequests/${requestId}`).get()).get("status"), "declined");
});

// --- applyForRental ---

test("TAQ-112: a signed-in tenant applies for a live listing; parties come from the listing", async () => {
  const result = await apply({ message: "Family of 3", moveInDate: "2026-07-01", occupants: 3, owner_id: "x", status: "approved", applicant_id: "other" });
  assert.equal(result.applicationId, "p1_visitor");
  const doc = (await db.doc("RentalApplications/p1_visitor").get()).data();
  assert.equal(doc.status, "pending");
  assert.equal(doc.owner_id, "owner");
  assert.equal(doc.agency_id, "agency-1");
  assert.equal(doc.applicant_id, "visitor");
  assert.equal(doc.applicant_name, "Sara Ali");
  assert.equal(doc.applicant_phone, "+971501234567");
  assert.equal(doc.occupants, 3);
  assert.equal(doc.move_in_date, "2026-07-01");
  assert.equal(doc.listing_titles.en, "Marina Apartment");
  assert.equal(doc.attempt, 1);
  const note = (await db.doc("Users/owner/notifications/application_p1_visitor_1").get()).data();
  assert.equal(note.type, "rental_application");
});

test("TAQ-112: only a signed-in Tenant applies, and only for a live listing", async () => {
  await expectCode(fns.applyForRental.run({ data: { listingId: "p1", name: "Sara", phone: "+971501234567" } }), "unauthenticated");
  await expectCode(apply({}, caller("anon1", { firebase: { sign_in_provider: "anonymous" } })), "unauthenticated");
  await expectCode(apply({}, caller("investor")), "permission-denied");
  await expectCode(apply({}, caller("other")), "permission-denied");
  for (const listingId of ["hidden", "held", "noowner", "missing"]) {
    await assert.rejects(apply({ listingId }), (e) => e.code === "failed-precondition" && e.details.reason === "listing_not_live", listingId);
  }
  assert.equal((await db.collection("RentalApplications").get()).size, 0);
});

test("TAQ-112: application fields are validated", async () => {
  for (const occupants of [0, 21, 1.5, "2", -1]) await expectCode(apply({ occupants }), "invalid-argument");
  for (const moveInDate of ["2026-02-30", "bad", "2025-01-01", "2030-01-01"]) await expectCode(apply({ moveInDate }), "invalid-argument");
  for (const phone of ["", "1", "abc"]) await expectCode(apply({ phone }), "invalid-argument");
  await expectCode(apply({ name: "" }), "invalid-argument");
  assert.equal((await db.collection("RentalApplications").get()).size, 0);
  assert.equal((await apply()).applicationId, "p1_visitor");
});

test("TAQ-112: one application per listing; a rejected applicant may apply again", async () => {
  await apply();
  clock += 61 * 1000;
  await assert.rejects(apply(), (e) => e.code === "already-exists" && e.details.reason === "duplicate_application");
  await fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "rejected" }, auth: caller("owner") });
  clock += 61 * 1000;
  await apply({ message: "second try" });
  const doc = (await db.doc("RentalApplications/p1_visitor").get()).data();
  assert.equal(doc.status, "pending");
  assert.equal(doc.attempt, 2);
  assert.equal(doc.message, "second try");
  await fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "approved" }, auth: caller("owner") });
  clock += 61 * 1000;
  await assert.rejects(apply(), (e) => e.code === "already-exists" && e.details.status === "approved");
});

test("TAQ-112: applications are rate limited", async () => {
  for (const id of ["a1", "a2", "a3"]) await db.doc(`Properties/${id}`).set(listing());
  await apply({ listingId: "a1" });
  await apply({ listingId: "a2" });
  await assert.rejects(apply({ listingId: "a3" }), (e) => e.code === "resource-exhausted");
});

// --- decideRentalApplication ---

test("TAQ-112: the owner approves or rejects and the applicant is notified; an application is decided once", async () => {
  await apply();
  const result = await fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "approved", note: "Welcome" }, auth: caller("owner") });
  assert.equal(result.status, "approved");
  const doc = (await db.doc("RentalApplications/p1_visitor").get()).data();
  assert.equal(doc.status, "approved");
  assert.equal(doc.decided_by, "owner");
  assert.equal(doc.response_note, "Welcome");
  const note = (await db.doc("Users/visitor/notifications/application_p1_visitor_1_approved").get()).data();
  assert.equal(note.type, "application_approved");
  assert.match(note.body.en, /lease offer/);
  await assert.rejects(fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "rejected" }, auth: caller("owner") }), (e) => e.details.reason === "not_pending");
  for (const decision of ["pending", "confirmed", undefined]) {
    await expectCode(fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision }, auth: caller("owner") }), "invalid-argument");
  }
});

test("TAQ-112: only the owner, the managing agency and SuperAdmin decide an application", async () => {
  await apply();
  const decide = (auth) => fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "approved" }, auth });
  await expectCode(decide(visitor()), "permission-denied");
  await expectCode(decide(caller("other")), "permission-denied");
  await expectCode(decide(caller("agent2", { role: "AgencyAdmin", agency_id: "agency-2" })), "permission-denied");
  await expectCode(decide(caller("adm", { role: "Admin" })), "permission-denied");
  await expectCode(fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "approved" } }), "unauthenticated");
  await expectCode(fns.decideRentalApplication.run({ data: { applicationId: "zzz", decision: "approved" }, auth: caller("owner") }), "not-found");
  assert.equal((await db.doc("RentalApplications/p1_visitor").get()).get("status"), "pending");
  await decide(caller("agent1", { role: "AgencyAdmin", agency_id: "agency-1" }));
});

// --- createLeaseFromApplication ---

const leaseInput = (extra = {}) => ({ applicationId: "p1_visitor", startDate: "2026-07-01", endDate: "2027-06-30", ...extra });
const createLease = (data = leaseInput(), auth = caller("owner")) => fns.createLeaseFromApplication.run({ data, auth });

async function approvedApplication() {
  await apply();
  await fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "approved" }, auth: caller("owner") });
}

test("TAQ-112: approving lets the owner create a draft lease from the application", async () => {
  await approvedApplication();
  const result = await createLease(leaseInput({ monthlyRent: 7500, tenant_id: "evil", owner_id: "evil", status: "active" }));
  assert.equal(result.status, "draft");
  assert.equal(result.leaseId, "app_p1_visitor");
  const lease = (await db.doc("Leases/app_p1_visitor").get()).data();
  assert.equal(lease.status, "draft");
  assert.equal(lease.tenant_id, "visitor");
  assert.equal(lease.owner_id, "owner");
  assert.equal(lease.agency_id, "agency-1");
  assert.equal(lease.property_id, "p1");
  assert.equal(lease.application_id, "p1_visitor");
  assert.equal(lease.monthly_rent, 7500);
  assert.deepEqual(lease.financialTerms, { monthlyRent: 7500 });
  assert.equal(lease.country_code, "AE");
  assert.equal(lease.start_date, "2026-07-01");
  assert.equal(lease.end_date, "2027-06-30");
  assert.equal(lease.tenant_name, "Sara Ali");
  assert.equal(lease.property_title, "Marina Apartment");
  assert.equal((await db.doc("RentalApplications/p1_visitor").get()).get("lease_id"), "app_p1_visitor");
});

test("TAQ-112: the lease rent defaults to the listing price", async () => {
  await approvedApplication();
  await createLease();
  assert.equal((await db.doc("Leases/app_p1_visitor").get()).get("monthly_rent"), 8000);
});

test("TAQ-112: no lease from a pending or rejected application, and only one lease per application", async () => {
  await apply();
  await assert.rejects(createLease(), (e) => e.details.reason === "not_approved");
  await fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "rejected" }, auth: caller("owner") });
  await assert.rejects(createLease(), (e) => e.details.reason === "not_approved");
  await apply();
  await fns.decideRentalApplication.run({ data: { applicationId: "p1_visitor", decision: "approved" }, auth: caller("owner") });
  await createLease();
  await expectCode(createLease(), "already-exists");
  assert.equal((await db.collection("Leases").get()).size, 1);
});

test("TAQ-112: only managers create the lease, with valid dates and rent", async () => {
  await approvedApplication();
  await expectCode(createLease(leaseInput(), visitor()), "permission-denied");
  await expectCode(createLease(leaseInput(), caller("other")), "permission-denied");
  await expectCode(createLease(leaseInput(), caller("agent2", { role: "AgencyAdmin", agency_id: "agency-2" })), "permission-denied");
  await expectCode(fns.createLeaseFromApplication.run({ data: leaseInput() }), "unauthenticated");
  await expectCode(createLease(leaseInput({ applicationId: "nope" })), "not-found");
  for (const startDate of [undefined, "bad", "2026-02-30"]) await expectCode(createLease(leaseInput({ startDate })), "invalid-argument");
  await expectCode(createLease(leaseInput({ endDate: "2026-07-01" })), "invalid-argument");
  await expectCode(createLease(leaseInput({ endDate: "2026-06-01" })), "invalid-argument");
  for (const monthlyRent of [0, -5, "8000", 1e10, NaN]) await expectCode(createLease(leaseInput({ monthlyRent })), "invalid-argument");
  assert.equal((await db.collection("Leases").get()).size, 0);
  await createLease(leaseInput(), caller("agent1", { role: "AgencyAdmin", agency_id: "agency-1" }));
});

test("TAQ-112: two managers creating the lease at once produce one lease", async () => {
  await approvedApplication();
  const results = await Promise.allSettled([createLease(), createLease(), createLease()]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal((await db.collection("Leases").get()).size, 1);
});
