#!/usr/bin/env node
/**
 * Fails when the Flutter client ships a Gemini key or calls Gemini directly.
 * Gemini runs only through the geminiGenerate Cloud Function (TAQ-19).
 *
 * Usage: node backend/scripts/check_client_ai_keys.js [--build]
 *   --build  also scans the compiled frontend/build/web output (run `flutter build web` first).
 *            For a dev build, export DEV_FIREBASE_WEB_API_KEY (the value given to --dart-define)
 *            so that one key is accepted.
 */
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const ROOT = path.join(__dirname, "..", "..");
const SCAN_DIRS = ["frontend/lib", "frontend/web"];
const BUILD_DIR = "frontend/build/web";
const SCAN_EXTENSIONS = new Set([".dart", ".js", ".mjs", ".map", ".html", ".json", ".yaml", ".txt"]);

// Firebase client config keys are public identifiers, not Gemini keys. In source they may appear
// only as `apiKey:` entries in the generated firebase_options.dart; compiled output may contain
// exactly those values and no other key.
const FIREBASE_OPTIONS = "frontend/lib/firebase_options.dart";
// The dev project's web key normally arrives through --dart-define (DEV_FIREBASE_WEB_API_KEY)
// and is not in the source. A dev build contains it, so pass the same value in this script's
// environment to let the build scan accept exactly that key.
const FIREBASE_OPTIONS_DEV = "frontend/lib/firebase_options_dev.dart";
const FIREBASE_OPTIONS_FILES = [FIREBASE_OPTIONS, FIREBASE_OPTIONS_DEV];
const DEV_KEY_ENV = "DEV_FIREBASE_WEB_API_KEY";

const RULES = [
  { name: "Google API key (AIza…)", pattern: /AIza[0-9A-Za-z_-]{30,}/g, firebaseConfigAllowed: true },
  { name: "Google API key (AQ.…)", pattern: /AQ\.[0-9A-Za-z_-]{20,}/g },
  { name: "base64 of an AIza key", pattern: /QUl6Y[0-9A-Za-z+/=]{20,}/g },
  { name: "base64 of an AQ. key", pattern: /QVEu[0-9A-Za-z+/=]{16,}/g },
  { name: "direct Gemini API URL", pattern: /generativelanguage\.googleapis\.com/g },
  { name: "direct Vertex AI URL", pattern: /aiplatform\.googleapis\.com/g },
  { name: "GEMINI_API_KEY define", pattern: /GEMINI_API_KEY/g },
  { name: "Gemini REST method", pattern: /:(stream)?[gG]enerateContent\b/g },
];

// Hosting can serve precompressed copies (main.dart.js.gz, .br). The build scan reads them
// decompressed, so a key only in a compressed copy is still found (TAQ-86).
const COMPRESSED = {
  ".gz": (buf) => zlib.gunzipSync(buf),
  ".br": (buf) => zlib.brotliDecompressSync(buf),
};

function scannable(name) {
  const ext = path.extname(name);
  if (COMPRESSED[ext]) return SCAN_EXTENSIONS.has(path.extname(name.slice(0, -ext.length)));
  return SCAN_EXTENSIONS.has(ext);
}

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else if (scannable(entry.name)) out.push(full);
  }
  return out;
}

/** A file's text, decompressed for .gz and .br. A copy that does not decompress is a finding. */
function readText(file) {
  const decompress = COMPRESSED[path.extname(file)];
  if (!decompress) return fs.readFileSync(file, "utf8");
  return decompress(fs.readFileSync(file)).toString("utf8");
}

function firebaseApiKeys(root = ROOT, env = process.env) {
  const keys = new Set();
  for (const rel of FIREBASE_OPTIONS_FILES) {
    const file = path.join(root, rel);
    if (!fs.existsSync(file)) continue;
    for (const m of fs.readFileSync(file, "utf8").matchAll(/^\s*apiKey:\s*'([^']+)',\s*$/gm)) keys.add(m[1]);
  }
  const devKey = String(env[DEV_KEY_ENV] || "").trim();
  if (devKey) keys.add(devKey);
  return keys;
}

function scanText(relPath, text, { allowedKeys = new Set() } = {}) {
  const findings = [];
  const lines = text.split("\n");
  lines.forEach((line, index) => {
    for (const rule of RULES) {
      rule.pattern.lastIndex = 0;
      if (!rule.pattern.test(line)) continue;
      if (rule.firebaseConfigAllowed) {
        if (FIREBASE_OPTIONS_FILES.includes(relPath) && /^\s*apiKey:\s*'[^']+',\s*$/.test(line)) continue;
        if (relPath.startsWith(`${BUILD_DIR}/`) && line.match(rule.pattern).every((key) => allowedKeys.has(key))) continue;
      }
      findings.push({ file: relPath, line: index + 1, rule: rule.name });
    }
  });
  return findings;
}

function scanClient(root = ROOT, { build = false, env = process.env } = {}) {
  const dirs = build ? [...SCAN_DIRS, BUILD_DIR] : SCAN_DIRS;
  if (build && !fs.existsSync(path.join(root, BUILD_DIR))) {
    throw new Error(`${BUILD_DIR} does not exist; run \`flutter build web\` in frontend/ first.`);
  }
  const allowedKeys = build ? firebaseApiKeys(root, env) : new Set();
  const findings = [];
  for (const dir of dirs) {
    for (const file of walk(path.join(root, dir))) {
      const relPath = path.relative(root, file).split(path.sep).join("/");
      let text;
      try {
        text = readText(file);
      } catch (err) {
        findings.push({ file: relPath, line: 0, rule: `unreadable compressed file (${err.code || err.message})` });
        continue;
      }
      findings.push(...scanText(relPath, text, { allowedKeys }));
    }
  }
  return findings;
}

module.exports = {
  scanClient,
  scanText,
  firebaseApiKeys,
  RULES,
  FIREBASE_OPTIONS,
  FIREBASE_OPTIONS_DEV,
  BUILD_DIR,
  DEV_KEY_ENV,
};

if (require.main === module) {
  const build = process.argv.includes("--build");
  let findings;
  try {
    findings = scanClient(ROOT, { build });
  } catch (err) {
    console.error(err.message);
    process.exit(2);
  }
  const scanned = (build ? [...SCAN_DIRS, BUILD_DIR] : SCAN_DIRS).join(", ");
  if (findings.length) {
    for (const f of findings) console.error(`${f.file}:${f.line}: ${f.rule}`);
    console.error(`\n${findings.length} client AI key finding(s) in ${scanned}. Gemini must go through geminiGenerate.`);
    process.exit(1);
  }
  console.log(`No Gemini keys or direct Gemini URLs in ${scanned}.`);
}
