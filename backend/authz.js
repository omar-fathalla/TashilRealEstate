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
  requireAuth,
  resolveRole,
  requireRole,
  loadLease,
  leaseAmount,
  leaseCountry,
  assertLeaseParty,
};
