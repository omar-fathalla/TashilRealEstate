// TAQ-149: owner-to-agency mandates and agency self-onboarding.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc: cdoc, getDoc, setDoc } = require("firebase/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");
const mandates = require("../mandates");
const { applicationFrom } = require("../agency_applications");

const db = getFirestore();
const projectId = process.env.GCLOUD_PROJECT;
const caller = (uid, claims = {}) => ({ uid, token: { uid, ...claims } });
const owner = (uid = "ownerA") => caller(uid, { role: "Owner" });
const agency = (id = "agM") => caller(`${id}-admin`, { role: "AgencyAdmin", agency_id: id });
const root = () => caller("root", { role: "SuperAdmin" });
const tenant = () => caller("tenantA", { role: "Tenant" });

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

async function user(uid, claims) {
  await getAuth().createUser({ uid });
  await getAuth().setCustomUserClaims(uid, claims);
  await db.doc(`Users/${uid}`).set({ role: claims.role, full_name: `Name ${uid}`, ...(claims.agency_id ? { agency_id: claims.agency_id } : {}) });
}

async function reason(promise, code, expected) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    if (expected) assert.equal(err.details && err.details.reason, expected);
    return true;
  });
}

const get = async (p) => {
  const snap = await db.doc(p).get();
  return snap.exists ? snap.data() : null;
};

const listing = {
  isPublished: true,
  rentalStatus: "available",
  countryCode: "AE",
  titles: { ar: "شقة", en: "Marina Flat", hi: "अपार्टमेंट" },
  pricePerMonth: 9000,
};

async function ownerWrites(uid, id, data) {
  const ref = db.doc(`Users/${uid}/properties/${id}`);
  const before = await ref.get();
  await ref.set(data);
  const after = await ref.get();
  return fns.syncOwnerPropertyToMarketplace.run({ params: { ownerId: uid, propertyId: id }, data: { before, after } });
}

async function resync(uid, id) {
  const snap = await db.doc(`Users/${uid}/properties/${id}`).get();
  return fns.syncOwnerPropertyToMarketplace.run({ params: { ownerId: uid, propertyId: id }, data: { before: snap, after: snap } });
}

const invite = (auth = agency(), propertyId = "propA") => fns.inviteMandate.run({ data: { propertyId }, auth });
const respond = (accept, auth = owner(), propertyId = "propA") => fns.respondToMandate.run({ data: { propertyId, accept }, auth });
const revoke = (auth = owner(), propertyId = "propA") => fns.revokeMandate.run({ data: { propertyId }, auth });
const offer = (auth, extra = {}) => fns.createLease.run({
  data: { propertyId: "propA", tenantId: "tenantA", startDate: "2026-01-01", endDate: "2099-12-31", monthlyRent: 5000, sendOffer: true, ...extra },
  auth,
});
const accept = (leaseId) => fns.respondToLeaseOffer.run({ data: { leaseId, decision: "approve" }, auth: tenant() });

let rulesEnv;
test.before(async () => {
  rulesEnv = await initializeTestEnvironment({
    projectId: `${projectId}-mandates`,
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});
test.after(async () => {
  mandates.deps.now = () => Date.now();
  if (rulesEnv) await rulesEnv.cleanup();
});

test.beforeEach(async () => {
  mandates.deps.now = () => Date.now();
  await clearAll();
  await user("ownerA", { role: "Owner" });
  await user("ownerB", { role: "Owner" });
  await user("tenantA", { role: "Tenant" });
  await user("root", { role: "SuperAdmin" });
  await user("agM-admin", { role: "AgencyAdmin", agency_id: "agM" });
  await user("agN-admin", { role: "AgencyAdmin", agency_id: "agN" });
  await db.doc("Agencies/agM").set({ name: "Gulf Homes", orn: "12345", verified_badge: true, licence_status: "verified" });
  await db.doc("Agencies/agN").set({ name: "Nile Estates" });
  await ownerWrites("ownerA", "propA", listing);
});

test("TAQ-149: invite, accept, agency leases the property, the owner cannot, and a live lease blocks revoke", async () => {
  assert.equal((await invite()).status, "invited");
  let m = await get("PropertyMandates/propA");
  assert.equal(m.owner_id, "ownerA");
  assert.equal(m.agency_id, "agM");
  assert.equal(m.agency_name, "Gulf Homes");
  assert.equal(m.property_title, "Marina Flat");
  assert.equal(m.country_code, "AE");
  assert.equal(m.price_per_month, 9000);
  assert.ok(m.expires_at.toMillis() > Date.now());

  // Before the owner accepts, the agency cannot lease it.
  await reason(offer(agency(), { ownerId: "ownerA" }), "permission-denied", "property_not_managed");

  assert.equal((await respond(true)).status, "active");
  const pub = await get("Properties/propA");
  assert.equal(pub.agency_id, "agM");
  assert.equal(pub.agencyNames.en, "Gulf Homes");
  assert.equal(pub.agencyOrn, "12345");
  assert.equal((await get("Users/ownerA/properties/propA")).managing_agency_id, "agM");

  // The marketplace sync reaches the same result from the mandate.
  await resync("ownerA", "propA");
  assert.equal((await get("Properties/propA")).agency_id, "agM");

  await reason(offer(owner()), "failed-precondition", "property_agency_managed");
  const { leaseId } = await offer(agency(), { ownerId: "ownerA" });
  assert.equal((await get(`Leases/${leaseId}`)).agency_id, "agM");
  assert.equal((await accept(leaseId)).status, "active");

  await reason(revoke(), "failed-precondition", "mandate_lease_live");
  await reason(revoke(agency()), "failed-precondition", "mandate_lease_live");
  await reason(invite(agency("agN")), "failed-precondition", "mandate_active_other");
  await reason(invite(), "failed-precondition", "mandate_already_active");
});

test("TAQ-149: revoking an active mandate gives the property back to the owner", async () => {
  await invite();
  await respond(true);
  const { leaseId } = await offer(agency(), { ownerId: "ownerA", sendOffer: false });
  assert.equal((await revoke()).status, "revoked");
  const m = await get("PropertyMandates/propA");
  assert.equal(m.status, "revoked");
  assert.equal(m.revoked_by, "ownerA");
  const pub = await get("Properties/propA");
  assert.equal(pub.agency_id, undefined);
  assert.equal(pub.agencyOrn, undefined);
  assert.notEqual(pub.agencyNames.en, "Gulf Homes");
  assert.equal((await get("Users/ownerA/properties/propA")).managing_agency_id, undefined);

  // The agency's old draft can no longer go live, and the agency cannot start a new one.
  await db.doc(`Leases/${leaseId}`).update({ status: "pending_tenant_approval" });
  // (refused at the listing check: the public listing no longer names the agency)
  await reason(accept(leaseId), "failed-precondition", "property_id_conflict");
  await reason(offer(agency(), { ownerId: "ownerA" }), "permission-denied", "property_not_managed");
  // The owner lets it again.
  assert.ok((await offer(owner())).leaseId);
  await reason(revoke(), "failed-precondition", "mandate_not_open");
});

test("TAQ-149: declining, expiry, withdrawing and who may answer", async () => {
  await invite();
  await reason(respond(true, owner("ownerB")), "not-found");
  await reason(respond(true, agency()), "permission-denied");
  await reason(invite(agency("agN")), "failed-precondition", "mandate_pending_other");
  assert.equal((await respond(false)).status, "declined");
  await reason(respond(true), "failed-precondition", "mandate_not_open");

  // Another agency may invite once the first is declined; that agency can withdraw it.
  await invite(agency("agN"));
  await reason(revoke(agency()), "permission-denied");
  await reason(revoke(caller("stranger", { role: "Owner" })), "permission-denied");
  assert.equal((await revoke(agency("agN"))).status, "revoked");

  // An invite older than 30 days cannot be accepted, and no longer blocks another agency.
  await invite();
  mandates.deps.now = () => Date.now() + 31 * 24 * 60 * 60 * 1000;
  await reason(respond(true), "failed-precondition", "mandate_not_open");
  assert.equal((await invite(agency("agN"))).status, "invited");
});

test("TAQ-149: invites are refused for missing, own or agency-owned properties and non-agencies", async () => {
  await reason(invite(owner()), "permission-denied");
  await reason(invite(caller("x", { role: "AgencyAdmin" })), "permission-denied");
  await reason(invite(agency(), "nope"), "failed-precondition", "property_not_registered");
  await ownerWrites("agN-admin", "propN", listing);
  await reason(invite(agency(), "propN"), "failed-precondition", "owner_not_eligible");
  await reason(invite(agency("agN"), "propN"), "failed-precondition", "mandate_own_property");
  await db.doc("Agencies/agM").delete();
  await reason(invite(), "failed-precondition", "agency_not_found");
});

test("TAQ-149: an owner's own live lease blocks accepting a mandate", async () => {
  const { leaseId } = await offer(owner());
  await accept(leaseId);
  await invite();
  await reason(respond(true), "failed-precondition", "mandate_lease_live");
  assert.equal((await respond(false)).status, "declined");
});

test("TAQ-149: the rules let the owner, the agency and SuperAdmin read a mandate, and nobody write it", async () => {
  await invite();
  await rulesEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(cdoc(ctx.firestore(), "PropertyMandates/propA"), { property_id: "propA", owner_id: "ownerA", agency_id: "agM", status: "invited" });
    await setDoc(cdoc(ctx.firestore(), "AgencyApplications/ownerB"), { applicant_id: "ownerB", status: "pending" });
  });
  const as = (uid, claims) => rulesEnv.authenticatedContext(uid, claims).firestore();
  await assertSucceeds(getDoc(cdoc(as("ownerA", { role: "Owner" }), "PropertyMandates/propA")));
  await assertSucceeds(getDoc(cdoc(as("agM-admin", { role: "AgencyAdmin", agency_id: "agM" }), "PropertyMandates/propA")));
  await assertSucceeds(getDoc(cdoc(as("root", { role: "SuperAdmin" }), "PropertyMandates/propA")));
  await assertFails(getDoc(cdoc(as("agN-admin", { role: "AgencyAdmin", agency_id: "agN" }), "PropertyMandates/propA")));
  await assertFails(getDoc(cdoc(as("ownerB", { role: "Owner" }), "PropertyMandates/propA")));
  await assertFails(setDoc(cdoc(as("ownerA", { role: "Owner" }), "PropertyMandates/propA"), { status: "active" }));
  await assertFails(setDoc(cdoc(as("root", { role: "SuperAdmin" }), "PropertyMandates/propA"), { status: "active" }));

  await assertSucceeds(getDoc(cdoc(as("ownerB", { role: "Owner" }), "AgencyApplications/ownerB")));
  await assertSucceeds(getDoc(cdoc(as("root", { role: "SuperAdmin" }), "AgencyApplications/ownerB")));
  await assertFails(getDoc(cdoc(as("ownerA", { role: "Owner" }), "AgencyApplications/ownerB")));
  await assertFails(setDoc(cdoc(as("ownerB", { role: "Owner" }), "AgencyApplications/ownerB"), { status: "approved" }));
});

// --- agency applications ---

const apply = (auth = owner("ownerB"), extra = {}) => fns.applyForAgency.run({
  data: { name: "Dune Realty", countryCode: "AE", city: "Dubai", orn: "77881", licenceNumber: "TL-1", phone: "+971 50 000 0000", ...extra },
  auth,
});
const review = (approve, auth = root(), uid = "ownerB", note) => fns.reviewAgencyApplication.run({ data: { uid, approve, note }, auth });

test("TAQ-149: an applicant applies once; a SuperAdmin approval creates the agency and the role", async () => {
  assert.equal((await apply()).status, "pending");
  const a = await get("AgencyApplications/ownerB");
  assert.equal(a.status, "pending");
  assert.equal(a.name, "Dune Realty");
  await reason(apply(), "already-exists", "application_pending");
  await reason(review(true, owner("ownerA")), "permission-denied");
  await reason(review(true, agency()), "permission-denied");

  const { agencyId, status } = await review(true);
  assert.equal(status, "approved");
  const ag = await get(`Agencies/${agencyId}`);
  assert.equal(ag.name, "Dune Realty");
  assert.equal(ag.licence_status, "pending");
  assert.equal(ag.verified_badge, false);
  assert.equal((await get(`Agencies/${agencyId}/private/profile`)).phone, "+971 50 000 0000");
  const claims = (await getAuth().getUser("ownerB")).customClaims;
  assert.equal(claims.role, "AgencyAdmin");
  assert.equal(claims.agency_id, agencyId);
  assert.equal((await get("AgencyApplications/ownerB")).agency_id, agencyId);
  await reason(review(true), "failed-precondition", "application_not_pending");
  await reason(apply(caller("ownerB", { role: "AgencyAdmin", agency_id: agencyId })), "permission-denied");
});

test("TAQ-149: a rejected applicant may apply again; open leases or mandates block an approval", async () => {
  await apply(owner("ownerA"));
  assert.equal((await review(false, root(), "ownerA", "Licence unreadable")).status, "rejected");
  assert.equal((await get("AgencyApplications/ownerA")).review_note, "Licence unreadable");
  assert.equal((await apply(owner("ownerA"))).status, "pending");

  await offer(owner());
  await reason(review(true, root(), "ownerA"), "failed-precondition", "applicant_has_open_leases");
  await clearLeases();
  await invite();
  await respond(true);
  await reason(review(true, root(), "ownerA"), "failed-precondition", "applicant_has_mandates");
  assert.equal((await getAuth().getUser("ownerA")).customClaims.role, "Owner");

  await apply(tenant());
  const l = await db.collection("Leases").add({ owner_id: "ownerB", tenant_id: "tenantA", status: "active" });
  await reason(review(true, root(), "tenantA"), "failed-precondition", "applicant_has_open_leases");
  await l.update({ status: "terminated" });
  assert.equal((await review(true, root(), "tenantA")).status, "approved");
});

async function clearLeases() {
  const all = await db.collection("Leases").get();
  await Promise.all(all.docs.map((d) => d.ref.delete()));
}

test("TAQ-149: application fields are checked", async () => {
  assert.throws(() => applicationFrom({ name: "A", countryCode: "AE", phone: "+97150000000" }), /name/);
  assert.throws(() => applicationFrom({ name: "Call 050 123 4567 now", countryCode: "AE", phone: "+97150000000" }), /phone, link or email/);
  assert.throws(() => applicationFrom({ name: "Dune", countryCode: "SA", phone: "+97150000000" }), /countryCode/);
  assert.throws(() => applicationFrom({ name: "Dune", countryCode: "AE", phone: "call me" }), /phone/);
  assert.throws(() => applicationFrom({ name: "Dune", countryCode: "AE", phone: "+97150000000", orn: "12 34/5" }), /ORN/);
  assert.equal(applicationFrom({ name: "  Dune   Realty ", countryCode: "EG", phone: "0100 000 0000" }).name, "Dune Realty");
  await reason(apply(caller("anon", { role: "Owner", firebase: { sign_in_provider: "anonymous" } })), "permission-denied");
});
