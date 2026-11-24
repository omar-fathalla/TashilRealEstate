#!/usr/bin/env node
/**
 * Fails when the Flutter client ships a Gemini key or calls Gemini directly.
 * Gemini runs only through the geminiGenerate Cloud Function (TAQ-19).
 *
 * Usage: node backend/scripts/check_client_ai_keys.js
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const SCAN_DIRS = ["frontend/lib", "frontend/web"];
const SCAN_EXTENSIONS = new Set([".dart", ".js", ".html", ".json", ".yaml", ".txt"]);

// Firebase client config keys are public identifiers, not Gemini keys. They may appear only
// as `apiKey:` entries in the generated firebase_options.dart.
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

function scanText(relPath, text) {
  const findings = [];
  const lines = text.split("\n");
  lines.forEach((line, index) => {
    for (const rule of RULES) {
      rule.pattern.lastIndex = 0;
      if (!rule.pattern.test(line)) continue;
      if (rule.firebaseConfigAllowed && relPath === FIREBASE_OPTIONS && /^\s*apiKey:\s*'[^']+',\s*$/.test(line)) continue;
      findings.push({ file: relPath, line: index + 1, rule: rule.name });
    }
  });
  return findings;
}

function scanClient(root = ROOT) {
  const findings = [];
  for (const dir of SCAN_DIRS) {
    for (const file of walk(path.join(root, dir))) {
      const relPath = path.relative(root, file).split(path.sep).join("/");
      findings.push(...scanText(relPath, fs.readFileSync(file, "utf8")));
    }
  }
  return findings;
}

module.exports = { scanClient, scanText, RULES, FIREBASE_OPTIONS };

if (require.main === module) {
  const findings = scanClient();
  if (findings.length) {
    for (const f of findings) console.error(`${f.file}:${f.line}: ${f.rule}`);
    console.error(`\n${findings.length} client AI key finding(s). Gemini must go through geminiGenerate.`);
    process.exit(1);
  }
  console.log(`No Gemini keys or direct Gemini URLs in ${SCAN_DIRS.join(", ")}.`);
}
