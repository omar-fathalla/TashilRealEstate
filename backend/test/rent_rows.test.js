// TAQ-163: Rent Collection row actions are kept on the server, per lease month.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, getDocs, collection, query, where } = require("firebase/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");
const { cleanNote } = require("../rent_rows");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });
const run = (data, auth) => fns.updateRentRow.run({ data, auth });
const row = async (id) => (await db.doc(`RentRowStates/${id}`).get()).data();

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

async function user(uid, claims) {
  await admin.auth().createUser({ uid });
  if (claims) await admin.auth().setCustomUserClaims(uid, claims);
}

async function code(promise, expected) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, expected, `expected ${expected}, got ${err.code}: ${err.message}`);
    return true;
  });
}

let rulesEnv;
test.before(async () => {
  rulesEnv = await initializeTestEnvironment({
    projectId: `${projectId}-rentrows`,
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});
test.after(async () => {
  if (rulesEnv) await rulesEnv.cleanup();
});

test.beforeEach(async () => {
  await clearAll();
  await user("ownerR", { role: "Owner" });
  await user("agR", { role: "AgencyAdmin", agency_id: "agR" });
  await user("otherAg", { role: "AgencyAdmin", agency_id: "agX" });
  await user("tenantR", { role: "Tenant" });
  await user("ownerZ", { role: "Owner" });
  await user("root", { role: "SuperAdmin" });
  const base = { status: "active", tenant_id: "tenantR", property_id: "p", monthly_rent: 5000, start_date: "2026-01-01", end_date: "2099-12-31" };
  await db.doc("Leases/own1").set({ ...base, owner_id: "ownerR", agency_id: "" });
  await db.doc("Leases/agy1").set({ ...base, owner_id: "ownerZ", agency_id: "agR" });
});

const owner = () => caller("ownerR", { role: "Owner" });
const agency = () => caller("agR", { role: "AgencyAdmin", agency_id: "agR" });

test("TAQ-163: trash, restore and delete are stored per lease month for the owner", async () => {
  await run({ leaseId: "own1", period: "2026-03", action: "trash" }, owner());
  let r = await row("own1_2026-03");
  assert.equal(r.hidden, true);
  assert.equal(r.deleted, false);
  assert.equal(r.owner_id, "ownerR");
  assert.equal(r.agency_id, "");
  assert.equal(r.lease_id, "own1");
  assert.equal(r.period, "2026-03");
  await run({ leaseId: "own1", period: "2026-03", action: "restore" }, owner());
  r = await row("own1_2026-03");
  assert.equal(r.hidden, false);
  await run({ leaseId: "own1", period: "2026-03", action: "delete" }, owner());
  r = await row("own1_2026-03");
  assert.equal(r.deleted, true);
  assert.equal(r.hidden, true);
  assert.equal((await db.doc("Leases/own1").get()).get("monthly_rent"), 5000, "the lease is untouched");
});

test("TAQ-163: notes are contact-free and capped; reminders count up; a legal notice is dated", async () => {
  await run({ leaseId: "agy1", period: "2026-04", action: "note", notes: "Call me on 0501234567 about the cheque" }, agency());
  assert.equal((await row("agy1_2026-04")).notes.includes("0501234567"), false);
  assert.equal(cleanNote("x".repeat(900)).length, 500);
  await run({ leaseId: "agy1", period: "2026-04", action: "reminder" }, agency());
  await run({ leaseId: "agy1", period: "2026-04", action: "reminder" }, caller("root", { role: "SuperAdmin" }));
  await run({ leaseId: "agy1", period: "2026-04", action: "legal_notice" }, agency());
  const r = await row("agy1_2026-04");
  assert.equal(r.reminder_count, 3);
  assert.ok(r.legal_notice_at);
  assert.ok(r.last_reminder_at);
  assert.ok(r.notes.includes("cheque"), "an earlier note survives later actions");
});

test("TAQ-163: only the lease's owner, managing agency or SuperAdmin may act", async () => {
  await code(run({ leaseId: "own1", period: "2026-03", action: "trash" }, caller("ownerZ", { role: "Owner" })), "permission-denied");
  await code(run({ leaseId: "agy1", period: "2026-03", action: "trash" }, caller("otherAg", { role: "AgencyAdmin", agency_id: "agX" })), "permission-denied");
  await code(run({ leaseId: "own1", period: "2026-03", action: "trash" }, caller("tenantR", { role: "Tenant" })), "permission-denied");
  await code(run({ leaseId: "own1", period: "2026-03", action: "trash" }, undefined), "unauthenticated");
  assert.equal((await db.collection("RentRowStates").get()).size, 0);
});

test("TAQ-163: bad periods, actions and lease ids are refused", async () => {
  for (const data of [
    { leaseId: "own1", period: "2026-13", action: "trash" },
    { leaseId: "own1", period: "2026-3", action: "trash" },
    { leaseId: "own1", period: "2026-03", action: "pay" },
    { leaseId: "own1", period: "2026-03" },
    { leaseId: "a/b", period: "2026-03", action: "trash" },
    { leaseId: "own1", period: "2026-03", action: "note", notes: 5 },
  ]) {
    await code(run(data, owner()), "invalid-argument");
  }
  await code(run({ leaseId: "nope", period: "2026-03", action: "trash" }, owner()), "not-found");
});

test("TAQ-163: the rules let the parties read the row state and nobody write it", async () => {
  await rulesEnv.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), "RentRowStates/own1_2026-03"), { owner_id: "ownerR", agency_id: "", hidden: true });
    await setDoc(doc(c.firestore(), "RentRowStates/agy1_2026-03"), { owner_id: "ownerZ", agency_id: "agR", hidden: true });
  });
  const as = (uid, claims) => rulesEnv.authenticatedContext(uid, claims).firestore();
  await assertSucceeds(getDoc(doc(as("ownerR"), "RentRowStates/own1_2026-03")));
  await assertSucceeds(getDocs(query(collection(as("ownerR"), "RentRowStates"), where("owner_id", "==", "ownerR"))));
  await assertSucceeds(getDocs(query(collection(as("agR", { role: "AgencyAdmin", agency_id: "agR" }), "RentRowStates"), where("agency_id", "==", "agR"))));
  await assertSucceeds(getDocs(collection(as("root", { role: "SuperAdmin" }), "RentRowStates")));
  await assertFails(getDoc(doc(as("ownerZ"), "RentRowStates/own1_2026-03")));
  await assertFails(getDoc(doc(as("agX", { role: "AgencyAdmin", agency_id: "agX" }), "RentRowStates/agy1_2026-03")));
  await assertFails(getDoc(doc(as("tenantR", { role: "Tenant" }), "RentRowStates/own1_2026-03")));
  await assertFails(setDoc(doc(as("ownerR"), "RentRowStates/own1_2026-04"), { owner_id: "ownerR", hidden: true }));
  await assertFails(setDoc(doc(as("root", { role: "SuperAdmin" }), "RentRowStates/own1_2026-04"), { owner_id: "ownerR" }));
});
