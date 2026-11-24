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

How the roles map to the backend today (`backend/authz.js`, `firestore.rules`):

| Account | Role claim | Notes |
| --- | --- | --- |
| `visitor@` | none | Signed in, no role: can use public AI features, not onboarding or OCR. |
| `tenant@` | `Tenant` (claim or profile) | |
| `owner@` | `Owner` (claim or profile) | |
| `agency@` | `AgencyAdmin` + `agency_id` claim | |
| `admin@` | not defined | The backend has no plain "Admin" role; see "Open questions". |
| `superadmin@` | `SuperAdmin` | |
| `investor@` | not defined | There is no Investor role yet; see below. |

## Creating the test users

`backend/seed.js` is the only script that creates users with roles. What it does today:

- It seeds three accounts only: `agency@test.com` (AgencyAdmin), `owner@test.com` (Owner) and
  `tenant@test.com` (Tenant). The list is `DEMO_USERS` in `seed.js`.
- The password comes from the `SEED_DEMO_PASSWORD` environment variable (at least 8
  characters), never argv. One password is used for all accounts. Without it, the script
  generates one and prints it, which is only allowed for emulators and `demo-*` projects.
- Emulator: `firebase emulators:exec --only firestore,auth --project demo-tashil-dev 'node seed.js'`.
- Dev: `SEED_DEMO_PASSWORD=... node seed.js --project tashil-aqar-dev --allow-live-project`, with
  Application Default Credentials for dev. It refuses any other live project without the flag.
- Existing accounts keep their password unless `--reset-passwords` is given; nothing is deleted.
- It cannot create `visitor@`, `investor@`, `admin@` or `superadmin@`, and it uses the
  `@test.com` domain. `SuperAdmin` is assignable through `applyUserRole`, but no script uses it.
  `backend/scripts/role_claims.js` only audits claims.

So the seven `@test.tashilaqar.com` accounts cannot be created by an existing script. They were
created by hand in the dev project; do not run `seed.js` against dev expecting them.

### Proposal: seed the per-role accounts from one table

A small change to `seed.js` would cover this (not implemented here, because the Investor and
Admin roles need a decision first):

1. Add a second user set, selected with `--set tashilaqar-test`, with one row per account:
   email, role, display name. `visitor@` has `role: null` (create the user, set no claim).
2. Read passwords from the environment, one variable per account (`SEED_PASSWORD_OWNER`,
   `SEED_PASSWORD_TENANT`, ...) with `SEED_DEMO_PASSWORD` as the fallback, so each role can have
   its own secret that CI or a developer injects from Secret Manager
   (`gcloud secrets versions access latest --secret=... --project tashil-aqar-dev`).
   Passwords never go through argv, files in the repo or logs.
3. Keep the existing safety checks: `demo-*` or loopback emulators run freely; a real project
   needs `--allow-live-project`, which for this set should additionally require the project id
   to be `tashil-aqar-dev` (never prod).
4. Reuse `applyUserRole`, so the claim and the `Users/{uid}` mirror are written the same way as
   `setUserRole`. Extend `test/seed.test.js` with the new set.

## Adding the Investor role

The Investor role does not exist in `setUserRole`: `ASSIGNABLE_ROLES` in `backend/authz.js` is
`Owner`, `Tenant`, `AgencyAdmin`, `SuperAdmin`, so `applyUserRole` rejects `Investor`. The
`/investor-dashboard` route is public today (`null` in `RouteAccess.table`). Proposed change,
as one ticket:

1. **Backend roles** (`backend/authz.js`): add `Investor` to `ASSIGNABLE_ROLES`. Keep it out of
   `SELF_SERVICE_ROLES`, so it is only ever granted by a SuperAdmin through a custom claim, the
   same as AgencyAdmin; a profile document can then never escalate to it. Update
   the `setUserRole` tests in `backend/test/functions.test.js` and check `scripts/role_claims.js`.
2. **Firestore rules** (`firestore.rules`): `currentRole()` already honours any claim, so no
   change there. Add an `isInvestor()` helper and grant read-only access to exactly the
   collections the investor dashboard reads, scoped by `investor_id == request.auth.uid` (the
   multi-tenant isolation standard). Add rules tests for allowed reads and for every write and
   cross-investor read being denied.
3. **Gemini gateway** (`backend/gemini_gateway.js`): add `Investor` to `PORTAL_ROLES` only if
   investors should use onboarding or OCR. Probably they should not, so give investor-facing AI
   features their own role list instead of widening `PORTAL_ROLES`.
4. **Flutter** (`frontend/lib/core/auth/trusted_role.dart`, `route_access.dart`): add
   `TrustedRole.investor` to `all`, set `/investor-dashboard` to `{investor, superAdmin}`, and
   return `/investor-dashboard` from `RouteAccess.homeFor`. Check the login redirect, header
   navbar and role tests.
5. **Seeding and tests**: give `investor@test.tashilaqar.com` the role in the seed set above,
   and add `Investor` cases to the `setUserRole` tests in `backend/test/functions.test.js`.

## Open questions

- `agency@` and `admin@`: the backend knows `AgencyAdmin` and `SuperAdmin`. Decide whether
  `admin@` is a second AgencyAdmin (needs its own `agency_id`), an alias for `SuperAdmin`, or a
  new role. Until then it has no defined behaviour.
- App Check for dev: register a dev reCAPTCHA site key before turning on `ENFORCE_APP_CHECK` in
  dev, as described in `docs/SECURITY_SETUP.md`.
- Mobile: add an Android and an iOS app to `tashil-aqar-dev` and extend
  `firebase_options_dev.dart` before building dev mobile apps.
