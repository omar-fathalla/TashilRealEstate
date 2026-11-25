// TAQ-16: Transactions are readable by their parties and writable by nobody on the client.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs, serverTimestamp } = require("firebase/firestore");

let env;
const ctx = {};
test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test",
    firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") },
  });
});
test.after(async () => {
  if (env) await env.cleanup();
});

test.beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    const d = c.firestore();
    await setDoc(doc(d, "Users/ownerA"), { role: "Owner" });
    await setDoc(doc(d, "Users/tenantA"), { role: "Tenant" });
    await setDoc(doc(d, "Users/tenantB"), { role: "Tenant" });
    await setDoc(doc(d, "Transactions/l1_2026-11"), { tenant_id: "tenantA", owner_id: "ownerA", agency_id: "ag1", status: "pending", amount: 8000 });
    await setDoc(doc(d, "PaymentSessions/9001"), { transactionId: "l1_2026-11", checkoutUrl: "https://x.test/?clientSecret=cs" });
  });
  const mk = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  ctx.tenantA = mk("tenantA");
  ctx.tenantB = mk("tenantB");
  ctx.ownerA = mk("ownerA");
  ctx.ag1 = mk("ag1admin", { role: "AgencyAdmin", agency_id: "ag1" });
  ctx.ag2 = mk("ag2admin", { role: "AgencyAdmin", agency_id: "ag2" });
  ctx.admin = mk("admin1", { role: "Admin" });
  ctx.sa = mk("sa", { role: "SuperAdmin" });
  ctx.unauth = env.unauthenticatedContext().firestore();
});

const T = (db) => doc(db, "Transactions/l1_2026-11");

test("TAQ-16: the tenant, the owner, the managing agency and SuperAdmin read a transaction", async () => {
  for (const who of ["tenantA", "ownerA", "ag1", "sa"]) await assertSucceeds(getDoc(T(ctx[who])), who);
});

test("TAQ-16: other tenants, other agencies, Admin and signed-out users cannot read a transaction", async () => {
  for (const who of ["tenantB", "ag2", "admin", "unauth"]) await assertFails(getDoc(T(ctx[who])), who);
});

test("TAQ-16: a tenant can list their own transactions and nobody else's", async () => {
  await assertSucceeds(getDocs(query(collection(ctx.tenantA, "Transactions"), where("tenant_id", "==", "tenantA"))));
  await assertFails(getDocs(query(collection(ctx.tenantB, "Transactions"), where("tenant_id", "==", "tenantA"))));
  await assertFails(getDocs(collection(ctx.tenantA, "Transactions")));
});

test("TAQ-16: no client writes a transaction, whatever the role: no pending, no paid, no Completed", async () => {
  for (const who of ["tenantA", "ownerA", "ag1", "sa", "admin", "unauth"]) {
    const db = ctx[who];
    await assertFails(setDoc(doc(db, "Transactions/forged"), { tenant_id: "tenantA", owner_id: "ownerA", status: "Completed", amount: 1 }), `${who} create`);
    await assertFails(updateDoc(T(db), { status: "paid" }), `${who} mark paid`);
    await assertFails(updateDoc(T(db), { status: "Completed" }), `${who} mark Completed`);
    await assertFails(deleteDoc(T(db)), `${who} delete`);
  }
});

test("TAQ-16: gateway sessions (they hold checkout links) are unreadable and unwritable by every client", async () => {
  for (const who of ["tenantA", "ownerA", "ag1", "sa", "admin", "unauth"]) {
    await assertFails(getDoc(doc(ctx[who], "PaymentSessions/9001")), who);
    await assertFails(setDoc(doc(ctx[who], "PaymentSessions/1"), { transactionId: "x" }), who);
  }
});

// --- Settings/payment_split ---

const SPLIT = (db) => doc(db, "Settings/payment_split");
const splitDoc = (extra = {}) => ({ platform_percent: 2, agency_percent: 8, updated_by: "sa", updated_at: serverTimestamp(), ...extra });

test("TAQ-16: only SuperAdmin reads or writes the payment split setting", async () => {
  await assertSucceeds(setDoc(SPLIT(ctx.sa), splitDoc()));
  await assertSucceeds(getDoc(SPLIT(ctx.sa)));
  await assertSucceeds(updateDoc(SPLIT(ctx.sa), { platform_percent: 3, agency_percent: 7, updated_by: "sa", updated_at: serverTimestamp() }));
  for (const who of ["tenantA", "ownerA", "ag1", "admin", "unauth"]) {
    await assertFails(setDoc(SPLIT(ctx[who]), splitDoc({ updated_by: who })), `${who} write`);
    await assertFails(getDoc(SPLIT(ctx[who])), `${who} read`);
  }
});

test("TAQ-16: the split setting must be two sane percentages stamped by the writer", async () => {
  for (const bad of [
    { platform_percent: "2" },
    { platform_percent: -1 },
    { agency_percent: 101 },
    { platform_percent: 60, agency_percent: 50 },
    { updated_by: "someone-else" },
    { updated_at: new Date() },
    { extra_field: 1 },
  ]) {
    await assertFails(setDoc(SPLIT(ctx.sa), splitDoc(bad)), JSON.stringify(bad));
  }
  const { agency_percent, ...missing } = splitDoc();
  await assertFails(setDoc(SPLIT(ctx.sa), missing));
  await assertSucceeds(setDoc(SPLIT(ctx.sa), splitDoc({ platform_percent: 0, agency_percent: 0 })));
  await assertSucceeds(setDoc(SPLIT(ctx.sa), splitDoc({ platform_percent: 50.5, agency_percent: 49.5 })));
});

test("TAQ-16: SuperAdmin cannot create other settings documents or delete the split", async () => {
  await assertFails(setDoc(doc(ctx.sa, "Settings/other"), splitDoc()));
  await assertSucceeds(setDoc(SPLIT(ctx.sa), splitDoc()));
  await assertFails(deleteDoc(SPLIT(ctx.sa)));
});
