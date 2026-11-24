const fs = require("fs");
const path = require("path");
const test = require("node:test");
const assert = require("node:assert/strict");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  getDocs,
  serverTimestamp,
} = require("firebase/firestore");

// TAQ-91: the Admin (platform staff) and Investor roles in firestore.rules.

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test",
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

const CLAIMS = {
  admin: { role: "Admin" },
  superAdmin: { role: "SuperAdmin" },
  investor: { role: "Investor" },
  owner: { role: "Owner" },
  agency: { role: "AgencyAdmin", agency_id: "agency-1" },
};

function as(uid, claims) {
  return testEnv.authenticatedContext(uid, claims || {}).firestore();
}

async function seed(docPath, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), docPath), data);
  });
}

const live = {
  id: "live",
  owner_id: "ownerA",
  countryCode: "AE",
  currencyCode: "AED",
  titles: { ar: "شقة", en: "Apartment", hi: "अपार्टमेंट" },
  pricePerMonth: 9000,
  status: "vacant",
  is_published: true,
};

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed("Users/ownerA", { user_id: "ownerA", role: "Owner", email: "a@x.test", iban: "AE070331234567890123456", national_id: "784-1990-1234567-1" });
  await seed("Users/ownerA/properties/live", { owner_id: "ownerA", tenant_name: "Private Tenant" });
  await seed("Users/investor1", { user_id: "investor1", role: "Investor" });
  await seed("Users/admin1", { user_id: "admin1", role: "Admin" });
  await seed("Properties/live", live);
  await seed("Properties/hidden", { ...live, id: "hidden", is_published: false, moderation_hidden: true });
  await seed("Properties/rented", { ...live, id: "rented", is_published: false, moderation_hidden: true, status: "rented" });
  await seed("Properties/draft", { ...live, id: "draft", is_published: false, status: "unavailable" });
  await seed("Agencies/agency-1", { name: "Agency One", verified_badge: false });
  await seed("Agencies/agency-1/private/bank", { iban: "AE070331234567890123456" });
  await seed("Leases/lease-1", { owner_id: "ownerA", tenant_id: "tenantA", agency_id: "agency-1" });
  await seed("Invoices/inv-1", { owner_id: "ownerA", tenant_id: "tenantA", agency_id: "agency-1" });
  await seed("Maintenance/m-1", { owner_id: "ownerA", tenant_id: "tenantA", agency_id: "agency-1", status: "open", title: "Leak" });
  await seed("Telemetry_Crashes/c-1", { message: "boom", isFatal: false, platform: "web" });
  await seed("AiRateLimits/uid_x", { minuteCount: 1 });
});

// --- Investor: signup and no escalation ---

test("TAQ-91: signup can pick Owner, Tenant or Investor, and nothing above them", async () => {
  for (const role of ["Owner", "Tenant", "Investor"]) {
    await assertSucceeds(setDoc(doc(as(`new-${role}`), `Users/new-${role}`), { user_id: `new-${role}`, role }));
  }
  for (const role of ["Admin", "SuperAdmin", "AgencyAdmin", "investor", "Broker", ""]) {
    await assertFails(setDoc(doc(as("mallory"), "Users/mallory"), { user_id: "mallory", role }));
  }
});

test("TAQ-91: an Investor cannot change their role, add an agency or flag themselves verified", async () => {
  const me = as("investor1");
  for (const role of ["Owner", "Tenant", "Admin", "SuperAdmin", "AgencyAdmin"]) {
    await assertFails(updateDoc(doc(me, "Users/investor1"), { role }));
  }
  await assertFails(updateDoc(doc(me, "Users/investor1"), { agency_id: "agency-1" }));
  await assertFails(updateDoc(doc(me, "Users/investor1"), { verified: true }));
  await assertSucceeds(updateDoc(doc(me, "Users/investor1"), { full_name: "Inv Estor" }));
});

test("TAQ-91: a profile that says Admin grants nothing without the claim", async () => {
  const me = as("admin1");
  await assertFails(updateDoc(doc(me, "Properties/live"), { verified: true, updated_at: serverTimestamp() }));
  await assertFails(getDoc(doc(me, "Properties/draft")));
  await assertFails(getDoc(doc(me, "Telemetry_Crashes/c-1")));
});

test("TAQ-91: a claimed Investor is an Investor even if the profile says Owner", async () => {
  await seed("Users/mixed", { role: "Owner" });
  const me = as("mixed", CLAIMS.investor);
  await assertFails(setDoc(doc(me, "Users/mixed/properties/p1"), { owner_id: "mixed" }));
});

// --- Investor: what they can and cannot reach ---

test("TAQ-91: an Investor reads published listings, agencies and nothing private", async () => {
  const me = as("investor1", CLAIMS.investor);
  await assertSucceeds(getDoc(doc(me, "Properties/live")));
  await assertSucceeds(getDocs(query(collection(me, "Properties"), where("is_published", "==", true))));
  await assertSucceeds(getDoc(doc(me, "Agencies/agency-1")));
  await assertSucceeds(getDoc(doc(me, "Users/investor1")));
  await assertFails(getDoc(doc(me, "Properties/draft")));
  await assertFails(getDoc(doc(me, "Properties/hidden")));
  await assertFails(getDocs(query(collection(me, "Properties"), where("is_published", "==", false))));
  await assertFails(getDoc(doc(me, "Users/ownerA")));
  await assertFails(getDoc(doc(me, "Users/ownerA/properties/live")));
  await assertFails(getDoc(doc(me, "Agencies/agency-1/private/bank")));
});

test("TAQ-91: an Investor has no access to leases, invoices, maintenance, telemetry or quotas", async () => {
  for (const claims of [CLAIMS.investor, undefined]) {
    const me = as("investor1", claims);
    await assertFails(getDoc(doc(me, "Leases/lease-1")));
    await assertFails(getDocs(collection(me, "Leases")));
    await assertFails(getDoc(doc(me, "Invoices/inv-1")));
    await assertFails(getDoc(doc(me, "Maintenance/m-1")));
    await assertFails(getDocs(collection(me, "Maintenance")));
    await assertFails(getDoc(doc(me, "Telemetry_Crashes/c-1")));
    await assertFails(getDoc(doc(me, "AiRateLimits/uid_x")));
  }
});

test("TAQ-91: an Investor cannot publish, edit or delete listings, nor create private drafts", async () => {
  for (const claims of [CLAIMS.investor, undefined]) {
    const me = as("investor1", claims);
    await assertFails(setDoc(doc(me, "Properties/inv-listing"), { ...live, id: "inv-listing", owner_id: "investor1" }));
    await assertFails(updateDoc(doc(me, "Properties/live"), { pricePerMonth: 1 }));
    await assertFails(deleteDoc(doc(me, "Properties/live")));
    await assertFails(setDoc(doc(me, "Users/investor1/properties/p1"), { owner_id: "investor1", isPublished: true }));
  }
});

test("TAQ-91: an Investor cannot create leases, invoices, maintenance requests or agencies", async () => {
  const me = as("investor1", CLAIMS.investor);
  await assertFails(setDoc(doc(me, "Leases/l2"), { owner_id: "investor1", tenant_id: "investor1", agency_id: "agency-1" }));
  await assertFails(setDoc(doc(me, "Invoices/i2"), { owner_id: "investor1" }));
  await assertFails(setDoc(doc(me, "Maintenance/m2"), { tenant_id: "investor1", status: "open" }));
  await assertFails(setDoc(doc(me, "Agencies/agency-x"), { name: "Mine" }));
});

// --- Admin: moderation ---

test("TAQ-91: an Admin can see every listing, including unpublished and hidden ones", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const id of ["live", "hidden", "rented", "draft"]) await assertSucceeds(getDoc(doc(me, `Properties/${id}`)));
  await assertSucceeds(getDocs(query(collection(me, "Properties"), where("is_published", "==", false))));
});

test("TAQ-91: an Admin can verify, unverify, hide and unpublish a listing", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { verified: true, updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { verified: false, updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { is_published: false, updated_at: serverTimestamp() }));
  await seed("Properties/live", live);
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { is_published: false, moderation_hidden: true, updated_at: serverTimestamp() }));
});

test("TAQ-91: an Admin can restore a hidden vacant listing, but only by clearing the hidden flag", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(updateDoc(doc(me, "Properties/hidden"), { is_published: true, updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(me, "Properties/hidden"), { is_published: true, moderation_hidden: false, updated_at: serverTimestamp() }));
});

test("TAQ-91: an Admin cannot resurrect a listing its owner took down, rented out or never published", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(updateDoc(doc(me, "Properties/rented"), { is_published: true, moderation_hidden: false, updated_at: serverTimestamp() }));
  await assertFails(updateDoc(doc(me, "Properties/draft"), { is_published: true, moderation_hidden: false, updated_at: serverTimestamp() }));
  await assertFails(updateDoc(doc(me, "Properties/live"), { moderation_hidden: true, updated_at: serverTimestamp() }));
});

test("TAQ-91: an Admin cannot edit listing content, ownership or ratings, create or delete listings", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const change of [
    { pricePerMonth: 1 },
    { owner_id: "admin1" },
    { agency_id: "agency-1" },
    { rating: 5 },
    { isFeatured: true },
    { titles: { en: "Hacked" } },
    { status: "rented" },
    { verified: "yes" },
    { phone: "+201001234567" },
  ]) {
    await assertFails(updateDoc(doc(me, "Properties/live"), { ...change, updated_at: serverTimestamp() }));
  }
  await assertFails(updateDoc(doc(me, "Properties/live"), { verified: true, updated_at: new Date(0) }));
  await assertFails(setDoc(doc(me, "Properties/admin-made"), { ...live, id: "admin-made" }));
  await assertFails(deleteDoc(doc(me, "Properties/live")));
  await assertFails(deleteDoc(doc(me, "Properties/draft")));
});

// --- Admin: users and agencies are read-only and never expose IBAN or national ID ---

test("TAQ-91: an Admin cannot read user profiles or owner private data (IBAN, national ID)", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(getDoc(doc(me, "Users/ownerA")));
  await assertFails(getDocs(collection(me, "Users")));
  await assertFails(getDoc(doc(me, "Users/ownerA/properties/live")));
  await assertFails(getDocs(collection(me, "Users/ownerA/properties")));
  await assertFails(getDoc(doc(me, "Agencies/agency-1/private/bank")));
  await assertSucceeds(getDoc(doc(me, "Users/admin1")));
});

test("TAQ-91: an Admin cannot create, edit or delete users, or write any role or claim field", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(updateDoc(doc(me, "Users/ownerA"), { full_name: "x" }));
  await assertFails(updateDoc(doc(me, "Users/ownerA"), { role: "SuperAdmin" }));
  await assertFails(deleteDoc(doc(me, "Users/ownerA")));
  await assertFails(setDoc(doc(me, "Users/newcomer"), { user_id: "newcomer", role: "SuperAdmin" }));
  await assertFails(setDoc(doc(me, "Users/newcomer"), { user_id: "newcomer", role: "Admin" }));
  await assertFails(setDoc(doc(me, "Users/newcomer"), { user_id: "newcomer", role: "Owner" }));
});

test("TAQ-91: an Admin cannot escalate itself", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const change of [
    { role: "SuperAdmin" },
    { role: "AgencyAdmin" },
    { role: "Owner" },
    { agency_id: "agency-1" },
    { isSuperAdmin: true },
    { customClaims: { role: "SuperAdmin" } },
    { claims: { role: "SuperAdmin" } },
    { Role: "SuperAdmin" },
    { verified: true },
  ]) {
    await assertFails(updateDoc(doc(me, "Users/admin1"), change));
  }
  await assertFails(setDoc(doc(me, "Users/admin1"), { user_id: "admin1", role: "SuperAdmin" }));
  await assertFails(deleteDoc(doc(me, "Users/admin1")));
});

test("TAQ-91: an Admin can read agencies but cannot create, edit, verify or delete them", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(getDoc(doc(me, "Agencies/agency-1")));
  await assertFails(setDoc(doc(me, "Agencies/agency-2"), { name: "New" }));
  await assertFails(updateDoc(doc(me, "Agencies/agency-1"), { name: "Renamed" }));
  await assertFails(updateDoc(doc(me, "Agencies/agency-1"), { verified_badge: true }));
  await assertFails(deleteDoc(doc(me, "Agencies/agency-1")));
  await assertFails(setDoc(doc(me, "Agencies/agency-1/private/bank"), { iban: "x" }));
});

// --- Admin: leases, payments, settings ---

test("TAQ-91: an Admin has no access to leases, invoices or rate-limit counters", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertFails(getDoc(doc(me, "Leases/lease-1")));
  await assertFails(getDocs(collection(me, "Leases")));
  await assertFails(setDoc(doc(me, "Leases/l2"), { owner_id: "x", agency_id: "agency-1" }));
  await assertFails(updateDoc(doc(me, "Leases/lease-1"), { tenant_id: "admin1" }));
  await assertFails(deleteDoc(doc(me, "Leases/lease-1")));
  await assertFails(getDoc(doc(me, "Invoices/inv-1")));
  await assertFails(setDoc(doc(me, "Invoices/i2"), { owner_id: "x" }));
  await assertFails(getDoc(doc(me, "AiRateLimits/uid_x")));
  await assertFails(setDoc(doc(me, "AiRateLimits/uid_x"), { minuteCount: 0 }));
});

test("TAQ-91: an Admin gets nothing from collections the rules do not name (settings, config, secrets)", async () => {
  const me = as("admin1", CLAIMS.admin);
  for (const p of ["Settings/system", "RemoteConfig/app", "Config/payments", "PaymentConfig/gateway", "Secrets/gemini", "MarketIndices/EG"]) {
    await assertFails(getDoc(doc(me, p)));
    await assertFails(setDoc(doc(me, p), { value: 1 }));
  }
});

// --- Admin: reports and maintenance escalations ---

test("TAQ-91: an Admin can read crash reports but not change or delete them", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(getDoc(doc(me, "Telemetry_Crashes/c-1")));
  await assertSucceeds(getDocs(collection(me, "Telemetry_Crashes")));
  await assertFails(updateDoc(doc(me, "Telemetry_Crashes/c-1"), { message: "x" }));
  await assertFails(deleteDoc(doc(me, "Telemetry_Crashes/c-1")));
});

test("TAQ-91: an Admin can read and escalate maintenance requests, and only change the escalation fields", async () => {
  const me = as("admin1", CLAIMS.admin);
  await assertSucceeds(getDoc(doc(me, "Maintenance/m-1")));
  await assertSucceeds(getDocs(collection(me, "Maintenance")));
  await assertSucceeds(updateDoc(doc(me, "Maintenance/m-1"), { status: "escalated", escalated: true, resolution_note: "Sent to agency", updated_at: serverTimestamp() }));
  await assertFails(updateDoc(doc(me, "Maintenance/m-1"), { tenant_id: "admin1" }));
  await assertFails(updateDoc(doc(me, "Maintenance/m-1"), { owner_id: "admin1" }));
  await assertFails(updateDoc(doc(me, "Maintenance/m-1"), { title: "Rewritten" }));
  await assertFails(deleteDoc(doc(me, "Maintenance/m-1")));
  await assertFails(setDoc(doc(me, "Maintenance/m2"), { tenant_id: "admin1", status: "open" }));
});

test("TAQ-91: maintenance requests stay with their parties and staff", async () => {
  await assertSucceeds(getDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/m-1")));
  await assertSucceeds(getDoc(doc(as("ownerA", CLAIMS.owner), "Maintenance/m-1")));
  await assertSucceeds(getDoc(doc(as("agent", CLAIMS.agency), "Maintenance/m-1")));
  await assertSucceeds(getDoc(doc(as("root", CLAIMS.superAdmin), "Maintenance/m-1")));
  await assertFails(getDoc(doc(as("stranger", CLAIMS.owner), "Maintenance/m-1")));
  await assertFails(getDoc(doc(as("stranger", { role: "Tenant" }), "Maintenance/m-1")));
  await assertFails(getDoc(doc(as("stranger"), "Maintenance/m-1")));
  await assertSucceeds(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/m2"), { tenant_id: "tenantA", owner_id: "ownerA", status: "open" }));
  await assertFails(setDoc(doc(as("tenantA", { role: "Tenant" }), "Maintenance/m3"), { tenant_id: "someoneElse", status: "open" }));
});

// --- SuperAdmin keeps full access ---

test("TAQ-91: a SuperAdmin still has full access", async () => {
  const me = as("root", CLAIMS.superAdmin);
  await assertSucceeds(getDoc(doc(me, "Users/ownerA")));
  await assertSucceeds(getDoc(doc(me, "Leases/lease-1")));
  await assertSucceeds(getDoc(doc(me, "Agencies/agency-1/private/bank")));
  await assertSucceeds(getDoc(doc(me, "Telemetry_Crashes/c-1")));
  await assertSucceeds(updateDoc(doc(me, "Agencies/agency-1"), { verified_badge: true }));
  await assertSucceeds(updateDoc(doc(me, "Properties/live"), { rating: 4, isFeatured: true, verified: true, updated_at: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(me, "Maintenance/m-1"), { title: "Changed" }));
});

test("TAQ-91: Owner, Tenant and AgencyAdmin behaviour is unchanged", async () => {
  const owner = as("ownerA", CLAIMS.owner);
  await assertSucceeds(getDoc(doc(owner, "Users/ownerA/properties/live")));
  await assertSucceeds(setDoc(doc(owner, "Users/ownerA/properties/p2"), { owner_id: "ownerA" }));
  await assertFails(getDoc(doc(as("tenantA", { role: "Tenant" }), "Leases/lease-2")));
  await assertSucceeds(getDoc(doc(as("tenantA", { role: "Tenant" }), "Leases/lease-1")));
  await assertSucceeds(getDoc(doc(as("agent", CLAIMS.agency), "Leases/lease-1")));
});
