// TAQ-110: the lease offer and the tenant's decision notify the right person, once.
const test = require("node:test");
const assert = require("node:assert/strict");
const { getFirestore } = require("firebase-admin/firestore");

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore and Auth emulators are attached.");
}

const fns = require("../index");
const db = getFirestore();
const projectId = process.env.GCLOUD_PROJECT;

const snap = (data) => ({ exists: Boolean(data), data: () => data });

async function run(leaseId, before, after) {
  return fns.notifyLeaseStatusChange.run({ params: { leaseId }, data: { before: snap(before), after: snap(after) } });
}

const lease = (status, extra = {}) => ({ tenant_id: "tenant", owner_id: "owner", property_title: "Marina Apartment", status, ...extra });

test.beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
});

const notes = async (uid) => (await db.collection("Users").doc(uid).collection("notifications").get()).docs.map((d) => d.data());

test("TAQ-110: a lease offered to the tenant notifies the tenant in all three languages", async () => {
  await run("l1", lease("draft"), lease("pending_tenant_approval"));
  const [note] = await notes("tenant");
  assert.equal(note.type, "lease_offer");
  assert.equal(note.recipientId, "tenant");
  assert.equal(note.leaseId, "l1");
  assert.equal(note.read, false);
  for (const lang of ["ar", "en", "hi"]) {
    assert.ok(note.title[lang] && note.body[lang], lang);
  }
  assert.match(note.body.en, /Marina Apartment/);
  assert.equal((await notes("owner")).length, 0);
});

test("TAQ-110: the tenant's approval and rejection notify the owner", async () => {
  await run("l1", lease("pending_tenant_approval"), lease("active"));
  await run("l2", lease("pending_tenant_approval"), lease("rejected"));
  const types = (await notes("owner")).map((n) => n.type).sort();
  assert.deepEqual(types, ["lease_approved", "lease_rejected"]);
  assert.equal((await notes("tenant")).length, 0);
});

test("TAQ-110: a replayed event does not duplicate the notification", async () => {
  await run("l1", lease("draft"), lease("pending_tenant_approval"));
  await run("l1", lease("draft"), lease("pending_tenant_approval"));
  assert.equal((await notes("tenant")).length, 1);
});

test("TAQ-110: edits that do not change the status, and other moves, send nothing", async () => {
  await run("l1", lease("draft"), lease("draft", { monthly_rent: 6000 }));
  await run("l1", lease("active"), lease("expired"));
  await run("l1", lease("active"), lease("terminated"));
  await run("l1", lease("pending_tenant_approval"), lease("draft"));
  await run("l1", lease("draft"), null);
  await run("l1", null, lease("draft"));
  assert.equal((await notes("tenant")).length, 0);
  assert.equal((await notes("owner")).length, 0);
});

test("TAQ-110: a lease created straight as an offer notifies the tenant", async () => {
  await run("l9", null, lease("pending_tenant_approval"));
  assert.equal((await notes("tenant")).length, 1);
});

test("TAQ-110: the agency admin who created the lease hears the tenant's decision too, once", async () => {
  await run("l1", lease("pending_tenant_approval", { created_by: "agadmin" }), lease("active", { created_by: "agadmin" }));
  await run("l2", lease("pending_tenant_approval", { created_by: "agadmin" }), lease("rejected", { created_by: "agadmin" }));
  const agency = await notes("agadmin");
  assert.deepEqual(agency.map((n) => n.type).sort(), ["lease_approved", "lease_rejected"]);
  assert.ok(agency.every((n) => n.recipientId === "agadmin"));
  assert.equal((await notes("owner")).length, 2);
  await run("l3", lease("pending_tenant_approval", { created_by: "owner" }), lease("active", { created_by: "owner" }));
  assert.equal((await notes("owner")).length, 3, "an owner who created the lease gets one notification");
  await run("l4", lease("pending_tenant_approval", { created_by: "tenant" }), lease("active", { created_by: "tenant" }));
  await run("l5", lease("pending_tenant_approval", { created_by: "a/b" }), lease("active", { created_by: "a/b" }));
  assert.equal((await notes("tenant")).length, 0);
});
