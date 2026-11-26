// TAQ-110: a tenant reads only their own leases, invoices, transactions and notifications,
// can mark a notification read (and nothing else), and still cannot write money records.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs } = require("firebase/firestore");

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
    await setDoc(doc(d, "Users/tenantA"), { role: "Tenant" });
    await setDoc(doc(d, "Users/tenantB"), { role: "Tenant" });
    await setDoc(doc(d, "Users/ownerA"), { role: "Owner" });
    for (const [id, tenant] of [["l1", "tenantA"], ["l2", "tenantB"]]) {
      await setDoc(doc(d, `Leases/${id}`), { tenant_id: tenant, owner_id: "ownerA", agency_id: "", property_id: "p1", status: "active" });
      await setDoc(doc(d, `Invoices/inv_${id}`), { tenant_id: tenant, owner_id: "ownerA", totalPaid: 100 });
      await setDoc(doc(d, `Transactions/tx_${id}`), { tenant_id: tenant, owner_id: "ownerA", amount: 100, status: "paid" });
    }
    await setDoc(doc(d, "Users/tenantA/notifications/n1"), { recipientId: "tenantA", read: false, type: "lease_offer", title: { en: "x" } });
    await setDoc(doc(d, "Users/tenantB/notifications/n2"), { recipientId: "tenantB", read: false });
  });
  const mk = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  ctx.tenantA = mk("tenantA");
  ctx.tenantB = mk("tenantB");
  ctx.ownerA = mk("ownerA");
  ctx.sa = mk("sa", { role: "SuperAdmin" });
  ctx.unauth = env.unauthenticatedContext().firestore();
});

test("TAQ-110: the tenant queries by tenant_id and gets only their own leases, invoices and transactions", async () => {
  for (const name of ["Leases", "Invoices", "Transactions"]) {
    const snap = await assertSucceeds(getDocs(query(collection(ctx.tenantA, name), where("tenant_id", "==", "tenantA"))));
    if (snap.size !== 1) throw new Error(`${name}: expected 1 record, got ${snap.size}`);
    await assertFails(getDocs(query(collection(ctx.tenantA, name), where("tenant_id", "==", "tenantB"))));
    await assertFails(getDocs(collection(ctx.tenantA, name)));
  }
});

test("TAQ-110: a tenant cannot read another tenant's lease, invoice or transaction by id", async () => {
  await assertFails(getDoc(doc(ctx.tenantA, "Leases/l2")));
  await assertFails(getDoc(doc(ctx.tenantA, "Invoices/inv_l2")));
  await assertFails(getDoc(doc(ctx.tenantA, "Transactions/tx_l2")));
  await assertFails(getDoc(doc(ctx.unauth, "Leases/l1")));
});

test("TAQ-110: a tenant cannot write an invoice or a transaction, so nothing can be marked paid on the client", async () => {
  await assertFails(setDoc(doc(ctx.tenantA, "Invoices/inv_new"), { tenant_id: "tenantA", totalPaid: 1, status: "Paid" }));
  await assertFails(updateDoc(doc(ctx.tenantA, "Invoices/inv_l1"), { totalPaid: 0 }));
  await assertFails(setDoc(doc(ctx.tenantA, "Transactions/tx_new"), { tenant_id: "tenantA", amount: 100, status: "paid" }));
  await assertFails(updateDoc(doc(ctx.tenantA, "Transactions/tx_l1"), { status: "paid", amount: 1 }));
  await assertFails(deleteDoc(doc(ctx.tenantA, "Transactions/tx_l1")));
});

test("TAQ-110: the notification stream works for the recipient only", async () => {
  const mine = await assertSucceeds(getDocs(collection(ctx.tenantA, "Users/tenantA/notifications")));
  if (mine.size !== 1) throw new Error("expected one notification");
  await assertFails(getDocs(collection(ctx.tenantA, "Users/tenantB/notifications")));
  await assertFails(getDoc(doc(ctx.ownerA, "Users/tenantA/notifications/n1")));
  await assertFails(getDocs(collection(ctx.unauth, "Users/tenantA/notifications")));
});

test("TAQ-110: the recipient can mark a notification read, and only that", async () => {
  const n1 = doc(ctx.tenantA, "Users/tenantA/notifications/n1");
  await assertSucceeds(updateDoc(n1, { read: true }));
  await assertSucceeds(updateDoc(n1, { read: false }));
  await assertFails(updateDoc(n1, { read: "yes" }));
  await assertFails(updateDoc(n1, { read: true, type: "other" }));
  await assertFails(updateDoc(n1, { title: { en: "changed" } }));
  await assertFails(updateDoc(n1, { recipientId: "tenantB" }));
  await assertFails(updateDoc(n1, { amount: 1 }));
});

test("TAQ-110: nobody else can touch another user's notifications, create them, or delete them", async () => {
  await assertFails(updateDoc(doc(ctx.tenantB, "Users/tenantA/notifications/n1"), { read: true }));
  await assertFails(updateDoc(doc(ctx.ownerA, "Users/tenantA/notifications/n1"), { read: true }));
  await assertFails(updateDoc(doc(ctx.unauth, "Users/tenantA/notifications/n1"), { read: true }));
  await assertFails(setDoc(doc(ctx.tenantA, "Users/tenantA/notifications/fake"), { recipientId: "tenantA", read: false, title: { en: "Your rent is waived" } }));
  await assertFails(deleteDoc(doc(ctx.tenantA, "Users/tenantA/notifications/n1")));
});

test("TAQ-110: the tenant cannot approve an offer directly (respondToLeaseOffer does), but may reject a pending one", async () => {
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), "Leases/offer"), { tenant_id: "tenantA", owner_id: "ownerA", agency_id: "", property_id: "p1", status: "pending_tenant_approval", monthly_rent: 5000 });
    await setDoc(doc(c.firestore(), "Leases/draft"), { tenant_id: "tenantA", owner_id: "ownerA", agency_id: "", property_id: "p1", status: "draft", monthly_rent: 5000 });
  });
  await assertFails(updateDoc(doc(ctx.tenantA, "Leases/draft"), { status: "active" }));
  await assertFails(updateDoc(doc(ctx.tenantA, "Leases/offer"), { status: "active", monthly_rent: 1 }));
  await assertFails(updateDoc(doc(ctx.tenantB, "Leases/offer"), { status: "active" }));
  await assertFails(updateDoc(doc(ctx.tenantA, "Leases/offer"), { status: "active" }));
  await assertFails(updateDoc(doc(ctx.tenantB, "Leases/offer"), { status: "rejected" }));
  await assertFails(updateDoc(doc(ctx.tenantA, "Leases/draft"), { status: "rejected" }));
  await assertSucceeds(updateDoc(doc(ctx.tenantA, "Leases/offer"), { status: "rejected" }));
});
