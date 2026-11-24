const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Roles a user may pick for themselves at signup. They are only read from the profile document
// (or a claim); a profile can never vouch for any other role, so none of these escalates.
const SELF_SERVICE_ROLES = ["Owner", "Tenant", "Investor"];
// Roles setUserRole (SuperAdmin only) can grant as custom claims.
const ASSIGNABLE_ROLES = ["Owner", "Tenant", "Investor", "AgencyAdmin", "Admin", "SuperAdmin"];
// Roles whose private listings the sync trigger publishes to the marketplace.
const PUBLISHER_ROLES = ["Owner", "AgencyAdmin", "SuperAdmin"];
// Platform staff who moderate listings and read the sanitized user directory. Admin is the
// restricted platform role; SuperAdmin keeps everything Admin can do.
const PLATFORM_STAFF_ROLES = ["Admin", "SuperAdmin"];

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

/**
 * resolveRole for a uid with no request token (triggers): reads custom claims via the Admin SDK.
 * agencyId is only trusted from the claims of an AgencyAdmin.
 */
async function resolveUserAuthority(uid) {
  let claims = {};
  try {
    claims = (await admin.auth().getUser(uid)).customClaims || {};
  } catch (err) {
    if (err.code !== "auth/user-not-found") throw err;
  }
  const role = await resolveRole({ uid, token: claims });
  const agencyId = role === "AgencyAdmin" && typeof claims.agency_id === "string" ? claims.agency_id : "";
  return { role, agencyId };
}

async function resolveUserRole(uid) {
  return (await resolveUserAuthority(uid)).role;
}

async function requireRole(auth, roles) {
  const role = await resolveRole(auth);
  if (!roles.includes(role)) {
    throw new HttpsError("permission-denied", "This action is not allowed for your role.");
  }
  return role;
}

async function loadLease(leaseId) {
  if (!leaseId || typeof leaseId !== "string") {
    throw new HttpsError("invalid-argument", "A lease id is required.");
  }
  const snap = await admin.firestore().collection("Leases").doc(leaseId).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Lease not found.");
  }
  return { id: snap.id, ...snap.data() };
}

function leaseAmount(lease) {
  const terms = lease.financialTerms || {};
  const monthly = Number(terms.monthlyRent || lease.monthly_rent || lease.baseAmount || 0);
  if (monthly > 0) return monthly;
  const annual = Number(terms.annualRent || 0);
  if (annual > 0) return Math.round((annual / 12) * 100) / 100;
  throw new HttpsError("failed-precondition", "The lease has no server-side rent amount.");
}

function leaseCountry(lease) {
  const code = String(lease.country_code || lease.countryCode || "").toUpperCase();
  if (code !== "EG" && code !== "AE") {
    throw new HttpsError("failed-precondition", "The lease has no supported country code.");
  }
  return code;
}

/**
 * Allows the lease's landlord, the agency that manages it, or a SuperAdmin.
 * Pass allowTenant to also accept the lease's tenant.
 */
function assertLeaseParty(auth, role, lease, { allowTenant = false } = {}) {
  const uid = auth.uid;
  if (role === "SuperAdmin") return;
  if (lease.owner_id && lease.owner_id === uid) return;
  if (allowTenant && lease.tenant_id && lease.tenant_id === uid) return;
  const agencyId = auth.token && auth.token.agency_id;
  if (role === "AgencyAdmin" && agencyId && lease.agency_id === agencyId) return;
  throw new HttpsError("permission-denied", "You are not a party to this lease.");
}

module.exports = {
  SELF_SERVICE_ROLES,
  ASSIGNABLE_ROLES,
  PUBLISHER_ROLES,
  PLATFORM_STAFF_ROLES,
  requireAuth,
  resolveRole,
  resolveUserRole,
  resolveUserAuthority,
  requireRole,
  loadLease,
  leaseAmount,
  leaseCountry,
  assertLeaseParty,
};
