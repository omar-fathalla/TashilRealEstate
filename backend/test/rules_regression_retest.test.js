// Regression suite carried over from User Test QA (021227b -> 90b89e6 -> 2d0a140).
// TAQ-51/TAQ-58: clients can no longer create or update /Properties; the owner/agency
// direct-write assertions are flipped to expect denial. Fixture data is fake.
// Retest of F-3/F-4/F-7/F-8 on 021227b (rules only). QA harness.
const fs = require("fs");
const path = require("path"); const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, collection, query, where, getDocs } = require("firebase/firestore");
let env; const c = {};
test.before(async () => { env = await initializeTestEnvironment({ projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test", firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") } }); });
test.after(async () => { if (env) await env.cleanup(); });
test.beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (x) => { const d = x.firestore();
    await setDoc(doc(d, "Users/ownerA"), { role: "Owner" }); await setDoc(doc(d, "Users/ownerB"), { role: "Owner" });
    await setDoc(doc(d, "Users/tenant"), { role: "Tenant" }); await setDoc(doc(d, "Users/norole"), { full_name: "x" });
    await setDoc(doc(d, "Properties/pub"), { id: "pub", owner_id: "ownerA", is_published: true, status: "vacant", titles: { en: "pub" }, pricePerMonth: 1000, agencyPhone: "+20 100 123 4567", agencyNames: { en: "Tashil" } });
    await setDoc(doc(d, "Properties/vacantUnpub"), { id: "vacantUnpub", owner_id: "ownerA", is_published: false, status: "vacant" });
    await setDoc(doc(d, "Properties/noflag"), { id: "noflag", owner_id: "ownerA", status: "vacant" });
    await setDoc(doc(d, "Properties/strflag"), { id: "strflag", owner_id: "ownerA", is_published: "true", status: "vacant" });
    await setDoc(doc(d, "Properties/agUnpub"), { id: "agUnpub", owner_id: "agXadmin", agency_id: "agX", is_published: false, status: "vacant" });
    await setDoc(doc(d, "Properties/tenantOld"), { id: "tenantOld", owner_id: "tenant", is_published: false, status: "draft" });
  });
  const mk = (u, cl) => env.authenticatedContext(u, cl).firestore();
  Object.assign(c, { ownerA: mk("ownerA"), ownerB: mk("ownerB"), tenant: mk("tenant"), norole: mk("norole"), tenantClaim: mk("tc", { role: "Tenant" }), agX: mk("agXadmin", { role: "AgencyAdmin", agency_id: "agX" }), agY: mk("agYadmin", { role: "AgencyAdmin", agency_id: "agY" }), sa: mk("sa", { role: "SuperAdmin" }), unauth: env.unauthenticatedContext().firestore() });
});
const P = (d, id) => doc(d, "Properties/" + id);
const base = (id, o = "ownerA") => ({ id, owner_id: o, is_published: true, status: "vacant", titles: { ar: "a", en: "e", hi: "h" }, pricePerMonth: 1000 });

// F-3 / TAQ-47
for (const f of ["whatsapp", "phone", "email", "ownerPhone", "tenant_name", "owner_name", "notes", "unit_number"]) {
  test(`TAQ-47 create with extra field ${f} denied`, async () => { await assertFails(setDoc(P(c.ownerA, "n_" + f), { ...base("n_" + f), [f]: "x" })); });
  test(`TAQ-47 update adding ${f} denied`, async () => { await assertFails(updateDoc(P(c.ownerA, "pub"), { [f]: "x" })); });
}
test("TAQ-47 agencyPhone/agencyNames: create and update denied for owner, allowed for SuperAdmin", async () => {
  await assertFails(setDoc(P(c.ownerA, "n_ap"), { ...base("n_ap"), agencyPhone: "+20 OWNER" }));
  await assertFails(setDoc(P(c.ownerA, "n_an"), { ...base("n_an"), agencyNames: { en: "Me" } }));
  await assertFails(updateDoc(P(c.ownerA, "pub"), { agencyPhone: "+20 OWNER" }));
  await assertFails(updateDoc(P(c.ownerA, "pub"), { agencyNames: { en: "Me", ar: "x", hi: "y" } }));
  await assertSucceeds(updateDoc(P(c.sa, "pub"), { agencyPhone: "+20 100 123 4567" }));
});
test("TAQ-47 nested extra locale key / mismatched id denied; clean create allowed", async () => {
  await assertFails(setDoc(P(c.ownerA, "n_loc"), { ...base("n_loc"), titles: { en: "x", phone: "0100" } }));
  await assertFails(setDoc(P(c.ownerA, "n_id"), { ...base("other-id") }));
  await assertFails(setDoc(P(c.ownerA, "n_ok"), base("n_ok")));  // TAQ-51: client /Properties writes are denied
  await assertFails(updateDoc(P(c.ownerA, "pub"), { pricePerMonth: 2000 }));  // TAQ-51: client /Properties writes are denied
});
test("TAQ-47 [probe] allowlisted fields with unsanitized values via direct client write", async (t) => {
  const r = {};
  for (const [k, v] of Object.entries({ rating: 999, isFeatured: true, imageUrls: ["javascript:alert(1)", "https://firebasestorage.googleapis.com/v0/b/x/o/kyc%2Fid.jpg"], image: "http://tracker.example/x.gif", pricePerMonth: -5, buildingName: "Call 01012345678", amenitiesMap: { en: "not-a-list" }, status: "anything" })) {
    try { await setDoc(P(c.ownerA, "pv_" + k), { ...base("pv_" + k), [k]: v }); r[k] = "ALLOWED"; } catch { r[k] = "denied"; }
  }
  t.diagnostic("PROBE " + JSON.stringify(r));
});

// F-4 / TAQ-48
for (const who of ["unauth", "ownerB", "tenant", "agY"]) {
  test(`TAQ-48 ${who} cannot get unpublished (vacant / missing flag / string flag / agency) listings`, async () => {
    for (const id of ["vacantUnpub", "noflag", "strflag", "agUnpub"]) await assertFails(getDoc(P(c[who], id)));
    await assertSucceeds(getDoc(P(c[who], "pub")));
  });
  test(`TAQ-48 ${who} list: status==vacant denied, is_published==true ok`, async () => {
    await assertFails(getDocs(query(collection(c[who], "Properties"), where("status", "==", "vacant"))));
    await assertFails(getDocs(collection(c[who], "Properties")));
    const s = await assertSucceeds(getDocs(query(collection(c[who], "Properties"), where("is_published", "==", true))));
    if (s.docs.map((d) => d.id).join() !== "pub") throw new Error("leak " + s.docs.map((d) => d.id));
  });
}
test("TAQ-48 owner/agency/SA still read own unpublished", async () => {
  await assertSucceeds(getDoc(P(c.ownerA, "vacantUnpub"))); await assertSucceeds(getDoc(P(c.agX, "agUnpub"))); await assertSucceeds(getDoc(P(c.sa, "noflag")));
});

// F-7 / TAQ-49
test("TAQ-49 Tenant (profile or claim) and no-role users cannot create or update listings", async () => {
  await assertFails(setDoc(P(c.tenant, "t1"), base("t1", "tenant")));
  await assertFails(setDoc(P(c.tenant, "t2"), { ...base("t2", "tenant"), is_published: false, status: "draft" }));
  await assertFails(setDoc(P(c.tenantClaim, "t3"), base("t3", "tc")));
  await assertFails(setDoc(P(c.norole, "t4"), base("t4", "norole")));
  await assertFails(updateDoc(P(c.tenant, "tenantOld"), { is_published: true }));
  await assertFails(setDoc(P(c.ownerA, "o1"), base("o1")));  // TAQ-51: client /Properties writes are denied
  await assertFails(setDoc(P(c.agX, "a1"), { ...base("a1", "agXadmin"), agency_id: "agX" }));  // TAQ-51: client /Properties writes are denied
});
test("TAQ-49 Tenant cannot self-switch to Owner to gain publish rights", async () => {
  await assertFails(updateDoc(doc(c.tenant, "Users/tenant"), { role: "Owner" }));
});

// F-8 / TAQ-50
for (const f of ["phone_verified", "phoneVerified", "kycStatus", "kyc_status", "account_status", "accountStatus"]) {
  test(`TAQ-50 ${f} locked on update, set-merge and create`, async () => {
    await assertFails(updateDoc(doc(c.ownerA, "Users/ownerA"), { [f]: true }));
    await assertFails(setDoc(doc(c.ownerA, "Users/ownerA"), { [f]: true, full_name: "x" }, { merge: true }));
    await assertFails(setDoc(doc(env.authenticatedContext("fresh").firestore(), "Users/fresh"), { role: "Owner", [f]: true }));
  });
}
test("TAQ-50 [probe] still-unlocked near names", async (t) => {
  const r = {};
  for (const f of ["is_verified", "kyc_verified", "isPhoneVerified", "email_verified", "Role", "role_updated_by", "plan"]) { try { await updateDoc(doc(c.ownerA, "Users/ownerA"), { [f]: true }); r[f] = "ALLOWED"; } catch { r[f] = "denied"; } }
  t.diagnostic("PROBE " + JSON.stringify(r));
});
