/**
 * Lease offer notifications (TAQ-110). A lease moving to `pending_tenant_approval` tells the
 * tenant there is an offer to approve. The tenant's decision (`active` or `rejected`) tells the
 * owner. The trigger covers every path that changes the status, so the rules stay the only gate.
 */
const admin = require("firebase-admin");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { Timestamp } = require("firebase-admin/firestore");

function field(snapshot, key) {
  if (!snapshot || !snapshot.exists) return undefined;
  const data = snapshot.data() || {};
  return data[key];
}

function titleOf(lease) {
  return String(lease.property_title || lease.propertyTitle || "").slice(0, 200);
}

function offerNotification(leaseId, lease) {
  const title = titleOf(lease);
  const suffix = title ? `: ${title}` : "";
  return {
    id: `lease_${leaseId}_offer`,
    recipientId: lease.tenant_id,
    type: "lease_offer",
    title: { ar: "عرض عقد إيجار بانتظار موافقتك", en: "A lease offer is waiting for you", hi: "आपके अनुमोदन के लिए पट्टा प्रस्ताव प्रतीक्षा में है" },
    body: {
      ar: `وصلك عرض عقد إيجار${suffix}. راجع التفاصيل ووافق عليه أو ارفضه من حسابك.`,
      en: `You received a lease offer${suffix}. Review it and approve or reject it in your account.`,
      hi: `आपको पट्टा प्रस्ताव मिला है${suffix}। अपने खाते में इसे देखें और स्वीकृत या अस्वीकृत करें।`,
    },
    leaseId,
    status: "delivered",
    read: false,
    createdAt: Timestamp.now(),
  };
}

function decisionNotification(leaseId, lease, decision) {
  const approved = decision === "active";
  const title = titleOf(lease);
  const suffix = title ? `: ${title}` : "";
  return {
    id: `lease_${leaseId}_${approved ? "approved" : "rejected"}`,
    recipientId: lease.owner_id,
    type: approved ? "lease_approved" : "lease_rejected",
    title: approved
      ? { ar: "وافق المستأجر على العقد", en: "The tenant approved the lease", hi: "किरायेदार ने पट्टा स्वीकार किया" }
      : { ar: "رفض المستأجر العقد", en: "The tenant rejected the lease", hi: "किरायेदार ने पट्टा अस्वीकार किया" },
    body: approved
      ? {
        ar: `أصبح عقد الإيجار ساريًا${suffix}.`,
        en: `The lease is now active${suffix}.`,
        hi: `पट्टा अब सक्रिय है${suffix}।`,
      }
      : {
        ar: `لم يوافق المستأجر على عقد الإيجار${suffix}.`,
        en: `The tenant did not accept the lease${suffix}.`,
        hi: `किरायेदार ने पट्टा स्वीकार नहीं किया${suffix}।`,
      },
    leaseId,
    status: "delivered",
    read: false,
    createdAt: Timestamp.now(),
  };
}

async function handleLeaseWrite(event) {
  const before = event.data && event.data.before;
  const after = event.data && event.data.after;
  if (!after || !after.exists) return null;
  const lease = after.data() || {};
  const from = field(before, "status");
  const to = lease.status;
  if (from === to) return null;

  const db = admin.firestore();
  const leaseId = event.params.leaseId;
  let uid = "";
  let note = null;
  if (to === "pending_tenant_approval" && lease.tenant_id) {
    uid = lease.tenant_id;
    note = offerNotification(leaseId, lease);
  } else if (from === "pending_tenant_approval" && (to === "active" || to === "rejected") && lease.owner_id) {
    uid = lease.owner_id;
    note = decisionNotification(leaseId, lease, to);
  }
  if (!note || !uid) return null;
  await db.collection("Users").doc(uid).collection("notifications").doc(note.id).set(note);
  return note.id;
}

const notifyLeaseStatusChange = onDocumentWritten("Leases/{leaseId}", handleLeaseWrite);

module.exports = { notifyLeaseStatusChange, handleLeaseWrite };
