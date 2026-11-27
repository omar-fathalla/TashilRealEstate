#!/usr/bin/env node
/**
 * One-off clean-up for TAQ-135. A public Properties doc that is both `is_published: true` and
 * `moderation_hidden: true` is listed to visitors by the marketplace query although its owner and
 * moderators consider it held. holdHiddenListingsOffline fixes such docs when they are next
 * written; this fixes the ones that are not written again. It only sets `is_published: false` on
 * hidden listings; nothing is deleted and no other field changes.
 *
 *   node scripts/backfill_hidden_unpublished.js --project demo-<name>                      # dry run (default)
 *   node scripts/backfill_hidden_unpublished.js --project demo-<name> --apply              # writes
 *   node scripts/backfill_hidden_unpublished.js --project <id> --confirm-project=<id>      # real project
 *
 * The same project guard as backfill_property_moderation.js applies: a project id that does not
 * start with `demo-` is refused, even for a dry run, unless `--confirm-project=<id>` repeats it.
 */
const admin = require("firebase-admin");
const { parseArgs, resolveTarget } = require("./backfill_property_moderation");
const { isPublishedAndHidden } = require("../hidden_listing_predicate");

/** Returns the ids of public listings that are published while held hidden. */
async function findPublishedHidden(db) {
  const ids = new Set();
  for (const flag of [true, "true"]) {
    const snap = await db.collection("Properties").where("moderation_hidden", "==", flag).get();
    for (const doc of snap.docs) if (isPublishedAndHidden(doc.data())) ids.add(doc.id);
  }
  return [...ids].sort();
}

async function backfill(db, { apply = false } = {}) {
  const found = await findPublishedHidden(db);
  if (apply) {
    for (const id of found) {
      const ref = db.collection("Properties").doc(id);
      await db.runTransaction(async (tx) => {
        const current = await tx.get(ref);
        if (current.exists && isPublishedAndHidden(current.data())) {
          tx.update(ref, { is_published: false, updated_at: admin.firestore.FieldValue.serverTimestamp() });
        }
      });
    }
  }
  return { found, applied: apply };
}

module.exports = { findPublishedHidden, backfill };

if (require.main === module) {
  (async () => {
    const args = parseArgs(process.argv.slice(2));
    console.log(`Target project: ${args.project} (${args.apply ? "APPLY: will write" : "dry run: no writes"})`);
    const target = resolveTarget(args);
    admin.initializeApp({ projectId: target.projectId });
    const result = await backfill(admin.firestore(), { apply: args.apply });
    console.log(`${result.found.length} listing(s) published while hidden: ${result.found.join(", ") || "none"}`);
    console.log(args.apply ? "Unpublished." : "Dry run. Re-run with --apply to unpublish them.");
  })().catch((err) => {
    console.error(err.message);
    process.exit(err.exitCode || 1);
  });
}
