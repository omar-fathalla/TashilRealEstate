const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const ALLOWED_CONTINUE_HOSTS = new Set([
  "tashilaqar.com",
  "www.tashilaqar.com",
  "tashil-proptech-os.web.app",
  "tashil-proptech-os.firebaseapp.com",
  "localhost",
  "127.0.0.1",
]);

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  return request.auth;
}

function roleOf(auth) {
  return (auth.token && auth.token.role) || "";
}

function requireRole(auth, roles) {
  const role = roleOf(auth);
  if (!roles.includes(role)) {
    throw new HttpsError("permission-denied", "This action is not allowed for your role.");
  }
  return role;
}

function isAdmin(auth) {
  return roleOf(auth) === "SuperAdmin";
}

function safeContinueUrl(raw) {
  const fallback = process.env.APP_BASE_URL || "https://tashilaqar.com";
  if (!raw || typeof raw !== "string") return fallback;
  let parsed;
  try {
    parsed = new URL(raw);
  } catch (err) {
    throw new HttpsError("invalid-argument", "continueUrl is not a valid URL.");
  }
  if (parsed.protocol !== "https:" && parsed.hostname !== "localhost" && parsed.hostname !== "127.0.0.1") {
    throw new HttpsError("invalid-argument", "continueUrl must use HTTPS.");
  }
  if (!ALLOWED_CONTINUE_HOSTS.has(parsed.hostname)) {
    throw new HttpsError("invalid-argument", "continueUrl is not an authorized domain.");
  }
  return parsed.toString();
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

function assertLeaseParty(auth, lease) {
  const uid = auth.uid;
  const role = roleOf(auth);
  if (role === "SuperAdmin") return;
  if (lease.tenant_id === uid || lease.owner_id === uid) return;
  if (role === "AgencyAdmin" && lease.agency_id && lease.agency_id === auth.token.agency_id) return;
  throw new HttpsError("permission-denied", "You are not a party to this lease.");
}

module.exports = {
  requireAuth,
  requireRole,
  isAdmin,
  safeContinueUrl,
  loadLease,
  leaseAmount,
  assertLeaseParty,
  roleOf,
};
