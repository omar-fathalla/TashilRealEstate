// TAQ-169 (B): agency team invites.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const { initializeTestEnvironment, assertFails } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc } = require("firebase/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the emulators are attached.");
}

const fns = require("../index");
const team = require("../agency_team");
const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT || "demo-tashil-test";
let testEnv;

const ADMIN = { uid: "adm1", token: { uid: "adm1", role: "AgencyAdmin", agency_id: "ag1", email: "boss@agency.test", email_verified: true } };
const SUPER = { uid: "root", token: { uid: "root", role: "SuperAdmin" } };
const invitee = (uid = "u1", extra = {}) => ({ uid, token: { uid, email: "Agent@Example.test", email_verified: true, ...extra } });

async function rejects(promise, code, reason) {
  await assert.rejects(promise, (e) => {
    assert.equal(e.code, code, e.message);
    if (reason) assert.equal(e.details && e.details.reason, reason);
    return true;
  });
}

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
  team.deps.now = () => Date.now();
  await testEnv.clearFirestore();
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
  await db.doc("Agencies/ag1").set({ name: "Agency One" });
  await db.doc("Agencies/ag2").set({ name: "Agency Two" });
  await admin.auth().createUser({ uid: "u1", email: "agent@example.test", emailVerified: true });
  await admin.auth().setCustomUserClaims("u1", { role: "Tenant" });
  await db.doc("Users/u1").set({ role: "Tenant" });
});

async function invite(email = "agent@example.test") {
  return (await fns.inviteAgencyAgent.run({ data: { email }, auth: ADMIN })).inviteId;
}

test("TAQ-169: invite, accept, list and remove an agent", async () => {
  const id = await invite(" Agent@Example.test ");
  const stored = (await db.doc(`AgencyInvites/${id}`).get()).data();
  assert.equal(stored.email, "agent@example.test");
  assert.equal(stored.agency_id, "ag1");
  assert.ok(stored.expires_at.toMillis() - Date.now() > 6.9 * 24 * 3600e3);

  const mine = await fns.listMyAgencyInvites.run({ data: {}, auth: invitee() });
  assert.deepEqual(mine.invites.map((i) => [i.id, i.agencyName]), [[id, "Agency One"]]);

  const res = await fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee() });
  assert.equal(res.agencyId, "ag1");
  const claims = (await admin.auth().getUser("u1")).customClaims;
  assert.equal(claims.role, "AgencyAgent");
  assert.equal(claims.agency_id, "ag1");
  assert.equal((await db.doc(`AgencyInvites/${id}`).get()).get("status"), "accepted");
  assert.equal((await db.doc("AgencyAgents/u1").get()).get("previous_role"), "Tenant");

  const listed = await fns.listAgencyTeam.run({ data: {}, auth: ADMIN });
  assert.deepEqual(listed.agents.map((a) => a.uid), ["u1"]);
  assert.equal(listed.invites.length, 0);

  // A second accept of the same invite fails.
  await rejects(fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee() }), "failed-precondition", "invite_not_open");

  await fns.removeAgencyAgent.run({ data: { uid: "u1" }, auth: ADMIN });
  const after = (await admin.auth().getUser("u1")).customClaims;
  assert.equal(after.role, "Tenant");
  assert.equal(after.agency_id, undefined);
  assert.equal((await db.doc("AgencyAgents/u1").get()).exists, false);
  const actions = (await db.collection("AuditLog").get()).docs.map((d) => d.get("action"));
  for (const a of ["agency_agent_invited", "agency_agent_joined", "agency_agent_removed"]) assert.ok(actions.includes(a), a);
});

test("TAQ-169: only an AgencyAdmin invites; bad emails and duplicates are refused", async () => {
  for (const auth of [invitee(), SUPER, { uid: "ag", token: { uid: "ag", role: "AgencyAgent", agency_id: "ag1" } }]) {
    await rejects(fns.inviteAgencyAgent.run({ data: { email: "x@y.test" }, auth }), "permission-denied");
  }
  await rejects(fns.inviteAgencyAgent.run({ data: { email: "nope" }, auth: ADMIN }), "invalid-argument", "email_invalid");
  await rejects(fns.inviteAgencyAgent.run({ data: { email: "boss@agency.test" }, auth: ADMIN }), "invalid-argument", "self_invite");
  await invite();
  await rejects(fns.inviteAgencyAgent.run({ data: { email: "agent@example.test" }, auth: ADMIN }), "already-exists", "invite_exists");
});

test("TAQ-169: at most 20 open invites per agency", async () => {
  for (let i = 0; i < team.MAX_OPEN_INVITES; i++) await invite(`a${i}@example.test`);
  await rejects(invite("one-more@example.test"), "resource-exhausted", "too_many_invites");
});

test("TAQ-169: the invite must match a verified email and be open", async () => {
  const id = await invite();
  await rejects(fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee("u1", { email_verified: false }) }), "failed-precondition", "email_not_verified");
  await rejects(fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee("u2", { email: "other@example.test" }) }), "not-found");
  team.deps.now = () => Date.now() + 8 * 24 * 3600e3;
  await rejects(fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee() }), "failed-precondition", "invite_not_open");
  team.deps.now = () => Date.now();
  await fns.revokeAgencyInvite.run({ data: { inviteId: id }, auth: ADMIN });
  await rejects(fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee() }), "failed-precondition", "invite_not_open");
});

test("TAQ-169: staff roles and users with open leases cannot accept", async () => {
  const id = await invite();
  await rejects(fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee("u1", { role: "AgencyAdmin", agency_id: "ag2" }) }), "failed-precondition", "role_not_self_service");
  await db.doc("Leases/L1").set({ tenant_id: "u1", owner_id: "o1", status: "active" });
  await rejects(fns.acceptAgencyInvite.run({ data: { inviteId: id }, auth: invitee("u1", { role: "Tenant" }) }), "failed-precondition", "applicant_has_open_leases");
  assert.equal((await db.doc(`AgencyInvites/${id}`).get()).get("status"), "pending");
});

test("TAQ-169: declining closes the invite; another agency cannot revoke or remove", async () => {
  const id = await invite();
  const other = { uid: "adm2", token: { uid: "adm2", role: "AgencyAdmin", agency_id: "ag2" } };
  await rejects(fns.revokeAgencyInvite.run({ data: { inviteId: id }, auth: other }), "not-found");
  await fns.declineAgencyInvite.run({ data: { inviteId: id }, auth: invitee() });
  assert.equal((await db.doc(`AgencyInvites/${id}`).get()).get("status"), "declined");

  const id2 = await invite();
  await fns.acceptAgencyInvite.run({ data: { inviteId: id2 }, auth: invitee("u1", { role: "Tenant" }) });
  await rejects(fns.removeAgencyAgent.run({ data: { uid: "u1" }, auth: other }), "not-found");
  await fns.removeAgencyAgent.run({ data: { uid: "u1", agencyId: "ag1" }, auth: SUPER });
  assert.equal((await admin.auth().getUser("u1")).customClaims.role, "Tenant");
});

test("TAQ-169: setUserRole still cannot grant AgencyAgent", async () => {
  await rejects(fns.setUserRole.run({ data: { uid: "u1", role: "AgencyAgent", agencyId: "ag1" }, auth: SUPER }), "invalid-argument");
});

test("TAQ-169 rules: AgencyInvites and AgencyAgents are server-only", async () => {
  await db.doc("AgencyInvites/i1").set({ agency_id: "ag1", email: "agent@example.test", status: "pending" });
  await db.doc("AgencyAgents/u1").set({ agency_id: "ag1" });
  const ctxs = [
    testEnv.authenticatedContext("adm1", { role: "AgencyAdmin", agency_id: "ag1" }),
    testEnv.authenticatedContext("u1", { email: "agent@example.test", email_verified: true }),
    testEnv.authenticatedContext("root", { role: "SuperAdmin" }),
  ];
  for (const ctx of ctxs) {
    const fsdb = ctx.firestore();
    await assertFails(getDoc(doc(fsdb, "AgencyInvites/i1")));
    await assertFails(getDoc(doc(fsdb, "AgencyAgents/u1")));
    await assertFails(setDoc(doc(fsdb, "AgencyInvites/i2"), { agency_id: "ag1" }));
    await assertFails(setDoc(doc(fsdb, "AgencyAgents/x"), { agency_id: "ag1" }));
  }
});
