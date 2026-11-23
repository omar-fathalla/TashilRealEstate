const fs = require("fs");
const path = require("path");
const test = require("node:test");
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

test("TAQ-11: an Owner can create, update, and delete their own listing", async () => {
  await seed("Users/owner", { role: "Owner" });
  const owner = db("owner");
  const ref = doc(owner, "Properties/prop-1");
  await assertSucceeds(setDoc(ref, listing("owner"), { merge: true }));
  await assertSucceeds(setDoc(ref, { pricePerMonth: 9500, owner_id: "owner", updated_at: serverTimestamp() }, { merge: true }));
  await assertSucceeds(setDoc(ref, { is_published: false, status: "rented", owner_id: "owner" }, { merge: true }));
  await assertSucceeds(deleteDoc(ref));
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

test("TAQ-11: an AgencyAdmin can only list under their own agency", async () => {
  const agent = db("agent", { role: "AgencyAdmin", agency_id: "agency-1" });
  await assertSucceeds(setDoc(doc(agent, "Properties/prop-1"), listing("agent", { agency_id: "agency-1" })));
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
  const owner = db("owner");
  await assertSucceeds(setDoc(doc(owner, "Users/owner"), { user_id: "owner", updated_at: serverTimestamp() }, { merge: true }));
  await assertSucceeds(setDoc(doc(owner, "Users/owner/properties/prop-9"), {
    id: "prop-9", owner_id: "owner", isPublished: false, tenantName: "T", tenantPhone: "+971", unitNumber: "12",
  }, { merge: true }));
  // Unpublished: hidden marketplace stub.
  await assertSucceeds(setDoc(doc(owner, "Properties/prop-9"), {
    owner_id: "owner", is_published: false, status: "unavailable", updated_at: serverTimestamp(),
  }, { merge: true }));
  // Published later.
  await assertSucceeds(setDoc(doc(owner, "Properties/prop-9"), listing("owner", {
    id: "prop-9", imageUrls: ["assets/images/properties/prop_eg_6_1.jpg"], updated_at: serverTimestamp(),
  }), { merge: true }));
  await assertSucceeds(deleteDoc(doc(owner, "Users/owner/properties/prop-9")));
  await assertSucceeds(deleteDoc(doc(owner, "Properties/prop-9")));
});

// --- TAQ-18: private fields cannot be written to the public catalog ---

test("TAQ-18: tenant and unit data cannot be written to a public listing", async () => {
  const owner = db("owner");
  await assertFails(setDoc(doc(owner, "Properties/prop-1"), listing("owner", { tenantPhone: "+971500000000" })));
  await seed("Properties/prop-2", listing("owner"));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { tenantName: "Tenant" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { unitNumber: "PH-4502" }));
  await assertFails(updateDoc(doc(owner, "Properties/prop-2"), { installments: [] }));
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
