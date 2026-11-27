/**
 * Mirrors a self-service role (Owner, Tenant, Investor) into the user's custom claims when the
 * profile first gets it (TAQ-23).
 *
 * The rules take the role from the claim first and only read `Users/{uid}` when there is no
 * claim, so a user with a claim costs no extra document read per request. This grants nothing
 * new: the rules already accept these roles from the profile, and the profile can set a
 * self-service role only once, while it has none. Elevated roles still come only from
 * setUserRole or the role_claims script. An existing role claim is never replaced. The refresh
 * token is not revoked, so the user stays signed in and the claim arrives with the next token
 * refresh. Until then the profile fallback in the rules still applies.
 */
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const { getAuth } = require("firebase-admin/auth");
const { SELF_SERVICE_ROLES } = require("./authz");

// No initializeApp here: index.js does it for the functions, and scripts/role_claims.js imports
// this module and must initialize the app with its own --project first.

/** Sets claims.role = role when role is self-service and the user has no role claim yet. */
async function grantSelfServiceClaim(uid, role, auth = getAuth()) {
  if (!SELF_SERVICE_ROLES.includes(role)) return "not_self_service";
  let user;
  try {
    user = await auth.getUser(uid);
  } catch (error) {
    if (error && error.code === "auth/user-not-found") return "no_user";
    throw error;
  }
  const claims = user.customClaims || {};
  if (typeof claims.role === "string" && claims.role !== "") return "has_claim";
  await auth.setCustomUserClaims(uid, { ...claims, role });
  return "granted";
}

const mirrorSelfServiceRole = onDocumentWritten({ document: "Users/{uid}", maxInstances: 5 }, async (event) => {
  const before = event.data && event.data.before && event.data.before.exists ? event.data.before.get("role") : undefined;
  const after = event.data && event.data.after && event.data.after.exists ? event.data.after.get("role") : undefined;
  if (!after || before === after) return null;
  const outcome = await grantSelfServiceClaim(event.params.uid, after);
  if (outcome === "granted") logger.info("Self-service role claim set", { uid: event.params.uid, role: after });
  return null;
});

module.exports = { mirrorSelfServiceRole, grantSelfServiceClaim };
