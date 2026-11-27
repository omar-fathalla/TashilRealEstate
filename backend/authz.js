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

function bearerToken(rawRequest) {
  const header = rawRequest && rawRequest.headers && (rawRequest.headers.authorization || rawRequest.headers.Authorization);
  if (typeof header !== "string") return "";
  const match = /^Bearer\s+(\S+)$/i.exec(header.trim());
  return match ? match[1] : "";
}

function revokedError() {
  return new HttpsError("unauthenticated", "Your session has expired. Please sign in again.", { reason: "token_revoked" });
}

/**
 * requireAuth plus a revocation check (TAQ-158). The callable runtime only checks the ID token's
 * signature and expiry, so a token issued before revokeRefreshTokens (role change, demotion,
 * disabled or deleted account) would still work for up to an hour. Sensitive callables call this
 * instead: the caller's bearer token is re-verified with verifyIdToken(token, checkRevoked=true),
 * which rejects revoked tokens and disabled or deleted users. Any verification failure is refused.
 *
 * A deployed callable always has the raw HTTP request. Only in-process unit tests call `.run()`
 * without one; then the same check is done from the decoded token's auth_time against the user's
 * tokensValidAfterTime (if the Auth user exists).
 */
async function requireFreshAuth(request) {
  const auth = requireAuth(request);
  const raw = bearerToken(request.rawRequest);
  if (raw) {
    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(raw, true);
    } catch (err) {
      throw revokedError();
    }
    if (decoded.uid !== auth.uid) throw revokedError();
    return auth;
  }
  if (request.rawRequest) throw revokedError();
  let user;
  try {
    user = await admin.auth().getUser(auth.uid);
  } catch (err) {
    if (err.code === "auth/user-not-found") return auth;
    throw err;
  }
  if (user.disabled) throw revokedError();
  const validAfter = user.tokensValidAfterTime ? Date.parse(user.tokensValidAfterTime) : NaN;
  const authTime = auth.token && Number(auth.token.auth_time);
  if (Number.isFinite(validAfter) && Number.isFinite(authTime) && authTime * 1000 < validAfter) {
    throw revokedError();
  }
  return auth;
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

const MAX_RENT = 1e9;

/** A stored rent field: absent (undefined/null), or a finite number > 0. Anything else is refused. */
function storedRent(value) {
  if (value === undefined || value === null) return null;
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 || value > MAX_RENT) {
    throw new HttpsError("failed-precondition", "The lease rent is not a valid positive amount.", { reason: "rent_invalid" });
  }
  return value;
}

/**
 * The monthly rent the server charges. Every rent field the lease carries (monthly, annual, base,
 * financialTerms.*) must be a finite number > 0; one bad value stops the payment instead of
 * falling through to another field.
 */
function leaseAmount(lease) {
  const raw = lease.financialTerms;
  if (raw !== undefined && raw !== null && (typeof raw !== "object" || Array.isArray(raw))) {
    throw new HttpsError("failed-precondition", "The lease rent is not a valid positive amount.", { reason: "rent_invalid" });
  }
  const terms = raw || {};
  const monthly = [terms.monthlyRent, lease.monthly_rent, lease.baseAmount].map(storedRent);
  const annual = [terms.annualRent, lease.annual_rent].map(storedRent);
  const firstMonthly = monthly.find((v) => v !== null);
  if (firstMonthly !== undefined) return firstMonthly;
  const firstAnnual = annual.find((v) => v !== null);
  if (firstAnnual !== undefined) return Math.round((firstAnnual / 12) * 100) / 100;
  throw new HttpsError("failed-precondition", "The lease has no server-side rent amount.", { reason: "rent_missing" });
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
  requireFreshAuth,
  resolveRole,
  resolveUserRole,
  resolveUserAuthority,
  requireRole,
  loadLease,
  leaseAmount,
  leaseCountry,
  assertLeaseParty,
};
