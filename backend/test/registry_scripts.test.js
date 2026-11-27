// TAQ-110 N-1 / N-3: the registry backfill (dev and demo only, dry run by default, conflicts are
// report-only) and the lease audit's read-only production mode. Guard tests use the fake id
// qa-fake-prod-xyz; the real production id is never passed to either script here.
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");
const { initializeApp, getApps } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const backfill = require("../scripts/backfill_property_owners");
const auditScript = require("../scripts/audit_leases");

const projectId = process.env.GCLOUD_PROJECT;
if (!getApps().length) initializeApp({ projectId });
const db = getFirestore();
const FAKE_PROD = "qa-fake-prod-xyz";
const NOWHERE = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:1", FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:1" };

const run = (script, args, env = {}) => spawnSync(process.execPath, [path.join(__dirname, "../scripts", script), ...args], {
  encoding: "utf8",
  timeout: 30000,
  env: { ...process.env, ...env },
});

async function clearAll() {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
}

async function user(uid, role) {
  await getAuth().createUser({ uid });
  await getAuth().setCustomUserClaims(uid, { role });
  await db.doc(`Users/${uid}`).set({ role });
}

test.beforeEach(clearAll);

const registry = async () => Object.fromEntries((await db.collection("PropertyOwners").get()).docs.map((d) => [d.id, d.get("owner_id")]));

/** One of each case the backfill sorts ids into. */
async function seedMixed() {
  await user("ownerA", "Owner");
  await user("ownerB", "Owner");
  await user("agency", "AgencyAdmin");
  await user("tenantT", "Tenant");
  // Private docs carry `id` like every app-written doc (TAQ-128); the other paths are left as given.
  const set = (p, data) => db.doc(p).set(p.startsWith("Users/") ? { id: p.split("/").pop(), ...data } : data);
  await set("Users/ownerA/properties/solo-a", { title: "x", rentalStatus: "available" });
  await set("Users/agency/properties/solo-agency", { title: "x", rentalStatus: "Rented" });
  await set("Properties/solo-agency", { owner_id: "agency" });
  await set("Users/ownerA/properties/shared", { title: "x" });
  await set("Users/ownerB/properties/shared", { title: "x" });
  await set("Users/ownerB/properties/pub-mismatch", { title: "x" });
  await set("Properties/pub-mismatch", { owner_id: "ownerA" });
  await set("Users/tenantT/properties/tenant-only", { title: "x" });
  await set("Users/ownerA/properties/done", { title: "x" });
  await set("PropertyOwners/done", { owner_id: "ownerA" });
  await set("Users/ownerB/properties/other-reg", { title: "x" });
  await set("PropertyOwners/other-reg", { owner_id: "ownerA" });
  await set("Users/ownerA/properties/flagged-ok", { title: "x" });
  await set("Users/ownerB/properties/flagged-ok", { title: "x", id_conflict: true });
  await set("PropertyOwners/flagged-ok", { owner_id: "ownerA" });
  await set("Agencies/ag1/properties/not-a-user-tree", { title: "ignored" });
}

// --- backfill guard ---

test("TAQ-110 N-1: the backfill accepts demo- projects and tashil-aqar-dev only", () => {
  const base = { project: "demo-x", write: false, prod: false, fixIdFields: false, batchSize: 100, cursor: "", overrides: "", confirmNoProfile: [] };
  assert.deepEqual(backfill.parseArgs(["--project", "demo-x"]), base);
  assert.deepEqual(backfill.parseArgs(["--project=demo-x", "--write"]), { ...base, write: true });
  assert.deepEqual(backfill.parseArgs(["--project=demo-x", "--fix-id-fields", "--write"]), { ...base, write: true, fixIdFields: true });
  assert.deepEqual(backfill.parseArgs(["--project=demo-x", "--confirm-no-profile-owner", "u1", "--confirm-no-profile-owner=u2"]), { ...base, confirmNoProfile: ["u1", "u2"] });
  assert.deepEqual(backfill.parseArgs(["--project", "p", "--prod", "--batch-size=7", "--cursor", "c1", "--overrides", "o.json"]), { ...base, project: "p", prod: true, batchSize: 7, cursor: "c1", overrides: "o.json" });
  for (const bad of ["0", "401", "x", "1.5"]) assert.throws(() => backfill.parseArgs(["--project", "p", "--batch-size", bad]), /--batch-size/);
  assert.throws(() => backfill.parseArgs([]), /--project is required/);
  assert.throws(() => backfill.parseArgs(["--project", "demo-x", "--apply"]), /Unknown argument/);
  assert.equal(backfill.resolveTarget("demo-tashil-test"), "demo-tashil-test");
  assert.equal(backfill.resolveTarget("tashil-aqar-dev"), "tashil-aqar-dev");
  for (const project of [FAKE_PROD, "Demo-x", "xdemo-x", "tashil-aqar-dev ", "tashil-aqar-dev2", "", undefined]) {
    assert.throws(() => backfill.resolveTarget(project), /Refusing to run against/, String(project));
  }
});

test("TAQ-110 N-1: the backfill CLI refuses any other project before reading or writing anything", () => {
  for (const args of [["--project", FAKE_PROD], ["--project", FAKE_PROD, "--write"], [`--project=${FAKE_PROD}`, "--write"]]) {
    const result = run("backfill_property_owners.js", args, NOWHERE);
    assert.equal(result.status, 2, `${args.join(" ")}: ${result.stdout}${result.stderr}`);
    assert.match(result.stdout, new RegExp(`^Target project: ${FAKE_PROD} `));
    assert.match(result.stderr, /Refusing to run against/);
    assert.doesNotMatch(result.stdout, /Private property docs/);
  }
});

// --- backfill on the emulator ---

test("TAQ-110 N-1: the backfill registers single-landlord ids and only reports conflicts", async () => {
  await seedMixed();
  const plan = await backfill.classify(db, await backfill.scanPrivateProperties(db));
  assert.equal(plan.privateDocs, 10, "docs outside Users/{uid}/properties are ignored");
  assert.deepEqual(plan.toRegister.map((x) => `${x.property_id}:${x.owner_id}`).sort(), ["solo-a:ownerA", "solo-agency:agency"]);
  assert.deepEqual(plan.multipleOwners, [{ property_id: "shared", owners: ["ownerA", "ownerB"] }]);
  assert.deepEqual(plan.publicOwnerMismatch, [{ property_id: "pub-mismatch", owner_id: "ownerB", public_owner_id: "ownerA" }]);
  assert.deepEqual(plan.nonLandlordOwner, [{ property_id: "tenant-only", owner_id: "tenantT", role: "Tenant" }]);
  assert.deepEqual(plan.registeredToOther, [{ property_id: "other-reg", registered_owner_id: "ownerA", holders: ["ownerB"], review: true }]);
  assert.equal(plan.alreadyRegistered, 2, "a flagged copy beside the registered owner's doc is already handled");

  const before = await registry();
  const dry = run("backfill_property_owners.js", ["--project", projectId]);
  assert.equal(dry.status, 0, dry.stderr);
  assert.match(dry.stdout, new RegExp(`^Target project: ${projectId} \\(dry run: no writes\\)`));
  assert.match(dry.stdout, /To register \(single landlord\): 2/);
  assert.match(dry.stdout, /Under more than one owner .*: 1/);
  assert.match(dry.stdout, /Dry run\. Re-run with --write/);
  assert.deepEqual(await registry(), before, "the default is a dry run");

  const wrote = run("backfill_property_owners.js", ["--project", projectId, "--write"]);
  assert.equal(wrote.status, 0, wrote.stderr);
  assert.match(wrote.stdout, /Registered 2 ids\./);
  assert.deepEqual(await registry(), { ...before, "solo-a": "ownerA", "solo-agency": "agency" });
  assert.equal((await db.doc("PropertyOwners/solo-a").get()).get("claimed_by"), "backfill");
  for (const id of ["shared", "pub-mismatch", "tenant-only"]) {
    assert.equal((await db.doc(`PropertyOwners/${id}`).get()).exists, false, `${id} stays unregistered`);
  }
  assert.equal((await db.doc("Users/ownerB/properties/shared").get()).get("id_conflict"), undefined, "nothing is flagged");
  assert.equal((await db.doc("Users/ownerB/properties/pub-mismatch").get()).exists, true, "nothing is deleted");

  const again = run("backfill_property_owners.js", ["--project", projectId, "--write"]);
  assert.match(again.stdout, /Registered 0 ids\./);
});

test("TAQ-110 N-1: the backfill never overwrites an id registered meanwhile", async () => {
  await user("ownerA", "Owner");
  await db.doc("Users/ownerA/properties/late").set({ title: "x" });
  const plan = await backfill.classify(db, await backfill.scanPrivateProperties(db));
  await db.doc("PropertyOwners/late").set({ owner_id: "someone" });
  assert.deepEqual(await backfill.applyPlan(db, plan), { registered: 0, skipped: ["late"], cursor: "late" });
  assert.equal((await db.doc("PropertyOwners/late").get()).get("owner_id"), "someone");
});

// --- N-3: the read-only production audit ---

test("TAQ-110 N-3: --prod-read-only runs only on the production project and only with AUDIT_PROD_OK naming it", () => {
  const prodProjects = [FAKE_PROD];
  assert.deepEqual(auditScript.parseArgs(["--project", FAKE_PROD, "--prod-read-only"]), { project: FAKE_PROD, prodReadOnly: true });
  assert.equal(auditScript.resolveTarget(FAKE_PROD, { prodReadOnly: true, confirm: FAKE_PROD, prodProjects }), FAKE_PROD);
  assert.throws(() => auditScript.resolveTarget(FAKE_PROD, { prodReadOnly: true, confirm: "", prodProjects }), /AUDIT_PROD_OK/);
  assert.throws(() => auditScript.resolveTarget(FAKE_PROD, { prodReadOnly: true, confirm: "yes", prodProjects }), /AUDIT_PROD_OK/);
  assert.throws(() => auditScript.resolveTarget(FAKE_PROD, { prodReadOnly: true, confirm: `${FAKE_PROD} `, prodProjects }), /AUDIT_PROD_OK/);
  assert.throws(() => auditScript.resolveTarget(FAKE_PROD, { prodProjects }), /runs on demo- projects/, "production needs the read-only flag");
  for (const project of ["tashil-aqar-dev", "demo-x", "other"]) {
    assert.throws(() => auditScript.resolveTarget(project, { prodReadOnly: true, confirm: project, prodProjects }), /only for the production project/);
  }
  assert.throws(() => auditScript.resolveTarget(FAKE_PROD, { prodReadOnly: true, confirm: FAKE_PROD, prodProjects: [] }), /only for the production project/);

  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "rc-"));
  fs.writeFileSync(path.join(dir, ".firebaserc"), JSON.stringify({ projects: { prod: FAKE_PROD, dev: "tashil-aqar-dev" } }));
  assert.deepEqual(auditScript.prodProjectsFromConfig(path.join(dir, ".firebaserc")), [FAKE_PROD]);
  assert.deepEqual(auditScript.prodProjectsFromConfig(path.join(dir, "missing")), []);
});

test("TAQ-110 N-3: the audit CLI refuses a project that is not production in read-only mode, reading nothing", () => {
  for (const [args, env] of [
    [["--project", FAKE_PROD, "--prod-read-only"], { AUDIT_PROD_OK: FAKE_PROD }],
    [["--project", FAKE_PROD], { AUDIT_PROD_OK: FAKE_PROD }],
    [["--project", "tashil-aqar-dev", "--prod-read-only"], { AUDIT_PROD_OK: "tashil-aqar-dev" }],
  ]) {
    const result = run("audit_leases.js", args, { ...NOWHERE, ...env });
    assert.equal(result.status, 1, `${args.join(" ")}: ${result.stdout}${result.stderr}`);
    assert.match(result.stderr, /Refusing project/);
    assert.equal(result.stdout, "");
  }
});

test("TAQ-110 N-3: the read-only wrapper throws on every write method of Firestore and Auth", async () => {
  await user("ownerA", "Owner");
  await db.doc("Users/ownerA/properties/p1").set({ title: "x" });
  await db.doc("Leases/l1").set({ status: "active", owner_id: "ownerA", property_id: "p1" });
  const ro = auditScript.readOnly(db);
  const roAuth = auditScript.readOnly(getAuth());
  const col = ro.collection("Leases");
  const ref = ro.doc("Leases/l1");
  const snap = await col.get();
  const docSnap = await ref.get();
  const group = await ro.collectionGroup("properties").get();
  const viaForEach = [];
  snap.forEach((d) => viaForEach.push(d));
  const reachable = {
    db: ro, collection: col, query: col.where("status", "==", "active"), doc: ref, nested: ro.collection("Users").doc("ownerA").collection("properties").doc("p1"),
    snapRef: snap.docs[0].ref, forEachRef: viaForEach[0].ref, docSnapRef: docSnap.ref, groupRef: group.docs[0].ref,
    parent: ref.parent, refFirestore: ref.firestore, snapQuery: snap.query,
  };
  const writes = ["set", "update", "delete", "create", "add", "batch", "runTransaction", "bulkWriter", "recursiveDelete"];
  for (const [name, target] of Object.entries(reachable)) {
    for (const method of writes) {
      assert.throws(() => target[method]({ x: 1 }), /Read-only audit/, `${name}.${method}`);
    }
  }
  for (const method of ["setCustomUserClaims", "createUser", "updateUser", "deleteUser", "deleteUsers", "importUsers", "revokeRefreshTokens", "createCustomToken", "generatePasswordResetLink", "createSessionCookie"]) {
    assert.throws(() => roAuth[method]("ownerA", {}), /Read-only audit/, `auth.${method}`);
  }
  assert.throws(() => { ro.settings = {}; }, /Read-only audit/);
  assert.throws(() => { delete ref.id; }, /Read-only audit/);

  assert.equal(docSnap.get("status"), "active", "reads still work");
  assert.equal(snap.size, 1);
  assert.equal((await roAuth.getUser("ownerA")).customClaims.role, "Owner");
  assert.deepEqual((await ro.getAll(ro.doc("Leases/l1"))).map((d) => d.id), ["l1"]);
  assert.equal((await db.doc("Leases/l1").get()).get("x"), undefined, "nothing was written");
});

test("TAQ-110 N-3: the audit gives the same report through the wrapper; the production view is counts and ids only", async () => {
  await seedMixed();
  const base = { status: "active", agency_id: "", country_code: "AE", start_date: "2026-01-01", end_date: "2099-12-31", tenant_name: "Secret Tenant", tenant_phone: "+971500000000" };
  await db.doc("Leases/live").set({ ...base, owner_id: "ownerA", tenant_id: "t1", property_id: "solo-a", monthly_rent: 7777 });
  await db.doc("Leases/squat").set({ ...base, owner_id: "ownerB", tenant_id: "t2", property_id: "other-reg", monthly_rent: 8888 });
  await db.doc("PropertyLeaseLocks/solo-a").set({ lease_id: "live", property_id: "solo-a" });
  await db.doc("PropertyLeaseLocks/other-reg").set({ lease_id: "squat", property_id: "other-reg" });

  const raw = await auditScript.audit(db, getAuth());
  const wrapped = await auditScript.audit(auditScript.readOnly(db), auditScript.readOnly(getAuth()));
  assert.deepEqual(JSON.parse(JSON.stringify(wrapped)), JSON.parse(JSON.stringify(raw)));

  assert.deepEqual(raw.idsUnderMultipleOwners.map((x) => x.property_id).sort(), ["flagged-ok", "shared"]);
  assert.deepEqual(raw.publicOwnerMismatch.map((x) => x.property_id), ["pub-mismatch"]);
  assert.deepEqual(raw.unregisteredIds, ["pub-mismatch", "shared", "solo-a", "solo-agency", "tenant-only"]);
  assert.deepEqual(raw.lockOwnerNotRegistered.map((x) => x.property_id), ["other-reg", "solo-a"]);
  assert.deepEqual(raw.rentalStatusAll, { available: 1, rented: 1, "(unset)": 8 });
  assert.deepEqual(raw.rentalStatusLiveLeased, { available: 1, "(unset)": 1 });

  const prod = JSON.stringify(auditScript.idsOnly(raw));
  for (const secret of ["Secret Tenant", "+971500000000", "7777", "8888", "tenant_name", "owner_id", "t1", "t2"]) {
    assert.ok(!prod.includes(secret), `production output leaks ${secret}`);
  }
  const view = auditScript.idsOnly(raw);
  assert.equal(view.leases, 2);
  assert.deepEqual(view.statusCounts, { active: 2 });
  assert.equal(view.locks, 2);
  assert.equal(view.unregisteredIds, 5);
  assert.deepEqual(view.lockOwnerNotRegistered, ["other-reg", "solo-a"]);
  assert.deepEqual(view.rentalStatusAll, raw.rentalStatusAll);
});

// --- TAQ-125: production-capable, guarded backfill ---

/** Runs the CLI function in-process with the console captured. */
async function runMain(argv, env = {}, deps = {}) {
  const out = [];
  const err = [];
  const log = console.log;
  const error = console.error;
  console.log = (...a) => out.push(a.join(" "));
  console.error = (...a) => err.push(a.join(" "));
  try {
    const code = await backfill.main(argv, env, { db, prodProjects: [FAKE_PROD], ...deps });
    return { code, out: out.join("\n"), err: err.join("\n") };
  } finally {
    console.log = log;
    console.error = error;
  }
}

const jsonReport = (out) => JSON.parse(out.slice(out.indexOf("JSON report:") + "JSON report:".length, out.lastIndexOf("}") + 1));

/** The production audit's shape: 4 owners, 8 ids, 6 under both the agency admin and the super admin. */
async function seedProdLike() {
  // No Firebase Auth users at all: the backfill must not need Auth.
  const profile = (uid, role) => db.doc(`Users/${uid}`).set({ role });
  await Promise.all([profile("ownerA", "Owner"), profile("ownerB", "Owner"), profile("agency", "AgencyAdmin"), profile("root", "SuperAdmin")]);
  const shared = ["prop-ae-101", "prop-ae-102", "prop-eg-101", "prop-eg-102", "prop-eg-103", "prop-eg-104"];
  for (const id of shared) {
    await db.doc(`Users/agency/properties/${id}`).set({ id, title: "seed" });
    await db.doc(`Users/root/properties/${id}`).set({ id, title: "seed" });
  }
  await db.doc("Users/ownerA/properties/pub-a").set({ id: "pub-a", title: "A", rentalStatus: "available" });
  await db.doc("Users/ownerB/properties/pub-b").set({ id: "pub-b", title: "B" });
  await db.doc("Properties/pub-a").set({ owner_id: "ownerA", is_published: true });
  await db.doc("Properties/pub-b").set({ owner_id: "ownerB", is_published: true });
  return shared;
}

test("TAQ-125: production needs --prod, BACKFILL_PROD_OK equal to the project id, and --write to write", async () => {
  const prodProjects = [FAKE_PROD];
  assert.equal(backfill.resolveTarget(FAKE_PROD, { prod: true, confirm: FAKE_PROD, prodProjects }), FAKE_PROD);
  assert.throws(() => backfill.resolveTarget(FAKE_PROD, { prodProjects }), /Pass --prod/);
  assert.throws(() => backfill.resolveTarget(FAKE_PROD, { prod: true, prodProjects }), /BACKFILL_PROD_OK/);
  for (const confirm of ["yes", "true", `${FAKE_PROD} `, FAKE_PROD.toUpperCase(), "demo-x"]) {
    assert.throws(() => backfill.resolveTarget(FAKE_PROD, { prod: true, confirm, prodProjects }), /BACKFILL_PROD_OK/, confirm);
  }
  for (const project of ["tashil-aqar-dev", "demo-x", "other"]) {
    assert.throws(() => backfill.resolveTarget(project, { prod: true, confirm: project, prodProjects }), /only for the production project/, project);
  }
  assert.throws(() => backfill.resolveTarget(FAKE_PROD, { prod: true, confirm: FAKE_PROD, prodProjects: [] }), /only for the production project/);
  assert.equal(backfill.resolveTarget("demo-x", { prodProjects }), "demo-x");

  const base = ["--project", FAKE_PROD];
  for (const [argv, env, expected] of [
    [base, {}, /Pass --prod/],
    [[...base, "--write"], {}, /Pass --prod/],
    [[...base, "--prod"], {}, /BACKFILL_PROD_OK/],
    [[...base, "--prod", "--write"], { BACKFILL_PROD_OK: "other" }, /BACKFILL_PROD_OK/],
    [["--project", "demo-x", "--prod"], { BACKFILL_PROD_OK: "demo-x" }, /only for the production project/],
  ]) {
    await seedProdLike();
    const before = await registry();
    const r = await runMain(argv, env);
    assert.equal(r.code, 2, `${argv.join(" ")}: ${r.err}`);
    assert.match(r.out, new RegExp(`^Target project: ${argv[1]} `), "the target is printed first");
    assert.match(r.err, expected);
    assert.doesNotMatch(r.out, /Private property docs/, "nothing is read when refused");
    assert.deepEqual(await registry(), before);
  }
});

test("TAQ-125: the prod CLI refuses without the flags or env before reading (real process, fake id)", () => {
  // .firebaserc names the real prod id, so the fake id is not production there: it is refused outright.
  for (const [args, env] of [[["--project", FAKE_PROD, "--prod"], { BACKFILL_PROD_OK: FAKE_PROD }], [["--project", FAKE_PROD, "--prod", "--write"], {}]]) {
    const result = run("backfill_property_owners.js", args, { ...NOWHERE, ...env });
    assert.equal(result.status, 2, result.stderr);
    assert.match(result.stdout, new RegExp(`^Target project: ${FAKE_PROD} \\(PROD, `));
    assert.match(result.stderr, /Refusing to run against/);
  }
});

test("TAQ-125: the prod dry run lists the 6 shared seed ids as multi-owner conflicts and writes nothing", async () => {
  const shared = await seedProdLike();
  const before = JSON.stringify(await registry());
  const r = await runMain(["--project", FAKE_PROD, "--prod"], { BACKFILL_PROD_OK: FAKE_PROD });
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, new RegExp(`^Target project: ${FAKE_PROD} \\(PROD, dry run: no writes\\)`));
  assert.match(r.out, /Dry run\. Re-run with --write/);
  assert.doesNotMatch(r.out, /Batch done/);
  const report = jsonReport(r.out);
  assert.equal(report.mode, "dry-run");
  assert.deepEqual(report.counts, {
    privateDocs: 14, ids: 8, alreadyRegistered: 0, toRegister: 2, multipleOwners: 6, publicOwnerMismatch: 0,
    nonLandlordOwner: 0, registeredToOther: 0, registeredToHolder: 0, idConflictCandidates: 12, overridden: 0, idFieldIssues: 0,
    flaggedHolders: 0, nonLandlordHolders: 0, holdersWithoutProfile: 0,
  });
  assert.deepEqual(report.multipleOwners.map((x) => x.property_id), [...shared].sort());
  for (const m of report.multipleOwners) assert.deepEqual(m.owners, ["agency", "root"]);
  assert.deepEqual(report.toRegister.map((x) => `${x.property_id}:${x.owner_id}`), ["pub-a:ownerA", "pub-b:ownerB"]);
  assert.equal(report.idConflictCandidates.filter((c) => c.reason === "multiple_owners").length, 12);
  assert.equal(JSON.stringify(await registry()), before, "a dry run writes nothing");
  assert.equal((await db.collection("AdminAlerts").get()).size, 0);
});

test("TAQ-125: --write registers the single-owner and public ids and never assigns the multi-owner ones", async () => {
  const shared = await seedProdLike();
  const argv = ["--project", FAKE_PROD, "--prod", "--write"];
  const env = { BACKFILL_PROD_OK: FAKE_PROD };
  const r = await runMain(argv, env);
  assert.equal(r.code, 0, r.err);
  assert.match(r.out, new RegExp(`^Target project: ${FAKE_PROD} \\(PROD, WRITE`));
  assert.match(r.out, /Registered 2 ids\./);
  assert.match(r.out, /Last cursor: pub-b/);
  assert.deepEqual(await registry(), { "pub-a": "ownerA", "pub-b": "ownerB" });
  for (const id of shared) assert.equal((await db.doc(`PropertyOwners/${id}`).get()).exists, false, id);
  assert.equal((await db.doc("Users/root/properties/prop-ae-101").get()).get("id_conflict"), undefined, "nothing is flagged");
  assert.equal((await db.collection("AdminAlerts").get()).size, 0);
  const docs = (await db.collectionGroup("properties").get()).size;
  assert.equal(docs, 14, "nothing is deleted");

  const again = await runMain(argv, env);
  assert.match(again.out, /Registered 0 ids\./, "idempotent");
  assert.deepEqual(await registry(), { "pub-a": "ownerA", "pub-b": "ownerB" });
});

test("TAQ-125: an explicit per-id override resolves a shared id; bad entries are refused before any write", async () => {
  await seedProdLike();
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ov-"));
  const file = (data) => {
    const f = path.join(dir, `o-${Math.random()}.json`);
    fs.writeFileSync(f, JSON.stringify(data));
    return f;
  };
  const argv = (f) => ["--project", FAKE_PROD, "--prod", "--write", "--overrides", f];
  const env = { BACKFILL_PROD_OK: FAKE_PROD };

  for (const [bad, expected] of [
    [{ "prop-ae-101": "ownerA" }, /does not hold that id/],
    [{ "pub-a": "ownerA" }, /not held by more than one owner/],
    [{ "no-such-id": "agency" }, /not held by more than one owner/],
    [["x"], /JSON object/],
    [{ "prop-ae-101": "" }, /Invalid override/],
  ]) {
    const r = await runMain(argv(file(bad)), env);
    assert.equal(r.code, 2, JSON.stringify(bad));
    assert.match(r.err, expected);
    assert.deepEqual(await registry(), {}, "a refused override file writes nothing");
  }

  const f = file({ "prop-ae-101": "agency", "prop-eg-104": "root" });
  const dry = await runMain(["--project", FAKE_PROD, "--prod", "--overrides", f], env);
  const report = jsonReport(dry.out);
  assert.equal(report.counts.overridden, 2);
  assert.equal(report.counts.multipleOwners, 4, "the other 4 stay unresolved");
  assert.deepEqual(await registry(), {}, "the dry run still writes nothing");

  const wrote = await runMain(argv(f), env);
  assert.equal(wrote.code, 0, wrote.err);
  assert.deepEqual(await registry(), { "pub-a": "ownerA", "pub-b": "ownerB", "prop-ae-101": "agency", "prop-eg-104": "root" });
  assert.equal((await db.doc("PropertyOwners/prop-ae-101").get()).get("claimed_by"), "backfill-override");
  assert.equal((await db.doc("PropertyOwners/pub-a").get()).get("claimed_by"), "backfill");
  assert.equal((await db.doc("PropertyOwners/prop-eg-101").get()).exists, false);
});

test("TAQ-125: an override is refused when the public listing belongs to another holder", async () => {
  await seedProdLike();
  await db.doc("Properties/prop-ae-102").set({ owner_id: "root" });
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ov-"));
  const f = path.join(dir, "o.json");
  fs.writeFileSync(f, JSON.stringify({ "prop-ae-102": "agency" }));
  const r = await runMain(["--project", FAKE_PROD, "--prod", "--write", "--overrides", f], { BACKFILL_PROD_OK: FAKE_PROD });
  assert.equal(r.code, 2);
  assert.match(r.err, /public listing belongs to "root"/);
  assert.deepEqual(await registry(), {});
});

test("TAQ-125: the backfill needs no Firebase Auth and tenants and investors never get an id", async () => {
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await db.doc("Users/inv").set({ role: "Investor" });
  await db.doc("Users/ownerA").set({ role: "Owner" });
  for (const [uid, id] of [["tenantT", "t-1"], ["inv", "i-1"], ["ownerA", "o-1"]]) await db.doc(`Users/${uid}/properties/${id}`).set({ id });
  const r = await runMain(["--project", "demo-x", "--write"], {}, { prodProjects: [] });
  assert.equal(r.code, 0, r.err);
  assert.deepEqual(await registry(), { "o-1": "ownerA" });
  assert.deepEqual(jsonReport(r.out).nonLandlordOwner.map((x) => x.role).sort(), ["Investor", "Tenant"]);
  assert.equal((await getAuth().listUsers()).users.length, 0, "no Auth user was needed");
});

test("TAQ-125: registeredToOther rows are marked for review and listed as id_conflict candidates", async () => {
  await seedMixed();
  const r = await runMain(["--project", "demo-x"], {}, { prodProjects: [] });
  const report = jsonReport(r.out);
  assert.deepEqual(report.registeredToOther, [{ property_id: "other-reg", registered_owner_id: "ownerA", holders: ["ownerB"], review: true }]);
  assert.match(r.out, /REVIEW; left as is\): 1/);
  assert.ok(report.idConflictCandidates.some((c) => c.property_id === "other-reg" && c.owner_id === "ownerB" && c.reason === "registered_to_other"));
  assert.ok(report.idConflictCandidates.some((c) => c.property_id === "pub-mismatch" && c.reason === "public_owner_mismatch"));
  assert.equal(report.idConflictCandidates.filter((c) => c.property_id === "shared").length, 2);
});

test("TAQ-125: writes go in batches with a cursor, resume after a failure, and skip ids that changed meanwhile", async () => {
  await user("ownerA", "Owner");
  const ids = ["b1", "b2", "b3", "b4", "b5"];
  for (const id of ids) await db.doc(`Users/ownerA/properties/${id}`).set({ id });
  const plan = await backfill.classify(db, await backfill.scanPrivateProperties(db, { pageSize: 2 }));
  assert.equal(plan.ids, 5, "paged scan sees every doc");

  const batches = [];
  const first = await backfill.applyPlan(db, plan, { batchSize: 2, onBatch: (b) => batches.push(b.cursor) });
  assert.deepEqual(batches, ["b2", "b4", "b5"]);
  assert.equal(first.registered, 5);

  await clearAll();
  await user("ownerA", "Owner");
  for (const id of ids) await db.doc(`Users/ownerA/properties/${id}`).set({ id });
  let calls = 0;
  const flaky = new Proxy(db, {
    get(target, prop) {
      if (prop === "runTransaction") {
        return (fn) => {
          calls += 1;
          if (calls === 2) return Promise.reject(new Error("deadline exceeded"));
          return target.runTransaction(fn);
        };
      }
      const v = target[prop];
      return typeof v === "function" ? v.bind(target) : v;
    },
  });
  await assert.rejects(backfill.applyPlan(flaky, plan, { batchSize: 2 }), (err) => {
    assert.equal(err.cursor, "b2", "the cursor is the last finished batch");
    return true;
  });
  assert.deepEqual(Object.keys(await registry()).sort(), ["b1", "b2"]);

  await db.doc("PropertyOwners/b4").set({ owner_id: "someone" });
  await db.doc("Users/ownerA/properties/b5").delete();
  const resumed = await backfill.applyPlan(db, plan, { batchSize: 2, cursor: "b2" });
  assert.deepEqual(resumed.skipped.sort(), ["b4", "b5"], "registered meanwhile, or the private doc is gone");
  assert.equal(resumed.registered, 1);
  assert.deepEqual(await registry(), { b1: "ownerA", b2: "ownerA", b3: "ownerA", b4: "someone" });
});

// --- TAQ-128: private docs without a matching `id` field ---

test("TAQ-128: the dry run lists private docs with a missing or mismatched id field", async () => {
  await db.doc("Users/ownerA").set({ role: "Owner" });
  await db.doc("Users/ownerB").set({ role: "Owner" });
  await db.doc("Users/ownerA/properties/no-id").set({ title: "legacy" });
  await db.doc("Users/ownerB/properties/wrong-id").set({ id: "something-else", title: "legacy" });
  await db.doc("Users/ownerB/properties/null-id").set({ id: null, title: "legacy" });
  await db.doc("Users/ownerA/properties/good").set({ id: "good" });
  const r = await runMain(["--project", "demo-x"], {}, { prodProjects: [] });
  assert.equal(r.code, 0, r.err);
  const report = jsonReport(r.out);
  assert.equal(report.counts.idFieldIssues, 3);
  assert.deepEqual(report.idFieldIssues, [
    { property_id: "no-id", owner_id: "ownerA", id_field: "missing" },
    { property_id: "null-id", owner_id: "ownerB", id_field: "missing" },
    { property_id: "wrong-id", owner_id: "ownerB", id_field: "mismatch" },
  ]);
  assert.match(r.out, /missing or mismatched id field .*: 3/);
  assert.match(r.out, /run with --fix-id-fields --write, then dry-run again/);
  assert.deepEqual(await registry(), {}, "a dry run writes nothing");
  assert.equal((await db.doc("Users/ownerA/properties/no-id").get()).get("id"), undefined);
});

test("TAQ-128: --write refuses to register while id field issues remain; --fix-id-fields --write fixes only the id", async () => {
  await db.doc("Users/ownerA").set({ role: "Owner" });
  await db.doc("Users/ownerA/properties/no-id").set({ title: "legacy", rentalStatus: "available" });
  await db.doc("Users/ownerA/properties/good").set({ id: "good" });
  const env = { BACKFILL_PROD_OK: FAKE_PROD };

  const refused = await runMain(["--project", FAKE_PROD, "--prod", "--write"], env);
  assert.equal(refused.code, 2);
  assert.match(refused.err, /Refusing to register: 1 private docs have a missing or mismatched id field/);
  assert.deepEqual(await registry(), {}, "nothing is registered, not even the clean id");

  const fixed = await runMain(["--project", FAKE_PROD, "--prod", "--fix-id-fields", "--write"], env);
  assert.equal(fixed.code, 0, fixed.err);
  assert.match(fixed.out, /^Target project: qa-fake-prod-xyz \(PROD, WRITE: will fix id fields only\)/);
  assert.match(fixed.out, /Fixed the id field on 1 private docs\./);
  assert.deepEqual(await registry(), {}, "fixing registers nothing");
  assert.deepEqual((await db.doc("Users/ownerA/properties/no-id").get()).data(), { id: "no-id", title: "legacy", rentalStatus: "available" });

  const dry = await runMain(["--project", FAKE_PROD, "--prod"], env);
  assert.equal(jsonReport(dry.out).counts.idFieldIssues, 0);
  const again = await runMain(["--project", FAKE_PROD, "--prod", "--fix-id-fields", "--write"], env);
  assert.match(again.out, /Fixed the id field on 0 private docs\./, "idempotent");

  const wrote = await runMain(["--project", FAKE_PROD, "--prod", "--write"], env);
  assert.equal(wrote.code, 0, wrote.err);
  assert.deepEqual(await registry(), { good: "ownerA", "no-id": "ownerA" });
});

test("TAQ-128: fixing skips docs deleted or fixed meanwhile and never touches other fields", async () => {
  await db.doc("Users/ownerA").set({ role: "Owner" });
  for (const id of ["a1", "a2", "a3"]) await db.doc(`Users/ownerA/properties/${id}`).set({ title: id });
  const plan = await backfill.classify(db, await backfill.scanPrivateProperties(db));
  assert.equal(plan.idFieldIssues.length, 3);
  await db.doc("Users/ownerA/properties/a2").delete();
  await db.doc("Users/ownerA/properties/a3").update({ id: "a3" });
  const batches = [];
  const result = await backfill.fixIdFields(db, plan, { batchSize: 2, onBatch: (b) => batches.push(b) });
  assert.deepEqual(result, { fixed: 1, skipped: ["ownerA/a2", "ownerA/a3"] });
  assert.equal(batches.length, 2);
  assert.equal((await db.doc("Users/ownerA/properties/a2").get()).exists, false, "a deleted doc is not re-created");
  assert.deepEqual((await db.doc("Users/ownerA/properties/a1").get()).data(), { title: "a1", id: "a1" });
});

// --- TAQ-129: who counts as a holder, override validation, report labels ---

test("TAQ-129: a flagged squatter doc does not count as a holder; the real owner is registered without an override", async () => {
  await db.doc("Users/victim").set({ role: "Owner" });
  await db.doc("Users/squatter").set({ role: "Owner" });
  await db.doc("Users/victim/properties/legacy-1").set({ id: "legacy-1" });
  await db.doc("Users/squatter/properties/legacy-1").set({ id: "legacy-1", id_conflict: true });
  const r = await runMain(["--project", "demo-x", "--write"], {}, { prodProjects: [] });
  assert.equal(r.code, 0, r.err);
  const report = jsonReport(r.out);
  assert.equal(report.counts.multipleOwners, 0);
  assert.deepEqual(report.flaggedHolders, [{ property_id: "legacy-1", owner_id: "squatter" }]);
  assert.match(r.out, /Ignored holders: docs flagged id_conflict .*: 1/);
  assert.deepEqual(await registry(), { "legacy-1": "victim" });
});

test("TAQ-129: a Tenant's or Investor's stray doc does not block the landlord; an id only they hold stays unregistered", async () => {
  await db.doc("Users/ownerA").set({ role: "Owner" });
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await db.doc("Users/inv").set({ role: "Investor" });
  for (const [uid, id] of [["ownerA", "home-1"], ["tenantT", "home-1"], ["inv", "home-1"], ["tenantT", "t-only"]]) {
    await db.doc(`Users/${uid}/properties/${id}`).set({ id });
  }
  const r = await runMain(["--project", "demo-x", "--write"], {}, { prodProjects: [] });
  assert.equal(r.code, 0, r.err);
  const report = jsonReport(r.out);
  assert.deepEqual(await registry(), { "home-1": "ownerA" });
  assert.deepEqual(report.nonLandlordHolders, [
    { property_id: "home-1", owner_id: "inv", role: "Investor" },
    { property_id: "home-1", owner_id: "tenantT", role: "Tenant" },
  ]);
  assert.deepEqual(report.nonLandlordOwner, [{ property_id: "t-only", owner_id: "tenantT", role: "Tenant" }]);
  assert.equal(report.idConflictCandidates.some((c) => c.owner_id === "tenantT" || c.owner_id === "inv"), false);
});

test("TAQ-129: an override naming a Tenant, an Investor or a flagged doc is refused before any write", async () => {
  await seedProdLike();
  await db.doc("Users/tenantT").set({ role: "Tenant" });
  await db.doc("Users/inv").set({ role: "Investor" });
  await db.doc("Users/squatter").set({ role: "Owner" });
  await db.doc("Users/tenantT/properties/prop-ae-101").set({ id: "prop-ae-101" });
  await db.doc("Users/inv/properties/prop-ae-102").set({ id: "prop-ae-102" });
  await db.doc("Users/squatter/properties/prop-eg-101").set({ id: "prop-eg-101", id_conflict: true });
  await db.doc("Users/tenantT/properties/pub-a").set({ id: "pub-a" });
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ov-"));
  const env = { BACKFILL_PROD_OK: FAKE_PROD };
  for (const [bad, expected] of [
    [{ "prop-ae-101": "tenantT" }, /"tenantT" is a Tenant; only a landlord/],
    [{ "prop-ae-102": "inv" }, /"inv" is an Investor; only a landlord/],
    [{ "prop-eg-101": "squatter" }, /"squatter" is flagged id_conflict/],
    [{ "pub-a": "ownerA" }, /not held by more than one owner \(id_conflict docs and Tenant or Investor holders do not count\)/],
  ]) {
    const f = path.join(dir, `o-${Math.random()}.json`);
    fs.writeFileSync(f, JSON.stringify(bad));
    const r = await runMain(["--project", FAKE_PROD, "--prod", "--write", "--overrides", f], env);
    assert.equal(r.code, 2, JSON.stringify(bad));
    assert.match(r.err, expected);
    assert.deepEqual(await registry(), {}, "a refused override file writes nothing");
  }
});

test("TAQ-129: after overrides the shared ids are reported as registered to a holder, not REVIEW", async () => {
  const shared = await seedProdLike();
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ov-"));
  const f = path.join(dir, "o.json");
  fs.writeFileSync(f, JSON.stringify(Object.fromEntries(shared.map((id) => [id, "agency"]))));
  const env = { BACKFILL_PROD_OK: FAKE_PROD };
  const wrote = await runMain(["--project", FAKE_PROD, "--prod", "--write", "--overrides", f], env);
  assert.equal(wrote.code, 0, wrote.err);

  await db.doc("Users/ownerB/properties/pub-a").set({ id: "pub-a" });
  await db.doc("Users/ownerB/properties/stray-reg").set({ id: "stray-reg" });
  await db.doc("PropertyOwners/stray-reg").set({ owner_id: "ownerA", claimed_by: "create" });
  const after = await runMain(["--project", FAKE_PROD, "--prod"], env);
  const report = jsonReport(after.out);
  assert.equal(report.counts.registeredToHolder, 7);
  assert.deepEqual(report.registeredToHolder.filter((x) => shared.includes(x.property_id)).map((x) => [x.registered_owner_id, x.claimed_by, x.other_holders]),
    shared.map(() => ["agency", "backfill-override", ["root"]]));
  assert.deepEqual(report.registeredToHolder.find((x) => x.property_id === "pub-a"), {
    property_id: "pub-a", registered_owner_id: "ownerA", claimed_by: "backfill", other_holders: ["ownerB"],
  });
  assert.deepEqual(report.registeredToOther, [{ property_id: "stray-reg", registered_owner_id: "ownerA", holders: ["ownerB"], review: true }]);
  assert.match(after.out, /Registered to one of several holders, e\.g\. by an override .*: 7/);
  assert.match(after.out, /Registered to someone who is not a landlord holder \(REVIEW; left as is\): 1/);
  assert.equal(report.idConflictCandidates.filter((c) => c.reason === "registered_to_other_holder").length, 7);
});

test("TAQ-129: a holder without a Users profile still counts as a landlord and is listed", async () => {
  await db.doc("Users/ownerA").set({ role: "Owner" });
  await db.doc("Users/ownerA/properties/p-shared").set({ id: "p-shared" });
  await db.doc("Users/claimsOnly/properties/p-shared").set({ id: "p-shared" });
  await db.doc("Users/claimsOnly/properties/p-solo").set({ id: "p-solo" });
  const r = await runMain(["--project", "demo-x"], {}, { prodProjects: [] });
  const report = jsonReport(r.out);
  assert.deepEqual(report.multipleOwners, [{ property_id: "p-shared", owners: ["claimsOnly", "ownerA"] }], "dropping it would hand the id to ownerA");
  assert.deepEqual(report.toRegister, [{ property_id: "p-solo", owner_id: "claimsOnly" }]);
  assert.deepEqual(report.holdersWithoutProfile, [{ property_id: "p-shared", owner_id: "claimsOnly" }, { property_id: "p-solo", owner_id: "claimsOnly" }]);
});

test("TAQ-137: an override naming a holder without a Users profile is refused unless that uid is confirmed", async () => {
  await db.doc("Users/ownerA").set({ role: "Owner" });
  await db.doc("Users/ownerA/properties/p-shared").set({ id: "p-shared" });
  await db.doc("Users/anon1/properties/p-shared").set({ id: "p-shared" });
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ov-"));
  const file = path.join(dir, "o.json");
  const write = (data) => fs.writeFileSync(file, JSON.stringify(data));

  write({ "p-shared": "anon1" });
  const refused = await runMain(["--project", "demo-x", "--write", "--overrides", file], {}, { prodProjects: [] });
  assert.equal(refused.code, 2);
  assert.match(refused.err, /no Users profile/);
  assert.match(refused.err, /--confirm-no-profile-owner anon1/);
  assert.deepEqual(await registry(), {}, "a refused override writes nothing");

  const wrongUid = await runMain(["--project", "demo-x", "--write", "--overrides", file, "--confirm-no-profile-owner", "someoneElse"], {}, { prodProjects: [] });
  assert.equal(wrongUid.code, 2);
  assert.deepEqual(await registry(), {});

  write({ "p-shared": "ownerA" });
  const profiled = await runMain(["--project", "demo-x", "--write", "--overrides", file], {}, { prodProjects: [] });
  assert.equal(profiled.code, 0, profiled.err);
  assert.equal((await db.doc("PropertyOwners/p-shared").get()).get("owner_id"), "ownerA", "a holder with a profile needs no confirmation");
});

test("TAQ-137: with the uid confirmed, the override to a no-profile holder goes through", async () => {
  await db.doc("Users/ownerA").set({ role: "Owner" });
  await db.doc("Users/ownerA/properties/p-shared").set({ id: "p-shared" });
  await db.doc("Users/anon1/properties/p-shared").set({ id: "p-shared" });
  const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "ov-")), "o.json");
  fs.writeFileSync(file, JSON.stringify({ "p-shared": "anon1" }));
  const r = await runMain(["--project", "demo-x", "--write", "--overrides", file, "--confirm-no-profile-owner", "anon1"], {}, { prodProjects: [] });
  assert.equal(r.code, 0, r.err);
  assert.equal((await db.doc("PropertyOwners/p-shared").get()).get("owner_id"), "anon1");
});
