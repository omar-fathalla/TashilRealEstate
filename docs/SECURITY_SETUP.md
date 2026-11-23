# Security setup

## App Check

The callables `sendRentalReminder`, `generateRentalInvoiceReceipt`, and `setUserRole` can
require a valid Firebase App Check token. Enforcement is **off by default** because the web
build has no registered reCAPTCHA key yet; turning it on before a key ships would block every
web user. Sign-in and role checks apply whether or not App Check is enforced.

### What is needed to turn it on

1. **A reCAPTCHA v3 site key** for the production web domains (for example `tashilaqar.com`
   and the Firebase Hosting domains). Create it in the reCAPTCHA admin console, then register
   the web app in Firebase console > App Check with the reCAPTCHA v3 provider and that key's
   **secret**. The secret stays in the Firebase console and never goes into this repo. The
   site key is public, but it is still passed at build time rather than committed.
2. **Android and Apple**: enable Play Integrity and DeviceCheck/App Attest for the mobile
   apps in App Check, if the mobile apps call these functions.
3. **Build the web app with the site key**:

   ```bash
   flutter build web --release --dart-define=RECAPTCHA_SITE_KEY=<site key>
   ```

   Without the define, release web builds skip App Check instead of sending tokens made
   with an invalid key. Debug builds use the App Check debug provider.
4. **Check the metrics** in Firebase console > App Check > APIs: most callable requests
   should be "verified" before enforcing.
5. **Enable enforcement for the callables** by setting `ENFORCE_APP_CHECK=true` for the
   production deploy, for example in `backend/.env.<production project id>`:

   ```bash
   ENFORCE_APP_CHECK=true
   ```

   Then redeploy the functions. Any other value, or no value, keeps enforcement off.

Firestore and Storage App Check enforcement are separate switches in the Firebase console
and are not affected by `ENFORCE_APP_CHECK`.
