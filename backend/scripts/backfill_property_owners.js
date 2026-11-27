#!/usr/bin/env node
/**
 * Backfill of the property owner registry (TAQ-110 N-1, TAQ-125). Dry run by default.
 *
 * Property docs created before the registry have no `PropertyOwners/{propertyId}` entry, so leases
 * and payments on them fail closed (`property_not_registered`). This script registers each id that
 * exactly one landlord holds:
 *  - the id appears under one `Users/{uid}/properties/{id}` only,
 *  - that uid's role can publish (Owner, AgencyAdmin, SuperAdmin),
 *  - no public listing exists for the id, or it belongs to the same uid.
 * Holders flagged `id_conflict` and Tenant or Investor holders never count (TAQ-129); they are listed
 * on their own. Everything else is reported and left alone, to be resolved by hand: ids under more
 * than one owner, ids whose public listing names another owner, ids no landlord holds, and ids already
 * registered to someone who is not a landlord holder (`registeredToOther`, marked for review). Ids
 * registered to one of several holders, as an override leaves them, are `registeredToHolder`.
 * `idConflictCandidates` lists the private docs the sync trigger would flag `id_conflict` once they
 * are written again. Nothing is deleted or flagged by this script, and it never overwrites an entry.
 *
 * `idFieldIssues` lists private docs whose `id` field is missing or differs from the doc id (TAQ-128).
 * The sync trigger finds other holders of an id through that field only, so such a doc's id could be
 * claimed by someone else while it is unregistered. `--write` refuses to register anything while the
 * list is not empty; `--fix-id-fields --write` sets `id` to the doc id on those docs and nothing else.
 *
 *   # dev / demo
 *   node scripts/backfill_property_owners.js --project tashil-aqar-dev            # dry run
 *   node scripts/backfill_property_owners.js --project tashil-aqar-dev --fix-id-fields --write  # if the dry run lists id field issues
 *   node scripts/backfill_property_owners.js --project tashil-aqar-dev --write    # register
 *
 *   # production (dry run first; read-only wrapper, so it cannot write)
 *   BACKFILL_PROD_OK=<prod id> node scripts/backfill_property_owners.js --prod --project <prod id>
 *   # production write: only after the dry run was reviewed
 *   BACKFILL_PROD_OK=<prod id> node scripts/backfill_property_owners.js --prod --project <prod id> --write
 *
 * Production (the `prod` alias in .firebaserc) needs `--prod`, `BACKFILL_PROD_OK` equal to the project
 * id, and, to write, `--write`. Any other project is refused before anything is read, and `--prod` is
 * refused on any project that is not production. The target is printed first. The dry run prints a
 * summary and then the whole report as JSON; counts and ids only.
 *
 * Ids held by more than one owner are never registered automatically. To resolve one, pass
 * `--overrides <file.json>` with `{ "<propertyId>": "<ownerUid>" }` naming one of its landlord holders;
 * the file is checked against the live data before anything is written and refused if an entry does
 * not fit (a Tenant, an Investor or an id_conflict doc is refused). A holder with no Users profile
 * (listed as `holdersWithoutProfile`) is refused too, because an anonymous account can create a private
 * doc; only proof of ownership justifies naming one, and then `--confirm-no-profile-owner <uid>` (repeatable)
 * must name it. Without an entry the id stays unregistered (the sync trigger flags any later create of it).
 * Firebase Auth is not used: the backfill needs only Firestore read access (`roles/datastore.viewer`
 * for the dry run), so it runs under an identity that cannot read Auth.
 *
 * `--write` registers in batches (`--batch-size`, default 100, at most 400) and prints the last id of
 * each batch as the cursor. It is idempotent: an id registered meanwhile is skipped. If a run stops,
 * start it again; `--cursor <id>` skips ids up to and including that one. The plan is recomputed from
 * live data on every run. See docs/PROPERTY_REGISTRY_BACKFILL.md for the production run order.
 *
 * Credentials come from Application Default Credentials or the emulator environment variables.
 */
const admin = require("firebase-admin");
const { FieldValue, FieldPath } = require("firebase-admin/firestore");
const { readOnly } = require("./read_only");
const { prodProjectsFromConfig } = require("./prod_projects");

const DEV_PROJECTS = ["tashil-aqar-dev"];
const REGISTRY = "PropertyOwners";
const NON_LANDLORD_ROLES = ["Tenant", "Investor"];
const DEFAULT_BATCH = 100;
const MAX_BATCH = 400;
const SCAN_PAGE = 500;

function parseArgs(argv) {
  const args = { project: "", write: false, prod: false, fixIdFields: false, batchSize: DEFAULT_BATCH, cursor: "", overrides: "", confirmNoProfile: [] };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg.startsWith("--project=")) args.project = arg.slice("--project=".length);
    else if (arg === "--write") args.write = true;
    else if (arg === "--prod") args.prod = true;
    else if (arg === "--fix-id-fields") args.fixIdFields = true;
    else if (arg === "--batch-size") args.batchSize = Number(argv[++i]);
    else if (arg.startsWith("--batch-size=")) args.batchSize = Number(arg.slice("--batch-size=".length));
    else if (arg === "--overrides") args.overrides = argv[++i] || "";
    else if (arg.startsWith("--overrides=")) args.overrides = arg.slice("--overrides=".length);
    else if (arg === "--confirm-no-profile-owner") args.confirmNoProfile.push(argv[++i] || "");
    else if (arg.startsWith("--confirm-no-profile-owner=")) args.confirmNoProfile.push(arg.slice("--confirm-no-profile-owner=".length));
    else if (arg === "--cursor") args.cursor = argv[++i] || "";
    else if (arg.startsWith("--cursor=")) args.cursor = arg.slice("--cursor=".length);
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
  if (!Number.isInteger(args.batchSize) || args.batchSize < 1 || args.batchSize > MAX_BATCH) {
    throw new Error(`--batch-size must be a whole number from 1 to ${MAX_BATCH}.`);
  }
  return args;
}

/**
 * The project the backfill may touch. demo- projects and the dev project need nothing more.
 * Production (one of [prodProjects]) needs [prod] (--prod) and [confirm] (BACKFILL_PROD_OK) equal to
 * the project id; [prod] on any other project is refused. Anything else is refused.
 */
function resolveTarget(project, { prod = false, confirm = "", prodProjects = prodProjectsFromConfig() } = {}) {
  const isProd = typeof project === "string" && prodProjects.includes(project);
  if (isProd) {
    if (!prod) throw new Error(`Refusing to run against "${project}": it is the production project. Pass --prod and set BACKFILL_PROD_OK=${project}.`);
    if (confirm !== project) throw new Error(`Refusing to run against "${project}": set BACKFILL_PROD_OK=${project} to confirm the production backfill.`);
    return project;
  }
  if (prod) throw new Error(`Refusing to run against "${project}": --prod is only for the production project.`);
  if (typeof project === "string" && (project.startsWith("demo-") || DEV_PROJECTS.includes(project))) return project;
  throw new Error(`Refusing to run against "${project}": the registry backfill runs on demo- projects, ${DEV_PROJECTS.join(", ")} and, with --prod, the production project.`);
}

/**
 * Every private property doc, grouped by id:
 * Map<propertyId, [{ ownerId, rentalStatus, idConflict, idField }]>. `idField` is "ok" when the doc's
 * `id` field equals the doc id, "missing" when it has none, and "mismatch" otherwise.
 * Only docs at Users/{uid}/properties/{id} count; other `properties` subcollections are ignored.
 */
async function scanPrivateProperties(db, { pageSize = SCAN_PAGE } = {}) {
  const byId = new Map();
  let last = null;
  for (;;) {
    let query = db.collectionGroup("properties").orderBy(FieldPath.documentId()).limit(pageSize);
    if (last) query = query.startAfter(last);
    const snap = await query.get();
    for (const d of snap.docs) {
      const usersDoc = d.ref.parent.parent;
      if (!usersDoc || !usersDoc.parent || usersDoc.parent.id !== "Users" || usersDoc.parent.parent) continue;
      const rental = d.get("rentalStatus");
      const idValue = d.get("id");
      const holders = byId.get(d.id) || [];
      holders.push({
        ownerId: usersDoc.id,
        rentalStatus: typeof rental === "string" ? rental.trim().toLowerCase() : "",
        idConflict: d.get("id_conflict") === true,
        idField: idValue === d.id ? "ok" : idValue === undefined || idValue === null ? "missing" : "mismatch",
      });
      byId.set(d.id, holders);
    }
    if (snap.docs.length < pageSize) break;
    last = snap.docs[snap.docs.length - 1];
  }
  return byId;
}

/**
 * Whether [uid] may hold a private property: false for a Tenant or Investor profile. It reads only
 * Firestore (`Users/{uid}.role`); Firebase Auth is never called, so the backfill also runs under an
 * identity that cannot read Auth. A missing or other profile role counts as a landlord (AgencyAdmin
 * and SuperAdmin roles live in claims, not in the profile); `profile` says whether a profile exists.
 */
async function isLandlord(db, uid, cache) {
  if (!cache.has(uid)) {
    const profile = await db.collection("Users").doc(uid).get();
    const role = profile.exists && typeof profile.get("role") === "string" ? profile.get("role") : "";
    cache.set(uid, { role, landlord: !NON_LANDLORD_ROLES.includes(role), profile: profile.exists });
  }
  return cache.get(uid);
}

/**
 * Splits the holders of one id (TAQ-129). Only `landlords` count as owners: a doc the sync trigger
 * flagged `id_conflict` never owns its id, and a Tenant or Investor cannot let property, so neither
 * keeps a real owner's id unregistered or can be named in an override. A holder without a profile
 * still counts: it may be a claims-only admin, and dropping it could hand the id to the other holder.
 */
async function splitHolders(db, list, roles) {
  const result = { landlords: [], flagged: [], nonLandlord: [], noProfile: [] };
  for (const uid of [...new Set(list.map((h) => h.ownerId))].sort()) {
    if (list.filter((h) => h.ownerId === uid).every((h) => h.idConflict)) {
      result.flagged.push(uid);
      continue;
    }
    const { role, landlord, profile } = await isLandlord(db, uid, roles);
    if (!landlord) {
      result.nonLandlord.push({ owner_id: uid, role });
      continue;
    }
    if (!profile) result.noProfile.push(uid);
    result.landlords.push(uid);
  }
  return result;
}

/**
 * Sorts every private property id into what the backfill would register and what needs a person.
 * Reads only. `holders` comes from scanPrivateProperties. Holders flagged `id_conflict` and Tenant or
 * Investor holders are reported (`flaggedHolders`, `nonLandlordHolders`) and never count as owners.
 * `registeredToOther` rows (registered to someone who is not a landlord holder) carry `review: true`;
 * `registeredToHolder` rows are registered to one of several holders, as an override leaves them.
 * `idConflictCandidates` are the private docs that conflict with the registry or with other holders
 * (the sync trigger flags them `id_conflict` when they are next created).
 */
async function classify(db, holders, { overrides = {}, confirmNoProfile = [] } = {}) {
  const plan = {
    privateDocs: 0,
    ids: holders.size,
    alreadyRegistered: 0,
    toRegister: [],
    multipleOwners: [],
    publicOwnerMismatch: [],
    nonLandlordOwner: [],
    registeredToOther: [],
    registeredToHolder: [],
    idConflictCandidates: [],
    overridden: [],
    idFieldIssues: [],
    flaggedHolders: [],
    nonLandlordHolders: [],
    holdersWithoutProfile: [],
  };
  const roles = new Map();
  for (const [propertyId, uid] of Object.entries(overrides)) {
    const split = await splitHolders(db, holders.get(propertyId) || [], roles);
    if (split.flagged.includes(uid)) throw new Error(`Override for "${propertyId}" refused: the doc of "${uid}" is flagged id_conflict, so it cannot own the id.`);
    const tenantLike = split.nonLandlord.find((h) => h.owner_id === uid);
    if (tenantLike) throw new Error(`Override for "${propertyId}" refused: "${uid}" is ${tenantLike.role === "Investor" ? "an" : "a"} ${tenantLike.role}; only a landlord (Owner, AgencyAdmin, SuperAdmin) can own an id.`);
    if (split.landlords.length < 2) throw new Error(`Override for "${propertyId}" refused: the id is not held by more than one owner (id_conflict docs and Tenant or Investor holders do not count). Overrides only resolve multi-owner ids.`);
    if (!split.landlords.includes(uid)) throw new Error(`Override for "${propertyId}" refused: "${uid}" does not hold that id (holders: ${split.landlords.join(", ")}).`);
    if (split.noProfile.includes(uid) && !confirmNoProfile.includes(uid)) {
      throw new Error(`Override for "${propertyId}" refused: "${uid}" has no Users profile (an anonymous or claims-only account can create a private doc too). Get proof that this account is the real owner, then repeat the run with --confirm-no-profile-owner ${uid}.`);
    }
  }
  const candidate = (propertyId, ownerId, reason) => plan.idConflictCandidates.push({ property_id: propertyId, owner_id: ownerId, reason });
  for (const propertyId of [...holders.keys()].sort()) {
    const list = holders.get(propertyId);
    plan.privateDocs += list.length;
    for (const h of list) {
      if (h.idField !== "ok") plan.idFieldIssues.push({ property_id: propertyId, owner_id: h.ownerId, id_field: h.idField });
    }
    const split = await splitHolders(db, list, roles);
    const owners = split.landlords;
    for (const uid of split.flagged) plan.flaggedHolders.push({ property_id: propertyId, owner_id: uid });
    for (const uid of split.noProfile) plan.holdersWithoutProfile.push({ property_id: propertyId, owner_id: uid });
    if (owners.length) {
      for (const h of split.nonLandlord) plan.nonLandlordHolders.push({ property_id: propertyId, ...h });
    }
    const reg = await db.collection(REGISTRY).doc(propertyId).get();
    const registered = reg.exists ? reg.get("owner_id") || "" : "";
    if (registered) {
      const others = owners.filter((uid) => uid !== registered);
      if (!owners.includes(registered)) {
        plan.registeredToOther.push({ property_id: propertyId, registered_owner_id: registered, holders: owners, review: true });
        for (const uid of others) candidate(propertyId, uid, "registered_to_other");
      } else if (others.length) {
        plan.registeredToHolder.push({ property_id: propertyId, registered_owner_id: registered, claimed_by: reg.get("claimed_by") || "", other_holders: others });
        for (const uid of others) candidate(propertyId, uid, "registered_to_other_holder");
      } else {
        plan.alreadyRegistered += 1;
      }
      continue;
    }
    if (!owners.length) {
      for (const h of split.nonLandlord) plan.nonLandlordOwner.push({ property_id: propertyId, ...h });
      continue;
    }
    if (owners.length > 1) {
      const chosen = Object.prototype.hasOwnProperty.call(overrides, propertyId) ? overrides[propertyId] : "";
      if (!chosen) {
        plan.multipleOwners.push({ property_id: propertyId, owners });
        for (const uid of owners) candidate(propertyId, uid, "multiple_owners");
        continue;
      }
      const pubSnap = await db.collection("Properties").doc(propertyId).get();
      const pubOwner = pubSnap.exists ? pubSnap.get("owner_id") || "" : "";
      if (pubOwner && pubOwner !== chosen) throw new Error(`Override for "${propertyId}" refused: its public listing belongs to "${pubOwner}".`);
      plan.overridden.push({ property_id: propertyId, owner_id: chosen, other_holders: owners.filter((u) => u !== chosen) });
      for (const uid of owners.filter((u) => u !== chosen)) candidate(propertyId, uid, "override_other_holder");
      plan.toRegister.push({ property_id: propertyId, owner_id: chosen, override: true });
      continue;
    }
    const [ownerId] = owners;
    const pub = await db.collection("Properties").doc(propertyId).get();
    const publicOwner = pub.exists ? pub.get("owner_id") || "" : "";
    if (publicOwner && publicOwner !== ownerId) {
      plan.publicOwnerMismatch.push({ property_id: propertyId, owner_id: ownerId, public_owner_id: publicOwner });
      candidate(propertyId, ownerId, "public_owner_mismatch");
      continue;
    }
    plan.toRegister.push({ property_id: propertyId, owner_id: ownerId });
  }
  return plan;
}

/**
 * Reads the per-id owner override file: a JSON object `{ "<propertyId>": "<ownerUid>" }`. An override
 * only resolves an id held by more than one owner, in favour of one of its holders; classify refuses
 * anything else. Without a file, multi-owner ids are never registered.
 */
function loadOverrides(file) {
  if (!file) return {};
  const data = JSON.parse(require("fs").readFileSync(file, "utf8"));
  if (!data || typeof data !== "object" || Array.isArray(data)) throw new Error("The overrides file must be a JSON object of propertyId: ownerUid.");
  for (const [id, uid] of Object.entries(data)) {
    if (typeof uid !== "string" || !uid.trim() || !id.trim() || id.includes("/") || uid.includes("/")) throw new Error(`Invalid override entry "${id}".`);
  }
  return data;
}

function counts(plan) {
  return {
    privateDocs: plan.privateDocs,
    ids: plan.ids,
    alreadyRegistered: plan.alreadyRegistered,
    toRegister: plan.toRegister.length,
    multipleOwners: plan.multipleOwners.length,
    publicOwnerMismatch: plan.publicOwnerMismatch.length,
    nonLandlordOwner: plan.nonLandlordOwner.length,
    registeredToOther: plan.registeredToOther.length,
    registeredToHolder: plan.registeredToHolder.length,
    idConflictCandidates: plan.idConflictCandidates.length,
    overridden: plan.overridden.length,
    idFieldIssues: plan.idFieldIssues.length,
    flaggedHolders: plan.flaggedHolders.length,
    nonLandlordHolders: plan.nonLandlordHolders.length,
    holdersWithoutProfile: plan.holdersWithoutProfile.length,
  };
}

/**
 * Sets `id` to the doc id on every doc in [plan.idFieldIssues], in transactions of [batchSize] docs.
 * Each doc is read again first: one deleted meanwhile, or already fixed, is skipped. Nothing else on
 * the doc changes. Each update fires the sync trigger like any other edit of the doc.
 */
async function fixIdFields(db, plan, { batchSize = DEFAULT_BATCH, onBatch = () => {} } = {}) {
  const todo = [...plan.idFieldIssues].sort((a, b) => (a.property_id === b.property_id
    ? (a.owner_id < b.owner_id ? -1 : 1)
    : (a.property_id < b.property_id ? -1 : 1)));
  let fixed = 0;
  const skipped = [];
  for (let i = 0; i < todo.length; i += batchSize) {
    const batch = todo.slice(i, i + batchSize);
    const result = await db.runTransaction(async (t) => {
      const refs = batch.map((r) => db.collection("Users").doc(r.owner_id).collection("properties").doc(r.property_id));
      const snaps = await t.getAll(...refs);
      const done = [];
      const skippedNow = [];
      snaps.forEach((snap, k) => {
        const r = batch[k];
        if (!snap.exists || snap.get("id") === r.property_id) {
          skippedNow.push(`${r.owner_id}/${r.property_id}`);
          return;
        }
        t.update(snap.ref, { id: r.property_id });
        done.push(`${r.owner_id}/${r.property_id}`);
      });
      return { done, skippedNow };
    });
    fixed += result.done.length;
    skipped.push(...result.skippedNow);
    onBatch({ fixed: result.done.length, skipped: result.skippedNow.length });
  }
  return { fixed, skipped };
}

/**
 * Registers [plan.toRegister] in batches of [batchSize], one transaction per batch, in property id
 * order, skipping ids up to and including [cursor]. Inside the transaction each id is checked again:
 * one already registered meanwhile, whose private doc is gone or whose public listing now names
 * someone else is skipped, never overwritten. [onBatch] receives each finished batch (its last id is
 * the resume cursor). If a batch fails, the error has `.cursor` set to the last finished id.
 */
async function applyPlan(db, plan, { batchSize = DEFAULT_BATCH, cursor = "", onBatch = () => {} } = {}) {
  const todo = [...plan.toRegister].sort((a, b) => (a.property_id < b.property_id ? -1 : 1)).filter((r) => !cursor || r.property_id > cursor);
  let registered = 0;
  const skipped = [];
  let lastCursor = cursor;
  for (let i = 0; i < todo.length; i += batchSize) {
    const batch = todo.slice(i, i + batchSize);
    try {
      const result = await db.runTransaction(async (t) => {
        const refs = batch.flatMap((r) => [
          db.collection(REGISTRY).doc(r.property_id),
          db.collection("Users").doc(r.owner_id).collection("properties").doc(r.property_id),
          db.collection("Properties").doc(r.property_id),
        ]);
        const snaps = await t.getAll(...refs);
        const done = [];
        const skippedNow = [];
        batch.forEach((r, k) => {
          const [reg, silo, pub] = snaps.slice(k * 3, k * 3 + 3);
          const publicOwner = pub.exists ? pub.get("owner_id") || "" : "";
          if (reg.exists || !silo.exists || (publicOwner && publicOwner !== r.owner_id)) {
            skippedNow.push(r.property_id);
            return;
          }
          t.create(reg.ref, { owner_id: r.owner_id, property_id: r.property_id, claimed_at: FieldValue.serverTimestamp(), claimed_by: r.override ? "backfill-override" : "backfill" });
          done.push(r.property_id);
        });
        return { done, skippedNow };
      });
      registered += result.done.length;
      skipped.push(...result.skippedNow);
      lastCursor = batch[batch.length - 1].property_id;
      onBatch({ registered: result.done.length, skipped: result.skippedNow.length, cursor: lastCursor });
    } catch (err) {
      err.cursor = lastCursor;
      throw err;
    }
  }
  return { registered, skipped, cursor: lastCursor };
}

function printSummary(plan) {
  const c = counts(plan);
  console.log(`Private property docs: ${c.privateDocs} (${c.ids} ids)`);
  console.log(`Already registered: ${c.alreadyRegistered}`);
  console.log(`To register (single landlord): ${c.toRegister}`);
  for (const r of plan.toRegister) console.log(`  ${r.property_id} -> ${r.owner_id}`);
  const report = [
    ["Under more than one owner (left unregistered; resolve by hand)", plan.multipleOwners],
    ["Public listing names another owner (left unregistered)", plan.publicOwnerMismatch],
    ["No landlord holder: only a Tenant or Investor holds it (left unregistered)", plan.nonLandlordOwner],
    ["Registered to someone who is not a landlord holder (REVIEW; left as is)", plan.registeredToOther],
    ["Registered to one of several holders, e.g. by an override (expected; the other holders are id_conflict candidates)", plan.registeredToHolder],
    ["Resolved by an explicit owner override (registered to the named owner)", plan.overridden],
    ["id_conflict candidates (private docs that conflict; nothing is flagged by this script)", plan.idConflictCandidates],
    ["Ignored holders: docs flagged id_conflict (never count as owners)", plan.flaggedHolders],
    ["Ignored holders: Tenant or Investor beside a landlord (never count as owners)", plan.nonLandlordHolders],
    ["Holders without a Users profile (counted as landlords; check who they are)", plan.holdersWithoutProfile],
    ["Private docs with a missing or mismatched id field (must be 0 before --write; fix with --fix-id-fields --write)", plan.idFieldIssues],
  ];
  for (const [label, list] of report) {
    console.log(`${label}: ${list.length}`);
    for (const item of list) console.log(`  ${JSON.stringify(item)}`);
  }
}

/**
 * Runs the CLI. [deps] lets tests inject the Firestore instance and the production
 * project list. Returns the process exit code: 0 done, 2 refused.
 */
async function main(argv, env = process.env, deps = {}) {
  const args = parseArgs(argv);
  const mode = !args.write ? "dry run: no writes" : args.fixIdFields ? "WRITE: will fix id fields only" : "WRITE: will register ids";
  console.log(`Target project: ${args.project} (${args.prod ? "PROD, " : ""}${mode})`);
  let projectId;
  try {
    projectId = resolveTarget(args.project, { prod: args.prod, confirm: env.BACKFILL_PROD_OK || "", prodProjects: deps.prodProjects });
  } catch (err) {
    console.error(err.message);
    return 2;
  }
  let db = deps.db;
  if (!db) {
    if (!admin.apps.length) admin.initializeApp({ projectId });
    db = admin.firestore();
  }
  // The scan, the classification and every dry run go through the read-only wrapper; only the
  // write step below gets the real instance.
  const reader = readOnly(db);
  let plan;
  try {
    plan = await classify(reader, await scanPrivateProperties(reader), { overrides: loadOverrides(args.overrides), confirmNoProfile: args.confirmNoProfile });
  } catch (err) {
    console.error(err.message);
    return 2;
  }
  printSummary(plan);
  console.log("JSON report:");
  console.log(JSON.stringify({ project: projectId, mode: args.write ? "write" : "dry-run", counts: counts(plan), ...plan }, null, 2));
  if (!args.write) {
    console.log(plan.idFieldIssues.length
      ? `Dry run. ${plan.idFieldIssues.length} private docs have a missing or mismatched id field: run with --fix-id-fields --write, then dry-run again; --write refuses until this is 0.`
      : "Dry run. Re-run with --write to register the ids listed under \"To register\".");
    return 0;
  }
  if (args.fixIdFields) {
    try {
      const { fixed, skipped } = await fixIdFields(db, plan, {
        batchSize: args.batchSize,
        onBatch: (b) => console.log(`Batch done: fixed ${b.fixed}, skipped ${b.skipped}`),
      });
      console.log(`Fixed the id field on ${fixed} private docs.${skipped.length ? ` Skipped (changed meanwhile): ${skipped.join(", ")}` : ""}`);
      console.log("Nothing was registered. Run the dry run again; it must show 0 id field issues before --write.");
    } catch (err) {
      console.error(`Fixing id fields stopped: ${err.message || err}`);
      console.error("Run it again to continue (it is idempotent).");
      return 1;
    }
    return 0;
  }
  if (plan.idFieldIssues.length) {
    console.error(`Refusing to register: ${plan.idFieldIssues.length} private docs have a missing or mismatched id field, so the sync trigger cannot see them as holders. Run with --fix-id-fields --write first, then dry-run again.`);
    return 2;
  }
  try {
    const { registered, skipped, cursor } = await applyPlan(db, plan, {
      batchSize: args.batchSize,
      cursor: args.cursor,
      onBatch: (b) => console.log(`Batch done: registered ${b.registered}, skipped ${b.skipped}, cursor=${b.cursor}`),
    });
    console.log(`Registered ${registered} ids.${skipped.length ? ` Skipped (changed meanwhile): ${skipped.join(", ")}` : ""}`);
    if (cursor) console.log(`Last cursor: ${cursor}`);
  } catch (err) {
    console.error(`Backfill stopped: ${err.message || err}`);
    console.error(`Run it again to continue (it is idempotent), or resume with --cursor ${err.cursor || ""}`);
    return 1;
  }
  return 0;
}

if (require.main === module) {
  main(process.argv.slice(2)).then((code) => process.exit(code)).catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}

module.exports = { parseArgs, resolveTarget, scanPrivateProperties, classify, applyPlan, fixIdFields, counts, loadOverrides, main };
