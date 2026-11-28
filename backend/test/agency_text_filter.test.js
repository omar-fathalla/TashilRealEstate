"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { containsContactInAgencyText, agencyTextFinding, RULES_FRAGMENTS } = require("../agency_text_filter");
const { agencyListingIdentity } = require("../listing_contact");
const { applicationFrom } = require("../agency_applications");
const { REFUSED, ALLOWED } = require("./fixtures/agency_text_cases");

const apply = (name) => applicationFrom({ name, countryCode: "AE", phone: "+97150000000" });

test("TAQ-201/207/209/212-237: the agency filter refuses every listed variant, as the kind it is", () => {
  for (const [text, kind] of REFUSED) {
    assert.equal(containsContactInAgencyText(text), true, text);
    assert.equal(agencyTextFinding(text).kind, kind, text);
  }
});

test("TAQ-201/208/209-237: legitimate agency names and about text still pass", () => {
  for (const text of ALLOWED) assert.equal(agencyTextFinding(text), null, text);
});

test("TAQ-208: applyForAgency says what it refused", () => {
  const reasons = { phone: "name_phone", link: "name_link" };
  for (const [text, kind] of REFUSED) {
    assert.throws(() => apply(text), (err) => err.details.reason === reasons[kind], text);
  }
  assert.throws(() => apply("St.Regis Homes"), (err) => err.details.reason === "name_link"
    && err.details.match === "st.regis" && /website address \("st\.regis"\)/.test(err.message));
  assert.throws(() => apply("Delta zero and five zero one two three four"), /looks like a phone number/);
  assert.throws(() => apply("Delta info@delta-homes.ae"), (err) => err.details.reason === "name_email");
  for (const text of ALLOWED.filter((t) => t.length <= 200)) assert.equal(apply(text).name, text.replace(/\s+/g, " "));
});

test("TAQ-207: such a name never reaches a listing; a clean locale is used instead", () => {
  assert.equal(agencyListingIdentity({ name: "Delta x.\u0645\u0635\u0631", names: { en: "Delta zero\u2013five\u2013zero\u2013one\u2013two\u2013three\u2013four" } }), null);
  const mixed = agencyListingIdentity({ name: "Delta x . c o m", names: { ar: "دلتا العقارية", en: "Delta x.c\u043em" } });
  assert.deepEqual(mixed.names, { ar: "دلتا العقارية", en: "دلتا العقارية", hi: "دلتا العقارية" });
  assert.equal(agencyListingIdentity({ name: "P.O.Box 12345 Realty" }).names.en, "P.O.Box 12345 Realty");
});

test("TAQ-207: firestore.rules agencyTextFree holds the server's word, ending and abbreviation lists verbatim", () => {
  const rules = fs.readFileSync(path.join(__dirname, "..", "..", "firestore.rules"), "utf8");
  const body = rules.slice(rules.indexOf("function agencyTextFree("), rules.indexOf("function agencyProfileOk("));
  for (const [name, fragment] of Object.entries(RULES_FRAGMENTS)) {
    assert.ok(body.includes(fragment), `${name} differs between agency_text_filter.js and firestore.rules`);
  }
});
