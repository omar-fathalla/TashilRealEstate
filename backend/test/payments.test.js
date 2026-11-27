// TAQ-16: rent payments through Paymob. createRentPaymentIntent records a pending payment and
// returns a checkout link; only the signed webhook can mark it paid. The gateway is faked here.
const crypto = require("crypto");
const test = require("node:test");
const assert = require("node:assert/strict");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
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
const ENV_KEYS = [...Object.keys(ENV), "PAYMOB_CURRENCY", "PAYMOB_BASE_URL", "PAYMOB_REDIRECT_URL"];
const savedEnv = Object.fromEntries(ENV_KEYS.map((k) => [k, process.env[k]]));
test.after(() => {
  for (const k of ENV_KEYS) {
    if (savedEnv[k] === undefined) delete process.env[k];
    else process.env[k] = savedEnv[k];
  }
});

const fns = require("../index");
const payments = require("../payments");

const db = getFirestore();
const projectId = process.env.GCLOUD_PROJECT;
const HMAC_SECRET = ENV.PAYMOB_HMAC_SECRET;

const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });
const tenantCaller = () => caller("tenant");

async function expectCode(promise, code) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    return true;
  });
}

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

/** YYYY-MM for the UTC month [offset] months from now. */
function monthsFromNow(offset) {
  const now = new Date();
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + offset, 1));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

const transactions = async () => (await db.collection("Transactions").get()).docs.map((d) => d.data());

let gateway;
let nextOrder;

function installGateway() {
  gateway = { calls: [], fail: false, status: 201 };
  nextOrder = 9000;
  payments.deps.fetch = async (url, init) => {
    gateway.calls.push({ url, init, body: JSON.parse(init.body) });
    if (gateway.fail) throw new Error("network down");
    if (gateway.status !== 201) return { ok: false, status: gateway.status, json: async () => ({ detail: "nope" }) };
    nextOrder += 1;
    return { ok: true, status: 201, json: async () => ({ id: `int_${nextOrder}`, intention_order_id: nextOrder, client_secret: `cs_${nextOrder}` }) };
  };
}

const realFetch = payments.deps.fetch;
test.after(() => {
  payments.deps.fetch = realFetch;
  payments.deps.now = () => Date.now();
});

/**
 * A lease on its own property in the owner's private tree. The owner ("owner") is the agency's
 * account (claims agency_id agency-1), so the lease and the property carry agency-1.
 */
async function seedLease(id, data) {
  const lease = { agency_id: "agency-1", property_id: `prop-${id}`, ...data };
  if (lease.owner_id && lease.property_id) {
    await db.collection("Users").doc(lease.owner_id).collection("properties").doc(lease.property_id)
      .set({ title: `Property ${id}`, agency_id: lease.agency_id }, { merge: true });
    await db.collection("PropertyOwners").doc(lease.property_id).set({ owner_id: lease.owner_id });
  }
  await db.collection("Leases").doc(id).set(lease);
}

test.beforeEach(async () => {
  Object.assign(process.env, ENV);
  delete process.env.PAYMOB_CURRENCY;
  delete process.env.PAYMOB_BASE_URL;
  delete process.env.PAYMOB_REDIRECT_URL;
  payments.deps.now = () => Date.now();
  installGateway();
  await clearAll();
  await db.collection("Users").doc("owner").set({ role: "AgencyAdmin" });
  await getAuth().createUser({ uid: "owner" });
  await getAuth().setCustomUserClaims("owner", { role: "AgencyAdmin", agency_id: "agency-1" });
  await db.collection("Users").doc("tenant").set({ role: "Tenant", full_name: "Lease Tenant", email: "tenant@example.test" });
  await db.collection("Users").doc("stranger").set({ role: "Owner" });
  await seedLease("lease-1", {
    owner_id: "owner",
    tenant_id: "tenant",
    agency_id: "agency-1",
    country_code: "AE",
    status: "active",
    property_title: "Marina Apartment",
    tenant_name: "Lease Tenant",
    financialTerms: { monthlyRent: 8000 },
  });
});

const intent = (data, auth = tenantCaller()) => fns.createRentPaymentIntent.run({ data, auth });

/** A Paymob "Transaction Processed" object for the order of [result], signed like Paymob signs it. */
function gatewayObject(result, overrides = {}) {
  const tx = overrides.amount_cents ?? 800000;
  return {
    amount_cents: tx,
    created_at: "2026-11-25T12:00:00.000000",
    currency: "AED",
    error_occured: false,
    has_parent_transaction: false,
    id: 555001,
    integration_id: 12345,
    is_3d_secure: true,
    is_auth: false,
    is_capture: false,
    is_refunded: false,
    is_standalone_payment: true,
    is_voided: false,
    order: { id: Number(result.orderId), merchant_order_id: `${result.transactionId}~1` },
    owner: 77,
    pending: false,
    source_data: { pan: "2346", sub_type: "MasterCard", type: "card" },
    success: true,
    ...overrides,
  };
}

const sign = (obj, secret = HMAC_SECRET) => crypto.createHmac("sha512", secret).update(payments.hmacPayload(obj)).digest("hex");

const NO_HMAC = Symbol("no hmac");
async function webhook(obj, { hmac = sign(obj), method = "POST", body } = {}) {
  if (hmac === NO_HMAC) hmac = undefined;
  const res = { statusCode: 0, body: null, status(code) { this.statusCode = code; return this; }, json(b) { this.body = b; return this; } };
  await payments.handlePaymobWebhook({ method, query: hmac === undefined ? {} : { hmac }, body: body === undefined ? { type: "TRANSACTION", obj } : body }, res);
  return res;
}

// --- the intent: who, what, how much ---

test("TAQ-16: a signed-out caller gets UNAUTHENTICATED and nothing is written or sent", async () => {
  await expectCode(fns.createRentPaymentIntent.run({ data: { leaseId: "lease-1" } }), "unauthenticated");
  await expectCode(fns.createRentPaymentIntent.run({ data: undefined }), "unauthenticated");
  assert.equal((await transactions()).length, 0);
  assert.equal(gateway.calls.length, 0);
});

test("TAQ-16: the lease's tenant gets a pending payment and a checkout link, never a paid one", async () => {
  const result = await intent({ leaseId: "lease-1", amount: 8000 });
  assert.equal(result.success, true);
  assert.equal(result.status, "pending");
  assert.equal(result.transactionId, `lease-1_${monthsFromNow(0)}`);
  assert.match(result.checkoutUrl, /^https:\/\/uae\.checkout\.paymob\.com\/\?publicKey=fake-public-key&clientSecret=cs_9001$/);
  const [tx] = await transactions();
  assert.equal(tx.status, "pending");
  assert.equal(tx.leaseId, "lease-1");
  assert.equal(tx.amount, 8000);
  assert.equal(tx.amountCents, 800000);
  assert.equal(tx.currencyCode, "AED");
  assert.equal(tx.tenant_id, "tenant");
  assert.equal(tx.owner_id, "owner");
  assert.equal(tx.agency_id, "agency-1");
  assert.equal(tx.userId, "tenant");
  assert.deepEqual(tx.splits, { platformFee: 160, agencyFee: 640, ownerPayout: 7200 });
  assert.equal(tx.gatewayState, "ready");
  assert.equal(tx.currentOrderId, "9001");
  assert.ok(tx.createdAt && typeof tx.createdAt.toDate === "function");
  assert.equal(tx.paidAt, undefined);
  assert.equal("checkoutUrl" in tx, false, "the checkout link (it carries the client secret) is not on the readable transaction");
  assert.equal((await db.collection("Invoices").get()).size, 0, "no invoice before the webhook");
  assert.equal((await db.collection("Users").doc("owner").collection("notifications").get()).size, 0);
});

test("TAQ-16: the gateway request is built on the server from the lease", async () => {
  await intent({ leaseId: "lease-1", amount: 8000 });
  const [call] = gateway.calls;
  assert.equal(call.url, "https://uae.paymob.com/v1/intention/");
  assert.equal(call.init.headers.Authorization, "Token fake-secret-key");
  assert.equal(call.body.amount, 800000);
  assert.equal(call.body.currency, "AED");
  assert.deepEqual(call.body.payment_methods, [12345]);
  assert.equal(call.body.special_reference, `lease-1_${monthsFromNow(0)}~1`);
  assert.equal(call.body.notification_url, "https://example.test/paymobWebhook");
  assert.equal(call.body.billing_data.first_name, "Lease");
  assert.equal(call.body.billing_data.last_name, "Tenant");
  assert.equal(call.body.billing_data.phone_number, "NA");
  assert.equal(JSON.stringify(call.body).includes("fake-secret-key"), false, "the secret key only goes in the header");
});

test("TAQ-16: the amount may be left out, and then the lease's rent is used", async () => {
  await intent({ leaseId: "lease-1" });
  await intent({ leaseId: "lease-1", amount: null, period: monthsFromNow(-1) });
  assert.deepEqual((await transactions()).map((t) => t.amount), [8000, 8000]);
  assert.deepEqual(gateway.calls.map((c) => c.body.amount), [800000, 800000]);
});

test("TAQ-16: negative, non-numeric, non-finite and mismatching amounts are INVALID_ARGUMENT", async () => {
  for (const amount of [-999999, 0, -0.01, "abc", "8000", true, [8000], {}, NaN, Infinity, -Infinity, 1, 7999.5, 8000.5, 80000]) {
    await expectCode(intent({ leaseId: "lease-1", amount }), "invalid-argument");
  }
  assert.equal((await transactions()).length, 0);
  assert.equal(gateway.calls.length, 0);
});

test("TAQ-16: a missing or malformed lease id is INVALID_ARGUMENT and an unknown lease is NOT_FOUND", async () => {
  for (const leaseId of [undefined, "", 7, null, {}, ["lease-1"]]) {
    await expectCode(intent({ leaseId, amount: 8000 }), "invalid-argument");
  }
  await expectCode(intent({ leaseId: "does-not-exist", amount: 8000 }), "not-found");
  await expectCode(intent(undefined), "invalid-argument");
});

test("TAQ-16: only the lease's tenant can pay: other tenants, owner, agency, SuperAdmin and other roles are denied", async () => {
  await db.collection("Users").doc("tenant2").set({ role: "Tenant" });
  await db.collection("Users").doc("inv").set({ role: "Investor" });
  const denied = [
    caller("tenant2"),
    caller("owner"),
    caller("stranger"),
    caller("agent1", { role: "AgencyAdmin", agency_id: "agency-1" }),
    caller("root", { role: "SuperAdmin" }),
    caller("adm", { role: "Admin" }),
    caller("inv"),
    caller("nobody"),
  ];
  for (const who of denied) await expectCode(intent({ leaseId: "lease-1", amount: 8000 }, who), "permission-denied");
  assert.equal((await transactions()).length, 0);
  assert.equal(gateway.calls.length, 0);
});

test("TAQ-16: a lease without a tenant or without a server-side rent cannot be paid", async () => {
  await seedLease("no-tenant", { owner_id: "owner", country_code: "AE", status: "active", financialTerms: { monthlyRent: 100 } });
  await expectCode(intent({ leaseId: "no-tenant", amount: 100 }), "permission-denied");
  await seedLease("no-rent", { owner_id: "owner", tenant_id: "tenant", country_code: "AE", status: "active" });
  await expectCode(intent({ leaseId: "no-rent", amount: 100 }), "failed-precondition");
  await seedLease("no-country", { owner_id: "owner", tenant_id: "tenant", status: "active", financialTerms: { monthlyRent: 100 } });
  await expectCode(intent({ leaseId: "no-country" }), "failed-precondition");
  assert.equal((await transactions()).length, 0);
});

test("TAQ-16: an annual-rent lease is charged one twelfth, rounded to cents", async () => {
  await seedLease("annual", { owner_id: "owner", tenant_id: "tenant", country_code: "AE", status: "active", financialTerms: { annualRent: 100000 } });
  await expectCode(intent({ leaseId: "annual", amount: 100000 }), "invalid-argument");
  await intent({ leaseId: "annual", amount: 8333.33 });
  const [tx] = await transactions();
  assert.equal(tx.amount, 8333.33);
  assert.equal(tx.amountCents, 833333);
  const { platformFee, agencyFee, ownerPayout } = tx.splits;
  assert.equal(Math.round((platformFee + agencyFee + ownerPayout) * 100) / 100, 8333.33);
});

// --- inactive and expired leases ---

test("TAQ-16: a lease that is not active cannot be paid", async () => {
  for (const status of ["draft", "pending_signatures", "expired", "terminated", "", undefined, "ACTIVE", 1]) {
    await db.collection("Leases").doc("lease-1").update({ status: status === undefined ? FieldValue.delete() : status });
    await assert.rejects(intent({ leaseId: "lease-1" }), (e) => {
      assert.equal(e.code, "failed-precondition", String(status));
      assert.equal(e.details.reason, "lease_not_active");
      return true;
    });
  }
  assert.equal((await transactions()).length, 0);
  assert.equal(gateway.calls.length, 0);
});

test("TAQ-16: a lease whose end date has passed cannot be paid, and a period after its end month is rejected", async () => {
  const lease = db.collection("Leases").doc("lease-1");
  await lease.update({ end_date: new Date(Date.now() - 86400000) });
  await assert.rejects(intent({ leaseId: "lease-1" }), (e) => e.code === "failed-precondition" && e.details.reason === "lease_expired");
  await lease.update({ end_date: new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth() + 1, 0, 23, 59, 59)) });
  assert.equal((await intent({ leaseId: "lease-1" })).status, "pending");
  await expectCode(intent({ leaseId: "lease-1", period: monthsFromNow(1) }), "failed-precondition");
  await lease.update({ end_date: new Date(Date.UTC(new Date().getUTCFullYear() + 1, 0, 1)) });
  assert.equal((await intent({ leaseId: "lease-1", period: monthsFromNow(1) })).status, "pending");
});

// --- idempotency, retries, concurrency ---

test("TAQ-16: asking again for a pending month returns the same checkout and creates no second intention", async () => {
  const first = await intent({ leaseId: "lease-1", amount: 8000 });
  const second = await intent({ leaseId: "lease-1" });
  assert.equal(second.checkoutUrl, first.checkoutUrl);
  assert.equal(second.orderId, first.orderId);
  assert.equal(gateway.calls.length, 1);
  assert.equal((await transactions()).length, 1);
});

test("TAQ-16: a paid month is ALREADY_EXISTS and the record is untouched", async () => {
  const first = await intent({ leaseId: "lease-1" });
  await webhook(gatewayObject(first));
  const before = (await db.collection("Transactions").doc(first.transactionId).get()).data();
  await assert.rejects(intent({ leaseId: "lease-1", amount: 8000 }), (err) => {
    assert.equal(err.code, "already-exists");
    assert.equal(err.details.transactionId, first.transactionId);
    return true;
  });
  await expectCode(intent({ leaseId: "lease-1", period: monthsFromNow(0) }), "already-exists");
  assert.deepEqual((await db.collection("Transactions").doc(first.transactionId).get()).data(), before);
  assert.equal(gateway.calls.length, 1);
});

test("TAQ-16: different months, and different leases, are separate payments", async () => {
  await seedLease("lease-2", { owner_id: "owner", tenant_id: "tenant", country_code: "AE", status: "active", financialTerms: { monthlyRent: 3000 } });
  const ids = [];
  for (const [leaseId, period] of [["lease-1", undefined], ["lease-1", monthsFromNow(-1)], ["lease-1", monthsFromNow(1)], ["lease-2", undefined]]) {
    ids.push((await intent({ leaseId, period })).transactionId);
  }
  assert.equal(new Set(ids).size, 4);
  assert.equal((await transactions()).length, 4);
});

test("TAQ-16: concurrent calls for the same lease and month start exactly one intention", async () => {
  const results = await Promise.allSettled(Array.from({ length: 8 }, () => intent({ leaseId: "lease-1", amount: 8000 })));
  const ok = results.filter((r) => r.status === "fulfilled");
  assert.ok(ok.length >= 1);
  assert.equal(gateway.calls.length, 1, "one intention for the month");
  for (const r of results) if (r.status === "rejected") assert.equal(r.reason.code, "aborted", r.reason.message);
  assert.equal((await transactions()).length, 1);
  const again = await intent({ leaseId: "lease-1" });
  assert.equal(again.orderId, "9001");
});

test("TAQ-16: concurrent calls for different months all succeed", async () => {
  const periods = [-3, -2, -1, 0, 1].map(monthsFromNow);
  const results = await Promise.all(periods.map((period) => intent({ leaseId: "lease-1", period })));
  assert.deepEqual(results.map((r) => r.period).sort(), [...periods].sort());
  assert.equal((await transactions()).length, 5);
});

test("TAQ-16: a malformed or out-of-range period is INVALID_ARGUMENT", async () => {
  for (const period of ["2026-13", "2026-00", "2026-1", "26-01", "2026/01", "2026-01-01", "abc", "", 202611, true, ["2026-11"], {}, monthsFromNow(2), monthsFromNow(-25), "1999-01", "9999-12"]) {
    await expectCode(intent({ leaseId: "lease-1", period }), "invalid-argument");
  }
  assert.equal((await transactions()).length, 0);
  for (const period of [monthsFromNow(1), monthsFromNow(-24)]) await intent({ leaseId: "lease-1", period });
  assert.equal((await transactions()).length, 2);
});

test("TAQ-16: a period before the lease start month is rejected, the start month and later are fine", async () => {
  const start = monthsFromNow(-3);
  await db.collection("Leases").doc("lease-1").update({ startDate: `${start}-15T00:00:00.000Z` });
  for (const period of [monthsFromNow(-4), monthsFromNow(-24)]) await expectCode(intent({ leaseId: "lease-1", period }), "invalid-argument");
  assert.equal((await transactions()).length, 0);
  for (const period of [start, monthsFromNow(-2), undefined]) await intent({ leaseId: "lease-1", period });
  assert.equal((await transactions()).length, 3);
});

test("TAQ-16: a rejected call (wrong amount, other tenant) does not use up the month", async () => {
  await expectCode(intent({ leaseId: "lease-1", amount: 1 }), "invalid-argument");
  await db.collection("Users").doc("tenant2").set({ role: "Tenant" });
  await expectCode(intent({ leaseId: "lease-1" }, caller("tenant2")), "permission-denied");
  assert.equal((await transactions()).length, 0);
  assert.equal((await intent({ leaseId: "lease-1", amount: 8000 })).success, true);
});

// --- the gateway is off, unconfigured or failing ---

test("TAQ-16: with the flag off the callable refuses and writes nothing, whatever the keys", async () => {
  for (const flag of [undefined, "", "false", "0", "yes", "TRUEISH"]) {
    if (flag === undefined) delete process.env.PAYMENTS_ENABLED;
    else process.env.PAYMENTS_ENABLED = flag;
    await assert.rejects(intent({ leaseId: "lease-1" }), (e) => e.code === "failed-precondition" && e.details.reason === "payments_disabled", String(flag));
  }
  assert.equal((await transactions()).length, 0);
  assert.equal(gateway.calls.length, 0);
});

test("TAQ-16: enabled but missing a key, the callable refuses without naming a value", async () => {
  for (const key of ["PAYMOB_SECRET_KEY", "PAYMOB_PUBLIC_KEY", "PAYMOB_HMAC_SECRET", "PAYMOB_INTEGRATION_ID", "PAYMOB_NOTIFICATION_URL"]) {
    const saved = process.env[key];
    delete process.env[key];
    await assert.rejects(intent({ leaseId: "lease-1" }), (e) => e.code === "failed-precondition" && e.details.reason === "payments_not_configured", key);
    process.env[key] = saved;
  }
  process.env.PAYMOB_NOTIFICATION_URL = "http://insecure.test/hook";
  await expectCode(intent({ leaseId: "lease-1" }), "failed-precondition");
  assert.equal(gateway.calls.length, 0);
});

test("TAQ-16: role and ownership are checked before the flag, so outsiders learn nothing about it", async () => {
  delete process.env.PAYMENTS_ENABLED;
  await expectCode(fns.createRentPaymentIntent.run({ data: { leaseId: "lease-1" } }), "unauthenticated");
  await expectCode(intent({ leaseId: "lease-1" }, caller("owner")), "permission-denied");
});

test("TAQ-16: only AED leases are payable while the gateway is the UAE one", async () => {
  await seedLease("eg", { owner_id: "owner", tenant_id: "tenant", country_code: "EG", status: "active", financialTerms: { monthlyRent: 500 } });
  await assert.rejects(intent({ leaseId: "eg" }), (e) => e.code === "failed-precondition" && e.details.reason === "currency_not_supported");
  assert.equal((await transactions()).length, 0);
});

test("TAQ-16: a gateway outage fails the payment cleanly and the next call can start a new attempt", async () => {
  gateway.fail = true;
  await expectCode(intent({ leaseId: "lease-1" }), "unavailable");
  let [tx] = await transactions();
  assert.equal(tx.status, "failed");
  assert.equal(tx.failureReason, "gateway_unavailable");
  gateway.fail = false;
  gateway.status = 500;
  await expectCode(intent({ leaseId: "lease-1" }), "unavailable");
  gateway.status = 201;
  const ok = await intent({ leaseId: "lease-1" });
  assert.equal(ok.status, "pending");
  [tx] = await transactions();
  assert.equal(tx.status, "pending");
  assert.equal(tx.attempt, 3);
  assert.equal(tx.failureReason, undefined);
  assert.equal(gateway.calls[2].body.special_reference, `lease-1_${monthsFromNow(0)}~3`);
});

test("TAQ-16: an expired checkout is replaced by a new attempt, and the old order can still be paid", async () => {
  const first = await intent({ leaseId: "lease-1" });
  const base = Date.now();
  payments.deps.now = () => base + 31 * 60 * 1000;
  const second = await intent({ leaseId: "lease-1" });
  assert.notEqual(second.orderId, first.orderId);
  assert.equal(gateway.calls.length, 2);
  const res = await webhook(gatewayObject(first));
  assert.equal(res.body.outcome, "paid", "money taken on the first checkout is not lost");
  assert.equal((await db.collection("Transactions").doc(first.transactionId).get()).get("status"), "paid");
});

test("TAQ-16: the gateway's keys never reach a response or a stored document", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const stored = JSON.stringify(await transactions());
  for (const secret of ["fake-secret-key", "fake-hmac-secret"]) {
    assert.equal(JSON.stringify(result).includes(secret), false);
    assert.equal(stored.includes(secret), false);
  }
});

// --- the webhook ---

test("TAQ-16: a signed success marks the payment paid, issues one verified invoice and notifies both parties", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const res = await webhook(gatewayObject(result));
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.outcome, "paid");

  const tx = (await db.collection("Transactions").doc(result.transactionId).get()).data();
  assert.equal(tx.status, "paid");
  assert.equal(tx.gatewayTransactionId, "555001");
  assert.ok(tx.paidAt);
  const invoice = (await db.collection("Invoices").doc(tx.invoiceNumber).get()).data();
  assert.equal(invoice.status, "Paid_Verified");
  assert.equal(invoice.totalPaid, 8000);
  assert.equal(invoice.amount, 8000);
  assert.equal(invoice.currencyCode, "AED");
  assert.equal(invoice.tenant_id, "tenant");
  assert.equal(invoice.owner_id, "owner");
  assert.equal(invoice.agency_id, "agency-1");
  assert.equal(invoice.transactionId, result.transactionId);
  assert.equal(invoice.period, monthsFromNow(0));
  assert.equal(invoice.ownerPayout, 7200);

  const tenantNote = (await db.doc(`Users/tenant/notifications/pay_${result.transactionId}_tenant`).get()).data();
  const ownerNote = (await db.doc(`Users/owner/notifications/pay_${result.transactionId}_owner`).get()).data();
  assert.equal(tenantNote.type, "rent_payment_receipt");
  assert.equal(ownerNote.type, "rent_payment_received");
  assert.equal(tenantNote.read, false);
  assert.equal(tenantNote.recipientId, "tenant");
  assert.match(tenantNote.body.ar, /^[^A-Za-z]*$/, "Arabic copy has no Latin text");
  assert.match(tenantNote.body.hi, /दिरहम/);
  assert.match(tenantNote.body.en, /AED/);
});

test("TAQ-16: replaying the webhook changes nothing", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const obj = gatewayObject(result);
  assert.equal((await webhook(obj)).body.outcome, "paid");
  const before = (await db.collection("Transactions").doc(result.transactionId).get()).data();
  for (let i = 0; i < 3; i += 1) assert.equal((await webhook(obj)).body.outcome, "already_paid");
  assert.deepEqual((await db.collection("Transactions").doc(result.transactionId).get()).data(), before);
  assert.equal((await db.collection("Invoices").get()).size, 1);
  assert.equal((await db.collection("Users").doc("tenant").collection("notifications").get()).size, 1);
});

test("TAQ-16: concurrent identical webhooks issue exactly one invoice and one notification", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const obj = gatewayObject(result);
  const results = await Promise.all(Array.from({ length: 6 }, () => webhook(obj)));
  assert.ok(results.every((r) => r.statusCode === 200));
  assert.equal(results.filter((r) => r.body.outcome === "paid").length, 1);
  assert.equal((await db.collection("Invoices").get()).size, 1);
  assert.equal((await db.collection("Users").doc("owner").collection("notifications").get()).size, 1);
});

test("TAQ-16: a bad, missing or foreign signature is rejected and nothing changes", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const obj = gatewayObject(result);
  const good = sign(obj);
  const cases = [
    sign(obj, "another-secret"),
    NO_HMAC,
    "",
    "abc",
    good.slice(0, -2),
    `${good}00`,
    good.replace(/^./, good[0] === "a" ? "b" : "a"),
    "z".repeat(128),
  ];
  for (const hmac of cases) {
    const res = await webhook(obj, { hmac });
    assert.equal(res.statusCode, 401, String(hmac));
  }
  assert.equal((await db.collection("Transactions").doc(result.transactionId).get()).get("status"), "pending");
  assert.equal((await db.collection("Invoices").get()).size, 0);
});

test("TAQ-16: a signature does not cover a tampered body", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const obj = gatewayObject(result);
  const good = sign(obj);
  for (const change of [{ amount_cents: 1 }, { success: false }, { id: 9 }, { currency: "EGP" }, { pending: true }, { order: { id: 1 } }, { is_refunded: true }]) {
    const res = await webhook({ ...obj, ...change }, { hmac: good });
    assert.equal(res.statusCode, 401, JSON.stringify(change));
  }
  assert.equal((await db.collection("Transactions").doc(result.transactionId).get()).get("status"), "pending");
});

test("TAQ-16: the signature is checked against the documented 20 fields in order", () => {
  const sample = {
    amount_cents: 100, created_at: "2024-06-13T11:33:44.592345", currency: "EGP", error_occured: false, has_parent_transaction: false,
    id: 192036465, integration_id: 4097558, is_3d_secure: true, is_auth: false, is_capture: false, is_refunded: false,
    is_standalone_payment: true, is_voided: false, order: { id: 217503754 }, owner: 302852, pending: false,
    source_data: { pan: "2346", sub_type: "MasterCard", type: "card" }, success: true,
  };
  assert.equal(
    payments.hmacPayload(sample),
    "1002024-06-13T11:33:44.592345EGPfalsefalse1920364654097558truefalsefalsefalsetruefalse217503754302852false2346MasterCardcardtrue",
    "matches the worked example in Paymob's documentation",
  );
  assert.equal(payments.verifyPaymobHmac(sample, sign(sample), HMAC_SECRET), true);
  assert.equal(payments.verifyPaymobHmac({ ...sample, source_data: null }, sign({ ...sample, source_data: null }), HMAC_SECRET), true);
  assert.equal(payments.verifyPaymobHmac(sample, sign(sample), ""), false);
});

test("TAQ-16: a failed payment is recorded as failed and never as paid; a later success still pays it", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const declined = await webhook(gatewayObject(result, { success: false, id: 555002 }));
  assert.equal(declined.body.outcome, "failed");
  let tx = (await db.collection("Transactions").doc(result.transactionId).get()).data();
  assert.equal(tx.status, "failed");
  assert.equal(tx.paidAt, undefined);
  assert.equal((await db.collection("Invoices").get()).size, 0);
  assert.equal((await webhook(gatewayObject(result, { error_occured: true, success: false, id: 555003 }))).body.outcome, "failure_ignored");
  assert.equal((await webhook(gatewayObject(result))).body.outcome, "paid");
  tx = (await db.collection("Transactions").doc(result.transactionId).get()).data();
  assert.equal(tx.status, "paid");
  assert.equal(tx.failureReason, undefined);
});

test("TAQ-16: a paid payment is never downgraded by a later failure, and a second capture is flagged not paid twice", async () => {
  const result = await intent({ leaseId: "lease-1" });
  await webhook(gatewayObject(result));
  assert.equal((await webhook(gatewayObject(result, { success: false, id: 555009 }))).body.outcome, "failure_ignored");
  assert.equal((await webhook(gatewayObject(result, { id: 555010 }))).body.outcome, "refund_required");
  const tx = (await db.collection("Transactions").doc(result.transactionId).get()).data();
  assert.equal(tx.status, "paid");
  assert.equal(tx.gatewayTransactionId, "555001");
  assert.deepEqual(tx.duplicateGatewayTransactions, ["555010"]);
  assert.equal((await db.collection("Invoices").get()).size, 1);
});

test("TAQ-16: a pending, authorised-only, refund or void callback never marks anything paid", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const outcomes = [];
  for (const change of [{ pending: true }, { is_auth: true }, { is_refunded: true }, { is_voided: true }, { has_parent_transaction: true }]) {
    outcomes.push((await webhook(gatewayObject(result, change))).body.outcome);
  }
  assert.deepEqual(outcomes, ["pending", "authorised_only", "refund_or_void_ignored", "refund_or_void_ignored", "refund_or_void_ignored"]);
  assert.equal((await db.collection("Transactions").doc(result.transactionId).get()).get("status"), "pending");
  assert.equal((await db.collection("Invoices").get()).size, 0);
});

test("TAQ-16: a success for a different amount or currency is not accepted as the rent", async () => {
  const result = await intent({ leaseId: "lease-1" });
  assert.equal((await webhook(gatewayObject(result, { amount_cents: 100 }))).body.outcome, "amount_mismatch");
  assert.equal((await webhook(gatewayObject(result, { currency: "EGP" }))).body.outcome, "amount_mismatch");
  const tx = (await db.collection("Transactions").doc(result.transactionId).get()).data();
  assert.equal(tx.status, "pending");
  assert.equal(tx.gatewayAnomaly.reason, "amount_or_currency_mismatch");
  assert.equal((await db.collection("Invoices").get()).size, 0);
});

test("TAQ-16: an order the server never created is ignored, even with a valid signature", async () => {
  const obj = gatewayObject({ orderId: 424242, transactionId: "x" });
  const res = await webhook(obj);
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.outcome, "unknown_order");
  assert.equal((await db.collection("Invoices").get()).size, 0);
  assert.equal((await transactions()).length, 0);
});

test("TAQ-16: the order id, not the merchant reference, finds the payment", async () => {
  const one = await intent({ leaseId: "lease-1" });
  const two = await intent({ leaseId: "lease-1", period: monthsFromNow(-1) });
  const forged = gatewayObject(two, { order: { id: Number(two.orderId), merchant_order_id: `${one.transactionId}~1` } });
  assert.equal((await webhook(forged)).body.outcome, "paid");
  assert.equal((await db.collection("Transactions").doc(one.transactionId).get()).get("status"), "pending");
  assert.equal((await db.collection("Transactions").doc(two.transactionId).get()).get("status"), "paid");
});

test("TAQ-16: other methods, other callback types and malformed bodies are refused or ignored without effect", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const obj = gatewayObject(result);
  assert.equal((await webhook(obj, { method: "GET" })).statusCode, 405);
  assert.equal((await webhook(obj, { method: "PUT" })).statusCode, 405);
  assert.equal((await webhook(obj, { body: { type: "TOKEN", obj: { token: "x" } } })).statusCode, 200);
  for (const body of [null, "x", { type: "TRANSACTION" }, { type: "TRANSACTION", obj: {} }, { type: "TRANSACTION", obj: { order: {} } }]) {
    assert.equal((await webhook(obj, { body })).statusCode, 400, JSON.stringify(body));
  }
  assert.equal((await db.collection("Transactions").doc(result.transactionId).get()).get("status"), "pending");
});

test("TAQ-16: with the flag off or a key missing the webhook answers 503 and touches nothing", async () => {
  const result = await intent({ leaseId: "lease-1" });
  const obj = gatewayObject(result);
  for (const mutate of [() => delete process.env.PAYMENTS_ENABLED, () => { process.env.PAYMENTS_ENABLED = "true"; delete process.env.PAYMOB_HMAC_SECRET; }]) {
    mutate();
    const res = await webhook(obj, { hmac: sign(obj) });
    assert.equal(res.statusCode, 503);
  }
  Object.assign(process.env, ENV);
  assert.equal((await db.collection("Transactions").doc(result.transactionId).get()).get("status"), "pending");
});

test("TAQ-16: no code path lets a client or the callable write Completed or paid", async () => {
  assert.equal(fns.processRentPayment, undefined, "processRentPayment is gone");
  const result = await intent({ leaseId: "lease-1", amount: 8000, status: "Completed", paid: true, transactionStatus: "paid" });
  const [tx] = await transactions();
  assert.equal(tx.status, "pending");
  assert.equal(tx.paidAt, undefined);
  assert.equal(result.status, "pending");
});

// --- the split comes from Settings/payment_split ---

test("TAQ-16: the split defaults to 2 / 8 / 90 when no setting exists, and is stored with the payment", async () => {
  await intent({ leaseId: "lease-1" });
  const [tx] = await transactions();
  assert.deepEqual(tx.splitPercent, { platform: 2, agency: 8 });
  assert.deepEqual(tx.splits, { platformFee: 160, agencyFee: 640, ownerPayout: 7200 });
});

test("TAQ-16: SuperAdmin's Settings/payment_split sets the split, and a client cannot send one", async () => {
  await db.doc("Settings/payment_split").set({ platform_percent: 3.5, agency_percent: 6, updated_by: "root" });
  await intent({ leaseId: "lease-1", splits: { platformFee: 0, agencyFee: 0, ownerPayout: 8000 }, platformPercent: 0, splitPercent: { platform: 0, agency: 0 } });
  const [tx] = await transactions();
  assert.deepEqual(tx.splitPercent, { platform: 3.5, agency: 6 });
  assert.deepEqual(tx.splits, { platformFee: 280, agencyFee: 480, ownerPayout: 7240 });
});

test("TAQ-16: a changed setting applies to the next payment only; a pending one keeps the split it was created with", async () => {
  const first = await intent({ leaseId: "lease-1" });
  await db.doc("Settings/payment_split").set({ platform_percent: 10, agency_percent: 10, updated_by: "root" });
  await intent({ leaseId: "lease-1" });
  const second = await intent({ leaseId: "lease-1", period: monthsFromNow(-1) });
  assert.deepEqual((await db.doc(`Transactions/${first.transactionId}`).get()).get("splits"), { platformFee: 160, agencyFee: 640, ownerPayout: 7200 });
  assert.deepEqual((await db.doc(`Transactions/${second.transactionId}`).get()).get("splits"), { platformFee: 800, agencyFee: 800, ownerPayout: 6400 });
  await webhook(gatewayObject(first));
  assert.equal((await db.collection("Invoices").doc(`TASHIL-INV-${first.transactionId}`).get()).get("ownerPayout"), 7200);
});

test("TAQ-16: an invalid split setting stops the payment instead of being guessed", async () => {
  for (const bad of [
    { platform_percent: "2", agency_percent: 8 },
    { platform_percent: -1, agency_percent: 8 },
    { platform_percent: 60, agency_percent: 50 },
    { platform_percent: 2 },
    { platform_percent: null, agency_percent: 8 },
  ]) {
    await db.doc("Settings/payment_split").set({ ...bad, updated_by: "root" });
    await assert.rejects(intent({ leaseId: "lease-1" }), (e) => e.code === "failed-precondition" && e.details.reason === "split_invalid", JSON.stringify(bad));
  }
  assert.equal((await transactions()).length, 0);
  assert.equal(gateway.calls.length, 0);
  await db.doc("Settings/payment_split").set({ platform_percent: 0, agency_percent: 0, updated_by: "root" });
  await intent({ leaseId: "lease-1" });
  assert.deepEqual((await transactions())[0].splits, { platformFee: 0, agencyFee: 0, ownerPayout: 8000 });
});

test("TAQ-16: the transaction keeps an audit trail of the gateway events", async () => {
  const result = await intent({ leaseId: "lease-1" });
  await webhook(gatewayObject(result, { success: false, id: 555002 }));
  await webhook(gatewayObject(result));
  const trail = (await db.doc(`Transactions/${result.transactionId}`).get()).get("auditTrail");
  assert.deepEqual(trail.map((e) => e.action), ["intent_created", "gateway_failed", "gateway_paid"]);
  assert.equal(trail[0].by, "tenant");
  assert.equal(trail[2].by, "paymob_webhook");
  assert.ok(trail.every((e) => e.at && typeof e.at.toDate === "function"));
});

// --- manual cash and bank-transfer payments ---

const ownerCaller = () => caller("owner", { role: "AgencyAdmin", agency_id: "agency-1" });
const manual = (data, auth = ownerCaller()) => fns.recordManualPayment.run({ data, auth });
const today = () => new Date().toISOString().slice(0, 10);
const cash = (extra = {}) => ({ leaseId: "lease-1", method: "cash", reference: "Receipt 118", paidOn: today(), ...extra });

/** Turns lease-1 into a lease of a private owner, with no agency, on the owner's own property. */
async function makeOwnerLease() {
  await getAuth().setCustomUserClaims("owner", { role: "Owner" });
  await db.collection("Users").doc("owner").set({ role: "Owner" });
  await db.doc("Users/owner/properties/prop-lease-1").set({ agency_id: "" }, { merge: true });
  await db.doc("Leases/lease-1").update({ agency_id: "" });
}

test("TAQ-16: the owner records a cash payment: paid, one recorded invoice, an audit entry and notifications", async () => {
  await makeOwnerLease();
  const result = await manual(cash({ amount: 8000 }), caller("owner", { role: "Owner" }));
  assert.equal(result.status, "paid");
  assert.equal(result.transactionId, `lease-1_${monthsFromNow(0)}`);
  const tx = (await db.doc(`Transactions/${result.transactionId}`).get()).data();
  assert.equal(tx.status, "paid");
  assert.equal(tx.method, "cash");
  assert.equal(tx.reference, "Receipt 118");
  assert.equal(tx.recordedBy, "owner");
  assert.equal(tx.recordedByRole, "Owner");
  assert.equal(tx.paidOn.toDate().toISOString().slice(0, 10), today());
  assert.deepEqual(tx.splits, { platformFee: 0, agencyFee: 0, ownerPayout: 8000 });
  assert.equal(tx.auditTrail.length, 1);
  assert.equal(tx.auditTrail[0].action, "manual_payment_recorded");
  assert.equal(tx.auditTrail[0].by, "owner");
  assert.equal(tx.auditTrail[0].role, "Owner");
  assert.equal(tx.auditTrail[0].method, "cash");
  assert.equal(tx.auditTrail[0].reference, "Receipt 118");

  const invoice = (await db.doc(`Invoices/${result.invoiceNumber}`).get()).data();
  assert.equal(invoice.status, "Paid_Recorded");
  assert.equal(invoice.paymentMethod, "cash");
  assert.equal(invoice.paymentReference, "Receipt 118");
  assert.equal(invoice.totalPaid, 8000);
  assert.equal(invoice.tenant_id, "tenant");
  assert.equal(invoice.issuedBy, "owner");
  const tenantNote = await db.doc(`Users/tenant/notifications/pay_${result.transactionId}_tenant`).get();
  assert.equal(tenantNote.get("type"), "rent_payment_receipt");
  assert.equal((await db.doc(`Users/owner/notifications/pay_${result.transactionId}_owner`).get()).exists, false, "the recorder is not notified of their own entry");
});

test("TAQ-16: the managing agency and a SuperAdmin can record, and the owner is notified of their entry", async () => {
  const agency = caller("agent1", { role: "AgencyAdmin", agency_id: "agency-1" });
  const staff = caller("root", { role: "SuperAdmin" });
  for (const [who, period, method] of [[agency, monthsFromNow(-1), "bank_transfer"], [staff, monthsFromNow(-2), "cash"]]) {
    const r = await manual(cash({ period, method, reference: "TRF-1" }), who);
    assert.equal(r.status, "paid");
    const tx = (await db.doc(`Transactions/${r.transactionId}`).get()).data();
    assert.equal(tx.recordedBy, who.uid);
    assert.equal(tx.recordedByRole, who.token.role);
    assert.equal((await db.doc(`Users/owner/notifications/pay_${r.transactionId}_owner`).get()).exists, true);
  }
});

test("TAQ-16, TAQ-183: the tenant, other owners, other agencies, investors, the platform Admin and signed-out callers cannot record a payment", async () => {
  await db.collection("Users").doc("inv").set({ role: "Investor" });
  const denied = [
    caller("adm", { role: "Admin" }),
    caller("tenant"),
    caller("stranger"),
    caller("agent2", { role: "AgencyAdmin", agency_id: "agency-2" }),
    caller("inv"),
    caller("nobody"),
  ];
  for (const who of denied) await expectCode(manual(cash(), who), "permission-denied");
  await expectCode(fns.recordManualPayment.run({ data: cash() }), "unauthenticated");
  assert.equal((await transactions()).length, 0);
});

test("TAQ-16: manual recording needs a real method, a reference and a valid date that is not in the future", async () => {
  for (const method of [undefined, "", "card", "Cash", "paymob", 1]) await expectCode(manual(cash({ method })), "invalid-argument");
  for (const reference of [undefined, "", "   ", 7, "x".repeat(101)]) await expectCode(manual(cash({ reference })), "invalid-argument");
  const tomorrow2 = new Date(Date.now() + 3 * 86400000).toISOString().slice(0, 10);
  for (const paidOn of [undefined, "", "2026-13-01", "2026-02-30", "26-01-01", "2026/01/01", tomorrow2, 20260101, "2026-1-1"]) {
    await expectCode(manual(cash({ paidOn })), "invalid-argument");
  }
  for (const amount of [1, -5, "8000", 8000.5]) await expectCode(manual(cash({ amount })), "invalid-argument");
  assert.equal((await transactions()).length, 0);
  assert.equal((await manual(cash({ paidOn: "2020-01-15" }))).status, "paid");
});

test("TAQ-16: a manual payment follows the same lease rules as a gateway one", async () => {
  await db.collection("Leases").doc("lease-1").update({ status: "terminated" });
  await assert.rejects(manual(cash()), (e) => e.code === "failed-precondition" && e.details.reason === "lease_not_active");
  await db.collection("Leases").doc("lease-1").update({ status: "active" });
  await expectCode(manual(cash({ period: monthsFromNow(-25) })), "invalid-argument");
  await expectCode(manual(cash({ leaseId: "nope" })), "not-found");
  assert.equal((await transactions()).length, 0);
});

test("TAQ-16: a month is paid once, whichever way it was paid", async () => {
  await manual(cash());
  await expectCode(manual(cash({ reference: "again" })), "already-exists");
  await expectCode(intent({ leaseId: "lease-1" }), "already-exists");
  const before = (await transactions())[0];
  assert.equal(before.auditTrail.length, 1);
  const gatewayFirst = await intent({ leaseId: "lease-1", period: monthsFromNow(-1) });
  await webhook(gatewayObject(gatewayFirst));
  await expectCode(manual(cash({ period: monthsFromNow(-1) })), "already-exists");
});

test("TAQ-110: a manual payment waits for an open checkout, then supersedes it; a late gateway success is a refund, not a second payment", async () => {
  await getAuth().createUser({ uid: "root" });
  await getAuth().setCustomUserClaims("root", { role: "SuperAdmin" });
  const start = Date.now();
  payments.deps.now = () => start;
  const pending = await intent({ leaseId: "lease-1" });
  let tx = (await db.doc(`Transactions/${pending.transactionId}`).get()).data();
  assert.ok(tx.intentExpiresAtMs >= start + payments.INTENTION_TTL_SECONDS * 1000, "the stored expiry matches the Paymob intention's own expiration");
  assert.equal(gateway.calls[0].body.expiration, payments.INTENTION_TTL_SECONDS);

  await assert.rejects(manual(cash({ method: "bank_transfer", reference: "IBAN ref 9" })), (err) => {
    assert.equal(err.code, "failed-precondition");
    assert.equal(err.details.reason, "payment_pending");
    assert.ok(err.details.retryAfterMs > 0);
    return true;
  });
  payments.deps.now = () => tx.intentExpiresAtMs - 1;
  await expectCode(manual(cash({ method: "bank_transfer", reference: "IBAN ref 9" })), "failed-precondition");

  payments.deps.now = () => tx.intentExpiresAtMs + 1;
  const r = await manual(cash({ method: "bank_transfer", reference: "IBAN ref 9" }));
  assert.equal(r.transactionId, pending.transactionId);
  tx = (await db.doc(`Transactions/${pending.transactionId}`).get()).data();
  assert.equal(tx.status, "paid");
  assert.equal(tx.method, "bank_transfer");
  assert.equal(tx.gatewayState, "superseded");
  assert.deepEqual(tx.supersededOrderIds, [pending.orderId]);
  assert.equal((await db.doc(`PaymentSessions/${pending.orderId}`).get()).get("superseded"), true);
  assert.deepEqual(tx.auditTrail.map((e) => e.action), ["intent_created", "manual_payment_recorded"]);

  const late = await webhook(gatewayObject(pending));
  assert.equal(late.body.outcome, "refund_required");
  tx = (await db.doc(`Transactions/${pending.transactionId}`).get()).data();
  assert.equal(tx.status, "paid");
  assert.equal(tx.method, "bank_transfer", "the month stays paid by the manual entry");
  assert.equal(tx.refund_required, true);
  assert.deepEqual(tx.refundRequiredGatewayTransactions, ["555001"]);
  assert.equal((await db.collection("Invoices").get()).size, 1, "no second invoice");
  const alerts = (await db.collection("AdminAlerts").get()).docs.map((d) => d.data());
  assert.equal(alerts.length, 1);
  assert.equal(alerts[0].type, "refund_required");
  assert.equal(alerts[0].status, "open");
  assert.equal(alerts[0].supersededIntent, true);
  assert.equal(alerts[0].amountCents, 800000);
  const note = (await db.collection("Users").doc("root").collection("notifications").get()).docs.map((d) => d.data());
  assert.equal(note.length, 1);
  assert.equal(note[0].type, "refund_required");
  assert.ok(note[0].title.ar && note[0].title.en && note[0].title.hi);

  assert.equal((await webhook(gatewayObject(pending))).body.outcome, "refund_required", "a replay is still a refund");
  assert.equal((await db.collection("AdminAlerts").get()).size, 1, "a replay raises no second alert");
  assert.equal((await db.collection("Users").doc("root").collection("notifications").get()).size, 1);
  assert.equal((await db.collection("Invoices").get()).size, 1);
});

test("TAQ-110: a checkout cannot be started for a month that is already paid, whichever way", async () => {
  await manual(cash());
  await assert.rejects(intent({ leaseId: "lease-1" }), (err) => err.code === "already-exists");
  await db.doc(`Invoices/TASHIL-INV-lease-1_${monthsFromNow(-1)}`).set({ status: "Paid_Verified" });
  await assert.rejects(intent({ leaseId: "lease-1", period: monthsFromNow(-1) }), (err) => err.code === "already-exists" && err.details.reason === "already_paid");
  assert.equal(gateway.calls.length, 0);
});

test("TAQ-16: concurrent manual recordings for one month write one payment", async () => {
  const results = await Promise.allSettled(Array.from({ length: 5 }, () => manual(cash())));
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  for (const r of results) if (r.status === "rejected") assert.equal(r.reason.code, "already-exists");
  assert.equal((await db.collection("Invoices").get()).size, 1);
  assert.equal((await transactions())[0].auditTrail.length, 1);
});
