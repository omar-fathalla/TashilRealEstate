// TAQ-109: download tokens of a listing's photos are replaced when it goes offline and when it goes
// live again. Runs against the Storage emulator through the Admin SDK.
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const { File } = require("@google-cloud/storage");

if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Storage emulator is attached.");
}

const fns = require("../index");
const photos = require("../listing_photos");

const projectId = process.env.GCLOUD_PROJECT;
const bucket = admin.storage().bucket(`${projectId}.firebasestorage.app`);
const TOKEN_KEY = "firebaseStorageDownloadTokens";

const live = { owner_id: "owner1", is_published: true, status: "vacant", moderation_hidden: false, pricePerMonth: 9000 };
const snap = (data) => ({ exists: Boolean(data), data: () => data });
const change = (before, after, propertyId = "prop1") =>
  fns.revokePhotoTokensOnOffline.run({ params: { propertyId }, data: { before: snap(before), after: snap(after) } });

const PHOTO = "public/listings/owner1/prop1/front.jpg";
const PHOTO2 = "public/listings/owner1/prop1/back.jpg";
const NO_TOKEN = "public/listings/owner1/prop1/plain.jpg";
const OTHER_PROPERTY = "public/listings/owner1/prop2/front.jpg";
const OTHER_OWNER = "public/listings/owner2/prop1/front.jpg";

async function put(name, token) {
  await bucket.file(name).save(Buffer.alloc(16), {
    metadata: { contentType: "image/jpeg", ...(token ? { metadata: { [TOKEN_KEY]: token } } : {}) },
  });
}
async function tokens(name) {
  const [meta] = await bucket.file(name).getMetadata();
  const value = meta.metadata && meta.metadata[TOKEN_KEY];
  return value ? value.split(",") : [];
}

let writes;
const realSetMetadata = File.prototype.setMetadata;
let counter;

test.before(() => {
  photos.deps.bucket = () => bucket;
  File.prototype.setMetadata = function (metadata, ...rest) {
    writes.push({ name: this.name, metadata });
    return realSetMetadata.call(this, metadata, ...rest);
  };
});

test.after(async () => {
  File.prototype.setMetadata = realSetMetadata;
  await bucket.deleteFiles({ prefix: "public/", force: true });
});

test.beforeEach(async () => {
  writes = [];
  counter = 0;
  photos.deps.newToken = () => `rotated-${(counter += 1)}`;
  await bucket.deleteFiles({ prefix: "public/", force: true });
  await put(PHOTO, "old-1");
  await put(PHOTO2, "old-2");
  await put(NO_TOKEN);
  await put(OTHER_PROPERTY, "other-prop");
  await put(OTHER_OWNER, "other-owner");
});

const unchanged = async () => {
  assert.deepEqual(await tokens(OTHER_PROPERTY), ["other-prop"]);
  assert.deepEqual(await tokens(OTHER_OWNER), ["other-owner"]);
};

test("TAQ-109: isLiveListing is the storage.rules live check", () => {
  assert.equal(photos.isLiveListing(live), true);
  for (const patch of [{ is_published: false }, { is_published: "true" }, { status: "rented" }, { status: undefined }, { moderation_hidden: true }, { owner_id: "" }, { owner_id: undefined }]) {
    assert.equal(photos.isLiveListing({ ...live, ...patch }), false, JSON.stringify(patch));
  }
  assert.equal(photos.isLiveListing(null), false);
});

for (const [name, after] of [
  ["unpublished", { ...live, is_published: false }],
  ["rented", { ...live, status: "rented", is_published: false }],
  ["held by moderation", { ...live, is_published: false, moderation_hidden: true }],
  ["made unavailable", { ...live, status: "unavailable" }],
  ["deleted", null],
]) {
  test(`TAQ-109: a listing ${name} gets new tokens on every photo that has one, and nothing else changes`, async () => {
    await change(live, after);
    assert.deepEqual(writes.map((w) => w.name).sort(), [PHOTO2, PHOTO].sort());
    for (const w of writes) {
      const value = w.metadata.metadata[TOKEN_KEY];
      assert.match(value, /^rotated-\d$/, "the value written is one new token, so a platform that replaces drops the old ones");
    }
    for (const name of [PHOTO, PHOTO2]) {
      const now = await tokens(name);
      assert.ok(now.some((t) => t.startsWith("rotated-")), `${name} has a new token`);
    }
    assert.deepEqual(await tokens(NO_TOKEN), [], "an object without a link gets none");
    await unchanged();
  });
}

test("TAQ-109: going live again rotates the tokens once more", async () => {
  await change({ ...live, is_published: false }, live);
  assert.deepEqual(writes.map((w) => w.name).sort(), [PHOTO2, PHOTO].sort());
  const first = (await tokens(PHOTO)).filter((t) => t.startsWith("rotated-"));
  writes = [];
  await change(live, { ...live, is_published: false });
  assert.equal(writes.length, 2);
  const second = (await tokens(PHOTO)).filter((t) => t.startsWith("rotated-"));
  assert.ok(second.length > first.length, "a further token was issued");
  await unchanged();
});

test("TAQ-109: a first publish (no earlier doc) rotates, a plain edit of a live or an offline listing does not", async () => {
  await change(live, { ...live, pricePerMonth: 9500 });
  await change({ ...live, is_published: false }, { ...live, is_published: false, pricePerMonth: 1 });
  await change(null, { ...live, is_published: false });
  await change(null, null);
  assert.equal(writes.length, 0);
  await change(null, live);
  assert.equal(writes.length, 2);
});

test("TAQ-109: handing a live listing to another owner rotates the old owner's photos", async () => {
  await change(live, { ...live, owner_id: "owner2" });
  assert.deepEqual(writes.map((w) => w.name).sort(), [PHOTO2, PHOTO].sort());
  assert.deepEqual(await tokens(OTHER_OWNER), ["other-owner"]);
});

test("TAQ-109: rotation errors are raised so the failure is visible", async () => {
  const bad = photos.deps.bucket;
  photos.deps.bucket = () => ({ getFiles: async () => { throw new Error("storage down"); } });
  try {
    await assert.rejects(change(live, null), /storage down/);
  } finally {
    photos.deps.bucket = bad;
  }
});
