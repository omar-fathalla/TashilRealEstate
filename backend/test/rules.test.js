const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs,
  serverTimestamp,
} = require("firebase/firestore");

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test",
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8"),
    },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
});

function db(uid, claims) {
  return testEnv.authenticatedContext(uid, claims || {}).firestore();
}

function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seed(docPath, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), docPath), data);
  });
}

function listing(ownerId, extra = {}) {
  return {
    id: "prop-1",
    owner_id: ownerId,
    countryCode: "AE",
    currencyCode: "AED",
    titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" },
    pricePerMonth: 9000,
    status: "vacant",
    is_published: true,
    ...extra,
  };
}

// --- TAQ-8: signup cannot pick an elevated role ---

test("TAQ-8: a new user can create their own profile as Owner or Tenant", async () => {
  await assertSucceeds(setDoc(doc(db("owner"), "Users/owner"), { user_id: "owner", email: "owner@demo.test", role: "Owner" }));
  await assertSucceeds(setDoc(doc(db("tenant"), "Users/tenant"), { user_id: "tenant", email: "tenant@demo.test", role: "Tenant" }));
});

test("TAQ-8: signup with SuperAdmin or AgencyAdmin is rejected", async () => {
  await assertFails(setDoc(doc(db("mallory"), "Users/mallory"), { user_id: "mallory", role: "SuperAdmin" }));
  await assertFails(setDoc(doc(db("mallory"), "Users/mallory"), { user_id: "mallory", role: "AgencyAdmin" }));
});

test("TAQ-8: a user cannot create someone else's profile", async () => {
  await assertFails(setDoc(doc(db("mallory"), "Users/victim"), { user_id: "victim", role: "Owner" }));
});

test("TAQ-8: a SuperAdmin role written into the profile grants nothing without a claim", async () => {
  await seed("Users/legacy", { role: "SuperAdmin" });
  await seed("Users/victim", { role: "Owner", iban: "AE070331234567890123456" });
  await seed("Properties/prop-x", listing("victim", { is_published: false, status: "unavailable" }));
  const legacy = db("legacy");
  await assertFails(updateDoc(doc(legacy, "Properties/prop-x"), { pricePerMonth: 1 }));
  await assertFails(getDoc(doc(legacy, "Properties/prop-x")));
});

test("TAQ-8: a SuperAdmin custom claim is honoured", async () => {
  await seed("Users/victim", { role: "Owner" });
  await assertSucceeds(getDoc(doc(db("admin", { role: "SuperAdmin" }), "Users/victim")));
});

// --- TAQ-9: role and agency are server-controlled ---

test("TAQ-9: an Owner cannot change their own role or agency", async () => {
  await seed("Users/owner", { user_id: "owner", role: "Owner" });
  const owner = db("owner");
  await assertFails(updateDoc(doc(owner, "Users/owner"), { role: "SuperAdmin" }));
  await assertFails(updateDoc(doc(owner, "Users/owner"), { role: "AgencyAdmin" }));
  await assertFails(updateDoc(doc(owner, "Users/owner"), { role: "Tenant" }));
  await assertFails(updateDoc(doc(owner, "Users/owner"), { agency_id: "agency-1" }));
  await assertFails(updateDoc(doc(owner, "Users/owner"), { verified: true }));
});

test("TAQ-9: a new profile cannot carry an agency or verification flag", async () => {
  await assertFails(setDoc(doc(db("mallory"), "Users/mallory"), { user_id: "mallory", role: "Owner", agency_id: "agency-1" }));
  await assertFails(setDoc(doc(db("mallory"), "Users/mallory"), { user_id: "mallory", role: "Owner", verified: true }));
});

test("TAQ-9: an AgencyAdmin cannot move themselves to another agency", async () => {
  await seed("Users/agent", { role: "AgencyAdmin", agency_id: "agency-1" });
  const agent = db("agent", { role: "AgencyAdmin", agency_id: "agency-1" });
  await assertFails(updateDoc(doc(agent, "Users/agent"), { agency_id: "agency-2" }));
});

test("TAQ-9: an Owner can still edit their own profile and bank details", async () => {
  await seed("Users/owner", { user_id: "owner", role: "Owner" });
  const owner = db("owner");
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), {
    full_name: "Owner Demo",
    phone: "+971500000000",
    national_id: "784-0000-0000000-0",
    iban: "AE070331234567890123456",
    updated_at: serverTimestamp(),
  }, { merge: true }));
  // The login flow re-sends the unchanged role; that is not a role change.
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), { role: "Owner", email: "owner@demo.test" }, { merge: true }));
});

test("TAQ-9: a profile created without a role can take a self-service role once", async () => {
  const owner = db("owner");
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), { user_id: "owner", updated_at: serverTimestamp() }, { merge: true }));
  await assertFails(setDoc(doc(owner, "Users/owner"), { role: "SuperAdmin" }, { merge: true }));
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), { role: "Owner" }, { merge: true }));
  await assertFails(setDoc(doc(owner, "Users/owner"), { role: "Tenant" }, { merge: true }));
});

// --- TAQ-50: verification and account state are server-managed ---

const TAQ50_FIELDS = {
  phone_verified: true,
  phoneVerified: true,
  kycStatus: "approved",
  kyc_status: "approved",
  account_status: "active",
  accountStatus: "active",
};

test("TAQ-50: a user cannot set their own phone, KYC, or account status flags", async () => {
  await seed("Users/owner", {
    user_id: "owner", role: "Owner", phone_verified: false, kycStatus: "pending", account_status: "suspended",
  });
  const owner = db("owner");
  for (const [field, value] of Object.entries(TAQ50_FIELDS)) {
    await assertFails(updateDoc(doc(owner, "Users/owner"), { [field]: value }));
    await assertFails(setDoc(doc(owner, "Users/owner"), { [field]: value, full_name: "X" }, { merge: true }));
  }
  await assertFails(updateDoc(doc(owner, "Users/owner"), { phone_verified: false, kycStatus: "rejected" }));
});

test("TAQ-50: a new profile cannot start out verified, KYC-approved, or active", async () => {
  for (const [field, value] of Object.entries(TAQ50_FIELDS)) {
    await assertFails(setDoc(doc(db("mallory"), "Users/mallory"), { user_id: "mallory", role: "Owner", [field]: value }));
  }
});

test("TAQ-50: a profile save that leaves the locked flags untouched still works", async () => {
  await seed("Users/owner", { user_id: "owner", role: "Owner", phone_verified: true, kycStatus: "approved", account_status: "active" });
  const owner = db("owner");
  // Matches UserProfileService.updateProfile, which no longer sends phone_verified.
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), {
    full_name: "Owner Demo", first_name: "Owner", surname: "Demo", phone: "+971500000000",
    preferred_contact_method: "phone", updated_at: serverTimestamp(),
  }, { merge: true }));
  const root = db("root", { role: "SuperAdmin" });
  await assertSucceeds(updateDoc(doc(root, "Users/owner"), { kycStatus: "rejected", account_status: "suspended" }));
});

// --- TAQ-53: remaining trust and plan fields are server-managed ---

const TAQ53_FIELDS = {
  is_verified: true,
  kyc_verified: true,
  isPhoneVerified: true,
  email_verified: true,
  Role: "SuperAdmin",
  role_updated_by: "root",
  role_updated_at: new Date("2026-01-01T00:00:00Z"),
  plan: "Enterprise",
};

test("TAQ-53: a user cannot set trust, role audit, or plan fields on their profile", async () => {
  await seed("Users/owner", { user_id: "owner", role: "Owner" });
  const owner = db("owner");
  for (const [field, value] of Object.entries(TAQ53_FIELDS)) {
    await assertFails(updateDoc(doc(owner, "Users/owner"), { [field]: value }), field);
    await assertFails(setDoc(doc(owner, "Users/owner"), { [field]: value, full_name: "X" }, { merge: true }), field);
  }
});

test("TAQ-53: a user cannot change server-set values of those fields", async () => {
  await seed("Users/owner", {
    user_id: "owner", role: "Owner", is_verified: false, kyc_verified: false, isPhoneVerified: false,
    email_verified: false, role_updated_by: "root", plan: "Free",
  });
  const owner = db("owner");
  await assertFails(updateDoc(doc(owner, "Users/owner"), { is_verified: true }));
  await assertFails(updateDoc(doc(owner, "Users/owner"), { plan: "Enterprise" }));
  await assertFails(updateDoc(doc(owner, "Users/owner"), { role_updated_by: "owner" }));
});

test("TAQ-53: a new profile cannot carry trust, role audit, or plan fields", async () => {
  for (const [field, value] of Object.entries(TAQ53_FIELDS)) {
    await assertFails(setDoc(doc(db("mallory"), "Users/mallory"), { user_id: "mallory", role: "Owner", [field]: value }), field);
  }
});

test("TAQ-53: normal profile saves and SuperAdmin updates still work", async () => {
  await seed("Users/owner", { user_id: "owner", role: "Owner", is_verified: true, plan: "Free", role_updated_by: "root" });
  const owner = db("owner");
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), {
    full_name: "Owner Demo", phone: "+971500000000", updated_at: serverTimestamp(),
  }, { merge: true }));
  const root = db("root", { role: "SuperAdmin" });
  await assertSucceeds(updateDoc(doc(root, "Users/owner"), { is_verified: false, plan: "Enterprise" }));
});

test("TAQ-9: users cannot delete their profile to reset their role", async () => {
  await seed("Users/owner", { role: "Owner" });
  await assertFails(deleteDoc(doc(db("owner"), "Users/owner")));
});

// --- TAQ-10: profile PII is private ---

test("TAQ-10: a signed-in user cannot read another user's profile", async () => {
  await seed("Users/bob", { role: "Owner", national_id: "29801011234567", iban: "EG380019000500000000263180002" });
  await assertFails(getDoc(doc(db("alice", { role: "Owner" }), "Users/bob")));
  await assertFails(getDoc(doc(db("agent", { role: "AgencyAdmin", agency_id: "agency-1" }), "Users/bob")));
  await assertFails(getDocs(collection(db("alice"), "Users")));
  await assertFails(getDoc(doc(anonDb(), "Users/bob")));
});

test("TAQ-10: a self-assigned SuperAdmin profile cannot read other profiles", async () => {
  await seed("Users/legacy", { role: "SuperAdmin" });
  await seed("Users/victim", { role: "Owner", iban: "AE070331234567890123456" });
  await assertFails(getDoc(doc(db("legacy"), "Users/victim")));
});

test("TAQ-10: a user can read their own profile", async () => {
  await seed("Users/bob", { role: "Owner", iban: "EG380019000500000000263180002" });
  await assertSucceeds(getDoc(doc(db("bob"), "Users/bob")));
});

test("owner private property tree is private to its owner", async () => {
  const owner = db("owner");
  await assertSucceeds(setDoc(doc(owner, "Users/owner/properties/prop-1"), { tenantName: "Tenant", tenantPhone: "+20100" }));
  await assertSucceeds(getDoc(doc(owner, "Users/owner/properties/prop-1")));
  await assertSucceeds(deleteDoc(doc(owner, "Users/owner/properties/prop-1")));
  await seed("Users/owner/properties/prop-2", { tenantName: "Tenant" });
  await assertFails(getDoc(doc(db("stranger"), "Users/owner/properties/prop-2")));
  await assertFails(setDoc(doc(db("stranger"), "Users/owner/properties/prop-3"), { title: "x" }));
});

test("notifications are readable by their recipient and written by the server only", async () => {
  await seed("Users/tenant/notifications/n1", { recipientId: "tenant" });
  await assertSucceeds(getDoc(doc(db("tenant"), "Users/tenant/notifications/n1")));
  await assertFails(getDoc(doc(db("stranger"), "Users/tenant/notifications/n1")));
  await assertFails(setDoc(doc(db("tenant"), "Users/tenant/notifications/n2"), { recipientId: "tenant" }));
});

// --- TAQ-11: properties are created in the creator's own name ---

test("TAQ-11: an Owner can delete their own listing", async () => {
  await seed("Users/owner", { role: "Owner" });
  await seed("Properties/prop-1", listing("owner"));
  await assertSucceeds(deleteDoc(doc(db("owner"), "Properties/prop-1")));
});

test("TAQ-11: a user cannot create a listing for another owner or without an owner", async () => {
  const mallory = db("mallory", { role: "Owner" });
  await assertFails(setDoc(doc(mallory, "Properties/prop-1"), listing("victim")));
  const { owner_id: _omit, ...noOwner } = listing("x");
  await assertFails(setDoc(doc(mallory, "Properties/prop-2"), noOwner));
});

test("TAQ-11: an Owner cannot attach a listing to an agency", async () => {
  await assertFails(setDoc(doc(db("owner"), "Properties/prop-1"), listing("owner", { agency_id: "agency-1" })));
});

test("TAQ-11: an AgencyAdmin cannot list under another agency", async () => {
  const agent = db("agent", { role: "AgencyAdmin", agency_id: "agency-1" });
  await assertFails(setDoc(doc(agent, "Properties/prop-2"), listing("agent", { agency_id: "agency-2" })));
  const selfMadeAgent = db("fake", { role: "Owner" });
  await seed("Users/fake", { role: "AgencyAdmin", agency_id: "agency-1" });
  await assertFails(setDoc(doc(selfMadeAgent, "Properties/prop-3"), listing("fake", { agency_id: "agency-1" })));
});

test("TAQ-11: ownership and agency cannot be reassigned on update", async () => {
  await seed("Properties/prop-1", listing("owner"));
  const owner = db("owner");
  await assertFails(updateDoc(doc(owner, "Properties/prop-1"), { owner_id: "someone-else" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-1"), { agency_id: "agency-1" }));
});

test("TAQ-11: a user cannot edit or delete someone else's listing", async () => {
  await seed("Properties/prop-1", listing("victim"));
  const mallory = db("mallory", { role: "Owner" });
  await assertFails(updateDoc(doc(mallory, "Properties/prop-1"), { pricePerMonth: 1 }));
  await assertFails(setDoc(doc(mallory, "Properties/prop-1"), { pricePerMonth: 1, owner_id: "mallory" }, { merge: true }));
  await assertFails(deleteDoc(doc(mallory, "Properties/prop-1")));
});

test("TAQ-11: unpublished listings are hidden from strangers but visible to their owner", async () => {
  await seed("Properties/draft-1", listing("owner", { status: "unavailable", is_published: false }));
  await assertFails(getDoc(doc(db("stranger"), "Properties/draft-1")));
  await assertFails(getDoc(doc(anonDb(), "Properties/draft-1")));
  await assertSucceeds(getDoc(doc(db("owner"), "Properties/draft-1")));
});

test("TAQ-11: visitors can still browse published listings", async () => {
  await seed("Properties/pub-1", listing("owner"));
  await seed("Properties/draft-1", listing("owner", { status: "unavailable", is_published: false }));
  await assertSucceeds(getDoc(doc(anonDb(), "Properties/pub-1")));
  await assertSucceeds(getDocs(query(collection(anonDb(), "Properties"), where("is_published", "==", true))));
  await assertSucceeds(getDocs(query(
    collection(anonDb(), "Properties"),
    where("is_published", "==", true),
    where("countryCode", "==", "AE"),
  )));
});

test("TAQ-11: the Owner save flow from FirestoreService.saveOwnerProperty is allowed", async () => {
  await seed("Users/owner", { role: "Owner" });
  const owner = db("owner");
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), { user_id: "owner", updated_at: serverTimestamp() }, { merge: true }));
  await assertSucceeds(setDoc(doc(owner, "Users/owner/properties/prop-9"), {
    id: "prop-9", owner_id: "owner", isPublished: false, tenantName: "T", tenantPhone: "+971", unitNumber: "12",
  }, { merge: true }));
  await assertSucceeds(setDoc(doc(owner, "Users/owner/properties/prop-9"), { isPublished: true }, { merge: true }));
  await assertSucceeds(deleteDoc(doc(owner, "Users/owner/properties/prop-9")));
});

// --- TAQ-18: private fields cannot be written to the public catalog ---

test("TAQ-18: tenant and unit data cannot be written to a public listing", async () => {
  const owner = db("owner");
  await assertFails(setDoc(doc(owner, "Properties/prop-1"), listing("owner", { tenantPhone: "+971500000000" })));
  await seed("Properties/prop-2", listing("owner", { id: "prop-2" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { tenantName: "Tenant" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { unitNumber: "PH-4502" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { installments: [] }));
});

// --- TAQ-47: public listings only accept allowlisted fields ---

test("TAQ-47: contact fields outside the allowlist cannot be written", async () => {
  const owner = db("root", { role: "SuperAdmin" });
  for (const field of ["whatsapp", "phone", "email", "ownerWhatsapp", "contactPhone", "website"]) {
    await assertFails(setDoc(doc(owner, "Properties/prop-1"), listing("owner", { [field]: "+971500000000" })));
  }
  await seed("Properties/prop-2", listing("owner", { id: "prop-2" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { whatsapp: "+971500000000" }));
  await assertFails(setDoc(doc(owner, "Properties/prop-2"), { email: "me@example.com" }, { merge: true }));
});

test("TAQ-47: localized maps only carry ar/en/hi", async () => {
  const owner = db("root", { role: "SuperAdmin" });
  await assertFails(setDoc(doc(owner, "Properties/prop-1"), listing("owner", {
    titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट", phone: "+971500000000" },
  })));
  await seed("Properties/prop-2", listing("owner", { id: "prop-2" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { "descriptions.whatsapp": "+971500000000" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { locations: "Call +971500000000" }));
});

test("TAQ-47: the platform agency contact is server-managed", async () => {
  await seed("Users/owner", { role: "Owner" });
  const owner = db("owner");
  await seed("Properties/prop-2", listing("owner", {
    id: "prop-2",
    agencyPhone: "+20 100 123 4567",
    agencyNames: { ar: "تسهيل", en: "Tashil", hi: "तशिल" },
  }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { agencyPhone: "+971500000000" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { "agencyNames.en": "Call me" }));
});

test("TAQ-47: a listing id must match its document id", async () => {
  await assertFails(setDoc(doc(db("root", { role: "SuperAdmin" }), "Properties/prop-1"), listing("owner", { id: "someone-elses-id" })));
});

// --- TAQ-48: only published listings are public ---

test("TAQ-48: a vacant but unpublished listing is hidden from the public", async () => {
  await seed("Properties/prop-1", listing("owner", { status: "vacant", is_published: false }));
  await seed("Properties/prop-2", (({ is_published: _omit, ...rest }) => ({ ...rest, id: "prop-2" }))(listing("owner")));
  for (const reader of [anonDb(), db("stranger"), db("tenant", { role: "Tenant" }), db("agent2", { role: "AgencyAdmin", agency_id: "agency-2" })]) {
    await assertFails(getDoc(doc(reader, "Properties/prop-1")));
    await assertFails(getDoc(doc(reader, "Properties/prop-2")));
  }
  await assertFails(getDocs(query(collection(anonDb(), "Properties"), where("status", "==", "vacant"))));
});

test("TAQ-48: unpublished listings stay visible to their owner, agency, and SuperAdmin", async () => {
  await seed("Properties/prop-1", listing("owner", { status: "vacant", is_published: false, agency_id: "agency-1" }));
  await assertSucceeds(getDoc(doc(db("owner"), "Properties/prop-1")));
  await assertSucceeds(getDoc(doc(db("agent1", { role: "AgencyAdmin", agency_id: "agency-1" }), "Properties/prop-1")));
  await assertSucceeds(getDoc(doc(db("root", { role: "SuperAdmin" }), "Properties/prop-1")));
});

test("TAQ-48: marketplace search over published listings still works", async () => {
  await seed("Properties/pub-1", listing("owner", { id: "pub-1" }));
  await seed("Properties/pub-2", listing("owner", { id: "pub-2", countryCode: "EG", currencyCode: "EGP" }));
  await seed("Properties/hidden-1", listing("owner", { id: "hidden-1", is_published: false }));
  const all = await assertSucceeds(getDocs(query(collection(anonDb(), "Properties"), where("is_published", "==", true))));
  assert.deepEqual(all.docs.map((d) => d.id).sort(), ["pub-1", "pub-2"]);
  const ae = await assertSucceeds(getDocs(query(
    collection(anonDb(), "Properties"),
    where("is_published", "==", true),
    where("countryCode", "==", "AE"),
  )));
  assert.deepEqual(ae.docs.map((d) => d.id), ["pub-1"]);
});

// --- TAQ-49: only Owners and AgencyAdmins can publish listings ---

test("TAQ-49: a Tenant cannot create a public listing", async () => {
  await seed("Users/tenant", { role: "Tenant" });
  await assertFails(setDoc(doc(db("tenant"), "Properties/prop-1"), listing("tenant")));
  await assertFails(setDoc(doc(db("tenant2", { role: "Tenant" }), "Properties/prop-1"), listing("tenant2")));
  // A profile with no role is not trusted either.
  await seed("Users/norole", { full_name: "No Role" });
  await assertFails(setDoc(doc(db("norole"), "Properties/prop-1"), listing("norole")));
});

test("TAQ-49: a Tenant cannot republish a listing they hold, but can remove it", async () => {
  await seed("Users/tenant", { role: "Tenant" });
  await seed("Properties/prop-1", listing("tenant", { is_published: false, status: "unavailable" }));
  const tenant = db("tenant");
  await assertFails(updateDoc(doc(tenant, "Properties/prop-1"), { is_published: true, status: "vacant" }));
  await assertSucceeds(deleteDoc(doc(tenant, "Properties/prop-1")));
});

// --- TAQ-51: only the sync trigger writes public listings ---

test("TAQ-51: no client can claim an unused listing id", async () => {
  await seed("Users/owner", { role: "Owner" });
  const squatters = [
    ["owner", db("owner")],
    ["owner2", db("owner2", { role: "Owner" })],
    ["agent", db("agent", { role: "AgencyAdmin", agency_id: "agency-1" })],
  ];
  for (const [uid, client] of squatters) {
    const ref = doc(client, "Properties/future-id");
    await assertFails(setDoc(ref, listing(uid, { id: "future-id" })));
    await assertFails(setDoc(ref, { owner_id: uid, is_published: false, status: "unavailable" }, { merge: true }));
    await assertFails(setDoc(ref, listing(uid, { id: "future-id", agency_id: "agency-1" })));
  }
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const snap = await getDoc(doc(ctx.firestore(), "Properties/future-id"));
    assert.equal(snap.exists(), false);
  });
});

test("TAQ-51: owners and agencies cannot edit a listing directly", async () => {
  await seed("Users/owner", { role: "Owner" });
  await seed("Properties/prop-1", listing("owner", { agency_id: "agency-1" }));
  const owner = db("owner");
  await assertFails(updateDoc(doc(owner, "Properties/prop-1"), { pricePerMonth: 9500 }));
  await assertFails(setDoc(doc(owner, "Properties/prop-1"), { is_published: false, status: "rented" }, { merge: true }));
  const agent = db("agent", { role: "AgencyAdmin", agency_id: "agency-1" });
  await assertFails(updateDoc(doc(agent, "Properties/prop-1"), { pricePerMonth: 9500 }));
  await assertSucceeds(deleteDoc(doc(agent, "Properties/prop-1")));
});

test("TAQ-51: a SuperAdmin can still moderate listings directly", async () => {
  const root = db("root", { role: "SuperAdmin" });
  await assertSucceeds(setDoc(doc(root, "Properties/prop-1"), listing("owner")));
  await assertSucceeds(updateDoc(doc(root, "Properties/prop-1"), { is_published: false, status: "unavailable" }));
  await assertSucceeds(deleteDoc(doc(root, "Properties/prop-1")));
});

// --- TAQ-52: direct listing writes are value-checked ---

const PROJECT_ID = process.env.GCLOUD_PROJECT || "demo-tashil-test";
const PROD_PROJECT = "tashil-proptech-os";
const PROJECT_IMAGE = `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}.firebasestorage.app/o/listings%2Fprop-1%2Fa.jpg?alt=media&token=t`;

test("TAQ-52: a well-formed listing is accepted", async () => {
  const root = db("root", { role: "SuperAdmin" });
  await assertSucceeds(setDoc(doc(root, "Properties/prop-1"), listing("owner", {
    descriptions: { ar: "شقة واسعة", en: "Spacious flat, 3 rooms, 15000000 EGP", hi: "विवरण" },
    locations: { ar: "دبي", en: "Dubai Marina", hi: "दुबई" },
    buildingName: "Marina Tower 2",
    bedrooms: 0,
    bathrooms: 1,
    areaSqM: 85.5,
    rating: 4.5,
    isFeatured: true,
    isFurnished: false,
    image: PROJECT_IMAGE,
    imageUrls: [
      PROJECT_IMAGE,
      `https://storage.googleapis.com/${PROJECT_ID}.appspot.com/listings/b.webp`,
      "assets/images/properties/prop_eg_6_1.jpg",
      "prop_eg_6_2.jpg",
      "data:image/jpeg;base64,/9j/AAAA",
      ...Array(15).fill(PROJECT_IMAGE),
    ],
    amenitiesMap: { ar: Array(30).fill("مسبح"), en: Array(30).fill("Pool"), hi: Array(30).fill("पूल") },
    updated_at: serverTimestamp(),
  })));
});

test("TAQ-52: out-of-range or wrongly typed values are rejected", async () => {
  const root = db("root", { role: "SuperAdmin" });
  const ref = doc(root, "Properties/prop-1");
  const bad = [
    { rating: 999 },
    { rating: -1 },
    { rating: "5" },
    { isFeatured: "yes" },
    { is_published: "true" },
    { pricePerMonth: -500 },
    { pricePerMonth: 0 },
    { pricePerMonth: "9000" },
    { areaSqM: -10 },
    { areaSqM: 0 },
    { bedrooms: -1 },
    { bathrooms: 1000 },
    { status: "sold" },
    { status: "" },
    { countryCode: "US" },
    { countryCode: "AE", currencyCode: "EGP" },
    { buildingName: "x".repeat(201) },
    { titles: { ar: "شقة", en: "x".repeat(201), hi: "अपार्टमेंट" } },
    { descriptions: { en: 42 } },
  ];
  for (const extra of bad) {
    await assertFails(setDoc(ref, listing("owner", extra)), JSON.stringify(extra));
  }
  const { pricePerMonth: _omit, ...noPrice } = listing("owner");
  await assertFails(setDoc(ref, noPrice));
});

test("TAQ-52: image references must be from this project's bucket or the app bundle", async () => {
  const root = db("root", { role: "SuperAdmin" });
  const ref = doc(root, "Properties/prop-1");
  const badImages = [
    "javascript:alert(1)",
    "http://evil.example.com/a.jpg",
    "https://images.unsplash.com/photo-1",
    "https://firebasestorage.googleapis.com/v0/b/other-project.appspot.com/o/a.jpg?alt=media",
    `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}.firebasestorage.app/o/kyc%2Fpassport.jpg?alt=media`,
    `https://storage.googleapis.com/${PROJECT_ID}.appspot.com/users/owner/id.jpg`,
    "assets/../secrets.png",
    "data:image/svg+xml;base64,PHN2Zz4=",
    "data:text/html;base64,PGgxPg==",
  ];
  for (const image of badImages) {
    await assertFails(setDoc(ref, listing("owner", { image })), image);
    await assertFails(setDoc(ref, listing("owner", { imageUrls: [PROJECT_IMAGE, PROJECT_IMAGE, PROJECT_IMAGE, PROJECT_IMAGE, image] })), image);
  }
  await assertFails(setDoc(ref, listing("owner", { imageUrls: Array(21).fill(PROJECT_IMAGE) })));
});

test("TAQ-52: phone numbers and emails are rejected in free text", async () => {
  const root = db("root", { role: "SuperAdmin" });
  const ref = doc(root, "Properties/prop-1");
  const bad = [
    { buildingName: "Tower call 0501234567" },
    { buildingName: "+971 50 123 4567" },
    { buildingName: "برج ٠١٠٠١٢٣٤٥٦٧" },
    { titles: { ar: "شقة", en: "Flat (050) 123-4567", hi: "फ्लैट" } },
    { descriptions: { ar: "وصف", en: "Mail me: owner@example.com", hi: "विवरण" } },
    { locations: { ar: "دبي", en: "Dubai", hi: "संपर्क ۰۵۰۱۲۳۴۵۶۷۸" } },
  ];
  for (const extra of bad) {
    await assertFails(setDoc(ref, listing("owner", extra)), JSON.stringify(extra));
  }
});

// --- TAQ-57: the allowed Storage bucket follows the project the rules run in ---

const FOREIGN_PROJECT_IMAGE = (project) => `https://firebasestorage.googleapis.com/v0/b/${project}.firebasestorage.app/o/listings%2Fa.jpg?alt=media`;

test("TAQ-57: a listing whose images are in this project's own bucket can be moderated", async () => {
  const root = db("root", { role: "SuperAdmin" });
  for (const suffix of ["firebasestorage.app", "appspot.com"]) {
    await assertSucceeds(setDoc(doc(root, "Properties/prop-1"), listing("owner", {
      image: `https://firebasestorage.googleapis.com/v0/b/${PROJECT_ID}.${suffix}/o/listings%2Fa.jpg?alt=media`,
      imageUrls: [`https://storage.googleapis.com/${PROJECT_ID}.${suffix}/listings/b.jpg`],
    })));
  }
});

test("TAQ-57: another project's bucket, including the prod one, is rejected outside that project", async () => {
  const root = db("root", { role: "SuperAdmin" });
  const ref = doc(root, "Properties/prop-1");
  for (const project of [PROD_PROJECT, "demo-someone-else", `${PROJECT_ID}-2`, `x${PROJECT_ID}`]) {
    await assertFails(setDoc(ref, listing("owner", { image: FOREIGN_PROJECT_IMAGE(project) })), project);
    await assertFails(setDoc(ref, listing("owner", { imageUrls: [FOREIGN_PROJECT_IMAGE(project)] })), project);
  }
});

test("TAQ-57: in the prod project the prod bucket is accepted and other buckets are not", async () => {
  const prodEnv = await initializeTestEnvironment({
    projectId: PROD_PROJECT,
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
  try {
    const root = prodEnv.authenticatedContext("root", { role: "SuperAdmin" }).firestore();
    const ref = doc(root, "Properties/prop-1");
    await assertSucceeds(setDoc(ref, listing("owner", {
      image: FOREIGN_PROJECT_IMAGE(PROD_PROJECT),
      imageUrls: [
        FOREIGN_PROJECT_IMAGE(PROD_PROJECT),
        "https://storage.googleapis.com/tashil-proptech-os.appspot.com/listings/b.webp",
      ],
    })));
    await assertFails(setDoc(ref, listing("owner", { image: FOREIGN_PROJECT_IMAGE(PROJECT_ID) })));
    await assertFails(setDoc(ref, listing("owner", { imageUrls: [FOREIGN_PROJECT_IMAGE("demo-someone-else")] })));
  } finally {
    await prodEnv.cleanup();
  }
});

// --- TAQ-58: every client write path to /Properties is denied (TAQ-51), including the ones
// the older rules suites used to expect to succeed ---

test("TAQ-58: owners, agencies, tenants, and visitors cannot create, update, or merge /Properties", async () => {
  await seed("Users/owner", { role: "Owner" });
  await seed("Users/tenant", { role: "Tenant" });
  await seed("Properties/existing", listing("owner", { id: "existing", agency_id: "agency-1" }));
  const actors = [
    { label: "owner", uid: "owner", client: db("owner") },
    { label: "owner (claim)", uid: "owner", client: db("owner", { role: "Owner" }) },
    { label: "agency admin", uid: "agent", client: db("agent", { role: "AgencyAdmin", agency_id: "agency-1" }), agency_id: "agency-1" },
    { label: "tenant", uid: "tenant", client: db("tenant") },
    { label: "signed in, no role", uid: "nobody", client: db("nobody") },
    { label: "visitor", uid: "anon", client: anonDb() },
  ];
  for (const { label, uid, client, agency_id } of actors) {
    const fresh = doc(client, "Properties/new-id");
    const existing = doc(client, "Properties/existing");
    const extra = agency_id ? { agency_id } : {};
    await assertFails(setDoc(fresh, listing(uid, { id: "new-id", ...extra })), label);
    await assertFails(setDoc(fresh, { owner_id: uid, is_published: false, status: "unavailable" }, { merge: true }), label);
    await assertFails(setDoc(existing, listing("owner", { agency_id: "agency-1", pricePerMonth: 9500 })), label);
    await assertFails(updateDoc(existing, { pricePerMonth: 9500 }), label);
    await assertFails(updateDoc(existing, { is_published: false, status: "unavailable" }), label);
    await assertFails(setDoc(existing, { rating: 5, isFeatured: true }, { merge: true }), label);
  }
});

// --- TAQ-17: lease documents are the source of truth for party checks ---

test("TAQ-17: lease parties can read; outsiders cannot write leases", async () => {
  await seed("Leases/lease-1", { owner_id: "owner", tenant_id: "tenant", agency_id: "agency-1", monthly_rent: 5000 });
  await assertSucceeds(getDoc(doc(db("owner"), "Leases/lease-1")));
  await assertSucceeds(getDoc(doc(db("tenant"), "Leases/lease-1")));
  await assertFails(getDoc(doc(db("stranger"), "Leases/lease-1")));
  await assertFails(updateDoc(doc(db("owner"), "Leases/lease-1"), { monthly_rent: 1 }));
  const otherAgency = db("agent2", { role: "AgencyAdmin", agency_id: "agency-2" });
  await assertFails(getDoc(doc(otherAgency, "Leases/lease-1")));
  await assertFails(updateDoc(doc(otherAgency, "Leases/lease-1"), { monthly_rent: 1 }));
  await assertFails(setDoc(doc(otherAgency, "Leases/lease-2"), { owner_id: "owner", tenant_id: "tenant", agency_id: "agency-1" }));
  const agency = db("agent1", { role: "AgencyAdmin", agency_id: "agency-1" });
  await assertSucceeds(updateDoc(doc(agency, "Leases/lease-1"), { monthly_rent: 5200 }));
  await assertFails(updateDoc(doc(agency, "Leases/lease-1"), { agency_id: "agency-2" }));
});
