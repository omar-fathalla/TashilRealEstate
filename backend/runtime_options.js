const { setGlobalOptions } = require("firebase-functions/v2");

const FUNCTIONS_SERVICE_ACCOUNT_NAME = "tashil-functions";

/**
 * Every function runs as a dedicated least-privilege service account instead of the default
 * compute service account, which holds Editor (TAQ-177). The Firebase CLI sets GCLOUD_PROJECT when
 * it loads this code for a deploy, so the full email is built for the target project. The full
 * email is needed because the CLI grants secret access with the raw value and does not expand the
 * "name@" shorthand there (firebase-tools 15.27), which failed the first dev deploy. The account
 * must exist in a project, with the roles in docs/SECURITY_SETUP.md, before this code is deployed
 * there. The CLI also uses it for the Eventarc triggers and as the Cloud Scheduler OIDC identity.
 */
function functionsServiceAccount(env = process.env) {
  const project = String(env.GCLOUD_PROJECT || "").trim();
  return project
    ? `${FUNCTIONS_SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com`
    : `${FUNCTIONS_SERVICE_ACCOUNT_NAME}@`;
}

const FUNCTIONS_SERVICE_ACCOUNT = functionsServiceAccount();

setGlobalOptions({ serviceAccount: FUNCTIONS_SERVICE_ACCOUNT });

module.exports = { FUNCTIONS_SERVICE_ACCOUNT, functionsServiceAccount };
