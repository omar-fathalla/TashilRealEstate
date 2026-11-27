const { setGlobalOptions } = require("firebase-functions/v2");

/**
 * Every function runs as a dedicated least-privilege service account instead of the default
 * compute service account, which holds Editor (TAQ-177). A value that ends in "@" is shorthand
 * the Firebase CLI expands to <name>@<project>.iam.gserviceaccount.com, so the same code works on
 * dev and prod. The account must exist in a project, with the roles in docs/SECURITY_SETUP.md,
 * before this code is deployed there. The CLI also uses it for the Eventarc triggers and as the
 * Cloud Scheduler OIDC identity.
 */
const FUNCTIONS_SERVICE_ACCOUNT = "tashil-functions@";

setGlobalOptions({ serviceAccount: FUNCTIONS_SERVICE_ACCOUNT });

module.exports = { FUNCTIONS_SERVICE_ACCOUNT };
