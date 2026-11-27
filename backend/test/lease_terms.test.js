// TAQ-164: optional lease terms. Tenant phone from the tenant's profile, owner payout bank,
// and a flat late fee (default 0) that payments add once the grace days are over.
const test = require("node:test");
const assert = require("node:assert/strict");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const ENV = {
  PAYMENTS_ENABLED: "true",
  PAYMOB_SECRET_KEY: "fake-secret-key",
  PAYMOB_PUBLIC_KEY: "fake-public-key",
  PAYMOB_HMAC_SECRET: "fake-hmac-secret",
  PAYMOB_INTEGRATION_ID: "12345",
  PAYMOB_NOTIFICATION_URL: "https://example.test/paymobWebhook",
};
const savedEnv = Object.fromEntries(Object.keys(ENV).map((k) => [k, process.env[k]]));

const fns = require("../index");
const leases = require("../leases");
const payments = require("../payments");
const terms = require("../lease_terms");

const db = getFirestore();
const projectId = process.env.GCLOUD_PROJECT;
const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });
const realFetch = payments.deps.fetch;
const realPayNow = payments.deps.now;
let sent = [];

test.after(() => {
  for (const [k, v] of Object.entries(savedEnv)) {
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
  payments.deps.fetch = realFetch;
  payments.deps.now = realPayNow;
  leases.deps.now = () => Date.now();
});

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

test.beforeEach(async () => {
  Object.assign(process.env, ENV);
  leases.deps.now = () => Date.now();
  payments.deps.now = () => Date.now();
  sent = [];
  let order = 9000;
  payments.deps.fetch = async (_url, init) => {
    order += 1;
    sent.push(JSON.parse(init.body));
    return { ok: true, status: 201, json: async () => ({ id: `int_${order}`, intention_order_id: order, client_secret: `cs_${order}` }) };
  };
  await clearAll();
  await getAuth().createUser({ uid: "ownerT" });
  await getAuth().setCustomUserClaims("ownerT", { role: "Owner" });
  await getAuth().createUser({ uid: "tenantT" });
  await getAuth().setCustomUserClaims("tenantT", { role: "Tenant" });
  await db.doc("Users/tenantT").set({ role: "Tenant", full_name: "Tenant T", phone: "+971 50 123 4567" });
  await db.doc("Users/ownerT/properties/propT").set({ title: "Flat T", countryCode: "AE" });
  await db.doc("PropertyOwners/propT").set({ owner_id: "ownerT" });
});

const owner = () => caller("ownerT", { role: "Owner" });
const input = (extra = {}) => ({ propertyId: "propT", tenantId: "tenantT", startDate: "2026-01-10", endDate: "2099-12-31", monthlyRent: 5000, sendOffer: true, ...extra });
const create = (data) => fns.createLease.run({ data, auth: owner() });
const leaseDoc = async (id) => (await db.doc(`Leases/${id}`).get()).data();

async function reason(promise, code, expected) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    if (expected) assert.equal(err.details && err.details.reason, expected);
    return true;
  });
}

// --- pure helpers ---

test("TAQ-164: leaseExtrasFrom cleans the optional terms and refuses bad ones", () => {
  assert.deepEqual(terms.leaseExtrasFrom({}), {});
  assert.deepEqual(
    terms.leaseExtrasFrom({ lateFeeAmount: 250.5, lateFeeGraceDays: 3, payoutBankName: "  Emirates  NBD ", payoutIban: "ae07 0331 2345 6789 0123 456" }),
    { late_fee_amount: 250.5, late_fee_grace_days: 3, payout_bank_name: "Emirates NBD", payout_iban: "AE070331234567890123456" },
  );
  assert.deepEqual(terms.leaseExtrasFrom({ lateFeeAmount: 0 }), { late_fee_amount: 0 });
  for (const bad of [{ lateFeeAmount: -1 }, { lateFeeAmount: "100" }, { lateFeeAmount: 1.234 }, { lateFeeAmount: Infinity }, { lateFeeGraceDays: 61 }, { lateFeeGraceDays: 1.5 }, { payoutIban: "12345" }, { payoutIban: "AE07" }, { payoutBankName: 5 }]) {
    assert.throws(() => terms.leaseExtrasFrom(bad), (err) => err.code === "invalid-argument", JSON.stringify(bad));
  }
  assert.equal(terms.leaseExtrasFrom({ payoutBankName: "call 0501234567" }).payout_bank_name.includes("0501234567"), false);
});

test("TAQ-164: the late fee applies only after the due day plus the grace days, and never at 0", () => {
  const lease = { start_date: "2026-01-31", late_fee_amount: 300, late_fee_grace_days: 5 };
  // February has 28 days: due 2026-02-28, grace to 2026-03-05, fee from 2026-03-06.
  assert.equal(terms.dueDateOf(lease, "2026-02").toISOString().slice(0, 10), "2026-02-28");
  assert.equal(terms.lateFeeFor(lease, "2026-02", Date.UTC(2026, 2, 5, 23, 59)), 0);
  assert.equal(terms.lateFeeFor(lease, "2026-02", Date.UTC(2026, 2, 6)), 300);
  assert.equal(terms.lateFeeFor({ ...lease, late_fee_amount: 0 }, "2026-02", Date.UTC(2027, 0, 1)), 0);
  assert.equal(terms.lateFeeFor({ start_date: "2026-01-10" }, "2026-02", Date.UTC(2027, 0, 1)), 0, "no fee unless the lease sets one");
  assert.equal(terms.lateFeeFor({ start_date: "2026-01-10", late_fee_amount: 100 }, "2026-02", Date.UTC(2026, 1, 15, 12)), 0, "default grace is 5 days");
  assert.equal(terms.lateFeeFor({ start_date: "2026-01-10", late_fee_amount: 100 }, "2026-02", Date.UTC(2026, 1, 16)), 100);
  assert.equal(terms.lateFeeFor({ late_fee_amount: 100 }, "2026-02", Date.UTC(2027, 0, 1)), 0, "no start date, no fee");
});

test("TAQ-164: tenantPhoneOf reads the profile phone in any of its spellings", () => {
  assert.equal(terms.tenantPhoneOf({ phone: "+971 50 123 4567" }), "+971501234567");
  assert.equal(terms.tenantPhoneOf({ phone_number: "0100-123-4567" }), "01001234567");
  assert.equal(terms.tenantPhoneOf({}), "");
  assert.equal(terms.tenantPhoneOf(null), "");
});

// --- createLease ---

test("TAQ-164: createLease copies the tenant's phone and stores the optional terms; the default fee is 0", async () => {
  const plain = await leaseDoc((await create(input())).leaseId);
  assert.equal(plain.tenant_phone, "+971501234567");
  assert.equal(plain.late_fee_amount, 0);
  assert.equal(plain.payout_iban, undefined);

  await db.collection("Leases").get().then((s) => Promise.all(s.docs.map((d) => d.ref.delete())));
  const full = await leaseDoc((await create(input({ lateFeeAmount: 200, lateFeeGraceDays: 3, payoutBankName: "FAB", payoutIban: "AE070331234567890123456", tenantPhone: "+1 555" }))).leaseId);
  assert.equal(full.late_fee_amount, 200);
  assert.equal(full.late_fee_grace_days, 3);
  assert.equal(full.payout_bank_name, "FAB");
  assert.equal(full.payout_iban, "AE070331234567890123456");
  assert.equal(full.tenant_phone, "+971501234567", "the phone comes from the profile, never the request");
});

test("TAQ-164: createLease refuses a bad IBAN or late fee", async () => {
  await reason(create(input({ payoutIban: "not-an-iban" })), "invalid-argument", "iban_invalid");
  await reason(create(input({ lateFeeAmount: -5 })), "invalid-argument", "late_fee_invalid");
  assert.equal((await db.collection("Leases").get()).size, 0);
});

// --- payments ---

async function activeLease(extra) {
  const id = (await create(input(extra))).leaseId;
  await fns.respondToLeaseOffer.run({ data: { leaseId: id, decision: "approve" }, auth: caller("tenantT", { role: "Tenant" }) });
  return id;
}

test("TAQ-164: a manual payment after the grace days carries the late fee; one inside them does not", async () => {
  const id = await activeLease({ lateFeeAmount: 250 });
  const now = Date.UTC(2026, 2, 20, 12);
  payments.deps.now = () => now;
  leases.deps.now = () => now;
  const late = await fns.recordManualPayment.run({ data: { leaseId: id, period: "2026-02", method: "cash", reference: "r-feb", paidOn: "2026-02-20" }, auth: owner() });
  assert.equal(late.status, "paid");
  const feb = (await db.doc(`Transactions/${id}_2026-02`).get()).data();
  assert.equal(feb.amount, 5250);
  assert.equal(feb.rentAmount, 5000);
  assert.equal(feb.lateFee, 250);

  await fns.recordManualPayment.run({ data: { leaseId: id, period: "2026-03", method: "cash", reference: "r-mar", paidOn: "2026-03-12" }, auth: owner() });
  const mar = (await db.doc(`Transactions/${id}_2026-03`).get()).data();
  assert.equal(mar.amount, 5000);
  assert.equal(mar.lateFee, 0);
  await reason(fns.recordManualPayment.run({ data: { leaseId: id, period: "2026-01", method: "cash", reference: "r-jan", paidOn: "2026-03-20", amount: 5000 }, auth: owner() }), "invalid-argument");
});

test("TAQ-164: an online payment for a late month charges rent plus the fee; a lease without a fee charges rent only", async () => {
  const id = await activeLease({ lateFeeAmount: 100, lateFeeGraceDays: 0 });
  const now = Date.UTC(2026, 2, 20, 12);
  payments.deps.now = () => now;
  leases.deps.now = () => now;
  const r = await fns.createRentPaymentIntent.run({ data: { leaseId: id, period: "2026-02" }, auth: caller("tenantT", { role: "Tenant" }) });
  assert.equal(r.status, "pending");
  const tx = (await db.doc(`Transactions/${id}_2026-02`).get()).data();
  assert.equal(tx.amount, 5100);
  assert.equal(tx.amountCents, 510000);
  assert.equal(tx.lateFee, 100);
  assert.equal(sent.at(-1).amount, 510000);
});
