/**
 * TAQ-169 (B): agency team invites. An AgencyAdmin invites staff by email; the invitee accepts
 * with that verified email and becomes the agency's AgencyAgent through applyUserRole.
 *
 *   inviteAgencyAgent    AgencyAdmin        -> AgencyInvites/{id} "pending", expires in 7 days
 *   revokeAgencyInvite   AgencyAdmin/SA     -> "revoked"
 *   listAgencyTeam       AgencyAdmin/SA     -> the agency's agents and open invites
 *   listMyAgencyInvites  the invitee        -> open invites for the caller's verified email
 *   acceptAgencyInvite   the invitee        -> AgencyAgent claim + AgencyAgents/{uid}
 *   declineAgencyInvite  the invitee        -> "declined"
 *   removeAgencyAgent    AgencyAdmin/SA     -> back to the agent's earlier self-service role
 *
 * AgencyInvites and AgencyAgents are server-only (rules deny every client read and write). An
 * agency has at most 20 open invites and 20 agents; an admin sends at most 30 invites a day. Only
 * a user holding a self-service role (or none) can accept, and not while they are a party to an
 * open lease or own a managed property (the same check as an agency approval). Each change is in
 * the audit log (TAQ-193).
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

if (!admin.apps.length) {
  admin.initializeApp();
}

const { SELF_SERVICE_ROLES, AGENCY_AGENT, requireFreshAuth, requireRole, resolveRole } = require("./authz");
const { appCheckEnforced } = require("./config");
const { applyUserRole } = require("./roles");
const { approvalBlocker } = require("./agency_applications");
const { writeAuditLog } = require("./audit_log");

const ENFORCE_APP_CHECK = appCheckEnforced();
const INVITES = "AgencyInvites";
const AGENTS = "AgencyAgents";
const RATE_LIMITS = "AiRateLimits";
const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const MAX_OPEN_INVITES = 20;
const MAX_AGENTS = 20;
const MAX_INVITES_PER_DAY = 30;
const EMAIL = /^[^\s@]{1,64}@[^\s@]{1,190}\.[^\s@]{2,63}$/;
const ID = /^[A-Za-z0-9_-]{1,128}$/;

const deps = { now: () => Date.now() };
const opts = { enforceAppCheck: ENFORCE_APP_CHECK, maxInstances: 10 };

function invalid(message, reason) {
  return new HttpsError("invalid-argument", message, { reason });
}

function normaliseEmail(value) {
  if (typeof value !== "string") throw invalid("An email is required.", "email_invalid");
  const email = value.trim().toLowerCase();
  if (!EMAIL.test(email)) throw invalid("That email is not valid.", "email_invalid");
  return email;
}

function idFrom(value, field) {
  if (typeof value !== "string" || !ID.test(value)) throw invalid(`${field} is required.`, `${field}_invalid`);
  return value;
}

function isAnonymous(auth) {
  return Boolean(auth.token && auth.token.firebase && auth.token.firebase.sign_in_provider === "anonymous");
}

/** The caller's verified email, or a refusal. */
function verifiedEmail(auth) {
  const token = auth.token || {};
  if (isAnonymous(auth) || typeof token.email !== "string" || token.email_verified !== true) {
    throw new HttpsError("failed-precondition", "Verify your email first.", { reason: "email_not_verified" });
  }
  return token.email.trim().toLowerCase();
}

/** The agency an admin call acts on: the AgencyAdmin's own, or any for a SuperAdmin. */
async function managedAgency(auth, data) {
  const role = await requireRole(auth, ["AgencyAdmin", "SuperAdmin"]);
  if (role === "SuperAdmin") return { role, agencyId: idFrom(data.agencyId, "agencyId") };
  const agencyId = auth.token && auth.token.agency_id;
  if (typeof agencyId !== "string" || !ID.test(agencyId)) {
    throw new HttpsError("permission-denied", "Your account has no agency.");
  }
  return { role, agencyId };
}

const millis = (value) => (value instanceof Timestamp ? value.toMillis() : null);
const isOpen = (invite, now) => invite.status === "pending" && millis(invite.expires_at) > now;

async function countInvitesToday(db, uid, now) {
  const ref = db.collection(RATE_LIMITS).doc(`team_invite_${uid}`);
  const day = new Date(now).toISOString().slice(0, 10);
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const count = snap.exists && snap.get("day") === day ? snap.get("count") || 0 : 0;
    if (count >= MAX_INVITES_PER_DAY) {
      throw new HttpsError("resource-exhausted", "The daily invite limit has been reached.", { reason: "invite_daily_limit" });
    }
    t.set(ref, { day, count: count + 1, updated_at: FieldValue.serverTimestamp() });
  });
}

const inviteAgencyAgent = onCall(opts, async (request) => {
  const auth = await requireFreshAuth(request);
  await requireRole(auth, ["AgencyAdmin"]);
  const { agencyId } = await managedAgency(auth, {});
  const email = normaliseEmail((request.data || {}).email);
  if (auth.token && typeof auth.token.email === "string" && auth.token.email.trim().toLowerCase() === email) {
    throw invalid("You cannot invite yourself.", "self_invite");
  }
  const db = admin.firestore();
  const now = deps.now();
  const agency = await db.collection("Agencies").doc(agencyId).get();
  if (!agency.exists) throw new HttpsError("failed-precondition", "That agency does not exist.", { reason: "agency_not_found" });
  const pending = await db.collection(INVITES).where("agency_id", "==", agencyId).where("status", "==", "pending").get();
  const open = pending.docs.map((d) => d.data()).filter((invite) => isOpen(invite, now));
  if (open.some((invite) => invite.email === email)) {
    throw new HttpsError("already-exists", "That email already has an open invite.", { reason: "invite_exists" });
  }
  if (open.length >= MAX_OPEN_INVITES) {
    throw new HttpsError("resource-exhausted", "Too many open invites.", { reason: "too_many_invites" });
  }
  const agents = await db.collection(AGENTS).where("agency_id", "==", agencyId).count().get();
  if (agents.data().count >= MAX_AGENTS) {
    throw new HttpsError("resource-exhausted", "The agency already has the most agents allowed.", { reason: "too_many_agents" });
  }
  await countInvitesToday(db, auth.uid, now);
  const ref = db.collection(INVITES).doc();
  await ref.set({
    agency_id: agencyId,
    agency_name: String(agency.get("name") || "").slice(0, 200),
    email,
    status: "pending",
    invited_by: auth.uid,
    created_at: FieldValue.serverTimestamp(),
    expires_at: Timestamp.fromMillis(now + INVITE_TTL_MS),
  });
  await writeAuditLog({ action: "agency_agent_invited", actorUid: auth.uid, actorRole: "AgencyAdmin", targetPath: `${INVITES}/${ref.id}`, details: { agency_id: agencyId } });
  return { success: true, inviteId: ref.id, expiresAt: now + INVITE_TTL_MS };
});

const revokeAgencyInvite = onCall(opts, async (request) => {
  const auth = await requireFreshAuth(request);
  const data = request.data || {};
  const { role, agencyId } = await managedAgency(auth, data);
  const ref = admin.firestore().collection(INVITES).doc(idFrom(data.inviteId, "inviteId"));
  const snap = await ref.get();
  if (!snap.exists || snap.get("agency_id") !== agencyId) throw new HttpsError("not-found", "Invite not found.");
  if (snap.get("status") !== "pending") {
    throw new HttpsError("failed-precondition", "This invite is no longer open.", { reason: "invite_not_pending" });
  }
  await ref.update({ status: "revoked", revoked_by: auth.uid, updated_at: FieldValue.serverTimestamp() });
  await writeAuditLog({ action: "agency_invite_revoked", actorUid: auth.uid, actorRole: role, targetPath: ref.path, details: { agency_id: agencyId } });
  return { success: true };
});

const listAgencyTeam = onCall(opts, async (request) => {
  const auth = await requireFreshAuth(request);
  const { agencyId } = await managedAgency(auth, request.data || {});
  const db = admin.firestore();
  const now = deps.now();
  const [agents, invites] = await Promise.all([
    db.collection(AGENTS).where("agency_id", "==", agencyId).limit(MAX_AGENTS * 2).get(),
    db.collection(INVITES).where("agency_id", "==", agencyId).where("status", "==", "pending").limit(MAX_OPEN_INVITES * 5).get(),
  ]);
  return {
    agents: agents.docs.map((d) => ({
      uid: d.id,
      email: d.get("email") || "",
      displayName: d.get("display_name") || "",
      joinedAt: millis(d.get("joined_at")),
    })),
    invites: invites.docs
      .filter((d) => isOpen(d.data(), now))
      .map((d) => ({ id: d.id, email: d.get("email"), expiresAt: millis(d.get("expires_at")) })),
  };
});

const listMyAgencyInvites = onCall(opts, async (request) => {
  const auth = await requireFreshAuth(request);
  const email = verifiedEmail(auth);
  const now = deps.now();
  const snap = await admin.firestore().collection(INVITES).where("email", "==", email).where("status", "==", "pending").limit(20).get();
  return {
    invites: snap.docs
      .filter((d) => isOpen(d.data(), now))
      .map((d) => ({ id: d.id, agencyId: d.get("agency_id"), agencyName: d.get("agency_name") || "", expiresAt: millis(d.get("expires_at")) })),
  };
});

/** The invite the caller may answer: open, and for the caller's verified email. */
async function ownOpenInvite(auth, data) {
  const email = verifiedEmail(auth);
  const ref = admin.firestore().collection(INVITES).doc(idFrom(data.inviteId, "inviteId"));
  const snap = await ref.get();
  if (!snap.exists || snap.get("email") !== email) throw new HttpsError("not-found", "Invite not found.");
  if (!isOpen(snap.data(), deps.now())) {
    throw new HttpsError("failed-precondition", "This invite is no longer open.", { reason: "invite_not_open" });
  }
  return { ref, invite: snap.data() };
}

const declineAgencyInvite = onCall(opts, async (request) => {
  const auth = await requireFreshAuth(request);
  const { ref } = await ownOpenInvite(auth, request.data || {});
  await ref.update({ status: "declined", answered_by: auth.uid, updated_at: FieldValue.serverTimestamp() });
  return { success: true };
});

const acceptAgencyInvite = onCall(opts, async (request) => {
  const auth = await requireFreshAuth(request);
  const { ref, invite } = await ownOpenInvite(auth, request.data || {});
  const role = await resolveRole(auth);
  if (role && !SELF_SERVICE_ROLES.includes(role)) {
    throw new HttpsError("failed-precondition", "Your account already has a staff role.", { reason: "role_not_self_service" });
  }
  const db = admin.firestore();
  const blocker = await approvalBlocker(db, auth.uid);
  if (blocker) {
    throw new HttpsError("failed-precondition", "You still have leases or managed properties.", { reason: blocker });
  }
  const agents = await db.collection(AGENTS).where("agency_id", "==", invite.agency_id).count().get();
  if (agents.data().count >= MAX_AGENTS) {
    throw new HttpsError("resource-exhausted", "The agency already has the most agents allowed.", { reason: "too_many_agents" });
  }
  // Claim the invite first so it can be used once.
  await db.runTransaction(async (t) => {
    const fresh = await t.get(ref);
    if (!fresh.exists || !isOpen(fresh.data(), deps.now())) {
      throw new HttpsError("failed-precondition", "This invite is no longer open.", { reason: "invite_not_open" });
    }
    t.update(ref, { status: "accepted", answered_by: auth.uid, updated_at: FieldValue.serverTimestamp() });
  });
  try {
    await applyUserRole({ uid: auth.uid, role: AGENCY_AGENT, agencyId: invite.agency_id, actorUid: auth.uid, allowAgencyAgent: true });
  } catch (err) {
    await ref.update({ status: "pending", answered_by: FieldValue.delete() });
    throw err;
  }
  await db.collection(AGENTS).doc(auth.uid).set({
    agency_id: invite.agency_id,
    email: invite.email,
    display_name: String((auth.token && auth.token.name) || "").slice(0, 200),
    previous_role: role || "",
    invite_id: ref.id,
    joined_at: FieldValue.serverTimestamp(),
  });
  await writeAuditLog({ action: "agency_agent_joined", actorUid: auth.uid, actorRole: role || "", targetUid: auth.uid, details: { agency_id: invite.agency_id, invite_id: ref.id } });
  return { success: true, agencyId: invite.agency_id };
});

const removeAgencyAgent = onCall(opts, async (request) => {
  const auth = await requireFreshAuth(request);
  const data = request.data || {};
  const { role, agencyId } = await managedAgency(auth, data);
  const uid = idFrom(data.uid, "uid");
  const db = admin.firestore();
  const member = await db.collection(AGENTS).doc(uid).get();
  if (!member.exists || member.get("agency_id") !== agencyId) throw new HttpsError("not-found", "Agent not found.");
  let claims = {};
  try {
    claims = (await admin.auth().getUser(uid)).customClaims || {};
  } catch (err) {
    if (err.code !== "auth/user-not-found") throw err;
  }
  if (claims.role === AGENCY_AGENT && claims.agency_id === agencyId) {
    const previous = member.get("previous_role");
    const backTo = SELF_SERVICE_ROLES.includes(previous) ? previous : "Tenant";
    await applyUserRole({ uid, role: backTo, actorUid: auth.uid });
  }
  await member.ref.delete();
  await writeAuditLog({ action: "agency_agent_removed", actorUid: auth.uid, actorRole: role, targetUid: uid, details: { agency_id: agencyId } });
  return { success: true };
});

module.exports = {
  INVITES,
  AGENTS,
  MAX_OPEN_INVITES,
  MAX_AGENTS,
  deps,
  inviteAgencyAgent,
  revokeAgencyInvite,
  listAgencyTeam,
  listMyAgencyInvites,
  acceptAgencyInvite,
  declineAgencyInvite,
  removeAgencyAgent,
};
