// TAQ-111: Maintenance requests are created against an active lease, with a bounded shape, and the
// owner or managing agency can only move their progress.
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

const lease = (extra = {}) => ({
  owner_id: "ownerA",
  tenant_id: "tenantA",
  agency_id: "",
  property_id: "p1",
  property_title: "Marina Apartment",
  tenant_name: "Sara Ali",
  status: "active",
  ...extra,
});
const PHOTO = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ==";

test.beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    const d = c.firestore();
    await setDoc(doc(d, "Users/tenantA"), { role: "Tenant" });
    await setDoc(doc(d, "Users/tenantB"), { role: "Tenant" });
    await setDoc(doc(d, "Users/ownerA"), { role: "Owner" });
    await setDoc(doc(d, "Users/ownerB"), { role: "Owner" });
    await setDoc(doc(d, "Leases/active"), lease());
    await setDoc(doc(d, "Leases/agency"), lease({ agency_id: "ag1" }));
    for (const status of ["draft", "pending_tenant_approval", "rejected", "expired", "terminated"]) {
      await setDoc(doc(d, `Leases/${status}`), lease({ status }));
    }
    await setDoc(doc(d, "Maintenance/m1"), { lease_id: "active", tenant_id: "tenantA", owner_id: "ownerA", agency_id: "", title: "Leak", status: "pending" });
    await setDoc(doc(d, "Maintenance/m2"), { lease_id: "agency", tenant_id: "tenantA", owner_id: "ownerA", agency_id: "ag1", title: "AC", status: "pending" });
  });
  const mk = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  ctx.tenantA = mk("tenantA");
  ctx.tenantB = mk("tenantB");
  ctx.ownerA = mk("ownerA");
  ctx.ownerB = mk("ownerB");
  ctx.ag1 = mk("ag1admin", { role: "AgencyAdmin", agency_id: "ag1" });
  ctx.ag2 = mk("ag2admin", { role: "AgencyAdmin", agency_id: "ag2" });
  ctx.admin = mk("admin1", { role: "Admin" });
  ctx.sa = mk("sa", { role: "SuperAdmin" });
  ctx.unauth = env.unauthenticatedContext().firestore();
});

const M = (db, id) => doc(db, `Maintenance/${id}`);
const request = (extra = {}) => ({
  lease_id: "active",
  tenant_id: "tenantA",
  owner_id: "ownerA",
  agency_id: "",
  property_id: "p1",
  property_title: "Marina Apartment",
  tenant_name: "Sara Ali",
  title: "Kitchen sink leaks",
  description: "Water under the sink",
  category: "plumbing",
  photos: [],
  status: "pending",
  created_at: serverTimestamp(),
  updated_at: serverTimestamp(),
  ...extra,
});

test("TAQ-111: a tenant creates a request on their active lease; parties are checked against the lease", async () => {
  await assertSucceeds(setDoc(M(ctx.tenantA, "n1"), request()));
  await assertSucceeds(setDoc(M(ctx.tenantA, "n2"), request({ lease_id: "agency", agency_id: "ag1", photos: [PHOTO] })));
  await assertFails(setDoc(M(ctx.tenantA, "n3"), request({ agency_id: "ag1" })), "agency does not match the lease");
  await assertFails(setDoc(M(ctx.tenantA, "n4"), request({ lease_id: "agency" })), "missing agency");
  await assertFails(setDoc(M(ctx.tenantA, "n5"), request({ owner_id: "ownerB" })), "wrong owner");
  await assertFails(setDoc(M(ctx.tenantA, "n6"), request({ tenant_id: "tenantB" })), "wrong tenant");
  await assertFails(setDoc(M(ctx.tenantB, "n7"), request()), "not this lease's tenant");
  await assertFails(setDoc(M(ctx.ownerB, "n8"), request()), "not this lease's owner");
  await assertSucceeds(setDoc(M(ctx.ownerA, "n9"), request()), "the owner may log one for their own lease");
});

test("TAQ-111: a request needs an active lease", async () => {
  for (const status of ["draft", "pending_tenant_approval", "rejected", "expired", "terminated"]) {
    await assertFails(setDoc(M(ctx.tenantA, `x_${status}`), request({ lease_id: status })), status);
  }
  await assertFails(setDoc(M(ctx.tenantA, "x_missing"), request({ lease_id: "ghost" })));
  await assertFails(setDoc(M(ctx.tenantA, "x_nolease"), request({ lease_id: "" })));
});

test("TAQ-111: the request shape is bounded", async () => {
  const bad = [
    { title: "" },
    { title: "x".repeat(121) },
    { title: 5 },
    { tenant_name: "x".repeat(101) },
    { property_title: 5 },
    { description: "x".repeat(2001) },
    { description: 5 },
    { category: "magic" },
    { photos: [PHOTO, PHOTO, PHOTO, PHOTO] },
    { photos: "not a list" },
    { status: "resolved" },
    { status: "in_progress" },
    { status: "open" },
    { escalated: true },
    { resolution_note: "done" },
    { extra: 1 },
    { created_at: new Date() },
  ];
  for (const patch of bad) await assertFails(setDoc(M(ctx.tenantA, "b"), request(patch)), JSON.stringify(patch));
  const { title, ...noTitle } = request();
  await assertFails(setDoc(M(ctx.tenantA, "b"), noTitle), "no title");
  const { description, category, photos, ...minimal } = request();
  await assertSucceeds(setDoc(M(ctx.tenantA, "named"), request({ tenant_name: "Sara Ali", property_id: "p1", property_title: "Marina Apartment" })));
  await assertSucceeds(setDoc(M(ctx.tenantA, "min"), minimal), "description, category and photos are optional");
  await assertSucceeds(setDoc(M(ctx.tenantA, "three"), request({ photos: [PHOTO, PHOTO, PHOTO] })));
});

test("TAQ-110: the request's property, property title and tenant name are the lease's", async () => {
  for (const patch of [
    { property_id: "p2" },
    { property_id: "" },
    { property_title: "Penthouse" },
    { property_title: "" },
    { tenant_name: "Someone Else" },
    { tenant_name: "" },
  ]) {
    await assertFails(setDoc(M(ctx.tenantA, "b"), request(patch)), JSON.stringify(patch));
  }
  const { property_id, property_title, tenant_name, ...unnamed } = request();
  await assertFails(setDoc(M(ctx.tenantA, "b"), unnamed), "the lease names a property, so the request must too");
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), "Leases/bare"), { owner_id: "ownerA", tenant_id: "tenantA", agency_id: "", property_id: "p9", status: "active" });
  });
  await assertSucceeds(setDoc(M(ctx.tenantA, "bare"), { ...unnamed, lease_id: "bare", property_id: "p9" }), "a lease with no title or name needs none");
});

test("TAQ-110: photos are image data URLs within the size cap", async () => {
  const big = `data:image/png;base64,${"A".repeat(300000 - "data:image/png;base64,".length)}`;
  await assertSucceeds(setDoc(M(ctx.tenantA, "cap"), request({ photos: [big] })), "exactly at the cap");
  for (const photos of [
    ["a"],
    ["https://evil.example/x.png"],
    ["data:text/html;base64,PHNjcmlwdD4="],
    ["data:image/svg+xml;base64,PHN2Zz4="],
    ["data:image/png,rawdata"],
    ["data:image/png;base64,abc def"],
    [`${big}A`],
    [PHOTO, 5],
    [PHOTO, PHOTO, "javascript:alert(1)"],
  ]) {
    await assertFails(setDoc(M(ctx.tenantA, "p"), request({ photos })), JSON.stringify(photos).slice(0, 80));
  }
  for (const type of ["png", "jpeg", "jpg", "webp", "gif"]) {
    await assertSucceeds(setDoc(M(ctx.tenantA, `t_${type}`), request({ photos: [`data:image/${type};base64,AAAA`] })), type);
  }
});

test("TAQ-111: Admin, Investor-style roles, agencies and signed-out users cannot create requests", async () => {
  await assertFails(setDoc(M(ctx.admin, "a1"), request()));
  await assertFails(setDoc(M(ctx.ag1, "a2"), request({ lease_id: "agency", agency_id: "ag1" })));
  await assertFails(setDoc(M(ctx.unauth, "a3"), request()));
  await assertSucceeds(setDoc(M(ctx.sa, "a4"), { tenant_id: "x", owner_id: "y" }));
});

test("TAQ-111: the owner and the managing agency move a request through its progress, and nothing else", async () => {
  for (const status of ["in_progress", "resolved", "pending"]) {
    await assertSucceeds(updateDoc(M(ctx.ownerA, "m1"), { status, updated_at: "2026-06-01" }), `owner ${status}`);
  }
  await assertSucceeds(updateDoc(M(ctx.ownerA, "m1"), { status: "resolved", resolution_note: "Replaced the trap" }));
  await assertSucceeds(updateDoc(M(ctx.ag1, "m2"), { status: "in_progress" }));
  for (const patch of [
    { status: "escalated" },
    { status: "open" },
    { status: "bogus" },
    { escalated: true },
    { title: "Rewritten" },
    { description: "Rewritten" },
    { category: "other" },
    { photos: [] },
    { lease_id: "agency" },
    { tenant_id: "tenantB" },
    { owner_id: "ownerB" },
    { agency_id: "ag1" },
    { resolution_note: "x".repeat(1001) },
    { resolution_note: 5 },
  ]) {
    await assertFails(updateDoc(M(ctx.ownerA, "m1"), patch), `owner ${JSON.stringify(patch)}`);
  }
  await assertFails(updateDoc(M(ctx.ag1, "m2"), { title: "Rewritten" }));
});

test("TAQ-111: tenants, strangers and other agencies cannot update, and the other owner cannot read", async () => {
  await assertFails(updateDoc(M(ctx.tenantA, "m1"), { status: "resolved" }), "the tenant cannot close their own request");
  await assertFails(updateDoc(M(ctx.tenantB, "m1"), { status: "resolved" }));
  await assertFails(updateDoc(M(ctx.ownerB, "m1"), { status: "resolved" }));
  await assertFails(updateDoc(M(ctx.ag2, "m2"), { status: "resolved" }));
  await assertFails(updateDoc(M(ctx.ag1, "m1"), { status: "resolved" }), "ag1 does not manage m1");
  await assertFails(updateDoc(M(ctx.unauth, "m1"), { status: "resolved" }));
});

test("TAQ-111: Admin escalates and notes only; SuperAdmin keeps full access", async () => {
  await assertSucceeds(updateDoc(M(ctx.admin, "m1"), { status: "escalated", escalated: true, resolution_note: "Sent to the platform" }));
  await assertFails(updateDoc(M(ctx.admin, "m1"), { title: "x" }));
  await assertFails(updateDoc(M(ctx.admin, "m1"), { owner_id: "admin1" }));
  await assertSucceeds(updateDoc(M(ctx.sa, "m1"), { title: "Fixed by staff" }));
});

test("TAQ-111: only the parties and staff read; list queries are scoped", async () => {
  for (const who of ["tenantA", "ownerA", "admin", "sa"]) await assertSucceeds(getDoc(M(ctx[who], "m1")), who);
  await assertSucceeds(getDoc(M(ctx.ag1, "m2")));
  for (const who of ["tenantB", "ownerB", "ag2", "unauth"]) await assertFails(getDoc(M(ctx[who], "m1")), who);
  await assertFails(getDoc(M(ctx.ag1, "m1")));
  const col = (db) => collection(db, "Maintenance");
  await assertSucceeds(getDocs(query(col(ctx.tenantA), where("tenant_id", "==", "tenantA"))));
  await assertSucceeds(getDocs(query(col(ctx.ownerA), where("owner_id", "==", "ownerA"))));
  await assertSucceeds(getDocs(query(col(ctx.ag1), where("agency_id", "==", "ag1"))));
  await assertFails(getDocs(col(ctx.tenantA)));
  await assertFails(getDocs(query(col(ctx.tenantA), where("tenant_id", "==", "tenantB"))));
  await assertFails(getDocs(query(col(ctx.ag2), where("agency_id", "==", "ag1"))));
});

test("TAQ-146: no one but SuperAdmin deletes a maintenance complaint, not even the managing agency", async () => {
  await assertFails(deleteDoc(M(ctx.tenantA, "m1")));
  await assertFails(deleteDoc(M(ctx.ownerA, "m1")));
  await assertFails(deleteDoc(M(ctx.ag2, "m2")));
  await assertFails(deleteDoc(M(ctx.ag1, "m2")), "the managing agency");
  await assertFails(deleteDoc(M(ctx.admin, "m2")));
  await assertFails(deleteDoc(M(ctx.unauth, "m2")));
  await assertSucceeds(deleteDoc(M(ctx.sa, "m1")));
});
