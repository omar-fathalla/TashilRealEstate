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
