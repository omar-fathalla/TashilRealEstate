/**
 * The contact fields of a public listing (TAQ-150/154), with no side effects: requiring this
 * module does not touch firebase-admin, so the functions and the backfill script
 * (scripts/backfill_listing_contact.js, TAQ-161) share one definition.
 */
const { stripContacts } = require("./contact_filter");

const MARKETPLACE_LOCALES = ["ar", "en", "hi"];

function cleanText(value, maxLength) {
  return typeof value === "string" ? stripContacts(value).trim().slice(0, maxLength).trim() : "";
}

// Keeps only the ar/en/hi string entries; any other nested key is dropped.
function localizedText(map, flatFallback, maxLength) {
  const source = map && typeof map === "object" && !Array.isArray(map) ? map : null;
  const result = {};
  for (const locale of MARKETPLACE_LOCALES) {
    result[locale] = cleanText(source ? source[locale] : flatFallback, maxLength);
  }
  return result;
}

// Listings from the owner tree are contacted through the platform, never the owner directly:
// visitors use the viewing and rental request buttons, so a listing carries no phone number
// (TAQ-150). A listing of an agency shows that agency's own name instead, and its ORN once a
// SuperAdmin has verified the licence (TAQ-154).
const PLATFORM_AGENCY_NAMES = {
  ar: "تسهيل عقار",
  en: "Tashil Real Estate",
  hi: "ताशिल रियल एस्टेट",
};
const PLATFORM_AGENCY_PHONE = "";
const AGENCY_ORN_PATTERN = /^[A-Za-z0-9/ -]{1,40}$/;

/**
 * The public face of an agency for its listings, from Agencies/{agencyId}: localized display
 * names (contact-free, falling back to `name`) and the ORN, only when the badge is on.
 * Returns null when the agency has no usable name, so the platform name is shown instead.
 */
function agencyListingIdentity(agencyData) {
  if (!agencyData || typeof agencyData !== "object") return null;
  const names = localizedText(agencyData.names, agencyData.name, 200);
  const fallback = cleanText(agencyData.name, 200) || MARKETPLACE_LOCALES.map((l) => names[l]).find(Boolean);
  if (!fallback) return null;
  for (const locale of MARKETPLACE_LOCALES) {
    if (!names[locale]) names[locale] = fallback;
  }
  const orn = typeof agencyData.orn === "string" ? agencyData.orn.trim() : "";
  const verified = agencyData.verified_badge === true && AGENCY_ORN_PATTERN.test(orn);
  return { names, orn: verified ? orn : "" };
}

/** The contact fields of a public listing: the agency's identity, or the platform's. */
function listingContactFields(agency) {
  const fields = {
    agencyNames: agency ? agency.names : PLATFORM_AGENCY_NAMES,
    agencyPhone: PLATFORM_AGENCY_PHONE,
  };
  if (agency && agency.orn) fields.agencyOrn = agency.orn;
  return fields;
}
module.exports = {
  MARKETPLACE_LOCALES,
  cleanText,
  localizedText,
  PLATFORM_AGENCY_NAMES,
  PLATFORM_AGENCY_PHONE,
  AGENCY_ORN_PATTERN,
  agencyListingIdentity,
  listingContactFields,
};
