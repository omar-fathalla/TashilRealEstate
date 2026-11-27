/**
 * Which agency manages a property (TAQ-149). Pure reads, no side effects, so leases.js, the
 * marketplace sync and the mandate callables can all share it:
 *
 * - An AgencyAdmin owner's own property: the agency in the owner's claims (as before).
 * - Any other owner's property: the agency of an `active` mandate in `PropertyMandates/{propertyId}`
 *   for that same owner. Mandates are written only by the callables in mandates.js.
 * - Otherwise none: the owner lets the property themselves.
 */
const { getFirestore } = require("firebase-admin/firestore");

const MANDATES = "PropertyMandates";
const AGENCY_ID = /^[A-Za-z0-9_-]{1,128}$/;

/** The agency an active mandate doc gives, or "" (wrong owner, not active, bad id, missing). */
function mandateAgency(data, ownerId) {
  if (!data || data.status !== "active" || data.owner_id !== ownerId) return "";
  return typeof data.agency_id === "string" && AGENCY_ID.test(data.agency_id) ? data.agency_id : "";
}

/**
 * The managing agency of [propertyId] for [ownerId], given the owner's resolved [authority]
 * ({ role, agencyId }). Reads through [t] (a transaction) when given.
 * Returns { agencyId, via: "claim" | "mandate" | "" }.
 */
async function managingAgency(t, db, ownerId, propertyId, authority) {
  if (authority && authority.agencyId) return { agencyId: authority.agencyId, via: "claim" };
  if (typeof propertyId !== "string" || !AGENCY_ID.test(propertyId)) return { agencyId: "", via: "" };
  const ref = (db || getFirestore()).collection(MANDATES).doc(propertyId);
  const snap = t ? await t.get(ref) : await ref.get();
  const agencyId = snap.exists ? mandateAgency(snap.data(), ownerId) : "";
  return { agencyId, via: agencyId ? "mandate" : "" };
}

module.exports = { MANDATES, AGENCY_ID, mandateAgency, managingAgency };
