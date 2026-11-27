/**
 * The TAQ-135 rule, with no side effects: requiring this module does not touch firebase-admin.
 * The trigger (hidden_listing_guard.js) and the clean-up script (scripts/backfill_hidden_unpublished.js)
 * both use it. The script must not require the trigger module, because that one initialises the
 * default Firebase app when it loads (TAQ-160).
 */
const isTrue = (value) => value === true || value === "true";

/** True when the public listing data says both published and held hidden. */
function isPublishedAndHidden(data) {
  return Boolean(data) && isTrue(data.is_published) && isTrue(data.moderation_hidden);
}

module.exports = { isTrue, isPublishedAndHidden };
