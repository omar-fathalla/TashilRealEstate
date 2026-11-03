const admin = require('firebase-admin');

// Refuse to touch any project unless the caller names it and confirms.
// This script can write Auth users and Firestore documents for that project.
const projectFlag = process.argv.indexOf('--project');
const projectId = projectFlag >= 0 ? process.argv[projectFlag + 1] : '';
const confirm = process.env.TASHIL_SEED_CONFIRM;

if (!projectId || confirm !== 'I_UNDERSTAND_THIS_WRITES_DATA') {
  console.error(
    'Refusing to run backend/seed.js. Pass --project <firebase-project-id> and set TASHIL_SEED_CONFIRM=I_UNDERSTAND_THIS_WRITES_DATA. For local data use backend/seed_emulator.js instead.',
  );
  process.exit(1);
}

admin.initializeApp({
  projectId,
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
