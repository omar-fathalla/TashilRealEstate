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
  assert.deepEqual(publicHttp, []);
});

// --- TAQ-20: syncMarketIndexManual ---

test("TAQ-20: syncMarketIndexManual is a single-instance callable, not a public HTTP endpoint", () => {
  const endpoint = fns.syncMarketIndexManual.__endpoint;
  assert.ok(endpoint.callableTrigger, "expected a callable trigger");
  assert.equal(endpoint.httpsTrigger, undefined);
  assert.equal(endpoint.maxInstances, 1);
  assert.equal(typeof fns.syncMarketIndexDaily, "function");
});

test("TAQ-20: market index refresh requires sign-in", async () => {
  await expectCode(fns.syncMarketIndexManual.run({ data: { country: "EG" } }), "unauthenticated");
});

test("TAQ-20: only a SuperAdmin can refresh the market index", async () => {
  await expectCode(fns.syncMarketIndexManual.run({ data: { country: "EG" }, auth: caller("owner") }), "permission-denied");
  await expectCode(
    fns.syncMarketIndexManual.run({ data: { country: "EG" }, auth: caller("agent", { role: "AgencyAdmin", agency_id: "agency-1" }) }),
    "permission-denied",
  );
  await db.collection("Users").doc("legacy").set({ role: "SuperAdmin" });
  await expectCode(fns.syncMarketIndexManual.run({ data: { country: "EG" }, auth: caller("legacy") }), "permission-denied");
  assert.equal((await db.collection("MarketIndices").doc("EG").get()).exists, false);
});

test("TAQ-20: the country must be EG or AE", async () => {
  const adminCaller = caller("root", { role: "SuperAdmin" });
  for (const country of [undefined, "", "US", "eg ae", 7, "../Users"]) {
    await expectCode(fns.syncMarketIndexManual.run({ data: { country }, auth: adminCaller }), "invalid-argument");
  }
  assert.equal((await db.collection("MarketIndices").get()).size, 0);
});

test("TAQ-20: a SuperAdmin refresh writes the index, then a 10-minute cooldown applies", async () => {
  const adminCaller = caller("root", { role: "SuperAdmin" });
  const result = await fns.syncMarketIndexManual.run({ data: { country: "ae" }, auth: adminCaller });
  assert.deepEqual(result, { success: true, country: "AE" });
  const written = await db.collection("MarketIndices").doc("AE").get();
  assert.ok(written.get("updatedAt") instanceof admin.firestore.Timestamp);

  await expectCode(fns.syncMarketIndexManual.run({ data: { country: "AE" }, auth: adminCaller }), "resource-exhausted");
  await fns.syncMarketIndexManual.run({ data: { country: "EG" }, auth: adminCaller });

  const elevenMinutesAgo = admin.firestore.Timestamp.fromMillis(Date.now() - 11 * 60 * 1000);
  await db.collection("MarketIndices").doc("AE").update({ updatedAt: elevenMinutesAgo });
  await fns.syncMarketIndexManual.run({ data: { country: "AE" }, auth: adminCaller });
  const refreshed = await db.collection("MarketIndices").doc("AE").get();
  assert.ok(refreshed.get("updatedAt").toMillis() > elevenMinutesAgo.toMillis());
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

// --- TAQ-91: Admin and Investor roles ---

async function claimsOf(uid) {
  return (await admin.auth().getUser(uid)).customClaims || {};
}

test("TAQ-91: a SuperAdmin can grant Admin and Investor; the claim and profile carry the role and no agency", async () => {
  const root = caller("root", { role: "SuperAdmin" });
  await admin.auth().createUser({ uid: "staff" });
  await admin.auth().setCustomUserClaims("staff", { role: "AgencyAdmin", agency_id: "agency-1" });
  await fns.setUserRole.run({ data: { uid: "staff", role: "Admin" }, auth: root });
  assert.deepEqual(await claimsOf("staff"), { role: "Admin" });
  const profile = (await db.collection("Users").doc("staff").get()).data();
  assert.equal(profile.role, "Admin");
  assert.equal(profile.role_updated_by, "root");

  await admin.auth().createUser({ uid: "inv" });
  await fns.setUserRole.run({ data: { uid: "inv", role: "Investor" }, auth: root });
  assert.deepEqual(await claimsOf("inv"), { role: "Investor" });
});

test("TAQ-91: an Admin cannot assign or change any role, for itself or anyone else", async () => {
  const staff = caller("staff", { role: "Admin" });
  await admin.auth().createUser({ uid: "staff" });
  await admin.auth().setCustomUserClaims("staff", { role: "Admin" });
  await admin.auth().createUser({ uid: "victim" });
  await admin.auth().createUser({ uid: "root" });
  await admin.auth().setCustomUserClaims("root", { role: "SuperAdmin" });
  for (const data of [
    { uid: "staff", role: "SuperAdmin" },
    { uid: "staff", role: "Admin" },
    { uid: "staff", role: "Owner" },
    { uid: "victim", role: "SuperAdmin" },
    { uid: "victim", role: "Admin" },
    { uid: "victim", role: "Investor" },
    { uid: "victim", role: "AgencyAdmin", agencyId: "agency-1" },
    { uid: "root", role: "Owner" },
    { uid: "root", role: "Admin" },
  ]) {
    await expectCode(fns.setUserRole.run({ data, auth: staff }), "permission-denied");
  }
  assert.deepEqual(await claimsOf("staff"), { role: "Admin" });
  assert.deepEqual(await claimsOf("victim"), {});
  assert.deepEqual(await claimsOf("root"), { role: "SuperAdmin" });
});

test("TAQ-91: Investor, Tenant, Owner and a profile that says Admin cannot assign roles either", async () => {
  await admin.auth().createUser({ uid: "victim" });
  await db.collection("Users").doc("fake-admin").set({ role: "Admin" });
  for (const who of [caller("inv", { role: "Investor" }), caller("tenant"), caller("owner"), caller("fake-admin"), caller("nobody")]) {
    await expectCode(fns.setUserRole.run({ data: { uid: "victim", role: "Owner" }, auth: who }), "permission-denied");
  }
  await expectCode(fns.setUserRole.run({ data: { uid: "victim", role: "Owner" } }), "unauthenticated");
});

test("TAQ-91: an Investor profile is trusted as a self-service role, Admin and SuperAdmin profiles are not", async () => {
  const authz = require("../authz");
  await db.collection("Users").doc("inv-profile").set({ role: "Investor" });
  await db.collection("Users").doc("admin-profile").set({ role: "Admin" });
  await db.collection("Users").doc("root-profile").set({ role: "SuperAdmin" });
  assert.equal(await authz.resolveRole(caller("inv-profile")), "Investor");
  assert.equal(await authz.resolveRole(caller("admin-profile")), "");
  assert.equal(await authz.resolveRole(caller("root-profile")), "");
  assert.equal(await authz.resolveRole(caller("admin-profile", { role: "Admin" })), "Admin");
  assert.deepEqual(authz.SELF_SERVICE_ROLES, ["Owner", "Tenant", "Investor"]);
  assert.ok(!authz.PUBLISHER_ROLES.includes("Investor") && !authz.PUBLISHER_ROLES.includes("Admin"));
});

test("TAQ-91: only Admin and SuperAdmin can read the user directory, and it never carries IBAN or national ID", async () => {
  await db.collection("Users").doc("rich").set({
    user_id: "rich",
    role: "Owner",
    email: "rich@test.tashilaqar.com",
    full_name: "Rich Owner",
    iban: "AE070331234567890123456",
    national_id: "784-1990-1234567-1",
    nationalId: "784199012345671",
    phone: "+971500000001",
    bank_details: { iban: "AE07" },
    kyc_status: "approved",
    created_at: admin.firestore.Timestamp.fromDate(new Date("2026-01-01T00:00:00Z")),
  });
  for (const who of [caller("a", { role: "Admin" }), caller("r", { role: "SuperAdmin" })]) {
    const out = await fns.listUsersForAdmin.run({ data: { limit: 100 }, auth: who });
    const row = out.users.find((u) => u.uid === "rich");
    assert.deepEqual(row, {
      uid: "rich",
      user_id: "rich",
      email: "rich@test.tashilaqar.com",
      full_name: "Rich Owner",
      role: "Owner",
      created_at: "2026-01-01T00:00:00.000Z",
    });
    assert.doesNotMatch(JSON.stringify(out), /AE07|784|iban|national|phone|bank|kyc/i);
  }
  for (const who of [caller("inv", { role: "Investor" }), caller("o", { role: "Owner" }), caller("t", { role: "Tenant" }),
    caller("ag", { role: "AgencyAdmin", agency_id: "agency-1" }), caller("none"), caller("tenant"), caller("owner")]) {
    await expectCode(fns.listUsersForAdmin.run({ data: {}, auth: who }), "permission-denied");
  }
  await expectCode(fns.listUsersForAdmin.run({ data: {} }), "unauthenticated");
});

test("TAQ-91: the user directory is paged", async () => {
  for (let i = 0; i < 5; i += 1) await db.collection("Users").doc(`p${i}`).set({ role: "Owner", email: `p${i}@x.test` });
  const staff = caller("a", { role: "Admin" });
  const first = await fns.listUsersForAdmin.run({ data: { limit: 2 }, auth: staff });
  assert.equal(first.users.length, 2);
  assert.ok(first.nextPageToken);
  const second = await fns.listUsersForAdmin.run({ data: { limit: 2, startAfter: first.nextPageToken }, auth: staff });
  assert.equal(second.users.length, 2);
  assert.notEqual(second.users[0].uid, first.users[0].uid);
  const huge = await fns.listUsersForAdmin.run({ data: { limit: 100000 }, auth: staff });
  assert.ok(huge.users.length <= 100);
});

test("TAQ-91: Admin and Investor cannot touch payments or the market index refresh", async () => {
  for (const who of [caller("a", { role: "Admin" }), caller("inv", { role: "Investor" }), caller("nobody")]) {
    await expectCode(fns.processRentPayment.run({ data: { leaseId: "lease-1", amount: 100 }, auth: who }), "permission-denied");
    await expectCode(fns.syncMarketIndexManual.run({ data: { country: "EG" }, auth: who }), "permission-denied");
    await expectCode(fns.sendRentalReminder.run({ data: { leaseId: "lease-1" }, auth: who }), "permission-denied");
    await expectCode(fns.generateRentalInvoiceReceipt.run({ data: { leaseId: "lease-1" }, auth: who }), "permission-denied");
  }
});

