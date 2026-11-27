/**
 * Optional lease terms (TAQ-164), with no side effects so the functions, the rules tests and the
 * client mirror share one definition:
 *
 * - `late_fee_amount` is a flat fee added once to a month's rent when that month is paid after
 *   its due day plus `late_fee_grace_days`. The default is 0: no fee, so leases without it behave
 *   exactly as before.
 * - `payout_bank_name` / `payout_iban` say where the owner wants the rent paid out. They are
 *   private to the lease parties, like the rest of the lease.
 * - `tenant_phone` is copied from the tenant's own profile by createLease, so the owner and the
 *   managing agency can reach their tenant. No client writes it.
 */
const { HttpsError } = require("firebase-functions/v2/https");
const { stripContacts } = require("./contact_filter");

const LATE_FEE_MAX = 1000000;
const DEFAULT_GRACE_DAYS = 5;
const MAX_GRACE_DAYS = 60;
const BANK_NAME_MAX = 100;
const IBAN_PATTERN = /^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$/;
const PHONE_MAX = 30;
const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;
const PERIOD = /^(\d{4})-(\d{2})$/;

function invalid(message, reason) {
  return new HttpsError("invalid-argument", message, reason ? { reason } : undefined);
}

/** The optional terms from a createLease request, cleaned; absent keys are left out. */
function leaseExtrasFrom(data) {
  const out = {};
  if (data.lateFeeAmount !== undefined && data.lateFeeAmount !== null) {
    const fee = data.lateFeeAmount;
    if (typeof fee !== "number" || !Number.isFinite(fee) || fee < 0 || fee > LATE_FEE_MAX) {
      throw invalid("lateFeeAmount must be a number of 0 or more.", "late_fee_invalid");
    }
    if (Math.abs(Math.round(fee * 100) - fee * 100) > 1e-6) throw invalid("lateFeeAmount can have at most 2 decimals.", "late_fee_invalid");
    out.late_fee_amount = Math.round(fee * 100) / 100;
  }
  if (data.lateFeeGraceDays !== undefined && data.lateFeeGraceDays !== null) {
    const grace = data.lateFeeGraceDays;
    if (!Number.isInteger(grace) || grace < 0 || grace > MAX_GRACE_DAYS) {
      throw invalid(`lateFeeGraceDays must be a whole number from 0 to ${MAX_GRACE_DAYS}.`, "late_fee_invalid");
    }
    out.late_fee_grace_days = grace;
  }
  if (data.payoutBankName !== undefined && data.payoutBankName !== null && data.payoutBankName !== "") {
    if (typeof data.payoutBankName !== "string") throw invalid("payoutBankName must be text.", "bank_invalid");
    const name = stripContacts(data.payoutBankName).replace(/\s+/g, " ").trim().slice(0, BANK_NAME_MAX);
    if (name) out.payout_bank_name = name;
  }
  if (data.payoutIban !== undefined && data.payoutIban !== null && data.payoutIban !== "") {
    const iban = normalizeIban(data.payoutIban);
    if (!iban) throw invalid("payoutIban is not a valid IBAN.", "iban_invalid");
    out.payout_iban = iban;
  }
  return out;
}

/** Upper-case, spaces removed, shape-checked (country, check digits, 11-30 characters); '' when not an IBAN. */
function normalizeIban(value) {
  if (typeof value !== "string") return "";
  const iban = value.replace(/\s+/g, "").toUpperCase();
  return IBAN_PATTERN.test(iban) ? iban : "";
}

/** The phone number on the tenant's own profile, or ''. */
function tenantPhoneOf(profile) {
  if (!profile || typeof profile !== "object") return "";
  for (const key of ["phone", "phone_number", "phoneNumber"]) {
    const value = profile[key];
    if (typeof value === "string" && value.trim()) return value.replace(/[^\d+]/g, "").slice(0, PHONE_MAX);
  }
  return "";
}

function storedLateFee(lease) {
  const fee = lease && lease.late_fee_amount;
  return typeof fee === "number" && Number.isFinite(fee) && fee > 0 && fee <= LATE_FEE_MAX ? Math.round(fee * 100) / 100 : 0;
}

function storedGraceDays(lease) {
  const grace = lease && lease.late_fee_grace_days;
  return Number.isInteger(grace) && grace >= 0 && grace <= MAX_GRACE_DAYS ? grace : DEFAULT_GRACE_DAYS;
}

/**
 * The day `period` (YYYY-MM) falls due on this lease, as a UTC date: the lease's start day,
 * clamped to the month's length. Null when the lease has no usable start date.
 */
function dueDateOf(lease, period) {
  const start = lease && typeof lease.start_date === "string" ? DATE_ONLY.exec(lease.start_date) : null;
  const month = typeof period === "string" ? PERIOD.exec(period) : null;
  if (!start || !month) return null;
  const year = Number(month[1]);
  const index = Number(month[2]) - 1;
  const last = new Date(Date.UTC(year, index + 1, 0)).getUTCDate();
  return new Date(Date.UTC(year, index, Math.min(Number(start[3]), last)));
}

/** The late fee owed with `period`'s rent when paid at `nowMs`: the flat fee once the grace days are over, else 0. */
function lateFeeFor(lease, period, nowMs) {
  const fee = storedLateFee(lease);
  if (fee <= 0) return 0;
  const due = dueDateOf(lease, period);
  if (!due) return 0;
  const graceEnd = due.getTime() + (storedGraceDays(lease) + 1) * 24 * 60 * 60 * 1000;
  return nowMs >= graceEnd ? fee : 0;
}

module.exports = {
  DEFAULT_GRACE_DAYS,
  MAX_GRACE_DAYS,
  IBAN_PATTERN,
  leaseExtrasFrom,
  normalizeIban,
  tenantPhoneOf,
  dueDateOf,
  lateFeeFor,
};
