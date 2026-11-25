/**
 * Lease creation, the tenant's decision and the one-live-lease-per-property lock (TAQ-110).
 *
 * Clients never create a lease and never make one `active` (firestore.rules). Leases are created
 * here (`createLease`) or from an approved application (`createLeaseFromApplication`), and only
 * `respondToLeaseOffer` activates one, inside a transaction that takes
 * `PropertyLeaseLocks/{propertyId}`. The lock doc id is the property, so two acceptances for the
 * same property cannot both win. A lock whose lease is no longer live (leaseLiveState) is stale and
 * may be taken over; `releasePropertyLeaseLock` deletes the lock when its lease leaves `active`.
 *
 * Every path re-checks the property against the lease parties (verifyLeaseProperty): the property
 * exists in the owner's private tree, the owner can let property, and the agency on the lease is
 * the owner's agency by claims AND by the property doc. Owners of agency-managed properties cannot
 * lease them themselves; the agency does.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { requireAuth, requireRole, resolveUserAuthority, leaseAmount } = require("./authz");
const { appCheckEnforced } = require("./config");
const { leaseLiveState, assertLeasePayable } = require("./lease_state");

const ENFORCE_APP_CHECK = appCheckEnforced();
const LOCKS = "PropertyLeaseLocks";
const LANDLORD_ROLES = ["Owner", "AgencyAdmin", "SuperAdmin"];
const NOTE_MAX = 500;
const MAX_RENT = 1e9;
const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

const deps = { now: () => Date.now() };

function precondition(message, reason, extra = {}) {
  return new HttpsError("failed-precondition", message, { reason, ...extra });
}

function validId(value) {
  return typeof value === "string" && value.length > 0 && value.length <= 200 && !value.includes("/");
}

function requireId(value, field) {
  if (!validId(value)) throw new HttpsError("invalid-argument", `${field} is required.`);
  return value;
}

function parseDateOnly(value, field) {
  const match = typeof value === "string" ? DATE_ONLY.exec(value) : null;
  const date = match ? new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]))) : null;
  if (!date || Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new HttpsError("invalid-argument", `${field} must be a date in the form YYYY-MM-DD.`);
  }
  return date;
}

function requireMoney(value, field) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 || value > MAX_RENT) {
    throw new HttpsError("invalid-argument", `${field} must be a positive number.`);
  }
  return Math.round(value * 100) / 100;
}

function cleanNote(value) {
  if (value === undefined || value === null || value === "") return "";
  if (typeof value !== "string") throw new HttpsError("invalid-argument", "note must be text.");
  return value.replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim().slice(0, NOTE_MAX);
}

/**
 * The property behind [lease] belongs to the lease's owner and, when the lease names an agency,
 * that agency manages it: by the owner's claims (resolveUserAuthority) and by the private property
 * doc's `agency_id`. A lease without an agency needs a property no agency manages. Reads go
 * through [t] so a transaction sees them; returns the private property snapshot.
 */
async function verifyLeaseProperty(t, db, lease) {
  if (!validId(lease.property_id)) throw precondition("The lease has no property.", "lease_missing_property");
  if (!validId(lease.owner_id)) throw precondition("The lease has no owner.", "lease_missing_owner");
  const silo = await t.get(db.collection("Users").doc(lease.owner_id).collection("properties").doc(lease.property_id));
  if (!silo.exists) throw precondition("This property does not belong to the lease's owner.", "property_not_found");
  const authority = await resolveUserAuthority(lease.owner_id);
  if (!LANDLORD_ROLES.includes(authority.role)) throw precondition("The lease's owner cannot let property.", "owner_not_landlord");
  const agency = typeof lease.agency_id === "string" ? lease.agency_id : "";
  const siloAgency = typeof silo.get("agency_id") === "string" ? silo.get("agency_id") : "";
  if (agency) {
    if (authority.agencyId !== agency || siloAgency !== agency) {
      throw precondition("This agency does not manage this property.", "property_not_managed");
    }
  } else if (authority.agencyId || siloAgency) {
    throw precondition("An agency manages this property; the agency creates its leases.", "property_agency_managed");
  }
  return silo;
}

/**
 * The lock on the lease's property, read in [t]. `heldByOther` is set when another live lease
 * holds it; a lock whose lease is gone, moved or no longer live is stale and counts as free.
 */
async function readPropertyLock(t, db, lease, nowMs) {
  if (!validId(lease.property_id)) throw precondition("The lease has no property.", "lease_missing_property");
  const ref = db.collection(LOCKS).doc(lease.property_id);
  const snap = await t.get(ref);
  if (!snap.exists) return { ref, mine: false, heldByOther: "" };
  const holderId = snap.get("lease_id");
  if (lease.id && holderId === lease.id) return { ref, mine: true, heldByOther: "" };
  if (!validId(holderId)) return { ref, mine: false, heldByOther: "" };
  const holderSnap = await t.get(db.collection("Leases").doc(holderId));
  const holder = holderSnap.exists ? holderSnap.data() : null;
  const live = holder && holder.property_id === lease.property_id && leaseLiveState(holder, nowMs).live;
  return { ref, mine: false, heldByOther: live ? holderId : "", stale: live ? "" : holderId };
}

function writePropertyLock(t, ref, lease, nowMs, by) {
  t.set(ref, {
    lease_id: lease.id,
    property_id: lease.property_id,
    tenant_id: lease.tenant_id || "",
    owner_id: lease.owner_id || "",
    agency_id: lease.agency_id || "",
    claimed_by: by,
    claimed_at: Timestamp.fromMillis(nowMs),
  });
}

function alreadyLeased(holderId) {
  return precondition("This property already has an active lease.", "property_already_leased", { leaseId: holderId });
}

/**
 * For the payment paths: re-reads the lease in [t], requires it to be payable, and makes sure it
 * holds its property's lock. A live lease without a lock (older data) claims it here once its
 * property checks pass; a lease whose property another live lease holds is refused. Returns the
 * lease and a `claim` to call after the transaction's reads.
 */
async function leaseForPayment(t, db, leaseId, nowMs, by) {
  const snap = await t.get(db.collection("Leases").doc(leaseId));
  if (!snap.exists) throw new HttpsError("not-found", "Lease not found.");
  const lease = { id: snap.id, ...snap.data() };
  assertLeasePayable(lease, nowMs);
  const lock = await readPropertyLock(t, db, lease, nowMs);
  if (lock.mine) return { lease, claim: () => {} };
  if (lock.heldByOther) {
    throw precondition("Another active lease holds this property; this lease cannot take payments.", "lease_not_verified", { leaseId: lock.heldByOther });
  }
  await verifyLeaseProperty(t, db, lease);
  return { lease, claim: () => writePropertyLock(t, lock.ref, lease, nowMs, by) };
}

function tenantNameOf(profile) {
  const name = profile && (profile.full_name || profile.fullName || profile.name);
  return typeof name === "string" ? name.trim().slice(0, 100) : "";
}

function titleOf(silo) {
  const titles = silo.get("titles");
  const fromTitles = titles && typeof titles === "object" ? titles.en || titles.ar || titles.hi : "";
  const value = fromTitles || silo.get("title") || "";
  return typeof value === "string" ? value.slice(0, 200) : "";
}

/**
 * Creates a lease (draft, or straight to the tenant as an offer) for a property the caller lets:
 *  - Owner: their own property that no agency manages; the owner is always the caller.
 *  - AgencyAdmin: a property of `ownerId` that the caller's agency manages.
 *  - SuperAdmin: any `ownerId`, with the agency taken from that owner (never from the caller).
 * The tenant must be a Tenant account. Rent and dates are checked here; the lock is not taken yet
 * (only the tenant's acceptance does), but a property that already has a live lease is refused.
 */
const createLease = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const role = await requireRole(auth, LANDLORD_ROLES);
  const data = request.data || {};
  const propertyId = requireId(data.propertyId, "propertyId");
  const tenantId = requireId(data.tenantId, "tenantId");
  const ownerId = role === "Owner" ? auth.uid : requireId(data.ownerId, "ownerId");
  const start = parseDateOnly(data.startDate, "startDate");
  const end = parseDateOnly(data.endDate, "endDate");
  if (end.getTime() <= start.getTime()) throw new HttpsError("invalid-argument", "endDate must be after startDate.");
  const rent = requireMoney(data.monthlyRent, "monthlyRent");
  if (tenantId === ownerId || tenantId === auth.uid) {
    throw new HttpsError("invalid-argument", "The tenant cannot be the owner or the caller.");
  }
  const status = data.sendOffer === true ? "pending_tenant_approval" : "draft";

  const ownerAuthority = await resolveUserAuthority(ownerId);
  const agencyId = ownerAuthority.agencyId;
  if (role === "AgencyAdmin") {
    const callerAgency = auth.token && auth.token.agency_id;
    if (!callerAgency || agencyId !== callerAgency) {
      throw new HttpsError("permission-denied", "Your agency does not manage this owner's property.", { reason: "property_not_managed" });
    }
  }
  const tenantAuthority = await resolveUserAuthority(tenantId);
  if (tenantAuthority.role !== "Tenant") throw precondition("The tenant must be a tenant account.", "tenant_not_found");

  const db = admin.firestore();
  const ref = db.collection("Leases").doc();
  const now = deps.now();
  const parties = { id: ref.id, owner_id: ownerId, tenant_id: tenantId, agency_id: agencyId, property_id: propertyId };
  await db.runTransaction(async (t) => {
    const silo = await verifyLeaseProperty(t, db, parties);
    const lock = await readPropertyLock(t, db, parties, now);
    if (lock.heldByOther) throw alreadyLeased(lock.heldByOther);
    const tenantProfile = await t.get(db.collection("Users").doc(tenantId));
    const country = String(silo.get("countryCode") || silo.get("country_code") || "").toUpperCase();
    if (country !== "AE" && country !== "EG") throw precondition("The property has no supported country.", "property_country_missing");
    t.create(ref, {
      owner_id: ownerId,
      tenant_id: tenantId,
      agency_id: agencyId,
      property_id: propertyId,
      status,
      country_code: country,
      currencyCode: country === "AE" ? "AED" : "EGP",
      monthly_rent: rent,
      financialTerms: { monthlyRent: rent },
      start_date: data.startDate,
      end_date: data.endDate,
      property_title: titleOf(silo),
      tenant_name: tenantNameOf(tenantProfile.exists ? tenantProfile.data() : null),
      created_by: auth.uid,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
  });
  return { success: true, leaseId: ref.id, status };
});

/** The offer's terms are complete and still in force: positive rent and a valid, unfinished range. */
function assertOfferTerms(lease, nowMs) {
  leaseAmount(lease);
  const startOk = typeof lease.start_date === "string" && DATE_ONLY.test(lease.start_date);
  const endOk = typeof lease.end_date === "string" && DATE_ONLY.test(lease.end_date);
  if (!startOk || !endOk || lease.end_date <= lease.start_date) {
    throw precondition("The lease offer has no valid dates.", "lease_dates_invalid");
  }
  if (!leaseLiveState({ ...lease, status: "active" }, nowMs).live) {
    throw precondition("This lease offer has already ended.", "offer_expired");
  }
}

/**
 * The tenant's answer to a lease offer. `approve` activates the lease only if its property checks
 * still pass and no other live lease holds the property, and takes the property lock in the same
 * transaction; `reject` closes the offer. Nothing else on the lease changes.
 */
const respondToLeaseOffer = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const data = request.data || {};
  const leaseId = requireId(data.leaseId, "leaseId");
  if (!["approve", "reject"].includes(data.decision)) {
    throw new HttpsError("invalid-argument", "decision must be approve or reject.");
  }
  const note = cleanNote(data.note);
  const db = admin.firestore();
  const ref = db.collection("Leases").doc(leaseId);
  const now = deps.now();
  const status = await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Lease not found.");
    const lease = { id: snap.id, ...snap.data() };
    if (lease.tenant_id !== auth.uid || lease.owner_id === auth.uid) {
      throw new HttpsError("permission-denied", "Only the lease's tenant can answer this offer.");
    }
    if (lease.status !== "pending_tenant_approval") {
      throw precondition("This lease is not waiting for your answer.", "not_pending");
    }
    const decided = { tenant_decision_note: note, decided_at: Timestamp.fromMillis(now), updated_at: FieldValue.serverTimestamp() };
    if (data.decision === "reject") {
      t.update(ref, { status: "rejected", ...decided });
      return "rejected";
    }
    assertOfferTerms(lease, now);
    const silo = await verifyLeaseProperty(t, db, lease);
    const lock = await readPropertyLock(t, db, lease, now);
    if (lock.heldByOther) throw alreadyLeased(lock.heldByOther);
    t.update(ref, { status: "active", activated_at: Timestamp.fromMillis(now), ...decided });
    writePropertyLock(t, lock.ref, lease, now, auth.uid);
    // The private listing is marked rented and unpublished in the same transaction. The sync
    // trigger then takes the public doc offline (status rented), so search, viewing requests and
    // applications exclude it. isPublished is the owner's wish and `available` + published goes
    // live on its own, so it is cleared here; the owner publishes again after the lease ends.
    t.update(silo.ref, { rentalStatus: "rented", isPublished: false, updated_at: FieldValue.serverTimestamp() });
    if (lock.stale) logger.info("Took over a stale property lock", { propertyId: lease.property_id, from: lock.stale, to: lease.id });
    return "active";
  });
  return { success: true, status };
});

/**
 * Releases the property lock when its lease stops being active (or is deleted). When the lock was
 * this lease's, the private listing goes back to `available` if it was `rented`. It is NOT
 * republished: isPublished stays as the activation left it, so the owner decides when to list again.
 */
async function handleLeaseLockRelease(event) {
  const before = event.data && event.data.before;
  const after = event.data && event.data.after;
  if (!before || !before.exists) return null;
  const was = before.data() || {};
  if (was.status !== "active" || !validId(was.property_id)) return null;
  const now = after && after.exists ? after.data() || {} : null;
  if (now && now.status === "active" && now.property_id === was.property_id) return null;
  const leaseId = event.params.leaseId;
  const db = admin.firestore();
  const ref = db.collection(LOCKS).doc(was.property_id);
  const siloRef = validId(was.owner_id) ? db.collection("Users").doc(was.owner_id).collection("properties").doc(was.property_id) : null;
  return db.runTransaction(async (t) => {
    const lock = await t.get(ref);
    if (!lock.exists || lock.get("lease_id") !== leaseId) return false;
    const silo = siloRef ? await t.get(siloRef) : null;
    t.delete(ref);
    if (silo && silo.exists && silo.get("rentalStatus") === "rented") {
      t.update(siloRef, { rentalStatus: "available", updated_at: FieldValue.serverTimestamp() });
    }
    return true;
  });
}

const releasePropertyLeaseLock = onDocumentWritten("Leases/{leaseId}", handleLeaseLockRelease);

module.exports = {
  LOCKS,
  deps,
  createLease,
  respondToLeaseOffer,
  releasePropertyLeaseLock,
  handleLeaseLockRelease,
  verifyLeaseProperty,
  readPropertyLock,
  writePropertyLock,
  leaseForPayment,
  alreadyLeased,
};
