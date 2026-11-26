/**
 * The property owner registry (TAQ-110, N-1).
 *
 * Private property ids are global: any owner could create Users/{self}/properties/{someone's id}.
 * `PropertyOwners/{propertyId}` records the one owner an id belongs to. It is written only here
 * (Admin SDK; no client access in firestore.rules):
 *  - when a private property doc is created and the id is not registered yet, its owner claims it
 *    (first creator wins). Deleting the private doc does not free the id; the same owner may
 *    create it again, nobody else can (the rules refuse, and the claim marks it `id_conflict`).
 *  - the backfill script registers ids that existed before the registry (dev / demo only).
 * A private doc whose id is registered to another owner, or whose public listing belongs to another
 * owner, is marked `id_conflict: true` and an admin alert is raised. Such a doc never syncs,
 * publishes or leases. Clients cannot write or clear `id_conflict`.
 *
 * Lease and payment paths call `verifyPropertyOwnership`, which fails closed: an id that is not
 * registered (`property_not_registered`) or registered to someone else (`property_id_conflict`)
 * cannot be leased or paid. There is no lazy claim on those paths.
 */
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { HttpsError } = require("firebase-functions/v2/https");
const { PUBLISHER_ROLES, resolveUserAuthority } = require("./authz");

const REGISTRY = "PropertyOwners";
const ALERTS = "AdminAlerts";

function registryRef(db, propertyId) {
  return db.collection(REGISTRY).doc(propertyId);
}

function siloRef(db, ownerId, propertyId) {
  return db.collection("Users").doc(ownerId).collection("properties").doc(propertyId);
}

function precondition(message, reason) {
  return new HttpsError("failed-precondition", message, { reason });
}

/**
 * Inside transaction [t]: the property id is registered to [lease.owner_id], the private doc
 * [silo] is not flagged, and the public listing (if any) has the same owner and agency.
 * Returns the registered owner id.
 */
async function verifyPropertyOwnership(t, db, lease, silo) {
  const reg = await t.get(registryRef(db, lease.property_id));
  const pub = await t.get(db.collection("Properties").doc(lease.property_id));
  if (!reg.exists) throw precondition("This property is not registered to an owner yet.", "property_not_registered");
  if (reg.get("owner_id") !== lease.owner_id || (silo && silo.get("id_conflict") === true)) {
    throw precondition("This property id belongs to another owner.", "property_id_conflict");
  }
  if (pub.exists) {
    const pubAgency = typeof pub.get("agency_id") === "string" ? pub.get("agency_id") : "";
    const leaseAgency = typeof lease.agency_id === "string" ? lease.agency_id : "";
    if (pub.get("owner_id") !== lease.owner_id || pubAgency !== leaseAgency) {
      throw precondition("The public listing for this property belongs to another owner or agency.", "property_id_conflict");
    }
  }
  return reg.get("owner_id");
}

/** The registered owner of [propertyId] read in [t], or "" when the id is not registered. */
async function registeredOwner(t, db, propertyId) {
  const reg = await t.get(registryRef(db, propertyId));
  return reg.exists ? reg.get("owner_id") || "" : "";
}

/**
 * The uids (other than [ownerId]) with an unflagged private doc for [propertyId], found through the
 * `id` field every app-written private doc carries (collection group query on `properties.id`, see
 * the fieldOverride in firestore.indexes.json). A failed query throws, so the trigger fails closed
 * (nothing is claimed or synced) instead of claiming blind. Docs without an `id` field are not seen
 * here; the backfill covers them.
 */
async function otherPrivateHolders(t, db, ownerId, propertyId) {
  const snap = await t.get(db.collectionGroup("properties").where("id", "==", propertyId));
  const uids = [];
  for (const d of snap.docs) {
    const users = d.ref.parent.parent;
    if (d.id !== propertyId || !users || !users.parent || users.parent.id !== "Users" || users.parent.parent) continue;
    if (users.id !== ownerId && d.get("id_conflict") !== true) uids.push(users.id);
  }
  return uids.sort();
}

/**
 * Runs for every write to a private property doc, before the marketplace sync. Returns
 * `{ blocked }`: true when the doc must not sync (it is, or has just been, marked id_conflict).
 *  - create by a publishing role (Owner, AgencyAdmin, SuperAdmin), id free and no other owner's
 *    real public listing: the owner claims the id. Other roles never claim (tenants do not let).
 *  - id registered to someone else, or created over another owner's real public listing (an
 *    unpublished placeholder [isPlaceholder] does not count): the doc is marked id_conflict and
 *    an alert is raised once.
 *  - id not registered and another owner's private doc already has it (TAQ-126, not yet backfilled):
 *    the same flag; the newcomer never claims a legacy id.
 *  - id not registered and not a create (a doc older than the registry): left for the backfill.
 */
async function claimOrCheckOwner(ownerId, propertyId, { created, isPlaceholder = async () => false }) {
  const canClaim = created && PUBLISHER_ROLES.includes((await resolveUserAuthority(ownerId)).role);
  const db = admin.firestore();
  const ref = registryRef(db, propertyId);
  const priv = siloRef(db, ownerId, propertyId);
  const pubRef = db.collection("Properties").doc(propertyId);
  const result = await db.runTransaction(async (t) => {
    const reg = await t.get(ref);
    const silo = await t.get(priv);
    const pub = await t.get(pubRef);
    // Before the backfill, a legacy private-only id has no registry entry. A create of that id by
    // someone else must not claim it while the real owner's private doc exists (TAQ-126).
    const rivals = created && !reg.exists
      ? await otherPrivateHolders(t, db, ownerId, propertyId)
      : [];
    if (!silo.exists) return { blocked: true, conflict: false };
    if (silo.get("id_conflict") === true) return { blocked: true, conflict: false };
    const regOwner = reg.exists ? reg.get("owner_id") : "";
    const publicOwner = pub.exists ? pub.get("owner_id") || "" : "";
    const othersPublic = Boolean(publicOwner && publicOwner !== ownerId && !(await isPlaceholder(pub)));
    if (regOwner === ownerId) return { blocked: false, conflict: false };
    if (regOwner || rivals.length || (created && othersPublic)) {
      t.update(priv, { id_conflict: true, id_conflict_at: FieldValue.serverTimestamp() });
      t.set(db.collection(ALERTS).doc(`property_id_conflict_${propertyId}_${ownerId}`), {
        type: "PROPERTY_ID_CONFLICT",
        status: "open",
        property_id: propertyId,
        claimant_id: ownerId,
        registered_owner_id: regOwner || "",
        public_owner_id: publicOwner,
        private_holder_ids: rivals,
        created_at: FieldValue.serverTimestamp(),
      });
      return { blocked: true, conflict: true, regOwner, publicOwner, rivals };
    }
    if (canClaim) {
      t.create(ref, { owner_id: ownerId, property_id: propertyId, claimed_at: FieldValue.serverTimestamp(), claimed_by: "create" });
      return { blocked: false, conflict: false, claimed: true };
    }
    return { blocked: false, conflict: false };
  });
  if (result.conflict) {
    logger.warn("Property id already belongs to another owner; private doc flagged id_conflict", {
      propertyId, claimantId: ownerId, registeredOwnerId: result.regOwner || "", publicOwnerId: result.publicOwner || "", privateHolderIds: result.rivals || [],
    });
  }
  return result;
}

module.exports = { REGISTRY, registryRef, verifyPropertyOwnership, registeredOwner, claimOrCheckOwner };
