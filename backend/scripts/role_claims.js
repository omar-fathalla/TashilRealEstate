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
 * Credentials come from Application Default Credentials (gcloud auth application-default login)
 * or GOOGLE_APPLICATION_CREDENTIALS. Nothing is read from this repository.
 */
const admin = require("firebase-admin");
const { SELF_SERVICE_ROLES } = require("../authz");
const { applyUserRole } = require("../roles");

function parseArgs(argv) {
  const args = { project: "", grant: [], apply: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--project") args.project = argv[++i] || "";
    else if (arg === "--grant") args.grant = (argv[++i] || "").split(",").map((s) => s.trim()).filter(Boolean);
    else if (arg === "--apply") args.apply = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!args.project) throw new Error("--project is required.");
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

async function main() {
  const args = parseArgs(process.argv.slice(2));
  admin.initializeApp({ projectId: args.project });
  const db = admin.firestore();
  if (args.grant.length > 0) {
    await grant(db, args.grant, args.apply);
  } else {
    await audit(db, admin.auth());
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
