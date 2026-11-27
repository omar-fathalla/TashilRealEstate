#!/usr/bin/env node
/**
 * Audits and migrates user roles to custom claims.
 *
 * Firestore rules and Cloud Functions only honour SuperAdmin / AgencyAdmin when they come
 * from a custom claim. Profiles that carry an elevated role in Users/{uid}.role without a
 * matching claim were either set by an admin before this change or self-assigned through
 * the old signup flow, so they are never migrated automatically.
 *
 * Audit (read-only, default):
 *   node scripts/role_claims.js --project <projectId>
 *
 * Grant the profile role as a claim to specific, reviewed accounts:
 *   node scripts/role_claims.js --project <projectId> --grant <uid>[,<uid>...]          # dry run
 *   node scripts/role_claims.js --project <projectId> --grant <uid>[,<uid>...] --apply  # writes
 *
 * Give self-service users (Owner, Tenant, Investor) the claim for the role their profile already
 * has, so the rules stop reading Users/{uid} for them (TAQ-23). Never touches a user that has a
 * role claim, and never revokes tokens:
 *   node scripts/role_claims.js --project <projectId> --backfill-self-service          # dry run
 *   node scripts/role_claims.js --project <projectId> --backfill-self-service --apply  # writes
 *
 * First SuperAdmin (TAQ-27). The profile can't vouch for SuperAdmin, so --grant can't bootstrap
 * it. This sets the claim on one uid, and only while no account has a SuperAdmin claim. After
 * that, another SuperAdmin is added with --grant on a reviewed profile; the setUserRole callable
 * never grants or removes SuperAdmin (TAQ-186):
 *   node scripts/role_claims.js --project <projectId> --bootstrap-superadmin <uid>          # dry run
 *   node scripts/role_claims.js --project <projectId> --bootstrap-superadmin <uid> --apply  # writes
 *
 * Second factor for SuperAdmin (TAQ-25, off until set). Once a SuperAdmin has enrolled a second
 * factor, this makes the rules and callables require it for that account. It refuses accounts with
 * no enrolled factor, so nobody is locked out. It revokes the refresh tokens, so the next sign-in
 * uses the second factor. --clear-mfa turns it back off (break-glass):
 *   node scripts/role_claims.js --project <projectId> --require-mfa <uid> [--apply]
 *   node scripts/role_claims.js --project <projectId> --clear-mfa <uid> [--apply]
 *
 * Credentials come from Application Default Credentials (gcloud auth application-default login)
 * or GOOGLE_APPLICATION_CREDENTIALS. Nothing is read from this repository.
 */
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { SELF_SERVICE_ROLES } = require("../authz");
const { applyUserRole } = require("../roles");
const { writeAuditLog } = require("../audit_log");
const { grantSelfServiceClaim } = require("../self_service_claims");

function parseArgs(argv) {
  const args = { project: "", grant: [], apply: false, backfillSelfService: false, bootstrapSuperAdmin: "", requireMfa: "", clearMfa: "" };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg === "--grant") args.grant = (argv[++i] || "").split(",").map((s) => s.trim()).filter(Boolean);
    else if (arg === "--apply") args.apply = true;
    else if (arg === "--backfill-self-service") args.backfillSelfService = true;
    else if (arg === "--bootstrap-superadmin") args.bootstrapSuperAdmin = (argv[++i] || "").trim();
    else if (arg === "--require-mfa") args.requireMfa = (argv[++i] || "").trim();
    else if (arg === "--clear-mfa") args.clearMfa = (argv[++i] || "").trim();
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
  const modes = [args.grant.length > 0, args.backfillSelfService, args.bootstrapSuperAdmin !== "", args.requireMfa !== "", args.clearMfa !== ""].filter(Boolean).length;
  if (modes > 1) throw new Error("Use one of --grant, --backfill-self-service, --bootstrap-superadmin, --require-mfa or --clear-mfa.");
  for (const flag of ["--bootstrap-superadmin", "--require-mfa", "--clear-mfa"]) {
    const value = { "--bootstrap-superadmin": args.bootstrapSuperAdmin, "--require-mfa": args.requireMfa, "--clear-mfa": args.clearMfa }[flag];
    if (argv.includes(flag) && !value) throw new Error(`${flag} needs a uid.`);
  }
  return args;
}

async function audit(db, auth) {
  const snapshot = await db.collection("Users").get();
  const rows = [];
  for (const doc of snapshot.docs) {
    const profileRole = doc.get("role") || "";
    let claimRole = "";
    let claimAgency = "";
    let email = doc.get("email") || "";
    try {
      const user = await auth.getUser(doc.id);
      claimRole = (user.customClaims && user.customClaims.role) || "";
      claimAgency = (user.customClaims && user.customClaims.agency_id) || "";
      email = user.email || email;
    } catch (err) {
      claimRole = err.code === "auth/user-not-found" ? "(no auth user)" : `(error: ${err.code})`;
    }
    const elevated = profileRole && !SELF_SERVICE_ROLES.includes(profileRole);
    if (elevated || (claimRole && claimRole !== profileRole)) {
      rows.push({
        uid: doc.id,
        email,
        profileRole,
        profileAgency: doc.get("agency_id") || "",
        claimRole,
        claimAgency,
      });
    }
  }
  console.log(`Scanned ${snapshot.size} profiles. ${rows.length} need review:`);
  console.table(rows);
}

async function grant(db, uids, apply) {
  for (const uid of uids) {
    const doc = await db.collection("Users").doc(uid).get();
    if (!doc.exists) {
      console.log(`${uid}: no profile, skipped.`);
      continue;
    }
    const role = doc.get("role");
    const agencyId = doc.get("agency_id");
    console.log(`${uid}: ${apply ? "granting" : "would grant"} role=${role}${role === "AgencyAdmin" ? ` agency_id=${agencyId}` : ""}`);
    if (apply) {
      await applyUserRole({ uid, role, agencyId, actorUid: "scripts/role_claims.js" });
    }
  }
  if (!apply) console.log("Dry run. Re-run with --apply to write claims.");
}

/** Self-service profiles whose user has no role claim get one for that same role. */
async function backfillSelfService(db, auth, apply, log = console.log) {
  const snapshot = await db.collection("Users").get();
  let pending = 0;
  for (const doc of snapshot.docs) {
    const role = doc.get("role");
    if (!SELF_SERVICE_ROLES.includes(role)) continue;
    if (!apply) {
      let user;
      try {
        user = await auth.getUser(doc.id);
      } catch (err) {
        if (err.code === "auth/user-not-found") continue;
        throw err;
      }
      if (!(user.customClaims && user.customClaims.role)) pending++;
      continue;
    }
    if ((await grantSelfServiceClaim(doc.id, role, auth)) === "granted") pending++;
  }
  log(`${apply ? "Set" : "Would set"} a self-service role claim on ${pending} of ${snapshot.size} profiles.`);
  if (!apply) log("Dry run. Re-run with --apply to write claims.");
  return pending;
}

/** Uids that already hold a SuperAdmin claim. */
async function superAdminUids(auth) {
  const uids = [];
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) if (user.customClaims && user.customClaims.role === "SuperAdmin") uids.push(user.uid);
    pageToken = page.pageToken;
  } while (pageToken);
  return uids;
}

/** Makes the first SuperAdmin. Refuses once any account holds the claim. */
async function bootstrapSuperAdmin(auth, uid, apply, { applyRole = applyUserRole, log = console.log } = {}) {
  const existing = await superAdminUids(auth);
  if (existing.length > 0) {
    throw new Error(`A SuperAdmin already exists (${existing.length}). Use the setUserRole callable instead.`);
  }
  const user = await auth.getUser(uid);
  log(`${apply ? "Making" : "Would make"} ${user.uid} (${user.email || "no email"}) the first SuperAdmin.`);
  if (!apply) {
    log("Dry run. Re-run with --apply to write the claim.");
    return false;
  }
  await applyRole({ uid, role: "SuperAdmin", actorUid: "scripts/role_claims.js --bootstrap-superadmin" });
  log("Done. The account's refresh tokens were revoked; it signs in again to get the claim.");
  return true;
}

/** TAQ-25, TAQ-185: require (or stop requiring) a second factor for one SuperAdmin or Admin. */
async function setMfaRequired(auth, uid, required, apply, log = console.log) {
  const user = await auth.getUser(uid);
  const claims = user.customClaims || {};
  if (required) {
    if (!["SuperAdmin", "Admin"].includes(claims.role)) {
      throw new Error(`${uid} is not a SuperAdmin or Admin; the second-factor switch only applies to those roles.`);
    }
    const factors = (user.multiFactor && user.multiFactor.enrolledFactors) || [];
    if (factors.length === 0) throw new Error(`${uid} has no enrolled second factor. Enrol one in the app first, or this would lock the account out.`);
  }
  if (Boolean(claims.mfa_required) === required) {
    log(`${uid}: second factor already ${required ? "required" : "not required"}.`);
    return false;
  }
  log(`${uid}: ${apply ? "" : "would "}${required ? "require" : "stop requiring"} a second factor.`);
  if (!apply) {
    log("Dry run. Re-run with --apply to write the claim.");
    return false;
  }
  const next = { ...claims };
  if (required) next.mfa_required = true;
  else delete next.mfa_required;
  await auth.setCustomUserClaims(uid, next);
  await writeAuditLog({
    action: required ? "mfa_required_set" : "mfa_required_cleared",
    actorUid: "scripts/role_claims.js",
    targetUid: uid,
    details: { role: claims.role || "" },
  });
  if (required) {
    await auth.revokeRefreshTokens(uid);
    log("Done. The account signs in again with its second factor.");
  }
  return true;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  initializeApp({ projectId: args.project });
  const db = getFirestore();
  if (args.grant.length > 0) {
    await grant(db, args.grant, args.apply);
  } else if (args.backfillSelfService) {
    await backfillSelfService(db, getAuth(), args.apply);
  } else if (args.bootstrapSuperAdmin) {
    await bootstrapSuperAdmin(getAuth(), args.bootstrapSuperAdmin, args.apply);
  } else if (args.requireMfa) {
    await setMfaRequired(getAuth(), args.requireMfa, true, args.apply);
  } else if (args.clearMfa) {
    await setMfaRequired(getAuth(), args.clearMfa, false, args.apply);
  } else {
    await audit(db, getAuth());
  }
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}

module.exports = { parseArgs, backfillSelfService, bootstrapSuperAdmin, superAdminUids, setMfaRequired };
