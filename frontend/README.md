# tashil_real_estate

A new Flutter project.

## Local Firebase emulators

Screenshot and local builds pass `--dart-define=USE_FIREBASE_EMULATOR=true`. The app connects Auth, Firestore, and Storage to loopback (`127.0.0.1` by default, or `FIREBASE_EMULATOR_HOST`) before Auth restores a session. It will not start those clients against a non-loopback host.

Seed the emulators from the repo root `backend/` directory:

```bash
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
export DEMO_USER_PASSWORD='your-demo-password'
export SUPER_ADMIN_PASSWORD='your-admin-password'
npm run seed:emulator
```

`backend/seed_emulator.js` exits immediately unless both emulator host variables are set to a loopback address. It creates the owner, tenant, agency, investor, and super-admin demo accounts, their `Users/{uid}` role documents, the Dubai permit listing, and one lease. Passwords are read from the environment and are not printed.

## `backend/seed.js`

That script can write Auth and Firestore for a named project. It refuses to run unless you pass `--project <firebase-project-id>` and set `TASHIL_SEED_CONFIRM=I_UNDERSTAND_THIS_WRITES_DATA`. Use `npm run seed:emulator` for local data. Do not point `seed.js` at the production project.
