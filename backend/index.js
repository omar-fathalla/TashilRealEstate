const { onCall, onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

exports.processRentPayment = onCall(async (request) => {
  const data = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new Error("Unauthenticated");
  }

  const leaseId = data.leaseId;
  const amount = data.amount;

  if (!leaseId || !amount) {
    throw new Error("Missing leaseId or amount");
  }

  // Calculate splits
  const platformFee = amount * 0.02;
  const agencyFee = amount * 0.08;
  const ownerPayout = amount * 0.90;

  try {
    const db = admin.firestore();
    const transactionRef = db.collection("Transactions").doc();
    
    await transactionRef.set({
      transactionId: transactionRef.id,
      leaseId: leaseId,
      amount: amount,
      splits: {
        platformFee: platformFee,
        agencyFee: agencyFee,
        ownerPayout: ownerPayout
      },
      status: "Completed",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: auth.uid
    });

    return { success: true, transactionId: transactionRef.id };
  } catch (error) {
    logger.error("Error processing rent payment", error);
    throw new Error("Failed to process payment");
  }
});

exports.seedDatabase = onRequest(async (req, res) => {
  const users = [
    { email: "agency@test.com", password: "password123", role: "AgencyAdmin", name: "Test Agency" },
    { email: "owner@test.com", password: "password123", role: "Owner", name: "Test Owner" },
    { email: "tenant@test.com", password: "password123", role: "Tenant", name: "Test Tenant" }
  ];

  const db = admin.firestore();
  const results = [];

  for (const u of users) {
    try {
      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(u.email);
      } catch (e) {
        if (e.code === 'auth/user-not-found') {
          userRecord = await admin.auth().createUser({
            email: u.email,
            password: u.password,
            displayName: u.name,
          });
        } else {
          throw e;
        }
      }

      await db.collection("Users").doc(userRecord.uid).set({
        user_id: userRecord.uid,
        email: u.email,
        full_name: u.name,
        role: u.role,
        agency_id: "agency_test_123" // Mock agency ID
      }, { merge: true });

      results.push({ email: u.email, uid: userRecord.uid, status: "Seeded" });
    } catch (error) {
      logger.error(`Error seeding ${u.email}`, error);
      results.push({ email: u.email, error: error.message });
    }
  }

  res.json({ message: "Seeded Successfully", details: results });
});
