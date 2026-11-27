const test = require("node:test");
const assert = require("node:assert/strict");

const { FUNCTIONS_SERVICE_ACCOUNT } = require("../runtime_options");

test("every exported function runs as the dedicated runtime service account (TAQ-177)", () => {
  assert.equal(FUNCTIONS_SERVICE_ACCOUNT, "tashil-functions@");
  const exported = require("../index");
  const endpoints = Object.entries(exported).filter(([, value]) => value && value.__endpoint);
  assert.ok(endpoints.length > 30, `expected the full function set, found ${endpoints.length}`);
  for (const [name, fn] of endpoints) {
    assert.equal(fn.__endpoint.serviceAccountEmail, FUNCTIONS_SERVICE_ACCOUNT, `${name} has no runtime SA`);
  }
});
