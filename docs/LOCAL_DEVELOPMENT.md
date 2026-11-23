# Local development

## Toolchain

| Tool | Version | Notes |
| --- | --- | --- |
| Flutter | 3.50.1 (Dart 3.14) | Pinned in `frontend/.fvmrc` and `frontend/pubspec.yaml` |
| Node.js | 20 | Cloud Functions runtime (`backend/package.json` engines) |
| Java | 21 | Firestore emulator |
| Firebase CLI | 15.x (tested with 15.37) | `npm i -g firebase-tools` |

Flutter 3.41.x and older cannot build the web app with the current lockfile:
`firebase_core_web` 3.11 uses `Object.isA` from `dart:js_interop`, which older Dart SDKs do
not have, and its pubspec does not say so. `pubspec.yaml` therefore requires Flutter 3.50.1,
and `flutter pub get` on an older SDK fails right away with "Try using the Flutter SDK
version: 3.50.1" instead of failing later during `flutter build web`. With
[FVM](https://fvm.app), run `fvm use` inside `frontend/`.

## Firebase projects

`.firebaserc` defaults to the emulator-only project `demo-tashil-dev`. Production is only
reachable through the explicit `prod` alias:

```bash
firebase emulators:start --only functions,firestore,auth   # uses demo-tashil-dev
firebase deploy --only functions --project prod           # production, on purpose only
```

`demo-*` project ids never reach real Google services, so local commands cannot touch
production data by accident.

## Emulators and tests

```bash
cd backend
npm ci
npm test                # rules + functions on Firestore/Auth emulators, then a Functions emulator smoke test
npm run serve           # Functions + Firestore + Auth emulators on demo-tashil-dev
```

The Functions emulator used to crash on the first server-timestamp write
(`Cannot read properties of undefined (reading 'serverTimestamp')`): the emulator wraps
`admin.firestore`, which drops its static `FieldValue`/`Timestamp`. The callables and the
marketplace sync now import them from `firebase-admin/firestore`, and
`npm run test:emulator` checks that inside the real emulator. `processRentPayment` and the
market-index functions still use the old form and will fail the same way in the emulator
until their own tickets (TAQ-16, TAQ-20) touch them.

## Demo accounts

Demo accounts (`agency@test.com`, `owner@test.com`, `tenant@test.com`) are seeded by a local
admin script, never by a deployed endpoint:

```bash
cd backend
# Into the emulators:
firebase emulators:exec --only firestore,auth --project demo-tashil-dev 'node seed.js'
# Into a real project, deliberately (password from the environment, never argv):
SEED_DEMO_PASSWORD='...' node seed.js --project <project id> --allow-live-project
```

`seed.js` refuses real projects unless both the Firestore and Auth emulators are on loopback
or `--allow-live-project` is passed. Existing accounts keep their password unless
`--reset-passwords` is passed, and nothing is deleted.

The login screen only shows the demo buttons in builds made with
`--dart-define=DEMO_DATA=true`. Add `--dart-define=DEMO_PASSWORD=...` to let them sign in
directly; otherwise they only fill in the email.
