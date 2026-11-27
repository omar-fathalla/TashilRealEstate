#!/usr/bin/env node
/**
 * One-off clean-up for TAQ-161, the follow-up to TAQ-150. Public Properties docs published
 * before TAQ-150 still carry the placeholder phone "+20 100 123 4567" and the old platform
 * name. The sync trigger rewrites a listing only when it or its agency changes. This script
 * brings every listing in line with listingContactFields(), the definition the functions use:
 *
 * - `agencyNames` is the agency's own names, or the platform's.
 * - `agencyPhone` is always empty.
 * - `agencyOrn` is set only for a verified licence.
 *
 * Only those three fields are written, and only on docs where they differ. Nothing is deleted.
 *
 *   node scripts/backfill_listing_contact.js --project demo-<name>                      # dry run (default)
 *   node scripts/backfill_listing_contact.js --project demo-<name> --apply              # writes
 *   node scripts/backfill_listing_contact.js --project <id> --confirm-project=<id>      # real project
 *
 * The TAQ-100 project guard applies: a project that is not demo- needs --confirm-project=<id>.
 */
const admin = require("firebase-admin");
const { parseArgs, resolveTarget } = require("./backfill_property_moderation");
const { agencyListingIdentity, listingContactFields } = require("../listing_contact");

const PAGE = 300;

function sameNames(a, b) {
  const left = a && typeof a === "object" ? a : {};
  const right = b && typeof b === "object" ? b : {};
  const keys = new Set([...Object.keys(left), ...Object.keys(right)]);
  for (const key of keys) if (left[key] !== right[key]) return false;
  return true;
}

/** The three-field update a listing needs, or null when it is already right. */
function contactUpdate(listing, expected, deleteSentinel) {
  const update = {};
  if (!sameNames(listing.agencyNames, expected.agencyNames)) update.agencyNames = expected.agencyNames;
  if (listing.agencyPhone !== expected.agencyPhone) update.agencyPhone = expected.agencyPhone;
  if (expected.agencyOrn) {
    if (listing.agencyOrn !== expected.agencyOrn) update.agencyOrn = expected.agencyOrn;
  } else if (listing.agencyOrn !== undefined) {
    update.agencyOrn = deleteSentinel;
  }
  return Object.keys(update).length ? update : null;
}

async function backfill(db, { apply = false } = {}) {
  const { FieldPath, FieldValue } = admin.firestore;
  const agencies = new Map();
  const expectedFor = async (agencyId) => {
    const key = typeof agencyId === "string" && agencyId ? agencyId : "";
    if (!agencies.has(key)) {
      let identity = null;
      if (key) {
        const snap = await db.collection("Agencies").doc(key).get();
        identity = snap.exists ? agencyListingIdentity(snap.data()) : null;
      }
      agencies.set(key, listingContactFields(identity));
    }
    return agencies.get(key);
  };

  const changed = [];
  let scanned = 0;
  let last = null;
  for (;;) {
    let query = db.collection("Properties").orderBy(FieldPath.documentId()).limit(PAGE);
    if (last) query = query.startAfter(last);
    const snap = await query.get();
    if (snap.empty) break;
    const batch = db.batch();
    let writes = 0;
    for (const doc of snap.docs) {
      scanned += 1;
      const data = doc.data();
      const update = contactUpdate(data, await expectedFor(data.agency_id), FieldValue.delete());
      if (!update) continue;
      changed.push(doc.id);
      if (apply) {
        batch.update(doc.ref, update);
        writes += 1;
      }
    }
    if (writes) await batch.commit();
    last = snap.docs[snap.size - 1];
    if (snap.size < PAGE) break;
  }
  return { scanned, changed, applied: apply };
}

function guardProject(args) {
  return resolveTarget(args);
}

module.exports = { backfill, contactUpdate, guardProject };

if (require.main === module) {
  (async () => {
    const args = parseArgs(process.argv.slice(2));
    console.log(`Target project: ${args.project} (${args.apply ? "APPLY: will write" : "dry run: no writes"})`);
    const target = guardProject(args);
    admin.initializeApp({ projectId: target.projectId });
    const result = await backfill(admin.firestore(), { apply: args.apply });
    console.log(`${result.changed.length} of ${result.scanned} listing(s) need new contact fields: ${result.changed.join(", ") || "none"}`);
    console.log(args.apply ? "Contact fields updated." : "Dry run. Re-run with --apply to update them.");
  })().catch((err) => {
    console.error(err.message);
    process.exit(err.exitCode || 1);
  });
}
