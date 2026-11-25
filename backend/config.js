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

/** Secrets the payment functions read. Bound to the functions only while the gateway is on. */
const PAYMOB_SECRET_NAMES = ["PAYMOB_SECRET_KEY", "PAYMOB_PUBLIC_KEY", "PAYMOB_HMAC_SECRET", "PAYMOB_INTEGRATION_ID"];

/**
 * PAYMENTS_ENABLED=true turns the Paymob gateway on. It stays off (the default) until the keys
 * exist; while it is off, createRentPaymentIntent refuses and paymobWebhook answers 503, and
 * deploys do not bind the Paymob secrets, so a missing secret cannot block a deploy.
 */
function paymentsEnabled(env = process.env) {
  return String(env.PAYMENTS_ENABLED || "").trim().toLowerCase() === "true";
}

/** The secrets to bind to the payment functions: all of them when the gateway is on, else none. */
function paymentSecrets(env = process.env) {
  return paymentsEnabled(env) ? PAYMOB_SECRET_NAMES : [];
}

/**
 * Gateway settings from the environment (secrets arrive as environment variables). Returns the
 * names, never the values, of anything missing.
 *   PAYMOB_BASE_URL      API origin, default https://uae.paymob.com
 *   PAYMOB_CHECKOUT_URL  Unified Checkout origin, default https://uae.checkout.paymob.com
 *   PAYMOB_CURRENCY      currency of the integration, default AED
 *   PAYMOB_NOTIFICATION_URL  public HTTPS URL of paymobWebhook (required)
 *   PAYMOB_REDIRECT_URL  where the customer lands after paying (optional)
 */
function paymobConfig(env = process.env) {
  const trim = (value) => String(value || "").trim();
  const base = (value, fallback) => trim(value || fallback).replace(/\/+$/, "");
  const config = {
    enabled: paymentsEnabled(env),
    secretKey: trim(env.PAYMOB_SECRET_KEY),
    publicKey: trim(env.PAYMOB_PUBLIC_KEY),
    hmacSecret: trim(env.PAYMOB_HMAC_SECRET),
    integrationId: trim(env.PAYMOB_INTEGRATION_ID),
    baseUrl: base(env.PAYMOB_BASE_URL, "https://uae.paymob.com"),
    checkoutUrl: base(env.PAYMOB_CHECKOUT_URL, "https://uae.checkout.paymob.com"),
    currency: trim(env.PAYMOB_CURRENCY || "AED").toUpperCase(),
    notificationUrl: trim(env.PAYMOB_NOTIFICATION_URL),
    redirectUrl: trim(env.PAYMOB_REDIRECT_URL),
  };
  const missing = [];
  if (!config.secretKey) missing.push("PAYMOB_SECRET_KEY");
  if (!config.publicKey) missing.push("PAYMOB_PUBLIC_KEY");
  if (!config.hmacSecret) missing.push("PAYMOB_HMAC_SECRET");
  if (!config.integrationId) missing.push("PAYMOB_INTEGRATION_ID");
  if (!/^https:\/\//.test(config.notificationUrl)) missing.push("PAYMOB_NOTIFICATION_URL");
  config.missing = missing;
  config.ready = config.enabled && missing.length === 0;
  return config;
}

module.exports = { appCheckEnforced, paymentsEnabled, paymentSecrets, paymobConfig, PAYMOB_SECRET_NAMES };
