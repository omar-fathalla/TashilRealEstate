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

## Visitor rate limits (`geminiGenerate`)

Signed-out visitors may use the public AI features under a per-IP limit (10 calls a minute,
60 a day) and a shared ceiling of 3000 visitor calls a day. Counters live in the server-only
`AiRateLimits` collection; a visitor's bucket id is an HMAC of the IP, never the IP itself.

### Which IP is used

A client can put anything in `X-Forwarded-For`; each proxy only **appends** the address it
received the request from. The function therefore takes the entry `VISITOR_IP_TRUSTED_HOPS`
places from the right (default `1`) and ignores everything to its left. Express's `req.ip` is
not used, because under `trust proxy` it is the left-most, client-chosen entry. With too few
entries, or a malformed one, the TCP peer address is used.

- `1` assumes the callable is reached on its own `cloudfunctions.net` / `run.app` URL and that
  Google's front end appends the caller's IP as the last entry.
- Set `VISITOR_IP_TRUSTED_HOPS=2` (for example in `backend/.env.<project id>`) if an external
  Application Load Balancer or another trusted proxy appends one more entry after the client's.

### Verify on a non-prod deploy before production

Use a Firebase project you own that is **not** `tashil-proptech-os`.

1. Give it a placeholder key; quota is counted before Gemini is called, so a dummy value is
   enough (Gemini then answers "AI is not configured"):

   ```bash
   firebase functions:secrets:set GEMINI_API_KEY --project <staging project>
   firebase deploy --only functions:geminiGenerate --project <staging project>
   ```

2. Signed out, call it 11 times with a forged header that changes every time:

   ```bash
   URL=https://us-central1-<staging project>.cloudfunctions.net/geminiGenerate
   for i in $(seq 1 11); do
     curl -s -X POST "$URL" -H 'Content-Type: application/json' -H "X-Forwarded-For: 10.0.0.$i" \
       -d '{"data":{"feature":"valuation","request":{"contents":[{"parts":[{"text":"ping"}]}]}}}'
     echo
   done
   ```

   Calls 1-10 return `FAILED_PRECONDITION` (or an answer with a real key); call 11 must return
   `RESOURCE_EXHAUSTED`. If it does not, the forged header is being trusted: fix the hop count.
3. In Firestore, `AiRateLimits` must hold exactly one new `ip_…` document (minute count 10).
4. `firebase functions:log --only geminiGenerate --project <staging project>` must show
   `ipSource: "x-forwarded-for"`. If every call says `socket`, the platform is not adding the
   header the way this assumes; stop and investigate.
5. From a second network (for example a phone hotspot) one call must succeed and create a
   second `ip_…` document. If it is rejected instead, every visitor shares one bucket (the hop
   count is too high, or a proxy IP is being counted).

## Gemini model (`geminiGenerate`)

The model is chosen on the server, never by the client. `GEMINI_MODEL` is a string param
(default `gemini-3.5-flash`); set it in `backend/.env.<project id>` and redeploy
`functions:geminiGenerate`. Allowed: `gemini-3.5-flash`, `gemini-3.8-flash`,
`gemini-flash-latest`, `gemini-flash-lite-latest`; any other value falls back to the default.
Retired names the app still sends (all `gemini-2.x`, `gemini-1.5-flash`, `gemini-3.8-pro`, and
similar) run on the configured model. An upstream 404 is logged at error level with the model
name only and returned to the caller as the usual unavailable error. Details and steps are in
`docs/DEV_ENVIRONMENT.md`.

## Client AI key check

`npm test` (in `backend/`) fails if `frontend/lib` or `frontend/web` holds a Gemini key, a base64
form of one, or a direct Gemini/Vertex URL. Before shipping a web build, scan the compiled output
too; only the public Firebase `apiKey` values from `firebase_options.dart` may appear in it:

```bash
cd frontend && flutter build web --release
cd ../backend && npm run check:client-keys:build
```
