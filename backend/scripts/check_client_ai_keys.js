#!/usr/bin/env node
/**
 * Fails when the Flutter client ships a Gemini key or calls Gemini directly.
 * Gemini runs only through the geminiGenerate Cloud Function (TAQ-19).
 *
 * Usage: node backend/scripts/check_client_ai_keys.js [--build]
 *   --build  also scans the compiled frontend/build/web output (run `flutter build web` first).
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const SCAN_DIRS = ["frontend/lib", "frontend/web"];
const BUILD_DIR = "frontend/build/web";
const SCAN_EXTENSIONS = new Set([".dart", ".js", ".mjs", ".map", ".html", ".json", ".yaml", ".txt"]);

// Firebase client config keys are public identifiers, not Gemini keys. In source they may appear
// only as `apiKey:` entries in the generated firebase_options.dart; compiled output may contain
// exactly those values and no other key.
const FIREBASE_OPTIONS = "frontend/lib/firebase_options.dart";

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

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else if (SCAN_EXTENSIONS.has(path.extname(entry.name))) out.push(full);
  }
  return out;
}

function firebaseApiKeys(root = ROOT) {
  const file = path.join(root, FIREBASE_OPTIONS);
  if (!fs.existsSync(file)) return new Set();
  return new Set([...fs.readFileSync(file, "utf8").matchAll(/^\s*apiKey:\s*'([^']+)',\s*$/gm)].map((m) => m[1]));
}

function scanText(relPath, text, { allowedKeys = new Set() } = {}) {
  const findings = [];
  const lines = text.split("\n");
  lines.forEach((line, index) => {
    for (const rule of RULES) {
      rule.pattern.lastIndex = 0;
      if (!rule.pattern.test(line)) continue;
      if (rule.firebaseConfigAllowed) {
        if (relPath === FIREBASE_OPTIONS && /^\s*apiKey:\s*'[^']+',\s*$/.test(line)) continue;
        if (relPath.startsWith(`${BUILD_DIR}/`) && line.match(rule.pattern).every((key) => allowedKeys.has(key))) continue;
      }
      findings.push({ file: relPath, line: index + 1, rule: rule.name });
    }
  });
  return findings;
}

function scanClient(root = ROOT, { build = false } = {}) {
  const dirs = build ? [...SCAN_DIRS, BUILD_DIR] : SCAN_DIRS;
  if (build && !fs.existsSync(path.join(root, BUILD_DIR))) {
    throw new Error(`${BUILD_DIR} does not exist; run \`flutter build web\` in frontend/ first.`);
  }
  const allowedKeys = build ? firebaseApiKeys(root) : new Set();
  const findings = [];
  for (const dir of dirs) {
    for (const file of walk(path.join(root, dir))) {
      const relPath = path.relative(root, file).split(path.sep).join("/");
      findings.push(...scanText(relPath, fs.readFileSync(file, "utf8"), { allowedKeys }));
    }
  }
  return findings;
}

module.exports = { scanClient, scanText, firebaseApiKeys, RULES, FIREBASE_OPTIONS, BUILD_DIR };

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
