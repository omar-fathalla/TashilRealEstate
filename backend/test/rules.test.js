const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "tashil-rules-test";

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
    storage: {
      rules: fs.readFileSync(path.join(__dirname, "../../storage.rules"), "utf8"),
      host: "127.0.0.1",
      port: 9199,
    },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

function authed(uid, role) {
  return testEnv.authenticatedContext(uid, role ? { role } : {});
}

test("a user cannot grant themselves SuperAdmin", async () => {
  const alice = authed("alice");
  await assertSucceeds(alice.firestore().collection("Users").doc("alice").set({
    role: "Tenant",
    email: "alice@demo.tashil.test",
  }));
  await assertFails(alice.firestore().collection("Users").doc("alice").update({
    role: "SuperAdmin",
  }));
  await assertSucceeds(alice.firestore().collection("Users").doc("alice").update({
    displayName: "Alice",
  }));
});

test("a user cannot read another user's profile", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("Users").doc("bob").set({
      role: "Owner",
      email: "bob@demo.tashil.test",
    });
  });
  await assertFails(authed("alice").firestore().collection("Users").doc("bob").get());
});

test("a broker public document cannot store a phone number", async () => {
  const admin = authed("admin", "SuperAdmin");
  await assertFails(admin.firestore().collection("Brokers").doc("broker-1").set({
    agencyId: "agency-1",
    names: { ar: "وسيط", en: "Broker" },
    phone: "+971500000000",
  }));
  await assertSucceeds(admin.firestore().collection("Brokers").doc("broker-1").set({
    agencyId: "agency-1",
    names: { ar: "وسيط", en: "Broker" },
    brokerRegistrationNumber: "BRN-1",
  }));
});

test("storage denies public reads of private files and foreign deletes", async () => {
  const alice = authed("alice");
  const bob = authed("bob");
  const file = alice.storage().ref("users/alice/id.pdf");
  await assertSucceeds(file.put(Buffer.from("identity"), { contentType: "application/pdf" }));
  await assertFails(testEnv.unauthenticatedContext().storage().ref("users/alice/id.pdf").getMetadata());
  await assertFails(bob.storage().ref("users/alice/id.pdf").delete());
});

test("unpublished properties are not readable by a signed-in stranger", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("Properties").doc("draft-1").set({
      owner_id: "owner-1",
      status: "draft",
      is_published: false,
    });
  });
  await assertFails(authed("stranger").firestore().collection("Properties").doc("draft-1").get());
  assert.equal(true, true);
});
