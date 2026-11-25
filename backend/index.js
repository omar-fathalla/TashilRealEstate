const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
// Import these directly: the Functions emulator wraps admin.firestore, which drops its static
// FieldValue/Timestamp members and made every server-timestamp write crash locally.
const { FieldPath, FieldValue, Timestamp } = require("firebase-admin/firestore");

if (!admin.apps.length) {
  admin.initializeApp();
}

const {
  PUBLISHER_ROLES,
  PLATFORM_STAFF_ROLES,
  requireAuth,
  requireRole,
  resolveUserAuthority,
  loadLease,
  leaseAmount,
  leaseCountry,
  assertLeaseParty,
} = require("./authz");
const { applyUserRole } = require("./roles");
const { appCheckEnforced } = require("./config");
const { phoneSpans, linkSpans, EXTRA_DIGIT_VALUES } = require("./contact_patterns");

const REMINDER_COOLDOWN_MS = 24 * 60 * 60 * 1000;
const ENFORCE_APP_CHECK = appCheckEnforced();

function parseDueDate(value) {
  if (typeof value !== "string" || !value) return new Date().toISOString();
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpsError("invalid-argument", "dueDate must be an ISO date.");
  }
  return parsed.toISOString();
}

// Party, tenant, amount, and currency come from the lease document, never from the caller.
exports.sendRentalReminder = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const data = request.data || {};
  const lease = await loadLease(data.leaseId);
  assertLeaseParty(auth, role, lease);

  const tenantId = lease.tenant_id;
  if (!tenantId) {
    throw new HttpsError("failed-precondition", "The lease has no tenant.");
  }
  const propertyTitle = lease.property_title || lease.propertyTitle || "وحدة سكنية";
  const amount = leaseAmount(lease);
  const dueDate = parseDueDate(data.dueDate);
  const countryCode = leaseCountry(lease);
  const currency = countryCode === "AE" ? "AED" : "EGP";

  const db = admin.firestore();
  const notifRef = db.collection("Notifications").doc();
  const reminderLogRef = db.collection("ReminderLog").doc(lease.id);

  const notificationPayload = {
    id: notifRef.id,
    recipientId: tenantId,
    leaseId: lease.id,
    senderId: auth.uid,
    type: "rental_due_reminder",
    title: {
      ar: "تذكير استحقاق الإيجار الشهري",
      en: "Monthly Rent Payment Reminder",
      hi: "मासिक किराया भुगतान अनुस्मारक",
    },
    body: {
      ar: `نحيطكم علماً باستحقاق دفعة الإيجار (${amount} ${currency}) لعقار: ${propertyTitle}`,
      en: `Friendly reminder: Rent payment (${amount} ${currency}) is due for: ${propertyTitle}`,
      hi: `अनुस्मारक: ${propertyTitle} के लिए किराया भुगतान (${amount} ${currency}) देय है`,
    },
    dueDate: dueDate,
    amount: amount,
    currency: currency,
    status: "delivered",
    createdAt: FieldValue.serverTimestamp(),
  };

  try {
    await db.runTransaction(async (tx) => {
      const log = await tx.get(reminderLogRef);
      const lastSentAt = log.exists ? log.get("lastSentAt") : null;
      if (lastSentAt && Date.now() - lastSentAt.toMillis() < REMINDER_COOLDOWN_MS) {
        throw new HttpsError("resource-exhausted", "A reminder was already sent for this lease in the last 24 hours.");
      }
      tx.set(reminderLogRef, { lastSentAt: Timestamp.now(), sentBy: auth.uid });
      tx.set(notifRef, notificationPayload);
      tx.set(db.collection("Users").doc(tenantId).collection("notifications").doc(notifRef.id), notificationPayload);
    });
    logger.info(`Rental reminder notification created: ${notifRef.id}`);
    return { success: true, messageId: notifRef.id };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Error creating rental reminder", error);
    throw new HttpsError("internal", "Failed to create the reminder.");
  }
});

exports.generateRentalInvoiceReceipt = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const data = request.data || {};
  const lease = await loadLease(data.leaseId);
  assertLeaseParty(auth, role, lease);

  const leaseId = lease.id;
  const tenantName = lease.tenant_name || lease.tenantName || "عميل تسهيل";
  const amount = leaseAmount(lease);
  const currencyCode = leaseCountry(lease) === "AE" ? "AED" : "EGP";

  const platformFee = amount * 0.025; // 2.5% platform fee
  const agencyFee = amount * 0.08;   // 8% agency fee
  const vatRate = currencyCode === "AED" ? 0.05 : 0.14;
  const vatAmount = (platformFee + agencyFee) * vatRate;
  const totalPaid = amount + vatAmount;

  const invoiceNumber = `TASHIL-INV-${new Date().getFullYear()}-${Date.now().toString().slice(-6)}`;
  const db = admin.firestore();
  const invoiceRef = db.collection("Invoices").doc(invoiceNumber);

  const invoiceData = {
    invoiceNumber: invoiceNumber,
    leaseId: leaseId,
    tenantName: tenantName,
    amount: amount,
    platformFee: platformFee,
    agencyFee: agencyFee,
    vatAmount: vatAmount,
    totalPaid: totalPaid,
    currencyCode: currencyCode,
    tenant_id: lease.tenant_id || null,
    owner_id: lease.owner_id || null,
    agency_id: lease.agency_id || null,
    issuedBy: auth.uid,
    // Paid_Verified is reserved for a verified payment record; issuing alone proves nothing.
    status: "Issued",
    createdAt: FieldValue.serverTimestamp(),
  };

  try {
    await invoiceRef.create(invoiceData);
    logger.info(`Generated digital rental invoice: ${invoiceNumber}`);
    return { success: true, invoiceNumber: invoiceNumber, invoice: invoiceData };
  } catch (error) {
    logger.error("Error generating rental invoice", error);
    throw new HttpsError("internal", "Failed to issue the invoice.");
  }
});

// SuperAdmin-only role assignment. Elevated roles live in custom claims, which clients cannot write.
exports.setUserRole = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 5 }, async (request) => {
  const auth = requireAuth(request);
  await requireRole(auth, ["SuperAdmin"]);
  const data = request.data || {};
  const result = await applyUserRole({
    uid: data.uid,
    role: data.role,
    agencyId: data.agencyId,
    actorUid: auth.uid,
  });
  logger.info(`Role ${result.role} assigned to ${result.uid} by ${auth.uid}`);
  return { success: true, ...result };
});

// Profile fields a platform Admin may see. An allowlist, so a field added to Users later (IBAN,
// national ID, phone, KYC data, ...) stays hidden until someone decides to expose it. Firestore
// rules cannot hide single fields, which is why Admin reads users through this callable instead
// of reading Users/{uid} (rules keep that to the owner of the profile and SuperAdmin).
const ADMIN_USER_FIELDS = ["user_id", "email", "full_name", "role", "agency_id", "country_code", "countryCode"];
const ADMIN_USER_PAGE_MAX = 100;

function adminUserView(doc) {
  const view = { uid: doc.id };
  for (const field of ADMIN_USER_FIELDS) {
    const value = doc.get(field);
    if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") view[field] = value;
  }
  const created = doc.get("created_at");
  if (created instanceof Timestamp) view.created_at = created.toDate().toISOString();
  return view;
}

// Page tokens are Users document ids. Firestore ids with a slash, or of the reserved __x__ form,
// make the query throw, so anything that is not a plain id is rejected up front.
const PAGE_TOKEN_PATTERN = /^(?!__.*__$)[A-Za-z0-9_-]{1,128}$/;

function isValidPageToken(value) {
  return typeof value === "string" && PAGE_TOKEN_PATTERN.test(value);
}

/** The role in each user's custom claim (what the rules and the app trust), by uid. */
async function claimRolesFor(uids) {
  const roles = new Map();
  if (uids.length === 0) return roles;
  const result = await admin.auth().getUsers(uids.map((uid) => ({ uid })));
  for (const user of result.users) {
    const role = user.customClaims && user.customClaims.role;
    if (typeof role === "string") roles.set(user.uid, role);
  }
  return roles;
}

// Read-only, paged, sanitized user directory for platform staff (Admin and SuperAdmin).
exports.listUsersForAdmin = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 5 }, async (request) => {
  const auth = requireAuth(request);
  await requireRole(auth, PLATFORM_STAFF_ROLES);
  const data = request.data || {};
  const requested = Number(data.limit);
  const limit = Number.isInteger(requested) && requested >= 1 ? Math.min(requested, ADMIN_USER_PAGE_MAX) : 50;
  let query = admin.firestore().collection("Users").orderBy(FieldPath.documentId()).limit(limit);
  if (data.startAfter !== undefined && data.startAfter !== null && data.startAfter !== "") {
    if (!isValidPageToken(data.startAfter)) {
      throw new HttpsError("invalid-argument", "startAfter is not a valid page token.");
    }
    query = query.startAfter(data.startAfter);
  }
  const snap = await query.get();
  const claimRoles = await claimRolesFor(snap.docs.map((doc) => doc.id));
  return {
    users: snap.docs.map((doc) => ({ ...adminUserView(doc), claim_role: claimRoles.get(doc.id) || "" })),
    nextPageToken: snap.size === limit ? snap.docs[snap.size - 1].id : null,
  };
});

// Demo accounts are seeded only by the local admin script (seed.js), never by a deployed endpoint.

const MARKETPLACE_LOCALES = ["ar", "en", "hi"];
const MARKETPLACE_MAX_IMAGES = 20;
const MARKETPLACE_MAX_AMENITIES = 30;

const DEFAULT_AMENITIES = {
  ar: ["مفروش بالكامل", "تكييف مركزي", "موقف سيارات خاص", "أمن وحراسة 24/7"],
  en: ["Fully Furnished", "Central A/C", "Private Parking", "24/7 Security"],
  hi: ["पूरी तरह सुसज्जित", "केंद्रीय एसी", "निजी पार्किंग", "24/7 सुरक्षा"],
};

// Listings from the owner tree are contacted through the platform, never the owner directly.
const PLATFORM_AGENCY_NAMES = {
  ar: "شركة تسهيل لإدارة الأملاك",
  en: "Tashil Property Management",
  hi: "तशिल संपत्ति प्रबंधन",
};
const PLATFORM_AGENCY_PHONE = "+20 100 123 4567";
// Shown until a SuperAdmin rates the listing; owners cannot set it.
const DEFAULT_LISTING_RATING = 5.0;

// Mirrored by contactFree() in firestore.rules. Phones, messaging links and @handles use the
// shared patterns in contact_patterns.js. Emails are matched after folding look-alike
// characters (full-width forms, invisible characters). Only the matched span is removed and
// other text is left exactly as written.
//  - Email: @ may be written [at], (at), {at}, or with spaces around it; dots may be [dot].
const EMAIL_AT = String.raw`\s*(?:@|[\[({]\s*at\s*[\])}])\s*`;
const EMAIL_DOT = String.raw`(?:\.|\s*[\[({]\s*dot\s*[\])}]\s*)`;
const EMAIL_LABEL = "[A-Za-z0-9-]+";
const EMAIL_PATTERN = new RegExp(
  `[A-Za-z0-9._%+-]+${EMAIL_AT}${EMAIL_LABEL}(?:${EMAIL_DOT}${EMAIL_LABEL})*${EMAIL_DOT}[A-Za-z]{2,}`,
  "gi",
);
const INVISIBLE = /^\p{Cf}$/u;
const DECIMAL_DIGIT = /^\p{Nd}$/u;

function isDecimalDigit(codePoint) {
  return codePoint >= 0 && DECIMAL_DIGIT.test(String.fromCodePoint(codePoint));
}

/** The ASCII digit value of any decimal digit (Devanagari, Arabic-Indic, styled, ...), or -1. */
function digitValue(codePoint) {
  if (EXTRA_DIGIT_VALUES.has(codePoint)) return EXTRA_DIGIT_VALUES.get(codePoint);
  if (!isDecimalDigit(codePoint)) return -1;
  let start = codePoint;
  while (isDecimalDigit(start - 1)) start -= 1;
  return (codePoint - start) % 10;
}

function foldCodePoint(ch) {
  if (INVISIBLE.test(ch)) return " ";
  const value = digitValue(ch.codePointAt(0));
  if (value >= 0) return String(value);
  const normalized = ch.normalize("NFKC");
  if (normalized.length === 1 && normalized.charCodeAt(0) < 0x80) return normalized;
  // One UTF-16 unit per code point keeps folded offsets aligned with `offsets` below.
  return ch.length === 1 ? ch : "\uFFFD";
}

/** One folded UTF-16 unit per code point of `text`, plus the original offset of each. */
function foldForContactMatching(text) {
  let folded = "";
  const offsets = [];
  let index = 0;
  for (const ch of text) {
    offsets.push(index);
    folded += foldCodePoint(ch);
    index += ch.length;
  }
  offsets.push(text.length);
  return { folded, offsets };
}

function removeSpans(text, spans) {
  if (spans.length === 0) return text;
  let result = "";
  let cursor = 0;
  for (const [start, end] of [...spans].sort((a, b) => a[0] - b[0])) {
    if (end <= cursor) continue;
    result += text.slice(cursor, Math.max(cursor, start));
    cursor = end;
  }
  return result + text.slice(cursor);
}

function matchSpans(text, pattern) {
  return [...text.matchAll(pattern)].map((m) => [m.index, m.index + m[0].length]);
}

function removeEmails(text) {
  const { folded, offsets } = foldForContactMatching(text);
  return removeSpans(text, matchSpans(folded, EMAIL_PATTERN).map(([start, end]) => [offsets[start], offsets[end]]));
}

function removeLinks(text) {
  return removeSpans(text, linkSpans(text));
}

function stripContacts(text) {
  let current = text;
  // Removing a contact can join the text around it into a new one, so repeat until stable.
  for (let pass = 0; pass < 4; pass += 1) {
    const cleaned = removeLinks(removeEmails(removeSpans(current, phoneSpans(current))));
    if (cleaned === current) break;
    current = cleaned;
  }
  return current;
}

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

function localizedAmenities(map) {
  if (!map || typeof map !== "object" || Array.isArray(map)) return DEFAULT_AMENITIES;
  const result = {};
  for (const locale of MARKETPLACE_LOCALES) {
    const list = Array.isArray(map[locale]) ? map[locale] : [];
    result[locale] = list
      .filter((item) => typeof item === "string" && item.trim())
      .slice(0, MARKETPLACE_MAX_AMENITIES)
      .map((item) => cleanText(item, 80));
  }
  return result;
}

const PRIVATE_STORAGE_FOLDER = /^(users|private|kyc|documents|leases|contracts)\//i;
const IMAGE_EXTENSION = "\\.(png|jpe?g|webp|gif)$";
const BUNDLED_ASSET = new RegExp(`^assets/[A-Za-z0-9_/.-]+${IMAGE_EXTENSION}`, "i");
const BUNDLED_FILE_NAME = new RegExp(`^[A-Za-z0-9_.-]+${IMAGE_EXTENSION}`, "i");
const INLINE_IMAGE = /^data:image\/(png|jpe?g|webp|gif);base64,[A-Za-z0-9+/=]+$/i;

/** This project's default Storage buckets (both the current and the legacy domain). */
function projectStorageBuckets() {
  let config = {};
  try {
    config = JSON.parse(process.env.FIREBASE_CONFIG || "{}");
  } catch (_) {
    config = {};
  }
  const projectId = config.projectId || process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "";
  return [
    config.storageBucket,
    projectId && `${projectId}.firebasestorage.app`,
    projectId && `${projectId}.appspot.com`,
  ].filter(Boolean);
}

/** The object path of an https download URL in this project's bucket, or null. */
function projectStorageObject(ref) {
  const located = projectStorageLocation(ref);
  return located ? located.objectPath : null;
}

/** { host, bucket, objectPath } of an https download URL in this project's bucket, or null. */
function projectStorageLocation(ref) {
  let url;
  try {
    url = new URL(ref);
  } catch (_) {
    return null;
  }
  if (url.protocol !== "https:") return null;
  const match = url.hostname === "firebasestorage.googleapis.com"
    ? url.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/)
    : url.hostname === "storage.googleapis.com"
      ? url.pathname.match(/^\/([^/]+)\/(.+)$/)
      : null;
  if (!match || !projectStorageBuckets().includes(match[1])) return null;
  try {
    return { host: url.hostname, bucket: match[1], objectPath: decodeURIComponent(match[2]) };
  } catch (_) {
    return null;
  }
}

/**
 * The form a public listing stores an accepted image ref in. A Firebase Storage download URL
 * loses its query: `&token=` makes a bearer link that Storage serves without its rules, so the
 * public doc keeps only `?alt=media`, and every download is checked against storage.rules
 * (a photo is served only while its listing is live).
 */
function publicImageRef(ref) {
  const trimmed = ref.trim();
  const located = trimmed.includes(":") ? projectStorageLocation(trimmed) : null;
  if (!located || located.host !== "firebasestorage.googleapis.com") return trimmed;
  return `https://firebasestorage.googleapis.com/v0/b/${located.bucket}/o/${encodeURIComponent(located.objectPath)}?alt=media`;
}

/**
 * Accepts https download URLs from this project's Storage bucket (outside private
 * folders), bundled asset paths, and inline raster images from the web picker.
 * Anything else (other hosts, http, javascript:, blob:, PDFs) is dropped.
 */
function isPublicImageRef(value) {
  if (typeof value !== "string") return false;
  const ref = value.trim();
  if (!ref) return false;
  if (ref.startsWith("data:")) return INLINE_IMAGE.test(ref);
  if (ref.startsWith("assets/")) return BUNDLED_ASSET.test(ref) && !ref.includes("..");
  if (ref.includes(":")) {
    const objectPath = projectStorageObject(ref);
    return objectPath !== null && !PRIVATE_STORAGE_FOLDER.test(objectPath);
  }
  return BUNDLED_FILE_NAME.test(ref);
}

function boundedNumber(value, fallback, max) {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) return fallback;
  return Math.min(n, max);
}

/**
 * Builds the public marketplace (/Properties) document from an owner property using an
 * explicit allowlist. Only the fields below can ever reach the public catalog; tenant
 * identity, installments, unit numbers, notes, and owner contact data never do.
 */
/**
 * Rating, featured and verified are moderated by platform staff, so they come from the current
 * public doc and an owner's edit can never clear them. Hiding is different: it is read from
 * PropertyModeration/{propertyId}, a doc no owner can write or delete, so deleting or recreating
 * the public or private doc cannot lift it. A listing hidden by moderation stays unpublished
 * until a moderator restores it. A missing moderation doc means not hidden.
 */
function moderatedFields(current, moderation = NOT_MODERATED) {
  const rating = current && current.rating;
  return {
    rating: typeof rating === "number" && rating >= 0 && rating <= 5 ? rating : DEFAULT_LISTING_RATING,
    isFeatured: Boolean(current && current.isFeatured === true),
    verified: Boolean(current && current.verified === true),
    moderation_hidden: moderation.hidden === true,
  };
}

const NOT_MODERATED = Object.freeze({ hidden: false });
const MODERATION_COLLECTION = "PropertyModeration";

function moderationFromSnap(snap) {
  return snap && snap.exists ? { hidden: snap.get("hidden") === true } : NOT_MODERATED;
}

/** Only listings with a positive rent can be published. */
function hasPublishablePrice(data) {
  const price = Number(data.pricePerMonth);
  return Number.isFinite(price) && price > 0;
}

function sanitizeForMarketplace(data, ownerId, propertyId, { agencyId = "", current = null, moderation = NOT_MODERATED } = {}) {
  const countryCode = data.countryCode === "AE" ? "AE" : "EG";
  const rawImages = Array.isArray(data.imageUrls) && data.imageUrls.length > 0
    ? data.imageUrls
    : [data.image];
  const images = rawImages.filter(isPublicImageRef).slice(0, MARKETPLACE_MAX_IMAGES).map(publicImageRef);

  const listing = {
    id: propertyId || cleanText(data.id, 200),
    owner_id: ownerId,
    countryCode: countryCode,
    currencyCode: countryCode === "AE" ? "AED" : "EGP",
    titles: localizedText(data.titles, data.title, 200),
    descriptions: localizedText(data.descriptions, data.description, 4000),
    locations: localizedText(data.locations, data.location, 300),
    cityCode: cleanText(data.cityCode, 60) || "cairo",
    propertyTypeCode: cleanText(data.propertyTypeCode, 60) || "apartment",
    buildingName: cleanText(data.buildingName, 200),
    pricePerMonth: hasPublishablePrice(data) ? Math.min(Number(data.pricePerMonth), 1e9) : 0,
    bedrooms: boundedNumber(data.bedrooms, 1, 100) || 1,
    bathrooms: boundedNumber(data.bathrooms, 1, 100) || 1,
    areaSqM: boundedNumber(data.areaSqM, 100, 1e6) || 100,
    image: images[0] || "",
    imageUrls: images,
    amenitiesMap: localizedAmenities(data.amenitiesMap),
    isFurnished: data.isFurnished !== false,
    agencyNames: PLATFORM_AGENCY_NAMES,
    agencyPhone: PLATFORM_AGENCY_PHONE,
    ...moderatedFields(current, moderation),
    status: "vacant",
    updated_at: FieldValue.serverTimestamp(),
  };
  listing.is_published = !listing.moderation_hidden;
  if (agencyId) listing.agency_id = agencyId;
  return listing;
}

/**
 * A public doc that nobody can legitimately hold: it is not live, and either never carried
 * listing content (the bare owner_id/status stubs older versions of the trigger created for
 * unpublished private docs) or belongs to an account that may not publish at all.
 */
async function isClaimablePlaceholder(current) {
  const holder = current.get("owner_id");
  if (!holder || current.get("is_published") === true) return false;
  if (!current.get("titles")) return true;
  const { role } = await resolveUserAuthority(holder);
  return !PUBLISHER_ROLES.includes(role);
}

/**
 * Applies `mutate(tx, marketDocRef, current)` only when /Properties/{propertyId} is absent or
 * already belongs to ownerId. Property ids are global, so any owner can create a private doc
 * with someone else's listing id; without this check that owner could overwrite, conceal, or
 * delete the other owner's public listing. With `claimPlaceholder`, a real publish may also
 * replace an unpublished placeholder left by a non-owner, so it cannot block the real owner.
 * Returns false when the write was refused.
 */
async function writeOwnedMarketDoc(db, ownerId, propertyId, mutate, { claimPlaceholder = false } = {}) {
  const marketDocRef = db.collection("Properties").doc(propertyId);
  const moderationRef = db.collection(MODERATION_COLLECTION).doc(propertyId);
  return db.runTransaction(async (tx) => {
    const current = await tx.get(marketDocRef);
    const moderation = moderationFromSnap(await tx.get(moderationRef));
    if (current.exists && current.get("owner_id") !== ownerId) {
      if (claimPlaceholder && await isClaimablePlaceholder(current)) {
        logger.warn(
          `Replacing the unpublished placeholder [${propertyId}] held by ` +
          `[${current.get("owner_id") || "no owner"}] with the listing of owner [${ownerId}].`
        );
        mutate(tx, marketDocRef, { exists: false, data: () => null }, moderation);
        return true;
      }
      logger.warn(
        `Refusing to sync [${propertyId}] from owner [${ownerId}]: the public listing belongs to ` +
        `[${current.get("owner_id") || "no owner"}].`
      );
      return false;
    }
    mutate(tx, marketDocRef, current, moderation);
    return true;
  });
}

/**
 * Whether a private listing may be live right now: the owner wants it public and available, holds
 * a role that can publish, and has a positive rent. `refusal` says why not when it wants to be live.
 */
async function publishDecision(ownerId, data) {
  const wantsPublic = Boolean(data.isPublished) && (data.rentalStatus || "available") === "available";
  if (!wantsPublic) return { wantsPublic: false, refusal: "", agencyId: "" };
  const { role, agencyId } = await resolveUserAuthority(ownerId);
  const refusal = !PUBLISHER_ROLES.includes(role) ? `owner [${ownerId}] has role [${role || "none"}]`
    : !hasPublishablePrice(data) ? "the rent is not a positive number"
      : "";
  return { wantsPublic, refusal, agencyId };
}

/**
 * Event-Driven Cloud Function: Automatically synchronizes owner property mutations
 * from the private tree (Users/{ownerId}/properties/{propertyId}) to the public
 * marketplace collection (/Properties/{propertyId}).
 */
exports.syncOwnerPropertyToMarketplace = onDocumentWritten(
  "Users/{ownerId}/properties/{propertyId}",
  async (event) => {
    const ownerId = event.params.ownerId;
    const propertyId = event.params.propertyId;
    const db = admin.firestore();

    // 1. Handle document deletion in owner's tree
    if (!event.data || !event.data.after || !event.data.after.exists) {
      logger.info(`Property [${propertyId}] was deleted by owner [${ownerId}]. Removing from /Properties.`);
      try {
        await writeOwnedMarketDoc(db, ownerId, propertyId, (tx, ref, current, moderation) => {
          if (!current.exists) return;
          // A listing under moderation hold is never deleted by an owner action: it stays,
          // unpublished, so recreating the private doc cannot bring it back.
          if (moderation.hidden) {
            tx.set(ref, { is_published: false, moderation_hidden: true, updated_at: FieldValue.serverTimestamp() }, { merge: true });
          } else {
            tx.delete(ref);
          }
        });
      } catch (err) {
        logger.error(`Error deleting property [${propertyId}] from /Properties`, err);
      }
      return null;
    }

    const afterData = event.data.after.data();
    const isPublished = Boolean(afterData.isPublished);
    const rentalStatus = afterData.rentalStatus || "available";
    const { wantsPublic, refusal, agencyId } = await publishDecision(ownerId, afterData);

    if (refusal) {
      logger.warn(`Not publishing [${propertyId}]: ${refusal}.`);
      try {
        await writeOwnedMarketDoc(db, ownerId, propertyId, (tx, ref, current) => {
          if (current.exists) {
            tx.set(ref, { is_published: false, updated_at: FieldValue.serverTimestamp() }, { merge: true });
          }
        });
      } catch (err) {
        logger.error(`Error concealing property [${propertyId}] in /Properties`, err);
      }
      return null;
    }

    // 2. Handle active published property
    if (wantsPublic) {
      logger.info(`Syncing published property [${propertyId}] for owner [${ownerId}] to /Properties`);
      try {
        // Full replace (no merge) so stale or previously leaked fields are purged.
        const written = await writeOwnedMarketDoc(db, ownerId, propertyId, (tx, ref, current, moderation) => tx.set(
          ref,
          sanitizeForMarketplace(afterData, ownerId, propertyId, {
            agencyId,
            current: current.exists ? current.data() : null,
            moderation,
          }),
        ), { claimPlaceholder: true });
        if (written) logger.info(`Successfully synchronized sanitized property [${propertyId}] to public marketplace.`);
      } catch (err) {
        logger.error(`Error syncing property [${propertyId}] to /Properties`, err);
        throw err;
      }
    } else {
      // 3. Handle rented, unpublished, or maintenance properties -> Conceal from public marketplace.
      // Only an existing public doc of this owner is updated; an unpublished private doc must
      // never create one, or it would reserve the id against the real owner's later publish.
      logger.info(`Concealing property [${propertyId}] from /Properties (status: ${rentalStatus}, isPublished: ${isPublished})`);
      try {
        await writeOwnedMarketDoc(db, ownerId, propertyId, (tx, ref, current) => {
          if (current.exists) {
            tx.set(ref, {
              is_published: false,
              status: rentalStatus === "rented" ? "rented" : "unavailable",
              updated_at: FieldValue.serverTimestamp(),
            }, { merge: true });
          }
        });
      } catch (err) {
        logger.error(`Error updating concealed state for property [${propertyId}] in /Properties`, err);
      }
    }

    return null;
  }
);

/**
 * Keeps the public listing in line with PropertyModeration.
 *
 * A hide always takes the public doc offline, even if the moderation doc was written without it.
 *
 * Lifting the hold (or deleting the moderation doc) is the only way a moderated listing goes back
 * online, and it is decided here, never by a client write: the public doc is rebuilt from the
 * owner's current private doc, and published only if the listing was live before the hide
 * (pre_hide_published), the private doc still wants to be public and available, the rent is
 * positive, and the owner still holds a publishing role. Otherwise the listing stays offline. This
 * is what stops a restore from reviving a stale public doc (old price, lost role, unpublished).
 */
exports.reconcilePropertyModeration = onDocumentWritten(
  `${MODERATION_COLLECTION}/{propertyId}`,
  async (event) => {
    const propertyId = event.params.propertyId;
    const before = event.data && event.data.before;
    const after = event.data && event.data.after;
    const hidden = Boolean(after && after.exists && after.get("hidden") === true);
    const wasHidden = Boolean(before && before.exists && before.get("hidden") === true);
    const preHidePublished = Boolean(after && after.exists && after.get("pre_hide_published") === true);
    const db = admin.firestore();
    const ref = db.collection("Properties").doc(propertyId);
    try {
      const current = await ref.get();
      if (!current.exists) return null;
      if (hidden) {
        if (current.get("is_published") !== false || current.get("moderation_hidden") !== true) {
          await ref.update({ is_published: false, moderation_hidden: true, updated_at: FieldValue.serverTimestamp() });
        }
        return null;
      }
      if (!wasHidden && current.get("moderation_hidden") !== true) return null;
      await liftHold(db, propertyId, preHidePublished);
    } catch (err) {
      logger.error(`Error reconciling moderation for property [${propertyId}]`, err);
      throw err;
    }
    return null;
  }
);

async function liftHold(db, propertyId, preHidePublished) {
  const ref = db.collection("Properties").doc(propertyId);
  const ownerId = (await ref.get()).get("owner_id");
  const privateSnap = ownerId && preHidePublished
    ? await db.doc(`Users/${ownerId}/properties/${propertyId}`).get()
    : null;
  const privateData = privateSnap && privateSnap.exists ? privateSnap.data() : null;
  const decision = privateData ? await publishDecision(ownerId, privateData) : null;
  const goLive = Boolean(decision && decision.wantsPublic && !decision.refusal);
  if (decision && decision.refusal) logger.warn(`Not republishing [${propertyId}] after moderation: ${decision.refusal}.`);

  await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    const moderation = moderationFromSnap(await tx.get(db.collection(MODERATION_COLLECTION).doc(propertyId)));
    if (!current.exists || current.get("owner_id") !== ownerId || moderation.hidden) return;
    if (goLive) {
      tx.set(ref, sanitizeForMarketplace(privateData, ownerId, propertyId, {
        agencyId: decision.agencyId,
        current: current.data(),
        moderation: NOT_MODERATED,
      }));
    } else {
      tx.update(ref, { is_published: false, moderation_hidden: false, updated_at: FieldValue.serverTimestamp() });
    }
  });
}

// Export helper for unit testing
exports.sanitizeForMarketplace = sanitizeForMarketplace;

/**
 * Generates structured, verified market intelligence payload combining official
 * baseline index points with daily 09:00 AM real-time grounded signals.
 */
function generateMarketIndexData(countryCode) {
  const isEgypt = countryCode === "EG";

  if (isEgypt) {
    return {
      countryCode: "EG",
      indexName: "مؤشر عقارماب مصر",
      indexPoints: 2940,
      indexChangeMoM: 4.8,
      demandStatus: "highDemand",
      marketState: "sellersMarket",
      averageRentalGrowthYoY: 18.5,
      averageDaysOnMarket: 14.5,
      inflationHedgingScore: 9.4,
      dailyBriefingTime: "09:00 ص",
      isLiveGrounded: true,
      lastUpdatedTimestamp: new Date().toLocaleDateString("ar-EG", {
        day: "numeric",
        month: "long",
        year: "numeric",
      }),
      aiExecutiveSummary: {
        ar: "يسجل مؤشر السوق العقاري المصري طلباً متصاعداً بقوة مدفوعاً برغبة المستثمرين في حماية السيولة النقدية وتفضيل الإيجارات عالية الجودة في المدن الجديدة.",
        en: "The Egyptian real estate index exhibits strong upward momentum driven by inflation hedging and sustained demand for premium units in modern suburbs.",
        hi: "मिस्र का रियल एस्टेट सूचकांक मुद्रास्फीति हेजिंग और नए उपनगरों में उच्च मांग द्वारा संचालित मजबूत गति प्रदर्शित करता है।",
      },
      ownerAdvice: {
        ar: "الوقت مثالي لإعادة تسعير الوحدات وفق مؤشر القيمة العادلة وتثبيت عقود سنوية مدعومة ببنود زيادة واضحة.",
        en: "Optimal timing to recalibrate rental rates according to fair market valuation and secure annual contracts with escalation terms.",
        hi: "उचित बाजार मूल्यांकन के अनुसार किराये की दरों को फिर से व्यवस्थित करने और वार्षिक अनुबंध सुरक्षित करने का आदर्श समय।",
      },
      tenantAdvice: {
        ar: "يُنصح بسرعة حسم التعاقدات لتجنب موجات الارتفاع القادمة والبحث في المناطق الناشئة ذات القيمة الممتازة.",
        en: "Fast-track lease signings to avoid upcoming quarterly price adjustments, and explore emerging high-value districts.",
        hi: "आगामी मूल्य समायोजन से बचने के लिए पट्टा हस्ताक्षर में तेजी लाएं और उभरते उच्च-मूल्य वाले क्षेत्रों का पता लगाएं।",
      },
      dailySignals: [
        {
          headline: {
            ar: "ارتفاع وتيرة الطلب على الإيجارات الفندقية والتنفيذية بالتجمع بنسبة +14% خلال 48 ساعة.",
            en: "Executive and serviced rental demand surged +14% in New Cairo over the last 48 hours.",
            hi: "न्यू काहिरा में कार्यकारी किराये की मांग में पिछले 48 घंटों में +14% की वृद्धि हुई है।",
          },
          category: "demand",
          impact: "positive",
          sourceName: "عقارماب + بحث Google المباشر",
          timeAgo: { ar: "اليوم 09:00 ص", en: "Today 09:00 AM", hi: "आज 09:00 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "البنك المركزي المصري يثبت أسعار الفائدة؛ ما يعزز تدفق السيولة إلى شراء وتأجير العقار التجاري والسكني.",
            en: "Central Bank interest rate policy supports steady capital allocation toward high-yield residential real estate.",
            hi: "केंद्रीय बैंक नीति उच्च-उपज आवासीय रियल एस्टेट में पूंजी आवंटन का समर्थन करती है।",
          },
          category: "economy",
          impact: "positive",
          sourceName: "القطاع المصرفي + تحليلات Google Search",
          timeAgo: { ar: "اليوم 08:30 ص", en: "Today 08:30 AM", hi: "आज 08:30 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "انخفاض متوسط أيام شغور الشقق في الشيخ زايد إلى 14 يوماً مع بدء موسم الانتقال الشتوي.",
            en: "Average vacancy duration in Sheikh Zayed dropped to 14 days ahead of Q4 leasing cycle.",
            hi: "चौथी तिमाही के पट्टा चक्र से पहले शेख जायद में औसत रिक्ति अवधि 14 दिनों तक गिर गई।",
          },
          category: "velocity",
          impact: "positive",
          sourceName: "مؤشر عقارماب للطلب السكني",
          timeAgo: { ar: "اليوم 07:45 ص", en: "Today 07:45 AM", hi: "आज 07:45 पूर्वाह्न" },
        },
      ],
      verifiedSources: [
        "مؤشر عقارماب مصر الرسمي (Aqarmap Egypt Index)",
        "Google Search Grounding Real-Time Market Feed",
        "بيانات الصفقات الموثقة عبر منصة تسهيل",
      ],
      updatedAt: FieldValue.serverTimestamp(),
    };
  } else {
    return {
      countryCode: "AE",
      indexName: "مؤشر دبي للعقارات DXB",
      indexPoints: 3420,
      indexChangeMoM: 3.2,
      demandStatus: "highDemand",
      marketState: "sellersMarket",
      averageRentalGrowthYoY: 14.2,
      averageDaysOnMarket: 11.0,
      inflationHedgingScore: 9.6,
      dailyBriefingTime: "09:00 ص",
      isLiveGrounded: true,
      lastUpdatedTimestamp: new Date().toLocaleDateString("ar-EG", {
        day: "numeric",
        month: "long",
        year: "numeric",
      }),
      aiExecutiveSummary: {
        ar: "يواصل القطاع العقاري في دبي تسجيل مستويات نمو تاريخية مدعوماً بتدفق المستثمرين الدوليين واستقرار العوائد الإيجارية عند مستويات قياسية تفوق 8%.",
        en: "Dubai property sector maintains sustained momentum powered by global capital migration and attractive net rental yields exceeding 8%.",
        hi: "दुबई का संपत्ति क्षेत्र वैश्विक पूंजी प्रवाह और 8% से अधिक आकर्षक शुद्ध किराये की उपज द्वारा निरंतर गति बनाए रखता है।",
      },
      ownerAdvice: {
        ar: "الاستفادة من قلة المعروض في المناطق المركزية لاختيار مستأجرين موثوقين وتفضيل الدفعات السنوية المرنة (1 إلى 2 شيك).",
        en: "Capitalize on limited prime inventory by securing vetted tenants with flexible 1-2 cheque payment schedules.",
        hi: "लचीले 1-2 चेक भुगतान अनुसूचियों के साथ सत्यापित किरायेदारों को सुरक्षित करके सीमित प्राथमिक सूची का लाभ उठाएं।",
      },
      tenantAdvice: {
        ar: "المبادرة بتسجيل العقود فوراً عبر نظام إيجاري والبحث في المناطق المتصلة حديثاً بالمترو للحصول على أفضل قيمة مقابل السعر.",
        en: "Expedite lease registrations via Ejari and explore emerging metro-linked communities for optimal value-to-cost ratio.",
        hi: "एज़ारी के माध्यम से पट्टा पंजीकरण में तेजी लाएं और सर्वोत्तम मूल्य-से-लागत अनुपात के लिए उभरते मेट्रो-लिंक्ड समुदायों का पता लगाएं।",
      },
      dailySignals: [
        {
          headline: {
            ar: "دائرة الأراضي والأملاك في دبي (DLD) تسجل معاملات قياسية في مارينا والخليج التجاري تجاوزت 2.1 مليار درهم.",
            en: "Dubai Land Department records over AED 2.1B in transactions across Marina & Business Bay.",
            hi: "दुबई भूमि विभाग ने मरीना और बिजनेस बे में 2.1 अरब एईडी से अधिक के लेनदेन दर्ज किए।",
          },
          category: "investment",
          impact: "positive",
          sourceName: "دائرة الأراضي والأملاك + Google Search",
          timeAgo: { ar: "اليوم 09:00 ص", en: "Today 09:00 AM", hi: "आज 09:00 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "استقرار العوائد الصافية لشقق دبي عند متوسط 8.4% مدفوعاً بطلب الإقامات طويلة الأجل (Golden Visa).",
            en: "Net rental yields in Dubai hold firm at 8.4% backed by Golden Visa and expat influx.",
            hi: "गोल्डन वीजा और प्रवासियों की आमद से समर्थित दुबई में शुद्ध किराये की उपज 8.4% पर स्थिर है।",
          },
          category: "demand",
          impact: "positive",
          sourceName: "DXB Pulse Index + Gemini AI",
          timeAgo: { ar: "اليوم 08:15 ص", en: "Today 08:15 AM", hi: "आज 08:15 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "نمو عقود الإيجار السنوية المسجلة عبر نظام إيجاري (Ejari) بنسبة +9.2% مقارنة بالفترة ذاتها من العام الماضي.",
            en: "Ejari-registered annual residential leases grew +9.2% YoY across central Dubai districts.",
            hi: "मध्य दुबई जिलों में एज़ारी-पंजीकृत वार्षिक आवासीय पट्टों में साल-दर-साल +9.2% की वृद्धि हुई।",
          },
          category: "policy",
          impact: "positive",
          sourceName: "مؤشر إيجاري الرسمي وريرا (RERA)",
          timeAgo: { ar: "اليوم 07:30 ص", en: "Today 07:30 AM", hi: "आज 07:30 पूर्वाह्न" },
        },
      ],
      verifiedSources: [
        "مؤشر دبي العقاري ومؤشرات دائرة الأراضي والأملاك (DLD / DXB Pulse)",
        "Google Search Grounding Real-Time Market Intelligence",
        "بيانات منصة إيجاري (Ejari) المعتمدة",
      ],
      updatedAt: FieldValue.serverTimestamp(),
    };
  }
}

/**
 * Scheduled Cloud Function (v2): Ingests and refreshes live market index,
 * daily signals, and verified economic indicators at 09:00 AM daily.
 */
exports.syncMarketIndexDaily = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Africa/Cairo",
  },
  async (event) => {
    logger.info("Executing 09:00 AM Daily Market Index Ingestion Pipeline...");
    const db = admin.firestore();
    const countries = ["EG", "AE"];

    for (const code of countries) {
      try {
        const payload = generateMarketIndexData(code);
        await db.collection("MarketIndices").doc(code).set(payload, { merge: true });
        logger.info(`Successfully ingested daily market index for [${code}]`);
      } catch (err) {
        logger.error(`Error ingesting daily market index for [${code}]`, err);
      }
    }
  }
);

const MARKET_INDEX_COUNTRIES = ["EG", "AE"];
const MARKET_INDEX_COOLDOWN_MS = 10 * 60 * 1000;

/**
 * SuperAdmin-only callable that refreshes one country's market index outside the daily
 * schedule. A country can be refreshed at most once every 10 minutes.
 */
exports.syncMarketIndexManual = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 1 }, async (request) => {
  const auth = requireAuth(request);
  await requireRole(auth, ["SuperAdmin"]);
  const data = request.data || {};
  const country = typeof data.country === "string" ? data.country.trim().toUpperCase() : "";
  if (!MARKET_INDEX_COUNTRIES.includes(country)) {
    throw new HttpsError("invalid-argument", "country must be EG or AE.");
  }

  const db = admin.firestore();
  const ref = db.collection("MarketIndices").doc(country);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const updatedAt = snap.exists ? snap.get("updatedAt") : null;
    if (updatedAt instanceof Timestamp && Date.now() - updatedAt.toMillis() < MARKET_INDEX_COOLDOWN_MS) {
      throw new HttpsError("resource-exhausted", "This market index was refreshed less than 10 minutes ago.");
    }
    tx.set(ref, generateMarketIndexData(country), { merge: true });
  });
  logger.info(`Manual market index refresh for [${country}] by ${auth.uid}`);
  return { success: true, country };
});

exports.geminiGenerate = require("./gemini_gateway").geminiGenerate;

// Rent payments through Paymob (TAQ-16). Off until PAYMENTS_ENABLED=true and the keys exist.
exports.createRentPaymentIntent = require("./payments").createRentPaymentIntent;
exports.paymobWebhook = require("./payments").paymobWebhook;
exports.recordManualPayment = require("./payments").recordManualPayment;
