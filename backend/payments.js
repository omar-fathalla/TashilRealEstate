/**
 * Rent payments through Paymob (TAQ-16).
 *
 * createRentPaymentIntent (callable, the lease's tenant only) loads the lease, computes the amount
 * on the server, records `Transactions/{leaseId}_{YYYY-MM}` as `pending`, asks Paymob for a
 * payment intention and returns the Unified Checkout URL. Nothing the client sends can make a
 * payment `paid`.
 *
 * paymobWebhook (HTTPS) is the only writer of `paid` and `failed`. It checks Paymob's HMAC-SHA512
 * signature, finds the payment through the Paymob order id (which the server stored when it
 * created the intention), checks the amount and currency against what it asked for, and only then
 * marks the transaction paid, issues the invoice and notifies the tenant and the owner. Replays
 * change nothing.
 *
 * The gateway is off (PAYMENTS_ENABLED) until the Paymob keys exist; keys come from the
 * environment / Secret Manager, never from the repo. See docs/SECURITY_SETUP.md.
 */
const crypto = require("crypto");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { requireAuth, requireRole, loadLease, leaseAmount, leaseCountry } = require("./authz");
const { appCheckEnforced, paymentSecrets, paymobConfig } = require("./config");

const ENFORCE_APP_CHECK = appCheckEnforced();

const BILLING_PERIOD_PATTERN = /^(\d{4})-(0[1-9]|1[0-2])$/;
const PAYMENT_PERIODS_BACK = 24;
// How long a Paymob intention (and so a checkout link) stays usable, and how long a caller who
// lost a race waits before another attempt may start.
const INTENTION_TTL_SECONDS = 30 * 60;
const CREATING_LOCK_MS = 60 * 1000;

const deps = {
  fetch: (...args) => fetch(...args),
  now: () => Date.now(),
};

const round2 = (value) => Math.round(value * 100) / 100;
const monthIndex = (year, month) => year * 12 + (month - 1);

/** The billing month (UTC) of [now] as YYYY-MM. */
function currentBillingPeriod(now = new Date()) {
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`;
}

function leaseDate(lease, keys) {
  for (const key of keys) {
    const raw = lease ? lease[key] : undefined;
    if (raw === undefined || raw === null || raw === "") continue;
    const date = typeof raw === "string" ? new Date(raw) : raw && typeof raw.toDate === "function" ? raw.toDate() : raw;
    if (date instanceof Date && !Number.isNaN(date.getTime())) return date;
  }
  return null;
}

const START_KEYS = ["startDate", "start_date", "leaseStartDate", "lease_start_date"];
const END_KEYS = ["endDate", "end_date", "leaseEndDate", "lease_end_date"];

// The month a lease starts or ends in, as a monthIndex, or null when the lease carries no readable
// date (older documents). Accepts an ISO string, a Date or a Firestore Timestamp.
function leaseMonth(lease, keys) {
  const date = leaseDate(lease, keys);
  return date ? monthIndex(date.getUTCFullYear(), date.getUTCMonth() + 1) : null;
}

/**
 * The month a payment is for: the caller's explicit `period` (YYYY-MM, from 24 months back to next
 * month, so the key can neither be garbage nor reach arbitrarily far) or the current billing month.
 * It is never earlier than the month the lease starts in, nor later than the month it ends in,
 * when the lease records those dates.
 */
function paymentPeriod(value, now = new Date(), lease = null) {
  const period = value === undefined || value === null ? currentBillingPeriod(now) : value;
  const match = typeof period === "string" ? BILLING_PERIOD_PATTERN.exec(period) : null;
  if (!match) throw new HttpsError("invalid-argument", "period must be a month in the form YYYY-MM.");
  const requested = monthIndex(Number(match[1]), Number(match[2]));
  const current = monthIndex(now.getUTCFullYear(), now.getUTCMonth() + 1);
  if (requested > current + 1 || requested < current - PAYMENT_PERIODS_BACK) {
    throw new HttpsError("invalid-argument", "period is outside the months a payment can be recorded for.");
  }
  const start = leaseMonth(lease, START_KEYS);
  if (start !== null && requested < start) {
    throw new HttpsError("invalid-argument", "period is before the month this lease starts.");
  }
  const end = leaseMonth(lease, END_KEYS);
  if (end !== null && requested > end) {
    throw new HttpsError("failed-precondition", "period is after the month this lease ends.");
  }
  return period;
}

/** Only an active lease that has not run out can be paid. */
function assertLeasePayable(lease, now = new Date()) {
  if (lease.status !== "active") {
    throw new HttpsError("failed-precondition", "Only an active lease can be paid.", { reason: "lease_not_active" });
  }
  const end = leaseDate(lease, END_KEYS);
  if (end !== null && end.getTime() < now.getTime()) {
    throw new HttpsError("failed-precondition", "This lease has ended.", { reason: "lease_expired" });
  }
}

function splitsFor(amount) {
  const platformFee = round2(amount * 0.02);
  const agencyFee = round2(amount * 0.08);
  return { platformFee, agencyFee, ownerPayout: round2(amount - platformFee - agencyFee) };
}

function currencyFor(lease) {
  return leaseCountry(lease) === "AE" ? "AED" : "EGP";
}

function splitName(fullName) {
  const parts = String(fullName || "").trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return { first: "NA", last: "NA" };
  return { first: parts[0], last: parts.slice(1).join(" ") || "NA" };
}

/** Calls Paymob's Create Intention API. Returns { id, orderId, clientSecret }. */
async function createIntention(config, body) {
  let response;
  try {
    response = await deps.fetch(`${config.baseUrl}/v1/intention/`, {
      method: "POST",
      headers: { Authorization: `Token ${config.secretKey}`, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
  } catch (error) {
    logger.error("Paymob intention request failed", { message: error && error.message });
    throw new HttpsError("unavailable", "The payment service is unreachable. Try again shortly.");
  }
  let payload = null;
  try {
    payload = await response.json();
  } catch (_) {
    payload = null;
  }
  const orderId = payload && (payload.intention_order_id ?? (payload.order && payload.order.id));
  if (!response.ok || !payload || !payload.client_secret || orderId === undefined || orderId === null) {
    logger.error("Paymob rejected the intention", { status: response.status });
    throw new HttpsError("unavailable", "The payment service could not start this payment. Try again shortly.");
  }
  return { id: payload.id === undefined ? "" : String(payload.id), orderId: String(orderId), clientSecret: String(payload.client_secret) };
}

function checkoutUrlFor(config, clientSecret) {
  const query = new URLSearchParams({ publicKey: config.publicKey, clientSecret });
  return `${config.checkoutUrl}/?${query.toString()}`;
}

async function loadTenantBilling(uid, lease) {
  const snap = await admin.firestore().collection("Users").doc(uid).get();
  const profile = snap.exists ? snap.data() : {};
  const name = splitName(profile.full_name || lease.tenant_name || lease.tenantName);
  const phone = String(profile.phone || profile.phone_number || profile.phoneNumber || "").trim();
  return {
    first_name: name.first,
    last_name: name.last,
    email: String(profile.email || "NA"),
    phone_number: phone || "NA",
    apartment: "NA",
    floor: "NA",
    street: "NA",
    building: "NA",
    city: "NA",
    country: "ARE",
    state: "NA",
  };
}

const createRentPaymentIntent = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10, secrets: paymentSecrets() },
  async (request) => {
    const auth = requireAuth(request);
    await requireRole(auth, ["Tenant"]);
    const data = request.data || {};

    const config = paymobConfig();
    if (!config.enabled) {
      throw new HttpsError("failed-precondition", "Online payment is not available yet.", { reason: "payments_disabled" });
    }
    if (!config.ready) {
      logger.error("Paymob is enabled but not configured", { missing: config.missing });
      throw new HttpsError("failed-precondition", "Online payment is not available yet.", { reason: "payments_not_configured" });
    }

    const lease = await loadLease(data.leaseId);
    if (!lease.tenant_id || lease.tenant_id !== auth.uid) {
      throw new HttpsError("permission-denied", "Only the tenant of this lease can pay it.");
    }
    assertLeasePayable(lease);

    const due = leaseAmount(lease);
    if (data.amount !== undefined && data.amount !== null) {
      if (typeof data.amount !== "number" || !Number.isFinite(data.amount) || data.amount <= 0) {
        throw new HttpsError("invalid-argument", "amount must be a positive number.");
      }
      if (Math.abs(data.amount - due) > 0.005) {
        throw new HttpsError("invalid-argument", "amount does not match the rent due on this lease.");
      }
    }

    const period = paymentPeriod(data.period, new Date(deps.now()), lease);
    const currency = currencyFor(lease);
    if (currency !== config.currency) {
      throw new HttpsError("failed-precondition", "Online payment is not available for this lease's country yet.", {
        reason: "currency_not_supported",
      });
    }
    const amountCents = Math.round(due * 100);

    const db = admin.firestore();
    const txRef = db.collection("Transactions").doc(`${lease.id}_${period}`);
    const now = deps.now();

    // One payment per lease and month. The claim runs in a transaction so that concurrent calls
    // start one intention between them; the others either reuse it or are told to retry.
    const claim = await db.runTransaction(async (t) => {
      const snap = await t.get(txRef);
      let attempt = 1;
      if (snap.exists) {
        const existing = snap.data();
        if (existing.status === "paid") {
          throw new HttpsError("already-exists", `Rent for ${period} has already been paid on this lease.`, {
            transactionId: txRef.id,
            period,
          });
        }
        if (existing.status === "pending") {
          if (existing.gatewayState === "creating" && now - (existing.intentStartedAtMs || 0) < CREATING_LOCK_MS) {
            throw new HttpsError("aborted", "A payment for this month is being prepared. Try again in a moment.");
          }
          if (existing.gatewayState === "ready" && (existing.sessionExpiresAtMs || 0) > now && existing.currentOrderId) {
            return { reuse: existing.currentOrderId };
          }
        }
        attempt = (existing.attempt || 0) + 1;
      }
      const record = {
        transactionId: txRef.id,
        leaseId: lease.id,
        period,
        tenant_id: lease.tenant_id,
        owner_id: lease.owner_id || "",
        agency_id: lease.agency_id || "",
        amount: due,
        amountCents,
        currencyCode: currency,
        splits: splitsFor(due),
        status: "pending",
        gateway: "paymob",
        gatewayState: "creating",
        attempt,
        intentStartedAtMs: now,
        updated_at: FieldValue.serverTimestamp(),
        userId: auth.uid,
      };
      if (snap.exists) {
        t.update(txRef, { ...record, failureReason: FieldValue.delete() });
      } else {
        t.create(txRef, { ...record, createdAt: FieldValue.serverTimestamp() });
      }
      return { attempt };
    });

    if (claim.reuse) {
      const session = await db.collection("PaymentSessions").doc(claim.reuse).get();
      if (session.exists && session.get("checkoutUrl")) {
        return { success: true, status: "pending", transactionId: txRef.id, period, orderId: claim.reuse, checkoutUrl: session.get("checkoutUrl") };
      }
      throw new HttpsError("aborted", "A payment for this month is being prepared. Try again in a moment.");
    }

    const billing = await loadTenantBilling(auth.uid, lease);
    let intention;
    try {
      intention = await createIntention(config, {
        amount: amountCents,
        currency,
        payment_methods: [/^\d+$/.test(config.integrationId) ? Number(config.integrationId) : config.integrationId],
        items: [{ name: `Rent ${period}`, amount: amountCents, description: `Rent ${period}, lease ${lease.id}`, quantity: 1 }],
        billing_data: billing,
        special_reference: `${txRef.id}~${claim.attempt}`,
        extras: { transactionId: txRef.id, leaseId: lease.id, period },
        expiration: INTENTION_TTL_SECONDS,
        notification_url: config.notificationUrl,
        ...(config.redirectUrl ? { redirection_url: config.redirectUrl } : {}),
      });
    } catch (error) {
      await txRef.update({ status: "failed", gatewayState: "error", failureReason: "gateway_unavailable", updated_at: FieldValue.serverTimestamp() });
      throw error;
    }

    const checkoutUrl = checkoutUrlFor(config, intention.clientSecret);
    const batch = db.batch();
    batch.set(db.collection("PaymentSessions").doc(intention.orderId), {
      orderId: intention.orderId,
      intentionId: intention.id,
      transactionId: txRef.id,
      leaseId: lease.id,
      period,
      attempt: claim.attempt,
      amountCents,
      currency,
      checkoutUrl,
      expiresAtMs: now + INTENTION_TTL_SECONDS * 1000,
      createdAt: FieldValue.serverTimestamp(),
    });
    batch.update(txRef, {
      gatewayState: "ready",
      currentOrderId: intention.orderId,
      gatewayIntentionId: intention.id,
      sessionExpiresAtMs: now + (INTENTION_TTL_SECONDS - 60) * 1000,
      updated_at: FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return { success: true, status: "pending", transactionId: txRef.id, period, orderId: intention.orderId, checkoutUrl };
  },
);

// ---------------------------------------------------------------------------------------------
// Webhook
// ---------------------------------------------------------------------------------------------

/**
 * The string Paymob signs for a "Transaction Processed" callback: the 20 documented fields of
 * `obj`, in the documented order, concatenated with no separator. Missing values count as empty.
 */
function hmacPayload(obj) {
  const order = obj.order || {};
  const source = obj.source_data || {};
  return [
    obj.amount_cents, obj.created_at, obj.currency, obj.error_occured, obj.has_parent_transaction, obj.id,
    obj.integration_id, obj.is_3d_secure, obj.is_auth, obj.is_capture, obj.is_refunded,
    obj.is_standalone_payment, obj.is_voided, order.id, obj.owner, obj.pending,
    source.pan, source.sub_type, source.type, obj.success,
  ].map((value) => (value === null || value === undefined ? "" : String(value))).join("");
}

function verifyPaymobHmac(obj, received, secret) {
  if (typeof received !== "string" || !/^[0-9a-f]{128}$/i.test(received) || !secret) return false;
  const expected = crypto.createHmac("sha512", secret).update(hmacPayload(obj)).digest();
  return crypto.timingSafeEqual(expected, Buffer.from(received, "hex"));
}

const CURRENCY_WORDS = {
  ar: { AED: "درهم", EGP: "جنيه" },
  hi: { AED: "दिरहम", EGP: "मिस्री पाउंड" },
  en: { AED: "AED", EGP: "EGP" },
};

function notificationFor(kind, tx, now) {
  const word = (lang) => `${tx.amount} ${CURRENCY_WORDS[lang][tx.currencyCode] || tx.currencyCode}`;
  const tenant = kind === "tenant";
  return {
    type: tenant ? "rent_payment_receipt" : "rent_payment_received",
    title: tenant
      ? { ar: "تم تأكيد دفع الإيجار", en: "Rent payment confirmed", hi: "किराया भुगतान की पुष्टि हुई" }
      : { ar: "تم استلام دفعة إيجار", en: "Rent payment received", hi: "किराया भुगतान प्राप्त हुआ" },
    body: tenant
      ? {
        ar: `تم تأكيد دفع إيجار شهر ${tx.period} بمبلغ ${word("ar")}.`,
        en: `Your rent for ${tx.period} (${word("en")}) was paid.`,
        hi: `${tx.period} का किराया (${word("hi")}) चुका दिया गया है।`,
      }
      : {
        ar: `استلمنا دفعة إيجار شهر ${tx.period} بمبلغ ${word("ar")}.`,
        en: `Rent for ${tx.period} (${word("en")}) was paid on one of your leases.`,
        hi: `आपके एक पट्टे पर ${tx.period} का किराया (${word("hi")}) चुकाया गया है।`,
      },
    leaseId: tx.leaseId,
    transactionId: tx.transactionId,
    amount: tx.amount,
    currency: tx.currencyCode,
    status: "delivered",
    read: false,
    createdAt: now,
  };
}

/**
 * Applies a verified Paymob transaction to its payment. Returns a short outcome for logs/tests.
 * `paid` only comes from here; a paid payment is never downgraded.
 */
async function applyGatewayTransaction(obj) {
  const db = admin.firestore();
  const orderId = String(obj.order.id);
  const sessionRef = db.collection("PaymentSessions").doc(orderId);

  return db.runTransaction(async (t) => {
    const session = await t.get(sessionRef);
    if (!session.exists) return { outcome: "unknown_order" };
    const txRef = db.collection("Transactions").doc(session.get("transactionId"));
    const txSnap = await t.get(txRef);
    if (!txSnap.exists) return { outcome: "unknown_transaction" };
    const tx = txSnap.data();

    if (obj.pending === true) return { outcome: "pending" };
    if (obj.is_refunded === true || obj.is_voided === true || obj.has_parent_transaction === true) {
      logger.warn("Paymob refund/void callback needs a manual review", { transactionId: txRef.id });
      return { outcome: "refund_or_void_ignored" };
    }

    const succeeded = obj.success === true && obj.error_occured !== true && obj.is_auth !== true;
    if (!succeeded) {
      if (obj.is_auth === true && obj.success === true) return { outcome: "authorised_only" };
      if (tx.status === "pending" && tx.currentOrderId === orderId) {
        t.update(txRef, {
          status: "failed",
          failureReason: "declined",
          gatewayTransactionId: String(obj.id),
          updated_at: FieldValue.serverTimestamp(),
        });
        return { outcome: "failed" };
      }
      return { outcome: "failure_ignored" };
    }

    if (Number(obj.amount_cents) !== session.get("amountCents") || String(obj.currency).toUpperCase() !== session.get("currency")) {
      logger.error("Paymob amount mismatch", { transactionId: txRef.id });
      t.update(txRef, {
        gatewayAnomaly: { reason: "amount_or_currency_mismatch", gatewayTransactionId: String(obj.id), amountCents: Number(obj.amount_cents), currency: String(obj.currency) },
        updated_at: FieldValue.serverTimestamp(),
      });
      return { outcome: "amount_mismatch" };
    }

    if (tx.status === "paid") {
      if (tx.gatewayTransactionId === String(obj.id)) return { outcome: "already_paid" };
      logger.error("Second Paymob payment for an already paid month", { transactionId: txRef.id });
      t.update(txRef, {
        duplicateGatewayTransactions: FieldValue.arrayUnion(String(obj.id)),
        updated_at: FieldValue.serverTimestamp(),
      });
      return { outcome: "duplicate_payment" };
    }

    const leaseSnap = await t.get(db.collection("Leases").doc(tx.leaseId));
    const lease = leaseSnap.exists ? leaseSnap.data() : {};
    const now = Timestamp.now();
    const invoiceNumber = `TASHIL-INV-${tx.transactionId}`;

    t.update(txRef, {
      status: "paid",
      paidAt: now,
      gatewayTransactionId: String(obj.id),
      gatewayOrderId: orderId,
      invoiceNumber,
      gatewayState: "done",
      failureReason: FieldValue.delete(),
      updated_at: FieldValue.serverTimestamp(),
    });
    t.set(db.collection("Invoices").doc(invoiceNumber), {
      invoiceNumber,
      leaseId: tx.leaseId,
      transactionId: tx.transactionId,
      period: tx.period,
      tenantName: lease.tenant_name || lease.tenantName || "",
      propertyTitle: lease.property_title || lease.propertyTitle || "",
      amount: tx.amount,
      platformFee: tx.splits.platformFee,
      agencyFee: tx.splits.agencyFee,
      ownerPayout: tx.splits.ownerPayout,
      vatAmount: 0,
      totalPaid: tx.amount,
      currencyCode: tx.currencyCode,
      tenant_id: tx.tenant_id || null,
      owner_id: tx.owner_id || null,
      agency_id: tx.agency_id || null,
      gatewayTransactionId: String(obj.id),
      status: "Paid_Verified",
      issuedBy: "paymob_webhook",
      createdAt: FieldValue.serverTimestamp(),
    });
    const notify = (uid, kind) => {
      if (!uid) return;
      const id = `pay_${tx.transactionId}_${kind}`;
      t.set(db.collection("Users").doc(uid).collection("notifications").doc(id), {
        id,
        recipientId: uid,
        ...notificationFor(kind, tx, now),
      });
    };
    notify(tx.tenant_id, "tenant");
    if (tx.owner_id !== tx.tenant_id) notify(tx.owner_id, "owner");
    return { outcome: "paid", transactionId: txRef.id };
  });
}

/** The webhook handler, separate from onRequest so tests can drive it with plain objects. */
async function handlePaymobWebhook(req, res) {
  if (req.method !== "POST") {
    res.status(405).json({ error: "method_not_allowed" });
    return;
  }
  const config = paymobConfig();
  if (!config.ready) {
    if (config.enabled) logger.error("Paymob webhook hit while not configured", { missing: config.missing });
    res.status(503).json({ error: "payments_disabled" });
    return;
  }
  const body = req.body;
  if (!body || typeof body !== "object") {
    res.status(400).json({ error: "bad_request" });
    return;
  }
  if (body.type !== undefined && body.type !== "TRANSACTION") {
    res.status(200).json({ ok: true, ignored: "type" });
    return;
  }
  const obj = body.obj;
  if (!obj || typeof obj !== "object" || !obj.order || typeof obj.order !== "object" || obj.order.id === undefined || obj.order.id === null) {
    res.status(400).json({ error: "bad_request" });
    return;
  }
  const received = req.query && typeof req.query.hmac === "string" ? req.query.hmac : "";
  if (!verifyPaymobHmac(obj, received, config.hmacSecret)) {
    logger.warn("Paymob webhook with a bad signature rejected");
    res.status(401).json({ error: "bad_signature" });
    return;
  }
  try {
    const result = await applyGatewayTransaction(obj);
    logger.info("Paymob webhook applied", { outcome: result.outcome });
    res.status(200).json({ ok: true, outcome: result.outcome });
  } catch (error) {
    logger.error("Paymob webhook failed", { message: error && error.message });
    res.status(500).json({ error: "internal" });
  }
}

const paymobWebhook = onRequest({ maxInstances: 10, secrets: paymentSecrets(), cors: false }, handlePaymobWebhook);

module.exports = {
  createRentPaymentIntent,
  paymobWebhook,
  handlePaymobWebhook,
  applyGatewayTransaction,
  hmacPayload,
  verifyPaymobHmac,
  paymentPeriod,
  assertLeasePayable,
  deps,
};
