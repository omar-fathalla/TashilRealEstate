const admin = require('firebase-admin');

function loopback(value) {
  if (!value) return false;
  const host = value.split(':')[0].trim().toLowerCase();
  return host === 'localhost' || host === '::1' || host.startsWith('127.');
}

if (!loopback(process.env.FIRESTORE_EMULATOR_HOST) || !loopback(process.env.FIREBASE_AUTH_EMULATOR_HOST)) {
  console.error(
    'Refusing to run backend/seed.js. It only runs when FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST point at loopback. Use npm run seed:emulator for the demo accounts.',
  );
  process.exit(1);
}

admin.initializeApp({
  projectId: process.env.FIREBASE_PROJECT_ID || 'tashil-proptech-os',
});

const auth = admin.auth();
const db = admin.firestore();

const usersToCreate = [
  { email: 'agency@test.com', password: 'password123', role: 'AgencyAdmin', fullName: 'Test Agency' },
  { email: 'owner@test.com', password: 'password123', role: 'Owner', fullName: 'Test Owner' },
  { email: 'tenant@test.com', password: 'password123', role: 'Tenant', fullName: 'Test Tenant' }
];

async function seed() {
  for (const u of usersToCreate) {
    try {
      let userRecord;
      try {
        userRecord = await auth.getUserByEmail(u.email);
        console.log(`User ${u.email} already exists, updating password...`);
        userRecord = await auth.updateUser(userRecord.uid, { password: u.password });
      } catch (err) {
        if (err.code === 'auth/user-not-found') {
          console.log(`Creating user ${u.email}...`);
          userRecord = await auth.createUser({
            email: u.email,
            password: u.password,
            displayName: u.fullName
          });
        } else {
          throw err;
        }
      }

      console.log(`Setting role ${u.role} in Firestore for UID ${userRecord.uid}...`);
      await db.collection('Users').doc(userRecord.uid).set({
        user_id: userRecord.uid,
        email: u.email,
        role: u.role,
        full_name: u.fullName
      }, { merge: true });

      console.log(`Successfully seeded ${u.email}`);
    } catch (error) {
      console.error(`Error processing ${u.email}:`, error);
    }
  }
  console.log('Seeding complete!');
  process.exit(0);
}

seed();
