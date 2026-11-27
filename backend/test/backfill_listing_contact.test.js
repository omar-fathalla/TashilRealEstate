const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("path");
const { spawnSync } = require("child_process");
const admin = require("firebase-admin");

const { contactUpdate, guardProject } = require("../scripts/backfill_listing_contact");
const { PLATFORM_AGENCY_NAMES, listingContactFields } = require("../listing_contact");

const script = path.join(__dirname, "../scripts/backfill_listing_contact.js");
const projectId = process.env.GCLOUD_PROJECT;
if (!admin.apps.length) admin.initializeApp({ projectId });

const run = (args, env = {}) => spawnSync(process.execPath, [script, ...args], {
  encoding: "utf8",
  timeout: 30000,
  env: { ...process.env, ...env },
});

// --- TAQ-161: re-write the contact fields of listings published before TAQ-150 ---

test("TAQ-161: contactUpdate touches only the three contact fields and only when they differ", () => {
  const DEL = Symbol("delete");
  const platform = listingContactFields(null);
  assert.equal(contactUpdate({ agencyNames: { ...PLATFORM_AGENCY_NAMES }, agencyPhone: "" }, platform, DEL), null);
  assert.deepEqual(
    contactUpdate({ agencyNames: { ar: "تسهيل لإدارة الأملاك", en: "Tashil Property Management" }, agencyPhone: "+20 100 123 4567", title: "x" }, platform, DEL),
    { agencyNames: PLATFORM_AGENCY_NAMES, agencyPhone: "" },
  );
  assert.deepEqual(contactUpdate({ agencyNames: { ...PLATFORM_AGENCY_NAMES }, agencyPhone: "", agencyOrn: "123" }, platform, DEL), { agencyOrn: DEL });
  const verified = { agencyNames: { ar: "أ", en: "A", hi: "A" }, agencyPhone: "", agencyOrn: "ORN-1" };
  assert.deepEqual(contactUpdate({ agencyNames: { ar: "أ", en: "A", hi: "A" }, agencyPhone: "" }, verified, DEL), { agencyOrn: "ORN-1" });
});

test("TAQ-161: the guard refuses tashil-dev even when confirmed, and real projects without confirmation", () => {
  assert.throws(() => guardProject({ project: "tashil-dev", confirmProject: "tashil-dev" }), /never touched/);
  assert.throws(() => guardProject({ project: "tashil-aqar-dev", confirmProject: "" }), /not a demo- project/);
  assert.deepEqual(guardProject({ project: "tashil-aqar-dev", confirmProject: "tashil-aqar-dev" }), { projectId: "tashil-aqar-dev", demo: false });
  const env = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:1" };
  const refused = run(["--project", "tashil-dev", "--confirm-project", "tashil-dev", "--apply"], env);
  assert.equal(refused.status, 2, refused.stderr);
  assert.match(refused.stderr, /never touched/);
  assert.doesNotMatch(refused.stdout, /listing\(s\)/);
});

test("TAQ-161: the CLI dry-runs by default and rewrites only stale contact fields with --apply", async () => {
  const db = admin.firestore();
  const tag = `taq161-${Date.now()}`;
  const agencyId = `${tag}-agency`;
  await db.doc(`Agencies/${agencyId}`).set({ name: "Nile Homes", names: { ar: "بيوت النيل", en: "Nile Homes" }, orn: "ORN-77", verified_badge: true });
  const stale = { title: "Flat", agencyNames: { ar: "تسهيل لإدارة الأملاك", en: "Tashil Property Management" }, agencyPhone: "+20 100 123 4567" };
  await db.doc(`Properties/${tag}-platform`).set({ ...stale, owner_id: "o" });
  await db.doc(`Properties/${tag}-agency`).set({ ...stale, owner_id: "o", agency_id: agencyId });
  await db.doc(`Properties/${tag}-fine`).set({ title: "Ok", owner_id: "o", ...listingContactFields(null) });
  try {
    const dry = run(["--project", projectId]);
    assert.equal(dry.status, 0, `${dry.stdout}${dry.stderr}`);
    assert.match(dry.stdout, new RegExp(`^Target project: ${projectId} \\(dry run: no writes\\)`));
    assert.match(dry.stdout, new RegExp(`${tag}-agency`));
    assert.match(dry.stdout, new RegExp(`${tag}-platform`));
    assert.doesNotMatch(dry.stdout, new RegExp(`${tag}-fine`));
    assert.equal((await db.doc(`Properties/${tag}-platform`).get()).get("agencyPhone"), "+20 100 123 4567", "the default is a dry run");

    const applied = run(["--project", projectId, "--apply"]);
    assert.equal(applied.status, 0, `${applied.stdout}${applied.stderr}`);
    assert.match(applied.stdout, /Contact fields updated\./);
    const platform = (await db.doc(`Properties/${tag}-platform`).get()).data();
    assert.deepEqual(platform.agencyNames, PLATFORM_AGENCY_NAMES);
    assert.equal(platform.agencyPhone, "");
    assert.equal(platform.title, "Flat");
    const agency = (await db.doc(`Properties/${tag}-agency`).get()).data();
    assert.deepEqual(agency.agencyNames, { ar: "بيوت النيل", en: "Nile Homes", hi: "Nile Homes" });
    assert.equal(agency.agencyOrn, "ORN-77");
    assert.equal(agency.agencyPhone, "");

    const again = run(["--project", projectId]);
    assert.doesNotMatch(again.stdout, new RegExp(tag));
  } finally {
    for (const id of ["platform", "agency", "fine"]) await db.doc(`Properties/${tag}-${id}`).delete();
    await db.doc(`Agencies/${agencyId}`).delete();
  }
});
