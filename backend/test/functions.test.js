const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;

function caller(uid, claims = {}) {
  return { uid, token: { uid, ...claims } };
}

async function expectCode(promise, code) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    return true;
  });
}

async function clearFirestore() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
}

async function clearAuth() {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

test.beforeEach(async () => {
  await Promise.all([clearFirestore(), clearAuth()]);
  await db.collection("Users").doc("owner").set({ role: "Owner" });
  await db.collection("Users").doc("tenant").set({ role: "Tenant" });
  await db.collection("Users").doc("stranger").set({ role: "Owner" });
  await db.collection("Leases").doc("lease-1").set({
    owner_id: "owner",
    tenant_id: "tenant",
    agency_id: "agency-1",
    country_code: "AE",
    property_title: "Marina Apartment",
    tenant_name: "Lease Tenant",
    financialTerms: { monthlyRent: 8000 },
  });
});

// --- TAQ-17: sendRentalReminder ---

test("TAQ-17: reminder requires sign-in", async () => {
  await expectCode(fns.sendRentalReminder.run({ data: { leaseId: "lease-1" } }), "unauthenticated");
});

test("TAQ-17: a user who is not on the lease cannot send a reminder", async () => {
  await expectCode(
    fns.sendRentalReminder.run({ data: { leaseId: "lease-1", tenantId: "tenant" }, auth: caller("stranger") }),
    "permission-denied",
  );
  await expectCode(
    fns.sendRentalReminder.run({ data: { leaseId: "lease-1" }, auth: caller("agent2", { role: "AgencyAdmin", agency_id: "agency-2" }) }),
    "permission-denied",
  );
});

test("TAQ-17: a tenant cannot send reminders", async () => {
  await expectCode(fns.sendRentalReminder.run({ data: { leaseId: "lease-1" }, auth: caller("tenant") }), "permission-denied");
});

test("TAQ-17: a self-assigned SuperAdmin profile without a claim is rejected", async () => {
  await db.collection("Users").doc("legacy").set({ role: "SuperAdmin" });
  await expectCode(fns.sendRentalReminder.run({ data: { leaseId: "lease-1" }, auth: caller("legacy") }), "permission-denied");
});

test("TAQ-17: an unknown lease is rejected", async () => {
  await expectCode(fns.sendRentalReminder.run({ data: { leaseId: "nope" }, auth: caller("owner") }), "not-found");
});

test("TAQ-17: the landlord's reminder uses lease data and is rate limited per lease", async () => {
  const result = await fns.sendRentalReminder.run({
    data: { leaseId: "lease-1", tenantId: "victim", amount: 1, propertyTitle: "Pay to IBAN X", countryCode: "EG" },
    auth: caller("owner"),
  });
  assert.equal(result.success, true);
  const notification = (await db.collection("Notifications").doc(result.messageId).get()).data();
  assert.equal(notification.recipientId, "tenant");
  assert.equal(notification.amount, 8000);
  assert.equal(notification.currency, "AED");
  assert.match(notification.body.en, /Marina Apartment/);
  assert.doesNotMatch(notification.body.en, /IBAN/);
  assert.ok((await db.doc(`Users/tenant/notifications/${result.messageId}`).get()).exists);
  assert.equal((await db.doc("Users/victim/notifications/" + result.messageId).get()).exists, false);

  await expectCode(fns.sendRentalReminder.run({ data: { leaseId: "lease-1" }, auth: caller("owner") }), "resource-exhausted");
});

test("TAQ-17: the managing agency can send a reminder", async () => {
  const result = await fns.sendRentalReminder.run({
    data: { leaseId: "lease-1" },
    auth: caller("agent1", { role: "AgencyAdmin", agency_id: "agency-1" }),
  });
  assert.equal(result.success, true);
});

// --- TAQ-17: generateRentalInvoiceReceipt ---

test("TAQ-17: a user who is not on the lease cannot issue an invoice", async () => {
  await expectCode(
    fns.generateRentalInvoiceReceipt.run({ data: { leaseId: "lease-1", amount: 1 }, auth: caller("stranger") }),
    "permission-denied",
  );
  await expectCode(
    fns.generateRentalInvoiceReceipt.run({ data: { leaseId: "lease-1" } }),
    "unauthenticated",
  );
});

test("TAQ-17: invoice amounts and VAT are computed from the lease", async () => {
  const result = await fns.generateRentalInvoiceReceipt.run({
    data: { leaseId: "lease-1", amount: 1, tenantName: "Fake", currencyCode: "EGP" },
    auth: caller("owner"),
  });
  const invoice = (await db.collection("Invoices").doc(result.invoiceNumber).get()).data();
  assert.equal(invoice.amount, 8000);
  assert.equal(invoice.currencyCode, "AED");
  assert.equal(invoice.tenantName, "Lease Tenant");
  assert.equal(invoice.status, "Issued");
  assert.equal(invoice.vatAmount, (8000 * 0.025 + 8000 * 0.08) * 0.05);
  assert.equal(invoice.owner_id, "owner");
  assert.equal(invoice.tenant_id, "tenant");
});

// --- TAQ-45: no public endpoint can create accounts or grant claims ---

test("TAQ-45: seedDatabase is no longer a deployed function", () => {
  assert.equal(fns.seedDatabase, undefined);
  const publicHttp = Object.keys(fns)
    .filter((name) => fns[name] && fns[name].__endpoint && fns[name].__endpoint.httpsTrigger)
    .sort();
  // syncMarketIndexManual is tracked separately (TAQ-20) and touches no accounts.
  assert.deepEqual(publicHttp, ["syncMarketIndexManual"]);
});

// --- TAQ-8 / TAQ-9: setUserRole ---

test("TAQ-8: only a SuperAdmin claim can assign roles", async () => {
  await admin.auth().createUser({ uid: "target" });
  await expectCode(fns.setUserRole.run({ data: { uid: "target", role: "SuperAdmin" }, auth: caller("owner") }), "permission-denied");
  await db.collection("Users").doc("legacy").set({ role: "SuperAdmin" });
  await expectCode(fns.setUserRole.run({ data: { uid: "legacy", role: "SuperAdmin" }, auth: caller("legacy") }), "permission-denied");
});

test("TAQ-9: setUserRole writes the role and agency as custom claims", async () => {
  await admin.auth().createUser({ uid: "target" });
  const adminCaller = caller("root", { role: "SuperAdmin" });
  await expectCode(fns.setUserRole.run({ data: { uid: "target", role: "AgencyAdmin" }, auth: adminCaller }), "invalid-argument");
  await expectCode(fns.setUserRole.run({ data: { uid: "target", role: "Overlord" }, auth: adminCaller }), "invalid-argument");

  await fns.setUserRole.run({ data: { uid: "target", role: "AgencyAdmin", agencyId: "agency-1" }, auth: adminCaller });
  let user = await admin.auth().getUser("target");
  assert.deepEqual(user.customClaims, { role: "AgencyAdmin", agency_id: "agency-1" });
  const profile = (await db.collection("Users").doc("target").get()).data();
  assert.equal(profile.role, "AgencyAdmin");
  assert.equal(profile.agency_id, "agency-1");
  assert.equal(profile.role_updated_by, "root");

  await fns.setUserRole.run({ data: { uid: "target", role: "Owner" }, auth: adminCaller });
  user = await admin.auth().getUser("target");
  assert.deepEqual(user.customClaims, { role: "Owner" });
});
