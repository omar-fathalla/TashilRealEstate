const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const { doc, setDoc, updateDoc, deleteDoc } = require("firebase/firestore");

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
    await setDoc(doc(db, "Users/ownerA/properties/propA"), { owner_id: "ownerA", isPublished: true });
    await setDoc(doc(db, "Users/ownerB/properties/propB"), { owner_id: "ownerB" });
    await setDoc(doc(db, "Properties/propA"), { owner_id: "ownerA", is_published: true, moderation_hidden: false, status: "vacant" });
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
const platformAdmin = () => as("admin1", { role: "Admin" });

async function seed(fn) {
  await testEnv.withSecurityRulesDisabled((ctx) => fn(ctx.firestore(), ctx.storage()));
}
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

test("TAQ-70: only the owner, a SuperAdmin or an Admin can list a property's listing photos", async () => {
  const folder = "public/listings/ownerA/propA";
  await assertFails(anon().ref(folder).listAll());
  await assertFails(anon().ref(folder).list({ maxResults: 10 }));
  await assertFails(anon().ref("public/listings/ownerA").listAll());
  await assertFails(as("ownerB").ref(folder).listAll());
  await assertFails(as("ownerB", { role: "AgencyAdmin" }).ref(folder).listAll());
  const own = await assertSucceeds(as("ownerA").ref(folder).listAll());
  assert.deepEqual(own.items.map((item) => item.name), ["front.jpg"]);
  await assertSucceeds(superAdmin().ref(folder).listAll());
  await assertSucceeds(platformAdmin().ref(folder).listAll());
});

test("TAQ-70: a signed-out visitor still gets a published listing photo", async () => {
  const photo = anon().ref("public/listings/ownerA/propA/front.jpg");
  await assertSucceeds(photo.getDownloadURL());
  await assertSucceeds(photo.getMetadata());
  await assertSucceeds(as("ownerB").ref("public/listings/ownerA/propA/front.jpg").getDownloadURL());
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

// --- TAQ-14 / TAQ-70 (M-1): a listing photo is public only while its listing is live ---

const PHOTO = "public/listings/ownerA/propA/front.jpg";

// A signed-out GET of the object with ?alt=media and no token, which is evaluated by the rules.
async function fetchMedia(objectPath) {
  const bucket = anon().ref(objectPath).bucket;
  const url = `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${bucket}/o/${encodeURIComponent(objectPath)}?alt=media`;
  return fetch(url);
}

async function setPublic(data) {
  await seed((db) => setDoc(doc(db, "Properties/propA"), { owner_id: "ownerA", status: "vacant", ...data }));
}

async function expectHiddenFromPublic(label) {
  for (const storage of [anon(), as("ownerB"), as("investor1", { role: "Investor" }), as("agent", { role: "AgencyAdmin", agency_id: "agency-1" })]) {
    await assertFails(storage.ref(PHOTO).getDownloadURL(), label);
    await assertFails(storage.ref(PHOTO).getMetadata(), label);
  }
  assert.equal((await fetchMedia(PHOTO)).status, 403, `${label}: tokenless alt=media download`);
}

async function expectStaffAndOwnerRead() {
  for (const storage of [as("ownerA"), superAdmin(), platformAdmin()]) {
    await assertSucceeds(storage.ref(PHOTO).getDownloadURL());
    await assertSucceeds(storage.ref(PHOTO).getMetadata());
  }
}

test("M-1: a published, unhidden listing's photo is readable by anyone, by URL, metadata or direct download", async () => {
  for (const storage of [anon(), as("ownerB"), as("investor1", { role: "Investor" })]) {
    await assertSucceeds(storage.ref(PHOTO).getDownloadURL());
    await assertSucceeds(storage.ref(PHOTO).getMetadata());
  }
  assert.equal((await fetchMedia(PHOTO)).status, 200, "tokenless alt=media download");
});

test("M-1: an unpublished listing's photo is not public; the owner, SuperAdmin and Admin still read it", async () => {
  await setPublic({ is_published: false, moderation_hidden: false, status: "unavailable" });
  await expectHiddenFromPublic("unpublished");
  await expectStaffAndOwnerRead();
});

test("M-1: a moderation-hidden listing's photo is not public, even if is_published were still true", async () => {
  await setPublic({ is_published: false, moderation_hidden: true });
  await expectHiddenFromPublic("hidden");
  await setPublic({ is_published: true, moderation_hidden: true });
  await expectHiddenFromPublic("hidden, published flag stale");
  await expectStaffAndOwnerRead();
});

test("M-1: a rented listing's photo is not public, even with a stale is_published flag", async () => {
  await setPublic({ is_published: false, moderation_hidden: false, status: "rented" });
  await expectHiddenFromPublic("rented");
  await setPublic({ is_published: true, moderation_hidden: false, status: "rented" });
  await expectHiddenFromPublic("rented, published flag stale");
  await setPublic({ is_published: true, moderation_hidden: false, status: "unavailable" });
  await expectHiddenFromPublic("unavailable");
  await seed((db) => setDoc(doc(db, "Properties/propA"), { owner_id: "ownerA", is_published: true }));
  await expectHiddenFromPublic("no status");
  await expectStaffAndOwnerRead();
});

test("M-1: a deleted listing's photo is not public (no /Properties doc)", async () => {
  await seed((db) => deleteDoc(doc(db, "Properties/propA")));
  await expectHiddenFromPublic("deleted");
  await expectStaffAndOwnerRead();
});

test("M-1: a photo under another owner's folder is not public, even if that property id is live", async () => {
  await setPublic({ owner_id: "ownerB", is_published: true, moderation_hidden: false });
  await expectHiddenFromPublic("wrong owner");
  await seed((db, storage) => storage.ref("public/listings/ownerB/propA/x.jpg").put(bytes(16), jpeg));
  await assertSucceeds(anon().ref("public/listings/ownerB/propA/x.jpg").getDownloadURL());
  await assertSucceeds(as("ownerA").ref(PHOTO).getDownloadURL(), "the uploader keeps their own file");
});

test("M-1: a listing with no is_published flag is not public", async () => {
  await seed((db) => setDoc(doc(db, "Properties/propA"), { owner_id: "ownerA" }));
  await expectHiddenFromPublic("no flag");
});

test("M-1: a download URL with a token is a bearer link the rules never see; tokenless access is refused", async () => {
  const url = await assertSucceeds(anon().ref(PHOTO).getDownloadURL());
  await setPublic({ is_published: false, moderation_hidden: true });
  await assertFails(anon().ref(PHOTO).getDownloadURL());
  assert.equal((await fetch(url.replace(/&token=[^&]*/, ""))).status, 403);
  // Documented limitation: a token URL issued while the listing was live still downloads.
  assert.equal((await fetch(url)).status, 200);
});

test("M-1 info (a): an owner cannot upload or replace photos while moderation holds the listing hidden", async () => {
  const owner = as("ownerA");
  await seed((db) => setDoc(doc(db, "PropertyModeration/propA"), { hidden: true }));
  await assertFails(owner.ref("public/listings/ownerA/propA/new.jpg").put(bytes(16), jpeg));
  await assertFails(owner.ref(PHOTO).put(bytes(16), jpeg));
  await assertSucceeds(owner.ref(PHOTO).getDownloadURL());
  await assertSucceeds(owner.ref(PHOTO).delete(), "removing a photo while held stays allowed");
  await seed((db) => setDoc(doc(db, "PropertyModeration/propA"), { hidden: false }));
  await assertSucceeds(owner.ref("public/listings/ownerA/propA/new.jpg").put(bytes(16), jpeg));
  await assertSucceeds(owner.ref("public/listings/ownerA/propA/new.jpg").delete());
});

// --- TAQ-107: while moderation holds a listing, owners add no photos through Storage or Firestore ---

const OWN_PHOTO = "https://firebasestorage.googleapis.com/v0/b/b/o/public%2Flistings%2FownerA%2FpropA%2Ffront.jpg?alt=media";
const NEW_PHOTO = "data:image/png;base64,iVBORw0KGgo=";

async function holdPropA({ privateDoc = { owner_id: "ownerA", isPublished: true, title: "Flat", imageUrls: [OWN_PHOTO, "assets/images/b.jpg"], image: OWN_PHOTO } } = {}) {
  await seed(async (db) => {
    await setDoc(doc(db, "PropertyModeration/propA"), { hidden: true, pre_hide_published: true, updated_by: "admin1" });
    if (privateDoc) await setDoc(doc(db, "Users/ownerA/properties/propA"), privateDoc);
  });
}

const ownerDb = () => testEnv.authenticatedContext("ownerA").firestore();
const privateRef = (db) => doc(db, "Users/ownerA/properties/propA");

test("TAQ-107: a held listing's owner cannot add image refs to the private doc, by update or re-create", async () => {
  await holdPropA();
  const db = ownerDb();
  await assertFails(updateDoc(privateRef(db), { imageUrls: [OWN_PHOTO, "assets/images/b.jpg", NEW_PHOTO] }));
  await assertFails(updateDoc(privateRef(db), { image: NEW_PHOTO }));
  await assertFails(updateDoc(privateRef(db), { imageUrls: NEW_PHOTO }));
  await assertFails(updateDoc(privateRef(db), { imageUrls: [OWN_PHOTO], image: 7 }));
  await assertSucceeds(deleteDoc(privateRef(db)));
  await assertFails(setDoc(privateRef(db), { owner_id: "ownerA", isPublished: true, imageUrls: [OWN_PHOTO] }));
  await assertSucceeds(setDoc(privateRef(db), { owner_id: "ownerA", isPublished: true, title: "Flat" }));
});

test("TAQ-107: a held listing's owner can still remove image refs and edit everything else", async () => {
  await holdPropA();
  const db = ownerDb();
  await assertSucceeds(updateDoc(privateRef(db), { title: "Flat, renovated", rentalStatus: "rented" }));
  await assertSucceeds(updateDoc(privateRef(db), { image: "assets/images/b.jpg" }), "the cover can become another photo it already has");
  await assertSucceeds(updateDoc(privateRef(db), { imageUrls: [OWN_PHOTO] }));
  await assertFails(updateDoc(privateRef(db), { imageUrls: [OWN_PHOTO, "assets/images/c.jpg"] }));
  await assertSucceeds(updateDoc(privateRef(db), { imageUrls: [], image: "" }));
});

test("TAQ-107: without a hold, or after it is lifted, the owner adds photos as before", async () => {
  const db = ownerDb();
  await assertSucceeds(updateDoc(privateRef(db), { imageUrls: [NEW_PHOTO], image: NEW_PHOTO }));
  await seed((d) => setDoc(doc(d, "PropertyModeration/propA"), { hidden: false, pre_hide_published: true, updated_by: "admin1" }));
  await assertSucceeds(updateDoc(privateRef(db), { imageUrls: [NEW_PHOTO, OWN_PHOTO] }));
  await assertSucceeds(as("ownerA").ref("public/listings/ownerA/propA/after.jpg").put(bytes(16), jpeg));
  await assertSucceeds(as("ownerA").ref("public/listings/ownerA/propA/after.jpg").delete());
});

test("TAQ-107: SuperAdmin and Admin still remove a held listing's photos (Storage), and SuperAdmin its image refs (Firestore)", async () => {
  await holdPropA();
  await seed((db, storage) => storage.ref("public/listings/ownerA/propA/second.jpg").put(bytes(16), jpeg));
  await assertSucceeds(platformAdmin().ref("public/listings/ownerA/propA/second.jpg").delete());
  await assertSucceeds(superAdmin().ref(PHOTO).delete());
  await assertFails(as("ownerA").ref("public/listings/ownerA/propA/third.jpg").put(bytes(16), jpeg));

  const bucket = `${projectId}.appspot.com`;
  const url = (name) => `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/public%2Flistings%2FownerA%2FpropA%2F${name}?alt=media`;
  await seed((db) => setDoc(doc(db, "Properties/propA"), {
    id: "propA", owner_id: "ownerA", countryCode: "AE", currencyCode: "AED",
    titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" }, pricePerMonth: 9000, status: "vacant",
    is_published: false, moderation_hidden: true, image: url("front.jpg"), imageUrls: [url("front.jpg"), url("second.jpg")],
  }));
  const root = testEnv.authenticatedContext("root", { role: "SuperAdmin" }).firestore();
  await assertSucceeds(updateDoc(doc(root, "Properties/propA"), { imageUrls: [url("front.jpg")] }));
  await assertSucceeds(updateDoc(privateRef(root), { imageUrls: [OWN_PHOTO] }));
  await assertSucceeds(updateDoc(privateRef(root), { imageUrls: [OWN_PHOTO, NEW_PHOTO] }), "SuperAdmin is not held back");
  // Admin moderates visibility in Firestore, not image refs.
  const adminDb = testEnv.authenticatedContext("admin1", { role: "Admin" }).firestore();
  await assertFails(updateDoc(doc(adminDb, "Properties/propA"), { imageUrls: [] }));
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
  await seed((db) => deleteDoc(doc(db, "Properties/propA")));
  const bucket = `${projectId}.appspot.com`;
  const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/public%2Flistings%2FownerA%2FpropA%2Ffront.jpg?alt=media`;
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
  await assertFails(setDoc(doc(db, "Properties/propA"), listing([`${publicUrl}&token=abc`])));

  const { sanitizeForMarketplace } = require("../index");
  const sanitized = sanitizeForMarketplace({ ...listing([publicUrl, privateUrl]), image: privateUrl }, "ownerA", "propA");
  assert.deepEqual(sanitized.imageUrls, [publicUrl]);
});

// --- TAQ-91: Admin and Investor ---

test("TAQ-91: an Admin can list and remove public listing photos to moderate them", async () => {
  const admin = as("admin1", { role: "Admin" });
  const folder = "public/listings/ownerA/propA";
  const listed = await assertSucceeds(admin.ref(folder).listAll());
  assert.deepEqual(listed.items.map((item) => item.name), ["front.jpg"]);
  await assertSucceeds(admin.ref(`${folder}/front.jpg`).getDownloadURL());
  await assertSucceeds(admin.ref(`${folder}/front.jpg`).delete());
});

test("TAQ-91: an Admin cannot read, list, change or delete private files, or upload listing photos", async () => {
  const admin = as("admin1", { role: "Admin" });
  await assertFails(admin.ref("users/ownerA/kyc/id.jpg").getDownloadURL());
  await assertFails(admin.ref("users/ownerA/kyc/id.jpg").getMetadata());
  await assertFails(admin.ref("users/ownerA/kyc/id.jpg").delete());
  await assertFails(admin.ref("users/ownerA").listAll());
  await assertFails(admin.ref("users/ownerA/kyc/new.jpg").put(bytes(16), jpeg));
  await assertFails(admin.ref("users/admin1/kyc/mine.jpg").put(bytes(16), { contentType: "text/html" }));
  await assertFails(admin.ref("public/listings/ownerA/propA/extra.jpg").put(bytes(16), jpeg));
  await assertFails(admin.ref("root.jpg").getDownloadURL());
});

test("TAQ-91: a profile that says Admin without the claim cannot moderate photos", async () => {
  await testEnv.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), "Users/legacy"), { role: "Admin" }));
  const legacy = as("legacy");
  await assertFails(legacy.ref("public/listings/ownerA/propA").listAll());
  await assertFails(legacy.ref("public/listings/ownerA/propA/front.jpg").delete());
});

test("TAQ-91: an Investor keeps public photos, but cannot list, upload, delete or read private files", async () => {
  for (const claims of [{ role: "Investor" }, {}]) {
    const investor = as("investor1", claims);
    await assertSucceeds(investor.ref("public/listings/ownerA/propA/front.jpg").getDownloadURL());
    await assertFails(investor.ref("public/listings/ownerA/propA").listAll());
    await assertFails(investor.ref("public/listings/ownerA/propA/front.jpg").delete());
    await assertFails(investor.ref("public/listings/investor1/propX/a.jpg").put(bytes(16), jpeg));
    await assertFails(investor.ref("users/ownerA/kyc/id.jpg").getDownloadURL());
  }
});

test("TAQ-91: an Investor can store their own private files like any user", async () => {
  await assertSucceeds(as("investor1", { role: "Investor" }).ref("users/investor1/kyc/id.png").put(bytes(16), { contentType: "image/png" }));
});
