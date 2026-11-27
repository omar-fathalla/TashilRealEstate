/**
 * Owner-to-agency mandates (TAQ-149). An agency manages another owner's property only while that
 * owner has accepted its mandate:
 *
 *   inviteMandate     AgencyAdmin  -> PropertyMandates/{propertyId} status "invited" (30 days)
 *   respondToMandate  the owner    -> "active" (accept) or "declined"
 *   revokeMandate     the owner, the agency or a SuperAdmin -> "revoked"
 *
 * Only these callables write the doc; the owner, the agency and SuperAdmin read it. While a mandate
 * is active, the agency creates the property's leases and the listing names the agency
 * (agency_mandate_state.js). An accept is refused while a live lease holds the property, and so is
 * a revoke: a running lease keeps the agency that made it. The agency fee stays the platform-wide
 * split in Settings/payment_split; there is no per-mandate commission.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { requireFreshAuth, requireRole, resolveUserAuthority } = require("./authz");
const { appCheckEnforced } = require("./config");
const { registeredOwner } = require("./property_owners");
const { readPropertyLock } = require("./leases");
const { agencyListingIdentity, listingContactFields } = require("./listing_contact");
const { MANDATES, AGENCY_ID } = require("./agency_mandate_state");

const ENFORCE_APP_CHECK = appCheckEnforced();
const INVITE_DAYS = 30;
const DAY_MS = 24 * 60 * 60 * 1000;
const deps = { now: () => Date.now() };

function precondition(message, reason) {
  return new HttpsError("failed-precondition", message, { reason });
}

function requirePropertyId(value) {
  if (typeof value !== "string" || !AGENCY_ID.test(value)) {
    throw new HttpsError("invalid-argument", "A property id is required.");
  }
  return value;
}

function millis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : 0;
}

/** An invite that is still open: status invited and not past its expiry. */
function openInvite(data, nowMs) {
  return Boolean(data && data.status === "invited" && millis(data.expires_at) > nowMs);
}

function titleOf(silo) {
  const titles = silo.get("titles");
  const value = (titles && typeof titles === "object" && (titles.en || titles.ar || titles.hi)) || silo.get("title") || "";
  return typeof value === "string" ? value.slice(0, 200) : "";
}

/**
 * Puts the agency (or, with null, the platform) on the owner's public listing and marks the private
 * doc, in [t], so the listing shows who manages it at once. The private doc write also re-runs the
 * marketplace sync, which reaches the same result from the mandate.
 */
function applyManager(t, db, mandate, agencyId, agencyData, pub) {
  const siloRef = db.collection("Users").doc(mandate.owner_id).collection("properties").doc(mandate.property_id);
  t.set(siloRef, {
    managing_agency_id: agencyId || FieldValue.delete(),
    updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (!pub.exists || pub.get("owner_id") !== mandate.owner_id) return;
  const contact = listingContactFields(agencyId ? agencyListingIdentity(agencyData) : null);
  t.set(pub.ref, {
    ...contact,
    ...(contact.agencyOrn ? {} : { agencyOrn: FieldValue.delete() }),
    agency_id: agencyId || FieldValue.delete(),
    updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });
}

const inviteMandate = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = await requireFreshAuth(request);
  await requireRole(auth, ["AgencyAdmin"]);
  const agencyId = auth.token && auth.token.agency_id;
  if (typeof agencyId !== "string" || !AGENCY_ID.test(agencyId)) {
    throw new HttpsError("permission-denied", "Your account has no agency.");
  }
  const propertyId = requirePropertyId((request.data || {}).propertyId);
  const db = admin.firestore();
  const nowMs = deps.now();

  const ownerId = await db.runTransaction((t) => registeredOwner(t, db, propertyId));
  if (!ownerId) throw precondition("This property is not registered to an owner.", "property_not_registered");
  if (ownerId === auth.uid) throw precondition("This is your own property.", "mandate_own_property");
  const owner = await resolveUserAuthority(ownerId);
  if (owner.role !== "Owner") throw precondition("Only an owner's property can be put under an agency.", "owner_not_eligible");

  return db.runTransaction(async (t) => {
    const ref = db.collection(MANDATES).doc(propertyId);
    const [snap, agency, silo] = await Promise.all([
      t.get(ref),
      t.get(db.collection("Agencies").doc(agencyId)),
      t.get(db.collection("Users").doc(ownerId).collection("properties").doc(propertyId)),
    ]);
    if (!agency.exists) throw precondition("Your agency profile does not exist yet.", "agency_not_found");
    if (!silo.exists || silo.get("id_conflict") === true) throw precondition("This property was not found.", "property_not_found");
    const current = snap.exists ? snap.data() : null;
    if (current && current.status === "active" && current.owner_id === ownerId) {
      throw precondition("An agency already manages this property.", current.agency_id === agencyId ? "mandate_already_active" : "mandate_active_other");
    }
    if (current && openInvite(current, nowMs) && current.owner_id === ownerId && current.agency_id !== agencyId) {
      throw precondition("Another agency's invite is waiting for the owner.", "mandate_pending_other");
    }
    t.set(ref, {
      property_id: propertyId,
      owner_id: ownerId,
      agency_id: agencyId,
      agency_name: String(agency.get("name") || "").slice(0, 200),
      property_title: titleOf(silo),
      country_code: String(silo.get("countryCode") || silo.get("country_code") || "").toUpperCase() === "EG" ? "EG" : "AE",
      price_per_month: Number(silo.get("pricePerMonth")) > 0 ? Math.min(Number(silo.get("pricePerMonth")), 1e9) : 0,
      status: "invited",
      invited_by: auth.uid,
      invited_at: FieldValue.serverTimestamp(),
      expires_at: Timestamp.fromMillis(nowMs + INVITE_DAYS * DAY_MS),
      updated_at: FieldValue.serverTimestamp(),
    });
    return { success: true, propertyId, status: "invited" };
  });
});

const respondToMandate = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = await requireFreshAuth(request);
  await requireRole(auth, ["Owner"]);
  const data = request.data || {};
  const propertyId = requirePropertyId(data.propertyId);
  if (typeof data.accept !== "boolean") throw new HttpsError("invalid-argument", "accept must be true or false.");
  const db = admin.firestore();
  const nowMs = deps.now();

  return db.runTransaction(async (t) => {
    const ref = db.collection(MANDATES).doc(propertyId);
    const snap = await t.get(ref);
    const mandate = snap.exists ? snap.data() : null;
    if (!mandate || mandate.owner_id !== auth.uid) throw new HttpsError("not-found", "No invite for this property.");
    if (!openInvite(mandate, nowMs)) throw precondition("This invite is no longer open.", "mandate_not_open");
    if ((await registeredOwner(t, db, propertyId)) !== auth.uid) {
      throw precondition("This property id belongs to another owner.", "property_id_conflict");
    }
    if (!data.accept) {
      t.update(ref, { status: "declined", responded_at: FieldValue.serverTimestamp(), updated_at: FieldValue.serverTimestamp() });
      return { success: true, propertyId, status: "declined" };
    }
    const lock = await readPropertyLock(t, db, { id: "", property_id: propertyId }, nowMs);
    if (lock.heldByOther) throw precondition("A live lease holds this property; end it before an agency takes over.", "mandate_lease_live");
    const [agency, pub] = await Promise.all([
      t.get(db.collection("Agencies").doc(mandate.agency_id)),
      t.get(db.collection("Properties").doc(propertyId)),
    ]);
    if (!agency.exists) throw precondition("That agency no longer exists.", "agency_not_found");
    t.update(ref, {
      status: "active",
      responded_at: FieldValue.serverTimestamp(),
      started_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    applyManager(t, db, mandate, mandate.agency_id, agency.data(), pub);
    return { success: true, propertyId, status: "active" };
  });
});

const revokeMandate = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = await requireFreshAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const propertyId = requirePropertyId((request.data || {}).propertyId);
  const db = admin.firestore();
  const nowMs = deps.now();

  return db.runTransaction(async (t) => {
    const ref = db.collection(MANDATES).doc(propertyId);
    const snap = await t.get(ref);
    const mandate = snap.exists ? snap.data() : null;
    if (!mandate) throw new HttpsError("not-found", "No mandate for this property.");
    const isOwner = mandate.owner_id === auth.uid;
    const isAgency = role === "AgencyAdmin" && auth.token && auth.token.agency_id === mandate.agency_id;
    if (!isOwner && !isAgency && role !== "SuperAdmin") throw new HttpsError("permission-denied", "You are not a party to this mandate.");
    if (mandate.status !== "active" && !openInvite(mandate, nowMs)) {
      throw precondition("This mandate is not active.", "mandate_not_open");
    }
    const wasActive = mandate.status === "active";
    let pub = null;
    if (wasActive) {
      const lock = await readPropertyLock(t, db, { id: "", property_id: propertyId }, nowMs);
      if (lock.heldByOther) throw precondition("A live lease holds this property; it keeps its agency until it ends.", "mandate_lease_live");
      pub = await t.get(db.collection("Properties").doc(propertyId));
    }
    t.update(ref, {
      status: "revoked",
      revoked_by: auth.uid,
      revoked_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    if (wasActive) applyManager(t, db, mandate, "", null, pub);
    return { success: true, propertyId, status: "revoked" };
  });
});

module.exports = { deps, inviteMandate, respondToMandate, revokeMandate, openInvite, INVITE_DAYS };
