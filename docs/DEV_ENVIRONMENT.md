# Dev environment (`tashil-aqar-dev`)

Tashil Aqar has its own dev Firebase project. Use it to test deploys, the web build and
the Gemini gateway without touching production.

| Alias in `.firebaserc` | Project id | Number | Use |
| --- | --- | --- | --- |
| `default` | `demo-tashil-dev` | none | Emulators only. A `demo-*` id never reaches Google services. |
| `dev` | `tashil-aqar-dev` | 169661829655 | Real dev project: deploys, User Test, staging checks. |
| `prod` | `tashil-proptech-os` | 534001947779 | Production. Needs Mohamed's explicit OK. |

`default` stays the emulator-only demo project, as in `docs/LOCAL_DEVELOPMENT.md`: a command
run without `--project` can never reach a real project by accident. Always name the project
for live work: `--project dev` or `--project prod`.

Only the three projects above belong to Tashil Aqar. Do not point this repo at any other
Firebase project.

## Build the web app for dev

`FIREBASE_ENV` picks the Firebase config at build time. Without it the build is prod, so
existing production build commands are unchanged. The dev web config is in
`frontend/lib/firebase_options_dev.dart` (web only; no Android or iOS app is registered in
the dev project yet, and those builds fail instead of falling back to prod).

The dev web API key is a public Firebase browser key restricted to dev referrers. It is not in
the repo; pass it as `DEV_FIREBASE_WEB_API_KEY`. A dev build without it throws at start-up
(`FIREBASE_ENV=dev needs the dev web API key`), and an unknown `FIREBASE_ENV` value throws too.

```bash
cd frontend
flutter build web --release \
  --dart-define=FIREBASE_ENV=dev \
  --dart-define=DEV_FIREBASE_WEB_API_KEY=<dev web key> \
  --dart-define=RECAPTCHA_SITE_KEY=<dev site key, once App Check is set up for dev>
```

Check the output for stray keys. The scan accepts the prod keys from `firebase_options.dart`
plus the one dev key you export, and fails on anything else:

```bash
cd backend
DEV_FIREBASE_WEB_API_KEY=<dev web key> npm run check:client-keys:build
```

## Deploy to dev

Hosting serves `frontend/build/web`, so build first. Always pass `--project dev`:

```bash
firebase deploy --project dev --only functions
firebase deploy --project dev --only firestore:rules,firestore:indexes,storage
firebase deploy --project dev --only hosting
```

`npm run deploy` in `backend/` is prod-only (`--project prod`); do not use it for dev.
Non-secret function settings such as `VISITOR_IP_TRUSTED_HOPS` or `ENFORCE_APP_CHECK` go in
`backend/.env.tashil-aqar-dev` (Firebase loads `.env.<project id>` on deploy). Never put a
secret in it; secrets go through Secret Manager.

## Secrets

Secrets live in the dev project's Secret Manager, never in the repo, `.env` files or build
defines.

- `GEMINI_API_KEY`, version 1, is set in dev Secret Manager and bound to `geminiGenerate`.
  Calls from a dev deploy therefore reach the real Gemini API and use real quota.
- Rotate or change it with `firebase functions:secrets:set GEMINI_API_KEY --project dev`, then
  redeploy `functions:geminiGenerate`.
- Test-account passwords are kept in dev Secret Manager too (see below).

### Gemini model (TAQ-89)

The model is a server-side setting, the string param `GEMINI_MODEL` (default
`gemini-3.5-flash`). The app never chooses it: every old model name the app sends
(`gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-2.0-*`, `gemini-3.8-pro`, and so on) runs
on the configured model. To change it, put the value in the git-ignored
`backend/.env.<project id>` (for example `backend/.env.tashil-aqar-dev`, or `.env.local` for the
emulator):

```
GEMINI_MODEL=gemini-3.8-flash
```

then redeploy `functions:geminiGenerate`. Allowed values: `gemini-3.5-flash`,
`gemini-3.8-flash`, `gemini-flash-latest`, `gemini-flash-lite-latest`. Anything else is ignored
with a warning and the default is used. To allow a new model, add it to `ALLOWED_MODELS` in
`backend/gemini_gateway.js`.

If Gemini answers 404 ("no longer available"), `functions:log --only geminiGenerate` shows an
error entry naming the model (never the key) and callers get the normal "AI service is
unavailable" error. Set `GEMINI_MODEL` to an available model and redeploy.

## Verify the visitor IP rule on dev (TAQ-77)

This is the check described in `docs/SECURITY_SETUP.md` ("Visitor rate limits"), run against
`tashil-aqar-dev`. Dev has a real Gemini key, so calls 1-10 return real answers.

1. Deploy the functions: `firebase deploy --project dev --only functions:geminiGenerate`.
2. Signed out, call it 11 times with a forged header that changes every time:

   ```bash
   URL=https://us-central1-tashil-aqar-dev.cloudfunctions.net/geminiGenerate
   for i in $(seq 1 11); do
     curl -s -X POST "$URL" -H 'Content-Type: application/json' -H "X-Forwarded-For: 10.0.0.$i" \
       -d '{"data":{"feature":"valuation","request":{"contents":[{"parts":[{"text":"Reply with OK"}]}]}}}'
     echo
   done
   ```

   Calls 1-10 return an answer; call 11 must return `RESOURCE_EXHAUSTED`. If it does not, the
   forged header is being trusted: fix `VISITOR_IP_TRUSTED_HOPS`.
3. In the Firestore console for dev, `AiRateLimits` must hold exactly one new `ip_...`
   document (minute count 10).
4. `firebase functions:log --only geminiGenerate --project dev` must show
   `ipSource: "x-forwarded-for"`. If every call says `socket`, the platform is not adding
   the header the way the code assumes.
5. From a second network (for example a phone hotspot), one call must succeed and create a
   second `ip_...` document. If it is rejected, every visitor shares one bucket (the hop count
   is too high, or a proxy address is being counted).

Record the result on TAQ-77. To clear the buckets between runs, delete the `ip_...` documents
in dev `AiRateLimits` (they only hold counters).

## Test accounts

The dev project has one test account per role, all on the `test.tashilaqar.com` domain:

- `visitor@test.tashilaqar.com`
- `tenant@test.tashilaqar.com`
- `owner@test.tashilaqar.com`
- `agency@test.tashilaqar.com`
- `investor@test.tashilaqar.com`
- `admin@test.tashilaqar.com`
- `superadmin@test.tashilaqar.com`

Passwords exist only in the dev project's Secret Manager. Never write them into the repo, a PR,
a ticket or a build define. Do not delete these accounts.

How the roles map to the backend (`backend/authz.js`, `firestore.rules`, TAQ-91):

| Account | Role claim | Notes |
| --- | --- | --- |
| `visitor@` | none | Signed in with no role: public AI features only, no onboarding or OCR. A real visitor is signed out. |
| `tenant@` | `Tenant` (claim or profile) | |
| `owner@` | `Owner` (claim or profile) | |
| `agency@` | `AgencyAdmin` + `agency_id` claim | |
| `investor@` | `Investor` (claim or profile) | Self-service like Owner and Tenant. Browses, saves, compares, market index, valuation and AI. No publishing, leases or tenants. |
| `admin@` | `Admin` (claim only) | Platform Admin. Moderates listings and reads users and agencies. Only a SuperAdmin can grant it. |
| `superadmin@` | `SuperAdmin` (claim only) | |

### What each role can do (TAQ-91 decisions)

- **Admin** (`/admin`): hide, restore and verify public listings (`is_published`,
  `verified`, `moderation_hidden`, `updated_at` only; a hidden listing can be restored only while
  vacant); read all listings, agencies, crash telemetry; read users only through the
  `listUsersForAdmin` callable, which returns an allowlist (uid, email, name, role, country and
  agency) and never the IBAN, national ID, phone or any private field; escalate maintenance requests
  (`status`, `escalated`, `resolution_note`). It cannot call `setUserRole`, touch roles or claims,
  create or change a SuperAdmin, write system settings, Remote Config, payments, invoices or
  secrets, run `seedDatabase` or `syncMarketIndexManual`, or delete users. Its role is never read
  from the profile document, so it cannot be self-granted.
- **Investor**: browse, save and compare listings, market index, valuation and the AI features that
  are open to any signed-in user. It cannot publish listings and has no access to leases, tenants
  or maintenance. It is accepted at signup and never escalates: the profile document can only ever
  carry `Owner`, `Tenant` or `Investor`.
- **OCR and onboarding** (`document_ocr`, `onboarding` in the Gemini gateway) stay `Owner`,
  `AgencyAdmin`, `Admin` and `SuperAdmin`. Investors do not get them: both features exist to
  list and manage properties, which an Investor cannot do, and OCR processes identity and
  contract documents.
- **Where each lands**: `Admin` -> `/admin`, `SuperAdmin` -> `/super-admin` (it may also open
  `/admin`), `Investor` -> `/` (the marketplace). `/super-admin` stays SuperAdmin-only.
  `/investor-dashboard` stays public, as before.

## Creating the test users

`backend/seed.js` creates users with roles. Two sets:

- Default set (`DEMO_USERS`): `agency@test.com`, `owner@test.com`, `tenant@test.com`. One password
  from `SEED_DEMO_PASSWORD`.
- `--set tashilaqar-test` (TAQ-91): the seven accounts above on `test.tashilaqar.com`. Each
  password comes from its own variable: `SEED_PW_VISITOR`, `SEED_PW_TENANT`, `SEED_PW_OWNER`,
  `SEED_PW_AGENCY`, `SEED_PW_INVESTOR`, `SEED_PW_ADMIN`, `SEED_PW_SUPERADMIN` (at least 8
  characters, never argv). Emulators and `demo-*` projects may leave them unset (random passwords
  are generated and printed). The visitor gets an Auth user with no claim and no role.

Safety: the test set runs only against emulators, `demo-*` projects, or `tashil-aqar-dev` with
`--allow-live-project`. The production project is read from the `prod` alias in `.firebaserc` at
runtime and always refused. Seeded documents carry `demo_seed: true`. Existing accounts keep their
password unless `--reset-passwords` is passed; nothing is deleted.

```bash
# Emulator
firebase emulators:exec --only firestore,auth --project demo-tashil-dev 'node seed.js --set tashilaqar-test'

# Dev (Application Default Credentials for dev; set all seven SEED_PW_* variables first)
node seed.js --set tashilaqar-test --project tashil-aqar-dev --allow-live-project
```

Passwords exist only in Secret Manager or the shell environment. Do not write them to the repo.

## Follow-ups

- The Admin dashboard covers listings moderation and read-only users and agencies. There is no
  Reports feature or collection in the app yet, so "handle reports" has nothing to act on; add it
  with the reports feature. Maintenance escalation is enforced in `firestore.rules` and tested,
  but has no screen in `/admin` yet.
- `/fast-onboarding` is still limited to `Owner` and `AgencyAdmin` in the Flutter route table (as
  before TAQ-91). The gateway already accepts `Admin` and `SuperAdmin` for onboarding and OCR.
- App Check for dev: register a dev reCAPTCHA site key before turning on `ENFORCE_APP_CHECK` in
  dev, as described in `docs/SECURITY_SETUP.md`.
- Mobile: add an Android and an iOS app to `tashil-aqar-dev` and extend
  `firebase_options_dev.dart` before building dev mobile apps.
