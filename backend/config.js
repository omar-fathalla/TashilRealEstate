/**
 * Deploy-time switches, read from the environment (functions .env files or the shell).
 *
 * ENFORCE_APP_CHECK=true makes the callables reject requests without a valid App Check token.
 * It stays off until the web build ships a real reCAPTCHA site key registered in App Check;
 * see docs/SECURITY_SETUP.md. Auth and role checks apply either way.
 */
function appCheckEnforced(env = process.env) {
  return String(env.ENFORCE_APP_CHECK || "").trim().toLowerCase() === "true";
}

module.exports = { appCheckEnforced };
