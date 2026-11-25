// TAQ-112: ViewingRequests and RentalApplications are read by their parties and written by nobody on the client.
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
    await setDoc(doc(d, "ViewingRequests/v1"), { requester_id: "visitorA", owner_id: "ownerA", agency_id: "ag1", listing_id: "p1", status: "pending" });
    await setDoc(doc(d, "RentalApplications/p1_visitorA"), { applicant_id: "visitorA", owner_id: "ownerA", agency_id: "ag1", listing_id: "p1", status: "pending" });
    await setDoc(doc(d, "ViewingRequests/v2"), { requester_id: "visitorB", owner_id: "ownerB", agency_id: "", listing_id: "p2", status: "pending" });
  });
  const mk = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  ctx.visitorA = mk("visitorA");
  ctx.visitorB = mk("visitorB");
  ctx.ownerA = mk("ownerA");
  ctx.ownerB = mk("ownerB");
  ctx.ag1 = mk("ag1admin", { role: "AgencyAdmin", agency_id: "ag1" });
  ctx.ag2 = mk("ag2admin", { role: "AgencyAdmin", agency_id: "ag2" });
  ctx.admin = mk("admin1", { role: "Admin" });
  ctx.sa = mk("sa", { role: "SuperAdmin" });
  ctx.unauth = env.unauthenticatedContext().firestore();
});

const V = (db) => doc(db, "ViewingRequests/v1");
const A = (db) => doc(db, "RentalApplications/p1_visitorA");

test("TAQ-112: the requester, owner, managing agency and staff read a viewing request and an application", async () => {
  for (const who of ["visitorA", "ownerA", "ag1", "admin", "sa"]) {
    await assertSucceeds(getDoc(V(ctx[who])), `viewing ${who}`);
    await assertSucceeds(getDoc(A(ctx[who])), `application ${who}`);
  }
});

test("TAQ-112: other visitors, other owners, other agencies and signed-out users cannot read them", async () => {
  for (const who of ["visitorB", "ownerB", "ag2", "unauth"]) {
    await assertFails(getDoc(V(ctx[who])), `viewing ${who}`);
    await assertFails(getDoc(A(ctx[who])), `application ${who}`);
  }
});

test("TAQ-112: inbox queries work for each party and cannot reach someone else's records", async () => {
  const col = (db, name) => collection(db, name);
  await assertSucceeds(getDocs(query(col(ctx.ownerA, "ViewingRequests"), where("owner_id", "==", "ownerA"))));
  await assertSucceeds(getDocs(query(col(ctx.ag1, "ViewingRequests"), where("agency_id", "==", "ag1"))));
  await assertSucceeds(getDocs(query(col(ctx.visitorA, "ViewingRequests"), where("requester_id", "==", "visitorA"))));
  await assertSucceeds(getDocs(query(col(ctx.visitorA, "RentalApplications"), where("applicant_id", "==", "visitorA"))));
  await assertFails(getDocs(col(ctx.ownerA, "ViewingRequests")), "unscoped list");
  await assertFails(getDocs(query(col(ctx.ownerA, "ViewingRequests"), where("owner_id", "==", "ownerB"))));
  await assertFails(getDocs(query(col(ctx.visitorA, "ViewingRequests"), where("requester_id", "==", "visitorB"))));
  await assertFails(getDocs(query(col(ctx.ag2, "ViewingRequests"), where("agency_id", "==", "ag1"))));
});

test("TAQ-112: nobody writes these collections from the client, not even the parties or SuperAdmin", async () => {
  const fresh = { requester_id: "visitorA", owner_id: "ownerA", listing_id: "p1", status: "pending" };
  for (const who of ["visitorA", "ownerA", "ag1", "admin", "sa", "unauth"]) {
    await assertFails(setDoc(doc(ctx[who], "ViewingRequests/new"), fresh), `create viewing ${who}`);
    await assertFails(setDoc(doc(ctx[who], "RentalApplications/new"), { ...fresh, applicant_id: "visitorA" }), `create application ${who}`);
    await assertFails(updateDoc(V(ctx[who]), { status: "confirmed" }), `update viewing ${who}`);
    await assertFails(updateDoc(A(ctx[who]), { status: "approved" }), `update application ${who}`);
    await assertFails(deleteDoc(V(ctx[who])), `delete viewing ${who}`);
    await assertFails(deleteDoc(A(ctx[who])), `delete application ${who}`);
  }
});
