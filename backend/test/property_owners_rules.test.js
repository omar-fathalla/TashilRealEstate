// TAQ-110 N-1: rules for the property owner registry. An id registered to another owner cannot be
// created in a private tree, nobody writes or clears id_conflict, and PropertyOwners has no client
// access at all.
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, getDocs, collection, setDoc, updateDoc, deleteDoc, deleteField } = require("firebase/firestore");

const RULES = path.join(__dirname, "../../firestore.rules");
let env;
const ctx = {};

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
    "Users/ownerA/properties/taken": { title: "A's flat" },
    "PropertyOwners/taken": { owner_id: "ownerA", property_id: "taken" },
    "PropertyOwners/gone": { owner_id: "ownerA", property_id: "gone" },
    "Users/ownerB/properties/flagged": { title: "B's copy", id_conflict: true },
  });
  const mk = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  ctx.ownerA = mk("ownerA", { role: "Owner" });
  ctx.ownerB = mk("ownerB", { role: "Owner" });
  ctx.sa = mk("sa", { role: "SuperAdmin" });
  ctx.admin = mk("admin1", { role: "Admin" });
  ctx.tenant = mk("tenantA", { role: "Tenant" });
  ctx.unauth = env.unauthenticatedContext().firestore();
});

const P = (db, uid, id) => doc(db, `Users/${uid}/properties/${id}`);

test("TAQ-110 N-1: an id registered to another owner cannot be created in a private tree, by anyone", async () => {
  await assertFails(setDoc(P(ctx.ownerB, "ownerB", "taken"), { title: "squat" }));
  await assertFails(setDoc(P(ctx.ownerB, "ownerB", "gone"), { title: "deleted ids stay taken" }));
  await assertFails(setDoc(P(ctx.sa, "ownerB", "taken"), { title: "break-glass cannot squat either" }));
  await assertSucceeds(setDoc(P(ctx.ownerA, "ownerA", "gone"), { title: "the owner re-creates their id" }));
  await assertSucceeds(setDoc(P(ctx.ownerB, "ownerB", "free-id"), { title: "unregistered ids are free" }));
  await assertSucceeds(setDoc(P(ctx.ownerA, "ownerA", "taken"), { title: "edit" }, { merge: true }));
});

test("TAQ-110 N-1: no client writes or clears id_conflict, SuperAdmin included", async () => {
  await assertFails(setDoc(P(ctx.ownerA, "ownerA", "new-1"), { title: "x", id_conflict: false }));
  await assertFails(setDoc(P(ctx.ownerA, "ownerA", "new-2"), { title: "x", id_conflict: true }));
  await assertFails(setDoc(P(ctx.sa, "ownerA", "new-3"), { title: "x", id_conflict: false }));
  await assertFails(updateDoc(P(ctx.ownerA, "ownerA", "taken"), { id_conflict: true }));
  await assertFails(updateDoc(P(ctx.ownerB, "ownerB", "flagged"), { id_conflict: false }));
  await assertFails(updateDoc(P(ctx.ownerB, "ownerB", "flagged"), { id_conflict: deleteField() }));
  await assertFails(updateDoc(P(ctx.sa, "ownerB", "flagged"), { id_conflict: false }));
  await assertFails(setDoc(P(ctx.ownerB, "ownerB", "flagged"), { title: "replace drops the flag" }));
  await assertFails(updateDoc(P(ctx.ownerB, "ownerB", "flagged"), { id_conflict_at: null }));
  await assertSucceeds(updateDoc(P(ctx.ownerB, "ownerB", "flagged"), { title: "other edits are fine" }));
  await assertSucceeds(deleteDoc(P(ctx.ownerB, "ownerB", "flagged")));
});

test("TAQ-110 N-1: PropertyOwners has no client access", async () => {
  for (const db of [ctx.ownerA, ctx.ownerB, ctx.sa, ctx.admin, ctx.tenant, ctx.unauth]) {
    await assertFails(getDoc(doc(db, "PropertyOwners/taken")));
    await assertFails(getDocs(collection(db, "PropertyOwners")));
    await assertFails(setDoc(doc(db, "PropertyOwners/free-id"), { owner_id: "ownerB" }));
    await assertFails(updateDoc(doc(db, "PropertyOwners/taken"), { owner_id: "ownerB" }));
    await assertFails(deleteDoc(doc(db, "PropertyOwners/taken")));
  }
});
