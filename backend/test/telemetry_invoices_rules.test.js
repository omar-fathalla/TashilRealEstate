const fs = require("fs");
const path = require("path");
const test = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
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
  addDoc,
  serverTimestamp,
} = require("firebase/firestore");

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

test.beforeEach(async () => {
  await testEnv.clearFirestore();
});

const anon = () => testEnv.unauthenticatedContext().firestore();
const as = (uid, claims = {}) => testEnv.authenticatedContext(uid, claims).firestore();
const superAdmin = () => as("root", { role: "SuperAdmin" });

async function seed(docPath, data) {
  await testEnv.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), docPath), data));
}

// --- TAQ-67: Telemetry_Crashes ---

function crash(extra = {}) {
  return {
    message: "Bad state: no element",
    stack: "#0 main (main.dart:1)",
    context: "widget build",
    isFatal: false,
    platform: "web",
    uid: null,
    createdAt: serverTimestamp(),
    ...extra,
  };
}

const crashRef = (db, id = "err_1") => doc(db, "Telemetry_Crashes", id);

test("TAQ-67: a signed-out visitor can create a crash report", async () => {
  await assertSucceeds(setDoc(crashRef(anon()), crash()));
  const noUid = crash();
  delete noUid.uid;
  await assertSucceeds(addDoc(collection(anon(), "Telemetry_Crashes"), noUid));
});

test("TAQ-67: a signed-in user can create a report with their own uid, and only their own", async () => {
  await assertSucceeds(setDoc(crashRef(as("u1")), crash({ uid: "u1" })));
  await assertFails(setDoc(crashRef(as("u1"), "err_2"), crash({ uid: "u2" })));
  await assertFails(setDoc(crashRef(anon(), "err_3"), crash({ uid: "u1" })));
});

test("TAQ-67: optional fields may be left out", async () => {
  await assertSucceeds(setDoc(crashRef(anon()), { message: "x", isFatal: true, platform: "android", createdAt: serverTimestamp() }));
});

test("TAQ-67: unknown keys and PII fields are rejected", async () => {
  for (const extra of [{ email: "a@b.c" }, { phone: "0501234567" }, { userId: "anonymous" }, { id: "err_1" }, { timestamp: "2026-01-01" }, { displayName: "A" }]) {
    await assertFails(setDoc(crashRef(anon()), crash(extra)));
  }
});

test("TAQ-67: required fields and types are enforced", async () => {
  for (const missing of ["message", "isFatal", "platform", "createdAt"]) {
    const data = crash();
    delete data[missing];
    await assertFails(setDoc(crashRef(anon()), data));
  }
  await assertFails(setDoc(crashRef(anon()), crash({ message: "" })));
  await assertFails(setDoc(crashRef(anon()), crash({ message: 42 })));
  await assertFails(setDoc(crashRef(anon()), crash({ stack: 42 })));
  await assertFails(setDoc(crashRef(anon()), crash({ context: { a: 1 } })));
  await assertFails(setDoc(crashRef(anon()), crash({ isFatal: "yes" })));
  await assertFails(setDoc(crashRef(anon()), crash({ platform: "<script>" })));
  await assertFails(setDoc(crashRef(anon()), crash({ uid: 12 })));
});

test("TAQ-67: string length caps (message 2000, stack 8000, context 500, id 64)", async () => {
  await assertSucceeds(setDoc(crashRef(anon(), "ok_max"), crash({ message: "m".repeat(2000), stack: "s".repeat(8000), context: "c".repeat(500) })));
  await assertFails(setDoc(crashRef(anon()), crash({ message: "m".repeat(2001) })));
  await assertFails(setDoc(crashRef(anon()), crash({ stack: "s".repeat(8001) })));
  await assertFails(setDoc(crashRef(anon()), crash({ context: "c".repeat(501) })));
  await assertFails(setDoc(crashRef(anon(), "i".repeat(65)), crash()));
  await assertSucceeds(setDoc(crashRef(anon(), "i".repeat(64)), crash()));
});

test("TAQ-67: createdAt must be the server time", async () => {
  await assertFails(setDoc(crashRef(anon()), crash({ createdAt: new Date("2020-01-01T00:00:00Z") })));
  await assertFails(setDoc(crashRef(anon()), crash({ createdAt: new Date() })));
  await assertFails(setDoc(crashRef(anon()), crash({ createdAt: "now" })));
});

test("TAQ-67: reports cannot be updated, deleted, or overwritten by their author", async () => {
  await assertSucceeds(setDoc(crashRef(as("u1")), crash({ uid: "u1" })));
  await assertFails(updateDoc(crashRef(as("u1")), { message: "changed" }));
  await assertFails(deleteDoc(crashRef(as("u1"))));
  await assertFails(deleteDoc(crashRef(superAdmin())));
  await assertFails(updateDoc(crashRef(superAdmin()), { message: "changed" }));
});

test("TAQ-67: only a SuperAdmin can read or list reports", async () => {
  await seed("Telemetry_Crashes/err_1", { message: "m", isFatal: false, platform: "web", uid: "u1", createdAt: new Date() });
  await assertSucceeds(getDoc(crashRef(superAdmin())));
  await assertSucceeds(getDocs(collection(superAdmin(), "Telemetry_Crashes")));
  for (const db of [anon(), as("u1"), as("owner", { role: "Owner" }), as("ag", { role: "AgencyAdmin", agency_id: "a1" })]) {
    await assertFails(getDoc(crashRef(db)));
    await assertFails(getDocs(collection(db, "Telemetry_Crashes")));
  }
});

test("TAQ-67: a Users profile that claims SuperAdmin cannot read reports", async () => {
  await seed("Users/legacy", { role: "SuperAdmin" });
  await assertFails(getDoc(crashRef(as("legacy"))));
});

// --- TAQ-67: Invoices ---

const invoice = (extra = {}) => ({
  invoiceNumber: "INV-1",
  leaseId: "lease-1",
  tenant_id: "tenant",
  owner_id: "owner",
  agency_id: "agency-1",
  amount: 8000,
  status: "Issued",
  ...extra,
});

const invRef = (db, id = "INV-1") => doc(db, "Invoices", id);

test("TAQ-67: the tenant, owner and agency admin of an invoice can read it", async () => {
  await seed("Invoices/INV-1", invoice());
  await assertSucceeds(getDoc(invRef(as("tenant", { role: "Tenant" }))));
  await assertSucceeds(getDoc(invRef(as("owner", { role: "Owner" }))));
  await assertSucceeds(getDoc(invRef(as("agent", { role: "AgencyAdmin", agency_id: "agency-1" }))));
  await assertSucceeds(getDoc(invRef(superAdmin())));
});

test("TAQ-67: other users, other agencies and visitors cannot read an invoice", async () => {
  await seed("Invoices/INV-1", invoice());
  await assertFails(getDoc(invRef(anon())));
  await assertFails(getDoc(invRef(as("stranger"))));
  await assertFails(getDoc(invRef(as("otherTenant", { role: "Tenant" }))));
  await assertFails(getDoc(invRef(as("otherOwner", { role: "Owner" }))));
  await assertFails(getDoc(invRef(as("agent2", { role: "AgencyAdmin", agency_id: "agency-2" }))));
  await assertFails(getDoc(invRef(as("agent", { role: "Owner", agency_id: "agency-1" }))));
  await seed("Users/legacy", { role: "SuperAdmin" });
  await assertFails(getDoc(invRef(as("legacy"))));
});

test("TAQ-67: an invoice without an agency or owner is not readable through empty ids", async () => {
  await seed("Invoices/INV-2", { invoiceNumber: "INV-2", tenant_id: "tenant", owner_id: null, agency_id: null });
  await assertSucceeds(getDoc(invRef(as("tenant"), "INV-2")));
  await assertFails(getDoc(invRef(as("agent", { role: "AgencyAdmin" }), "INV-2")));
});

test("TAQ-67: invoice queries must be scoped to the caller", async () => {
  await seed("Invoices/INV-1", invoice());
  await seed("Invoices/INV-9", invoice({ invoiceNumber: "INV-9", tenant_id: "other", owner_id: "other2", agency_id: "agency-9" }));
  const col = (db) => collection(db, "Invoices");
  await assertSucceeds(getDocs(query(col(as("tenant")), where("tenant_id", "==", "tenant"))));
  await assertSucceeds(getDocs(query(col(as("owner")), where("owner_id", "==", "owner"))));
  await assertFails(getDocs(col(as("tenant"))));
  await assertFails(getDocs(query(col(as("tenant")), where("tenant_id", "==", "other"))));
  await assertFails(getDocs(col(anon())));
  await assertSucceeds(getDocs(col(superAdmin())));
});

test("TAQ-67: no client can create, update or delete an invoice (functions issue them)", async () => {
  await seed("Invoices/INV-1", invoice());
  for (const db of [anon(), as("tenant", { role: "Tenant" }), as("owner", { role: "Owner" }), as("agent", { role: "AgencyAdmin", agency_id: "agency-1" }), superAdmin()]) {
    await assertFails(setDoc(invRef(db, "INV-new"), invoice({ status: "Paid_Verified" })));
    await assertFails(updateDoc(invRef(db), { status: "Paid_Verified" }));
    await assertFails(deleteDoc(invRef(db)));
  }
});
