// TAQ-13: lease create/update rules (owner-created leases, locked parties, rent frozen after draft,
// tenant approval of lease offers).
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, deleteField } = require("firebase/firestore");

const RULES = path.join(__dirname, "../../firestore.rules");
let env;
const ctx = {};

const lease = (extra = {}) => ({
  owner_id: "ownerA",
  tenant_id: "tenantA",
  agency_id: "",
  property_id: "propA",
  status: "draft",
  country_code: "AE",
  monthly_rent: 5000,
  financialTerms: { monthlyRent: 5000 },
  start_date: "2026-01-01",
  end_date: "2026-12-31",
  ...extra,
});
const agencyLease = (extra = {}) => lease({ agency_id: "ag1", ...extra });

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test",
    firestore: { rules: fs.readFileSync(RULES, "utf8") },
  });
});
test.after(async () => {
  if (env) await env.cleanup();
});

async function seed(entries) {
  await env.withSecurityRulesDisabled(async (c) => {
    for (const [p, data] of Object.entries(entries)) await setDoc(doc(c.firestore(), p), data);
  });
}

test.beforeEach(async () => {
  await env.clearFirestore();
  await seed({
    "Users/ownerA": { role: "Owner" },
    "Users/ownerB": { role: "Owner" },
    "Users/tenantA": { role: "Tenant" },
    "Users/tenantB": { role: "Tenant" },
    "Users/investor1": { role: "Investor" },
    "Users/ownerA/properties/propA": { title: "Flat" },
    "Users/ownerB/properties/propB": { title: "Villa" },
  });
  const mk = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  ctx.ownerA = mk("ownerA");
  ctx.ownerB = mk("ownerB");
  ctx.tenantA = mk("tenantA");
  ctx.tenantB = mk("tenantB");
  ctx.investor = mk("investor1");
  ctx.ag1 = mk("ag1admin", { role: "AgencyAdmin", agency_id: "ag1" });
  ctx.ag2 = mk("ag2admin", { role: "AgencyAdmin", agency_id: "ag2" });
  ctx.admin = mk("admin1", { role: "Admin" });
  ctx.sa = mk("sa", { role: "SuperAdmin" });
  ctx.unauth = env.unauthenticatedContext().firestore();
});

const L = (db, id = "l1") => doc(db, `Leases/${id}`);

// --- owner-created leases ---

test("TAQ-13: an owner creates a lease for their own property, without an agency", async () => {
  await assertSucceeds(setDoc(L(ctx.ownerA), lease()));
  await assertSucceeds(setDoc(L(ctx.ownerA, "l2"), lease({ status: "pending_tenant_approval" })));
  const { agency_id, ...noAgencyKey } = lease();
  await assertSucceeds(setDoc(L(ctx.ownerA, "l3"), noAgencyKey));
});

test("TAQ-13: an owner cannot create a lease for another owner's property or in someone else's name", async () => {
  await assertFails(setDoc(L(ctx.ownerA), lease({ property_id: "propB" })), "property in another owner's silo");
  await assertFails(setDoc(L(ctx.ownerB), lease({ property_id: "propA" })), "someone else's property id");
  await assertFails(setDoc(L(ctx.ownerB), lease({ property_id: "propB" })), "owner_id is ownerA");
  await assertFails(setDoc(L(ctx.ownerA), lease({ property_id: "ghost" })), "property does not exist");
  await assertFails(setDoc(L(ctx.ownerA), lease({ property_id: "" })));
  const { property_id, ...noProperty } = lease();
  await assertFails(setDoc(L(ctx.ownerA), noProperty));
});

test("TAQ-13: an owner lease cannot carry an agency, miss a tenant, or lease to its owner", async () => {
  await assertFails(setDoc(L(ctx.ownerA), lease({ agency_id: "ag1" })), "owner naming an agency");
  await assertFails(setDoc(L(ctx.ownerA), lease({ tenant_id: "" })));
  await assertFails(setDoc(L(ctx.ownerA), lease({ tenant_id: 7 })));
  await assertFails(setDoc(L(ctx.ownerA), lease({ tenant_id: "ownerA" })));
  for (const status of ["active", "rejected", "expired", "terminated", "pending_signatures", "bogus", 3]) {
    await assertFails(setDoc(L(ctx.ownerA), lease({ status })), String(status));
  }
});

test("TAQ-13: tenants, investors, signed-out users and Admin cannot create leases", async () => {
  await assertFails(setDoc(L(ctx.tenantA), lease({ owner_id: "tenantA", tenant_id: "tenantB" })));
  await assertFails(setDoc(L(ctx.investor), lease({ owner_id: "investor1", property_id: "propA" })));
  await assertFails(setDoc(L(ctx.unauth), lease()));
  await assertFails(setDoc(L(ctx.admin), agencyLease()));
});

// --- agency scope ---

test("TAQ-13: an agency creates leases for itself only", async () => {
  await assertSucceeds(setDoc(L(ctx.ag1), agencyLease()));
  await assertFails(setDoc(L(ctx.ag2, "l2"), agencyLease()), "ag2 naming ag1");
  await assertFails(setDoc(L(ctx.ag1, "l3"), agencyLease({ tenant_id: "" })));
  await assertFails(setDoc(L(ctx.ag1, "l4"), agencyLease({ status: "terminated" })));
  await assertFails(setDoc(L(ctx.ag1, "l6"), agencyLease({ status: "active" })), "an agency cannot create an active lease");
  await assertSucceeds(setDoc(L(ctx.ag1, "l7"), agencyLease({ status: "pending_tenant_approval" })));
  await assertSucceeds(setDoc(L(ctx.sa, "l5"), agencyLease({ status: "terminated" })));
});

test("TAQ-13: cross-agency update, delete and read are denied", async () => {
  await seed({ "Leases/l1": agencyLease() });
  await assertFails(updateDoc(L(ctx.ag2), { notes: "x" }));
  await assertFails(updateDoc(L(ctx.ag2), { monthly_rent: 1 }));
  await assertFails(deleteDoc(L(ctx.ag2)));
  await assertFails(getDoc(L(ctx.ag2)));
  await assertSucceeds(updateDoc(L(ctx.ag1), { notes: "ok" }));
});

// --- locked parties ---

test("TAQ-13: tenant_id, owner_id, agency_id and property_id are locked after creation", async () => {
  await seed({ "Leases/l1": agencyLease(), "Leases/own": lease() });
  for (const [who, id, base] of [["ag1", "l1"], ["ownerA", "own"]]) {
    const db = ctx[who];
    for (const patch of [
      { tenant_id: "tenantB" },
      { owner_id: "ownerB" },
      { property_id: "propB" },
      { agency_id: "ag2" },
      { agency_id: "" },
      { agency_id: "ag1" },
    ]) {
      if (who === "ag1" && patch.agency_id === "ag1") continue;
      if (who === "ownerA" && patch.agency_id === "") continue;
      await assertFails(updateDoc(L(db, id), patch), `${who} ${JSON.stringify(patch)}`);
    }
    await assertFails(updateDoc(L(db, id), { tenant_id: deleteField() }), `${who} removing tenant_id`);
    await assertFails(updateDoc(L(db, id), { property_id: deleteField() }), `${who} removing property_id`);
  }
  await assertFails(setDoc(L(ctx.ag1), agencyLease({ tenant_id: "tenantB" })), "overwrite with another tenant");
  await assertSucceeds(updateDoc(L(ctx.sa), { tenant_id: "tenantB" }), "SuperAdmin keeps break-glass");
});

test("TAQ-13: the tenant, a stranger and the other owner cannot touch a lease", async () => {
  await seed({ "Leases/l1": lease() });
  await assertSucceeds(getDoc(L(ctx.tenantA)));
  await assertFails(updateDoc(L(ctx.tenantA), { status: "active" }), "a draft is not up for decision");
  await assertFails(updateDoc(L(ctx.tenantA), { monthly_rent: 1 }));
  await assertFails(updateDoc(L(ctx.ownerB), { notes: "x" }));
  await assertFails(deleteDoc(L(ctx.tenantA)));
  await assertFails(getDoc(L(ctx.ownerB)));
  await assertFails(getDoc(L(ctx.tenantB)));
});

test("TAQ-13: an owner cannot edit a lease an agency manages", async () => {
  await seed({ "Leases/l1": agencyLease() });
  await assertSucceeds(getDoc(L(ctx.ownerA)));
  await assertFails(updateDoc(L(ctx.ownerA), { monthly_rent: 1 }));
  await assertFails(updateDoc(L(ctx.ownerA), { status: "pending_tenant_approval" }));
  await assertFails(deleteDoc(L(ctx.ownerA)));
});

// --- rent frozen after draft ---

test("TAQ-13: rent and dates change only while the lease is a draft", async () => {
  await seed({ "Leases/own": lease(), "Leases/ag": agencyLease() });
  for (const [db, id] of [[ctx.ownerA, "own"], [ctx.ag1, "ag"]]) {
    await assertSucceeds(updateDoc(L(db, id), { monthly_rent: 5200, financialTerms: { monthlyRent: 5200 }, start_date: "2026-02-01", end_date: "2027-01-31" }));
    await assertSucceeds(updateDoc(L(db, id), { status: "pending_tenant_approval" }), "sending the offer with terms already final");
    for (const patch of [
      { monthly_rent: 1 },
      { financialTerms: { monthlyRent: 1 } },
      { start_date: "2020-01-01" },
      { end_date: "2099-01-01" },
      { country_code: "EG" },
      { baseAmount: 1 },
      { status: "terminated", monthly_rent: 1 },
    ]) {
      await assertFails(updateDoc(L(db, id), patch), JSON.stringify(patch));
    }
  }
});

test("TAQ-13: draft to pending may change terms in the same write; terms stay locked from then on", async () => {
  await seed({ "Leases/own": lease() });
  await assertSucceeds(updateDoc(L(ctx.ownerA, "own"), { status: "pending_tenant_approval", monthly_rent: 5100, financialTerms: { monthlyRent: 5100 } }));
  await assertFails(updateDoc(L(ctx.ownerA, "own"), { monthly_rent: 5200 }));
});

// --- the tenant's decision ---

const decision = (status, extra = {}) => ({ status, updated_at: "2026-06-01", ...extra });

test("TAQ-13: owners and agencies cannot activate or reject a lease; only the tenant can", async () => {
  await seed({ "Leases/own": lease(), "Leases/ag": agencyLease(), "Leases/pown": lease({ status: "pending_tenant_approval" }), "Leases/pag": agencyLease({ status: "pending_tenant_approval" }) });
  for (const id of ["own", "pown"]) {
    for (const status of ["active", "rejected"]) await assertFails(updateDoc(L(ctx.ownerA, id), { status }), `owner ${id} -> ${status}`);
  }
  for (const id of ["ag", "pag"]) {
    for (const status of ["active", "rejected"]) await assertFails(updateDoc(L(ctx.ag1, id), { status }), `agency ${id} -> ${status}`);
  }
  await assertFails(updateDoc(L(ctx.ownerA, "own"), { status: "active", monthly_rent: 1 }));
});

test("TAQ-13: the tenant approves or rejects a pending lease, and only the decision fields change", async () => {
  await seed({ "Leases/a": lease({ status: "pending_tenant_approval" }), "Leases/r": lease({ status: "pending_tenant_approval" }), "Leases/n": lease({ status: "pending_tenant_approval" }) });
  await assertSucceeds(updateDoc(L(ctx.tenantA, "a"), decision("active")));
  await assertSucceeds(updateDoc(L(ctx.tenantA, "r"), decision("rejected", { tenant_decision_note: "Rent is too high" })));
  await assertSucceeds(updateDoc(L(ctx.tenantA, "n"), { status: "active" }));
  for (const bad of [
    decision("active", { monthly_rent: 1 }),
    decision("active", { financialTerms: { monthlyRent: 1 } }),
    decision("active", { start_date: "2020-01-01" }),
    decision("active", { end_date: "2099-01-01" }),
    decision("active", { notes: "x" }),
    decision("active", { tenant_id: "tenantB" }),
    decision("active", { owner_id: "tenantA" }),
    decision("active", { agency_id: "ag1" }),
    decision("active", { property_id: "propB" }),
    decision("active", { tenant_decision_note: "x".repeat(501) }),
    decision("active", { tenant_decision_note: 5 }),
    decision("active", { extra_field: 1 }),
  ]) {
    await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }) });
    await assertFails(updateDoc(L(ctx.tenantA, "p"), bad), JSON.stringify(bad));
  }
});

test("TAQ-13: the tenant decides only while pending, and only to active or rejected", async () => {
  await seed({
    "Leases/d": lease(),
    "Leases/a": lease({ status: "active" }),
    "Leases/e": lease({ status: "expired" }),
    "Leases/t": lease({ status: "terminated" }),
    "Leases/x": lease({ status: "rejected" }),
    "Leases/p": lease({ status: "pending_tenant_approval" }),
  });
  for (const id of ["d", "a", "e", "t", "x"]) {
    for (const status of ["active", "rejected", "terminated", "draft"]) {
      await assertFails(updateDoc(L(ctx.tenantA, id), decision(status)), `tenant ${id} -> ${status}`);
    }
  }
  for (const status of ["draft", "terminated", "expired", "pending_tenant_approval", "bogus"]) {
    await assertFails(updateDoc(L(ctx.tenantA, "p"), decision(status)), `tenant pending -> ${status}`);
  }
  await assertFails(updateDoc(L(ctx.tenantA, "p"), { updated_at: "2026-06-01" }), "no decision at all");
});

test("TAQ-13: only the lease's own tenant decides; other tenants, owners, agencies and strangers cannot", async () => {
  await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }), "Leases/pa": agencyLease({ status: "pending_tenant_approval" }) });
  for (const who of ["tenantB", "ownerB", "investor", "ag2", "admin", "unauth"]) {
    await assertFails(updateDoc(L(ctx[who], "p"), decision("active")), who);
    await assertFails(updateDoc(L(ctx[who], "pa"), decision("rejected")), who);
  }
  await assertSucceeds(updateDoc(L(ctx.tenantA, "pa"), decision("active")), "tenant of an agency lease");
});

test("TAQ-13: a tenant who is also the owner of the lease cannot approve their own offer", async () => {
  await seed({ "Leases/self": lease({ owner_id: "tenantA", tenant_id: "tenantA", status: "pending_tenant_approval" }) });
  await assertFails(updateDoc(L(ctx.tenantA, "self"), decision("active")));
});

test("TAQ-13: after the decision, the tenant cannot change anything and terms stay locked", async () => {
  await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }) });
  await assertSucceeds(updateDoc(L(ctx.tenantA, "p"), decision("active")));
  await assertFails(updateDoc(L(ctx.tenantA, "p"), decision("rejected")), "cannot flip an active lease");
  await assertFails(updateDoc(L(ctx.tenantA, "p"), { notes: "x" }));
  await assertFails(updateDoc(L(ctx.ownerA, "p"), { monthly_rent: 1 }), "owner cannot edit rent on the now-active lease");
  await assertSucceeds(updateDoc(L(ctx.ownerA, "p"), { status: "terminated" }));
});

test("TAQ-13: a rejected lease is final; the owner starts a new draft instead", async () => {
  await seed({ "Leases/x": lease({ status: "rejected" }) });
  for (const status of ["draft", "pending_tenant_approval", "active", "terminated"]) {
    await assertFails(updateDoc(L(ctx.ownerA, "x"), { status }), `rejected -> ${status}`);
  }
  await assertFails(updateDoc(L(ctx.ownerA, "x"), { monthly_rent: 1 }));
  await assertSucceeds(updateDoc(L(ctx.ownerA, "x"), { notes: "tenant declined" }));
});

test("TAQ-13: an active lease allows only status moves forward, notes and updated_at", async () => {
  await seed({ "Leases/own": lease({ status: "active" }), "Leases/ag": agencyLease({ status: "active" }) });
  for (const [db, id] of [[ctx.ownerA, "own"], [ctx.ag1, "ag"]]) {
    await assertSucceeds(updateDoc(L(db, id), { notes: "paid by cheque", updated_at: "2026-06-01" }));
    for (const status of ["draft", "pending_tenant_approval", "rejected", "pending_signatures", "bogus"]) {
      await assertFails(updateDoc(L(db, id), { status }), `active -> ${status}`);
    }
  }
  await assertSucceeds(updateDoc(L(ctx.ownerA, "own"), { status: "expired" }));
  await assertSucceeds(updateDoc(L(ctx.ag1, "ag"), { status: "terminated" }));
});

test("TAQ-13: expired and terminated leases are final; an owner cannot unlock terms by walking status back", async () => {
  await seed({ "Leases/e": lease({ status: "expired" }), "Leases/t": lease({ status: "terminated" }) });
  for (const id of ["e", "t"]) {
    await assertFails(updateDoc(L(ctx.ownerA, id), { status: "active" }));
    await assertFails(updateDoc(L(ctx.ownerA, id), { status: "draft" }));
    await assertFails(updateDoc(L(ctx.ownerA, id), { monthly_rent: 1 }));
    await assertSucceeds(updateDoc(L(ctx.ownerA, id), { notes: "closed out" }));
  }
});

test("TAQ-13: a pending lease locks terms; the owner can pull it back to draft to edit, or terminate it", async () => {
  await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }), "Leases/q": lease({ status: "pending_tenant_approval" }) });
  await assertFails(updateDoc(L(ctx.ownerA, "p"), { monthly_rent: 1 }));
  await assertSucceeds(updateDoc(L(ctx.ownerA, "p"), { status: "draft" }));
  await assertSucceeds(updateDoc(L(ctx.ownerA, "p"), { monthly_rent: 4800 }));
  await assertSucceeds(updateDoc(L(ctx.ownerA, "q"), { status: "terminated" }));
});

test("TAQ-13: SuperAdmin keeps break-glass over lease status", async () => {
  await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }) });
  await assertSucceeds(updateDoc(L(ctx.sa, "p"), { status: "active" }));
});

test("TAQ-13: a lease with no status counts as a draft (older documents)", async () => {
  const { status, ...legacy } = lease();
  await seed({ "Leases/old": legacy });
  await assertSucceeds(updateDoc(L(ctx.ownerA, "old"), { monthly_rent: 5300 }));
});

// --- delete ---

test("TAQ-13: an owner deletes their own draft lease only; the agency and SuperAdmin keep delete", async () => {
  await seed({ "Leases/d": lease(), "Leases/a": lease({ status: "active" }), "Leases/g": agencyLease() });
  await assertSucceeds(deleteDoc(L(ctx.ownerA, "d")));
  await assertFails(deleteDoc(L(ctx.ownerA, "a")));
  await assertFails(deleteDoc(L(ctx.tenantA, "a")));
  await assertSucceeds(deleteDoc(L(ctx.ag1, "g")));
  await assertSucceeds(deleteDoc(L(ctx.sa, "a")));
});

test("TAQ-13: only lease parties and SuperAdmin read leases (unchanged)", async () => {
  await seed({ "Leases/l1": agencyLease() });
  for (const who of ["ownerA", "tenantA", "ag1", "sa"]) await assertSucceeds(getDoc(L(ctx[who])), who);
  for (const who of ["ownerB", "tenantB", "ag2", "admin", "investor", "unauth"]) await assertFails(getDoc(L(ctx[who])), who);
});
