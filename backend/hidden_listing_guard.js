/**
 * A listing held hidden by moderation is never published (TAQ-135).
 *
 * The marketplace list query filters on `is_published == true` only (Firestore rules are not
 * filters), so a public doc that says both published and hidden would still be listed to
 * visitors even though a single read of it is refused. Every legitimate writer already keeps the
 * two apart (the sync trigger, reconcilePropertyModeration, the rules on client writes). This
 * trigger is the server-side backstop for anything else: documents written before those paths
 * existed, edits made with the Admin SDK or the console, and any future writer.
 */
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { FieldValue } = admin.firestore;

const { isPublishedAndHidden } = require("./hidden_listing_predicate");

const holdHiddenListingsOffline = onDocumentWritten("Properties/{propertyId}", async (event) => {
  const after = event.data && event.data.after && event.data.after.exists ? event.data.after.data() : null;
  if (!isPublishedAndHidden(after)) return null;
  const propertyId = event.params.propertyId;
  const db = admin.firestore();
  const ref = db.collection("Properties").doc(propertyId);
  try {
    // Re-read inside a transaction so a moderator's lift that landed in the meantime is not undone.
    const changed = await db.runTransaction(async (tx) => {
      const current = await tx.get(ref);
      if (!current.exists || !isPublishedAndHidden(current.data())) return false;
      tx.update(ref, { is_published: false, updated_at: FieldValue.serverTimestamp() });
      return true;
    });
    if (changed) logger.warn(`Listing [${propertyId}] was both published and held by moderation; unpublished it.`);
  } catch (err) {
    logger.error(`Error unpublishing held listing [${propertyId}]`, err);
    throw err;
  }
  return null;
});

module.exports = { holdHiddenListingsOffline, isPublishedAndHidden };
