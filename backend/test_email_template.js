const { sendBrandedVerificationEmail, sendBrandedPasswordResetEmail } = require("./email_service");
const assert = require("assert");

async function test() {
  console.log("Testing M3 Email Templates...");
  
  const verif = await sendBrandedVerificationEmail("support@sw-point.com");
  assert(verif.success === true, "Verification dispatch should succeed");
  assert(verif.verificationLink === undefined, "Verification link must stay in the email");
  console.log("✅ Verification Email Template Rendered and Dispatched Successfully!");

  const reset = await sendBrandedPasswordResetEmail("support@sw-point.com");
  assert(reset.success === true, "Password reset dispatch should succeed");
  assert(reset.resetLink === undefined, "Reset link must stay in the email");
  console.log("✅ Password Reset Email Template Rendered and Dispatched Successfully!");

  console.log("All backend email tests PASSED!");
}

test().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
