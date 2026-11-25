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
`backend/.env.tashil-aqar-dev` (Firebase loads `.env.<project id>` on deploy, after `backend/.env`).
Never put a secret in either file; secrets go through Secret Manager.

### Function params in `backend/.env` (TAQ-89)

A non-interactive `firebase deploy --only functions` (CI, agents) fails with "no value for
GEMINI_THINKING_BUDGET" unless every `defineString`/`defineInt` param has a value in a `.env`
file, even if the code has a default. `backend/.env` is committed and holds only those
non-secret params:

| Param | Type | Value | Meaning |
| --- | --- | --- | --- |
| `GEMINI_MODEL` | string | `gemini-3.5-flash` | model the gateway uses |
| `GEMINI_THINKING_BUDGET` | int | `0` | thinking tokens (see below) |

`backend/test/function_params.test.js` fails if a param used in `backend/` has no value there,
if `.env` holds anything that is not a declared param, or if `backend/.env` becomes gitignored.
When you add a `defineString`/`defineInt`, add its line to `backend/.env`. `GEMINI_API_KEY` is a
secret (`defineSecret`) and stays in Secret Manager. `ENFORCE_APP_CHECK` and
`VISITOR_IP_TRUSTED_HOPS` are plain environment variables, not params, so they are not needed
there.

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
on the configured model. To change it for every project, edit `backend/.env`. To change it for
one project, put the value in `backend/.env.<project id>` (for example
`backend/.env.tashil-aqar-dev`), which overrides `backend/.env`; `.env.local` does the same for
the emulator and is gitignored:

```
GEMINI_MODEL=gemini-3.8-flash
```

then redeploy `functions:geminiGenerate`. Allowed values: `gemini-3.5-flash`,
`gemini-3.8-flash`, `gemini-flash-latest`, `gemini-flash-lite-latest`. Anything else is ignored
with a warning and the default is used. To allow a new model, add it to `ALLOWED_MODELS` in
`backend/gemini_gateway.js`.

### Thinking budget and output tokens (TAQ-89)

Gemini 3.x models think before answering, and thinking tokens count against `maxOutputTokens`.
A small limit (a call with 200 used 188 on thinking) returns a cut-off answer. The server
therefore owns both settings:

- `GEMINI_THINKING_BUDGET` (int param, default `0`) is sent as
  `generationConfig.thinkingConfig.thinkingBudget` on every call. `0` turns thinking off, a
  positive number (up to 24576) caps it, `-1` sends no `thinkingConfig` at all (the model's own
  default). An invalid value is ignored and `0` is used. Any `thinkingConfig` from the client is
  dropped. Set it in `backend/.env` (or a per-project `.env.<project id>`) like `GEMINI_MODEL`, then redeploy
  `functions:geminiGenerate`. When you raise it, keep the budget well below the 4096 output cap.
- `maxOutputTokens` from the app is clamped to between 1024 and 4096. The floor is
  `CAPS.minOutputTokens` in `backend/gemini_gateway.js`.

Google's docs describe `thinking_level` as the control for Gemini 3 and later, so check a live
call after any model change. If Gemini rejects `thinkingBudget` for a model, set
`GEMINI_THINKING_BUDGET=-1` as a stopgap (the 1024 floor still limits truncation).

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

   The local Functions emulator ignores `X-Forwarded-For` altogether (nothing in front of it adds
   the caller's IP), so locally `ipSource` is always `socket` and all calls share one bucket.
   For a local probe that needs one bucket per forged header, set
   `VISITOR_IP_EMULATOR_TRUST_XFF=true` in `backend/.env.local`; deployed functions ignore it.
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

- **Admin** (`/admin`): hide, restore and verify public listings, read all listings, agencies and
  crash telemetry, read users only through the `listUsersForAdmin` callable (an allowlist: uid,
  email, name, profile role, claim role, country and agency; never the IBAN, national ID, phone or
  any private field), and escalate maintenance requests (`status`, `escalated`, `resolution_note`).
  It cannot call `setUserRole`, touch roles or claims, create or change a SuperAdmin, write system
  settings, Remote Config, payments, invoices or secrets, run `seedDatabase` or
  `syncMarketIndexManual`, or delete users. Its role is never read from the profile document, so it
  cannot be self-granted.
- **Listing moderation** lives in `PropertyModeration/{propertyId}` (`hidden`,
  `pre_hide_published`, `updated_by`, `updated_at`). Only Admin and SuperAdmin can create or change
  it, only SuperAdmin can delete it, and no owner, agency or tenant can touch it at all. A missing
  doc means "not hidden". The Admin dashboard writes it in one batch with the public doc, and the
  rules require the two to agree (`getAfter`), so the moderation doc is never written after the
  public doc. `pre_hide_published` records whether the listing was live when hidden; a restore
  brings back that value (and only for a vacant listing), so a listing that was never public is
  never published by a restore. No client write can ever set `is_published` to `true` on the public doc:
  a change to `is_published` or `moderation_hidden` by Admin or SuperAdmin is accepted only in the
  same batch as a `PropertyModeration` write (the rules check that the moderation doc's `updated_at`
  is this request's time) and only to take the listing offline. A restore therefore only lifts the
  hold; `reconcilePropertyModeration` then rebuilds the public doc from the owner's current private
  doc and puts it online only if the listing was live before the hide, the private doc is still
  published and available, the rent is positive and the owner still holds a publishing role. The sync trigger reads `PropertyModeration`, so deleting or
  recreating the public or private doc keeps a hidden listing hidden, and an owner or agency
  cannot delete the public doc of a hidden listing. `reconcilePropertyModeration` takes the
  public doc offline if a hide is written without it. An owner who deletes and recreates the
  private doc under a new id has created a new listing, which needs no moderation.
  Listings hidden before this change have no moderation doc: run
  `node scripts/backfill_property_moderation.js --project <id>` (dry run by default, `--apply` to
  write) once per project. It prints its target project first and refuses any project id that does
  not start with `demo-` unless `--confirm-project=<that id>` is also given (even for a dry run). It records `pre_hide_published: false`, so such a listing is not
  published automatically when restored.
- **Maintenance requests** must carry `lease_id`, and that lease must link the request's
  `tenant_id`, `owner_id` and `agency_id` (empty on both sides when the lease has no agency).
  Only the lease's tenant or owner can create one.
- **Rent payments** (`processRentPayment`): only the lease's tenant (role `Tenant`) can record a
  payment. The owner, the managing agency and SuperAdmin cannot: the app has no flow in which they
  record a payment, so nothing needs it. The amount is the lease's rent (monthly rent, or annual
  rent divided by 12); the client may omit it or repeat it, and any other value is
  `invalid-argument`. Errors are clean codes: `unauthenticated`, `permission-denied`,
  `not-found`, `invalid-argument`, `failed-precondition`, `already-exists`. A lease can be paid once
  per month: the transaction id is `<leaseId>_<YYYY-MM>` (`period` is an optional `YYYY-MM`, from 24
  months back to next month; the default is the current UTC month) and the record is `create()`d
  inside a Firestore transaction, so a repeat or a concurrent call gets `already-exists` (the
  existing id is in the error details) and writes nothing.
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

## Firestore rules budget (TAQ-101)

A request may evaluate at most 1000 rule expressions, and the full listing check (`listingShapeOk`:
sizes, contact filter, image references, localized maps) of a large listing uses most of them. So:

- A SuperAdmin edit of an existing `/Properties` doc validates only the keys that changed
  (`listingEditOk`, from `diff().affectedKeys()`), not the whole doc. Admin and SuperAdmin
  visibility changes (`is_published`, `moderation_hidden`) take the moderation path first.
  Admin still cannot edit content, only verify and moderate.
- The full check runs once, on a SuperAdmin create. A create also needs the owner's private doc at
  `Users/{owner_id}/properties/{id}` and is refused while `PropertyModeration/{id}` says hidden.
- `backend/test/admin_investor_rules.test.js` holds a maximum-size listing fixture (every text at its
  cap, 30 amenities per language, 20 images). Any rule change must keep its create and edit tests green;
  a budget overrun shows as `maximum of 1000 expressions` in the emulator log.
- TAQ-103/104: edits also validate `agencyNames` (ar/en/hi map, strings up to 200 chars, contact-free),
  `agencyPhone` (phone characters, 30 at most), `agency_id` (id characters) and keep `titles` present;
  an image ref with a space inside a list element is rejected. A create that is live (`is_published`
  true) needs the owner's private doc to be published (`isPublished`) and available (`rentalStatus`).
- Measured headroom (SuperAdmin create, largest fixture): about 50-80 expressions of the 1000 left
  (dev before TAQ-103 had under 27 on the largest fixture). One edit that rewrites every text field,
  all images and every scalar in a single update is still over budget; split it, or edit the fields
  you need. The emulator log must show no `maximum of 1000 expressions` message during `npm test`.
- `processRentPayment` rejects a `period` earlier than the lease's start month (`startDate`,
  `start_date`, `leaseStartDate` or `lease_start_date`); a lease with no readable start date keeps the
  24-month window.

## Follow-ups

- The Admin dashboard covers listings moderation and read-only users and agencies. There is no
  Reports feature or collection in the app yet, so "handle reports" has nothing to act on; add it
  with the reports feature. Maintenance escalation is enforced in `firestore.rules` and tested,
  but has no screen in `/admin` yet.
- `/fast-onboarding` is still limited to `Owner` and `AgencyAdmin` in the Flutter route table (as
  before TAQ-91). The gateway already accepts `Admin` and `SuperAdmin` for onboarding and OCR.
- `processRentPayment` records a payment but no money moves: there is no payment provider yet.
- App Check for dev: register a dev reCAPTCHA site key before turning on `ENFORCE_APP_CHECK` in
  dev, as described in `docs/SECURITY_SETUP.md`.
- Mobile: add an Android and an iOS app to `tashil-aqar-dev` and extend
  `firebase_options_dev.dart` before building dev mobile apps.
