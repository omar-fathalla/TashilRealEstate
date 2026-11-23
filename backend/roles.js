const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { ASSIGNABLE_ROLES } = require("./authz");

/**
 * Writes the role (and agency for AgencyAdmin) into the user's custom claims and
 * mirrors it onto Users/{uid} so the app can keep reading the role from the profile.
 * Other existing custom claims are preserved.
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

  const user = await admin.auth().getUser(uid);
  const claims = { ...(user.customClaims || {}), role };
  if (needsAgency) {
    claims.agency_id = agencyId;
  } else {
    delete claims.agency_id;
  }
  await admin.auth().setCustomUserClaims(uid, claims);

  const profile = {
    role,
    role_updated_at: FieldValue.serverTimestamp(),
    role_updated_by: actorUid || null,
  };
  if (needsAgency) profile.agency_id = agencyId;
  await admin.firestore().collection("Users").doc(uid).set(profile, { merge: true });

  return { uid, role, agencyId: needsAgency ? agencyId : null };
}

module.exports = { applyUserRole };
