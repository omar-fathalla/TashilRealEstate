const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const test = require("node:test");
const assert = require("node:assert/strict");

const backendDir = path.join(__dirname, "..");
const envFile = path.join(backendDir, ".env");

const PARAM_CALL = /\bdefine(String|Int|Boolean|Float|List)\(\s*["']([A-Z][A-Z0-9_]*)["']/g;
const SECRET_CALL = /\bdefine(Secret|JsonSecret)\(\s*["']([A-Z][A-Z0-9_]*)["']/g;

function sourceFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    if (entry.name === "node_modules" || entry.name === "test") return [];
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return sourceFiles(full);
    return entry.name.endsWith(".js") ? [full] : [];
  });
}

function collect(pattern) {
  const found = new Map();
  for (const file of sourceFiles(backendDir)) {
    for (const match of fs.readFileSync(file, "utf8").matchAll(pattern)) {
      found.set(match[2], path.relative(backendDir, file));
    }
  }
  return found;
}

function readEnv() {
  const values = new Map();
  for (const line of fs.readFileSync(envFile, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    assert.ok(eq > 0, `backend/.env line is not KEY=value: ${trimmed}`);
    values.set(trimmed.slice(0, eq).trim(), trimmed.slice(eq + 1).trim());
  }
  return values;
}

// --- TAQ-89: non-interactive deploys need a value for every param ---

test("TAQ-89: every defineString/defineInt param in backend has a value in backend/.env", () => {
  const params = collect(PARAM_CALL);
  assert.ok(params.has("GEMINI_MODEL") && params.has("GEMINI_THINKING_BUDGET"), "param scan found nothing; fix the test");
  const values = readEnv();
  for (const [name, file] of params) {
    assert.ok(values.get(name), `${name} (${file}) has no value in backend/.env; a non-interactive deploy would fail`);
  }
});

test("TAQ-89: backend/.env holds only declared non-secret params with valid values", () => {
  const params = collect(PARAM_CALL);
  const secrets = collect(SECRET_CALL);
  const values = readEnv();
  for (const [name, value] of values) {
    assert.ok(params.has(name), `${name} in backend/.env is not a param used in backend/`);
    assert.ok(!secrets.has(name), `${name} is a secret and must not be in backend/.env`);
    assert.doesNotMatch(value, /AIza|AQ\.|[A-Za-z0-9_-]{32,}/, `${name} looks like a credential`);
  }
  assert.ok(secrets.has("GEMINI_API_KEY"));
  assert.match(values.get("GEMINI_MODEL"), /^gemini-[a-z0-9.-]+$/);
  assert.match(values.get("GEMINI_THINKING_BUDGET"), /^-?\d+$/);
});

test("TAQ-89: backend/.env is tracked, while local override files stay ignored", () => {
  const ignored = (file) => {
    try {
      execFileSync("git", ["check-ignore", "-q", file], { cwd: backendDir, stdio: "ignore" });
      return true;
    } catch (error) {
      if (error.status === 1) return false;
      throw error;
    }
  };
  assert.equal(ignored(".env"), false, "backend/.env must not be gitignored");
  for (const file of [".env.local", ".env.tashil-aqar-dev.local", ".secret.local", ".secret.dev.local"]) {
    assert.equal(ignored(file), true, `${file} must be gitignored`);
  }
});
