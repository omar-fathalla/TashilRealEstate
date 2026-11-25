/**
 * When a lease is "live": the one definition the payment paths, the property lock and its stale
 * takeover all use (TAQ-110). A live lease is `active` and not past its end date. A lease that
 * starts later is live too: once the tenant accepts, it holds the property, and its first months
 * can be paid ahead (paymentPeriod still refuses months before the start).
 */
const { HttpsError } = require("firebase-functions/v2/https");

const START_KEYS = ["startDate", "start_date", "leaseStartDate", "lease_start_date"];
const END_KEYS = ["endDate", "end_date", "leaseEndDate", "lease_end_date"];
const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;
const DAY_MS = 24 * 60 * 60 * 1000;

/** The first readable date under [keys]: an ISO string, a Date or a Firestore Timestamp. */
function leaseDate(lease, keys) {
  for (const key of keys) {
    const raw = lease ? lease[key] : undefined;
    if (raw === undefined || raw === null || raw === "") continue;
    const date = typeof raw === "string" ? new Date(raw) : raw && typeof raw.toDate === "function" ? raw.toDate() : raw;
    if (date instanceof Date && !Number.isNaN(date.getTime())) return date;
  }
  return null;
}

/** The last instant the lease covers: a date-only end date covers that whole day (UTC). */
function leaseEndMs(lease) {
  for (const key of END_KEYS) {
    const raw = lease ? lease[key] : undefined;
    if (typeof raw === "string" && DATE_ONLY.test(raw)) {
      const day = new Date(`${raw}T00:00:00.000Z`).getTime();
      if (!Number.isNaN(day)) return day + DAY_MS - 1;
    }
    if (raw !== undefined && raw !== null && raw !== "") break;
  }
  const end = leaseDate(lease, END_KEYS);
  return end === null ? null : end.getTime();
}

function leaseLiveState(lease, nowMs = Date.now()) {
  if (!lease || lease.status !== "active") return { live: false, reason: "lease_not_active" };
  const end = leaseEndMs(lease);
  if (end !== null && end < nowMs) return { live: false, reason: "lease_expired" };
  return { live: true, reason: "" };
}

/** Only a live lease can be paid. */
function assertLeasePayable(lease, now = Date.now()) {
  const state = leaseLiveState(lease, now instanceof Date ? now.getTime() : now);
  if (state.live) return;
  throw new HttpsError(
    "failed-precondition",
    state.reason === "lease_expired" ? "This lease has ended." : "Only an active lease can be paid.",
    { reason: state.reason },
  );
}

module.exports = { START_KEYS, END_KEYS, leaseDate, leaseEndMs, leaseLiveState, assertLeasePayable };
