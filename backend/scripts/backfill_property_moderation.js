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
 *   node scripts/backfill_property_moderation.js --project demo-<name>                      # dry run (default)
 *   node scripts/backfill_property_moderation.js --project demo-<name> --apply              # writes
 *   node scripts/backfill_property_moderation.js --project <id> --confirm-project=<id>      # real project
 *
 * The target project id is printed first. Any project id that does not start with `demo-` is
 * refused, even for a dry run, unless `--confirm-project=<id>` repeats exactly that id. The dry run
 * stays the default; `--apply` is still needed to write.
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
  const args = { project: "", apply: false, confirmProject: "" };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg.startsWith("--project=")) args.project = arg.slice("--project=".length);
    else if (arg === "--confirm-project") args.confirmProject = argv[++i] || "";
    else if (arg.startsWith("--confirm-project=")) args.confirmProject = arg.slice("--confirm-project=".length);
    else if (arg === "--apply") args.apply = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
  return args;
}

/**
 * Decides whether the script may touch args.project. A `demo-` project is always fine; anything
 * else needs `--confirm-project=<that exact id>`, so a copy-pasted command cannot reach a real
 * project by accident.
 */
function resolveTarget(args) {
  const projectId = args.project;
  const demo = projectId.startsWith("demo-");
  if (!demo && args.confirmProject !== projectId) {
    throw Object.assign(new Error(
      `Refusing to run against "${projectId}": it is not a demo- project. ` +
      `Repeat the project id to confirm: --confirm-project=${projectId}` +
      (args.confirmProject ? ` (got --confirm-project=${args.confirmProject}).` : "."),
    ), { exitCode: 2 });
  }
  return { projectId, demo };
}

module.exports = { findMissingModeration, backfill, parseArgs, resolveTarget };

if (require.main === module) {
  (async () => {
    const args = parseArgs(process.argv.slice(2));
    console.log(`Target project: ${args.project} (${args.apply ? "APPLY: will write" : "dry run: no writes"})`);
    const target = resolveTarget(args);
    admin.initializeApp({ projectId: target.projectId });
    const result = await backfill(admin.firestore(), { apply: args.apply });
    console.log(`${result.missing.length} hidden listing(s) without a moderation doc: ${result.missing.join(", ") || "none"}`);
    console.log(args.apply ? "Moderation docs written." : "Dry run. Re-run with --apply to write them.");
  })().catch((err) => {
    console.error(err.message);
    process.exit(err.exitCode || 1);
  });
}
