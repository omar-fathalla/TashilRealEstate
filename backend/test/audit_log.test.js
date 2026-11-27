// TAQ-193: server-written AuditLog with one-year retention.
const test = require("node:test");
const assert = require("node:assert/strict");
const { getAuth } = require("firebase-admin/auth");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");
const audit = require("../audit_log");
const { Timestamp, getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();
const projectId = process.env.GCLOUD_PROJECT;
const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });

test.beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
});

async function entries(action) {
  const snap = await db.collection("AuditLog").where("action", "==", action).get();
  return snap.docs.map((d) => d.data());
}

test("TAQ-193: a role change through setUserRole is audited with actor, target, roles and a one-year expiry", async () => {
  await getAuth().createUser({ uid: "target" });
  const before = Date.now();
  await fns.setUserRole.run({ data: { uid: "target", role: "Admin" }, auth: caller("root", { role: "SuperAdmin" }) });
  const [entry] = await entries("role_assigned");
  assert.equal(entry.actor_uid, "root");
  assert.equal(entry.target_uid, "target");
  assert.equal(entry.details.from_role, "");
  assert.equal(entry.details.to_role, "Admin");
  assert.equal(entry.details.changed, true);
  const days = (entry.expire_at.toMillis() - before) / 86400000;
  assert.ok(days > 364.9 && days < 365.1, `expire_at is ~365 days out, got ${days}`);
  assert.ok(entry.created_at instanceof Timestamp);
});

test("TAQ-193: agency application decisions are audited", async () => {
  await db.collection("AgencyApplications").doc("app1").set({ status: "pending", name: "A", country_code: "AE" });
  await fns.reviewAgencyApplication.run({ data: { uid: "app1", approve: false }, auth: caller("root", { role: "SuperAdmin" }) });
  const [entry] = await entries("agency_application_rejected");
  assert.equal(entry.actor_uid, "root");
  assert.equal(entry.target_uid, "app1");
});

test("TAQ-193: a Settings write is audited with the split values and the writer", async () => {
  const snap = (data) => ({ exists: !!data, data: () => data });
  await fns.auditSettingsChange.run({
    params: { settingId: "payment_split" },
    authType: "app_user",
    authId: "root",
    data: { before: snap({ platform_percent: 5, agency_percent: 10 }), after: snap({ platform_percent: 7, agency_percent: 10, updated_by: "root" }) },
  });
  const [entry] = await entries("settings_updated");
  assert.equal(entry.actor_uid, "root");
  assert.equal(entry.target_path, "Settings/payment_split");
  assert.deepEqual(entry.details, { before: { platform_percent: 5, agency_percent: 10 }, after: { platform_percent: 7, agency_percent: 10 } });
});

test("TAQ-193: details keep only plain values and short strings", () => {
  const e = audit.auditEntry({ action: "x", details: { a: "y".repeat(300), b: [1, 2], c: { d: 1, e: () => 1 }, f: undefined } });
  assert.equal(e.details.a.length, 200);
  assert.equal("b" in e.details, false);
  assert.deepEqual(e.details.c, { d: 1 });
  assert.equal("f" in e.details, false);
});

test("TAQ-193: purgeExpired deletes only entries past expire_at", async () => {
  const now = Date.now();
  await db.collection("AuditLog").doc("old").set({ action: "x", expire_at: Timestamp.fromMillis(now - 1000) });
  await db.collection("AuditLog").doc("new").set({ action: "x", expire_at: Timestamp.fromMillis(now + 86400000) });
  assert.equal(await audit.purgeExpired(db, now), 1);
  assert.equal((await db.doc("AuditLog/old").get()).exists, false);
  assert.equal((await db.doc("AuditLog/new").get()).exists, true);
});

test("TAQ-193: the purge is a scheduled job, not an HTTP endpoint", () => {
  assert.ok(fns.purgeExpiredAuditLog.__endpoint.scheduleTrigger, "expected a schedule trigger");
  assert.equal(fns.purgeExpiredAuditLog.__endpoint.scheduleTrigger.schedule, "30 3 * * *");
});
