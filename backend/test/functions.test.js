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
