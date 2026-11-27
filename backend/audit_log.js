/**
 * TAQ-193: server-written audit trail for SuperAdmin-level changes.
 *
 * `AuditLog/{id}` is written only by the Admin SDK (rules deny every client write) and readable
 * only by a SuperAdmin. Each entry keeps one year: `expire_at` is created_at + 365 days. The daily
 * `purgeExpiredAuditLog` deletes expired entries; the same field can also back a Firestore TTL
 * policy on AuditLog.expire_at if one is enabled.
 *
 * Entries carry uids, roles and small non-personal details only: no emails, names, phones or
 * bank data.
 */
const { onDocumentWrittenWithAuthContext } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

const AUDIT_LOG = "AuditLog";
const RETENTION_MS = 365 * 24 * 60 * 60 * 1000;
const PURGE_BATCH = 400;
const PURGE_MAX_BATCHES = 25;

const deps = { now: () => Date.now() };

function plainDetails(details) {
  const out = {};
  for (const [key, value] of Object.entries(details || {})) {
    if (value === undefined) continue;
    if (value === null || ["string", "number", "boolean"].includes(typeof value)) {
      out[key] = typeof value === "string" ? value.slice(0, 200) : value;
    } else if (typeof value === "object" && !Array.isArray(value)) {
      out[key] = plainDetails(value);
    }
  }
  return out;
}

function auditEntry({ action, actorUid, actorRole, targetUid, targetPath, details }) {
  return {
    action: String(action),
    actor_uid: actorUid || null,
    actor_role: actorRole || null,
    target_uid: targetUid || null,
    target_path: targetPath || null,
    details: plainDetails(details),
    created_at: FieldValue.serverTimestamp(),
    expire_at: Timestamp.fromMillis(deps.now() + RETENTION_MS),
  };
}

/** Writes one audit entry. A failure is logged and never undoes the audited change. */
async function writeAuditLog(entry, db = admin.firestore()) {
  try {
    await db.collection(AUDIT_LOG).add(auditEntry(entry));
  } catch (err) {
    logger.error("AuditLog write failed", { action: entry && entry.action, error: err && err.message });
  }
}

/** Deletes entries whose expire_at has passed. Returns the number deleted. */
async function purgeExpired(db = admin.firestore(), now = deps.now()) {
  let deleted = 0;
  for (let i = 0; i < PURGE_MAX_BATCHES; i++) {
    const snap = await db.collection(AUDIT_LOG).where("expire_at", "<", Timestamp.fromMillis(now)).limit(PURGE_BATCH).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += snap.size;
    if (snap.size < PURGE_BATCH) break;
  }
  return deleted;
}

const purgeExpiredAuditLog = onSchedule(
  { schedule: "30 3 * * *", timeZone: "Africa/Cairo", maxInstances: 1 },
  async () => {
    const deleted = await purgeExpired();
    if (deleted) logger.info("Expired audit log entries deleted", { deleted });
  }
);

// Settings (payment_split) are written by a SuperAdmin from the client, so the trigger records who
// did it from the event's auth context.
const auditSettingsChange = onDocumentWrittenWithAuthContext(
  { document: "Settings/{settingId}", maxInstances: 2 },
  async (event) => {
    const before = event.data && event.data.before && event.data.before.exists ? event.data.before.data() : null;
    const after = event.data && event.data.after && event.data.after.exists ? event.data.after.data() : null;
    const pick = (d) => (d ? { platform_percent: d.platform_percent, agency_percent: d.agency_percent } : null);
    const writer = after && typeof after.updated_by === "string" ? after.updated_by : null;
    await writeAuditLog({
      action: after ? (before ? "settings_updated" : "settings_created") : "settings_deleted",
      actorUid: (event.authType === "app_user" && event.authId) || writer,
      actorRole: event.authType || null,
      targetPath: `Settings/${event.params.settingId}`,
      details: { before: pick(before), after: pick(after) },
    });
  }
);

module.exports = { AUDIT_LOG, RETENTION_MS, writeAuditLog, auditEntry, purgeExpired, purgeExpiredAuditLog, auditSettingsChange, deps };
