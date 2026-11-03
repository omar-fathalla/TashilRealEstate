/**
 * Seeds the local Firebase emulators only.
 *
 * Required environment:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
 *   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
 *   DEMO_USER_PASSWORD=...          (owner, tenant, agency, investor)
 *   SUPER_ADMIN_PASSWORD=...        (super-admin accounts)
 *
 * Optional:
 *   FIREBASE_PROJECT_ID=tashil-proptech-os
 *
 * Does not print passwords. Exits before initializing Firebase when either
 * emulator host is missing or is not loopback.
 */
const admin = require('firebase-admin');

function loopbackHost(value, name) {
  if (!value || !value.trim()) {
    console.error(`Refusing to run: ${name} is not set. This script only talks to the local emulators.`);
    process.exit(1);
  }
  const host = value.split(':')[0].trim().toLowerCase();
  const loopback = host === 'localhost' || host === '::1' || host.startsWith('127.');
  if (!loopback) {
    console.error(`Refusing to run: ${name} is not a loopback address.`);
    process.exit(1);
  }
  return value.trim();
}

const firestoreHost = loopbackHost(process.env.FIRESTORE_EMULATOR_HOST, 'FIRESTORE_EMULATOR_HOST');
const authHost = loopbackHost(process.env.FIREBASE_AUTH_EMULATOR_HOST, 'FIREBASE_AUTH_EMULATOR_HOST');
const demoPassword = process.env.DEMO_USER_PASSWORD || '';
const adminPassword = process.env.SUPER_ADMIN_PASSWORD || '';

if (!demoPassword || !adminPassword) {
  console.error('Refusing to run: set DEMO_USER_PASSWORD and SUPER_ADMIN_PASSWORD. They are not stored in the repo.');
  process.exit(1);
}

process.env.FIRESTORE_EMULATOR_HOST = firestoreHost;
process.env.FIREBASE_AUTH_EMULATOR_HOST = authHost;

const projectId = process.env.FIREBASE_PROJECT_ID || 'tashil-proptech-os';

admin.initializeApp({ projectId });

const auth = admin.auth();
const db = admin.firestore();

const users = [
  { email: 'owner@demo.tashil.test', password: demoPassword, role: 'Owner', fullName: 'Demo Owner' },
  { email: 'tenant@demo.tashil.test', password: demoPassword, role: 'Tenant', fullName: 'Demo Tenant' },
  { email: 'agency@demo.tashil.test', password: demoPassword, role: 'AgencyAdmin', fullName: 'Demo Agency' },
  { email: 'investor@demo.tashil.test', password: demoPassword, role: 'Investor', fullName: 'Demo Investor' },
  { email: 'superadmin@demo.tashil.test', password: adminPassword, role: 'SuperAdmin', fullName: 'Demo Super Admin' },
  { email: 'support@sw-point.com', password: adminPassword, role: 'SuperAdmin', fullName: 'Support Admin' },
];

async function upsertUser(user) {
  let record;
  try {
    record = await auth.getUserByEmail(user.email);
    await auth.updateUser(record.uid, {
      password: user.password,
      displayName: user.fullName,
      emailVerified: true,
    });
  } catch (err) {
    if (err.code !== 'auth/user-not-found') throw err;
    record = await auth.createUser({
      email: user.email,
      password: user.password,
      displayName: user.fullName,
      emailVerified: true,
    });
  }
  await db.collection('Users').doc(record.uid).set({
    user_id: record.uid,
    email: user.email,
    role: user.role,
    full_name: user.fullName,
    country_code: 'AE',
  }, { merge: true });
  console.log(`Seeded ${user.role} ${user.email}`);
  return record.uid;
}

async function seed() {
  const ids = {};
  for (const user of users) {
    ids[user.role + ':' + user.email] = await upsertUser(user);
  }
  const ownerId = ids['Owner:owner@demo.tashil.test'];
  const tenantId = ids['Tenant:tenant@demo.tashil.test'];

  await db.collection('Properties').doc('listing-dubai-permit').set({
    id: 'listing-dubai-permit',
    countryCode: 'AE',
    country_code: 'AE',
    currencyCode: 'AED',
    titles: {
      ar: 'شقة واجهة مائية في دبي مارينا',
      en: 'Waterfront apartment in Dubai Marina',
      hi: 'दुबई मरीना में वॉटरफ्रंट अपार्टमेंट',
    },
    descriptions: {
      ar: 'شقة مفروشة بإطلالة على المارينا وقريبة من الخدمات.',
      en: 'Furnished apartment with a marina view, close to services.',
      hi: 'मरीना दृश्य वाला सुसज्जित अपार्टमेंट।',
    },
    propertyTypeCode: 'apartment',
    locations: {
      ar: 'دبي مارينا، دبي',
      en: 'Dubai Marina, Dubai',
      hi: 'दुबई मरीना, दुबई',
    },
    cityCode: 'dubai',
    pricePerMonth: 18000,
    bedrooms: 2,
    bathrooms: 2,
    areaSqM: 120,
    imageUrls: [],
    amenitiesMap: { ar: [], en: [], hi: [] },
    isFurnished: true,
    isFeatured: true,
    agencyNames: {
      ar: 'دبي برايم للعقارات',
      en: 'Dubai Prime Real Estate',
      hi: 'दुबई प्राइम रियल एस्टेट',
    },
    agencyPhone: '+97143000000',
    rating: 4.8,
    adPermitNumber: '7123456789',
    advertisingPermitNumber: '7123456789',
    isSample: false,
    brokerId: 'broker-demo-marina',
    owner_id: ownerId,
    status: 'published',
  }, { merge: true });
  console.log('Seeded Properties/listing-dubai-permit');

  const now = new Date();
  const end = new Date(now.getTime());
  end.setFullYear(end.getFullYear() + 1);
  await db.collection('Leases').doc('lease-dubai-permit').set({
    contractNumber: 'AE-2026-DXB-1001',
    countryCode: 'AE',
    country_code: 'AE',
    status: 'active',
    startDate: now.toISOString(),
    endDate: end.toISOString(),
    owner_id: ownerId,
    tenant_id: tenantId,
    propertyId: 'listing-dubai-permit',
    lessor: {
      name: 'Demo Owner',
      nationalIdOrEmiratesId: '784-1985-1111111-1',
      nationality: 'AE',
      phone: '+971501110000',
      email: 'owner@demo.tashil.test',
      address: 'Dubai Marina',
      isLessor: true,
    },
    tenant: {
      name: 'Demo Tenant',
      nationalIdOrEmiratesId: '784-1992-2222222-2',
      nationality: 'AE',
      phone: '+971502220000',
      email: 'tenant@demo.tashil.test',
      address: 'Dubai Marina',
      isLessor: false,
    },
    property: {
      propertyTitle: 'Waterfront apartment in Dubai Marina',
      unitNumber: '1001',
      buildingName: 'Marina Gate',
      district: 'Dubai Marina',
      city: 'Dubai',
      countryCode: 'AE',
      areaSqm: 120,
      propertyType: 'apartment',
    },
    financialTerms: {
      annualRent: 216000,
      paymentFrequency: 'quarterly',
      securityDeposit: 18000,
      cheques: [],
    },
    clauses: [],
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
    isDeleted: false,
  }, { merge: true });
  console.log('Seeded Leases/lease-dubai-permit');
  console.log('Emulator seed complete.');
  process.exit(0);
}

seed().catch((error) => {
  console.error('Emulator seed failed:', error.message || error);
  process.exit(1);
});
