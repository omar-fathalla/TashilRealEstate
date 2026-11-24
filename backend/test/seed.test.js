const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const { resolveSeedTarget, DEMO_USERS, DEMO_AGENCY_ID, TEST_USERS } = require("../seed");

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

// --- TAQ-91: the per-role test accounts on @test.tashilaqar.com ---

const SET = ["--set", "tashilaqar-test"];
const allPasswords = () => Object.fromEntries(TEST_USERS.map((u) => [`SEED_PW_${u.key.toUpperCase()}`, `pw-${u.key}-12345`]));

test("TAQ-91: the test set defines seven accounts, one per role, all on the test domain", () => {
  assert.deepEqual(TEST_USERS.map((u) => [u.key, u.role]), [
    ["visitor", null],
    ["tenant", "Tenant"],
    ["owner", "Owner"],
    ["agency", "AgencyAdmin"],
    ["investor", "Investor"],
    ["admin", "Admin"],
    ["superadmin", "SuperAdmin"],
  ]);
  for (const u of TEST_USERS) assert.equal(u.email, `${u.key}@test.tashilaqar.com`);
});

test("TAQ-91: the test set never targets production, even with emulator hosts or --allow-live-project", () => {
  const prod = JSON.parse(require("node:fs").readFileSync(path.join(__dirname, "..", "..", ".firebaserc"), "utf8")).projects.prod;
  assert.ok(prod);
  for (const env of [{}, emulatorEnv, allPasswords(), { ...emulatorEnv, ...allPasswords() }]) {
    for (const extra of [[], ["--allow-live-project"]]) {
      assert.throws(() => resolveSeedTarget([...SET, "--project", prod, ...extra], env), /production project/);
      assert.throws(() => resolveSeedTarget([...SET, `--project=${prod}`, ...extra], env), /production project/);
    }
  }
  assert.throws(() => resolveSeedTarget(SET, { GCLOUD_PROJECT: prod, ...emulatorEnv }), /production project/);
});

test("TAQ-91: the test set only runs on emulators, demo projects or the dev project with the live flag", () => {
  assert.throws(() => resolveSeedTarget([...SET, "--project", "some-other-project", "--allow-live-project"], allPasswords()), /Refusing to seed test accounts/);
  assert.throws(() => resolveSeedTarget([...SET, "--project", "tashil-aqar-dev"], allPasswords()), /--allow-live-project/);
  const dev = resolveSeedTarget([...SET, "--project", "tashil-aqar-dev", "--allow-live-project"], allPasswords());
  assert.equal(dev.live, true);
  assert.equal(dev.projectId, "tashil-aqar-dev");
  assert.equal(resolveSeedTarget([...SET, "--project", "demo-tashil-dev"], {}).live, false);
  assert.equal(resolveSeedTarget([...SET, "--project", "any-name"], emulatorEnv).live, false);
});

test("TAQ-91: seeding the dev project needs every per-role password, each from its own variable", () => {
  const dev = [...SET, "--project", "tashil-aqar-dev", "--allow-live-project"];
  assert.throws(() => resolveSeedTarget(dev, {}), /SEED_PW_VISITOR.*SEED_PW_SUPERADMIN/);
  const partial = allPasswords();
  delete partial.SEED_PW_OWNER;
  assert.throws(() => resolveSeedTarget(dev, partial), /requires SEED_PW_OWNER\./);
  assert.throws(() => resolveSeedTarget(dev, { ...allPasswords(), SEED_PW_ADMIN: "short" }), /SEED_PW_ADMIN must be at least 8/);
  assert.throws(() => resolveSeedTarget(dev, { SEED_DEMO_PASSWORD: "shared-password-1" }), /SEED_PW_/);
  const target = resolveSeedTarget(dev, allPasswords());
  assert.equal(target.passwords.owner, "pw-owner-12345");
  assert.equal(target.passwords.superadmin, "pw-superadmin-12345");
});

test("TAQ-91: an unknown --set is rejected", () => {
  assert.throws(() => resolveSeedTarget(["--set", "everything", "--project", "demo-x"], {}), /Unknown --set/);
});

test("TAQ-91: running the test set against production exits before touching Firebase", () => {
  const prod = JSON.parse(require("node:fs").readFileSync(path.join(__dirname, "..", "..", ".firebaserc"), "utf8")).projects.prod;
  const result = spawnSync(process.execPath, [SEED, ...SET, "--project", prod, "--allow-live-project"], {
    env: liveEnv({ ...emulatorEnv, ...allPasswords() }),
    encoding: "utf8",
    timeout: 20000,
  });
  assert.equal(result.status, 2, result.stdout + result.stderr);
  assert.match(result.stderr, /production project/);
  assert.doesNotMatch(result.stdout, /Creating user|Seeded/);
});

test("TAQ-91: the test set creates all seven accounts with the right claims and separate passwords", async () => {
  const passwords = allPasswords();
  const run = (extra = []) => spawnSync(process.execPath, [SEED, ...SET, "--project", projectId, ...extra], {
    env: liveEnv({ ...emulatorEnv, ...passwords }),
    encoding: "utf8",
    timeout: 60000,
  });
  const first = run();
  assert.equal(first.status, 0, first.stdout + first.stderr);
  for (const value of Object.values(passwords)) assert.ok(!first.stdout.includes(value) && !first.stderr.includes(value));
  assert.doesNotMatch(first.stdout, /Generated password/);

  const expectedClaims = {
    visitor: {},
    tenant: { role: "Tenant" },
    owner: { role: "Owner" },
    agency: { role: "AgencyAdmin", agency_id: DEMO_AGENCY_ID },
    investor: { role: "Investor" },
    admin: { role: "Admin" },
    superadmin: { role: "SuperAdmin" },
  };
  for (const u of TEST_USERS) {
    const record = await admin.auth().getUserByEmail(u.email);
    assert.deepEqual(record.customClaims || {}, expectedClaims[u.key], u.email);
    const profile = (await admin.firestore().collection("Users").doc(record.uid).get()).data();
    assert.equal(profile.email, u.email);
    assert.equal(profile.role, u.role === null ? undefined : u.role);
    assert.equal(profile.demo_seed, "tashilaqar-test");
  }

  const signIn = async (email, password) => {
    const res = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    });
    return res.status;
  };
  assert.equal(await signIn("owner@test.tashilaqar.com", passwords.SEED_PW_OWNER), 200);
  assert.equal(await signIn("superadmin@test.tashilaqar.com", passwords.SEED_PW_SUPERADMIN), 200);
  assert.equal(await signIn("owner@test.tashilaqar.com", passwords.SEED_PW_SUPERADMIN), 400, "each account has its own password");

  const second = run();
  assert.equal(second.status, 0, second.stdout + second.stderr);
  assert.match(second.stdout, /exists, keeping its password/);
});

test("TAQ-91: without password variables an emulator run generates and prints per-account passwords", async () => {
  const result = spawnSync(process.execPath, [SEED, ...SET, "--project", projectId, "--reset-passwords"], {
    env: liveEnv(emulatorEnv),
    encoding: "utf8",
    timeout: 60000,
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  const lines = result.stdout.split("\n").filter((l) => l.startsWith("Generated password for"));
  assert.equal(lines.length, TEST_USERS.length);
  assert.equal(new Set(lines.map((l) => l.split(": ")[1])).size, TEST_USERS.length, "every password is different");
});
