const test = require("node:test");
const assert = require("node:assert/strict");

const { FUNCTIONS_SERVICE_ACCOUNT, functionsServiceAccount } = require("../runtime_options");

test("TAQ-177: the runtime service account is the full email for the deploy's project", () => {
  assert.equal(
    functionsServiceAccount({ GCLOUD_PROJECT: "tashil-aqar-dev" }),
    "tashil-functions@tashil-aqar-dev.iam.gserviceaccount.com",
  );
  assert.equal(
    functionsServiceAccount({ GCLOUD_PROJECT: "tashil-proptech-os" }),
    "tashil-functions@tashil-proptech-os.iam.gserviceaccount.com",
  );
  assert.equal(functionsServiceAccount({}), "tashil-functions@");
});

test("TAQ-177: every exported function runs as the dedicated runtime service account", () => {
  assert.match(FUNCTIONS_SERVICE_ACCOUNT, /^tashil-functions@([a-z0-9-]+\.iam\.gserviceaccount\.com)?$/);
  const exported = require("../index");
  const endpoints = Object.entries(exported).filter(([, value]) => value && value.__endpoint);
  assert.ok(endpoints.length > 30, `expected the full function set, found ${endpoints.length}`);
  for (const [name, fn] of endpoints) {
    assert.equal(fn.__endpoint.serviceAccountEmail, FUNCTIONS_SERVICE_ACCOUNT, `${name} has no runtime SA`);
  }
});
