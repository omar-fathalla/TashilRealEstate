"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { containsContactInAgencyText } = require("../agency_text_filter");
const { agencyListingIdentity } = require("../listing_contact");
const { REFUSED, ALLOWED } = require("./fixtures/agency_text_cases");

test("TAQ-201: the agency filter refuses the variants the request filter lets through", () => {
  for (const text of REFUSED) assert.equal(containsContactInAgencyText(text), true, text);
});

test("TAQ-201: legitimate agency names and about text still pass", () => {
  for (const text of ALLOWED) assert.equal(containsContactInAgencyText(text), false, text);
});

test("TAQ-201: such a name never reaches a listing; a clean locale is used instead", () => {
  assert.equal(agencyListingIdentity({ name: "Delta x.shop", names: { en: "Delta 0 five 0 one 2 three 4" } }), null);
  const mixed = agencyListingIdentity({ name: "Delta x.Me", names: { ar: "دلتا العقارية", en: "Delta x\u3002com" } });
  assert.deepEqual(mixed.names, { ar: "دلتا العقارية", en: "دلتا العقارية", hi: "دلتا العقارية" });
});
