/**
 * Listing photo download tokens (TAQ-109).
 *
 * A Storage download URL that carries a `token` is a bearer link: Storage serves it without
 * storage.rules, so a URL issued while a listing was live keeps working after the listing goes
 * offline. This trigger replaces the tokens of every object under
 * public/listings/{owner}/{property}/ when the listing stops being live (unpublished, rented,
 * held by moderation, deleted, or handed to another owner), and again when it goes live, so a
 * link issued in between does not outlive the state it was issued in.
 *
 * "Live" is the check in storage.rules (`listingLive`): published, vacant, not held, and owned by
 * the owner in the photo's path. Listings store photo URLs without tokens (the sanitizer strips
 * them), so rotating tokens never breaks the images the marketplace shows.
 */
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const crypto = require("crypto");

if (!admin.apps.length) {
  admin.initializeApp();
}

const TOKEN_KEY = "firebaseStorageDownloadTokens";

const deps = {
  bucket: () => admin.storage().bucket(),
  newToken: () => crypto.randomUUID(),
};

/** The same conditions as listingLive() in storage.rules, on a public listing doc's data. */
function isLiveListing(data) {
  return Boolean(data)
    && data.is_published === true
    && (data.status === undefined ? "unavailable" : data.status) === "vacant"
    && data.moderation_hidden !== true
    && typeof data.owner_id === "string"
    && data.owner_id !== "";
}

function photoPrefix(ownerId, propertyId) {
  return `public/listings/${ownerId}/${propertyId}/`;
}

/**
 * Gives every object under the prefix that has a download token a fresh one. The value is
 * replaced, not appended to, so older links stop working. Objects without a token have no link to
 * revoke and are left alone. Returns the number of objects rotated.
 */
async function rotatePhotoTokens(ownerId, propertyId) {
  const [files] = await deps.bucket().getFiles({ prefix: photoPrefix(ownerId, propertyId) });
  let rotated = 0;
  for (const file of files) {
    const current = file.metadata && file.metadata.metadata && file.metadata.metadata[TOKEN_KEY];
    if (!current) continue;
    await file.setMetadata({ metadata: { [TOKEN_KEY]: deps.newToken() } });
    rotated += 1;
  }
  return rotated;
}

const revokePhotoTokensOnOffline = onDocumentWritten("Properties/{propertyId}", async (event) => {
  const propertyId = event.params.propertyId;
  const before = event.data && event.data.before && event.data.before.exists ? event.data.before.data() : null;
  const after = event.data && event.data.after && event.data.after.exists ? event.data.after.data() : null;
  const wasLive = isLiveListing(before);
  const isLive = isLiveListing(after);

  const owners = new Set();
  if (wasLive && (!isLive || before.owner_id !== after.owner_id)) owners.add(before.owner_id);
  if (isLive && !wasLive) owners.add(after.owner_id);
  if (owners.size === 0) return null;

  for (const ownerId of owners) {
    try {
      const rotated = await rotatePhotoTokens(ownerId, propertyId);
      logger.info(`Rotated ${rotated} photo token(s) for [${propertyId}] (${isLive ? "live" : "offline"}).`);
    } catch (err) {
      logger.error(`Error rotating photo tokens for property [${propertyId}]`, err);
      throw err;
    }
  }
  return null;
});

module.exports = { revokePhotoTokensOnOffline, rotatePhotoTokens, isLiveListing, deps };
