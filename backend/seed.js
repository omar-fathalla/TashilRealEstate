#!/usr/bin/env node
/**
 * Local admin script that seeds demo accounts. Two sets:
 *
 * 1. Default: agency@, owner@, tenant@test.com (one shared password).
 *
 *   firebase emulators:exec --only firestore,auth --project demo-tashil-dev 'node seed.js'
 *   node seed.js --project demo-tashil-dev            # demo-* projects are always allowed
 *   SEED_DEMO_PASSWORD=... node seed.js --project <real-id> --allow-live-project
 *
 * 2. `--set tashilaqar-test`: one account per role on @test.tashilaqar.com (visitor, tenant,
 *    owner, agency, investor, admin, superadmin), each with its own password from its own
 *    variable (SEED_PW_VISITOR, SEED_PW_TENANT, SEED_PW_OWNER, SEED_PW_AGENCY, SEED_PW_INVESTOR,
 *    SEED_PW_ADMIN, SEED_PW_SUPERADMIN). Emulators and demo-* projects may leave them unset (random
 *    passwords are printed); the dev project needs all seven. This set only ever runs against
 *    emulators, demo-* projects, or the Tashil Aqar dev project with --allow-live-project, and never
 *    against the production project named by the `prod` alias in .firebaserc.
 *
 *   firebase emulators:exec --only firestore,auth --project demo-tashil-dev 'node seed.js --set tashilaqar-test'
 *   SEED_PW_OWNER=... (and the other six) node seed.js --set tashilaqar-test --project tashil-aqar-dev --allow-live-project
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

const TEST_DOMAIN = 'test.tashilaqar.com';
const TEST_SET = 'tashilaqar-test';
// `role: null` is a signed-in user with no claim and no profile role. A signed-out visitor
// needs no account at all; this one exists to test what a logged-in user without a role can do.
const TEST_USERS = [
  { key: 'visitor', email: `visitor@${TEST_DOMAIN}`, role: null, fullName: 'Test Visitor' },
  { key: 'tenant', email: `tenant@${TEST_DOMAIN}`, role: 'Tenant', fullName: 'Test Tenant' },
  { key: 'owner', email: `owner@${TEST_DOMAIN}`, role: 'Owner', fullName: 'Test Owner' },
  { key: 'agency', email: `agency@${TEST_DOMAIN}`, role: 'AgencyAdmin', fullName: 'Test Agency' },
  { key: 'investor', email: `investor@${TEST_DOMAIN}`, role: 'Investor', fullName: 'Test Investor' },
  { key: 'admin', email: `admin@${TEST_DOMAIN}`, role: 'Admin', fullName: 'Test Platform Admin' },
  { key: 'superadmin', email: `superadmin@${TEST_DOMAIN}`, role: 'SuperAdmin', fullName: 'Test Super Admin' },
];
// The only real project the test set may write to.
const TEST_SET_LIVE_PROJECTS = ['tashil-aqar-dev'];

const LOOPBACK_HOST = /^(localhost|127\.0\.0\.1|\[::1\]|::1)(:\d+)?$/i;

function parseArgs(argv) {
  const args = { project: '', allowLiveProject: false, resetPasswords: false, set: 'demo' };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--project') args.project = argv[++i] || '';
    else if (arg.startsWith('--project=')) args.project = arg.slice('--project='.length);
    else if (arg === '--allow-live-project') args.allowLiveProject = true;
    else if (arg === '--reset-passwords') args.resetPasswords = true;
    else if (arg === '--set') args.set = argv[++i] || '';
    else if (arg.startsWith('--set=')) args.set = arg.slice('--set='.length);
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return args;
}

function isLoopback(host) {
  return typeof host === 'string' && LOOPBACK_HOST.test(host.trim());
}

/** The production project id, read from the `prod` alias so no id is hard-coded here. */
function productionProjectId() {
  try {
    const rc = JSON.parse(require('fs').readFileSync(require('path').join(__dirname, '..', '.firebaserc'), 'utf8'));
    return (rc.projects && rc.projects.prod) || '';
  } catch (_) {
    return '';
  }
}

function resolveTestSetTarget(args, projectId, emulated, demoProject, env) {
  const production = productionProjectId();
  if (!production) {
    throw new Error('Cannot read the prod alias from .firebaserc, so the test set cannot prove it is not production.');
  }
  if (projectId === production) {
    throw new Error(`Refusing to seed test accounts into "${projectId}": it is the production project.`);
  }
  const devProject = TEST_SET_LIVE_PROJECTS.includes(projectId);
  if (!emulated && !demoProject) {
    if (!devProject) {
      throw new Error(
        `Refusing to seed test accounts into "${projectId}". The ${TEST_SET} set only runs against ` +
        `the emulators, demo-* projects, or ${TEST_SET_LIVE_PROJECTS.join(', ')} with --allow-live-project.`
      );
    }
    if (!args.allowLiveProject) {
      throw new Error(`Seeding "${projectId}" needs --allow-live-project (it is a real project).`);
    }
  }
  const live = !emulated && !demoProject;
  const passwords = {};
  const missing = [];
  for (const u of TEST_USERS) {
    const name = `SEED_PW_${u.key.toUpperCase()}`;
    const value = env[name] || '';
    if (value && value.length < 8) throw new Error(`${name} must be at least 8 characters.`);
    if (value) passwords[u.key] = value;
    else if (live) missing.push(name);
  }
  if (missing.length) throw new Error(`Seeding a real project requires ${missing.join(', ')}.`);
  return { projectId, live, resetPasswords: args.resetPasswords, set: TEST_SET, passwords };
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
  if (args.set === TEST_SET) return resolveTestSetTarget(args, projectId, emulated, demoProject, env);
  if (args.set !== 'demo') throw new Error(`Unknown --set "${args.set}". Use ${TEST_SET} or omit it.`);
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
  const { initializeApp, getApps } = require('firebase-admin/app');
  if (!getApps().length) initializeApp({ projectId: target.projectId });
  const { applyUserRole } = require('./roles');

  const auth = require('firebase-admin/auth').getAuth();
  const db = require('firebase-admin/firestore').getFirestore();
  const testSet = target.set === TEST_SET;
  const users = testSet ? TEST_USERS : DEMO_USERS;
  const sharedPassword = target.password || crypto.randomBytes(12).toString('base64url');
  const generated = [];
  let failures = 0;

  // setUserRole only accepts an agency that exists, so the demo agency gets its document first.
  // An existing document is left as it is.
  const agencyRef = db.collection('Agencies').doc(DEMO_AGENCY_ID);
  if (!(await agencyRef.get()).exists) {
    await agencyRef.set({ name: 'Tashil Demo Agency', countryCode: 'AE', updated_at: require('firebase-admin/firestore').FieldValue.serverTimestamp() });
    console.log(`Created demo agency ${DEMO_AGENCY_ID}`);
  }

  for (const u of users) {
    try {
      let password = testSet ? target.passwords[u.key] : target.password;
      const wasGenerated = !password;
      if (wasGenerated) password = testSet ? crypto.randomBytes(12).toString('base64url') : sharedPassword;
      let userRecord;
      try {
        userRecord = await auth.getUserByEmail(u.email);
        if (target.resetPasswords) {
          console.log(`User ${u.email} exists, resetting password...`);
          userRecord = await auth.updateUser(userRecord.uid, { password });
          if (wasGenerated) generated.push(testSet ? `${u.email}: ${password}` : '');
        } else {
          console.log(`User ${u.email} exists, keeping its password.`);
        }
      } catch (err) {
        if (err.code !== 'auth/user-not-found') throw err;
        console.log(`Creating user ${u.email}...`);
        userRecord = await auth.createUser({ email: u.email, password, displayName: u.fullName });
        if (wasGenerated) generated.push(testSet ? `${u.email}: ${password}` : '');
      }

      await db.collection('Users').doc(userRecord.uid).set({
        user_id: userRecord.uid,
        email: u.email,
        full_name: u.fullName,
        ...(testSet ? { demo_seed: TEST_SET } : {}),
      }, { merge: true });
      if (u.role === null) {
        const claimed = userRecord.customClaims && userRecord.customClaims.role;
        console.log(claimed
          ? `Warning: ${u.email} has the claim "${claimed}"; a visitor account should have none.`
          : `Seeded ${u.email} with no role`);
        continue;
      }
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

  if (testSet) {
    for (const line of generated.filter(Boolean)) console.log(`Generated password for ${line}`);
  } else if (generated.some((g) => g === '')) {
    console.log(`Generated demo password for new accounts: ${sharedPassword}`);
  }
  return failures;
}

module.exports = { resolveSeedTarget, DEMO_USERS, DEMO_AGENCY_ID, TEST_USERS, TEST_SET, TEST_DOMAIN };

if (require.main === module) {
  let target;
  try {
    target = resolveSeedTarget(process.argv.slice(2), process.env);
  } catch (err) {
    console.error(err.message);
    process.exit(2);
  }
  console.log(`Seeding ${target.set === TEST_SET ? TEST_SET : 'demo'} accounts into ${target.projectId}${target.live ? ' (LIVE project)' : ''}`);
  seed(target)
    .then((failures) => process.exit(failures ? 1 : 0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
