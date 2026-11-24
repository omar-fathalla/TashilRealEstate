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
  for (const origin of ["https://firestore.googleapis.com", "https://*.firebaseio.com", "https://*.cloudfunctions.net", "https://fonts.gstatic.com"]) {
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

// --- TAQ-19: the client ships no Gemini key and never calls Gemini directly ---

const clientKeys = require("../scripts/check_client_ai_keys");

test("TAQ-19: frontend/lib and frontend/web hold no Gemini key, key define or direct Gemini URL", () => {
  assert.deepEqual(clientKeys.scanClient(), []);
});

test("TAQ-19: the client key check catches keys, their base64 forms and direct Gemini calls", () => {
  const fake = (prefix) => prefix + "x".repeat(36);
  const samples = [
    `const k = '${fake("AI" + "za")}';`,
    `const k = '${fake("AQ" + ".")}';`,
    `base64.decode('${Buffer.from(fake("AI" + "za")).toString("base64")}')`,
    `base64.decode('${Buffer.from(fake("AQ" + ".")).toString("base64")}')`,
    "Uri.parse('https://generative" + "language.googleapis.com/v1beta/models/m')",
    "String.fromEnvironment('GEMINI" + "_API_KEY')",
    "'models/$m:generate" + "Content'",
  ];
  for (const line of samples) {
    assert.equal(clientKeys.scanText("frontend/lib/x.dart", line).length > 0, true, line);
  }
});

test("TAQ-19: Firebase config keys are allowed only as apiKey entries in firebase_options.dart", () => {
  const line = `    apiKey: '${"AI" + "za"}${"y".repeat(35)}',`;
  assert.deepEqual(clientKeys.scanText(clientKeys.FIREBASE_OPTIONS, line), []);
  assert.equal(clientKeys.scanText("frontend/lib/other.dart", line).length, 1);
  assert.equal(clientKeys.scanText(clientKeys.FIREBASE_OPTIONS, `final k = '${"AI" + "za"}${"y".repeat(35)}';`).length, 1);
});

// --- TAQ-78: local secret files never get committed ---

test("TAQ-78: .secret.local, .secret.*.local and .env*.local are ignored; example templates are not", () => {
  const { execFileSync } = require("child_process");
  const ignored = (file) => {
    try {
      execFileSync("git", ["check-ignore", "-q", file], { cwd: root });
      return true;
    } catch (err) {
      if (err.status === 1) return false;
      throw err;
    }
  };
  for (const file of [
    "backend/.secret.local",
    "backend/.secret.prod.local",
    "backend/.env.local",
    "backend/.env.tashil-proptech-os.local",
    "frontend/.env.local",
    "backend/.env",
  ]) {
    assert.equal(ignored(file), true, `${file} must be ignored`);
  }
  assert.equal(ignored("backend/.secret.local.example"), false);
});

// --- TAQ-79: the CSP allows only the Google API hosts Firebase uses ---

test("TAQ-79: connect-src lists the Firebase googleapis hosts by name and never the Gemini or Vertex APIs", () => {
  const headers = hostingHeaders("**");
  assert.equal(headers["Content-Security-Policy"], undefined, "the CSP stays report-only");
  const connect = headers["Content-Security-Policy-Report-Only"].match(/connect-src ([^;]*)/)[1].trim().split(/\s+/);
  const googleapis = connect.filter((origin) => origin.includes("googleapis.com"));
  assert.deepEqual(googleapis.sort(), [
    "https://content-firebaseappcheck.googleapis.com",
    "https://fcmregistrations.googleapis.com",
    "https://firebaseinstallations.googleapis.com",
    "https://firebaselogging.googleapis.com",
    "https://firebaseremoteconfig.googleapis.com",
    "https://firebaseremoteconfigrealtime.googleapis.com",
    "https://firebasestorage.googleapis.com",
    "https://firestore.googleapis.com",
    "https://identitytoolkit.googleapis.com",
    "https://securetoken.googleapis.com",
    "https://storage.googleapis.com",
  ]);
  for (const origin of connect) {
    assert.doesNotMatch(origin, /\*\.googleapis\.com|generativelanguage|aiplatform/, origin);
  }
});

test("TAQ-79: the --build scan allows only the firebase_options keys in compiled web output", () => {
  const os = require("os");
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "client-keys-"));
  const firebaseKey = "AIza" + "F".repeat(35);
  const otherKey = "AIza" + "G".repeat(35);
  const write = (rel, text) => {
    fs.mkdirSync(path.dirname(path.join(tmp, rel)), { recursive: true });
    fs.writeFileSync(path.join(tmp, rel), text);
  };
  try {
    write(clientKeys.FIREBASE_OPTIONS, `  static const FirebaseOptions web = FirebaseOptions(\n    apiKey: '${firebaseKey}',\n  );\n`);
    assert.throws(() => clientKeys.scanClient(tmp, { build: true }), /flutter build web/);
    write(`${clientKeys.BUILD_DIR}/main.dart.js`, `a={apiKey:"${firebaseKey}",authDomain:"x"};b="${firebaseKey}"\n`);
    assert.deepEqual(clientKeys.scanClient(tmp, { build: true }), []);

    write(`${clientKeys.BUILD_DIR}/main.dart.js`, `a={apiKey:"${firebaseKey}"};k="${otherKey}"\n`);
    write(`${clientKeys.BUILD_DIR}/main.dart.js.map`, `{"x":"https://generativelanguage.googleapis.com/v1beta/models/m:generateContent"}`);
    write(`${clientKeys.BUILD_DIR}/assets/env.json`, `{"k":"${Buffer.from("AQ." + "h".repeat(30)).toString("base64")}"}`);
    const rules = clientKeys.scanClient(tmp, { build: true }).map((f) => `${f.file}: ${f.rule}`).sort();
    assert.deepEqual(rules, [
      `${clientKeys.BUILD_DIR}/assets/env.json: base64 of an AQ. key`,
      `${clientKeys.BUILD_DIR}/main.dart.js.map: Gemini REST method`,
      `${clientKeys.BUILD_DIR}/main.dart.js.map: direct Gemini API URL`,
      `${clientKeys.BUILD_DIR}/main.dart.js: Google API key (AIza…)`,
    ]);
    assert.deepEqual(clientKeys.scanClient(tmp), [], "without --build the compiled output is not scanned");
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

// --- TAQ-7: the dev Firebase project ---

test("TAQ-7: .firebaserc keeps the demo default and prod, and adds the Tashil Aqar dev alias", () => {
  const rc = JSON.parse(read(".firebaserc"));
  assert.deepEqual(rc.projects, {
    default: "demo-tashil-dev",
    prod: "tashil-proptech-os",
    dev: "tashil-aqar-dev",
  });
});

test("TAQ-7: tashil-dev (another product's project) is not referenced anywhere", () => {
  const { execFileSync } = require("child_process");
  const files = execFileSync("git", ["ls-files"], { cwd: root, encoding: "utf8" }).split("\n").filter(Boolean);
  const offenders = files.filter((file) => {
    if (file === "backend/test/project_config.test.js") return false;
    const text = fs.readFileSync(path.join(root, file), "utf8");
    return /(^|[^\w-])tashil-dev\b/.test(text);
  });
  assert.deepEqual(offenders, []);
});

test("TAQ-7: the dev web config names tashil-aqar-dev and takes its API key from a define", () => {
  const dev = read(clientKeys.FIREBASE_OPTIONS_DEV);
  for (const value of [
    "projectId: 'tashil-aqar-dev'",
    "appId: '1:169661829655:web:0251892e514a30e54c4252'",
    "messagingSenderId: '169661829655'",
    "authDomain: 'tashil-aqar-dev.firebaseapp.com'",
    "storageBucket: 'tashil-aqar-dev.firebasestorage.app'",
  ]) {
    assert.ok(dev.includes(value), value);
  }
  assert.doesNotMatch(dev, /measurementId/);
  assert.match(dev, /String\.fromEnvironment\(webApiKeyDefine\)/);
  assert.doesNotMatch(dev, /AIza/);
  assert.match(read("frontend/lib/app_firebase_options.dart"), /fromEnvironment\('FIREBASE_ENV', defaultValue: 'prod'\)/);
});

test("TAQ-7: the key guard allows the dev firebase config like prod's, and only that", () => {
  const key = "AIza" + "d".repeat(35);
  const line = `    apiKey: '${key}',`;
  assert.deepEqual(clientKeys.scanText(clientKeys.FIREBASE_OPTIONS_DEV, line), []);
  assert.equal(clientKeys.scanText("frontend/lib/other.dart", line).length, 1);
  assert.equal(clientKeys.scanText(clientKeys.FIREBASE_OPTIONS_DEV, `final k = '${key}';`).length, 1);

  const os = require("os");
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "client-keys-dev-"));
  const build = path.join(tmp, clientKeys.BUILD_DIR);
  fs.mkdirSync(build, { recursive: true });
  fs.mkdirSync(path.join(tmp, "frontend/lib"), { recursive: true });
  try {
    fs.writeFileSync(path.join(tmp, clientKeys.FIREBASE_OPTIONS), "  apiKey: '" + "AIza" + "p".repeat(35) + "',\n");
    fs.writeFileSync(path.join(build, "main.dart.js"), `a={apiKey:"${key}",projectId:"tashil-aqar-dev"}\n`);
    assert.equal(clientKeys.scanClient(tmp, { build: true, env: {} }).length, 1, "an unknown dev key is flagged");
    assert.deepEqual(clientKeys.scanClient(tmp, { build: true, env: { [clientKeys.DEV_KEY_ENV]: key } }), []);
    assert.equal(
      clientKeys.scanClient(tmp, { build: true, env: { [clientKeys.DEV_KEY_ENV]: "AIza" + "z".repeat(35) } }).length,
      1,
      "only the exact dev key is accepted",
    );
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
