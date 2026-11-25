#!/usr/bin/env node
/**
 * Read-only lease audit for TAQ-110. Lists what the lease exclusivity and ownership checks would
 * refuse, so it can be fixed by hand before or after deploying them:
 *  - properties with more than one live lease (active and not past its end date),
 *  - live leases without a property lock, or whose lock names another lease,
 *  - leases whose property is missing from the owner's private tree,
 *  - leases whose agency does not match the owner's agency (claims) or the property doc,
 *  - leases with a missing, non-numeric or non-positive rent, or no property / owner / tenant,
 *  - private properties of agency owners (with leases) whose `agency_id` is not the owner's agency
 *    (agency leases on them are refused),
 *  - the property owner registry (N-1): ids under more than one owner, ids whose public listing
 *    names another owner, unregistered ids, and locks whose lease owner is not the registered owner,
 *  - the rentalStatus of every private property, and of the properties with a live lease (N-4).
 * It never writes anything: no flag turns writes on.
 *
 *   node scripts/audit_leases.js --project demo-<name>            # emulator / demo project
 *   node scripts/audit_leases.js --project tashil-aqar-dev        # the dev project
 *
 * Production (N-3) runs only in read-only mode, only with Mohamed's approval, and only under an
 * identity with the read-only IAM role `roles/datastore.viewer` (plus Firebase Auth read access):
 *
 *   AUDIT_PROD_OK=<prod project id> node scripts/audit_leases.js --prod-read-only --project <prod project id>
 *
 * The prod project id is the `prod` alias in .firebaserc. In that mode Firestore and Auth are wrapped
 * so every write method throws, and the output is counts and ids only (no names, phones or rents).
 * Any other project is refused. Credentials come from Application Default Credentials or the
 * emulator environment variables.
 */
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const { scanPrivateProperties } = require("./backfill_property_owners");

const DEV_PROJECTS = ["tashil-aqar-dev"];
const LOCKS = "PropertyLeaseLocks";
const REGISTRY = "PropertyOwners";

function parseArgs(argv) {
  const args = { project: "", prodReadOnly: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg.startsWith("--project=")) args.project = arg.slice("--project=".length);
    else if (arg === "--prod-read-only") args.prodReadOnly = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
  return args;
}

/** The production project ids: the `prod` alias in .firebaserc. */
function prodProjectsFromConfig(file = path.join(__dirname, "../../.firebaserc")) {
  try {
    const prod = JSON.parse(fs.readFileSync(file, "utf8")).projects.prod;
    return typeof prod === "string" && prod ? [prod] : [];
  } catch (_) {
    return [];
  }
}

/**
 * The project the audit may run on. Without [prodReadOnly]: demo- projects and the dev project.
 * With it: only a production project, and only when [confirm] (AUDIT_PROD_OK) names it exactly.
 */
function resolveTarget(project, { prodReadOnly = false, confirm = "", prodProjects = prodProjectsFromConfig() } = {}) {
  if (prodReadOnly) {
    if (!prodProjects.includes(project)) {
      throw new Error(`Refusing project "${project}": --prod-read-only is only for the production project.`);
    }
    if (confirm !== project) {
      throw new Error(`Refusing project "${project}": set AUDIT_PROD_OK=${project} to confirm the read-only production audit.`);
    }
    return project;
  }
  if (project.startsWith("demo-") || DEV_PROJECTS.includes(project)) return project;
  throw new Error(`Refusing project "${project}": the lease audit runs on demo- projects and ${DEV_PROJECTS.join(", ")} only.`);
}

const WRITE_METHOD = /^(set|update|delete|create|add|import|revoke|generate|commit|batch|runTransaction|bulkWriter|recursiveDelete)/;
const proxies = new WeakMap();
const targets = new WeakMap();

/**
 * A read-only view of a Firestore or Auth instance and of everything reached through it (refs,
 * snapshots, query results). Every write method throws; assigning or deleting properties throws.
 */
function readOnly(value) {
  if (value === null || (typeof value !== "object" && typeof value !== "function")) return value;
  if (targets.has(value)) return value;
  if (typeof value.then === "function") return value.then(readOnly);
  if (Array.isArray(value)) return value.map(readOnly);
  if (proxies.has(value)) return proxies.get(value);
  const refuse = (what) => {
    throw new Error(`Read-only audit: ${what} is not allowed.`);
  };
  const proxy = new Proxy(value, {
    get(target, prop) {
      if (typeof prop === "string" && WRITE_METHOD.test(prop)) return () => refuse(prop);
      const v = Reflect.get(target, prop, target);
      const own = Object.getOwnPropertyDescriptor(target, prop);
      // Proxy invariant: a frozen data property must be returned as is.
      if (own && !own.configurable && !own.writable) return v;
      if (typeof v !== "function") return readOnly(v);
      return (...args) => readOnly(v.apply(target, args.map((a) => (typeof a === "function"
        ? (...xs) => a(...xs.map(readOnly))
        : targets.get(a) || a))));
    },
    set: (_, prop) => refuse(`setting ${String(prop)}`),
    defineProperty: (_, prop) => refuse(`defining ${String(prop)}`),
    deleteProperty: (_, prop) => refuse(`deleting ${String(prop)}`),
  });
  proxies.set(value, proxy);
  targets.set(proxy, value);
  return proxy;
}

function rentProblem(lease) {
  const terms = lease.financialTerms;
  if (terms !== undefined && terms !== null && (typeof terms !== "object" || Array.isArray(terms))) return "financialTerms is not a map";
  const t = terms || {};
  const fields = {
    "financialTerms.monthlyRent": t.monthlyRent,
    "financialTerms.annualRent": t.annualRent,
    monthly_rent: lease.monthly_rent,
    annual_rent: lease.annual_rent,
    baseAmount: lease.baseAmount,
  };
  let any = false;
  for (const [name, value] of Object.entries(fields)) {
    if (value === undefined || value === null) continue;
    any = true;
    if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) return `${name} is ${JSON.stringify(value)}`;
  }
  return any ? "" : "no rent";
}

async function authorityOf(auth, db, uid, cache) {
  if (cache.has(uid)) return cache.get(uid);
  let claims = {};
  try {
    claims = (await auth.getUser(uid)).customClaims || {};
  } catch (err) {
    if (err.code !== "auth/user-not-found") throw err;
  }
  let role = claims.role || "";
  if (!role) {
    const profile = await db.collection("Users").doc(uid).get();
    const profileRole = profile.exists ? profile.get("role") : "";
    role = ["Owner", "Tenant", "Investor"].includes(profileRole) ? profileRole : "";
  }
  const result = { role, agencyId: role === "AgencyAdmin" && typeof claims.agency_id === "string" ? claims.agency_id : "" };
  cache.set(uid, result);
  return result;
}

async function audit(db, auth, { now = Date.now() } = {}) {
  const { leaseLiveState } = require("../lease_state");
  const leases = (await db.collection("Leases").get()).docs.map((d) => ({ id: d.id, ...d.data() }));
  const locks = new Map((await db.collection(LOCKS).get()).docs.map((d) => [d.id, d.data()]));
  const cache = new Map();
  const report = {
    leases: leases.length,
    liveLeases: 0,
    multipleLiveLeases: [],
    liveWithoutLock: [],
    lockHeldByOther: [],
    propertyMissing: [],
    agencyMismatch: [],
    rentInvalid: [],
    partiesMissing: [],
    agencyPropertiesWithoutAgencyId: [],
    statusCounts: {},
    locks: locks.size,
    registryEntries: 0,
    unregisteredIds: [],
    idsUnderMultipleOwners: [],
    publicOwnerMismatch: [],
    lockOwnerNotRegistered: [],
    rentalStatusAll: {},
    rentalStatusLiveLeased: {},
  };
  const liveByProperty = new Map();
  for (const lease of leases) {
    const live = leaseLiveState(lease, now).live;
    const status = lease.status || "(none)";
    report.statusCounts[status] = (report.statusCounts[status] || 0) + 1;
    if (!lease.property_id || !lease.owner_id || !lease.tenant_id) {
      report.partiesMissing.push({ leaseId: lease.id, status: lease.status || "", property_id: lease.property_id || "", owner_id: lease.owner_id || "", tenant_id: lease.tenant_id || "" });
    }
    const rent = rentProblem(lease);
    if (rent) report.rentInvalid.push({ leaseId: lease.id, status: lease.status || "", problem: rent });
    if (live) {
      report.liveLeases += 1;
      if (lease.property_id) liveByProperty.set(lease.property_id, [...(liveByProperty.get(lease.property_id) || []), lease.id]);
      const lock = lease.property_id ? locks.get(lease.property_id) : null;
      if (!lock) report.liveWithoutLock.push({ leaseId: lease.id, property_id: lease.property_id || "" });
      else if (lock.lease_id !== lease.id) report.lockHeldByOther.push({ leaseId: lease.id, property_id: lease.property_id, lockLeaseId: lock.lease_id });
    }
    if (lease.property_id && lease.owner_id) {
      const silo = await db.collection("Users").doc(lease.owner_id).collection("properties").doc(lease.property_id).get();
      if (!silo.exists) {
        report.propertyMissing.push({ leaseId: lease.id, status: lease.status || "", owner_id: lease.owner_id, property_id: lease.property_id });
      } else {
        const authority = await authorityOf(auth, db, lease.owner_id, cache);
        const agency = lease.agency_id || "";
        const siloAgency = typeof silo.get("agency_id") === "string" ? silo.get("agency_id") : "";
        if (authority.agencyId !== agency || siloAgency !== agency) {
          report.agencyMismatch.push({ leaseId: lease.id, status: lease.status || "", lease_agency: agency, owner_claims_agency: authority.agencyId, property_agency: siloAgency });
        }
      }
    }
  }
  for (const [propertyId, ids] of liveByProperty) {
    if (ids.length > 1) report.multipleLiveLeases.push({ property_id: propertyId, leaseIds: ids });
  }
  const owners = new Set(leases.map((l) => l.owner_id).filter(Boolean));
  for (const uid of owners) {
    const authority = await authorityOf(auth, db, uid, cache);
    if (!authority.agencyId) continue;
    const props = await db.collection("Users").doc(uid).collection("properties").get();
    for (const p of props.docs) {
      if (p.get("agency_id") !== authority.agencyId) report.agencyPropertiesWithoutAgencyId.push({ owner_id: uid, property_id: p.id, agency_id: authority.agencyId });
    }
  }

  const registry = new Map((await db.collection(REGISTRY).get()).docs.map((d) => [d.id, d.get("owner_id") || ""]));
  report.registryEntries = registry.size;
  const holders = await scanPrivateProperties(db);
  const count = (bucket, status) => {
    const key = status || "(unset)";
    bucket[key] = (bucket[key] || 0) + 1;
  };
  for (const [propertyId, list] of holders) {
    const owners = [...new Set(list.map((h) => h.ownerId))].sort();
    for (const h of list) count(report.rentalStatusAll, h.rentalStatus);
    if (owners.length > 1) report.idsUnderMultipleOwners.push({ property_id: propertyId, owners, registered_owner_id: registry.get(propertyId) || "" });
    if (!registry.has(propertyId)) report.unregisteredIds.push(propertyId);
    const pub = await db.collection("Properties").doc(propertyId).get();
    const publicOwner = pub.exists ? pub.get("owner_id") || "" : "";
    const expected = registry.get(propertyId) || (owners.length === 1 ? owners[0] : "");
    if (publicOwner && expected && publicOwner !== expected) report.publicOwnerMismatch.push({ property_id: propertyId, public_owner_id: publicOwner, owner_id: expected });
  }
  for (const [propertyId, ids] of liveByProperty) {
    const lease = leases.find((l) => l.id === ids[0]);
    const h = (holders.get(propertyId) || []).find((x) => x.ownerId === lease.owner_id);
    count(report.rentalStatusLiveLeased, h ? h.rentalStatus : "(no private doc)");
  }
  const byId = new Map(leases.map((l) => [l.id, l]));
  for (const [propertyId, lock] of locks) {
    const holder = byId.get(lock.lease_id);
    const registered = registry.get(propertyId) || "";
    if (!holder || holder.owner_id !== registered) {
      report.lockOwnerNotRegistered.push({ property_id: propertyId, lease_id: lock.lease_id || "", lease_owner_id: holder ? holder.owner_id || "" : "", registered_owner_id: registered });
    }
  }
  report.unregisteredIds.sort();
  return report;
}

/** The production view of a report: counts and ids only, no names, phones, rents or agency ids. */
function idsOnly(report) {
  const ids = (list, key) => list.map((x) => (typeof x === "string" ? x : x[key])).filter(Boolean);
  return {
    leases: report.leases,
    liveLeases: report.liveLeases,
    statusCounts: report.statusCounts,
    locks: report.locks,
    registryEntries: report.registryEntries,
    multipleLiveLeases: report.multipleLiveLeases.map((x) => ({ property_id: x.property_id, leaseIds: x.leaseIds })),
    liveWithoutLock: ids(report.liveWithoutLock, "leaseId"),
    lockHeldByOther: ids(report.lockHeldByOther, "leaseId"),
    propertyMissing: ids(report.propertyMissing, "leaseId"),
    agencyMismatch: ids(report.agencyMismatch, "leaseId"),
    rentInvalid: ids(report.rentInvalid, "leaseId"),
    partiesMissing: ids(report.partiesMissing, "leaseId"),
    agencyPropertiesWithoutAgencyId: ids(report.agencyPropertiesWithoutAgencyId, "property_id"),
    unregisteredIds: report.unregisteredIds.length,
    idsUnderMultipleOwners: ids(report.idsUnderMultipleOwners, "property_id"),
    publicOwnerMismatch: ids(report.publicOwnerMismatch, "property_id"),
    lockOwnerNotRegistered: ids(report.lockOwnerNotRegistered, "property_id"),
    rentalStatusAll: report.rentalStatusAll,
    rentalStatusLiveLeased: report.rentalStatusLiveLeased,
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const projectId = resolveTarget(args.project, { prodReadOnly: args.prodReadOnly, confirm: process.env.AUDIT_PROD_OK || "" });
  console.log(`Lease audit (read-only${args.prodReadOnly ? ", production: counts and ids only" : ""}) on project: ${projectId}`);
  if (!admin.apps.length) admin.initializeApp({ projectId });
  if (args.prodReadOnly) {
    const report = await audit(readOnly(admin.firestore()), readOnly(admin.auth()));
    console.log(JSON.stringify(idsOnly(report), null, 2));
    return;
  }
  const report = await audit(admin.firestore(), admin.auth());
  console.log(JSON.stringify(report, null, 2));
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}

module.exports = { parseArgs, resolveTarget, prodProjectsFromConfig, readOnly, audit, idsOnly, rentProblem };
