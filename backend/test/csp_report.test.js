// TAQ-171: the Report-Only CSP reports to /csp-report, which logs a trimmed line and stores nothing.
const test = require("node:test");
const assert = require("node:assert");
const fs = require("fs");
const path = require("path");
const logger = require("firebase-functions/logger");
const { handleCspReport, summarize, safeUrl, MAX_BODY_BYTES } = require("../csp_report");

function call({ method = "POST", body, raw, headers = {} }) {
  const rawBody = raw !== undefined ? Buffer.from(raw) : body !== undefined ? Buffer.from(JSON.stringify(body)) : undefined;
  const res = { code: null, status(c) { this.code = c; return this; }, end() { this.ended = true; return this; } };
  handleCspReport({ method, headers, rawBody, body: undefined }, res);
  return res;
}

function captureWarn(fn) {
  const lines = [];
  const original = logger.warn;
  logger.warn = (msg, data) => lines.push({ msg, data });
  try {
    return { result: fn(), lines };
  } finally {
    logger.warn = original;
  }
}

const REPORT = {
  "csp-report": {
    "document-uri": "https://tashilaqar.ae/listing/abc?token=secret#x",
    "violated-directive": "script-src-elem",
    "effective-directive": "script-src-elem",
    "blocked-uri": "https://evil.example/x.js?email=a@b.c",
    "source-file": "https://tashilaqar.ae/main.dart.js?v=1",
    "line-number": 12,
    disposition: "report",
    "original-policy": "default-src 'self'; ...",
  },
};

test("TAQ-171: a report is logged without query strings, fragments or the policy, and answered 204", () => {
  const { result, lines } = captureWarn(() => call({ body: REPORT }));
  assert.equal(result.code, 204);
  assert.equal(lines.length, 1);
  assert.equal(lines[0].msg, "csp_violation");
  assert.deepEqual(lines[0].data, {
    directive: "script-src-elem",
    blocked: "https://evil.example/x.js",
    page: "/listing/abc",
    source: "https://tashilaqar.ae/main.dart.js",
    line: 12,
    disposition: "report",
  });
  assert.ok(!JSON.stringify(lines[0].data).includes("secret"));
  assert.ok(!JSON.stringify(lines[0].data).includes("@"));
});

test("TAQ-171: the Reporting API shape and CSP keywords are understood", () => {
  const s = summarize({ type: "csp-violation", body: { effectiveDirective: "script-src", blockedURL: "inline", documentURL: "https://x.test/a?b" } });
  assert.deepEqual([s.directive, s.blocked, s.page], ["script-src", "inline", "/a"]);
  assert.equal(safeUrl("data:image/png;base64,AAAA"), "data");
  assert.equal(safeUrl("not a url"), undefined);
  assert.equal(summarize({ unrelated: true }), null);
});

test("TAQ-171: only small POSTs are read, at most 5 reports each, and junk is ignored", () => {
  assert.equal(call({ method: "GET" }).code, 405);
  assert.equal(call({ raw: "x".repeat(MAX_BODY_BYTES + 1) }).code, 413);
  assert.equal(call({ raw: "{}", headers: { "content-length": String(MAX_BODY_BYTES + 1) } }).code, 413);
  const junk = captureWarn(() => call({ raw: "not json" }));
  assert.equal(junk.result.code, 204);
  assert.equal(junk.lines.length, 0);
  const many = captureWarn(() => call({ body: Array.from({ length: 9 }, () => ({ type: "csp-violation", body: { effectiveDirective: "img-src" } })) }));
  assert.equal(many.lines.length, 5);
  const long = captureWarn(() => call({ body: { "csp-report": { "effective-directive": "a".repeat(5000) } } }));
  assert.equal(long.lines[0].data.directive.length, 200);
});

test("TAQ-171: the CSP stays report-only and its report-uri is rewritten to cspReport before the SPA rewrite", () => {
  const { hosting } = JSON.parse(fs.readFileSync(path.join(__dirname, "../../firebase.json"), "utf8"));
  const headers = Object.fromEntries(hosting.headers.find((h) => h.source === "**").headers.map(({ key, value }) => [key, value]));
  assert.equal(headers["Content-Security-Policy"], undefined);
  assert.match(headers["Content-Security-Policy-Report-Only"], /(^|; )report-uri \/csp-report$/);
  const at = hosting.rewrites.findIndex((r) => r.source === "/csp-report");
  assert.ok(at >= 0 && at < hosting.rewrites.findIndex((r) => r.source === "**"));
  assert.deepEqual(hosting.rewrites[at].function, { functionId: "cspReport", region: "us-central1" });
});
