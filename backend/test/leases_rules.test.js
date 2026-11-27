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

// --- creation: callable only, SuperAdmin break-glass as a draft or offer ---

test("TAQ-110: owners, agencies, tenants and everyone else cannot create leases directly", async () => {
  for (const status of ["draft", "pending_tenant_approval", "active"]) {
    await assertFails(setDoc(L(ctx.ownerA), lease({ status })), `owner ${status}`);
    await assertFails(setDoc(L(ctx.ag1), agencyLease({ status })), `agency ${status}`);
    await assertFails(setDoc(L(ctx.tenantA), lease({ status })), `tenant ${status}`);
  }
  await assertFails(setDoc(L(ctx.tenantA), lease({ owner_id: "tenantA", tenant_id: "tenantB" })));
  await assertFails(setDoc(L(ctx.investor), lease({ owner_id: "investor1", property_id: "propA" })));
  await assertFails(setDoc(L(ctx.unauth), lease()));
  await assertFails(setDoc(L(ctx.admin), agencyLease()));
});

test("TAQ-110: SuperAdmin creates only a draft or an offer, with parties, rent > 0 and valid dates", async () => {
  await assertSucceeds(setDoc(L(ctx.sa, "d"), lease()));
  await assertSucceeds(setDoc(L(ctx.sa, "p"), agencyLease({ status: "pending_tenant_approval" })));
  const { monthly_rent, ...annualOnly } = lease({ financialTerms: { annualRent: 60000 } });
  await assertSucceeds(setDoc(L(ctx.sa, "an"), annualOnly), "annual rent only");
  for (const status of ["active", "expired", "terminated", "rejected", "pending_signatures", "bogus", 3]) {
    await assertFails(setDoc(L(ctx.sa, "x"), lease({ status })), `SuperAdmin create ${status}`);
  }
  const { status, ...noStatus } = lease();
  await assertFails(setDoc(L(ctx.sa, "x"), noStatus), "no status");
  for (const bad of [
    { tenant_id: "" }, { tenant_id: 7 }, { tenant_id: "ownerA" }, { owner_id: "" }, { property_id: "" }, { agency_id: 5 },
    { start_date: "2026-13-01" }, { start_date: "2026/01/01" }, { end_date: "2025-12-31" }, { end_date: "2026-01-01" }, { start_date: 20260101 },
  ]) {
    await assertFails(setDoc(L(ctx.sa, "x"), lease(bad)), JSON.stringify(bad));
  }
  const { property_id, ...noProperty } = lease();
  await assertFails(setDoc(L(ctx.sa, "x"), noProperty), "no property");
  const { start_date, ...noStart } = lease();
  await assertFails(setDoc(L(ctx.sa, "x"), noStart), "no start date");
});

test("TAQ-110: rent <= 0, NaN, Infinity, a string or no rent at all fails on create", async () => {
  for (const bad of [0, -1, NaN, Infinity, -Infinity, "5000", 1e10]) {
    await assertFails(setDoc(L(ctx.sa, "x"), lease({ monthly_rent: bad })), `monthly_rent ${bad}`);
    await assertFails(setDoc(L(ctx.sa, "x"), lease({ financialTerms: { monthlyRent: bad } })), `financialTerms.monthlyRent ${bad}`);
    await assertFails(setDoc(L(ctx.sa, "x"), lease({ financialTerms: { monthlyRent: 5000, annualRent: bad } })), `financialTerms.annualRent ${bad}`);
    await assertFails(setDoc(L(ctx.sa, "x"), lease({ annual_rent: bad })), `annual_rent ${bad}`);
    await assertFails(setDoc(L(ctx.sa, "x"), lease({ baseAmount: bad })), `baseAmount ${bad}`);
  }
  const { monthly_rent, financialTerms, ...noRent } = lease();
  await assertFails(setDoc(L(ctx.sa, "x"), noRent), "no rent");
  await assertFails(setDoc(L(ctx.sa, "x"), { ...noRent, financialTerms: {} }), "empty terms");
  await assertFails(setDoc(L(ctx.sa, "x"), { ...noRent, financialTerms: "5000" }), "terms not a map");
  await assertFails(setDoc(L(ctx.sa, "x"), lease({ financialTerms: { monthlyRent: 5000, splitPercent: 0 } })), "unknown term");
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
  for (const patch of [{ tenant_id: "tenantB" }, { owner_id: "ownerB" }, { property_id: "propB" }, { agency_id: "ag2" }, { agency_id: "" }, { property_id: deleteField() }]) {
    await assertFails(updateDoc(L(ctx.sa), patch), `SuperAdmin ${JSON.stringify(patch)}`);
    if (patch.agency_id !== "") await assertFails(updateDoc(L(ctx.sa, "own"), patch), `SuperAdmin own ${JSON.stringify(patch)}`);
  }
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

test("TAQ-110: the tenant rejects a pending offer directly; approving goes through respondToLeaseOffer", async () => {
  await seed({ "Leases/a": lease({ status: "pending_tenant_approval" }), "Leases/r": lease({ status: "pending_tenant_approval" }), "Leases/n": lease({ status: "pending_tenant_approval" }) });
  await assertFails(updateDoc(L(ctx.tenantA, "a"), decision("active")), "approval is server-side only");
  await assertFails(updateDoc(L(ctx.tenantA, "n"), { status: "active" }));
  await assertSucceeds(updateDoc(L(ctx.tenantA, "r"), decision("rejected", { tenant_decision_note: "Rent is too high" })));
  await assertSucceeds(updateDoc(L(ctx.tenantA, "n"), { status: "rejected" }));
  for (const bad of [
    decision("rejected", { monthly_rent: 1 }),
    decision("rejected", { financialTerms: { monthlyRent: 1 } }),
    decision("rejected", { start_date: "2020-01-01" }),
    decision("rejected", { end_date: "2099-01-01" }),
    decision("rejected", { notes: "x" }),
    decision("rejected", { tenant_id: "tenantB" }),
    decision("rejected", { owner_id: "tenantA" }),
    decision("rejected", { agency_id: "ag1" }),
    decision("rejected", { property_id: "propB" }),
    decision("rejected", { tenant_decision_note: "x".repeat(501) }),
    decision("rejected", { tenant_decision_note: 5 }),
    decision("rejected", { extra_field: 1 }),
  ]) {
    await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }) });
    await assertFails(updateDoc(L(ctx.tenantA, "p"), bad), JSON.stringify(bad));
  }
});

test("TAQ-110: no client role, SuperAdmin included, writes status active by any path", async () => {
  const pending = { "Leases/p": lease({ status: "pending_tenant_approval" }), "Leases/pa": agencyLease({ status: "pending_tenant_approval" }) };
  const others = { "Leases/d": lease(), "Leases/t": lease({ status: "terminated" }), "Leases/e": lease({ status: "expired" }), "Leases/x": lease({ status: "rejected" }) };
  await seed({ ...pending, ...others });
  for (const who of ["ownerA", "ownerB", "tenantA", "tenantB", "investor", "ag1", "ag2", "admin", "sa", "unauth"]) {
    for (const id of ["p", "pa", "d", "t", "e", "x"]) {
      await assertFails(updateDoc(L(ctx[who], id), decision("active")), `${who} ${id} -> active`);
      await assertFails(setDoc(L(ctx[who], id), lease({ status: "active" })), `${who} overwrites ${id} as active`);
    }
    await assertFails(setDoc(L(ctx[who], `new_${who}`), lease({ status: "active" })), `${who} creates active`);
  }
  // active -> terminated -> active: once a lease leaves active it never comes back from a client.
  await seed({ "Leases/act": lease({ status: "active" }) });
  await assertSucceeds(updateDoc(L(ctx.sa, "act"), { status: "terminated" }));
  for (const who of ["sa", "ownerA", "tenantA"]) await assertFails(updateDoc(L(ctx[who], "act"), { status: "active" }), `${who} reactivates`);
  await seed({ "Leases/act2": agencyLease({ status: "active" }) });
  await assertSucceeds(updateDoc(L(ctx.ag1, "act2"), { status: "expired" }));
  for (const who of ["sa", "ag1"]) await assertFails(updateDoc(L(ctx[who], "act2"), { status: "active" }), `${who} reactivates`);
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
  for (const status of ["active", "draft", "terminated", "expired", "pending_tenant_approval", "bogus"]) {
    await assertFails(updateDoc(L(ctx.tenantA, "p"), decision(status)), `tenant pending -> ${status}`);
  }
  await assertFails(updateDoc(L(ctx.tenantA, "p"), { updated_at: "2026-06-01" }), "no decision at all");
});

test("TAQ-13: only the lease's own tenant decides; other tenants, owners, agencies and strangers cannot", async () => {
  await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }), "Leases/pa": agencyLease({ status: "pending_tenant_approval" }) });
  for (const who of ["tenantB", "ownerB", "investor", "ag2", "admin", "unauth"]) {
    await assertFails(updateDoc(L(ctx[who], "p"), decision("rejected")), who);
    await assertFails(updateDoc(L(ctx[who], "pa"), decision("rejected")), who);
  }
  await assertSucceeds(updateDoc(L(ctx.tenantA, "pa"), decision("rejected")), "tenant of an agency lease");
});

test("TAQ-13: a tenant who is also the owner of the lease cannot approve their own offer", async () => {
  await seed({ "Leases/self": lease({ owner_id: "tenantA", tenant_id: "tenantA", status: "pending_tenant_approval" }) });
  await assertFails(updateDoc(L(ctx.tenantA, "self"), decision("rejected")));
});

test("TAQ-13: after the decision, the tenant cannot change anything and terms stay locked", async () => {
  await seed({ "Leases/p": lease({ status: "active" }) });
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

test("TAQ-13: SuperAdmin keeps break-glass over lease status, except activation", async () => {
  await seed({ "Leases/p": lease({ status: "pending_tenant_approval" }), "Leases/a": lease({ status: "active" }) });
  await assertFails(updateDoc(L(ctx.sa, "p"), { status: "active" }));
  await assertSucceeds(updateDoc(L(ctx.sa, "p"), { status: "rejected" }));
  await assertSucceeds(updateDoc(L(ctx.sa, "a"), { notes: "checked" }));
  await assertSucceeds(updateDoc(L(ctx.sa, "a"), { monthly_rent: 5100, financialTerms: { monthlyRent: 5100 } }));
  await assertFails(updateDoc(L(ctx.sa, "a"), { monthly_rent: 0 }));
});

test("TAQ-110: rent <= 0 or NaN fails on edit, for every role and every rent field", async () => {
  await seed({ "Leases/own": lease(), "Leases/ag": agencyLease(), "Leases/sa": lease() });
  for (const [db, id] of [[ctx.ownerA, "own"], [ctx.ag1, "ag"], [ctx.sa, "sa"]]) {
    for (const bad of [0, -1, NaN, Infinity, "5000"]) {
      for (const patch of [
        { monthly_rent: bad },
        { financialTerms: { monthlyRent: bad } },
        { financialTerms: { monthlyRent: 5000, annualRent: bad } },
        { annual_rent: bad },
        { baseAmount: bad },
      ]) {
        await assertFails(updateDoc(L(db, id), patch), `${id} ${JSON.stringify(patch)} (${bad})`);
      }
    }
    await assertFails(updateDoc(L(db, id), { financialTerms: { monthlyRent: 5000, platformPercent: 0 } }), `${id} unknown term`);
    await assertFails(updateDoc(L(db, id), { start_date: "2027-06-01" }), `${id} start after end`);
    await assertFails(updateDoc(L(db, id), { end_date: "soon" }), `${id} bad end date`);
    await assertSucceeds(updateDoc(L(db, id), { monthly_rent: 5100, financialTerms: { monthlyRent: 5100 } }), `${id} valid edit`);
  }
});

test("TAQ-110: an offer goes out only with a positive rent and valid dates", async () => {
  const { monthly_rent, financialTerms, ...noRent } = lease();
  const { end_date, ...noEnd } = lease();
  await seed({ "Leases/nr": noRent, "Leases/ne": noEnd, "Leases/bad": lease({ monthly_rent: 0, financialTerms: { monthlyRent: 0 } }) });
  for (const id of ["nr", "ne", "bad"]) {
    await assertFails(updateDoc(L(ctx.ownerA, id), { status: "pending_tenant_approval" }), id);
    await assertFails(updateDoc(L(ctx.sa, id), { status: "pending_tenant_approval" }), `SuperAdmin ${id}`);
  }
  await assertSucceeds(updateDoc(L(ctx.ownerA, "nr"), { status: "pending_tenant_approval", monthly_rent: 4000, financialTerms: { monthlyRent: 4000 } }));
});

test("TAQ-13: a lease with no status counts as a draft (older documents)", async () => {
  const { status, ...legacy } = lease();
  await seed({ "Leases/old": legacy });
  await assertSucceeds(updateDoc(L(ctx.ownerA, "old"), { monthly_rent: 5300 }));
});

// --- delete ---

test("TAQ-13/146: an owner and the managing agency delete a draft lease only; SuperAdmin keeps delete", async () => {
  await seed({
    "Leases/d": lease(),
    "Leases/a": lease({ status: "active" }),
    "Leases/g": agencyLease(),
    "Leases/gd": agencyLease(),
    "Leases/ga": agencyLease({ status: "active" }),
  });
  await assertSucceeds(deleteDoc(L(ctx.ownerA, "d")));
  await assertFails(deleteDoc(L(ctx.ownerA, "a")));
  await assertFails(deleteDoc(L(ctx.tenantA, "a")));
  await assertSucceeds(deleteDoc(L(ctx.ag1, "g")), "the agency deletes its own draft");
  await assertFails(deleteDoc(L(ctx.ag2, "gd")), "another agency cannot delete it");
  await assertFails(deleteDoc(L(ctx.ownerA, "gd")), "the owner does not delete an agency-managed lease");
  await assertFails(deleteDoc(L(ctx.ag1, "ga")), "an active lease is never deleted by the agency");
  await assertSucceeds(deleteDoc(L(ctx.sa, "a")));
});

test("TAQ-146: the agency cannot delete offered, rejected, expired or terminated leases; SuperAdmin can", async () => {
  const statuses = ["pending_tenant_approval", "rejected", "expired", "terminated", "active"];
  const docs = {};
  for (const status of statuses) {
    docs[`Leases/${status}`] = agencyLease({ status });
    docs[`Leases/own_${status}`] = lease({ status });
  }
  await seed(docs);
  for (const status of statuses) {
    await assertFails(deleteDoc(L(ctx.ag1, status)), `agency deletes ${status}`);
    await assertFails(deleteDoc(L(ctx.ownerA, `own_${status}`)), `owner deletes ${status}`);
  }
  await assertSucceeds(deleteDoc(L(ctx.sa, "terminated")), "SuperAdmin break-glass");
  await assertSucceeds(deleteDoc(L(ctx.sa, "pending_tenant_approval")));
});

test("TAQ-146: an offer is withdrawn by moving it back to draft, which can then be deleted", async () => {
  await seed({ "Leases/o": agencyLease({ status: "pending_tenant_approval" }) });
  await assertFails(deleteDoc(L(ctx.ag1, "o")), "an offer under the tenant is not deleted");
  await assertSucceeds(updateDoc(L(ctx.ag1, "o"), { status: "draft" }));
  await assertSucceeds(deleteDoc(L(ctx.ag1, "o")));
});

test("TAQ-110: PropertyLeaseLocks are server-only and AdminAlerts are read by platform staff only", async () => {
  await seed({ "PropertyLeaseLocks/propA": { lease_id: "l1", property_id: "propA" }, "AdminAlerts/a1": { type: "refund_required" } });
  for (const who of ["ownerA", "tenantA", "ag1", "admin", "sa", "unauth"]) {
    await assertFails(getDoc(doc(ctx[who], "PropertyLeaseLocks/propA")), who);
    await assertFails(setDoc(doc(ctx[who], "PropertyLeaseLocks/propB"), { lease_id: "x" }), who);
    await assertFails(deleteDoc(doc(ctx[who], "PropertyLeaseLocks/propA")), who);
    await assertFails(setDoc(doc(ctx[who], "AdminAlerts/a2"), { type: "x" }), who);
  }
  for (const who of ["admin", "sa"]) await assertSucceeds(getDoc(doc(ctx[who], "AdminAlerts/a1")), who);
  for (const who of ["ownerA", "tenantA", "ag1", "unauth"]) await assertFails(getDoc(doc(ctx[who], "AdminAlerts/a1")), who);
});

test("TAQ-13: only lease parties and SuperAdmin read leases (unchanged)", async () => {
  await seed({ "Leases/l1": agencyLease() });
  for (const who of ["ownerA", "tenantA", "ag1", "sa"]) await assertSucceeds(getDoc(L(ctx[who])), who);
  for (const who of ["ownerB", "tenantB", "ag2", "admin", "investor", "unauth"]) await assertFails(getDoc(L(ctx[who])), who);
});

// --- TAQ-164: optional lease terms ---

test("TAQ-164: a draft takes a late fee, grace days and payout bank of the right shape", async () => {
  await seed({ "Leases/l1": lease(), "Leases/g1": agencyLease() });
  await assertSucceeds(updateDoc(L(ctx.ownerA), { late_fee_amount: 250, late_fee_grace_days: 3, payout_bank_name: "FAB", payout_iban: "AE070331234567890123456" }));
  await assertSucceeds(updateDoc(L(ctx.ag1, "g1"), { late_fee_amount: 0, late_fee_grace_days: 0, payout_iban: "" }));
  for (const bad of [
    { late_fee_amount: -1 }, { late_fee_amount: "250" }, { late_fee_amount: 2000000 },
    { late_fee_grace_days: 61 }, { late_fee_grace_days: 2.5 }, { late_fee_grace_days: -1 },
    { payout_iban: "12345" }, { payout_iban: "ae070331234567890123456" }, { payout_bank_name: "x".repeat(101) },
    { payout_bank_name: "call 0501234567" },
  ]) {
    await assertFails(updateDoc(L(ctx.ownerA), bad), JSON.stringify(bad));
  }
});

test("TAQ-164: the terms are frozen once the offer is out, and nobody but SuperAdmin rewrites the tenant phone", async () => {
  await seed({ "Leases/l1": lease({ tenant_phone: "+971501234567" }), "Leases/p1": lease({ status: "pending_tenant_approval" }) });
  await assertFails(updateDoc(L(ctx.ownerA), { tenant_phone: "+20100" }));
  await assertFails(updateDoc(L(ctx.ownerA, "p1"), { late_fee_amount: 100 }));
  await assertFails(updateDoc(L(ctx.tenantA, "p1"), { status: "rejected", late_fee_amount: 0 }));
  await assertSucceeds(updateDoc(L(ctx.sa), { tenant_phone: "+971500000000" }));
  await assertFails(updateDoc(L(ctx.sa), { late_fee_amount: -5 }), "SuperAdmin still gets the shape check");
});

test("TAQ-164: a SuperAdmin-created lease must carry valid optional terms", async () => {
  await assertSucceeds(setDoc(L(ctx.sa, "n1"), lease({ late_fee_amount: 100, late_fee_grace_days: 5 })));
  await assertFails(setDoc(L(ctx.sa, "n2"), lease({ late_fee_grace_days: 90 })));
  await assertFails(setDoc(L(ctx.sa, "n3"), lease({ payout_iban: "bad" })));
});
