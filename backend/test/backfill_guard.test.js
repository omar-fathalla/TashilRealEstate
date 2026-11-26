const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("path");
const { spawnSync } = require("child_process");
const admin = require("firebase-admin");

const { parseArgs, resolveTarget } = require("../scripts/backfill_property_moderation");

const script = path.join(__dirname, "../scripts/backfill_property_moderation.js");
const projectId = process.env.GCLOUD_PROJECT;
if (!admin.apps.length) admin.initializeApp({ projectId });

function run(args, env = {}) {
  return spawnSync(process.execPath, [script, ...args], {
    encoding: "utf8",
    timeout: 30000,
    env: { ...process.env, ...env },
  });
}

// --- TAQ-100: the backfill script refuses real projects unless the id is confirmed ---

test("TAQ-100: parseArgs reads --project, --apply and --confirm-project in both spellings", () => {
  assert.deepEqual(parseArgs(["--project", "demo-x"]), { project: "demo-x", apply: false, confirmProject: "" });
  assert.deepEqual(parseArgs(["--project=demo-x", "--apply"]), { project: "demo-x", apply: true, confirmProject: "" });
  assert.deepEqual(parseArgs(["--project", "p", "--confirm-project=p"]), { project: "p", apply: false, confirmProject: "p" });
  assert.deepEqual(parseArgs(["--project", "p", "--confirm-project", "p", "--apply"]), { project: "p", apply: true, confirmProject: "p" });
  assert.throws(() => parseArgs([]), /--project is required/);
  assert.throws(() => parseArgs(["--project", "demo-x", "--force"]), /Unknown argument/);
});

test("TAQ-100: demo- projects need no confirmation", () => {
  for (const project of ["demo-tashil-test", "demo-x", "demo-"]) {
    assert.deepEqual(resolveTarget({ project, confirmProject: "" }), { projectId: project, demo: true });
  }
});

test("TAQ-100: any other project is refused without an exactly matching --confirm-project", () => {
  for (const project of ["qa-fake-prod-xyz", "my-project", "Demo-x", "xdemo-x", "demo", "x-demo-y"]) {
    assert.throws(() => resolveTarget({ project, confirmProject: "" }), /not a demo- project/, project);
    assert.throws(() => resolveTarget({ project, confirmProject: "other" }), /got --confirm-project=other/, project);
    assert.throws(() => resolveTarget({ project, confirmProject: `${project} ` }), /not a demo- project/, project);
    assert.throws(() => resolveTarget({ project, confirmProject: project.toUpperCase() + "x" }), /not a demo- project/, project);
  }
  assert.deepEqual(resolveTarget({ project: "my-project", confirmProject: "my-project" }), { projectId: "my-project", demo: false });
  assert.equal(resolveTarget({ project: "qa-fake-prod-xyz", confirmProject: "qa-fake-prod-xyz" }).demo, false);
});

test("TAQ-100: the CLI prints the target first and exits 2 for a real project without confirmation, touching nothing", () => {
  // The Firestore host points nowhere: if the script got past the guard it would fail or hang here.
  const env = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:1" };
  for (const args of [
    ["--project", "qa-fake-prod-xyz"],
    ["--project", "qa-fake-prod-xyz", "--apply"],
    ["--project=some-real-project", "--confirm-project=qa-fake-prod-xyz"],
    ["--project", "some-real-project", "--confirm-project", ""],
  ]) {
    const result = run(args, env);
    assert.equal(result.status, 2, `${args.join(" ")}: ${result.stdout}${result.stderr}`);
    assert.match(result.stdout, /^Target project: /);
    assert.match(result.stderr, /Refusing to run against/);
    assert.doesNotMatch(result.stdout, /hidden listing/);
  }
  const first = run(["--project", "qa-fake-prod-xyz", "--apply"], env).stdout.split("\n")[0];
  assert.equal(first, "Target project: qa-fake-prod-xyz (APPLY: will write)");
});

test("TAQ-100: the CLI dry-runs a demo- project by default and writes only with --apply", async () => {
  const db = admin.firestore();
  const id = `guard-${Date.now()}`;
  await db.doc(`Properties/${id}`).set({ id, owner_id: "o", moderation_hidden: true, is_published: false });

  const dry = run(["--project", projectId]);
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, new RegExp(`^Target project: ${projectId} \\(dry run: no writes\\)`));
  assert.match(dry.stdout, new RegExp(`without a moderation doc: .*${id}`));
  assert.match(dry.stdout, /Dry run\. Re-run with --apply/);
  assert.equal((await db.doc(`PropertyModeration/${id}`).get()).exists, false, "the default is a dry run");

  const applied = run(["--project", projectId, "--apply"]);
  assert.equal(applied.status, 0, applied.stderr);
  assert.match(applied.stdout, /\(APPLY: will write\)/);
  assert.equal((await db.doc(`PropertyModeration/${id}`).get()).get("hidden"), true);
  await db.doc(`Properties/${id}`).delete();
  await db.doc(`PropertyModeration/${id}`).delete();
});

test("TAQ-100: an unknown flag and a missing project id fail before any connection", () => {
  const env = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:1" };
  const noProject = run([], env);
  assert.equal(noProject.status, 1);
  assert.match(noProject.stderr, /--project is required/);
  assert.doesNotMatch(noProject.stdout, /Target project/);
  const unknown = run(["--project", projectId, "--yes"], env);
  assert.equal(unknown.status, 1);
  assert.match(unknown.stderr, /Unknown argument: --yes/);
});
