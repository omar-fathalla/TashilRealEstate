/**
 * Viewing requests and rental applications (TAQ-112).
 *
 * A signed-in visitor asks to view a live listing (`requestViewing`) or applies to rent it
 * (`applyForRental`). Both are written here, by the server, never by the client: the listing must be
 * live, the caller is rate limited, and the owner and agency are copied from the public listing, so
 * nobody can aim a request at someone else's inbox. `ViewingRequests` and `RentalApplications` are
 * readable only by the requester, the owner, the managing agency and staff (see firestore.rules).
 *
 * The owner or agency answers through `respondToViewingRequest` and `decideRentalApplication`, which
 * also notify the requester. `createLeaseFromApplication` turns an approved application into a draft
 * lease whose parties come from the application, and links the two.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { requireAuth, requireRole, resolveRole } = require("./authz");
const { verifyLeaseProperty, readPropertyLock, alreadyLeased } = require("./leases");
const { appCheckEnforced } = require("./config");
const { containsContact } = require("./contact_filter");

const ENFORCE_APP_CHECK = appCheckEnforced();

const VIEWINGS = "ViewingRequests";
const APPLICATIONS = "RentalApplications";
const RATE_LIMITS = "AiRateLimits";

const LIMITS = {
  viewing: { perMinute: 3, perDay: 20 },
  application: { perMinute: 2, perDay: 10 },
};
const MAX_PENDING_VIEWINGS_PER_LISTING = 1;
const MAX_FUTURE_DAYS = 180;
const DAY_MS = 24 * 60 * 60 * 1000;

const deps = { now: () => Date.now() };

function cleanText(value, max) {
  return typeof value === "string" ? value.replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim().slice(0, max) : "";
}

function requireName(value) {
  const name = cleanText(value, 100);
  if (name.length < 2) throw new HttpsError("invalid-argument", "Your name is required.");
  return name;
}

/** Digits with an optional leading +, 7 to 15 digits (E.164 length). Returns it without separators. */
function requirePhone(value) {
  const compact = typeof value === "string" ? value.replace(/[\s\-().]/g, "") : "";
  if (!/^\+?[0-9]{7,15}$/.test(compact)) {
    throw new HttpsError("invalid-argument", "A valid phone number is required.");
  }
  return compact;
}

function optionalMessage(value) {
  if (value === undefined || value === null || value === "") return "";
  if (typeof value !== "string") throw new HttpsError("invalid-argument", "message must be text.");
  // Contacts are rejected, not redacted: a visitor and an owner talk through the platform until a
  // lease exists. The check runs on the text as sent, so truncation cannot hide a number.
  if (containsContact(value)) {
    throw new HttpsError("invalid-argument", "Messages cannot contain phone numbers, emails or links.", { reason: "contact_in_message" });
  }
  return cleanText(value, 500);
}

const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

function parseDateOnly(value, field) {
  const match = typeof value === "string" ? DATE_ONLY.exec(value) : null;
  const date = match ? new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]))) : null;
  if (!date || Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new HttpsError("invalid-argument", `${field} must be a date in the form YYYY-MM-DD.`);
  }
  return date;
}

function optionalFutureDate(value, field, now) {
  if (value === undefined || value === null || value === "") return "";
  const date = parseDateOnly(value, field);
  if (date.getTime() < now - DAY_MS || date.getTime() > now + MAX_FUTURE_DAYS * DAY_MS) {
    throw new HttpsError("invalid-argument", `${field} must be within the next ${MAX_FUTURE_DAYS} days.`);
  }
  return value;
}

/** Signed-in only. Anonymous sessions (used for browsing) do not count. */
function requireSignedInUser(request) {
  const auth = requireAuth(request);
  const provider = auth.token && auth.token.firebase && auth.token.firebase.sign_in_provider;
  if (provider === "anonymous") {
    throw new HttpsError("unauthenticated", "Sign in with an account to continue.");
  }
  return auth;
}

async function consumeQuota(uid, kind) {
  const db = admin.firestore();
  const limits = LIMITS[kind];
  const now = deps.now();
  const minute = Math.floor(now / 60000);
  const day = new Date(now).toISOString().slice(0, 10);
  const ref = db.collection(RATE_LIMITS).doc(`req_${kind}_${uid}`);
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const data = snap.exists ? snap.data() : {};
    const minuteCount = data.minute === minute ? Number(data.minuteCount || 0) : 0;
    const dayCount = data.day === day ? Number(data.dayCount || 0) : 0;
    if (minuteCount >= limits.perMinute) {
      throw new HttpsError("resource-exhausted", "Too many requests. Try again in a minute.", { retry: "minute" });
    }
    if (dayCount >= limits.perDay) {
      throw new HttpsError("resource-exhausted", "The daily request limit has been reached.", { retry: "day" });
    }
    t.set(ref, {
      kind: `request_${kind}`,
      minute,
      minuteCount: minuteCount + 1,
      day,
      dayCount: dayCount + 1,
      updatedAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(now + 2 * DAY_MS),
    });
  });
}

/** A listing a request may target: published, vacant, not held by moderation, with an owner. */
async function loadLiveListing(listingId) {
  if (typeof listingId !== "string" || !listingId || listingId.length > 200 || listingId.includes("/")) {
    throw new HttpsError("invalid-argument", "A listing id is required.");
  }
  const snap = await admin.firestore().collection("Properties").doc(listingId).get();
  const listing = snap.exists ? snap.data() : null;
  if (!listing || listing.is_published !== true || listing.moderation_hidden === true || !listing.owner_id
    || ["rented", "unavailable"].includes(listing.status)) {
    throw new HttpsError("failed-precondition", "This listing is not available.", { reason: "listing_not_live" });
  }
  return { id: snap.id, ...listing };
}

function partiesFromListing(listing) {
  return {
    listing_id: listing.id,
    owner_id: String(listing.owner_id),
    agency_id: typeof listing.agency_id === "string" ? listing.agency_id : "",
    country_code: listing.countryCode === "AE" ? "AE" : "EG",
    listing_titles: {
      ar: cleanText(listing.titles && listing.titles.ar, 200),
      en: cleanText(listing.titles && listing.titles.en, 200),
      hi: cleanText(listing.titles && listing.titles.hi, 200),
    },
  };
}

function assertNotOwnListing(auth, role, record) {
  if (record.owner_id === auth.uid || (role === "AgencyAdmin" && record.agency_id && auth.token.agency_id === record.agency_id)) {
    throw new HttpsError("failed-precondition", "You cannot send a request for your own listing.", { reason: "own_listing" });
  }
}

/** Owner, the agency that manages the record, or SuperAdmin. */
function assertManager(auth, role, record) {
  if (role === "SuperAdmin") return;
  if (role === "Owner" && record.owner_id === auth.uid) return;
  const agencyId = auth.token && auth.token.agency_id;
  if (role === "AgencyAdmin" && agencyId && record.agency_id === agencyId) return;
  throw new HttpsError("permission-denied", "You cannot manage this request.");
}

function notification(id, recipientId, type, title, body, extra = {}) {
  return {
    id,
    recipientId,
    type,
    title,
    body,
    status: "delivered",
    read: false,
    createdAt: Timestamp.now(),
    ...extra,
  };
}

function writeNotification(t, db, uid, data) {
  if (!uid) return;
  t.set(db.collection("Users").doc(uid).collection("notifications").doc(data.id), data);
}

// ---------------------------------------------------------------------------------------------
// Viewing requests
// ---------------------------------------------------------------------------------------------

const requestViewing = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireSignedInUser(request);
  const data = request.data || {};
  const name = requireName(data.name);
  const phone = requirePhone(data.phone);
  const message = optionalMessage(data.message);
  const now = deps.now();
  const preferredDate = optionalFutureDate(data.preferredDate, "preferredDate", now);

  const listing = await loadLiveListing(data.listingId);
  const parties = partiesFromListing(listing);
  const role = await resolveRole(auth);
  assertNotOwnListing(auth, role, parties);
  await consumeQuota(auth.uid, "viewing");

  const db = admin.firestore();
  const ref = db.collection(VIEWINGS).doc();
  await db.runTransaction(async (t) => {
    const open = await t.get(
      db.collection(VIEWINGS).where("requester_id", "==", auth.uid).where("listing_id", "==", listing.id).limit(25)
    );
    const pending = open.docs.filter((d) => d.get("status") === "pending").length;
    if (pending >= MAX_PENDING_VIEWINGS_PER_LISTING) {
      throw new HttpsError("already-exists", "You already have a pending viewing request for this listing.", { reason: "duplicate_pending" });
    }
    t.create(ref, {
      ...parties,
      requester_id: auth.uid,
      requester_name: name,
      requester_phone: phone,
      message,
      preferred_date: preferredDate,
      status: "pending",
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    writeNotification(
      t,
      db,
      parties.owner_id,
      notification(
        `viewing_${ref.id}`,
        parties.owner_id,
        "viewing_request",
        { ar: "طلب معاينة جديد", en: "New viewing request", hi: "नया निरीक्षण अनुरोध" },
        {
          ar: "وصلك طلب معاينة على أحد عقاراتك. افتح صندوق الطلبات للرد.",
          en: "You have a viewing request for one of your listings. Open the inbox to respond.",
          hi: "आपकी एक लिस्टिंग के लिए निरीक्षण अनुरोध आया है। जवाब देने के लिए इनबॉक्स खोलें।",
        },
        { requestId: ref.id, listingId: listing.id }
      )
    );
  });
  return { success: true, requestId: ref.id, status: "pending" };
});

const respondToViewingRequest = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const data = request.data || {};
  if (!["confirmed", "declined"].includes(data.decision)) {
    throw new HttpsError("invalid-argument", "decision must be confirmed or declined.");
  }
  if (typeof data.requestId !== "string" || !data.requestId || data.requestId.includes("/")) {
    throw new HttpsError("invalid-argument", "A request id is required.");
  }
  const note = optionalMessage(data.note);
  const db = admin.firestore();
  const ref = db.collection(VIEWINGS).doc(data.requestId);
  const confirmed = data.decision === "confirmed";
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Request not found.");
    const record = snap.data();
    assertManager(auth, role, record);
    if (record.status !== "pending") {
      throw new HttpsError("failed-precondition", "This request was already answered.", { reason: "not_pending" });
    }
    t.update(ref, {
      status: data.decision,
      response_note: note,
      responded_by: auth.uid,
      responded_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    writeNotification(
      t,
      db,
      record.requester_id,
      notification(
        `viewing_${ref.id}_${data.decision}`,
        record.requester_id,
        confirmed ? "viewing_confirmed" : "viewing_declined",
        confirmed
          ? { ar: "تم تأكيد طلب المعاينة", en: "Viewing confirmed", hi: "निरीक्षण की पुष्टि हुई" }
          : { ar: "تم رفض طلب المعاينة", en: "Viewing declined", hi: "निरीक्षण अनुरोध अस्वीकृत" },
        confirmed
          ? {
            ar: "تم تأكيد طلب المعاينة الخاص بك. سيتواصل معك المالك أو الوكالة لتحديد الموعد.",
            en: "Your viewing request was confirmed. The owner or agency will contact you to set the time.",
            hi: "आपके निरीक्षण अनुरोध की पुष्टि हो गई है। समय तय करने के लिए मालिक या एजेंसी आपसे संपर्क करेगी।",
          }
          : {
            ar: "تعذر قبول طلب المعاينة الخاص بك هذه المرة.",
            en: "Your viewing request could not be accepted this time.",
            hi: "इस बार आपका निरीक्षण अनुरोध स्वीकार नहीं किया जा सका।",
          },
        { requestId: ref.id, listingId: record.listing_id }
      )
    );
  });
  return { success: true, status: data.decision };
});

// ---------------------------------------------------------------------------------------------
// Rental applications
// ---------------------------------------------------------------------------------------------

const applyForRental = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireSignedInUser(request);
  const role = await requireRole(auth, ["Tenant"]);
  const data = request.data || {};
  const name = requireName(data.name);
  const phone = requirePhone(data.phone);
  const message = optionalMessage(data.message);
  const now = deps.now();
  const moveInDate = optionalFutureDate(data.moveInDate, "moveInDate", now);
  let occupants = 1;
  if (data.occupants !== undefined && data.occupants !== null) {
    if (!Number.isInteger(data.occupants) || data.occupants < 1 || data.occupants > 20) {
      throw new HttpsError("invalid-argument", "occupants must be a whole number from 1 to 20.");
    }
    occupants = data.occupants;
  }

  const listing = await loadLiveListing(data.listingId);
  const parties = partiesFromListing(listing);
  assertNotOwnListing(auth, role, parties);
  await consumeQuota(auth.uid, "application");

  const db = admin.firestore();
  const ref = db.collection(APPLICATIONS).doc(`${listing.id}_${auth.uid}`);
  await db.runTransaction(async (t) => {
    const existing = await t.get(ref);
    if (existing.exists && existing.get("status") !== "rejected") {
      throw new HttpsError("already-exists", "You already applied for this listing.", { reason: "duplicate_application", status: existing.get("status") });
    }
    t.set(ref, {
      ...parties,
      applicant_id: auth.uid,
      applicant_name: name,
      applicant_phone: phone,
      message,
      move_in_date: moveInDate,
      occupants,
      status: "pending",
      attempt: existing.exists ? Number(existing.get("attempt") || 1) + 1 : 1,
      created_at: existing.exists ? existing.get("created_at") : FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    writeNotification(
      t,
      db,
      parties.owner_id,
      notification(
        `application_${ref.id}_${existing.exists ? Number(existing.get("attempt") || 1) + 1 : 1}`,
        parties.owner_id,
        "rental_application",
        { ar: "طلب إيجار جديد", en: "New rental application", hi: "नया किराया आवेदन" },
        {
          ar: "وصلك طلب إيجار على أحد عقاراتك. افتح صندوق الطلبات للمراجعة.",
          en: "You have a rental application for one of your listings. Open the inbox to review it.",
          hi: "आपकी एक लिस्टिंग के लिए किराया आवेदन आया है। समीक्षा के लिए इनबॉक्स खोलें।",
        },
        { applicationId: ref.id, listingId: listing.id }
      )
    );
  });
  return { success: true, applicationId: ref.id, status: "pending" };
});

const decideRentalApplication = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const data = request.data || {};
  if (!["approved", "rejected"].includes(data.decision)) {
    throw new HttpsError("invalid-argument", "decision must be approved or rejected.");
  }
  if (typeof data.applicationId !== "string" || !data.applicationId || data.applicationId.includes("/")) {
    throw new HttpsError("invalid-argument", "An application id is required.");
  }
  const note = optionalMessage(data.note);
  const db = admin.firestore();
  const ref = db.collection(APPLICATIONS).doc(data.applicationId);
  const approved = data.decision === "approved";
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Application not found.");
    const record = snap.data();
    assertManager(auth, role, record);
    if (record.status !== "pending") {
      throw new HttpsError("failed-precondition", "This application was already answered.", { reason: "not_pending" });
    }
    t.update(ref, {
      status: data.decision,
      response_note: note,
      decided_by: auth.uid,
      decided_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    writeNotification(
      t,
      db,
      record.applicant_id,
      notification(
        `application_${ref.id}_${record.attempt || 1}_${data.decision}`,
        record.applicant_id,
        approved ? "application_approved" : "application_rejected",
        approved
          ? { ar: "تمت الموافقة على طلب الإيجار", en: "Rental application approved", hi: "किराया आवेदन स्वीकृत" }
          : { ar: "تم رفض طلب الإيجار", en: "Rental application declined", hi: "किराया आवेदन अस्वीकृत" },
        approved
          ? {
            ar: "تمت الموافقة على طلب الإيجار الخاص بك. سيصلك عرض عقد للموافقة عليه من حسابك.",
            en: "Your rental application was approved. A lease offer will arrive for you to approve in your account.",
            hi: "आपका किराया आवेदन स्वीकृत हो गया है। आपके खाते में अनुमोदन के लिए पट्टा प्रस्ताव आएगा।",
          }
          : {
            ar: "تعذر قبول طلب الإيجار الخاص بك هذه المرة.",
            en: "Your rental application could not be accepted this time.",
            hi: "इस बार आपका किराया आवेदन स्वीकार नहीं किया जा सका।",
          },
        { applicationId: ref.id, listingId: record.listing_id }
      )
    );
  });
  return { success: true, status: data.decision };
});

function requireMoney(value, field) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 || value > 1e9) {
    throw new HttpsError("invalid-argument", `${field} must be a positive number.`);
  }
  if (Math.abs(Math.round(value * 100) - value * 100) > 1e-6) {
    throw new HttpsError("invalid-argument", `${field} can have at most 2 decimals.`, { reason: "rent_precision" });
  }
  return Math.round(value * 100) / 100;
}

/**
 * Turns an approved application into a draft lease. Parties and property come from the
 * application, never from the caller; the lease id is derived from the application, so an
 * application produces at most one lease. The lease stays a draft until the owner or agency sends it
 * to the tenant for approval.
 */
const createLeaseFromApplication = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const role = await requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const data = request.data || {};
  if (typeof data.applicationId !== "string" || !data.applicationId || data.applicationId.includes("/")) {
    throw new HttpsError("invalid-argument", "An application id is required.");
  }
  const start = parseDateOnly(data.startDate, "startDate");
  const end = parseDateOnly(data.endDate, "endDate");
  if (end.getTime() <= start.getTime()) {
    throw new HttpsError("invalid-argument", "endDate must be after startDate.");
  }

  const db = admin.firestore();
  const appRef = db.collection(APPLICATIONS).doc(data.applicationId);
  const leaseRef = db.collection("Leases").doc(`app_${data.applicationId}`);
  return db.runTransaction(async (t) => {
    const appSnap = await t.get(appRef);
    if (!appSnap.exists) throw new HttpsError("not-found", "Application not found.");
    const application = appSnap.data();
    assertManager(auth, role, application);
    if (application.status !== "approved") {
      throw new HttpsError("failed-precondition", "Approve the application before creating a lease.", { reason: "not_approved" });
    }
    const leaseSnap = await t.get(leaseRef);
    if (leaseSnap.exists || application.lease_id || application.consumed_at) {
      throw new HttpsError("already-exists", "A lease was already created from this application.", { leaseId: leaseRef.id, reason: "application_consumed" });
    }
    const listingSnap = await t.get(db.collection("Properties").doc(application.listing_id));
    const listing = listingSnap.exists ? listingSnap.data() : {};
    if (!listingSnap.exists || listing.owner_id !== application.owner_id) {
      throw new HttpsError("failed-precondition", "The listing no longer belongs to this owner.", { reason: "property_not_found" });
    }
    const parties = {
      id: leaseRef.id,
      owner_id: application.owner_id,
      tenant_id: application.applicant_id,
      agency_id: application.agency_id || "",
      property_id: application.listing_id,
    };
    await verifyLeaseProperty(t, db, parties);
    const lock = await readPropertyLock(t, db, parties, deps.now());
    if (lock.heldByOther) throw alreadyLeased(lock.heldByOther);
    const rent = data.monthlyRent === undefined || data.monthlyRent === null
      ? requireMoney(Number(listing.pricePerMonth), "monthlyRent")
      : requireMoney(data.monthlyRent, "monthlyRent");
    const titles = application.listing_titles || {};
    t.create(leaseRef, {
      owner_id: application.owner_id,
      tenant_id: application.applicant_id,
      agency_id: application.agency_id || "",
      property_id: application.listing_id,
      application_id: appSnap.id,
      status: "draft",
      country_code: application.country_code,
      currencyCode: application.country_code === "AE" ? "AED" : "EGP",
      monthly_rent: rent,
      financialTerms: { monthlyRent: rent },
      start_date: data.startDate,
      end_date: data.endDate,
      property_title: titles.en || titles.ar || titles.hi || "",
      tenant_name: application.applicant_name,
      created_by: auth.uid,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    t.update(appRef, { lease_id: leaseRef.id, consumed_at: FieldValue.serverTimestamp(), updated_at: FieldValue.serverTimestamp() });
    return { success: true, leaseId: leaseRef.id, status: "draft" };
  });
});

module.exports = {
  requestViewing,
  respondToViewingRequest,
  applyForRental,
  decideRentalApplication,
  createLeaseFromApplication,
  deps,
};
