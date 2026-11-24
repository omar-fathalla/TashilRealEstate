const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");

const root = path.join(__dirname, "..", "..");
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");

// --- TAQ-44: local tooling never targets production by default ---

test("TAQ-44: the default Firebase project is a demo project; production needs the prod alias", () => {
  const rc = JSON.parse(read(".firebaserc"));
  assert.match(rc.projects.default, /^demo-/);
  assert.equal(rc.projects.prod, "tashil-proptech-os");
});

test("TAQ-44: backend scripts that touch a live project name it explicitly", () => {
  const { scripts } = JSON.parse(read("backend/package.json"));
  assert.match(scripts.deploy, /--project prod\b/);
  assert.match(scripts.logs, /--project prod\b/);
  for (const name of ["test:core", "test:emulator", "serve", "shell"]) {
    assert.match(scripts[name], /--project demo-/, name);
  }
});

test("TAQ-44: seed.js has no hard-coded project id", () => {
  assert.doesNotMatch(read("backend/seed.js"), /tashil-proptech-os/);
});

test("TAQ-44: the Flutter version pin is consistent", () => {
  const pinned = JSON.parse(read("frontend/.fvmrc")).flutter;
  const pubspec = read("frontend/pubspec.yaml");
  const lock = read("frontend/pubspec.lock");
  assert.match(pubspec, new RegExp(`flutter: '>=${pinned.replace(/\./g, "\\.")}'`));
  assert.match(lock, new RegExp(`flutter: ">=${pinned.replace(/\./g, "\\.")}"`));
});

// --- TAQ-54: `flutter analyze` exits 0 and leaves the tree clean ---

test("TAQ-54: analysis_options.yaml already excludes build and every platform folder", () => {
  // Otherwise Flutter's AnalysisOptionsMigration rewrites the file on every flutter command.
  const options = read("frontend/analysis_options.yaml");
  const excludes = new Set([...options.matchAll(/^\s+-\s+(\S+\/\*\*)\s*$/gm)].map((m) => m[1]));
  const platforms = ["android", "ios", "web", "windows", "macos", "linux"]
    .filter((dir) => fs.existsSync(path.join(root, "frontend", dir)));
  for (const dir of ["build", ...platforms]) {
    assert.ok(excludes.has(`${dir}/**`), `add "${dir}/**" to analyzer.exclude`);
  }
});

test("TAQ-54: the material_ui deprecation infos do not fail flutter analyze", () => {
  assert.match(read("frontend/analysis_options.yaml"), /^\s+deprecated_member_use:\s+ignore\s*$/m);
});

// --- TAQ-35: Firebase Hosting security headers ---

function hostingHeaders(source) {
  const { hosting } = JSON.parse(read("firebase.json"));
  const entry = (hosting.headers || []).find((h) => h.source === source);
  assert.ok(entry, `no hosting.headers entry for ${source}`);
  return Object.fromEntries(entry.headers.map(({ key, value }) => [key, value]));
}

test("TAQ-35: every hosting response carries the security headers", () => {
  const headers = hostingHeaders("**");
  assert.equal(headers["Strict-Transport-Security"], "max-age=31536000; includeSubDomains");
  assert.equal(headers["X-Content-Type-Options"], "nosniff");
  assert.equal(headers["X-Frame-Options"], "DENY");
  assert.equal(headers["Referrer-Policy"], "strict-origin-when-cross-origin");
  assert.equal(headers["Permissions-Policy"], "camera=(self), microphone=(self), geolocation=(self), payment=()");
});

test("TAQ-35: the CSP ships report-only and covers the Flutter web and Firebase origins", () => {
  const headers = hostingHeaders("**");
  assert.equal(headers["Content-Security-Policy"], undefined, "enforce the CSP only after the report-only run is clean");
  const csp = Object.fromEntries(headers["Content-Security-Policy-Report-Only"].split(";").map((d) => {
    const [name, ...values] = d.trim().split(/\s+/);
    return [name, values];
  }));
  assert.deepEqual(csp["default-src"], ["'self'"]);
  assert.ok(csp["script-src"].includes("'wasm-unsafe-eval'"));
  assert.ok(!csp["script-src"].includes("'unsafe-eval'"));
  assert.ok(!csp["script-src"].includes("'unsafe-inline'"));
  for (const origin of ["https://*.googleapis.com", "https://*.firebaseio.com", "https://*.cloudfunctions.net", "https://fonts.gstatic.com"]) {
    assert.ok(csp["connect-src"].includes(origin), origin);
  }
  assert.deepEqual(csp["frame-ancestors"], ["'none'"]);
  assert.deepEqual(csp["object-src"], ["'none'"]);
  assert.deepEqual(csp["base-uri"], ["'self'"]);
});

test("TAQ-35: index.html is revalidated on every load, including SPA routes that rewrite to it", () => {
  assert.equal(hostingHeaders("/index.html")["Cache-Control"], "no-cache");
  // The ** -> /index.html rewrite keeps the request path, so "/" and app routes need their own entry.
  assert.equal(hostingHeaders("{/,**/!(*.*)}")["Cache-Control"], "no-cache");
});

test("TAQ-71: listing deep links with a dot and the fixed-name Flutter scripts are revalidated", () => {
  assert.equal(hostingHeaders("/listing/**")["Cache-Control"], "no-cache");
  assert.equal(hostingHeaders("/{main.dart.js,flutter_bootstrap.js,flutter_service_worker.js}")["Cache-Control"], "no-cache");
  const { hosting } = JSON.parse(read("firebase.json"));
  const noCache = hosting.headers.filter((h) => h.headers.some(({ key }) => key === "Cache-Control")).map((h) => h.source);
  assert.ok(!noCache.includes("**"), "hashed assets and CanvasKit stay cacheable");
  assert.equal(hostingHeaders("**")["Content-Security-Policy"], undefined, "the CSP stays report-only");
});
