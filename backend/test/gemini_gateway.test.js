const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("Run through `npm test` so the Firestore emulator is attached.");
}

const TEST_KEY = "test-only-not-a-real-key";
process.env.GEMINI_API_KEY = TEST_KEY;

const fns = require("../index");
const logger = require("firebase-functions/logger");
const { _internal: gw } = require("../gemini_gateway");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const realNow = gw.deps.now;
const realFetch = gw.deps.fetch;

let calls;
let reply;

function geminiReply(status, payload) {
  return async (url, init) => {
    calls.push({ url, init, body: JSON.parse(init.body) });
    return { status, ok: status >= 200 && status < 300, json: async () => payload };
  };
}

const OK_PAYLOAD = {
  candidates: [{ content: { parts: [{ text: "{\"ok\":true}" }] } }],
  usageMetadata: { totalTokenCount: 12 },
  modelVersion: "gemini-2.5-flash",
};

function textRequest(text = "Estimate the rent for a 2 bedroom flat.") {
  return { contents: [{ parts: [{ text }] }] };
}

function call({ feature = "valuation", model, request = textRequest(), uid = null, ip = "203.0.113.7" } = {}) {
  return fns.geminiGenerate.run({
    data: { feature, model, request },
    auth: uid ? { uid, token: { uid } } : undefined,
    rawRequest: { headers: { "x-forwarded-for": `198.51.100.99, ${ip}` }, ip: "198.51.100.99" },
  });
}

async function expectCode(promise, code) {
  await assert.rejects(promise, (err) => {
    assert.equal(err.code, code, `expected ${code}, got ${err.code}: ${err.message}`);
    return true;
  });
}

test.beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: "DELETE" });
  calls = [];
  reply = geminiReply(200, OK_PAYLOAD);
  gw.deps.fetch = (...args) => reply(...args);
  gw.deps.now = realNow;
  process.env.GEMINI_API_KEY = TEST_KEY;
});

test.after(() => {
  gw.deps.fetch = realFetch;
  gw.deps.now = realNow;
});

// --- Deployment shape ---

test("TAQ-19: geminiGenerate is a callable bound to the GEMINI_API_KEY secret with 5 max instances", () => {
  const endpoint = fns.geminiGenerate.__endpoint;
  assert.ok(endpoint.callableTrigger, "must be a callable, not a public HTTP endpoint");
  assert.equal(endpoint.httpsTrigger, undefined);
  assert.equal(endpoint.maxInstances, 5);
  assert.equal(endpoint.timeoutSeconds, 60);
  assert.deepEqual(endpoint.secretEnvironmentVariables.map((s) => s.key), ["GEMINI_API_KEY"]);
});

// --- Auth ---

test("TAQ-19: signed-out callers cannot use sign-in-only features", async () => {
  for (const feature of ["onboarding", "document_ocr"]) {
    await expectCode(call({ feature }), "unauthenticated");
  }
  assert.equal(calls.length, 0);
});

test("TAQ-19: every visitor feature works signed out; sign-in-only features work signed in", async () => {
  const visitorFeatures = Object.keys(gw.FEATURES).filter((name) => gw.FEATURES[name].visitor);
  assert.deepEqual(visitorFeatures.sort(), [
    "geocoding", "image_moderation", "legal_advisor", "market_index", "semantic_search", "valuation", "voice_broker",
  ]);
  for (const feature of visitorFeatures) {
    const result = await call({ feature, ip: `192.0.2.${visitorFeatures.indexOf(feature) + 1}` });
    assert.equal(result.candidates[0].content.parts[0].text, "{\"ok\":true}");
  }
  for (const feature of ["onboarding", "document_ocr"]) {
    await call({ feature, uid: "owner-1" });
  }
  assert.equal(calls.length, visitorFeatures.length + 2);
});

test("TAQ-19: an unknown feature is rejected", async () => {
  await expectCode(call({ feature: "anything", uid: "owner-1" }), "invalid-argument");
  await expectCode(fns.geminiGenerate.run({ data: null, auth: { uid: "u", token: {} } }), "invalid-argument");
});

// --- Secret ---

test("TAQ-19: the key is sent in a header, never in the URL or the response", async () => {
  const result = await call({ uid: "owner-1" });
  assert.equal(calls.length, 1);
  assert.doesNotMatch(calls[0].url, /key=/);
  assert.equal(calls[0].url, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent");
  assert.equal(calls[0].init.headers["x-goog-api-key"], TEST_KEY);
  assert.doesNotMatch(JSON.stringify(result), new RegExp(TEST_KEY));
});

test("TAQ-19: a missing secret fails closed without calling Gemini", async () => {
  delete process.env.GEMINI_API_KEY;
  await expectCode(call({ uid: "owner-1" }), "failed-precondition");
  assert.equal(calls.length, 0);
});

// --- Model allowlist ---

test("TAQ-19: only allowlisted models run; legacy app ids map to the default model", async () => {
  await call({ uid: "u1", model: "gemini-2.5-flash-lite" });
  await call({ uid: "u1", model: "gemini-3.8-pro" });
  await call({ uid: "u1", model: "gemini-1.5-flash" });
  await call({ uid: "u1" });
  assert.deepEqual(
    calls.map((c) => c.url.match(/models\/([^:]+):/)[1]),
    ["gemini-2.5-flash-lite", "gemini-2.5-flash", "gemini-2.5-flash", "gemini-2.5-flash"],
  );
  for (const model of ["gemini-2.5-pro", "gemini-ultra", "../../v1/files", 42]) {
    await expectCode(call({ uid: "u1", model }), "invalid-argument");
  }
  assert.equal(calls.length, 4);
});

// --- Size caps and body shape ---

test("TAQ-19: oversized prompts and files are rejected before Gemini or the quota", async () => {
  await expectCode(call({ uid: "u1", request: textRequest("x".repeat(gw.CAPS.textChars + 1)) }), "invalid-argument");
  const many = { contents: Array.from({ length: gw.CAPS.contents + 1 }, () => ({ parts: [{ text: "hi" }] })) };
  await expectCode(call({ uid: "u1", request: many }), "invalid-argument");
  const bigFile = {
    contents: [{ parts: [{ text: "Read this ID" }, { inline_data: { mime_type: "image/jpeg", data: "A".repeat(gw.CAPS.inlineBase64Chars + 1) } }] }],
  };
  await expectCode(call({ uid: "u1", feature: "document_ocr", request: bigFile }), "invalid-argument");
  assert.equal(calls.length, 0);
  const bucket = await db.collection(gw.RATE_LIMIT_COLLECTION).doc("uid_u1").get();
  assert.equal(bucket.exists, false, "rejected requests must not use quota");
});

test("TAQ-19: files are only accepted by file features and only as images or PDFs", async () => {
  const image = (mime) => ({ contents: [{ parts: [{ text: "check" }, { inlineData: { mimeType: mime, data: "QUJD" } }] }] });
  await expectCode(call({ uid: "u1", feature: "valuation", request: image("image/png") }), "invalid-argument");
  await expectCode(call({ uid: "u1", feature: "image_moderation", request: image("text/html") }), "invalid-argument");
  await call({ uid: "u1", feature: "image_moderation", request: image("image/PNG") });
  assert.deepEqual(calls[0].body.contents[0].parts[1], { inline_data: { mime_type: "image/png", data: "QUJD" } });
});

test("TAQ-19: only known request fields reach Gemini and output tokens are capped", async () => {
  await call({
    uid: "u1",
    feature: "voice_broker",
    request: {
      system_instruction: { parts: [{ text: "You are a broker." }] },
      contents: [{ role: "user", parts: [{ text: "Book a viewing" }] }],
      tools: [{ function_declarations: [{ name: "book_viewing_appointment", parameters: { type: "object" } }] }],
      generationConfig: { temperature: 0.6, maxOutputTokens: 100000, responseMimeType: "application/json", stopSequences: ["x"] },
      safetySettings: [{ category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" }],
      cachedContent: "cachedContents/abc",
    },
  });
  assert.deepEqual(calls[0].body, {
    contents: [{ role: "user", parts: [{ text: "Book a viewing" }] }],
    system_instruction: { parts: [{ text: "You are a broker." }] },
    tools: [{ function_declarations: [{ name: "book_viewing_appointment", parameters: { type: "object" } }] }],
    generationConfig: { temperature: 0.6, maxOutputTokens: gw.CAPS.maxOutputTokens, responseMimeType: "application/json" },
  });
  await call({ uid: "u1", request: { ...textRequest(), tools: [{ google_search: {} }] } });
  assert.deepEqual(calls[1].body.tools, [{ google_search: {} }]);
  await expectCode(call({ uid: "u1", request: { ...textRequest(), tools: [{ code_execution: {} }] } }), "invalid-argument");
  await expectCode(call({ uid: "u1", request: { contents: [{ role: "system", parts: [{ text: "x" }] }] } }), "invalid-argument");
});

// --- Rate limits ---

test("TAQ-19: a signed-in user gets 20 calls a minute, then a fresh window the next minute", async () => {
  const start = Date.UTC(2026, 10, 24, 10, 0, 5);
  gw.deps.now = () => start;
  for (let i = 0; i < gw.LIMITS.user.perMinute; i += 1) await call({ uid: "u1" });
  await expectCode(call({ uid: "u1" }), "resource-exhausted");
  await call({ uid: "u2" });
  gw.deps.now = () => start + 60000;
  await call({ uid: "u1" });
  assert.equal(calls.length, gw.LIMITS.user.perMinute + 2);
  const bucket = (await db.collection(gw.RATE_LIMIT_COLLECTION).doc("uid_u1").get()).data();
  assert.equal(bucket.dayCount, gw.LIMITS.user.perMinute + 1);
  assert.equal(bucket.minuteCount, 1);
});

test("TAQ-19: a signed-in user is stopped at 200 calls a day until the next UTC day", async () => {
  const now = Date.UTC(2026, 10, 24, 12, 0, 0);
  gw.deps.now = () => now;
  await db.collection(gw.RATE_LIMIT_COLLECTION).doc("uid_u1").set({
    minute: 0, minuteCount: 0, day: "2026-11-24", dayCount: gw.LIMITS.user.perDay,
  });
  await expectCode(call({ uid: "u1" }), "resource-exhausted");
  gw.deps.now = () => Date.UTC(2026, 10, 25, 0, 0, 1);
  await call({ uid: "u1" });
  assert.equal(calls.length, 1);
});

test("TAQ-19: visitors are limited per IP, and the stored bucket id is not the raw IP", async () => {
  gw.deps.now = () => Date.UTC(2026, 10, 24, 9, 30, 0);
  for (let i = 0; i < gw.LIMITS.visitor.perMinute; i += 1) await call({ ip: "203.0.113.7" });
  await expectCode(call({ ip: "203.0.113.7" }), "resource-exhausted");
  await call({ ip: "203.0.113.8" });
  const ids = (await db.collection(gw.RATE_LIMIT_COLLECTION).get()).docs.map((d) => d.id);
  assert.ok(ids.includes("visitors_global"));
  for (const id of ids) assert.doesNotMatch(id, /203\.0\.113|198\.51/);
  const global = (await db.collection(gw.RATE_LIMIT_COLLECTION).doc("visitors_global").get()).data();
  assert.equal(global.dayCount, gw.LIMITS.visitor.perMinute + 1);
});

test("TAQ-19: a forged X-Forwarded-For prefix does not give a visitor a new bucket", async () => {
  assert.equal(gw.clientIp({ headers: { "x-forwarded-for": "1.1.1.1, 2.2.2.2, 203.0.113.7" } }), "203.0.113.7");
  assert.equal(gw.clientIp({ headers: {}, ip: "203.0.113.9" }), "203.0.113.9");
  assert.equal(gw.visitorBucket("203.0.113.7", "k"), gw.visitorBucket("203.0.113.7", "k"));
  assert.notEqual(gw.visitorBucket("203.0.113.7", "k"), gw.visitorBucket("203.0.113.8", "k"));
});

test("TAQ-19: the shared visitor ceiling stops signed-out calls but not signed-in ones", async () => {
  gw.deps.now = () => Date.UTC(2026, 10, 24, 9, 0, 0);
  await db.collection(gw.RATE_LIMIT_COLLECTION).doc("visitors_global").set({
    day: "2026-11-24", dayCount: gw.LIMITS.visitorsPerDay,
  });
  await expectCode(call({ ip: "192.0.2.50" }), "resource-exhausted");
  await call({ uid: "u1" });
  assert.equal(calls.length, 1);
});

// --- Upstream errors and logging ---

test("TAQ-19: upstream failures map to callable errors without leaking Gemini's body", async () => {
  reply = geminiReply(429, { error: { message: "quota for key test-only-not-a-real-key" } });
  await expectCode(call({ uid: "u1" }), "resource-exhausted");
  reply = geminiReply(500, { error: { message: "boom" } });
  await expectCode(call({ uid: "u1" }), "unavailable");
  reply = geminiReply(403, { error: { message: "API key invalid" } });
  await expectCode(call({ uid: "u1" }), "failed-precondition");
  reply = async () => {
    const err = new Error("aborted");
    err.name = "AbortError";
    throw err;
  };
  await expectCode(call({ uid: "u1" }), "deadline-exceeded");
});

test("TAQ-19: logs carry sizes and outcome, never the prompt or the key", async () => {
  const lines = [];
  const original = { info: logger.info, warn: logger.warn, error: logger.error };
  for (const level of Object.keys(original)) logger[level] = (...args) => lines.push(JSON.stringify(args));
  try {
    const secretPrompt = "Tenant Fatima Ali, passport A1234567, phone +971501234567";
    await call({ uid: "u1", request: textRequest(secretPrompt) });
    reply = geminiReply(500, { error: { message: secretPrompt } });
    await expectCode(call({ uid: "u1", request: textRequest(secretPrompt) }), "unavailable");
  } finally {
    Object.assign(logger, original);
  }
  const logged = lines.join("\n");
  assert.match(logged, /geminiGenerate/);
  assert.match(logged, /"textChars":\d+/);
  for (const needle of ["Fatima", "A1234567", "971501234567", TEST_KEY]) {
    assert.ok(!logged.includes(needle), `log leaked ${needle}`);
  }
});
