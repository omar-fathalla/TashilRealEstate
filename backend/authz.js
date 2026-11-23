const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const SELF_SERVICE_ROLES = ["Owner", "Tenant"];
const ASSIGNABLE_ROLES = ["Owner", "Tenant", "AgencyAdmin", "SuperAdmin"];

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  return request.auth;
}

function claimedRole(auth) {
  return (auth.token && auth.token.role) || "";
}

/**
 * Mirrors currentRole() in firestore.rules: a custom claim wins, and the profile
 * document is only trusted for self-service roles.
 */
async function resolveRole(auth) {
  const claim = claimedRole(auth);
  if (claim) return claim;
  const snap = await admin.firestore().collection("Users").doc(auth.uid).get();
  const profileRole = snap.exists ? snap.get("role") : "";
  return SELF_SERVICE_ROLES.includes(profileRole) ? profileRole : "";
}

async function requireRole(auth, roles) {
  const role = await resolveRole(auth);
  if (!roles.includes(role)) {
    throw new HttpsError("permission-denied", "This action is not allowed for your role.");
  }
  return role;
}

module.exports = {
  SELF_SERVICE_ROLES,
  ASSIGNABLE_ROLES,
  requireAuth,
  resolveRole,
  requireRole,
};
