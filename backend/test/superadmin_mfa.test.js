// TAQ-25: an off-by-default, per-account switch that makes a SuperAdmin's rules and callables
// require a second factor. role_claims.js --require-mfa sets it, only after enrolment.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc } = require("firebase/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the emulators are attached.");
}
if (!admin.apps.length) admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });

const { requireRole, resolveRole, resolveUserAuthority, missingSecondFactor } = require("../authz");
const { setMfaRequired, parseArgs } = require("../scripts/role_claims");

const projectId = process.env.GCLOUD_PROJECT || "demo-tashil-test";
let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
    storage: { rules: fs.readFileSync(path.join(__dirname, "../../storage.rules"), "utf8") },
  });
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "Users/someone"), { role: "Owner", email: "s@example.test" });
    await ctx.storage().ref("users/someone/kyc/id.jpg").put(new Uint8Array(8), { contentType: "image/jpeg" });
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

const OFF = { role: "SuperAdmin" };
const ON_NO_2FA = { role: "SuperAdmin", mfa_required: true };
const ON_WITH_2FA = { role: "SuperAdmin", mfa_required: true, firebase: { sign_in_provider: "password", sign_in_second_factor: "totp" } };

test("TAQ-25 rules: the switch is off by default; when on, a SuperAdmin needs the second factor", async () => {
  const read = (claims) => getDoc(doc(testEnv.authenticatedContext("root", claims).firestore(), "Users/someone"));
  await assertSucceeds(read(OFF));
  await assertFails(read(ON_NO_2FA));
  await assertSucceeds(read(ON_WITH_2FA));
  await assertFails(read({ role: "Owner", mfa_required: true, firebase: { sign_in_second_factor: "totp" } }));
});

test("TAQ-25 storage: same switch on the private users/ folder", async () => {
  const meta = (claims) => testEnv.authenticatedContext("root", claims).storage().ref("users/someone/kyc/id.jpg").getMetadata();
  await assertSucceeds(meta(OFF));
  await assertFails(meta(ON_NO_2FA));
  await assertSucceeds(meta(ON_WITH_2FA));
});

test("TAQ-25 callables: requireRole refuses with mfa_required, and triggers are unaffected", async () => {
  const auth = (token) => ({ uid: "root", token });
  assert.equal(await requireRole(auth(OFF), ["SuperAdmin"]), "SuperAdmin");
  assert.equal(await requireRole(auth(ON_WITH_2FA), ["SuperAdmin"]), "SuperAdmin");
  await assert.rejects(requireRole(auth(ON_NO_2FA), ["SuperAdmin"]), (e) => e.code === "permission-denied" && e.details.reason === "mfa_required");
  await assert.rejects(requireRole(auth(ON_NO_2FA), ["Admin", "SuperAdmin"]), (e) => e.details.reason === "mfa_required");
  assert.equal(await resolveRole(auth(ON_NO_2FA)), "");
  assert.equal(missingSecondFactor(auth({ role: "Owner", mfa_required: true })), false, "only SuperAdmin and Admin are switched");
  await admin.auth().createUser({ uid: "trigger-sa" }).catch(() => {});
  await admin.auth().setCustomUserClaims("trigger-sa", ON_NO_2FA);
  assert.equal((await resolveUserAuthority("trigger-sa")).role, "SuperAdmin");
});

test("TAQ-25 script: --require-mfa refuses without an enrolled factor or for a non-SuperAdmin, and is a dry run by default", async () => {
  const fake = (claims, factors) => {
    const calls = [];
    return {
      calls,
      getUser: async (uid) => ({ uid, customClaims: claims, multiFactor: { enrolledFactors: factors } }),
      setCustomUserClaims: async (uid, c) => calls.push(["claims", c]),
      revokeRefreshTokens: async (uid) => calls.push(["revoke", uid]),
    };
  };
  const quiet = () => {};
  await assert.rejects(setMfaRequired(fake({ role: "SuperAdmin" }, []), "u", true, true, quiet), /no enrolled second factor/);
  await assert.rejects(setMfaRequired(fake({ role: "Owner" }, [{ factorId: "totp" }]), "u", true, true, quiet), /not a SuperAdmin or Admin/);
  assert.equal(await setMfaRequired(fake({ role: "Admin" }, [{ factorId: "totp" }]), "u", true, true, quiet), true, "TAQ-185: an Admin can be switched on");
  const dry = fake({ role: "SuperAdmin" }, [{ factorId: "totp" }]);
  assert.equal(await setMfaRequired(dry, "u", true, false, quiet), false);
  assert.deepEqual(dry.calls, []);
  const on = fake({ role: "SuperAdmin", x: 1 }, [{ factorId: "totp" }]);
  assert.equal(await setMfaRequired(on, "u", true, true, quiet), true);
  assert.deepEqual(on.calls, [["claims", { role: "SuperAdmin", x: 1, mfa_required: true }], ["revoke", "u"]]);
  const off = fake({ role: "SuperAdmin", mfa_required: true }, []);
  assert.equal(await setMfaRequired(off, "u", false, true, quiet), true);
  assert.deepEqual(off.calls, [["claims", { role: "SuperAdmin" }]], "turning it off needs no factor and keeps the session");
  assert.throws(() => parseArgs(["--project", "p", "--require-mfa"]), /needs a uid/);
  assert.throws(() => parseArgs(["--project", "p", "--require-mfa", "u", "--clear-mfa", "u"]), /one of/);
});

test("TAQ-185: the same switch applies to the platform Admin in rules, Storage and callables", async () => {
  const A_OFF = { role: "Admin" };
  const A_NO_2FA = { role: "Admin", mfa_required: true };
  const A_2FA = { role: "Admin", mfa_required: true, firebase: { sign_in_provider: "password", sign_in_second_factor: "totp" } };
  const alerts = (claims) => getDoc(doc(testEnv.authenticatedContext("staff", claims).firestore(), "AdminAlerts/a1"));
  await assertSucceeds(alerts(A_OFF));
  await assertFails(alerts(A_NO_2FA));
  await assertSucceeds(alerts(A_2FA));
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.storage().ref("public/listings/o1/p1/a.jpg").put(new Uint8Array(8), { contentType: "image/jpeg" });
  });
  const photo = (claims) => testEnv.authenticatedContext("staff", claims).storage().ref("public/listings/o1/p1/a.jpg").getMetadata();
  await assertSucceeds(photo(A_OFF));
  await assertFails(photo(A_NO_2FA));
  await assertSucceeds(photo(A_2FA));
  const auth = (token) => ({ uid: "staff", token });
  assert.equal(await requireRole(auth(A_2FA), ["Admin", "SuperAdmin"]), "Admin");
  await assert.rejects(requireRole(auth(A_NO_2FA), ["Admin", "SuperAdmin"]), (e) => e.details && e.details.reason === "mfa_required");
  await assert.rejects(requireRole(auth(A_NO_2FA), ["Owner"]), (e) => e.code === "permission-denied" && !(e.details && e.details.reason));
});
