#!/usr/bin/env node
/**
 * Read-only lease audit for TAQ-110 (dev only). Lists what the lease exclusivity and ownership
 * checks would refuse, so it can be fixed by hand before or after deploying them:
 *  - properties with more than one live lease (active and not past its end date),
 *  - live leases without a property lock, or whose lock names another lease,
 *  - leases whose property is missing from the owner's private tree,
 *  - leases whose agency does not match the owner's agency (claims) or the property doc,
 *  - leases with a missing, non-numeric or non-positive rent, or no property / owner / tenant,
 *  - private properties of agency owners (with leases) whose `agency_id` is not the owner's agency
 *    (agency leases on them are refused).
 * It never writes anything: no flag turns writes on.
 *
 *   node scripts/audit_leases.js --project demo-<name>            # emulator / demo project
 *   node scripts/audit_leases.js --project tashil-aqar-dev        # the dev project
 *
 * Only demo- projects and the dev project are accepted; production and anything else is refused.
 * Credentials come from Application Default Credentials or the emulator environment variables.
 */
const admin = require("firebase-admin");

const DEV_PROJECTS = ["tashil-aqar-dev"];
const LOCKS = "PropertyLeaseLocks";

function parseArgs(argv) {
  const args = { project: "" };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg.startsWith("--project=")) args.project = arg.slice("--project=".length);
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
  return args;
}

function resolveTarget(project) {
  if (project.startsWith("demo-") || DEV_PROJECTS.includes(project)) return project;
  throw new Error(`Refusing project "${project}": the lease audit runs on demo- projects and ${DEV_PROJECTS.join(", ")} only.`);
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
  };
  const liveByProperty = new Map();
  for (const lease of leases) {
    const live = leaseLiveState(lease, now).live;
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
  return report;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const projectId = resolveTarget(args.project);
  console.log(`Lease audit (read-only) on project: ${projectId}`);
  if (!admin.apps.length) admin.initializeApp({ projectId });
  const report = await audit(admin.firestore(), admin.auth());
  console.log(JSON.stringify(report, null, 2));
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}

module.exports = { parseArgs, resolveTarget, audit, rentProblem };
