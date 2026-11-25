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

## Listing photos (`storage.rules`)

Photos live under `public/listings/{ownerUid}/{propertyId}/{fileName}`.

- The owner, a SuperAdmin and an Admin can always read and list them.
- Anyone else can read a photo only while `/Properties/{propertyId}` exists, has
  `is_published == true` and `moderation_hidden != true`, and has `owner_id == ownerUid`.
  Unpublished, rented, moderation-hidden and deleted listings are refused. The rule costs one
  Firestore read (Storage rules allow two per evaluation).
- Owners cannot upload or replace photos while `PropertyModeration/{propertyId}` has
  `hidden: true`. They can still delete them.
- Download URLs with `&token=` are bearer links: Cloud Storage serves them without evaluating
  the rules. A token URL handed out while a listing was live keeps working after it goes
  offline, until the token is revoked (Firebase console, file details, "Revoke").
  Tokenless downloads, `getDownloadURL()` and `getMetadata()` all go through the rules.
- The deployed project needs the Storage service agent to have Firestore read access for
  cross-service rules (the console prompts for it on the first rules deploy).

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

Behind Firebase Hosting: the app calls the callable on its `cloudfunctions.net` URL, not through
a Hosting rewrite, so the default `1` applies and `firebase.json` has no function rewrite. If a
Hosting `rewrites` rule to the function is ever added, Hosting's own proxy sits in front of
Google's front end and the chain can be longer; do not guess. Deploy it to a non-prod project,
send `X-Forwarded-For: 10.9.9.9` with a known source IP, read `ipSource` and the new `ip_…`
document, and set `VISITOR_IP_TRUSTED_HOPS` to the position (from the right) of your own IP
before sending any production traffic through that route.

Local emulator: the Functions emulator has no front end that appends the caller, so every
`X-Forwarded-For` entry would be client-written. When `FUNCTIONS_EMULATOR=true` the header is
ignored and the TCP peer is used (`ipSource: "socket"`), so all local calls share one bucket and
a forged header cannot pick its own. This is covered by `backend/test/gemini_gateway.test.js`.
The emulator therefore cannot show the per-network behaviour in step 5 below; that needs a deploy.

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
(default `gemini-3.5-flash`); set it in `backend/.env` (or a per-project
`backend/.env.<project id>`) and redeploy
`functions:geminiGenerate`. Allowed: `gemini-3.5-flash`, `gemini-3.8-flash`,
`gemini-flash-latest`, `gemini-flash-lite-latest`; any other value falls back to the default.
Retired names the app still sends (all `gemini-2.x`, `gemini-1.5-flash`, `gemini-3.8-pro`, and
similar) run on the configured model. An upstream 404 is logged at error level with the model
name only and returned to the caller as the usual unavailable error. Details and steps are in
`docs/DEV_ENVIRONMENT.md`.

Thinking is also capped on the server. `GEMINI_THINKING_BUDGET` (int param, default `0`) is
added to every request as `generationConfig.thinkingConfig.thinkingBudget`; `-1` sends none; the
client's own `thinkingConfig` is always dropped. `maxOutputTokens` from the client is clamped to
1024-4096, so thinking tokens cannot use up a small limit and cut the answer off. See
`docs/DEV_ENVIRONMENT.md`.

## Committed function params (`backend/.env`)

`backend/.env` is tracked on purpose so non-interactive deploys have a value for every
`defineString`/`defineInt` param. It holds `GEMINI_MODEL` and `GEMINI_THINKING_BUDGET` only.
It must never hold a secret: `GEMINI_API_KEY` stays in Secret Manager. Git ignores the repo-root
`/.env` and `/.secret*` (anchored with a leading slash, because a bare `.env` pattern would also
ignore `backend/.env`), `backend/.secret*.json` and `backend/.env.*` (per-project override files such
as `backend/.env.<project id>` stay local and are never committed; `backend/.env` and `*.example`
templates are not matched), plus `.secret.local`, `.secret.*.local` and `.env*.local` anywhere.
`npm test` in `backend/` fails if `backend/.env` is missing a param, holds an undeclared name or a
credential-looking value, is ignored by git, or is not tracked.
`check:client-keys` scans only `frontend/lib` and `frontend/web`, so it does not read this file.

## Client AI key check

`npm test` (in `backend/`) fails if `frontend/lib` or `frontend/web` holds a Gemini key, a base64
form of one, or a direct Gemini/Vertex URL. Before shipping a web build, scan the compiled output
too; only the public Firebase `apiKey` values from `firebase_options.dart` may appear in it:

```bash
cd frontend && flutter build web --release
cd ../backend && npm run check:client-keys:build
```
