/**
 * TAQ-171: the receiver for the Report-Only CSP's `report-uri /csp-report` (a Hosting rewrite).
 * It writes one trimmed log line per violation and stores nothing. It writes no Firestore
 * data and grants nothing, so it is safe as a public endpoint. Query strings and fragments
 * are dropped, because URLs can carry tokens or emails, and every field is capped in length.
 */
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const MAX_BODY_BYTES = 8 * 1024;
const MAX_FIELD = 200;
const MAX_REPORTS = 5;
const KEYWORDS = new Set(["inline", "eval", "wasm-eval", "data", "blob", "self", "trusted-types-policy", "trusted-types-sink"]);

function trim(value) {
  return typeof value === "string" ? value.slice(0, MAX_FIELD) : undefined;
}

/** An origin and path only: no query, fragment or credentials. Keywords like `inline` pass as-is. */
function safeUrl(value, { pathOnly = false } = {}) {
  if (typeof value !== "string" || !value) return undefined;
  if (KEYWORDS.has(value)) return value;
  try {
    const url = new URL(value);
    if (url.protocol === "data:" || url.protocol === "blob:") return url.protocol.slice(0, -1);
    return trim(pathOnly ? url.pathname : `${url.origin}${url.pathname}`);
  } catch (_) {
    return undefined;
  }
}

/** The trimmed fields of one violation, from the report-uri (`csp-report`) or Reporting API shape. */
function summarize(report) {
  if (!report || typeof report !== "object") return null;
  const r = report["csp-report"] || (report.type === "csp-violation" ? report.body : null) || null;
  if (!r || typeof r !== "object") return null;
  const pick = (dashed, camel) => (r[dashed] !== undefined ? r[dashed] : r[camel]);
  return {
    directive: trim(pick("effective-directive", "effectiveDirective") || pick("violated-directive", "violatedDirective")),
    blocked: safeUrl(pick("blocked-uri", "blockedURL")),
    page: safeUrl(pick("document-uri", "documentURL"), { pathOnly: true }),
    source: safeUrl(pick("source-file", "sourceFile")),
    line: Number.isInteger(pick("line-number", "lineNumber")) ? pick("line-number", "lineNumber") : undefined,
    disposition: trim(r.disposition),
  };
}

function parseBody(req) {
  const raw = Buffer.isBuffer(req.rawBody) ? req.rawBody : null;
  if (raw) {
    if (raw.length > MAX_BODY_BYTES) return { tooLarge: true };
    try {
      return { body: JSON.parse(raw.toString("utf8")) };
    } catch (_) {
      return { body: null };
    }
  }
  return { body: req.body && typeof req.body === "object" ? req.body : null };
}

/** The handler, separate from onRequest so tests can drive it with plain objects. */
function handleCspReport(req, res) {
  if (req.method !== "POST") {
    res.status(405).end();
    return;
  }
  const declared = Number(req.headers && req.headers["content-length"]);
  if (Number.isFinite(declared) && declared > MAX_BODY_BYTES) {
    res.status(413).end();
    return;
  }
  const { body, tooLarge } = parseBody(req);
  if (tooLarge) {
    res.status(413).end();
    return;
  }
  const reports = (Array.isArray(body) ? body : [body]).slice(0, MAX_REPORTS).map(summarize).filter(Boolean);
  for (const violation of reports) logger.warn("csp_violation", violation);
  res.status(204).end();
}

const cspReport = onRequest({ maxInstances: 2, concurrency: 80, memory: "256MiB", cors: false }, handleCspReport);

module.exports = { cspReport, handleCspReport, summarize, safeUrl, MAX_BODY_BYTES };
