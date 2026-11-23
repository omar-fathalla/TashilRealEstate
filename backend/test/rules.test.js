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
