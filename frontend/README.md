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

`backend/seed.js` refuses to start unless `FIRESTORE_EMULATOR_HOST` and `FIREBASE_AUTH_EMULATOR_HOST` are loopback addresses. It cannot be pointed at production. Use `npm run seed:emulator` for the demo accounts. Production seeding is not a deployed function.
