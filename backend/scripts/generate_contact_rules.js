// Rewrites the generated contact-pattern block in firestore.rules from contact_patterns.js.
//   node scripts/generate_contact_rules.js          -> rewrite the file
//   node scripts/generate_contact_rules.js --check  -> exit 1 if the file is out of date
const fs = require("fs");
const path = require("path");
const {
  NORMALIZE_STEPS,
  MERGE_STEPS,
  rulesPhonePatterns,
  rulesLinkPatterns,
  LINK_INVISIBLE,
  escapeRulesLiteral,
} = require("../contact_patterns");

const RULES_PATH = path.join(__dirname, "../../firestore.rules");
const BEGIN = "    // BEGIN GENERATED contact patterns\n";
const END = "    // END GENERATED contact patterns\n";

const literal = (text) => `'${escapeRulesLiteral(text)}'`;
const replaces = (steps) => steps.map(([pattern, replacement]) => `.replace(${literal(pattern)}, ${literal(replacement)})`);

function generatedBlock() {
  const phones = rulesPhonePatterns();
  const checks = [
    ...phones.map((pattern) => `t.matches(${literal(pattern)})`),
    ...phones.map((pattern) => `m.matches(${literal(pattern)})`),
  ];
  const linkChecks = rulesLinkPatterns().map((pattern) => `!l.matches(${literal(pattern)})`);
  return `${BEGIN}    function contactPhone(text) {
      let t = text
        ${replaces(NORMALIZE_STEPS).join("\n        ")};
      let m = t
        ${replaces(MERGE_STEPS).join("\n        ")};
      return ${checks.join("\n        || ")};
    }

    function contactLinkFree(text) {
      let l = text.replace(${literal(LINK_INVISIBLE)}, '');
      return ${linkChecks.join("\n        && ")};
    }
${END}`;
}

function rewrite(source) {
  const start = source.indexOf(BEGIN);
  const end = source.indexOf(END);
  if (start < 0 || end < start) throw new Error("contact pattern markers not found in firestore.rules");
  return source.slice(0, start) + generatedBlock() + source.slice(end + END.length);
}

if (require.main === module) {
  const current = fs.readFileSync(RULES_PATH, "utf8");
  const next = rewrite(current);
  if (process.argv.includes("--check")) {
    if (next !== current) {
      console.error("firestore.rules contact patterns are out of date: run `npm run gen:contact-rules` in backend/.");
      process.exit(1);
    }
  } else {
    fs.writeFileSync(RULES_PATH, next);
  }
}

module.exports = { generatedBlock, rewrite };
