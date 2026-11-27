const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("path");
const fs = require("fs");
const { spawnSync } = require("child_process");
const admin = require("firebase-admin");

const script = path.join(__dirname, "../scripts/backfill_hidden_unpublished.js");
const projectId = process.env.GCLOUD_PROJECT;
if (!admin.apps.length) admin.initializeApp({ projectId });

const run = (args) => spawnSync(process.execPath, [script, ...args], {
  encoding: "utf8",
  timeout: 30000,
  env: process.env,
});

// --- TAQ-160: the TAQ-135 clean-up script starts (it used to die on "default Firebase app already exists") ---

test("TAQ-160: the script does not load the trigger module, which initialises the default app", () => {
  const source = fs.readFileSync(script, "utf8");
  assert.doesNotMatch(source, /require\(["']\.\.\/hidden_listing_guard["']\)/);
  assert.match(source, /require\(["']\.\.\/hidden_listing_predicate["']\)/);
  const predicate = fs.readFileSync(path.join(__dirname, "../hidden_listing_predicate.js"), "utf8");
  assert.doesNotMatch(predicate, /require\(["']firebase-admin["']\)|initializeApp\(/);
});

test("TAQ-160: the trigger and the script share one predicate", () => {
  const guard = require("../hidden_listing_guard");
  const predicate = require("../hidden_listing_predicate");
  assert.equal(guard.isPublishedAndHidden, predicate.isPublishedAndHidden);
  assert.equal(predicate.isPublishedAndHidden({ is_published: true, moderation_hidden: "true" }), true);
  assert.equal(predicate.isPublishedAndHidden({ is_published: false, moderation_hidden: true }), false);
  assert.equal(predicate.isPublishedAndHidden(null), false);
});

test("TAQ-160: the CLI dry-runs against the emulator, prints the count and writes only with --apply", async () => {
  const db = admin.firestore();
  const id = `taq160-${Date.now()}`;
  const ok = `${id}-ok`;
  await db.doc(`Properties/${id}`).set({ id, owner_id: "o", moderation_hidden: true, is_published: true });
  await db.doc(`Properties/${ok}`).set({ id: ok, owner_id: "o", moderation_hidden: true, is_published: false });
  try {
    const dry = run(["--project", projectId]);
    assert.equal(dry.status, 0, `${dry.stdout}${dry.stderr}`);
    assert.doesNotMatch(dry.stderr, /already exists/);
    assert.match(dry.stdout, new RegExp(`^Target project: ${projectId} \\(dry run: no writes\\)`));
    assert.match(dry.stdout, /\d+ listing\(s\) published while hidden: /);
    assert.match(dry.stdout, new RegExp(`published while hidden: .*${id}`));
    assert.doesNotMatch(dry.stdout, new RegExp(`${ok}`));
    assert.equal((await db.doc(`Properties/${id}`).get()).get("is_published"), true, "the default is a dry run");

    const applied = run(["--project", projectId, "--apply"]);
    assert.equal(applied.status, 0, `${applied.stdout}${applied.stderr}`);
    assert.match(applied.stdout, /Unpublished\./);
    assert.equal((await db.doc(`Properties/${id}`).get()).get("is_published"), false);
    const again = run(["--project", projectId]);
    assert.doesNotMatch(again.stdout, new RegExp(`${id}`));
  } finally {
    await db.doc(`Properties/${id}`).delete();
    await db.doc(`Properties/${ok}`).delete();
  }
});
