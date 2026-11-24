const crypto = require("crypto");
const net = require("net");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

const { appCheckEnforced } = require("./config");
const { requireRole } = require("./authz");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

const GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models";
const RATE_LIMIT_COLLECTION = "AiRateLimits";

const ALLOWED_MODELS = new Set(["gemini-2.5-flash", "gemini-2.5-flash-lite"]);
const DEFAULT_MODEL = "gemini-2.5-flash";

// Model ids the app's AI Engine Hub and older services still send. They all run on the
// default model; anything not listed here or in ALLOWED_MODELS is rejected.
const MODEL_ALIASES = {
  "gemini-1.5-flash": DEFAULT_MODEL,
  "gemini-2.0-flash": DEFAULT_MODEL,
  "gemini-2.0-flash-vision": DEFAULT_MODEL,
  "gemini-2.5-embed": DEFAULT_MODEL,
  "gemini-3.6-flash": DEFAULT_MODEL,
  "gemini-3.8-flash": DEFAULT_MODEL,
  "gemini-3.8-pro": DEFAULT_MODEL,
  "gemini-3.8-flagship": DEFAULT_MODEL,
  "gemini-3.8-analyst": DEFAULT_MODEL,
  "gemini-3.8-creative": DEFAULT_MODEL,
};

// Listing a property and reading lease/ID documents belong to the owner and agency portals,
// and to platform staff who support them. Investor is deliberately not here: investors do not
// list properties or hold leases, and OCR reads national IDs and contracts, so they have no use
// for either feature and no business processing other people's documents. They keep every
// visitor-level AI feature (valuation, search, market index, advisor) under the per-user quota.
const PORTAL_ROLES = ["Owner", "AgencyAdmin", "Admin", "SuperAdmin"];

// `visitor`: reachable from public pages, so signed-out callers may use it under the
// per-IP limit. `inline`: may carry base64 images or PDFs. `roles`: signed-in callers must
// hold one of these roles (custom claim, or the profile document for self-service roles).
const FEATURES = {
  valuation: { visitor: true, inline: false },
  geocoding: { visitor: true, inline: false },
  market_index: { visitor: true, inline: false },
  image_moderation: { visitor: true, inline: true },
  voice_broker: { visitor: true, inline: false },
  semantic_search: { visitor: true, inline: false },
  legal_advisor: { visitor: true, inline: false },
  onboarding: { visitor: false, inline: false, roles: PORTAL_ROLES },
  document_ocr: { visitor: false, inline: true, roles: PORTAL_ROLES },
};

const LIMITS = {
  user: { perMinute: 20, perDay: 200 },
  visitor: { perMinute: 10, perDay: 60 },
  // Shared ceiling for all signed-out traffic, so rotating IPs cannot run up the bill.
  visitorsPerDay: 3000,
};

const CAPS = {
  requestBytes: 6 * 1024 * 1024,
  textChars: 40000,
  inlineBase64Chars: 5 * 1024 * 1024,
  contents: 24,
  partsPerContent: 16,
  functionDeclarations: 8,
  maxOutputTokens: 4096,
};

const INLINE_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
  "application/pdf",
]);
const RESPONSE_MIME_TYPES = new Set(["application/json", "text/plain"]);
const UPSTREAM_TIMEOUT_MS = 45000;

// Swapped in tests so no request leaves the machine and the clock can be moved.
const deps = {
  fetch: (...args) => fetch(...args),
  now: () => Date.now(),
};

function invalid(message) {
  return new HttpsError("invalid-argument", message);
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function resolveModel(requested) {
  if (requested === undefined || requested === null || requested === "") return DEFAULT_MODEL;
  if (typeof requested !== "string") throw invalid("model must be a string.");
  const name = requested.trim();
  if (ALLOWED_MODELS.has(name)) return name;
  if (Object.prototype.hasOwnProperty.call(MODEL_ALIASES, name)) return MODEL_ALIASES[name];
  throw invalid("This model is not allowed.");
}

function sanitizePart(part, feature, totals) {
  if (!isPlainObject(part)) throw invalid("Each part must be an object.");
  if (typeof part.text === "string") {
    totals.textChars += part.text.length;
    return { text: part.text };
  }
  const inline = part.inline_data || part.inlineData;
  if (inline !== undefined) {
    if (!FEATURES[feature].inline) throw invalid("This feature does not accept files.");
    const mimeType = isPlainObject(inline) ? inline.mime_type || inline.mimeType : null;
    const data = isPlainObject(inline) ? inline.data : null;
    if (typeof mimeType !== "string" || !INLINE_MIME_TYPES.has(mimeType.toLowerCase())) {
      throw invalid("This file type is not allowed.");
    }
    if (typeof data !== "string" || data.length === 0) throw invalid("File data is missing.");
    totals.inlineChars += data.length;
    return { inline_data: { mime_type: mimeType.toLowerCase(), data } };
  }
  throw invalid("Only text and file parts are allowed.");
}

function sanitizeParts(parts, feature, totals) {
  if (!Array.isArray(parts) || parts.length === 0) throw invalid("parts must be a non-empty list.");
  if (parts.length > CAPS.partsPerContent) throw invalid("Too many parts.");
  return parts.map((part) => sanitizePart(part, feature, totals));
}

function sanitizeTools(tools, totals) {
  if (tools === undefined) return undefined;
  if (!Array.isArray(tools) || tools.length > 2) throw invalid("tools must be a short list.");
  return tools.map((tool) => {
    if (!isPlainObject(tool)) throw invalid("Each tool must be an object.");
    if (tool.google_search !== undefined || tool.googleSearch !== undefined) {
      return { google_search: {} };
    }
    const declarations = tool.function_declarations || tool.functionDeclarations;
    if (Array.isArray(declarations)) {
      if (declarations.length === 0 || declarations.length > CAPS.functionDeclarations) {
        throw invalid("Too many function declarations.");
      }
      for (const declaration of declarations) {
        if (!isPlainObject(declaration) || typeof declaration.name !== "string") {
          throw invalid("Each function declaration needs a name.");
        }
      }
      totals.textChars += JSON.stringify(declarations).length;
      return { function_declarations: declarations };
    }
    throw invalid("Only Google Search and function tools are allowed.");
  });
}

function sanitizeGenerationConfig(config) {
  if (config === undefined) return undefined;
  if (!isPlainObject(config)) throw invalid("generationConfig must be an object.");
  const out = {};
  const number = (key, min, max) => {
    if (config[key] === undefined) return;
    const value = Number(config[key]);
    if (!Number.isFinite(value) || value < min || value > max) throw invalid(`${key} is out of range.`);
    out[key] = value;
  };
  number("temperature", 0, 2);
  number("topP", 0, 1);
  number("topK", 1, 100);
  if (config.maxOutputTokens !== undefined) {
    const tokens = Math.floor(Number(config.maxOutputTokens));
    if (!Number.isFinite(tokens) || tokens < 1) throw invalid("maxOutputTokens is out of range.");
    out.maxOutputTokens = Math.min(tokens, CAPS.maxOutputTokens);
  }
  if (config.responseMimeType !== undefined) {
    if (!RESPONSE_MIME_TYPES.has(config.responseMimeType)) throw invalid("responseMimeType is not allowed.");
    out.responseMimeType = config.responseMimeType;
  }
  return out;
}

/**
 * Rebuilds the Gemini request from the allowed fields only and enforces the size caps.
 * Returns the body to send upstream plus the counted sizes (for logs; never the text).
 */
function sanitizeRequest(feature, request) {
  if (!isPlainObject(request)) throw invalid("request must be an object.");
  if (JSON.stringify(request).length > CAPS.requestBytes) throw invalid("The request is too large.");

  const totals = { textChars: 0, inlineChars: 0 };
  const { contents } = request;
  if (!Array.isArray(contents) || contents.length === 0) throw invalid("contents must be a non-empty list.");
  if (contents.length > CAPS.contents) throw invalid("Too many conversation turns.");

  const body = {
    contents: contents.map((content) => {
      if (!isPlainObject(content)) throw invalid("Each content entry must be an object.");
      const role = content.role === undefined ? "user" : content.role;
      if (role !== "user" && role !== "model") throw invalid("role must be user or model.");
      return { role, parts: sanitizeParts(content.parts, feature, totals) };
    }),
  };

  const system = request.system_instruction || request.systemInstruction;
  if (system !== undefined) {
    if (!isPlainObject(system)) throw invalid("system_instruction must be an object.");
    const parts = sanitizeParts(system.parts, feature, totals);
    if (parts.some((part) => part.text === undefined)) throw invalid("system_instruction must be text.");
    body.system_instruction = { parts };
  }

  const tools = sanitizeTools(request.tools, totals);
  if (tools) body.tools = tools;
  const generationConfig = sanitizeGenerationConfig(request.generationConfig);
  if (generationConfig) body.generationConfig = generationConfig;

  if (totals.textChars > CAPS.textChars) throw invalid("The prompt is too long.");
  if (totals.inlineChars > CAPS.inlineBase64Chars) throw invalid("The attached file is too large.");
  return { body, totals };
}

/**
 * How many proxies in front of the function append to X-Forwarded-For. A proxy appends the
 * address it received the request from, so the client's IP is this many entries from the
 * right; everything to its left is whatever the client sent and is never trusted.
 *  - 1 (default): the callable is reached on its own cloudfunctions.net / run.app URL, and
 *    Google's front end appends the caller's IP as the last entry.
 *  - 2: an external Application Load Balancer (or another trusted proxy) sits in front and
 *    appends its own entry after the client's.
 * Set VISITOR_IP_TRUSTED_HOPS in the functions environment if the deployment differs, and
 * check it on a non-prod deploy first (docs/SECURITY_SETUP.md, "Visitor rate limits").
 */
function trustedHops(env = process.env) {
  const hops = Number(env.VISITOR_IP_TRUSTED_HOPS || 1);
  return Number.isInteger(hops) && hops >= 1 && hops <= 5 ? hops : 1;
}

function normalizeIp(value) {
  if (typeof value !== "string") return null;
  let ip = value.trim();
  const bracketed = ip.match(/^\[([^\]]+)\](?::\d+)?$/);
  if (bracketed) ip = bracketed[1];
  else if (/^\d{1,3}(?:\.\d{1,3}){3}:\d+$/.test(ip)) ip = ip.replace(/:\d+$/, "");
  if (/^::ffff:/i.test(ip) && net.isIPv4(ip.slice(7))) ip = ip.slice(7);
  return net.isIP(ip) ? ip.toLowerCase() : null;
}

/**
 * The visitor's IP and where it came from. Express's `req.ip` is not used: under
 * `trust proxy` it returns the left-most X-Forwarded-For entry, which the client chose.
 * Without enough trusted entries the TCP peer address is used instead.
 */
function clientAddress(rawRequest, hops = trustedHops()) {
  const headers = (rawRequest && rawRequest.headers) || {};
  const header = headers["x-forwarded-for"];
  const value = Array.isArray(header) ? header.join(",") : header;
  const entries = typeof value === "string" ? value.split(",").map((entry) => entry.trim()).filter(Boolean) : [];
  if (entries.length >= hops) {
    const ip = normalizeIp(entries[entries.length - hops]);
    if (ip) return { ip, source: "x-forwarded-for" };
  }
  const socket = rawRequest && (rawRequest.socket || rawRequest.connection);
  const peer = normalizeIp(socket && socket.remoteAddress);
  if (peer) return { ip: peer, source: "socket" };
  return { ip: "unknown", source: "unknown" };
}

function clientIp(rawRequest, hops) {
  return clientAddress(rawRequest, hops).ip;
}

// Rate-limit documents never store a raw IP: the id is an HMAC keyed with the server secret.
function visitorBucket(ip, secret) {
  return `ip_${crypto.createHmac("sha256", secret || "tashil").update(ip).digest("hex").slice(0, 40)}`;
}

function windowCount(data, windowField, countField, current) {
  return data && data[windowField] === current ? Number(data[countField] || 0) : 0;
}

async function consumeQuota({ uid, ip, secret }) {
  const db = admin.firestore();
  const now = deps.now();
  const minute = Math.floor(now / 60000);
  const day = new Date(now).toISOString().slice(0, 10);
  const limits = uid ? LIMITS.user : LIMITS.visitor;
  const ref = db.collection(RATE_LIMIT_COLLECTION).doc(uid ? `uid_${uid}` : visitorBucket(ip, secret));
  const globalRef = uid ? null : db.collection(RATE_LIMIT_COLLECTION).doc("visitors_global");
  const expiresAt = Timestamp.fromMillis(now + 2 * 24 * 60 * 60 * 1000);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const globalSnap = globalRef ? await tx.get(globalRef) : null;
    const data = snap.exists ? snap.data() : null;
    const minuteCount = windowCount(data, "minute", "minuteCount", minute);
    const dayCount = windowCount(data, "day", "dayCount", day);
    if (minuteCount >= limits.perMinute) {
      throw new HttpsError("resource-exhausted", "Too many AI requests. Try again in a minute.", { retry: "minute" });
    }
    if (dayCount >= limits.perDay) {
      throw new HttpsError("resource-exhausted", "The daily AI limit has been reached.", { retry: "day" });
    }
    if (globalRef) {
      const globalCount = windowCount(globalSnap.exists ? globalSnap.data() : null, "day", "dayCount", day);
      if (globalCount >= LIMITS.visitorsPerDay) {
        throw new HttpsError("resource-exhausted", "AI is busy today. Sign in to keep using it.", { retry: "day" });
      }
      tx.set(globalRef, { day, dayCount: globalCount + 1, updatedAt: FieldValue.serverTimestamp(), expiresAt });
    }
    tx.set(ref, {
      kind: uid ? "user" : "visitor",
      minute,
      minuteCount: minuteCount + 1,
      day,
      dayCount: dayCount + 1,
      updatedAt: FieldValue.serverTimestamp(),
      expiresAt,
    });
  });
}

function upstreamError(status) {
  if (status === 429) return new HttpsError("resource-exhausted", "The AI service is busy. Try again shortly.");
  if (status === 400) return new HttpsError("invalid-argument", "The AI service rejected this request.");
  if (status === 401 || status === 403) return new HttpsError("failed-precondition", "AI is not configured.");
  return new HttpsError("unavailable", "The AI service is unavailable.");
}

async function callGemini({ model, body, key }) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), UPSTREAM_TIMEOUT_MS);
  try {
    const response = await deps.fetch(`${GEMINI_ENDPOINT}/${encodeURIComponent(model)}:generateContent`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    const payload = await response.json().catch(() => null);
    return { status: response.status, ok: response.ok, payload };
  } catch (error) {
    if (error && error.name === "AbortError") {
      throw new HttpsError("deadline-exceeded", "The AI service took too long to answer.");
    }
    throw new HttpsError("unavailable", "The AI service is unavailable.");
  } finally {
    clearTimeout(timer);
  }
}

async function handleGeminiGenerate(request) {
  const data = isPlainObject(request.data) ? request.data : {};
  const feature = typeof data.feature === "string" ? data.feature : "";
  if (!Object.prototype.hasOwnProperty.call(FEATURES, feature)) throw invalid("Unknown AI feature.");

  const uid = request.auth && request.auth.uid ? request.auth.uid : null;
  if (!uid && !FEATURES[feature].visitor) {
    throw new HttpsError("unauthenticated", "Sign in to use this feature.");
  }
  if (FEATURES[feature].roles) await requireRole(request.auth, FEATURES[feature].roles);

  const model = resolveModel(data.model);
  const { body, totals } = sanitizeRequest(feature, data.request);

  const key = GEMINI_API_KEY.value();
  if (!key) throw new HttpsError("failed-precondition", "AI is not configured.");

  const address = uid ? null : clientAddress(request.rawRequest);
  await consumeQuota({ uid, ip: address ? address.ip : null, secret: key });

  const started = deps.now();
  const result = await callGemini({ model, body, key });
  // Sizes and outcome only. Prompts, files and answers can hold personal data and are never logged.
  const logEntry = {
    feature,
    model,
    caller: uid ? "user" : "visitor",
    ipSource: address ? address.source : undefined,
    appCheck: Boolean(request.app),
    textChars: totals.textChars,
    inlineChars: totals.inlineChars,
    status: result.status,
    ms: deps.now() - started,
  };
  if (!result.ok || !isPlainObject(result.payload)) {
    logger.warn("geminiGenerate upstream error", logEntry);
    throw upstreamError(result.ok ? 502 : result.status);
  }
  logger.info("geminiGenerate", logEntry);

  const { candidates, promptFeedback, usageMetadata, modelVersion } = result.payload;
  return { candidates: candidates || [], promptFeedback, usageMetadata, modelVersion };
}

const geminiGenerate = onCall(
  {
    secrets: [GEMINI_API_KEY],
    enforceAppCheck: appCheckEnforced(),
    maxInstances: 5,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  handleGeminiGenerate,
);

module.exports = {
  geminiGenerate,
  _internal: {
    deps,
    FEATURES,
    LIMITS,
    CAPS,
    ALLOWED_MODELS,
    MODEL_ALIASES,
    RATE_LIMIT_COLLECTION,
    resolveModel,
    sanitizeRequest,
    clientIp,
    clientAddress,
    normalizeIp,
    trustedHops,
    visitorBucket,
  },
};
