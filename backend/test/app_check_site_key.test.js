// TAQ-170: the dev build's reCAPTCHA key comes from App Check only, or the lookup fails.
const test = require("node:test");
const assert = require("node:assert");
const fs = require("fs");
const path = require("path");
const { parseArgs, webAppId, lookupSiteKey, LookupError } = require("../scripts/app_check_site_key");

const KEY = "6Lc" + "a".repeat(37);
const ok = (body) => async () => ({ ok: true, status: 200, json: async () => body });

test("TAQ-170: --project is required and limited to the known projects", () => {
  assert.throws(() => parseArgs([]), LookupError);
  assert.throws(() => parseArgs(["--project"]), LookupError);
  assert.throws(() => parseArgs(["--project", "some-other-project"]), LookupError);
  assert.deepStrictEqual(parseArgs(["--project", "tashil-aqar-dev"]), { project: "tashil-aqar-dev" });
});

test("TAQ-170: the web appId comes from the matching options file", () => {
  const read = (f) => fs.readFileSync(path.join(__dirname, "../..", f), "utf8");
  assert.strictEqual(webAppId(read("frontend/lib/firebase_options_dev.dart"), "tashil-aqar-dev"), "1:169661829655:web:0251892e514a30e54c4252");
  assert.match(webAppId(read("frontend/lib/firebase_options.dart"), "tashil-proptech-os"), /^1:534001947779:web:/);
  assert.throws(() => webAppId(read("frontend/lib/firebase_options.dart"), "tashil-aqar-dev"), LookupError);
});

test("TAQ-170: reads siteKey from the App Check recaptchaEnterpriseConfig of the dev web app", async () => {
  let seen;
  const key = await lookupSiteKey({
    project: "tashil-aqar-dev",
    token: "t",
    fetchImpl: async (url, init) => {
      seen = { url, init };
      return { ok: true, status: 200, json: async () => ({ name: "x", siteKey: KEY, tokenTtl: "3600s" }) };
    },
  });
  assert.strictEqual(key, KEY);
  assert.strictEqual(
    seen.url,
    "https://firebaseappcheck.googleapis.com/v1/projects/tashil-aqar-dev/apps/1:169661829655:web:0251892e514a30e54c4252/recaptchaEnterpriseConfig",
  );
  assert.strictEqual(seen.init.headers.Authorization, "Bearer t");
});

test("TAQ-170: fails instead of guessing when there is no usable key", async () => {
  const run = (fetchImpl, token = "t") => lookupSiteKey({ project: "tashil-aqar-dev", token, fetchImpl });
  await assert.rejects(run(ok({ siteKey: KEY }), ""), /ACCESS_TOKEN/);
  await assert.rejects(run(ok({ name: "x" })), /no reCAPTCHA Enterprise site key/);
  await assert.rejects(run(ok({ siteKey: "" })), /no reCAPTCHA Enterprise site key/);
  await assert.rejects(run(ok({ siteKey: "AIzaSy" + "b".repeat(33) + "!" })), /does not look like/);
  await assert.rejects(run(ok({ siteKey: KEY.slice(1) })), /does not look like/);
  await assert.rejects(run(async () => ({ ok: false, status: 404, json: async () => ({}) })), /HTTP 404/);
});
