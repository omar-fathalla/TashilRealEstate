#!/usr/bin/env node
/**
 * Backfill of the property owner registry (TAQ-110, N-1). Dev and demo projects only.
 *
 * Property docs created before the registry have no `PropertyOwners/{propertyId}` entry, so leases
 * and payments on them fail closed (`property_not_registered`). This script registers each id that
 * exactly one landlord holds:
 *  - the id appears under one `Users/{uid}/properties/{id}` only,
 *  - that uid's role can publish (Owner, AgencyAdmin, SuperAdmin),
 *  - no public listing exists for the id, or it belongs to the same uid.
 * Everything else is reported and left alone, to be resolved by hand: ids under more than one owner,
 * ids whose public listing names another owner, ids whose only holder cannot let property, and ids
 * already registered to someone other than a holder. Nothing is deleted or flagged.
 *
 *   node scripts/backfill_property_owners.js --project tashil-aqar-dev            # dry run
 *   node scripts/backfill_property_owners.js --project tashil-aqar-dev --write    # register
 *
 * Only demo- projects and tashil-aqar-dev are accepted; any other project is refused before anything
 * is read. Credentials come from Application Default Credentials or the emulator environment.
 */
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

const DEV_PROJECTS = ["tashil-aqar-dev"];
const REGISTRY = "PropertyOwners";
const PUBLISHER_ROLES = ["Owner", "AgencyAdmin", "SuperAdmin"];

function parseArgs(argv) {
  const args = { project: "", write: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg.startsWith("--project=")) args.project = arg.slice("--project=".length);
    else if (arg === "--write") args.write = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
  return args;
}

function resolveTarget(project) {
  if (typeof project === "string" && (project.startsWith("demo-") || DEV_PROJECTS.includes(project))) return project;
  throw new Error(`Refusing to run against "${project}": the registry backfill runs on demo- projects and ${DEV_PROJECTS.join(", ")} only.`);
}

/**
 * Every private property doc, grouped by id: Map<propertyId, [{ ownerId, rentalStatus, idConflict }]>.
 * Only docs at Users/{uid}/properties/{id} count; other `properties` subcollections are ignored.
 */
async function scanPrivateProperties(db) {
  const byId = new Map();
  const snap = await db.collectionGroup("properties").get();
  for (const d of snap.docs) {
    const usersDoc = d.ref.parent.parent;
    if (!usersDoc || !usersDoc.parent || usersDoc.parent.id !== "Users" || usersDoc.parent.parent) continue;
    const rental = d.get("rentalStatus");
    const holders = byId.get(d.id) || [];
    holders.push({
      ownerId: usersDoc.id,
      rentalStatus: typeof rental === "string" ? rental.trim().toLowerCase() : "",
      idConflict: d.get("id_conflict") === true,
    });
    byId.set(d.id, holders);
  }
  return byId;
}

async function roleOf(auth, db, uid, cache) {
  if (cache.has(uid)) return cache.get(uid);
  let claims = {};
  try {
    claims = (await auth.getUser(uid)).customClaims || {};
  } catch (err) {
    if (err.code !== "auth/user-not-found") throw err;
  }
  let role = typeof claims.role === "string" ? claims.role : "";
  if (!role) {
    const profile = await db.collection("Users").doc(uid).get();
    const profileRole = profile.exists ? profile.get("role") : "";
    role = ["Owner", "Tenant", "Investor"].includes(profileRole) ? profileRole : "";
  }
  cache.set(uid, role);
  return role;
}

/**
 * Sorts every private property id into what the backfill would register and what needs a person.
 * Reads only. `holders` comes from scanPrivateProperties.
 */
async function classify(db, auth, holders) {
  const plan = {
    privateDocs: 0,
    ids: holders.size,
    alreadyRegistered: 0,
    toRegister: [],
    multipleOwners: [],
    publicOwnerMismatch: [],
    nonLandlordOwner: [],
    registeredToOther: [],
  };
  const roles = new Map();
  for (const [propertyId, list] of holders) {
    plan.privateDocs += list.length;
    const owners = [...new Set(list.map((h) => h.ownerId))].sort();
    const reg = await db.collection(REGISTRY).doc(propertyId).get();
    const registered = reg.exists ? reg.get("owner_id") || "" : "";
    if (registered) {
      const others = owners.filter((uid) => uid !== registered && !list.find((h) => h.ownerId === uid && h.idConflict));
      if (others.length || !owners.includes(registered)) plan.registeredToOther.push({ property_id: propertyId, registered_owner_id: registered, holders: owners });
      else plan.alreadyRegistered += 1;
      continue;
    }
    if (owners.length > 1) {
      plan.multipleOwners.push({ property_id: propertyId, owners });
      continue;
    }
    const [ownerId] = owners;
    const pub = await db.collection("Properties").doc(propertyId).get();
    const publicOwner = pub.exists ? pub.get("owner_id") || "" : "";
    if (publicOwner && publicOwner !== ownerId) {
      plan.publicOwnerMismatch.push({ property_id: propertyId, owner_id: ownerId, public_owner_id: publicOwner });
      continue;
    }
    const role = await roleOf(auth, db, ownerId, roles);
    if (!PUBLISHER_ROLES.includes(role)) {
      plan.nonLandlordOwner.push({ property_id: propertyId, owner_id: ownerId, role });
      continue;
    }
    plan.toRegister.push({ property_id: propertyId, owner_id: ownerId });
  }
  return plan;
}

/** Registers [plan.toRegister]; an id registered meanwhile is skipped, never overwritten. */
async function applyPlan(db, plan) {
  let registered = 0;
  const skipped = [];
  for (const { property_id: propertyId, owner_id: ownerId } of plan.toRegister) {
    const ref = db.collection(REGISTRY).doc(propertyId);
    const done = await db.runTransaction(async (t) => {
      const reg = await t.get(ref);
      if (reg.exists) return false;
      t.create(ref, { owner_id: ownerId, property_id: propertyId, claimed_at: FieldValue.serverTimestamp(), claimed_by: "backfill" });
      return true;
    });
    if (done) registered += 1;
    else skipped.push(propertyId);
  }
  return { registered, skipped };
}

function printPlan(plan) {
  console.log(`Private property docs: ${plan.privateDocs} (${plan.ids} ids)`);
  console.log(`Already registered: ${plan.alreadyRegistered}`);
  console.log(`To register (single landlord): ${plan.toRegister.length}`);
  for (const r of plan.toRegister) console.log(`  ${r.property_id} -> ${r.owner_id}`);
  const report = [
    ["Under more than one owner (left unregistered; resolve by hand)", plan.multipleOwners],
    ["Public listing names another owner (left unregistered)", plan.publicOwnerMismatch],
    ["Only holder cannot let property (left unregistered)", plan.nonLandlordOwner],
    ["Registered to someone other than a holder (left as is)", plan.registeredToOther],
  ];
  for (const [label, list] of report) {
    console.log(`${label}: ${list.length}`);
    for (const item of list) console.log(`  ${JSON.stringify(item)}`);
  }
}

async function main(argv) {
  const args = parseArgs(argv);
  console.log(`Target project: ${args.project} (${args.write ? "WRITE: will register ids" : "dry run: no writes"})`);
  let projectId;
  try {
    projectId = resolveTarget(args.project);
  } catch (err) {
    console.error(err.message);
    return 2;
  }
  if (!admin.apps.length) admin.initializeApp({ projectId });
  const db = admin.firestore();
  const plan = await classify(db, admin.auth(), await scanPrivateProperties(db));
  printPlan(plan);
  if (!args.write) {
    console.log("Dry run. Re-run with --write to register the ids listed above.");
    return 0;
  }
  const { registered, skipped } = await applyPlan(db, plan);
  console.log(`Registered ${registered} ids.${skipped.length ? ` Skipped (registered meanwhile): ${skipped.join(", ")}` : ""}`);
  return 0;
}

if (require.main === module) {
  main(process.argv.slice(2)).then((code) => process.exit(code)).catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}

module.exports = { parseArgs, resolveTarget, scanPrivateProperties, classify, applyPlan, PUBLISHER_ROLES };
