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
