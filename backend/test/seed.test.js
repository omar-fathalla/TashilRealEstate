const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const { resolveSeedTarget, DEMO_USERS, DEMO_AGENCY_ID } = require("../seed");

const SEED = path.join(__dirname, "..", "seed.js");
const projectId = process.env.GCLOUD_PROJECT;
const emulatorEnv = {
  FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST,
  FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST,
};

if (!admin.apps.length) admin.initializeApp({ projectId });

// A clean environment: no emulator hosts, no project, no credentials beyond what is passed in.
function liveEnv(extra = {}) {
  return { PATH: process.env.PATH, HOME: process.env.HOME, ...extra };
}

// --- TAQ-45: seed.js is a local script that refuses real projects by default ---

test("TAQ-45: seed.js has no default project", () => {
  assert.throws(() => resolveSeedTarget([], {}), /No project/);
});

test("TAQ-45: seed.js refuses the production project without emulators", () => {
  assert.throws(() => resolveSeedTarget(["--project", "tashil-proptech-os"], {}), /Refusing to seed/);
  assert.throws(() => resolveSeedTarget([], { GCLOUD_PROJECT: "tashil-proptech-os" }), /Refusing to seed/);
  // Only the Firestore emulator attached means Auth would still hit the live project.
  assert.throws(
    () => resolveSeedTarget(["--project", "tashil-proptech-os"], { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" }),
    /Refusing to seed/,
  );
  assert.throws(
    () => resolveSeedTarget(["--project", "tashil-proptech-os"], {
      FIRESTORE_EMULATOR_HOST: "firestore.example.com:8080",
      FIREBASE_AUTH_EMULATOR_HOST: "auth.example.com:9099",
    }),
    /Refusing to seed/,
  );
});

test("TAQ-45: a live project needs the explicit flag and a password from the environment", () => {
  assert.throws(
    () => resolveSeedTarget(["--project", "tashil-proptech-os", "--allow-live-project"], {}),
    /SEED_DEMO_PASSWORD/,
  );
  const target = resolveSeedTarget(
    ["--project", "tashil-proptech-os", "--allow-live-project"],
    { SEED_DEMO_PASSWORD: "a-long-enough-secret" },
  );
  assert.equal(target.live, true);
  assert.equal(target.resetPasswords, false);
});

test("TAQ-45: demo projects and loopback emulators are allowed", () => {
  assert.equal(resolveSeedTarget(["--project", "demo-tashil-dev"], {}).live, false);
  assert.equal(resolveSeedTarget(["--project=tashil-proptech-os"], emulatorEnv).live, false);
});

test("TAQ-45: running seed.js against production exits before touching Firebase", () => {
  const result = spawnSync(process.execPath, [SEED, "--project", "tashil-proptech-os"], {
    env: liveEnv(),
    encoding: "utf8",
    timeout: 20000,
  });
  assert.equal(result.status, 2, result.stdout + result.stderr);
  assert.match(result.stderr, /Refusing to seed "tashil-proptech-os"/);
  assert.doesNotMatch(result.stdout, /Creating user|Seeded/);
});

test("TAQ-45: seed.js seeds the demo accounts into the emulator and keeps existing passwords", async () => {
  const run = () => spawnSync(process.execPath, [SEED, "--project", projectId], {
    env: liveEnv({ ...emulatorEnv, SEED_DEMO_PASSWORD: "emulator-only-pass" }),
    encoding: "utf8",
    timeout: 60000,
  });

  const first = run();
  assert.equal(first.status, 0, first.stdout + first.stderr);
  assert.doesNotMatch(first.stdout, /emulator-only-pass/);
  for (const u of DEMO_USERS) {
    const user = await admin.auth().getUserByEmail(u.email);
    const expected = u.role === "AgencyAdmin" ? { role: u.role, agency_id: DEMO_AGENCY_ID } : { role: u.role };
    assert.deepEqual(user.customClaims, expected);
  }

  const second = run();
  assert.equal(second.status, 0, second.stdout + second.stderr);
  assert.match(second.stdout, /exists, keeping its password/);
});
