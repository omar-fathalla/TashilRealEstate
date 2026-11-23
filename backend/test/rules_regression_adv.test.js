// Regression suite carried over from User Test QA (021227b -> 90b89e6 -> 2d0a140).
// TAQ-51/TAQ-58: clients can no longer create or update /Properties; the owner/agency
// direct-write assertions are flipped to expect denial. Fixture data is fake.
// Adversarial Firestore rules tests for TAQ-8/9/10/11 (QA harness, not part of the repo).
const fs = require("fs");
const path = require("path");
const test = require("node:test");
const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, updateDoc, deleteDoc, deleteField, collection, collectionGroup, query, where, getDocs, documentId } = require("firebase/firestore");

const RULES = path.join(__dirname, "../../firestore.rules");
let env;
const ctx = {};
test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "demo-tashil-test",
    firestore: { rules: fs.readFileSync(RULES, "utf8") },
  });
});
test.after(async () => { if (env) await env.cleanup(); });
test.beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    const d = c.firestore();
    await setDoc(doc(d, "Users/ownerA"), { role: "Owner", full_name: "A", national_id: "29001010101010", iban: "EG00", status: "active", verified: false });
    await setDoc(doc(d, "Users/ownerB"), { role: "Owner", full_name: "B" });
    await setDoc(doc(d, "Users/tenant"), { role: "Tenant" });
    await setDoc(doc(d, "Users/legacySA"), { role: "SuperAdmin" });        // legacy self-assigned, no claim
    await setDoc(doc(d, "Users/legacyAG"), { role: "AgencyAdmin", agency_id: "agX" }); // legacy, no claim
    await setDoc(doc(d, "Users/norole"), { full_name: "no role yet" });
    await setDoc(doc(d, "Users/ownerA/properties/pA"), { title: "private tree" });
    await setDoc(doc(d, "Properties/pub"), { owner_id: "ownerA", is_published: true, status: "vacant", titles: { en: "x" } });
    await setDoc(doc(d, "Properties/draft"), { owner_id: "ownerA", is_published: false, status: "draft" });
    await setDoc(doc(d, "Properties/vacantUnpub"), { owner_id: "ownerA", is_published: false, status: "vacant" });
    await setDoc(doc(d, "Properties/rented"), { owner_id: "ownerA", is_published: false, status: "rented" });
    await setDoc(doc(d, "Properties/agDraft"), { owner_id: "ownerA", agency_id: "agX", is_published: false, status: "draft" });
  });
  const mk = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
  ctx.ownerA = mk("ownerA");                       // real signup flow: no claim, profile role Owner
  ctx.ownerB = mk("ownerB");
  ctx.tenant = mk("tenant");
  ctx.legacySA = mk("legacySA");
  ctx.legacyAG = mk("legacyAG");
  ctx.norole = mk("norole");
  ctx.fresh = mk("fresh");                         // brand-new user, no profile
  ctx.agX = mk("agXadmin", { role: "AgencyAdmin", agency_id: "agX" });
  ctx.agY = mk("agYadmin", { role: "AgencyAdmin", agency_id: "agY" });
  ctx.sa = mk("sa", { role: "SuperAdmin" });
  ctx.unauth = env.unauthenticatedContext().firestore();
});
const U = (d, id) => doc(d, "Users/" + id);
const P = (d, id) => doc(d, "Properties/" + id);

// ---------------- TAQ-8: signup / role injection ----------------
for (const role of ["AgencyAdmin", "SuperAdmin", "superadmin", "Agency", "Admin", " Owner", "owner"]) {
  test(`TAQ-8 create own Users doc with role=${JSON.stringify(role)} is denied`, async () => {
    await assertFails(setDoc(U(ctx.fresh, "fresh"), { role, email: "f@x.test" }));
  });
}
test("TAQ-8 create with role as array/map is denied", async () => {
  await assertFails(setDoc(U(ctx.fresh, "fresh"), { role: ["Owner"] }));
  await assertFails(setDoc(U(ctx.fresh, "fresh"), { role: { v: "SuperAdmin" } }));
});
for (const role of ["Owner", "Tenant", undefined]) {
  test(`TAQ-8 create own Users doc with role=${role} is allowed`, async () => {
    const data = { email: "f@x.test", full_name: "F" }; if (role) data.role = role;
    await assertSucceeds(setDoc(U(ctx.fresh, "fresh"), data));
  });
}
for (const f of ["agency_id", "agencyId", "verified", "isVerified", "status", "isSuperAdmin", "customClaims", "claims"]) {
  test(`TAQ-8 create Owner profile carrying locked field ${f} is denied`, async () => {
    await assertFails(setDoc(U(ctx.fresh, "fresh"), { role: "Owner", [f]: f === "agency_id" || f === "agencyId" ? "agX" : true }));
  });
}
test("TAQ-8 cannot create a Users doc for another uid", async () => {
  await assertFails(setDoc(U(ctx.fresh, "victim"), { role: "Owner" }));
  await assertFails(setDoc(U(ctx.unauth, "victim"), { role: "Owner" }));
});
test("TAQ-8 legacy self-assigned SuperAdmin profile (no claim) gets no admin power", async () => {
  await assertFails(getDoc(U(ctx.legacySA, "ownerA")));
  await assertFails(updateDoc(U(ctx.legacySA, "ownerA"), { role: "Tenant" }));
  await assertFails(getDoc(P(ctx.legacySA, "draft")));
  await assertFails(deleteDoc(P(ctx.legacySA, "pub")));
});
test("TAQ-8 legacy self-assigned AgencyAdmin profile (no claim) cannot act as agency agX", async () => {
  await assertFails(getDoc(P(ctx.legacyAG, "agDraft")));
  await assertFails(setDoc(P(ctx.legacyAG, "newAg"), { owner_id: "legacyAG", agency_id: "agX" }));
});

// ---------------- TAQ-9: self-update of locked fields ----------------
const locked = { role: "SuperAdmin", agency_id: "agX", agencyId: "agX", verified: true, isVerified: true, status: "approved", isSuperAdmin: true, customClaims: { role: "SuperAdmin" }, claims: { role: "SuperAdmin" } };
for (const [f, v] of Object.entries(locked)) {
  test(`TAQ-9 updateDoc ${f} alone is denied`, async () => { await assertFails(updateDoc(U(ctx.ownerA, "ownerA"), { [f]: v })); });
  test(`TAQ-9 updateDoc ${f} mixed with full_name is denied`, async () => { await assertFails(updateDoc(U(ctx.ownerA, "ownerA"), { [f]: v, full_name: "ok" })); });
  test(`TAQ-9 set-merge ${f} is denied`, async () => { await assertFails(setDoc(U(ctx.ownerA, "ownerA"), { [f]: v, full_name: "ok" }, { merge: true })); });
}
test("TAQ-9 role Owner->Tenant (self-service switch) is denied", async () => {
  await assertFails(updateDoc(U(ctx.ownerA, "ownerA"), { role: "Tenant" }));
});
test("TAQ-9 deleting role / status / verified fields is denied", async () => {
  await assertFails(updateDoc(U(ctx.ownerA, "ownerA"), { role: deleteField() }));
  await assertFails(updateDoc(U(ctx.ownerA, "ownerA"), { status: deleteField() }));
  await assertFails(updateDoc(U(ctx.ownerA, "ownerA"), { verified: deleteField() }));
});
test("TAQ-9 create-overwrite (set without merge) that changes role or drops locked fields is denied", async () => {
  await assertFails(setDoc(U(ctx.ownerA, "ownerA"), { role: "SuperAdmin", full_name: "A" }));
  await assertFails(setDoc(U(ctx.ownerA, "ownerA"), { role: "Owner", full_name: "A" })); // drops status/verified/national_id...
});
test("TAQ-9 allowed self edits (name, phone, photo, national_id, bank) succeed", async () => {
  await assertSucceeds(updateDoc(U(ctx.ownerA, "ownerA"), { full_name: "New", phone: "01000000000", photo_url: "https://x/y.png", national_id: "29001010101011", iban: "EG11", bank_name: "B" }));
  await assertSucceeds(setDoc(U(ctx.ownerA, "ownerA"), { first_name: "N", surname: "S" }, { merge: true }));
});
test("TAQ-9 profile without role may pick Owner/Tenant once, never elevated", async () => {
  await assertFails(updateDoc(U(ctx.norole, "norole"), { role: "SuperAdmin" }));
  await assertFails(updateDoc(U(ctx.norole, "norole"), { role: "AgencyAdmin" }));
  await assertSucceeds(updateDoc(U(ctx.norole, "norole"), { role: "Tenant" }));
});
test("TAQ-9 [probe] unlocked verification-like fields a user CAN self-set", async (t) => {
  const res = {};
  for (const f of ["phone_verified", "is_verified", "kyc_verified", "kycStatus", "account_status", "Role", "role_updated_by", "plan"]) {
    try { await updateDoc(U(ctx.ownerA, "ownerA"), { [f]: f === "Role" ? "SuperAdmin" : true }); res[f] = "ALLOWED"; } catch { res[f] = "denied"; }
  }
  t.diagnostic("PROBE " + JSON.stringify(res));
});
test("TAQ-9 another user cannot update my profile", async () => {
  await assertFails(updateDoc(U(ctx.ownerB, "ownerA"), { full_name: "pwn" }));
  await assertFails(updateDoc(U(ctx.agX, "ownerA"), { full_name: "pwn" }));
  await assertFails(deleteDoc(U(ctx.ownerA, "ownerA"))); // self delete is SuperAdmin-only
});
test("TAQ-9 SuperAdmin claim can update role field", async () => {
  await assertSucceeds(updateDoc(U(ctx.sa, "ownerA"), { verified: true }));
});

// ---------------- TAQ-10: Users read ----------------
for (const who of ["ownerB", "tenant", "agX", "agY", "legacySA", "unauth"]) {
  test(`TAQ-10 ${who} cannot get Users/ownerA`, async () => { await assertFails(getDoc(U(ctx[who], "ownerA"))); });
}
test("TAQ-10 owner and SuperAdmin can get Users/ownerA", async () => {
  await assertSucceeds(getDoc(U(ctx.ownerA, "ownerA")));
  await assertSucceeds(getDoc(U(ctx.sa, "ownerA")));
});
for (const who of ["ownerA", "ownerB", "tenant", "agX", "unauth"]) {
  test(`TAQ-10 ${who} cannot list the Users collection`, async () => {
    await assertFails(getDocs(collection(ctx[who], "Users")));
    await assertFails(getDocs(query(collection(ctx[who], "Users"), where("role", "==", "Owner"))));
  });
}
test("TAQ-10 ownerB cannot query Users by documentId==ownerA; ownerA can query self", async () => {
  await assertFails(getDocs(query(collection(ctx.ownerB, "Users"), where(documentId(), "==", "ownerA"))));
  await assertSucceeds(getDocs(query(collection(ctx.ownerA, "Users"), where(documentId(), "==", "ownerA"))));
});
test("TAQ-10 collectionGroup reads of private subcollections are denied", async () => {
  for (const who of ["ownerB", "tenant", "agX", "unauth"]) {
    await assertFails(getDocs(collectionGroup(ctx[who], "properties")));
    await assertFails(getDocs(collectionGroup(ctx[who], "notifications")));
  }
  await assertFails(getDoc(doc(ctx.ownerB, "Users/ownerA/properties/pA")));
});
test("TAQ-10 nobody can write notifications subcollection from the client", async () => {
  await assertFails(setDoc(doc(ctx.ownerA, "Users/ownerA/notifications/n1"), { x: 1 }));
  await assertFails(setDoc(doc(ctx.ownerB, "Users/ownerA/notifications/n1"), { x: 1 }));
});

// ---------------- TAQ-11: listings ----------------
test("TAQ-11 create in own name allowed; in another's name / no owner denied", async () => {
  await assertFails(setDoc(P(ctx.ownerA, "n1"), { owner_id: "ownerA", is_published: false, status: "draft" }));  // TAQ-51: client /Properties writes are denied
  await assertFails(setDoc(P(ctx.ownerA, "n2"), { owner_id: "ownerB" }));
  await assertFails(setDoc(P(ctx.ownerA, "n3"), { title: "no owner" }));
  await assertFails(setDoc(P(ctx.unauth, "n4"), { owner_id: "ownerA" }));
  await assertFails(setDoc(P(ctx.ownerA, "n5"), { owner_id: null }));
});
test("TAQ-11 owner cannot self-attach an agency on create; agency only its own", async () => {
  await assertFails(setDoc(P(ctx.ownerA, "n6"), { owner_id: "ownerA", agency_id: "agX" }));
  await assertFails(setDoc(P(ctx.agX, "n7"), { owner_id: "agXadmin", agency_id: "agX" }));  // TAQ-51: client /Properties writes are denied
  await assertFails(setDoc(P(ctx.agX, "n8"), { owner_id: "agXadmin", agency_id: "agY" }));
  await assertFails(setDoc(P(ctx.agX, "n9"), { owner_id: "ownerA", agency_id: "agX" }));
});
test("TAQ-11 create overwrite of an existing listing by another user is denied (treated as update)", async () => {
  await assertFails(setDoc(P(ctx.ownerB, "pub"), { owner_id: "ownerB", is_published: true, status: "vacant" }));
});
test("TAQ-11 private fields rejected on create and update", async () => {
  await assertFails(setDoc(P(ctx.ownerA, "n10"), { owner_id: "ownerA", tenantPhone: "0100" }));
  await assertFails(updateDoc(P(ctx.ownerA, "pub"), { ownerPhone: "0100" }));
  await assertFails(updateDoc(P(ctx.ownerA, "pub"), { unitNumber: "12" }));
});
test("TAQ-11 [probe] near-miss private field names accepted on public /Properties", async (t) => {
  const res = {};
  for (const f of ["tenant_name", "tenant_phone", "owner_name", "phone", "email", "whatsapp", "unit_number", "lease_end_date", "national_id_number"]) {
    try { await setDoc(P(ctx.ownerA, "probe_" + f), { owner_id: "ownerA", is_published: true, status: "vacant", [f]: "x" }); res[f] = "ALLOWED"; } catch { res[f] = "denied"; }
  }
  t.diagnostic("PROBE " + JSON.stringify(res));
});
test("TAQ-11 owner_id / agency_id immutable on update (update, merge, overwrite, delete-field)", async () => {
  await assertFails(updateDoc(P(ctx.ownerA, "pub"), { owner_id: "ownerB" }));
  await assertFails(updateDoc(P(ctx.ownerA, "pub"), { agency_id: "agX" }));
  await assertFails(setDoc(P(ctx.ownerA, "pub"), { owner_id: "ownerB" }, { merge: true }));
  await assertFails(setDoc(P(ctx.ownerA, "pub"), { is_published: true }));            // overwrite drops owner_id
  await assertFails(updateDoc(P(ctx.ownerA, "pub"), { owner_id: deleteField() }));
  await assertFails(updateDoc(P(ctx.agX, "agDraft"), { agency_id: "agY" }));
  await assertFails(updateDoc(P(ctx.agX, "agDraft"), { owner_id: "agXadmin" }));
  await assertFails(updateDoc(P(ctx.ownerA, "pub"), { pricePerMonth: 9000 }));  // TAQ-51: client /Properties writes are denied
  await assertFails(updateDoc(P(ctx.agX, "agDraft"), { pricePerMonth: 1 }));  // TAQ-51: client /Properties writes are denied
});
test("TAQ-11 others cannot update/delete my listing", async () => {
  for (const who of ["ownerB", "tenant", "agY", "unauth", "legacySA"]) {
    await assertFails(updateDoc(P(ctx[who], "pub"), { pricePerMonth: 1 }));
    await assertFails(deleteDoc(P(ctx[who], "pub")));
  }
});
for (const who of ["ownerB", "tenant", "agY", "unauth", "legacySA", "legacyAG"]) {
  test(`TAQ-11 ${who} cannot get unpublished draft/rented listings`, async () => {
    await assertFails(getDoc(P(ctx[who], "draft")));
    await assertFails(getDoc(P(ctx[who], "rented")));
    await assertFails(getDoc(P(ctx[who], "agDraft")));
  });
}
test("TAQ-11 owner, its agency and SuperAdmin can read drafts", async () => {
  await assertSucceeds(getDoc(P(ctx.ownerA, "draft")));
  await assertSucceeds(getDoc(P(ctx.agX, "agDraft")));
  await assertSucceeds(getDoc(P(ctx.sa, "draft")));
});
test("TAQ-11 [finding probe] unpublished listing with status 'vacant' is readable by unauth/other users", async (t) => {
  const res = {};
  for (const who of ["unauth", "ownerB", "tenant"]) {
    try { const s = await getDoc(P(ctx[who], "vacantUnpub")); res[who] = s.exists() ? "READABLE" : "missing"; } catch { res[who] = "denied"; }
  }
  try { const s = await getDocs(query(collection(ctx.unauth, "Properties"), where("status", "==", "vacant"))); res.unauthListStatusVacant = s.docs.map((d) => d.id); } catch { res.unauthListStatusVacant = "denied"; }
  t.diagnostic("PROBE " + JSON.stringify(res));
});
test("TAQ-11 list queries: published filter OK for unauth; unfiltered / other-owner lists denied", async () => {
  const pubQ = await assertSucceeds(getDocs(query(collection(ctx.unauth, "Properties"), where("is_published", "==", true))));
  if (pubQ.docs.some((d) => d.id !== "pub")) throw new Error("published query leaked " + pubQ.docs.map((d) => d.id));
  for (const who of ["unauth", "ownerB", "tenant", "agY"]) {
    await assertFails(getDocs(collection(ctx[who], "Properties")));
    await assertFails(getDocs(query(collection(ctx[who], "Properties"), where("owner_id", "==", "ownerA"))));
    await assertFails(getDocs(query(collection(ctx[who], "Properties"), where("is_published", "==", false))));
  }
  await assertSucceeds(getDocs(query(collection(ctx.ownerA, "Properties"), where("owner_id", "==", "ownerA"))));
  await assertSucceeds(getDocs(query(collection(ctx.agX, "Properties"), where("agency_id", "==", "agX"))));
});
test("TAQ-11 [probe] Tenant can create a published public listing in own name", async (t) => {
  let r; try { await setDoc(P(ctx.tenant, "tenantListing"), { owner_id: "tenant", is_published: true, status: "vacant" }); r = "ALLOWED"; } catch { r = "denied"; }
  t.diagnostic("PROBE tenantCreatesListing=" + r);
});

// ---------------- Leases (supporting TAQ-17) ----------------
test("Leases: only agency/SuperAdmin create; owner/tenant cannot forge a lease", async () => {
  await assertFails(setDoc(doc(ctx.ownerB, "Leases/forged"), { owner_id: "ownerB", tenant_id: "tenant", agency_id: "", country_code: "EG", financialTerms: { monthlyRent: 1 } }));
  await assertFails(setDoc(doc(ctx.tenant, "Leases/forged"), { owner_id: "tenant", tenant_id: "tenant" }));
  await assertFails(setDoc(doc(ctx.agY, "Leases/forged"), { owner_id: "ownerA", agency_id: "agX" }));
  await assertSucceeds(setDoc(doc(ctx.agX, "Leases/ok"), { owner_id: "ownerA", tenant_id: "tenant", agency_id: "agX" }));
  await assertFails(updateDoc(doc(ctx.agX, "Leases/ok"), { agency_id: "agY" }));
});
