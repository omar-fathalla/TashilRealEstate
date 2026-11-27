#!/usr/bin/env node
/**
 * Prints the reCAPTCHA Enterprise site key that App Check uses for a project's web app, for
 * `--dart-define=RECAPTCHA_SITE_KEY=` (TAQ-170). It reads that one value from the App Check
 * config and fails on anything else. An earlier ad-hoc lookup took a random string from
 * console output, which put a wrong key into dev builds.
 *
 *   ACCESS_TOKEN=<OAuth access token, supplied by the caller> \
 *     node scripts/app_check_site_key.js --project tashil-aqar-dev
 *
 * The script runs no gcloud or firebase commands and never signs in. The web app id comes
 * from the matching generated options file, so it can't drift from what the build ships.
 * The output is the key alone, so `$(...)` gets exactly one value or the build stops.
 */
const fs = require("fs");
const path = require("path");

const OPTIONS_FILES = {
  "tashil-aqar-dev": "frontend/lib/firebase_options_dev.dart",
  "tashil-proptech-os": "frontend/lib/firebase_options.dart",
};
const SITE_KEY = /^[A-Za-z0-9_-]{40}$/;
const ROOT = path.join(__dirname, "../..");

class LookupError extends Error {}

function parseArgs(argv) {
  const at = argv.indexOf("--project");
  const project = at >= 0 ? argv[at + 1] : undefined;
  if (!project || project.startsWith("--")) throw new LookupError("pass --project <project id>");
  if (!OPTIONS_FILES[project]) {
    throw new LookupError(`unknown project ${project}; expected one of ${Object.keys(OPTIONS_FILES).join(", ")}`);
  }
  return { project };
}

/** The web appId in a generated options file, checked against the project it names. */
function webAppId(source, project) {
  const start = source.search(/\bFirebaseOptions\s+web\b/);
  if (start < 0) throw new LookupError("no web FirebaseOptions in the options file");
  const block = source.slice(start, source.indexOf(");", start));
  const appId = (block.match(/appId:\s*'([^']+)'/) || [])[1];
  const projectId = (block.match(/projectId:\s*'([^']+)'/) || [])[1];
  if (!appId || !/^1:\d+:web:[0-9a-f]+$/.test(appId)) throw new LookupError("no web appId in the options file");
  if (projectId !== project) throw new LookupError(`the web options are for ${projectId}, not ${project}`);
  return appId;
}

async function lookupSiteKey({ project, token, fetchImpl = fetch, readFile = (f) => fs.readFileSync(path.join(ROOT, f), "utf8") }) {
  if (!token) throw new LookupError("set ACCESS_TOKEN to an OAuth access token for the project");
  const appId = webAppId(readFile(OPTIONS_FILES[project]), project);
  const url = `https://firebaseappcheck.googleapis.com/v1/projects/${project}/apps/${appId}/recaptchaEnterpriseConfig`;
  const res = await fetchImpl(url, { headers: { Authorization: `Bearer ${token}`, "x-goog-user-project": project } });
  if (!res.ok) throw new LookupError(`App Check config lookup failed with HTTP ${res.status}`);
  const body = await res.json();
  const siteKey = body && body.siteKey;
  if (typeof siteKey !== "string" || !siteKey) {
    throw new LookupError(`no reCAPTCHA Enterprise site key is registered in App Check for ${appId}`);
  }
  if (!SITE_KEY.test(siteKey)) throw new LookupError("the App Check site key does not look like a reCAPTCHA Enterprise key");
  return siteKey;
}

async function main() {
  try {
    const { project } = parseArgs(process.argv.slice(2));
    process.stdout.write(`${await lookupSiteKey({ project, token: process.env.ACCESS_TOKEN })}\n`);
  } catch (e) {
    process.stderr.write(`app_check_site_key: ${e instanceof LookupError ? e.message : "lookup failed"}\n`);
    process.exitCode = 1;
  }
}

if (require.main === module) main();

module.exports = { parseArgs, webAppId, lookupSiteKey, LookupError, OPTIONS_FILES };
