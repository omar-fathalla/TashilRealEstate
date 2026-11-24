const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { doc, setDoc } = require("firebase/firestore");

if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Storage emulator is attached.");
}

const projectId = process.env.GCLOUD_PROJECT || "demo-tashil-test";
let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
    storage: { rules: fs.readFileSync(path.join(__dirname, "../../storage.rules"), "utf8") },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test.beforeEach(async () => {
  await Promise.all([testEnv.clearFirestore(), testEnv.clearStorage()]);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "Users/ownerA/properties/propA"), { owner_id: "ownerA" });
    await setDoc(doc(db, "Users/ownerB/properties/propB"), { owner_id: "ownerB" });
    const storage = ctx.storage();
    await storage.ref("public/listings/ownerA/propA/front.jpg").put(bytes(16), { contentType: "image/jpeg" });
    await storage.ref("users/ownerA/kyc/id.jpg").put(bytes(16), { contentType: "image/jpeg" });
    await storage.ref("users/x/id.jpg").put(bytes(16), { contentType: "image/jpeg" });
    await storage.ref("root.jpg").put(bytes(16), { contentType: "image/jpeg" });
  });
});

function bytes(size) {
  return new Uint8Array(size);
}

function anon() {
  return testEnv.unauthenticatedContext().storage();
}

function as(uid, claims = {}) {
  return testEnv.authenticatedContext(uid, claims).storage();
}

const superAdmin = () => as("root", { role: "SuperAdmin" });
const jpeg = { contentType: "image/jpeg" };

// --- TAQ-14: reads ---

test("TAQ-14: a visitor can read public listing photos", async () => {
  await assertSucceeds(anon().ref("public/listings/ownerA/propA/front.jpg").getDownloadURL());
  await assertSucceeds(anon().ref("public/listings/ownerA/propA/front.jpg").getMetadata());
});

test("TAQ-14: a visitor cannot read private files, the bucket root, or list folders", async () => {
  await assertFails(anon().ref("users/x/id.jpg").getDownloadURL());
  await assertFails(anon().ref("users/ownerA/kyc/id.jpg").getMetadata());
  await assertFails(anon().ref("root.jpg").getDownloadURL());
  await assertFails(anon().ref().listAll());
  await assertFails(anon().ref("users/x").listAll());
});

test("TAQ-14: a signed-in user reads only their own private files", async () => {
  await assertSucceeds(as("ownerA").ref("users/ownerA/kyc/id.jpg").getDownloadURL());
  await assertFails(as("ownerB").ref("users/ownerA/kyc/id.jpg").getDownloadURL());
  await assertFails(as("ownerB", { role: "AgencyAdmin", agency_id: "agency-1" }).ref("users/ownerA/kyc/id.jpg").getDownloadURL());
  await assertFails(as("ownerB").ref("root.jpg").getDownloadURL());
});

test("TAQ-14: a SuperAdmin can read and delete private files", async () => {
  await assertSucceeds(superAdmin().ref("users/x/id.jpg").getDownloadURL());
  await assertSucceeds(superAdmin().ref("users/ownerA/kyc/id.jpg").getMetadata());
  await assertSucceeds(superAdmin().ref("users/x/id.jpg").delete());
});

test("TAQ-14: a SuperAdmin role written into a profile without a claim grants nothing", async () => {
  await testEnv.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), "Users/legacy"), { role: "SuperAdmin" }));
  await assertFails(as("legacy").ref("users/x/id.jpg").getDownloadURL());
});

// --- TAQ-14: private writes ---

test("TAQ-14: an owner writes images, PDFs and audio under their own folder", async () => {
  const storage = as("ownerA");
  await assertSucceeds(storage.ref("users/ownerA/kyc/passport.png").put(bytes(32), { contentType: "image/png" }));
  await assertSucceeds(storage.ref("users/ownerA/contracts/lease.pdf").put(bytes(32), { contentType: "application/pdf" }));
  await assertSucceeds(storage.ref("users/ownerA/voice/note.m4a").put(bytes(32), { contentType: "audio/mp4" }));
  await assertSucceeds(storage.ref("users/ownerA/kyc/passport.png").delete());
});

test("TAQ-14: user A cannot write into user B's folder", async () => {
  await assertFails(as("ownerA").ref("users/ownerB/kyc/id.jpg").put(bytes(32), jpeg));
  await assertFails(as("ownerA").ref("users/x/id.jpg").delete());
  await assertFails(anon().ref("users/ownerA/kyc/new.jpg").put(bytes(32), jpeg));
  await assertFails(superAdmin().ref("users/ownerA/kyc/new.jpg").put(bytes(32), jpeg));
});

test("TAQ-14: oversized and non-media private uploads are rejected", async () => {
  const storage = as("ownerA");
  await assertFails(storage.ref("users/ownerA/kyc/big.jpg").put(bytes(11 * 1024 * 1024), jpeg));
  await assertFails(storage.ref("users/ownerA/page.html").put(bytes(32), { contentType: "text/html" }));
  await assertFails(storage.ref("users/ownerA/app.js").put(bytes(32), { contentType: "application/javascript" }));
});

// --- TAQ-14: public listing writes ---

test("TAQ-14: an owner uploads listing photos only under a property in their own tree", async () => {
  const storage = as("ownerA");
  await assertSucceeds(storage.ref("public/listings/ownerA/propA/back.webp").put(bytes(32), { contentType: "image/webp" }));
  await assertSucceeds(storage.ref("public/listings/ownerA/propA/front.jpg").put(bytes(32), jpeg));
  await assertSucceeds(storage.ref("public/listings/ownerA/propA/back.webp").delete());

  await assertFails(storage.ref("public/listings/ownerB/propB/x.jpg").put(bytes(32), jpeg));
  await assertFails(storage.ref("public/listings/ownerA/propB/x.jpg").put(bytes(32), jpeg));
  await assertFails(storage.ref("public/listings/ownerA/not-a-property/x.jpg").put(bytes(32), jpeg));
  await assertFails(storage.ref("public/listings/ownerA/propA/nested/x.jpg").put(bytes(32), jpeg));
  await assertFails(storage.ref("public/x.jpg").put(bytes(32), jpeg));
  await assertFails(storage.ref("root.jpg").put(bytes(32), jpeg));
  await assertFails(anon().ref("public/listings/ownerA/propA/x.jpg").put(bytes(32), jpeg));
});

test("TAQ-14: listing photos must be raster images under 10MB", async () => {
  const storage = as("ownerA");
  await assertFails(storage.ref("public/listings/ownerA/propA/big.jpg").put(bytes(11 * 1024 * 1024), jpeg));
  await assertFails(storage.ref("public/listings/ownerA/propA/page.html").put(bytes(32), { contentType: "text/html" }));
  await assertFails(storage.ref("public/listings/ownerA/propA/doc.pdf").put(bytes(32), { contentType: "application/pdf" }));
  await assertFails(storage.ref("public/listings/ownerA/propA/x.svg").put(bytes(32), { contentType: "image/svg+xml" }));
});

test("TAQ-14: only the owner or a SuperAdmin can delete listing photos", async () => {
  await assertFails(as("ownerB").ref("public/listings/ownerA/propA/front.jpg").delete());
  await assertFails(anon().ref("public/listings/ownerA/propA/front.jpg").delete());
  await assertSucceeds(superAdmin().ref("public/listings/ownerA/propA/front.jpg").delete());
});

// --- TAQ-14: listing documents still accept public/listings download URLs ---

test("TAQ-14: Firestore imageRefsOk accepts public/listings download URLs and rejects users/ ones", async () => {
  const bucket = `${projectId}.appspot.com`;
  const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/public%2Flistings%2FownerA%2FpropA%2Ffront.jpg?alt=media&token=abc`;
  const privateUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/users%2FownerA%2Fkyc%2Fid.jpg?alt=media`;
  const listing = (imageUrls) => ({
    id: "propA",
    owner_id: "ownerA",
    countryCode: "AE",
    currencyCode: "AED",
    titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" },
    pricePerMonth: 9000,
    status: "vacant",
    is_published: true,
    image: imageUrls[0],
    imageUrls,
  });
  const db = testEnv.authenticatedContext("root", { role: "SuperAdmin" }).firestore();
  await assertSucceeds(setDoc(doc(db, "Properties/propA"), listing([publicUrl])));
  await assertFails(setDoc(doc(db, "Properties/propA"), listing([privateUrl])));

  const { sanitizeForMarketplace } = require("../index");
  const sanitized = sanitizeForMarketplace({ ...listing([publicUrl, privateUrl]), image: privateUrl }, "ownerA", "propA");
  assert.deepEqual(sanitized.imageUrls, [publicUrl]);
});
