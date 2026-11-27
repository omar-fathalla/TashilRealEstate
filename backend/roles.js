const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { ASSIGNABLE_ROLES, AGENCY_AGENT } = require("./authz");
const { writeAuditLog } = require("./audit_log");

// A Firestore document id the rules and queries can use as an agency id.
const AGENCY_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;

/**
 * Writes the role (and agency for AgencyAdmin) into the user's custom claims and
 * mirrors it onto Users/{uid} so the app can keep reading the role from the profile.
 * Other existing custom claims are preserved.
 *
 * An AgencyAdmin needs an id of a real agency (`Agencies/{agencyId}` must exist). Moving a user off
 * AgencyAdmin removes `agency_id` from both the claim and the profile. When the role or agency
 * changes, the user's refresh tokens are revoked (TAQ-148), so the client cannot mint a new ID token
 * with the old role. What that does and does not cover (TAQ-158):
 * - Callables that use requireFreshAuth (authz.js) re-verify the caller's ID token with
 *   checkRevoked=true, so they refuse an ID token issued before the revocation right away.
 * - Firestore and Storage security rules cannot check revocation. An ID token that was issued before
 *   the change keeps its old role/agency_id claims in the rules until it expires, at most one hour.
 */
async function applyUserRole({ uid, role, agencyId, actorUid, allowAgencyAgent = false }) {
  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "A user id is required.");
  }
  // TAQ-169: AgencyAgent is never assignable through setUserRole; only the invite flow
  // (agency_team.js) passes allowAgencyAgent.
  const agentGrant = allowAgencyAgent === true && role === AGENCY_AGENT;
  if (!ASSIGNABLE_ROLES.includes(role) && !agentGrant) {
    throw new HttpsError("invalid-argument", `Role must be one of: ${ASSIGNABLE_ROLES.join(", ")}.`);
  }
  const needsAgency = role === "AgencyAdmin" || agentGrant;
  if (needsAgency && (!agencyId || typeof agencyId !== "string")) {
    throw new HttpsError("invalid-argument", `An agencyId is required for ${role}.`);
  }
  if (needsAgency && !AGENCY_ID_PATTERN.test(agencyId)) {
    throw new HttpsError("invalid-argument", "The agencyId is not a valid agency id.", { reason: "agency_id_invalid" });
  }
  if (needsAgency) {
    const agency = await admin.firestore().collection("Agencies").doc(agencyId).get();
    if (!agency.exists) {
      throw new HttpsError("failed-precondition", "That agency does not exist.", { reason: "agency_not_found" });
    }
  }

  const user = await admin.auth().getUser(uid);
  const before = user.customClaims || {};
  const claims = { ...(user.customClaims || {}), role };
  if (needsAgency) {
    claims.agency_id = agencyId;
  } else {
    delete claims.agency_id;
  }
  await admin.auth().setCustomUserClaims(uid, claims);
  const changed = before.role !== claims.role || (before.agency_id || "") !== (claims.agency_id || "");
  if (changed) await admin.auth().revokeRefreshTokens(uid);

  const profile = {
    role,
    role_updated_at: FieldValue.serverTimestamp(),
    role_updated_by: actorUid || null,
  };
  profile.agency_id = needsAgency ? agencyId : FieldValue.delete();
  await admin.firestore().collection("Users").doc(uid).set(profile, { merge: true });
  // TAQ-193: every role assignment, from the callable, the scripts or agency approval.
  await writeAuditLog({
    action: "role_assigned",
    actorUid: actorUid || null,
    targetUid: uid,
    details: { from_role: before.role || "", to_role: role, from_agency: before.agency_id || "", to_agency: needsAgency ? agencyId : "", changed },
  });

  return { uid, role, agencyId: needsAgency ? agencyId : null };
}

module.exports = { applyUserRole };
