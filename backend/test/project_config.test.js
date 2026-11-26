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
  assert.match(rc.projects.prod, /^[a-z][a-z0-9-]+$/);
  assert.doesNotMatch(rc.projects.prod, /^demo-/);
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
  assert.doesNotMatch(read("backend/seed.js"), new RegExp(JSON.parse(read(".firebaserc")).projects.prod));
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
    "backend/.env.qa-fake-prod-xyz.local",
    "frontend/.env.local",
  ]) {
    assert.equal(ignored(file), true, `${file} must be ignored`);
  }
  assert.equal(ignored("backend/.secret.local.example"), false);
  // TAQ-89: backend/.env is committed on purpose (non-secret function params only).
  assert.equal(ignored("backend/.env"), false);
});

test("TAQ-91: the repo-root .env and .secret* are ignored, and the ignore does not reach backend/.env", () => {
  const { execFileSync } = require("child_process");
  const check = (file) => {
    try {
      return execFileSync("git", ["check-ignore", "-v", file], { cwd: root, encoding: "utf8" }).trim();
    } catch (err) {
      if (err.status === 1) return "";
      throw err;
    }
  };
  for (const file of [".env", ".secret", ".secret.json", ".secret.prod"]) {
    assert.match(check(file), /^\.gitignore:\d+:\/\.(env|secret\*)\t/, `${file} must be ignored by an anchored root rule`);
  }
  // `git check-ignore -v backend/.env` prints nothing: no rule matches, and the file is tracked.
  assert.equal(check("backend/.env"), "");
  const tracked = execFileSync("git", ["ls-files", "--error-unmatch", "backend/.env"], { cwd: root, encoding: "utf8" });
  assert.equal(tracked.trim(), "backend/.env");
  assert.equal(check("backend/.secret.local") !== "", true);
});

test("TAQ-100 (F4 follow-up): backend/.secret*.json and backend/.env.* are ignored, backend/.env and examples are not", () => {
  const { execFileSync } = require("child_process");
  const check = (file) => {
    try {
      return execFileSync("git", ["check-ignore", "-v", file], { cwd: root, encoding: "utf8" }).trim();
    } catch (err) {
      if (err.status === 1) return "";
      throw err;
    }
  };
  for (const file of [
    "backend/.secret.json",
    "backend/.secret-prod.json",
    "backend/.secret.service-account.json",
    "backend/.env.qa-fake-prod-xyz",
    "backend/.env.some-project",
    "backend/.env.production",
  ]) {
    assert.notEqual(check(file), "", `${file} must be ignored`);
  }
  assert.equal(check("backend/.env"), "", "backend/.env stays tracked");
  let exampleIgnored = true;
  try {
    execFileSync("git", ["check-ignore", "-q", "backend/.env.example"], { cwd: root });
  } catch (err) {
    if (err.status !== 1) throw err;
    exampleIgnored = false;
  }
  assert.equal(exampleIgnored, false, "example templates stay tracked");
  assert.equal(check("backend/package.json"), "");
  const { execFileSync: run } = require("child_process");
  assert.equal(run("git", ["ls-files", "--error-unmatch", "backend/.env"], { cwd: root, encoding: "utf8" }).trim(), "backend/.env");
  const tracked = run("git", ["ls-files", "backend"], { cwd: root, encoding: "utf8" }).split("\n");
  assert.deepEqual(tracked.filter((f) => /(^|\/)\.env\./.test(f) && !f.endsWith(".example")), [], "no per-project env file is tracked");
  assert.deepEqual(tracked.filter((f) => /\.secret.*\.json$/.test(f)), [], "no secret json is tracked");
});

test("TAQ-87: connect-src names the two geocoding hosts the app calls, and the CSP stays report-only", () => {
  const headers = hostingHeaders("**");
  assert.equal(headers["Content-Security-Policy"], undefined);
  const connect = headers["Content-Security-Policy-Report-Only"].match(/connect-src ([^;]*)/)[1].trim().split(/\s+/);
  for (const origin of ["https://nominatim.openstreetmap.org", "https://ipwho.is"]) assert.ok(connect.includes(origin), origin);
  const service = fs.readFileSync(path.join(__dirname, "../../frontend/lib/core/services/location/location_geocoding_service.dart"), "utf8");
  for (const host of ["nominatim.openstreetmap.org", "ipwho.is"]) assert.ok(service.includes(`https://${host}/`), `${host} is used by the app`);
});

// --- TAQ-155: web App Check (reCAPTCHA Enterprise) must not be blocked once the CSP is enforced ---

test("TAQ-155: the CSP allows the reCAPTCHA Enterprise script, its challenge frames and its network calls", () => {
  const headers = hostingHeaders("**");
  assert.equal(headers["Content-Security-Policy"], undefined, "the CSP stays report-only");
  const csp = Object.fromEntries(headers["Content-Security-Policy-Report-Only"].split(";").map((d) => {
    const [name, ...values] = d.trim().split(/\s+/);
    return [name, values];
  }));
  const want = {
    "script-src": ["https://www.google.com/recaptcha/", "https://www.gstatic.com/recaptcha/", "https://www.recaptcha.net/recaptcha/"],
    "connect-src": ["https://www.google.com/recaptcha/", "https://www.recaptcha.net/recaptcha/"],
    "frame-src": ["https://www.google.com/recaptcha/", "https://recaptcha.google.com/recaptcha/", "https://www.recaptcha.net/recaptcha/"],
  };
  for (const [directive, origins] of Object.entries(want)) {
    for (const origin of origins) assert.ok(csp[directive].includes(origin), `${directive} lacks ${origin}`);
  }
  assert.ok(!csp["script-src"].includes("'unsafe-inline'") && !csp["script-src"].includes("'unsafe-eval'"), "script-src stays strict");
  assert.ok(!csp["connect-src"].includes("*") && !csp["frame-src"].includes("*"), "no wildcard sources");
  assert.deepEqual(csp["frame-ancestors"], ["'none'"]);
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
  assert.deepEqual(Object.keys(rc.projects).sort(), ["default", "dev", "prod"]);
  assert.equal(rc.projects.default, "demo-tashil-dev");
  assert.equal(rc.projects.dev, "tashil-aqar-dev");
  assert.match(rc.projects.prod, /^[a-z][a-z0-9-]+$/);
  assert.notEqual(rc.projects.prod, rc.projects.dev);
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

test("TAQ-7: docs/DEV_ENVIRONMENT.md documents the dev build and deploy and holds no secret", () => {
  const doc = read("docs/DEV_ENVIRONMENT.md");
  for (const needle of [
    "--dart-define=FIREBASE_ENV=dev",
    "DEV_FIREBASE_WEB_API_KEY",
    "firebase deploy --project dev",
    "GEMINI_API_KEY",
    "X-Forwarded-For",
    "visitor@test.tashilaqar.com",
    "superadmin@test.tashilaqar.com",
    "Investor",
  ]) {
    assert.ok(doc.includes(needle), needle);
  }
  assert.doesNotMatch(doc, /AIza[0-9A-Za-z_-]{20,}/);
  assert.doesNotMatch(doc, /(password|passwd)\s*[:=]\s*\S{6,}/i);
});

// --- TAQ-88: Cloud Functions run on a supported Node runtime ---

const MIN_NODE_MAJOR = 22;

function minMajor(range) {
  const match = String(range).match(/\d+/);
  assert.ok(match, `engines.node "${range}" has no version number`);
  return Number(match[0]);
}

test("TAQ-88: backend engines.node is at least 22 (Node 20 is decommissioned on Firebase)", () => {
  const { engines } = JSON.parse(read("backend/package.json"));
  assert.ok(engines && engines.node, "backend/package.json must set engines.node");
  assert.ok(minMajor(engines.node) >= MIN_NODE_MAJOR, `engines.node is ${engines.node}; need >= ${MIN_NODE_MAJOR}`);
});

test("TAQ-88: the lockfile and firebase.json runtime agree with engines.node", () => {
  const lock = JSON.parse(read("backend/package-lock.json"));
  assert.ok(minMajor(lock.packages[""].engines.node) >= MIN_NODE_MAJOR);
  const functions = JSON.parse(read("firebase.json")).functions;
  for (const entry of Array.isArray(functions) ? functions : [functions]) {
    if (entry.runtime === undefined) continue;
    const major = Number(String(entry.runtime).replace(/^nodejs/, ""));
    assert.ok(major >= MIN_NODE_MAJOR, `firebase.json runtime ${entry.runtime} is too old`);
  }
});

test("TAQ-83: the emulator-only XFF switch is never committed in a function env file", () => {
  const root = path.join(__dirname, "../..");
  const files = require("child_process").execFileSync("git", ["ls-files", "backend/.env*", "backend/**/.env*"], { cwd: root, encoding: "utf8" })
    .split("\n").filter(Boolean);
  assert.ok(files.includes("backend/.env"));
  for (const file of files) {
    assert.doesNotMatch(fs.readFileSync(path.join(root, file), "utf8"), /VISITOR_IP_EMULATOR_TRUST_XFF/, file);
  }
});

// --- TAQ-130: the registry backfill runbook ---

test("TAQ-130: the backfill runbook orders indexes, functions with rules, dry run, write, hosting, smoke", () => {
  const doc = read("docs/PROPERTY_REGISTRY_BACKFILL.md");
  const order = doc.slice(doc.indexOf("## Order of the production rollout"), doc.indexOf("## Running the backfill"));
  const steps = [
    "firebase deploy --only firestore:indexes --project prod",
    "gcloud firestore indexes composite list",
    "gcloud firestore indexes fields describe id --collection-group=properties",
    "firebase deploy --only functions,firestore:rules,storage --project prod",
    "idFieldIssues: 0",
    "--fix-id-fields --write",
    "--overrides overrides.json --write",
    "firebase deploy --only hosting --project prod",
    "Smoke check",
  ];
  let at = -1;
  for (const step of steps) {
    const next = order.indexOf(step, at + 1);
    assert.ok(next > at, `"${step}" is missing or out of order`);
    at = next;
  }
  assert.doesNotMatch(order, /--only firestore:rules,storage --project prod/, "rules no longer go out after the backfill");
  for (const id of ["prop-ae-101", "prop-ae-102", "prop-eg-101", "prop-eg-102", "prop-eg-103", "prop-eg-104"]) {
    assert.ok(doc.includes(id), `${id} is named for the owner decision`);
  }
  assert.ok(!doc.includes(JSON.parse(read(".firebaserc")).projects.prod), "no real production id in the runbook");
});

// --- TAQ-136: the runbook's dev rehearsal commands are ones the script accepts ---

test("TAQ-136: the runbook's backfill commands for dev name the real dev project, never the alias", () => {
  const backfill = require("../scripts/backfill_property_owners");
  const doc = read("docs/PROPERTY_REGISTRY_BACKFILL.md");
  const dev = JSON.parse(read(".firebaserc")).projects.dev;
  const commands = doc.split("\n").filter((l) => l.startsWith("node scripts/backfill_property_owners.js"));
  assert.ok(commands.length >= 3);
  for (const line of commands) {
    const argv = line.replace(/\s+#.*$/, "").split(/\s+/).slice(2);
    const { project } = backfill.parseArgs(argv);
    assert.equal(project, dev, line);
    assert.equal(backfill.resolveTarget(project), dev, line);
  }
  assert.throws(() => backfill.resolveTarget("dev"), /Refusing to run against/);
  assert.doesNotMatch(doc, /nothing in the repo holds the production project id/i);
});

// --- TAQ-138: the Android build needs the Gradle version Flutter 3.50 requires ---

test("TAQ-138: the Gradle wrapper is at least 9.3.1 (Flutter 3.50.1 refuses 9.1.0)", () => {
  const props = read("frontend/android/gradle/wrapper/gradle-wrapper.properties");
  const version = props.match(/gradle-(\d+)\.(\d+)(?:\.(\d+))?-(?:all|bin)\.zip/);
  assert.ok(version, "distributionUrl names a Gradle version");
  const [major, minor, patch] = [version[1], version[2], version[3] || "0"].map(Number);
  const atLeast = (a, b, c) => major > a || (major === a && (minor > b || (minor === b && patch >= c)));
  assert.ok(atLeast(9, 3, 1), `Gradle ${major}.${minor}.${patch} is older than 9.3.1`);
  assert.ok(!atLeast(9, 6, 0), "Flutter 3.50 supports Gradle up to 9.5.0; check the Flutter pin before raising it");
});
