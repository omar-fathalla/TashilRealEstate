const fs = require("fs");
const path = require("path");
const test = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
} = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs } = require("firebase/firestore");

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test",
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "AiRateLimits", "uid_u1"), { day: "2026-11-24", dayCount: 199 });
    await setDoc(doc(ctx.firestore(), "AiRateLimits", "visitors_global"), { day: "2026-11-24", dayCount: 5 });
  });
});

const contexts = () => [
  ["visitor", testEnv.unauthenticatedContext().firestore()],
  ["owner of the bucket", testEnv.authenticatedContext("u1").firestore()],
  ["SuperAdmin", testEnv.authenticatedContext("root", { role: "SuperAdmin" }).firestore()],
];

test("TAQ-19: no client can read the AI rate-limit counters, including its own", async () => {
  for (const [, db] of contexts()) {
    await assertFails(getDoc(doc(db, "AiRateLimits", "uid_u1")));
    await assertFails(getDoc(doc(db, "AiRateLimits", "visitors_global")));
    await assertFails(getDocs(collection(db, "AiRateLimits")));
  }
});

test("TAQ-19: no client can reset or forge an AI rate-limit counter", async () => {
  for (const [, db] of contexts()) {
    await assertFails(updateDoc(doc(db, "AiRateLimits", "uid_u1"), { dayCount: 0 }));
    await assertFails(setDoc(doc(db, "AiRateLimits", "uid_u1"), { day: "2026-11-24", dayCount: 0 }));
    await assertFails(setDoc(doc(db, "AiRateLimits", "uid_new"), { dayCount: 0 }));
    await assertFails(deleteDoc(doc(db, "AiRateLimits", "uid_u1")));
  }
});
