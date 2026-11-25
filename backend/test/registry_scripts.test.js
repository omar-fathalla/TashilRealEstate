// TAQ-110 N-1 / N-3: the registry backfill (dev and demo only, dry run by default, conflicts are
// report-only) and the lease audit's read-only production mode. Guard tests use the fake id
// qa-fake-prod-xyz; the real production id is never passed to either script here.
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const backfill = require("../scripts/backfill_property_owners");
const auditScript = require("../scripts/audit_leases");

const projectId = process.env.GCLOUD_PROJECT;
if (!admin.apps.length) admin.initializeApp({ projectId });
const db = admin.firestore();
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
  await admin.auth().createUser({ uid });
  await admin.auth().setCustomUserClaims(uid, { role });
}

test.beforeEach(clearAll);

const registry = async () => Object.fromEntries((await db.collection("PropertyOwners").get()).docs.map((d) => [d.id, d.get("owner_id")]));

/** One of each case the backfill sorts ids into. */
async function seedMixed() {
  await user("ownerA", "Owner");
  await user("ownerB", "Owner");
  await user("agency", "AgencyAdmin");
  await user("tenantT", "Tenant");
  const set = (p, data) => db.doc(p).set(data);
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
  assert.deepEqual(backfill.parseArgs(["--project", "demo-x"]), { project: "demo-x", write: false });
  assert.deepEqual(backfill.parseArgs(["--project=demo-x", "--write"]), { project: "demo-x", write: true });
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
  const plan = await backfill.classify(db, admin.auth(), await backfill.scanPrivateProperties(db));
  assert.equal(plan.privateDocs, 10, "docs outside Users/{uid}/properties are ignored");
  assert.deepEqual(plan.toRegister.map((x) => `${x.property_id}:${x.owner_id}`).sort(), ["solo-a:ownerA", "solo-agency:agency"]);
  assert.deepEqual(plan.multipleOwners, [{ property_id: "shared", owners: ["ownerA", "ownerB"] }]);
  assert.deepEqual(plan.publicOwnerMismatch, [{ property_id: "pub-mismatch", owner_id: "ownerB", public_owner_id: "ownerA" }]);
  assert.deepEqual(plan.nonLandlordOwner, [{ property_id: "tenant-only", owner_id: "tenantT", role: "Tenant" }]);
  assert.deepEqual(plan.registeredToOther, [{ property_id: "other-reg", registered_owner_id: "ownerA", holders: ["ownerB"] }]);
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
  const plan = await backfill.classify(db, admin.auth(), await backfill.scanPrivateProperties(db));
  await db.doc("PropertyOwners/late").set({ owner_id: "someone" });
  assert.deepEqual(await backfill.applyPlan(db, plan), { registered: 0, skipped: ["late"] });
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
  const roAuth = auditScript.readOnly(admin.auth());
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

  const raw = await auditScript.audit(db, admin.auth());
  const wrapped = await auditScript.audit(auditScript.readOnly(db), auditScript.readOnly(admin.auth()));
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
