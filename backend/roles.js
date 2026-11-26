const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { ASSIGNABLE_ROLES } = require("./authz");

// A Firestore document id the rules and queries can use as an agency id.
const AGENCY_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;

/**
 * Writes the role (and agency for AgencyAdmin) into the user's custom claims and
 * mirrors it onto Users/{uid} so the app can keep reading the role from the profile.
 * Other existing custom claims are preserved.
 *
 * An AgencyAdmin needs an id of a real agency (`Agencies/{agencyId}` must exist). Moving a user off
 * AgencyAdmin removes `agency_id` from both the claim and the profile. When the role or agency
 * changes, the user's refresh tokens are revoked, so a demoted or moved admin does not keep the old
 * access until the one-hour token expires (TAQ-148).
 */
async function applyUserRole({ uid, role, agencyId, actorUid }) {
  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "A user id is required.");
  }
  if (!ASSIGNABLE_ROLES.includes(role)) {
    throw new HttpsError("invalid-argument", `Role must be one of: ${ASSIGNABLE_ROLES.join(", ")}.`);
  }
  const needsAgency = role === "AgencyAdmin";
  if (needsAgency && (!agencyId || typeof agencyId !== "string")) {
    throw new HttpsError("invalid-argument", "An agencyId is required for AgencyAdmin.");
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

  return { uid, role, agencyId: needsAgency ? agencyId : null };
}

module.exports = { applyUserRole };
