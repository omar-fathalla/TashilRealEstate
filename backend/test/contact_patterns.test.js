const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const { rewrite } = require("../scripts/generate_contact_rules");
const { rulesPhonePatterns } = require("../contact_patterns");

test("firestore.rules holds the contact patterns generated from contact_patterns.js", () => {
  const source = fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8");
  assert.equal(rewrite(source), source, "run `npm run gen:contact-rules` in backend/");
});

test("each generated phone pattern fits the rules' 4096-character regex limit", () => {
  for (const pattern of rulesPhonePatterns()) {
    assert.ok(pattern.length < 4096, `pattern of ${pattern.length} characters`);
  }
});
