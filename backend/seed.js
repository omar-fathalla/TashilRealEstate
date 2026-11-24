#!/usr/bin/env node
/**
 * Local admin script that seeds the demo accounts (agency@, owner@, tenant@test.com).
 *
 *   firebase emulators:exec --only firestore,auth --project demo-tashil-dev 'node seed.js'
 *   node seed.js --project demo-tashil-dev            # demo-* projects are always allowed
 *   SEED_DEMO_PASSWORD=... node seed.js --project <real-id> --allow-live-project
 *
 * The project comes from --project, GCLOUD_PROJECT, FIREBASE_PROJECT_ID, or GOOGLE_CLOUD_PROJECT;
 * there is no default. Real projects are refused unless both the Firestore and Auth emulators
 * are on loopback, or --allow-live-project is passed explicitly.
 *
 * The password comes from SEED_DEMO_PASSWORD (never argv or source). Without it a random one
 * is generated and printed, which is only allowed for emulator or demo-* targets. Existing
 * accounts keep their password unless --reset-passwords is passed. Nothing is ever deleted.
 */
const crypto = require('crypto');

const DEMO_AGENCY_ID = 'agency_test_123';
const DEMO_USERS = [
  { email: 'agency@test.com', role: 'AgencyAdmin', fullName: 'Test Agency' },
  { email: 'owner@test.com', role: 'Owner', fullName: 'Test Owner' },
  { email: 'tenant@test.com', role: 'Tenant', fullName: 'Test Tenant' },
];

const LOOPBACK_HOST = /^(localhost|127\.0\.0\.1|\[::1\]|::1)(:\d+)?$/i;

function parseArgs(argv) {
  const args = { project: '', allowLiveProject: false, resetPasswords: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--project') args.project = argv[++i] || '';
    else if (arg.startsWith('--project=')) args.project = arg.slice('--project='.length);
    else if (arg === '--allow-live-project') args.allowLiveProject = true;
    else if (arg === '--reset-passwords') args.resetPasswords = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return args;
}

function isLoopback(host) {
  return typeof host === 'string' && LOOPBACK_HOST.test(host.trim());
}

/** Resolves and validates the seed target. Throws before any Firebase SDK is touched. */
function resolveSeedTarget(argv, env) {
  const args = parseArgs(argv);
  const projectId = args.project || env.GCLOUD_PROJECT || env.FIREBASE_PROJECT_ID || env.GOOGLE_CLOUD_PROJECT || '';
  if (!projectId) {
    throw new Error('No project. Pass --project <id> or set GCLOUD_PROJECT.');
  }

  const emulated = isLoopback(env.FIRESTORE_EMULATOR_HOST) && isLoopback(env.FIREBASE_AUTH_EMULATOR_HOST);
  const demoProject = projectId.startsWith('demo-');
  const live = !emulated && !demoProject;
  if (live && !args.allowLiveProject) {
    throw new Error(
      `Refusing to seed "${projectId}": it is not a demo-* project and the Firestore/Auth emulators ` +
      'are not both on loopback. Pass --allow-live-project to seed a real project on purpose.'
    );
  }

  const password = env.SEED_DEMO_PASSWORD || '';
  if (live && !password) {
    throw new Error('Seeding a real project requires SEED_DEMO_PASSWORD.');
  }
  if (password && password.length < 8) {
    throw new Error('SEED_DEMO_PASSWORD must be at least 8 characters.');
  }

  return {
    projectId,
    live,
    resetPasswords: args.resetPasswords,
    password,
  };
}

async function seed(target) {
  const admin = require('firebase-admin');
  if (!admin.apps.length) admin.initializeApp({ projectId: target.projectId });
  const { applyUserRole } = require('./roles');

  const auth = admin.auth();
  const db = admin.firestore();
  const password = target.password || crypto.randomBytes(12).toString('base64url');
  const generated = !target.password;
  let failures = 0;

  for (const u of DEMO_USERS) {
    try {
      let userRecord;
      try {
        userRecord = await auth.getUserByEmail(u.email);
        if (target.resetPasswords) {
          console.log(`User ${u.email} exists, resetting password...`);
          userRecord = await auth.updateUser(userRecord.uid, { password });
        } else {
          console.log(`User ${u.email} exists, keeping its password.`);
        }
      } catch (err) {
        if (err.code !== 'auth/user-not-found') throw err;
        console.log(`Creating user ${u.email}...`);
        userRecord = await auth.createUser({ email: u.email, password, displayName: u.fullName });
      }

      await db.collection('Users').doc(userRecord.uid).set({
        user_id: userRecord.uid,
        email: u.email,
        full_name: u.fullName,
      }, { merge: true });
      await applyUserRole({
        uid: userRecord.uid,
        role: u.role,
        agencyId: u.role === 'AgencyAdmin' ? DEMO_AGENCY_ID : undefined,
        actorUid: 'seed.js',
      });
      console.log(`Seeded ${u.email} as ${u.role}`);
    } catch (error) {
      failures++;
      console.error(`Error processing ${u.email}:`, error.message);
    }
  }

  if (generated) console.log(`Generated demo password for new accounts: ${password}`);
  return failures;
}

module.exports = { resolveSeedTarget, DEMO_USERS, DEMO_AGENCY_ID };

if (require.main === module) {
  let target;
  try {
    target = resolveSeedTarget(process.argv.slice(2), process.env);
  } catch (err) {
    console.error(err.message);
    process.exit(2);
  }
  console.log(`Seeding demo accounts into ${target.projectId}${target.live ? ' (LIVE project)' : ''}`);
  seed(target)
    .then((failures) => process.exit(failures ? 1 : 0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
