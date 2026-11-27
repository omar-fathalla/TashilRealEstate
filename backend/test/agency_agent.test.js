// TAQ-169 (A): the AgencyAgent role. Reads what its agency manages, writes almost nothing.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require("firebase/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the emulators are attached.");
}

const fns = require("../index");
const db = getFirestore();
const projectId = process.env.GCLOUD_PROJECT || "demo-tashil-test";
let testEnv;

const AGENT = { role: "AgencyAgent", agency_id: "ag1" };
const OTHER_AGENT = { role: "AgencyAgent", agency_id: "ag2" };
const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
  const lease = { tenant_id: "tenant1", owner_id: "owner1", agency_id: "ag1", status: "active", monthlyRent: 5000, countryCode: "AE", property_id: "p1" };
  await db.doc("Leases/L1").set(lease);
  await db.doc("Invoices/I1").set({ tenant_id: "tenant1", owner_id: "owner1", agency_id: "ag1" });
  await db.doc("Transactions/T1").set({ tenant_id: "tenant1", owner_id: "owner1", agency_id: "ag1" });
  await db.doc("RentRowStates/L1_2026-01").set({ owner_id: "owner1", agency_id: "ag1" });
  await db.doc("PropertyMandates/p1").set({ owner_id: "owner1", agency_id: "ag1", status: "active" });
  await db.doc("ViewingRequests/v1").set({ requester_id: "tenant1", owner_id: "owner1", agency_id: "ag1", status: "pending", listing_id: "p1" });
  await db.doc("RentalApplications/a1").set({ applicant_id: "tenant1", owner_id: "owner1", agency_id: "ag1", status: "pending", listing_id: "p1" });
  await db.doc("Maintenance/m1").set({ lease_id: "L1", tenant_id: "tenant1", owner_id: "owner1", agency_id: "ag1", status: "pending", resolution_note: "" });
  await db.doc("Agencies/ag1").set({ name: "Agency One" });
  await db.doc("Agencies/ag1/private/payout").set({ iban: "x" });
  await db.doc("Properties/p1").set({ owner_id: "owner1", agency_id: "ag1", is_published: false, status: "vacant" });
});

const as = (claims, uid = "agent1") => testEnv.authenticatedContext(uid, claims).firestore();

test("TAQ-169 rules: an agent reads its agency's leases, rent rows, mandates, requests, maintenance and drafts", async () => {
  const agent = as(AGENT);
  for (const p of ["Leases/L1", "RentRowStates/L1_2026-01", "PropertyMandates/p1", "ViewingRequests/v1", "RentalApplications/a1", "Maintenance/m1", "Properties/p1"]) {
    await assertSucceeds(getDoc(doc(agent, p)), p);
    await assertFails(getDoc(doc(as(OTHER_AGENT), p)), `other agency: ${p}`);
  }
});

test("TAQ-169 rules: an agent gets no invoices, transactions or payout details", async () => {
  for (const p of ["Invoices/I1", "Transactions/T1", "Agencies/ag1/private/payout"]) {
    await assertFails(getDoc(doc(as(AGENT), p)), p);
  }
  await assertSucceeds(getDoc(doc(as({ role: "AgencyAdmin", agency_id: "ag1" }, "adm1"), "Invoices/I1")), "the admin still can");
});

test("TAQ-169 rules: an agent writes no lease, listing, agency or mandate and deletes nothing", async () => {
  const agent = as(AGENT);
  await assertFails(updateDoc(doc(agent, "Leases/L1"), { notes: "x" }));
  await assertFails(deleteDoc(doc(agent, "Leases/L1")));
  await assertFails(deleteDoc(doc(agent, "Properties/p1")));
  await assertFails(updateDoc(doc(agent, "Agencies/ag1"), { name: "Mine" }));
  await assertFails(setDoc(doc(agent, "Agencies/ag1/private/payout"), { iban: "y" }));
  await assertFails(deleteDoc(doc(agent, "Maintenance/m1")));
  await assertFails(setDoc(doc(agent, "Users/agent1"), { role: "AgencyAdmin" }));
});

test("TAQ-169 rules: an agent can move its agency's maintenance request along", async () => {
  await assertSucceeds(updateDoc(doc(as(AGENT), "Maintenance/m1"), { status: "in_progress", resolution_note: "On it" }));
  await assertFails(updateDoc(doc(as(OTHER_AGENT), "Maintenance/m1"), { status: "resolved" }));
});

test("TAQ-169 rules: a profile that says AgencyAgent grants nothing without the claim", async () => {
  await db.doc("Users/fake").set({ role: "AgencyAgent", agency_id: "ag1" });
  await assertFails(getDoc(doc(as({}, "fake"), "Leases/L1")));
});

async function expectCode(promise, code) {
  await assert.rejects(promise, (e) => e.code === code || assert.fail(`expected ${code}, got ${e.code}: ${e.message}`));
}

test("TAQ-169 callables: an agent may update rent rows and answer viewings, but not delete rows or send legal notices", async () => {
  const agent = caller("agent1", AGENT);
  const r = await fns.updateRentRow.run({ data: { leaseId: "L1", period: "2026-01", action: "note", notes: "called" }, auth: agent });
  assert.ok(r);
  for (const action of ["delete", "legal_notice"]) {
    await expectCode(fns.updateRentRow.run({ data: { leaseId: "L1", period: "2026-01", action }, auth: agent }), "permission-denied");
  }
  await expectCode(fns.updateRentRow.run({ data: { leaseId: "L1", period: "2026-01", action: "note" }, auth: caller("agent2", OTHER_AGENT) }), "permission-denied");
  await fns.respondToViewingRequest.run({ data: { requestId: "v1", decision: "confirmed" }, auth: agent });
  assert.equal((await db.doc("ViewingRequests/v1").get()).get("status"), "confirmed");
});

test("TAQ-169 callables: an agent cannot decide applications, make leases, record payments, issue receipts or touch mandates", async () => {
  const agent = caller("agent1", AGENT);
  const calls = [
    [fns.decideRentalApplication, { applicationId: "a1", decision: "approved" }],
    [fns.createLeaseFromApplication, { applicationId: "a1" }],
    [fns.createLease, { propertyId: "p1" }],
    [fns.recordManualPayment, { leaseId: "L1", method: "cash", reference: "r" }],
    [fns.generateRentalInvoiceReceipt, { leaseId: "L1" }],
    [fns.inviteMandate, { propertyId: "p1" }],
    [fns.respondToMandate, { propertyId: "p1", accept: true }],
    [fns.revokeMandate, { propertyId: "p1" }],
    [fns.setUserRole, { uid: "x", role: "Owner" }],
    [fns.listUsersForAdmin, {}],
  ];
  for (const [fn, data] of calls) await expectCode(fn.run({ data, auth: agent }), "permission-denied");
});

test("TAQ-169: setUserRole cannot assign AgencyAgent; it comes only from an invite", async () => {
  await getAuth().createUser({ uid: "x" });
  await expectCode(fns.setUserRole.run({ data: { uid: "x", role: "AgencyAgent", agencyId: "ag1" }, auth: caller("root", { role: "SuperAdmin" }) }), "invalid-argument");
});
