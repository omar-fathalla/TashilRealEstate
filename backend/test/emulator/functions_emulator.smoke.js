// Runs inside `firebase emulators:exec --only functions,firestore,auth` (npm run test:emulator).
// Exercises the deployed code paths through the real Functions emulator runtime, which wraps
// firebase-admin differently from a plain `require("../index")`.
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";

if (!projectId || !projectId.startsWith("demo-") || !firestoreHost || !authHost) {
  throw new Error("Run through `npm run test:emulator` against a demo- project.");
}

admin.initializeApp({ projectId });
const db = admin.firestore();

async function clearEmulators() {
  await Promise.all([
    fetch(`http://${firestoreHost}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" }),
    fetch(`http://${authHost}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" }),
  ]);
}

async function signUp(email, claims) {
  const user = await admin.auth().createUser({ email, password: "emulator-only-pass" });
  if (claims) await admin.auth().setCustomUserClaims(user.uid, claims);
  const res = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, password: "emulator-only-pass", returnSecureToken: true }),
    },
  );
  const body = await res.json();
  assert.ok(body.idToken, JSON.stringify(body));
  return { uid: user.uid, idToken: body.idToken };
}

async function callable(name, idToken, data) {
  const res = await fetch(`http://${functionsHost}/${projectId}/us-central1/${name}`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data }),
  });
  return { status: res.status, body: await res.json() };
}

async function waitFor(check, timeoutMs = 20000) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const value = await check();
    if (value) return value;
    if (Date.now() > deadline) return null;
    await new Promise((r) => setTimeout(r, 250));
  }
}

test.beforeEach(clearEmulators);

// --- TAQ-44: the Functions emulator runs the trigger and callables without crashing ---

test("TAQ-44: the sync trigger publishes an owner listing in the Functions emulator", async () => {
  await db.doc("Users/smoke-owner").set({ role: "Owner" });
  await db.doc("Users/smoke-owner/properties/smoke-1").set({
    isPublished: true,
    rentalStatus: "available",
    countryCode: "AE",
    titles: { en: "Smoke listing" },
    pricePerMonth: 7000,
    tenantName: "Private",
  });
  const pub = await waitFor(async () => {
    const snap = await db.doc("Properties/smoke-1").get();
    return snap.exists ? snap.data() : null;
  });
  assert.ok(pub, "the trigger did not write /Properties/smoke-1");
  assert.equal(pub.owner_id, "smoke-owner");
  assert.equal(pub.is_published, true);
  assert.equal(pub.tenantName, undefined);
  assert.ok(pub.updated_at, "server timestamp missing");
});

test("TAQ-44: reminder, invoice, and setUserRole callables run in the Functions emulator", async () => {
  const owner = await signUp("smoke-owner@example.com");
  await db.doc(`Users/${owner.uid}`).set({ role: "Owner" });
  await db.doc("Leases/smoke-lease").set({
    owner_id: owner.uid,
    tenant_id: "smoke-tenant",
    country_code: "EG",
    financialTerms: { monthlyRent: 12000 },
  });

  const reminder = await callable("sendRentalReminder", owner.idToken, { leaseId: "smoke-lease" });
  assert.equal(reminder.status, 200, JSON.stringify(reminder.body));
  assert.equal(reminder.body.result.success, true);

  const invoice = await callable("generateRentalInvoiceReceipt", owner.idToken, { leaseId: "smoke-lease" });
  assert.equal(invoice.status, 200, JSON.stringify(invoice.body));
  assert.equal(invoice.body.result.invoice.currencyCode, "EGP");

  const root = await signUp("smoke-root@example.com", { role: "SuperAdmin" });
  const target = await admin.auth().createUser({ email: "smoke-target@example.com" });
  const role = await callable("setUserRole", root.idToken, { uid: target.uid, role: "Tenant" });
  assert.equal(role.status, 200, JSON.stringify(role.body));
  assert.deepEqual((await admin.auth().getUser(target.uid)).customClaims, { role: "Tenant" });
});

// --- TAQ-20: the market index callable runs in the Functions emulator ---

test("TAQ-20: syncMarketIndexManual is SuperAdmin-only and writes a server timestamp", async () => {
  const owner = await signUp("smoke-owner@example.com");
  await db.doc(`Users/${owner.uid}`).set({ role: "Owner" });
  const denied = await callable("syncMarketIndexManual", owner.idToken, { country: "EG" });
  assert.equal(denied.status, 403, JSON.stringify(denied.body));

  const root = await signUp("smoke-root@example.com", { role: "SuperAdmin" });
  const ok = await callable("syncMarketIndexManual", root.idToken, { country: "EG" });
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  const index = await db.doc("MarketIndices/EG").get();
  assert.ok(index.get("updatedAt"), "server timestamp missing");

  const again = await callable("syncMarketIndexManual", root.idToken, { country: "EG" });
  assert.equal(again.status, 429, JSON.stringify(again.body));

  const res = await fetch(`http://${functionsHost}/${projectId}/us-central1/syncMarketIndexManual?country=EG`);
  assert.notEqual(res.status, 200);
});

// --- TAQ-91: processRentPayment and moderation in the Functions emulator ---

test("TAQ-91: processRentPayment runs in the Functions emulator, with clean error statuses", async () => {
  const tenant = await signUp("smoke-tenant@example.com");
  await db.doc(`Users/${tenant.uid}`).set({ role: "Tenant" });
  await db.doc("Leases/pay-lease").set({
    owner_id: "smoke-owner-x",
    tenant_id: tenant.uid,
    country_code: "AE",
    financialTerms: { monthlyRent: 5000 },
  });

  const ok = await callable("processRentPayment", tenant.idToken, { leaseId: "pay-lease", amount: 5000 });
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.equal(ok.body.result.success, true);
  const tx = (await db.doc(`Transactions/${ok.body.result.transactionId}`).get()).data();
  assert.equal(tx.amount, 5000);
  assert.ok(tx.createdAt, "server timestamp missing");

  const wrongAmount = await callable("processRentPayment", tenant.idToken, { leaseId: "pay-lease", amount: -999999 });
  assert.equal(wrongAmount.status, 400, JSON.stringify(wrongAmount.body));
  const text = await callable("processRentPayment", tenant.idToken, { leaseId: "pay-lease", amount: "abc" });
  assert.equal(text.status, 400, JSON.stringify(text.body));
  const missing = await callable("processRentPayment", tenant.idToken, { leaseId: "nope", amount: 5000 });
  assert.equal(missing.status, 404, JSON.stringify(missing.body));

  const other = await signUp("smoke-other@example.com");
  await db.doc(`Users/${other.uid}`).set({ role: "Tenant" });
  const denied = await callable("processRentPayment", other.idToken, { leaseId: "pay-lease", amount: 5000 });
  assert.equal(denied.status, 403, JSON.stringify(denied.body));

  const res = await fetch(`http://${functionsHost}/${projectId}/us-central1/processRentPayment`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ data: { leaseId: "pay-lease", amount: 5000 } }),
  });
  assert.equal(res.status, 401, "signed out is UNAUTHENTICATED (401), not INTERNAL (500)");
});

test("TAQ-91: the moderation trigger keeps a hidden listing hidden when its owner edits it", async () => {
  await db.doc("Users/mod-owner").set({ role: "Owner" });
  const priv = db.doc("Users/mod-owner/properties/mod-smoke");
  await priv.set({ isPublished: true, rentalStatus: "available", countryCode: "AE", titles: { en: "Mod smoke" }, pricePerMonth: 7000 });
  const live = await waitFor(async () => {
    const snap = await db.doc("Properties/mod-smoke").get();
    return snap.exists && snap.get("is_published") === true ? snap.data() : null;
  });
  assert.ok(live, "listing was not published");

  await db.doc("PropertyModeration/mod-smoke").set({ hidden: true, pre_hide_published: true, updated_by: "admin1" });
  const hidden = await waitFor(async () => {
    const snap = await db.doc("Properties/mod-smoke").get();
    return snap.get("is_published") === false && snap.get("moderation_hidden") === true ? snap.data() : null;
  });
  assert.ok(hidden, "the moderation write did not take the public doc offline");

  await db.doc("Properties/mod-smoke").delete();
  await priv.set({ titles: { en: "Edited after the public doc was deleted" } }, { merge: true });
  const back = await waitFor(async () => {
    const snap = await db.doc("Properties/mod-smoke").get();
    return snap.exists ? snap.data() : null;
  });
  assert.ok(back, "the sync did not recreate the public doc");
  assert.equal(back.is_published, false);
  assert.equal(back.moderation_hidden, true);
});
