/**
 * Rent Collection row actions on the server (TAQ-163). A rent row is one month of one lease
 * (`{leaseId}_{YYYY-MM}`, the same key as its Transactions doc). What the managers do with the
 * row lives in `RentRowStates/{leaseId}_{YYYY-MM}`, so every device and teammate sees it:
 *
 * - trash / restore: hidden from the list for now, or back.
 * - delete: hidden for good (the month's lease and payments are untouched).
 * - note: a private note (contact-free, 500 characters).
 * - reminder / legal_notice: the reminder count and the legal notice date.
 *
 * The rent amount and due date are the lease's, so they are not editable here. Only the lease's
 * owner, its managing agency or a SuperAdmin may act; the parties and SuperAdmin read the doc.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp, getApps } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");

if (!getApps().length) initializeApp();

const { requireFreshAuth, requireRole, loadLease, assertLeaseParty, AGENCY_AGENT } = require("./authz");
const { appCheckEnforced } = require("./config");
const { stripContacts } = require("./contact_filter");

const ENFORCE_APP_CHECK = appCheckEnforced();
const PERIOD = /^\d{4}-(0[1-9]|1[0-2])$/;
const NOTE_MAX = 500;
const ACTIONS = ["trash", "restore", "delete", "note", "reminder", "legal_notice"];
const AGENT_REFUSED_ACTIONS = ["delete", "legal_notice"];

function cleanNote(value) {
  if (value === undefined || value === null) return "";
  if (typeof value !== "string") throw new HttpsError("invalid-argument", "notes must be text.");
  return stripContacts(value.replace(/[\u0000-\u001f\u007f]/g, " ")).replace(/\s+/g, " ").trim().slice(0, NOTE_MAX);
}

/** The fields an action writes. */
function changesFor(action, data) {
  const now = FieldValue.serverTimestamp();
  switch (action) {
    case "trash":
      return { hidden: true, hidden_at: now, deleted: false };
    case "restore":
      return { hidden: false, hidden_at: null, deleted: false };
    case "delete":
      return { hidden: true, deleted: true, deleted_at: now };
    case "note":
      return { notes: cleanNote(data.notes) };
    case "reminder":
      return { reminder_count: FieldValue.increment(1), last_reminder_at: now };
    case "legal_notice":
      return { legal_notice_at: now, reminder_count: FieldValue.increment(1), last_reminder_at: now };
    default:
      throw new HttpsError("invalid-argument", `action must be one of ${ACTIONS.join(", ")}.`);
  }
}

const updateRentRow = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = await requireFreshAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", AGENCY_AGENT, "SuperAdmin"]); // TAQ-169
  const data = request.data || {};
  const period = data.period;
  if (typeof period !== "string" || !PERIOD.test(period)) {
    throw new HttpsError("invalid-argument", "period must be a month in the form YYYY-MM.");
  }
  if (!ACTIONS.includes(data.action)) {
    throw new HttpsError("invalid-argument", `action must be one of ${ACTIONS.join(", ")}.`);
  }
  if (typeof data.leaseId !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(data.leaseId)) {
    throw new HttpsError("invalid-argument", "A lease id is required.");
  }
  // TAQ-169: an agent works the rent rows but cannot delete one or send a legal notice.
  if (role === AGENCY_AGENT && AGENT_REFUSED_ACTIONS.includes(data.action)) {
    throw new HttpsError("permission-denied", "Only the agency admin can do this.", { reason: "agent_not_allowed" });
  }
  const lease = await loadLease(data.leaseId);
  assertLeaseParty(auth, role, lease);
  const changes = changesFor(data.action, data);
  const ref = getFirestore().collection("RentRowStates").doc(`${lease.id}_${period}`);
  await ref.set({
    lease_id: lease.id,
    period,
    owner_id: lease.owner_id || "",
    agency_id: lease.agency_id || "",
    ...changes,
    updated_by: auth.uid,
    updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { success: true, id: ref.id, action: data.action };
});

module.exports = { updateRentRow, cleanNote, ACTIONS };
