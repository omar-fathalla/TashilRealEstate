# Security setup

## App Check

The callables `sendRentalReminder`, `generateRentalInvoiceReceipt`, and `setUserRole` can
require a valid Firebase App Check token. Enforcement is **off by default** because the web
build ships without a reCAPTCHA site key yet; turning it on before a key ships would block every
web user. Sign-in and role checks apply whether or not App Check is enforced.

### What is needed to turn it on

1. **Web: a reCAPTCHA Enterprise site key** for the production web domains (for example
   `tashilaqar.com` and the Firebase Hosting domains). Register the web app in Firebase console
   > App Check with the **reCAPTCHA Enterprise** provider and that key. The app uses
   `ReCaptchaEnterpriseProvider`; a reCAPTCHA v3 provider cannot attest with an Enterprise key.
   Any secret stays in the Firebase / Google Cloud consoles and never goes into this repo. The
   site key is public, but it is passed at build time rather than committed.
2. **iOS**: the app `com.tashil.realestate` (Team ID `TX5G7GZL6T`) is registered for **App
   Attest** in App Check. The app activates `AppleAppAttestWithDeviceCheckFallbackProvider`
   (App Attest, with DeviceCheck on devices that lack it). DeviceCheck is **not** registered in
   the console, so those devices stay unverified until it is. `ios/Runner/Runner.entitlements`
   (Release and Profile) sets `com.apple.developer.devicecheck.appattest-environment` to
   `production`; `ios/Runner/RunnerDebug.entitlements` (Debug) sets it to `development`.
   Enable the App Attest capability on the App ID `com.tashil.realestate` in the Apple
   developer account if it is not already on, or signing fails.
3. **Android**: the app activates `AndroidPlayIntegrityProvider`. Play Integrity is registered
   only for the Firebase app `ae.tashilaqar.app`
   (`1:534001947779:android:6ae6cd3ce53bcb8e7ff7b6`). The repo still builds as
   `com.example.tashil_real_estate`, so **Android App Check only verifies once the app ships as
   `ae.tashilaqar.app` with a real release signing key**. Renaming the package and signing are
   a separate ticket. Until then Android tokens are not verified, which is harmless while
   enforcement is off.
4. **Debug builds** use the App Check debug providers on every platform.
5. **Build with the site key**. Release builds need the define only for web; mobile builds
   ignore it:

   ```bash
   flutter build web --release --dart-define=RECAPTCHA_SITE_KEY=<site key>
   flutter build ipa --release
   flutter build appbundle --release
   ```

   Without the define, release web builds skip App Check instead of sending tokens made
   with an invalid key.
6. **Check the metrics** in Firebase console > App Check > APIs: most callable requests
   should be "verified" before enforcing.
7. **Enable enforcement for the callables** by setting `ENFORCE_APP_CHECK=true` for the
   production deploy, for example in `backend/.env.<production project id>`:

   ```bash
   ENFORCE_APP_CHECK=true
   ```

   Then redeploy the functions. Any other value, or no value, keeps enforcement off.

Firestore and Storage App Check enforcement are separate switches in the Firebase console
and are not affected by `ENFORCE_APP_CHECK`.

## Public listings (`firestore.rules`, TAQ-131)

- A visitor can `get` a `/Properties` doc only when it is published and `moderation_hidden` is
  neither `true` nor `'true'`. Owners, their agency and platform staff can always read it.
- List queries check `is_published` only. Rules are not filters: also testing `moderation_hidden`
  would refuse the marketplace query (`is_published == true`), and adding a
  `moderation_hidden == false` filter would drop public docs that lack the field. No write can make
  a doc both published and hidden instead: a SuperAdmin create with both is refused, Admin and
  SuperAdmin visibility changes can only set `is_published` to false, and the sync trigger sets
  `is_published = !moderation_hidden`.

## Listing photos (`storage.rules`)

Photos live under `public/listings/{ownerUid}/{propertyId}/{fileName}`.

- The owner, a SuperAdmin and an Admin can always read and list them.
- Anyone else can read a photo only while `/Properties/{propertyId}` exists, has
  `is_published == true`, `status == 'vacant'` and `moderation_hidden` neither `true` nor the
  string `'true'`, and has `owner_id == ownerUid`. `firestore.rules` treats the string the same
  way (TAQ-131).
  Unpublished, rented, moderation-hidden and deleted listings are refused. The rule costs one
  Firestore read (Storage rules allow two per evaluation).
- Owners cannot upload or replace photos while `PropertyModeration/{propertyId}` has
  `hidden: true`, and `firestore.rules` stops them adding new `imageUrls` / `image` refs to
  `Users/{ownerUid}/properties/{propertyId}` for as long. They can still delete photos and
  remove refs; SuperAdmin and Admin can delete photos for moderation.
- Public listings store Storage photos as tokenless `...?alt=media` URLs: the sanitizer drops
  `&token=` and `firestore.rules` rejects it, so every download goes through these rules.
- Download URLs with `&token=` are bearer links: Cloud Storage serves them without evaluating
  the rules. A token URL handed out while a listing was live keeps working after it goes
  offline unless the token is replaced. The `revokePhotoTokensOnOffline` function
  (`backend/listing_photos.js`, TAQ-109) watches `Properties/{propertyId}`: when a listing stops
  being live by the same check as `listingLive` (unpublished, rented, made unavailable, held by
  moderation, deleted, or handed to another owner) it replaces the `firebaseStorageDownloadTokens`
  of every object under `public/listings/{owner}/{propertyId}/` that has one, and it does so again
  when the listing goes live. The replacement is a single fresh token, which drops the old ones in
  Cloud Storage. The Storage emulator appends instead of replacing, so the emulator test checks
  what is written, not that an old link stops working. The function's service account needs
  `storage.objects.update` on the default bucket (the default compute account has it). A listing
  that was offline when this function was deployed keeps any token issued earlier until its next
  change of state; revoke those once in the console if needed.
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
A local probe script that needs one bucket per simulated visitor can start the emulator with
`VISITOR_IP_EMULATOR_TRUST_XFF=true` (for example in `backend/.env.local`), which trusts the
last `X-Forwarded-For` entry again, or send each simulated visitor from a different source
address. The switch is read only when `FUNCTIONS_EMULATOR` is exactly `true`, so it never
changes a deployed function (tested in `backend/test/gemini_gateway.test.js`). Never set it on
dev or prod anyway: keep it out of `backend/.env`, every `backend/.env.<project id>` and the
function's runtime environment (`backend/test/project_config.test.js` fails if a committed env
file names it).
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

## Paymob rent payments (TAQ-16)

Rent is paid through Paymob Unified Checkout (UAE). The app never decides that a payment happened:

1. `createRentPaymentIntent` (callable, the lease's tenant only) loads the lease, takes the amount
   from it, writes `Transactions/{leaseId}_{YYYY-MM}` as `pending`, asks Paymob for an intention
   and returns the checkout URL. The checkout URL (it carries the intention's client secret) is
   kept in `PaymentSessions/{paymobOrderId}`, which no client can read.
2. `paymobWebhook` (HTTPS) receives Paymob's "Transaction Processed" callback. It verifies the
   `hmac` query parameter (HMAC-SHA512 over the 20 documented fields, with `PAYMOB_HMAC_SECRET`),
   finds the payment by the Paymob order id the server stored (not by anything in the body's
   references), checks amount and currency, and only then sets `paid`, issues the `Paid_Verified`
   invoice and notifies the tenant and the owner. Replays and duplicate captures change nothing.
   Failed callbacks set `failed` (a later success on the same order still pays it). Refunds and
   voids are logged for manual review and do not change the payment.
3. Clients cannot write `Transactions` or read `PaymentSessions` (`firestore.rules`).

### Turning it on

The gateway is off: `PAYMENTS_ENABLED` is unset (the default is off). While off, the callable answers
`failed-precondition` and the webhook answers `503`, and deploys do not bind the Paymob secrets, so a
missing secret cannot block a deploy. To enable it for a project:

```
firebase functions:secrets:set PAYMOB_SECRET_KEY --project <project>
firebase functions:secrets:set PAYMOB_PUBLIC_KEY --project <project>
firebase functions:secrets:set PAYMOB_HMAC_SECRET --project <project>
firebase functions:secrets:set PAYMOB_INTEGRATION_ID --project <project>
```

Then, in the git-ignored `backend/.env.<project id>`, set `PAYMENTS_ENABLED=true` and
`PAYMOB_NOTIFICATION_URL=<the deployed paymobWebhook HTTPS URL>`; optional:
`PAYMOB_REDIRECT_URL`, `PAYMOB_BASE_URL` (default `https://uae.paymob.com`),
`PAYMOB_CHECKOUT_URL` (default `https://uae.checkout.paymob.com`), `PAYMOB_CURRENCY` (default
`AED`). In the Paymob dashboard set the integration's transaction processed callback to the same
URL. Use Paymob's test keys on dev and live keys only on prod. Never put any of these keys in
`backend/.env` or anywhere in the repo (`backend/test/project_config.test.js` fails if a tracked
file names them).

Before the first live payment, run a sandbox payment end to end: Paymob's docs do not say how a
`null` field is written into the signed string, and the code treats it as empty (as PHP and
JavaScript's `join` do). A sandbox callback with a wrong-signature result would show it at once.

Deploying this change also stops exporting `processRentPayment`, so the deploy deletes it. A
non-interactive deploy needs `firebase deploy --only functions --force` to confirm the deletion;
run that on dev first and on prod only with Mohamed's approval. Nothing in the app calls the old
function.

### Payment split and manual payments (TAQ-16)

- The platform and agency percentages come from `Settings/payment_split` (`platform_percent`,
  `agency_percent`; the owner gets the rest). Only SuperAdmin can read or write it (rules), the
  functions read it server-side when a payment is created, and the client never sends one. With no
  document the split is 2 / 8 / 90; an invalid document stops payments (`split_invalid`) instead of
  guessing. A payment keeps the split it was created with.
- `recordManualPayment` lets the lease's owner, its managing agency, Admin or SuperAdmin record cash
  or bank-transfer rent (method, reference, paid-on date). It settles the month the same way the
  webhook does (invoice `Paid_Recorded`, receipt and owner notifications) and writes an `auditTrail`
  entry on the transaction. No split is deducted because the money did not pass through the platform.
