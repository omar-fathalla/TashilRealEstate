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
const { initializeApp, getApps } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, Timestamp, getFirestore } = require("firebase-admin/firestore");

if (!getApps().length) initializeApp();

const { requireFreshAuth, requireRole, loadLease, leaseAmount, leaseCountry } = require("./authz");
const { lateFeeFor } = require("./lease_terms");
const { appCheckEnforced, paymentSecrets, paymobConfig } = require("./config");
const { START_KEYS, END_KEYS, leaseDate, assertLeasePayable } = require("./lease_state");
const { leaseForPayment } = require("./leases");

const ENFORCE_APP_CHECK = appCheckEnforced();

const BILLING_PERIOD_PATTERN = /^(\d{4})-(0[1-9]|1[0-2])$/;
const PAYMENT_PERIODS_BACK = 24;
// How long a Paymob intention (and so a checkout link) stays usable, and how long a caller who
// lost a race waits before another attempt may start.
const INTENTION_TTL_SECONDS = 30 * 60;
const CREATING_LOCK_MS = 60 * 1000;
// Invoice statuses that mean the month is settled, whichever way it was paid.
const PAID_INVOICE_STATUSES = ["Paid_Verified", "Paid_Recorded"];
const ALERTS = "AdminAlerts";

/**
 * When the gateway can no longer take money for the pending payment [tx]: the expiry of the
 * Paymob intention it opened (the same TTL is sent to Paymob as the intention's `expiration`).
 * While the intention is still being created, its expiry is not known yet, so the longest it could
 * be is assumed. 0 when the payment has no open gateway intention.
 */
function intentExpiresAtMs(tx) {
  // A declined card can be retried in the same checkout until the intention expires, so a failed
  // payment keeps its intention open too.
  if (!tx || !["pending", "failed"].includes(tx.status) || tx.gateway !== "paymob") return 0;
  if (tx.gatewayState === "ready") {
    if (typeof tx.intentExpiresAtMs === "number") return tx.intentExpiresAtMs;
    return (tx.sessionExpiresAtMs || 0) + 60 * 1000;
  }
  if (tx.gatewayState === "creating" && tx.status === "pending") {
    return (tx.intentStartedAtMs || 0) + CREATING_LOCK_MS + INTENTION_TTL_SECONDS * 1000;
  }
  return 0;
}

const deps = {
  fetch: (...args) => fetch(...args),
  now: () => Date.now(),
  listSuperAdmins: () => listSuperAdminUids(),
};

const round2 = (value) => Math.round(value * 100) / 100;
const monthIndex = (year, month) => year * 12 + (month - 1);

/** The billing month (UTC) of [now] as YYYY-MM. */
function currentBillingPeriod(now = new Date()) {
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`;
}

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

const DEFAULT_SPLIT = { platformPercent: 2, agencyPercent: 8 };
const SPLIT_DOC = "payment_split";

/**
 * The platform/agency percentages of a payment, read on the server from `Settings/payment_split`
 * (only SuperAdmin can write it). A missing document means the 2 / 8 defaults; a document that is
 * not valid stops the payment instead of guessing. Nothing here ever comes from a client.
 */
async function loadSplitPercents() {
  const snap = await getFirestore().collection("Settings").doc(SPLIT_DOC).get();
  if (!snap.exists) return { ...DEFAULT_SPLIT };
  const platform = snap.get("platform_percent");
  const agency = snap.get("agency_percent");
  const valid = [platform, agency].every((v) => typeof v === "number" && Number.isFinite(v) && v >= 0 && v <= 100) && platform + agency <= 100;
  if (!valid) {
    logger.error("Settings/payment_split is not valid");
    throw new HttpsError("failed-precondition", "The payment split is not configured correctly.", { reason: "split_invalid" });
  }
  return { platformPercent: platform, agencyPercent: agency };
}

function splitsFor(amount, percents = DEFAULT_SPLIT) {
  const platformFee = round2((amount * percents.platformPercent) / 100);
  const agencyFee = round2((amount * percents.agencyPercent) / 100);
  return { platformFee, agencyFee, ownerPayout: round2(amount - platformFee - agencyFee) };
}

/** An audit entry: who did what, when. Appended to the transaction's `auditTrail`. */
function auditEntry(action, actor, extra = {}) {
  return { action, by: actor.uid, role: actor.role, at: Timestamp.now(), ...extra };
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
  const snap = await getFirestore().collection("Users").doc(uid).get();
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
    const auth = await requireFreshAuth(request);
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

    // The month's rent, plus the lease's flat late fee once its grace days are over (TAQ-164; 0 by default).
    const period = paymentPeriod(data.period, new Date(deps.now()), lease);
    const rent = leaseAmount(lease);
    const lateFee = lateFeeFor(lease, period, deps.now());
    const due = Math.round((rent + lateFee) * 100) / 100;
    if (data.amount !== undefined && data.amount !== null) {
      if (typeof data.amount !== "number" || !Number.isFinite(data.amount) || data.amount <= 0) {
        throw new HttpsError("invalid-argument", "amount must be a positive number.");
      }
      if (Math.abs(data.amount - due) > 0.005) {
        throw new HttpsError("invalid-argument", "amount does not match the rent due on this lease.");
      }
    }

    const currency = currencyFor(lease);
    if (currency !== config.currency) {
      throw new HttpsError("failed-precondition", "Online payment is not available for this lease's country yet.", {
        reason: "currency_not_supported",
      });
    }
    const amountCents = Math.round(due * 100);
    const percents = await loadSplitPercents();

    const db = getFirestore();
    const txRef = db.collection("Transactions").doc(`${lease.id}_${period}`);
    const now = deps.now();

    // One payment per lease and month. The claim runs in a transaction so that concurrent calls
    // start one intention between them; the others either reuse it or are told to retry.
    const invoiceRef = db.collection("Invoices").doc(`TASHIL-INV-${txRef.id}`);
    const claim = await db.runTransaction(async (t) => {
      const held = await leaseForPayment(t, db, lease.id, now, auth.uid);
      const snap = await t.get(txRef);
      const invoice = await t.get(invoiceRef);
      if (invoice.exists && PAID_INVOICE_STATUSES.includes(invoice.get("status"))) {
        throw new HttpsError("already-exists", `Rent for ${period} has already been paid on this lease.`, {
          transactionId: txRef.id,
          period,
          reason: "already_paid",
        });
      }
      let attempt = 1;
      if (snap.exists) {
        const existing = snap.data();
        if (existing.status === "paid") {
          throw new HttpsError("already-exists", `Rent for ${period} has already been paid on this lease.`, {
            transactionId: txRef.id,
            period,
            reason: "already_paid",
          });
        }
        if (existing.status === "pending") {
          if (existing.gatewayState === "creating" && now - (existing.intentStartedAtMs || 0) < CREATING_LOCK_MS) {
            throw new HttpsError("aborted", "A payment for this month is being prepared. Try again in a moment.");
          }
          if (existing.gatewayState === "ready" && (existing.sessionExpiresAtMs || 0) > now && existing.currentOrderId) {
            held.claim();
            return { reuse: existing.currentOrderId };
          }
        }
        attempt = (existing.attempt || 0) + 1;
      }
      held.claim();
      const record = {
        transactionId: txRef.id,
        leaseId: lease.id,
        period,
        tenant_id: lease.tenant_id,
        owner_id: lease.owner_id || "",
        agency_id: lease.agency_id || "",
        amount: due,
        rentAmount: rent,
        lateFee,
        amountCents,
        currencyCode: currency,
        splits: splitsFor(due, percents),
        splitPercent: { platform: percents.platformPercent, agency: percents.agencyPercent },
        status: "pending",
        gateway: "paymob",
        gatewayState: "creating",
        attempt,
        intentStartedAtMs: now,
        updated_at: FieldValue.serverTimestamp(),
        userId: auth.uid,
      };
      const created = auditEntry("intent_created", { uid: auth.uid, role: "Tenant" }, { attempt });
      if (snap.exists) {
        t.update(txRef, { ...record, failureReason: FieldValue.delete(), auditTrail: FieldValue.arrayUnion(created) });
      } else {
        t.create(txRef, { ...record, createdAt: FieldValue.serverTimestamp(), auditTrail: [created] });
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
    // Paymob counts the intention's expiration from when it created it, which is no later than now.
    const expiresAtMs = deps.now() + INTENTION_TTL_SECONDS * 1000;

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
      expiresAtMs,
      createdAt: FieldValue.serverTimestamp(),
    });
    batch.update(txRef, {
      gatewayState: "ready",
      currentOrderId: intention.orderId,
      gatewayIntentionId: intention.id,
      sessionExpiresAtMs: now + (INTENTION_TTL_SECONDS - 60) * 1000,
      intentExpiresAtMs: expiresAtMs,
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
  const result = await settleGatewayTransaction(obj);
  if (result.outcome === "refund_required" && result.alert) {
    try {
      await notifySuperAdmins(result.alertId, result.alert);
    } catch (error) {
      logger.error("Could not notify SuperAdmins of a refund", { alertId: result.alertId, message: error && error.message });
    }
  }
  const { alert, ...outcome } = result;
  return outcome;
}

/** Every SuperAdmin (by custom claim) gets an in-app notification for the refund alert. */
async function notifySuperAdmins(alertId, alert) {
  const db = getFirestore();
  const uids = await deps.listSuperAdmins();
  const amount = `${Math.round(alert.amountCents) / 100} ${alert.currency}`;
  const batch = db.batch();
  for (const uid of uids) {
    batch.set(db.collection("Users").doc(uid).collection("notifications").doc(alertId), {
      id: alertId,
      recipientId: uid,
      type: "refund_required",
      title: { ar: "مطلوب استرداد دفعة إيجار", en: "Rent payment needs a refund", hi: "किराया भुगतान का रिफंड आवश्यक है" },
      body: {
        ar: `تم تحصيل ${amount} إلكترونياً عن شهر ${alert.period} بعد سداده بالفعل. يلزم استرداد المبلغ للمستأجر.`,
        en: `${amount} was charged online for ${alert.period} after that month was already paid. The tenant must be refunded.`,
        hi: `${alert.period} का भुगतान पहले ही हो जाने के बाद ${amount} ऑनलाइन लिया गया। किरायेदार को रिफंड देना होगा।`,
      },
      transactionId: alert.transactionId,
      leaseId: alert.leaseId,
      status: "delivered",
      read: false,
      createdAt: Timestamp.now(),
    });
  }
  if (uids.length) await batch.commit();
  return uids.length;
}

async function listSuperAdminUids() {
  const uids = [];
  let pageToken;
  do {
    const page = await getAuth().listUsers(1000, pageToken);
    for (const user of page.users) {
      if (user.customClaims && user.customClaims.role === "SuperAdmin") uids.push(user.uid);
    }
    pageToken = page.pageToken;
  } while (pageToken);
  return uids;
}

async function settleGatewayTransaction(obj) {
  const db = getFirestore();
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
          auditTrail: FieldValue.arrayUnion(auditEntry("gateway_failed", { uid: "paymob_webhook", role: "system" }, { gatewayTransactionId: String(obj.id) })),
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
      // Money was taken for a month that is already settled (a manual payment after the checkout
      // expired, or a second checkout). The month stays paid once; the charge needs a refund.
      const gatewayTransactionId = String(obj.id);
      const alertRef = db.collection(ALERTS).doc(`refund_${txRef.id}_${gatewayTransactionId}`);
      const existingAlert = await t.get(alertRef);
      if (existingAlert.exists) return { outcome: "refund_required", alertId: alertRef.id, transactionId: txRef.id, repeated: true };
      const superseded = session.get("superseded") === true || (tx.supersededOrderIds || []).includes(orderId);
      logger.error("Paymob payment for an already paid month: refund required", { transactionId: txRef.id, superseded });
      t.update(txRef, {
        refund_required: true,
        refundRequiredGatewayTransactions: FieldValue.arrayUnion(gatewayTransactionId),
        duplicateGatewayTransactions: FieldValue.arrayUnion(gatewayTransactionId),
        updated_at: FieldValue.serverTimestamp(),
        auditTrail: FieldValue.arrayUnion(auditEntry("refund_required", { uid: "paymob_webhook", role: "system" }, { gatewayTransactionId, orderId })),
      });
      const alert = {
        type: "refund_required",
        status: "open",
        transactionId: txRef.id,
        leaseId: tx.leaseId || "",
        period: tx.period || "",
        orderId,
        gatewayTransactionId,
        amountCents: Number(obj.amount_cents),
        currency: String(obj.currency).toUpperCase(),
        settledBy: tx.gateway === "manual" ? "manual" : "gateway",
        supersededIntent: superseded,
        tenant_id: tx.tenant_id || "",
        owner_id: tx.owner_id || "",
        agency_id: tx.agency_id || "",
        created_at: FieldValue.serverTimestamp(),
      };
      t.create(alertRef, alert);
      return { outcome: "refund_required", alertId: alertRef.id, transactionId: txRef.id, alert };
    }

    const leaseSnap = await t.get(db.collection("Leases").doc(tx.leaseId));
    settlePaid(t, db, txRef, tx, leaseSnap.exists ? leaseSnap.data() : {}, {
      invoiceStatus: "Paid_Verified",
      issuedBy: "paymob_webhook",
      txFields: { gatewayTransactionId: String(obj.id), gatewayOrderId: orderId, gatewayState: "done" },
      invoiceExtra: { gatewayTransactionId: String(obj.id) },
      audit: auditEntry("gateway_paid", { uid: "paymob_webhook", role: "system" }, { gatewayTransactionId: String(obj.id) }),
    });
    return { outcome: "paid", transactionId: txRef.id };
  });
}

/**
 * Everything that happens when a payment becomes paid, gateway or manual: the transaction, one
 * invoice with a deterministic id, and a notification for the tenant and the owner. It runs inside
 * the caller's Firestore transaction, so it is all-or-nothing and a replay finds `paid` and stops
 * before getting here.
 */
function settlePaid(t, db, txRef, tx, lease, { invoiceStatus, issuedBy, txFields, audit, invoiceExtra = {}, notifyOwner = true }) {
  const now = Timestamp.now();
  const invoiceNumber = `TASHIL-INV-${tx.transactionId}`;
  t.update(txRef, {
    status: "paid",
    paidAt: now,
    invoiceNumber,
    failureReason: FieldValue.delete(),
    updated_at: FieldValue.serverTimestamp(),
    auditTrail: FieldValue.arrayUnion(audit),
    ...txFields,
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
    status: invoiceStatus,
    issuedBy,
    createdAt: FieldValue.serverTimestamp(),
    ...invoiceExtra,
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
  if (notifyOwner && tx.owner_id !== tx.tenant_id) notify(tx.owner_id, "owner");
}

// ---------------------------------------------------------------------------------------------
// Manual (cash / bank transfer) payments
// ---------------------------------------------------------------------------------------------

const MANUAL_METHODS = ["cash", "bank_transfer"];
const REFERENCE_MAX = 100;
const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

function parsePaidOn(value, now) {
  const match = typeof value === "string" ? DATE_ONLY.exec(value) : null;
  const date = match ? new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]))) : null;
  if (!date || Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new HttpsError("invalid-argument", "paidOn must be a date in the form YYYY-MM-DD.");
  }
  if (date.getTime() > now + 24 * 60 * 60 * 1000) {
    throw new HttpsError("invalid-argument", "paidOn cannot be in the future.");
  }
  return date;
}

/**
 * Who may record a payment that happened outside the gateway: the lease's owner, the agency that
 * manages it, or a SuperAdmin. Never the tenant, and never the platform Admin, which has no
 * access to leases or transactions (TAQ-91, TAQ-183).
 */
function assertCanRecordPayment(auth, role, lease) {
  if (role === "SuperAdmin") return;
  if (role === "Owner" && lease.owner_id && lease.owner_id === auth.uid) return;
  const agencyId = auth.token && auth.token.agency_id;
  if (role === "AgencyAdmin" && agencyId && lease.agency_id === agencyId) return;
  throw new HttpsError("permission-denied", "You cannot record payments on this lease.");
}

const recordManualPayment = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = await requireFreshAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const data = request.data || {};

  const lease = await loadLease(data.leaseId);
  assertCanRecordPayment(auth, role, lease);
  if (!lease.tenant_id) throw new HttpsError("failed-precondition", "The lease has no tenant.");
  assertLeasePayable(lease);

  if (!MANUAL_METHODS.includes(data.method)) {
    throw new HttpsError("invalid-argument", "method must be cash or bank_transfer.");
  }
  const reference = typeof data.reference === "string" ? data.reference.trim() : "";
  if (!reference || reference.length > REFERENCE_MAX) {
    throw new HttpsError("invalid-argument", `reference is required (up to ${REFERENCE_MAX} characters).`);
  }
  const now = deps.now();
  const paidOn = parsePaidOn(data.paidOn, now);

  const period = paymentPeriod(data.period, new Date(now), lease);
  // Paid on paidOn: the late fee applies when that day is past the grace days (TAQ-164).
  const rent = leaseAmount(lease);
  const lateFee = lateFeeFor(lease, period, paidOn.getTime());
  const due = Math.round((rent + lateFee) * 100) / 100;
  if (data.amount !== undefined && data.amount !== null) {
    if (typeof data.amount !== "number" || !Number.isFinite(data.amount) || data.amount <= 0) {
      throw new HttpsError("invalid-argument", "amount must be a positive number.");
    }
    if (Math.abs(data.amount - due) > 0.005) {
      throw new HttpsError("invalid-argument", "amount does not match the rent due on this lease.");
    }
  }
  const currency = currencyFor(lease);

  const db = getFirestore();
  const txRef = db.collection("Transactions").doc(`${lease.id}_${period}`);
  const actor = { uid: auth.uid, role };
  await db.runTransaction(async (t) => {
    const held = await leaseForPayment(t, db, lease.id, now, auth.uid);
    const snap = await t.get(txRef);
    if (snap.exists && snap.get("status") === "paid") {
      throw new HttpsError("already-exists", `Rent for ${period} has already been paid on this lease.`, {
        transactionId: txRef.id,
        period,
        reason: "already_paid",
      });
    }
    const existing = snap.exists ? snap.data() : null;
    const openUntil = intentExpiresAtMs(existing);
    if (openUntil > now) {
      throw new HttpsError("failed-precondition", "An online payment for this month is still open. Try again after it expires.", {
        reason: "payment_pending",
        transactionId: txRef.id,
        period,
        retryAfterMs: openUntil,
      });
    }
    const supersededOrder = existing && existing.gateway === "paymob" && existing.currentOrderId ? String(existing.currentOrderId) : "";
    const record = {
      transactionId: txRef.id,
      leaseId: lease.id,
      period,
      tenant_id: lease.tenant_id,
      owner_id: lease.owner_id || "",
      agency_id: lease.agency_id || "",
      amount: due,
      rentAmount: rent,
      lateFee,
      amountCents: Math.round(due * 100),
      currencyCode: currency,
      // Nothing passed through the platform, so nothing is deducted.
      splits: { platformFee: 0, agencyFee: 0, ownerPayout: due },
      method: data.method,
      reference,
      paidOn: Timestamp.fromDate(paidOn),
      recordedBy: auth.uid,
      recordedByRole: role,
      gateway: "manual",
      userId: auth.uid,
    };
    const audit = auditEntry("manual_payment_recorded", actor, {
      method: data.method,
      reference,
      paidOn: data.paidOn,
      ...(supersededOrder ? { supersededOrderId: supersededOrder } : {}),
    });
    const txView = { ...record, status: "paid" };
    held.claim();
    if (snap.exists) {
      t.update(txRef, {
        ...record,
        gatewayState: supersededOrder ? "superseded" : FieldValue.delete(),
        ...(supersededOrder ? { supersededOrderIds: FieldValue.arrayUnion(supersededOrder) } : {}),
      });
      if (supersededOrder) {
        t.set(db.collection("PaymentSessions").doc(supersededOrder), { superseded: true, supersededAt: Timestamp.fromMillis(now) }, { merge: true });
      }
    } else {
      t.create(txRef, { ...record, status: "pending", createdAt: FieldValue.serverTimestamp(), auditTrail: [] });
    }
    settlePaid(t, db, txRef, txView, lease, {
      invoiceStatus: "Paid_Recorded",
      issuedBy: auth.uid,
      txFields: {},
      audit,
      invoiceExtra: { paymentMethod: data.method, paymentReference: reference, paidOn: data.paidOn, recordedByRole: role },
      notifyOwner: auth.uid !== lease.owner_id,
    });
  });
  return { success: true, status: "paid", transactionId: txRef.id, period, invoiceNumber: `TASHIL-INV-${txRef.id}` };
});

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
  recordManualPayment,
  loadSplitPercents,
  splitsFor,
  paymobWebhook,
  handlePaymobWebhook,
  applyGatewayTransaction,
  hmacPayload,
  verifyPaymobHmac,
  paymentPeriod,
  assertLeasePayable,
  intentExpiresAtMs,
  INTENTION_TTL_SECONDS,
  deps,
};
