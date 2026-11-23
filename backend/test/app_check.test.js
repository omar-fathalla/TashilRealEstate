const test = require("node:test");
const assert = require("node:assert/strict");
const { appCheckEnforced } = require("../config");

const CALLABLES = ["sendRentalReminder", "generateRentalInvoiceReceipt", "setUserRole"];

/** Loads a fresh copy of index.js with ENFORCE_APP_CHECK set as given. */
function loadFunctions(value) {
  const previous = process.env.ENFORCE_APP_CHECK;
  if (value === undefined) delete process.env.ENFORCE_APP_CHECK;
  else process.env.ENFORCE_APP_CHECK = value;
  try {
    for (const mod of ["../index", "../config"]) delete require.cache[require.resolve(mod)];
    return require("../index");
  } finally {
    if (previous === undefined) delete process.env.ENFORCE_APP_CHECK;
    else process.env.ENFORCE_APP_CHECK = previous;
  }
}

/** Sends an HTTP callable request with no Auth and no App Check token through the real handler. */
function callOverHttp(fn) {
  return new Promise((resolve) => {
    const headers = { "content-type": "application/json" };
    const req = {
      method: "POST",
      url: "/",
      headers,
      header: (name) => headers[name.toLowerCase()],
      get: (name) => headers[name.toLowerCase()],
      body: { data: { leaseId: "lease-1" } },
      on() {},
    };
    const res = {
      statusCode: 200,
      headers: {},
      setHeader(k, v) { this.headers[k] = v; },
      getHeader(k) { return this.headers[k]; },
      status(code) { this.statusCode = code; return this; },
      send(body) { resolve({ status: this.statusCode, body }); },
      json(body) { resolve({ status: this.statusCode, body }); },
      end(body) { resolve({ status: this.statusCode, body }); },
      on() {},
    };
    fn(req, res);
  });
}

// --- TAQ-41: App Check enforcement is configurable and off by default ---

test("TAQ-41: ENFORCE_APP_CHECK parsing", () => {
  assert.equal(appCheckEnforced({}), false);
  assert.equal(appCheckEnforced({ ENFORCE_APP_CHECK: "" }), false);
  assert.equal(appCheckEnforced({ ENFORCE_APP_CHECK: "false" }), false);
  assert.equal(appCheckEnforced({ ENFORCE_APP_CHECK: "1" }), false);
  assert.equal(appCheckEnforced({ ENFORCE_APP_CHECK: "true" }), true);
  assert.equal(appCheckEnforced({ ENFORCE_APP_CHECK: " TRUE " }), true);
});

test("TAQ-41: by default callables accept requests without App Check and still require sign-in", async () => {
  const fns = loadFunctions(undefined);
  for (const name of CALLABLES) {
    const { status, body } = await callOverHttp(fns[name]);
    assert.equal(status, 401, name);
    assert.equal(body.error.message, "Sign in is required.", `${name} should reach the handler's auth check`);
  }
});

test("TAQ-41: with ENFORCE_APP_CHECK=true callables reject requests without App Check", async () => {
  const fns = loadFunctions("true");
  for (const name of CALLABLES) {
    const { status, body } = await callOverHttp(fns[name]);
    assert.equal(status, 401, name);
    assert.equal(body.error.message, "Unauthenticated", `${name} should be stopped by App Check`);
  }
});
