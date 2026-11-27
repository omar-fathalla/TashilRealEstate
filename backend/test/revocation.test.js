// TAQ-158: sensitive callables refuse ID tokens issued before revokeRefreshTokens.
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");
const { requireFreshAuth } = require("../authz");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${authHost}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

/** Signs a new email user up on the Auth emulator and returns { uid, idToken }. */
async function signUp(email) {
  const res = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password: "not-a-real-password-1", returnSecureToken: true }),
  });
  const body = await res.json();
  assert.ok(body.idToken, `signUp failed: ${JSON.stringify(body)}`);
  return { uid: body.localId, idToken: body.idToken };
}

async function signIn(email) {
  const res = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password: "not-a-real-password-1", returnSecureToken: true }),
  });
  return (await res.json()).idToken;
}

/** The callable request the runtime would build for this ID token. */
async function callRequest(idToken, data = {}) {
  const decoded = await admin.auth().verifyIdToken(idToken);
  return {
    data,
    auth: { uid: decoded.uid, token: decoded },
    rawRequest: { headers: { authorization: `Bearer ${idToken}` } },
  };
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function expectRevoked(promise) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, "unauthenticated", `got ${err.code}: ${err.message}`);
    assert.equal(err.details && err.details.reason, "token_revoked");
    return true;
  });
}

test.beforeEach(clearAll);

test("TAQ-158: a current ID token passes the revocation check", async () => {
  const { uid, idToken } = await signUp("fresh@taq158.test");
  const auth = await requireFreshAuth(await callRequest(idToken));
  assert.equal(auth.uid, uid);
});

test("TAQ-158: an ID token issued before revokeRefreshTokens is refused", async () => {
  const { uid, idToken } = await signUp("revoked@taq158.test");
  const request = await callRequest(idToken);
  await sleep(1100); // validSince has 1 s resolution
  await admin.auth().revokeRefreshTokens(uid);
  await expectRevoked(requireFreshAuth(request));
  // Signing in again gives a token that works.
  await sleep(1100);
  const again = await signIn("revoked@taq158.test");
  assert.equal((await requireFreshAuth(await callRequest(again))).uid, uid);
});

test("TAQ-158: a disabled or deleted account's token is refused", async () => {
  const a = await signUp("disabled@taq158.test");
  const b = await signUp("deleted@taq158.test");
  const ra = await callRequest(a.idToken);
  const rb = await callRequest(b.idToken);
  await admin.auth().updateUser(a.uid, { disabled: true });
  await admin.auth().deleteUser(b.uid);
  await expectRevoked(requireFreshAuth(ra));
  await expectRevoked(requireFreshAuth(rb));
});

test("TAQ-158: a bearer token that is garbage, missing, or for another user is refused", async () => {
  const a = await signUp("a@taq158.test");
  const b = await signUp("b@taq158.test");
  const ra = await callRequest(a.idToken);
  await expectRevoked(requireFreshAuth({ ...ra, rawRequest: { headers: { authorization: "Bearer not-a-token" } } }));
  await expectRevoked(requireFreshAuth({ ...ra, rawRequest: { headers: {} } }));
  await expectRevoked(requireFreshAuth({ ...ra, rawRequest: { headers: { authorization: `Bearer ${b.idToken}` } } }));
});

test("TAQ-158: without a raw request, auth_time before tokensValidAfterTime is refused", async () => {
  const { uid, idToken } = await signUp("inproc@taq158.test");
  const { auth } = await callRequest(idToken);
  assert.equal((await requireFreshAuth({ auth })).uid, uid);
  await sleep(1100);
  await admin.auth().revokeRefreshTokens(uid);
  await expectRevoked(requireFreshAuth({ auth }));
});

test("TAQ-158: a demoted AgencyAdmin's pre-demotion token no longer works on callables", async () => {
  await db.collection("Agencies").doc("agency-1").set({ name: "Agency One" });
  const admin1 = await signUp("agency-admin@taq158.test");
  const root = { uid: "root", token: { uid: "root", role: "SuperAdmin" } };
  await fns.setUserRole.run({ data: { uid: admin1.uid, role: "AgencyAdmin", agencyId: "agency-1" }, auth: root });
  await sleep(1100);
  const agencyToken = await signIn("agency-admin@taq158.test");
  const request = await callRequest(agencyToken, { leaseId: "missing-lease" });
  assert.equal(request.auth.token.role, "AgencyAdmin");
  assert.equal(request.auth.token.agency_id, "agency-1");

  // Before the demotion the token reaches the callable's own checks (here: lease not found).
  await assert.rejects(fns.sendRentalReminder.run(request), (err) => err.code !== "unauthenticated");

  await sleep(1100);
  await fns.setUserRole.run({ data: { uid: admin1.uid, role: "Owner" }, auth: root });
  for (const fn of [fns.sendRentalReminder, fns.generateRentalInvoiceReceipt, fns.createLease, fns.recordManualPayment, fns.listUsersForAdmin]) {
    await expectRevoked(fn.run(request));
  }
});
