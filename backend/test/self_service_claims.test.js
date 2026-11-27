// TAQ-23: self-service roles reach the custom claim, so the rules skip the Users/{uid} read.
// TAQ-27: a written, guarded way to make the first SuperAdmin.
const test = require("node:test");
const assert = require("node:assert/strict");
const { getAuth } = require("firebase-admin/auth");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");
const { grantSelfServiceClaim } = require("../self_service_claims");
const { parseArgs, backfillSelfService, bootstrapSuperAdmin } = require("../scripts/role_claims");

const auth = getAuth();
const projectId = process.env.GCLOUD_PROJECT;

test.beforeEach(async () => {
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: "DELETE" });
});

const snap = (data) => ({ exists: data !== null, get: (k) => (data ? data[k] : undefined), data: () => data });
const event = (uid, before, after) => ({ params: { uid }, data: { before: snap(before), after: snap(after) } });

test("TAQ-23: a self-service role is mirrored into the claim, keeping other claims", async () => {
  await auth.createUser({ uid: "u-owner" });
  await auth.setCustomUserClaims("u-owner", { beta: true });
  assert.equal(await grantSelfServiceClaim("u-owner", "Owner", auth), "granted");
  assert.deepEqual((await auth.getUser("u-owner")).customClaims, { beta: true, role: "Owner" });
});

test("TAQ-23: an existing role claim, an elevated role or a missing user is left alone", async () => {
  await auth.createUser({ uid: "u-agency" });
  await auth.setCustomUserClaims("u-agency", { role: "AgencyAdmin", agency_id: "a1" });
  assert.equal(await grantSelfServiceClaim("u-agency", "Owner", auth), "has_claim");
  assert.deepEqual((await auth.getUser("u-agency")).customClaims, { role: "AgencyAdmin", agency_id: "a1" });
  await auth.createUser({ uid: "u-plain" });
  for (const role of ["SuperAdmin", "Admin", "AgencyAdmin", "", undefined, "owner"]) {
    assert.equal(await grantSelfServiceClaim("u-plain", role, auth), "not_self_service", String(role));
  }
  assert.equal((await auth.getUser("u-plain")).customClaims, undefined);
  assert.equal(await grantSelfServiceClaim("nobody", "Tenant", auth), "no_user");
});

test("TAQ-23: the trigger acts only when the profile role changes, and never revokes the session", async () => {
  const created = await auth.createUser({ uid: "u-t" });
  await fns.mirrorSelfServiceRole.run(event("u-t", { full_name: "x" }, { full_name: "y" }));
  assert.equal((await auth.getUser("u-t")).customClaims, undefined, "no role, no claim");
  await fns.mirrorSelfServiceRole.run(event("u-t", { full_name: "y" }, { full_name: "y", role: "Tenant" }));
  const after = await auth.getUser("u-t");
  assert.deepEqual(after.customClaims, { role: "Tenant" });
  assert.equal(after.tokensValidAfterTime, created.tokensValidAfterTime, "refresh tokens are not revoked");
  await fns.mirrorSelfServiceRole.run(event("u-t", null, { role: "SuperAdmin" }));
  assert.deepEqual((await auth.getUser("u-t")).customClaims, { role: "Tenant" });
});

function fakeDb(profiles) {
  return {
    collection: () => ({
      get: async () => ({
        size: profiles.length,
        docs: profiles.map(([id, role]) => ({ id, get: (k) => (k === "role" ? role : undefined) })),
      }),
    }),
  };
}

test("TAQ-23: the backfill dry run counts, --apply writes, and claimed or elevated users are skipped", async () => {
  await auth.createUser({ uid: "b1" });
  await auth.createUser({ uid: "b2" });
  await auth.createUser({ uid: "b3" });
  await auth.setCustomUserClaims("b3", { role: "AgencyAdmin", agency_id: "a" });
  await auth.createUser({ uid: "b4" });
  const db = fakeDb([["b1", "Owner"], ["b2", "Investor"], ["b3", "Owner"], ["b4", "SuperAdmin"], ["gone", "Tenant"]]);
  const lines = [];
  assert.equal(await backfillSelfService(db, auth, false, (l) => lines.push(l)), 2);
  assert.equal((await auth.getUser("b1")).customClaims, undefined, "dry run writes nothing");
  assert.match(lines.join("\n"), /Dry run/);
  assert.equal(await backfillSelfService(db, auth, true, () => {}), 2);
  assert.deepEqual((await auth.getUser("b1")).customClaims, { role: "Owner" });
  assert.deepEqual((await auth.getUser("b2")).customClaims, { role: "Investor" });
  assert.deepEqual((await auth.getUser("b3")).customClaims, { role: "AgencyAdmin", agency_id: "a" });
  assert.equal((await auth.getUser("b4")).customClaims, undefined, "an elevated profile role is never granted");
  assert.equal(await backfillSelfService(db, auth, true, () => {}), 0, "running it again changes nothing");
});

test("TAQ-27: the first SuperAdmin is a dry run by default and refused once one exists", async () => {
  await auth.createUser({ uid: "first", email: "first@example.test" });
  const applied = [];
  const applyRole = async (args) => {
    applied.push(args);
    await auth.setCustomUserClaims(args.uid, { role: args.role });
  };
  assert.equal(await bootstrapSuperAdmin(auth, "first", false, { applyRole, log: () => {} }), false);
  assert.equal(applied.length, 0);
  assert.equal(await bootstrapSuperAdmin(auth, "first", true, { applyRole, log: () => {} }), true);
  assert.deepEqual(applied.map((a) => [a.uid, a.role]), [["first", "SuperAdmin"]]);
  await auth.createUser({ uid: "second" });
  await assert.rejects(bootstrapSuperAdmin(auth, "second", true, { applyRole, log: () => {} }), /already exists/);
  assert.equal(applied.length, 1);
});

test("TAQ-27: role_claims.js takes one mode at a time and needs a uid to bootstrap", () => {
  assert.throws(() => parseArgs(["--backfill-self-service"]), /--project/);
  assert.throws(() => parseArgs(["--project", "p", "--bootstrap-superadmin"]), /needs a uid/);
  assert.throws(() => parseArgs(["--project", "p", "--backfill-self-service", "--grant", "u"]), /one of/);
  assert.deepEqual(parseArgs(["--project", "p", "--bootstrap-superadmin", "u1", "--apply"]), {
    project: "p", grant: [], apply: true, backfillSelfService: false, bootstrapSuperAdmin: "u1", requireMfa: "", clearMfa: "",
  });
});
