const fs = require("fs");
const path = require("path");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

/**
 * Creates the Nodemailer Transporter based on environment variables or dev defaults.
 */
function createTransporter() {
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT || "587", 10);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (host && user && pass) {
    return nodemailer.createTransport({
      host: host,
      port: port,
      secure: port === 465,
      auth: { user: user, pass: pass },
    });
  }

  // Graceful development / sandbox transporter
  return nodemailer.createTransport({
    streamTransport: true,
    newline: "unix",
    buffer: true,
  });
}

/**
 * Default ActionCodeSettings directing users to the Tashil Web App
 */
const defaultActionSettings = {
  url: process.env.APP_BASE_URL || "https://tashilaqar.com/admin/login?verified=true",
  handleCodeInApp: true,
};

/**
 * Dispatches a rich Material Design 3 Email Verification message.
 * @param {string} email - Destination email address
 * @param {object} customSettings - Optional custom ActionCodeSettings
 */
async function sendBrandedVerificationEmail(email, customSettings = {}) {
  const cleanEmail = email.trim();
  const settings = { ...defaultActionSettings, ...customSettings };

  let link;
  try {
    link = await admin.auth().generateEmailVerificationLink(cleanEmail, settings);
  } catch (err) {
    logger.warn(`Could not generate Firebase verification link, using fallback action URL: ${err.message}`);
    link = `https://tashil-proptech-os.firebaseapp.com/__/auth/action?mode=verifyEmail&email=${encodeURIComponent(cleanEmail)}`;
  }

  // Load M3 HTML Template
  const templatePath = path.join(__dirname, "templates", "email_verification_template.html");
  let html = fs.readFileSync(templatePath, "utf8");
  html = html.replace(/{{USER_EMAIL}}/g, cleanEmail);
  html = html.replace(/{{VERIFICATION_LINK}}/g, link);

  const transporter = createTransporter();
  const mailOptions = {
    from: '"منظومة تسهيل عقار | Tashil Aqar" <noreply@tashil-proptech-os.firebaseapp.com>',
    replyTo: "support@sw-point.com",
    to: cleanEmail,
    subject: "تأكيد وتفعيل البريد الإلكتروني | Tashil Aqar Verification",
    html: html,
  };

  const info = await transporter.sendMail(mailOptions);
  logger.info(`✅ [EmailService] Verification email sent to ${cleanEmail}`);

  return {
    success: true,
    messageId: info.messageId,
    verificationLink: link,
  };
}

/**
 * Dispatches a rich Material Design 3 Password Reset message.
 * @param {string} email - Destination email address
 * @param {object} customSettings - Optional custom ActionCodeSettings
 */
async function sendBrandedPasswordResetEmail(email, customSettings = {}) {
  const cleanEmail = email.trim();
  const settings = { ...defaultActionSettings, ...customSettings };

  let link;
  try {
    link = await admin.auth().generatePasswordResetLink(cleanEmail, settings);
  } catch (err) {
    logger.warn(`Could not generate Firebase reset link, using fallback action URL: ${err.message}`);
    link = `https://tashil-proptech-os.firebaseapp.com/__/auth/action?mode=resetPassword&email=${encodeURIComponent(cleanEmail)}`;
  }

  // Load M3 HTML Template
  const templatePath = path.join(__dirname, "templates", "password_reset_template.html");
  let html = fs.readFileSync(templatePath, "utf8");
  html = html.replace(/{{USER_EMAIL}}/g, cleanEmail);
  html = html.replace(/{{RESET_LINK}}/g, link);

  const transporter = createTransporter();
  const mailOptions = {
    from: '"منظومة تسهيل عقار | Tashil Aqar" <noreply@tashil-proptech-os.firebaseapp.com>',
    replyTo: "support@sw-point.com",
    to: cleanEmail,
    subject: "إعادة تعيين كلمة المرور | Tashil Aqar Password Reset",
    html: html,
  };

  const info = await transporter.sendMail(mailOptions);
  logger.info(`✅ [EmailService] Password reset email sent to ${cleanEmail}`);

  return {
    success: true,
    messageId: info.messageId,
    resetLink: link,
  };
}

module.exports = {
  sendBrandedVerificationEmail,
  sendBrandedPasswordResetEmail,
};
