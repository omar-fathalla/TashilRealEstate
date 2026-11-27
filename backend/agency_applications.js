/**
 * Agency self-onboarding (TAQ-149). Anyone signed in with a self-service role (Owner, Tenant,
 * Investor) can apply; a SuperAdmin reviews:
 *
 *   applyForAgency           the applicant -> AgencyApplications/{uid} status "pending"
 *   reviewAgencyApplication  SuperAdmin    -> "rejected", or "approved": creates Agencies/{id}
 *                                             (licence pending, no badge) and makes the applicant
 *                                             its AgencyAdmin through applyUserRole
 *
 * Only these callables write the application; the applicant and SuperAdmin read it. An approval is
 * refused while the applicant is a party to a lease that is not finished, or owns a property an
 * agency manages: becoming an agency would change who manages those. The licence badge stays a
 * separate SuperAdmin check (TAQ-154).
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp, getApps } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");

if (!getApps().length) initializeApp();

const { SELF_SERVICE_ROLES, requireFreshAuth, requireRole } = require("./authz");
const { appCheckEnforced } = require("./config");
const { containsContact } = require("./contact_filter");
const { applyUserRole } = require("./roles");
const { writeAuditLog } = require("./audit_log");
const { MANDATES } = require("./agency_mandate_state");

const ENFORCE_APP_CHECK = appCheckEnforced();
const APPLICATIONS = "AgencyApplications";
const OPEN_LEASE_STATUSES = ["draft", "pending_tenant_approval", "active"];
const ORN = /^[A-Za-z0-9-]{1,40}$/;
const PHONE = /^\+?[0-9 ]{6,20}$/;
const UID = /^[A-Za-z0-9_-]{1,128}$/;

function invalid(message, reason) {
  return new HttpsError("invalid-argument", message, { reason });
}

function text(value, field, max, { required = false } = {}) {
  if (value === undefined || value === null || value === "") {
    if (required) throw invalid(`${field} is required.`, `${field}_required`);
    return "";
  }
  if (typeof value !== "string") throw invalid(`${field} must be text.`, `${field}_invalid`);
  const cleaned = value.replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim();
  if (required && cleaned.length < 2) throw invalid(`${field} is required.`, `${field}_required`);
  if (cleaned.length > max) throw invalid(`${field} is too long.`, `${field}_invalid`);
  return cleaned;
}

/** The application fields from the request, checked. */
function applicationFrom(data) {
  const name = text(data.name, "name", 200, { required: true });
  if (containsContact(name)) throw invalid("The agency name cannot hold a phone, link or email.", "name_contact");
  const countryCode = data.countryCode === "AE" || data.countryCode === "EG" ? data.countryCode : "";
  if (!countryCode) throw invalid("countryCode must be AE or EG.", "country_invalid");
  const orn = text(data.orn, "orn", 40);
  if (orn && !ORN.test(orn)) throw invalid("The ORN/RERA number is not valid.", "orn_invalid");
  const phone = text(data.phone, "phone", 20, { required: true });
  if (!PHONE.test(phone)) throw invalid("The phone number is not valid.", "phone_invalid");
  return {
    name,
    country_code: countryCode,
    city: text(data.city, "city", 100),
    orn,
    licence_number: text(data.licenceNumber, "licenceNumber", 60),
    phone,
  };
}

const applyForAgency = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = await requireFreshAuth(request);
  await requireRole(auth, SELF_SERVICE_ROLES);
  if (auth.token && auth.token.firebase && auth.token.firebase.sign_in_provider === "anonymous") {
    throw new HttpsError("permission-denied", "Sign in with an account to apply.");
  }
  const fields = applicationFrom(request.data || {});
  const db = getFirestore();
  const ref = db.collection(APPLICATIONS).doc(auth.uid);
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const status = snap.exists ? snap.get("status") : "";
    if (status === "pending") throw new HttpsError("already-exists", "Your application is already being reviewed.", { reason: "application_pending" });
    if (status === "approved") throw new HttpsError("already-exists", "Your agency is already approved.", { reason: "application_approved" });
    t.set(ref, {
      applicant_id: auth.uid,
      ...fields,
      status: "pending",
      submitted_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
  });
  return { success: true, status: "pending" };
});

/** Why [uid] cannot become an agency now, or "". */
async function approvalBlocker(db, uid) {
  const leases = db.collection("Leases");
  const [asOwner, asTenant, mandates] = await Promise.all([
    leases.where("owner_id", "==", uid).where("status", "in", OPEN_LEASE_STATUSES).limit(1).get(),
    leases.where("tenant_id", "==", uid).where("status", "in", OPEN_LEASE_STATUSES).limit(1).get(),
    db.collection(MANDATES).where("owner_id", "==", uid).where("status", "==", "active").limit(1).get(),
  ]);
  if (!asOwner.empty || !asTenant.empty) return "applicant_has_open_leases";
  if (!mandates.empty) return "applicant_has_mandates";
  return "";
}

const reviewAgencyApplication = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = await requireFreshAuth(request);
  await requireRole(auth, ["SuperAdmin"]);
  const data = request.data || {};
  if (typeof data.uid !== "string" || !UID.test(data.uid)) throw invalid("An applicant id is required.", "uid_invalid");
  if (typeof data.approve !== "boolean") throw invalid("approve must be true or false.", "approve_invalid");
  const note = text(data.note, "note", 500);
  const db = getFirestore();
  const ref = db.collection(APPLICATIONS).doc(data.uid);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Application not found.");
  const application = snap.data();
  if (application.status !== "pending") {
    throw new HttpsError("failed-precondition", "This application was already reviewed.", { reason: "application_not_pending" });
  }

  if (!data.approve) {
    await ref.update({
      status: "rejected",
      review_note: note,
      reviewed_by: auth.uid,
      reviewed_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    await writeAuditLog({ action: "agency_application_rejected", actorUid: auth.uid, actorRole: "SuperAdmin", targetUid: data.uid });
    return { success: true, status: "rejected" };
  }

  const blocker = await approvalBlocker(db, data.uid);
  if (blocker) {
    throw new HttpsError("failed-precondition", "The applicant still has leases or managed properties.", { reason: blocker });
  }

  const agencyRef = db.collection("Agencies").doc();
  const batch = db.batch();
  batch.set(agencyRef, {
    name: application.name,
    names: { ar: application.name, en: application.name, hi: application.name },
    countryCode: application.country_code,
    city: application.city || "",
    orn: application.orn || "",
    licence_status: "pending",
    verified_badge: false,
    updated_at: FieldValue.serverTimestamp(),
  });
  batch.set(agencyRef.collection("private").doc("profile"), {
    phone: application.phone || "",
    licence_number: application.licence_number || "",
    updated_at: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  try {
    await applyUserRole({ uid: data.uid, role: "AgencyAdmin", agencyId: agencyRef.id, actorUid: auth.uid });
  } catch (err) {
    await agencyRef.collection("private").doc("profile").delete();
    await agencyRef.delete();
    throw err;
  }
  await ref.update({
    status: "approved",
    agency_id: agencyRef.id,
    review_note: note,
    reviewed_by: auth.uid,
    reviewed_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  });
  await writeAuditLog({
    action: "agency_application_approved",
    actorUid: auth.uid,
    actorRole: "SuperAdmin",
    targetUid: data.uid,
    details: { agency_id: agencyRef.id },
  });
  return { success: true, status: "approved", agencyId: agencyRef.id };
});

module.exports = { APPLICATIONS, applyForAgency, reviewAgencyApplication, applicationFrom, approvalBlocker };
