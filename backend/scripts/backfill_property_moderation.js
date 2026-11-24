#!/usr/bin/env node
/**
 * One-off migration for TAQ-91. Before PropertyModeration/{propertyId} existed, a moderator's hide
 * was recorded only as `moderation_hidden: true` on the public Properties doc, which its owner
 * could delete. This writes the missing moderation doc for every public listing still marked
 * hidden, so the hold survives deleting or recreating the public or private doc.
 *
 * pre_hide_published is stored as false because the old data did not record it: a listing
 * restored after this migration is never published automatically, and the owner's next sync (or a
 * moderator) decides. Existing moderation docs are never changed. Nothing is deleted.
 *
 *   node scripts/backfill_property_moderation.js --project <projectId>          # dry run (default)
 *   node scripts/backfill_property_moderation.js --project <projectId> --apply  # writes
 *
 * Credentials come from Application Default Credentials or the emulator environment variables.
 */
const admin = require("firebase-admin");

const MODERATION_COLLECTION = "PropertyModeration";

/** Returns the ids of hidden public listings that have no moderation doc yet. */
async function findMissingModeration(db) {
  const hidden = await db.collection("Properties").where("moderation_hidden", "==", true).get();
  const missing = [];
  for (const doc of hidden.docs) {
    const existing = await db.collection(MODERATION_COLLECTION).doc(doc.id).get();
    if (!existing.exists) missing.push(doc.id);
  }
  return missing;
}

async function backfill(db, { apply = false } = {}) {
  const missing = await findMissingModeration(db);
  if (apply) {
    for (const id of missing) {
      // create() fails if a moderator wrote the doc in the meantime, so a real hold is never overwritten.
      try {
        await db.collection(MODERATION_COLLECTION).doc(id).create({
          hidden: true,
          pre_hide_published: false,
          updated_by: "migration-taq-91",
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (err) {
        if (err.code !== 6) throw err;
      }
    }
  }
  return { missing, applied: apply };
}

function parseArgs(argv) {
  const args = { project: "", apply: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg === "--apply") args.apply = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
  return args;
}

module.exports = { findMissingModeration, backfill };

if (require.main === module) {
  (async () => {
    const args = parseArgs(process.argv.slice(2));
    admin.initializeApp({ projectId: args.project });
    const result = await backfill(admin.firestore(), { apply: args.apply });
    console.log(`${result.missing.length} hidden listing(s) without a moderation doc: ${result.missing.join(", ") || "none"}`);
    console.log(args.apply ? "Moderation docs written." : "Dry run. Re-run with --apply to write them.");
  })().catch((err) => {
    console.error(err.message);
    process.exit(1);
  });
}
