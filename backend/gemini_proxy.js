const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { requireAuth } = require("./authz");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const MODEL_ALIASES = {
  "gemini-1.5-flash": "gemini-2.5-flash",
  "gemini-2.0-flash": "gemini-2.5-flash",
  "gemini-2.0-flash-vision": "gemini-2.5-flash",
  "gemini-2.5-embed": "gemini-2.5-flash",
  "gemini-3.6-flash": "gemini-2.5-flash",
  "gemini-3.8-flash": "gemini-2.5-flash",
  "gemini-3.8-pro": "gemini-2.5-flash",
  "gemini-3.8-flagship": "gemini-2.5-flash",
  "gemini-3.8-analyst": "gemini-2.5-flash",
  "gemini-3.8-creative": "gemini-2.5-flash",
};

const SENSITIVE_PURPOSES = new Set(["voice", "image", "ocr"]);
const DAILY_LIMIT = 40;

function canonicalModel(requested) {
  const name = String(requested || "gemini-2.5-flash");
  return MODEL_ALIASES[name] || (name.startsWith("gemini-2.5-") ? name : "gemini-2.5-flash");
}

async function assertQuota(uid) {
  const day = new Date().toISOString().slice(0, 10);
  const ref = admin.firestore().collection("AiQuota").doc(uid);
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : {};
    const count = data.day === day ? Number(data.count || 0) : 0;
    if (count >= DAILY_LIMIT) {
      throw new HttpsError("resource-exhausted", "Daily AI quota reached.");
    }
    tx.set(ref, { day, count: count + 1, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  });
}

const geminiGenerateContent = onCall(
  {
    secrets: [geminiApiKey],
    enforceAppCheck: true,
    maxInstances: 10,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request) => {
    const auth = requireAuth(request);
    const purpose = String(request.data?.purpose || "text");
    if (SENSITIVE_PURPOSES.has(purpose) && request.data?.processingConsent !== true) {
      throw new HttpsError("failed-precondition", "AI processing consent is required.");
    }
    const body = request.data?.body;
    if (!body || typeof body !== "object" || !Array.isArray(body.contents)) {
      throw new HttpsError("invalid-argument", "A Gemini request body is required.");
    }
    const model = canonicalModel(request.data?.model);
    await assertQuota(auth.uid);

    const key = geminiApiKey.value();
    if (!key) {
      throw new HttpsError("failed-precondition", "AI is not configured.");
    }
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(key)}`;
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      logger.error("Gemini request failed", { status: response.status, model });
      throw new HttpsError("internal", "The AI request failed.");
    }
    return payload;
  },
);

module.exports = { geminiGenerateContent, canonicalModel };
