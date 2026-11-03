# Production runbook

These steps change the live project `tashil-proptech-os`. Do not run them until Mohamed approves each one. Nothing in this repository deploy was executed while the engineering-audit fixes were written.

The code changes (rules, functions, hosting headers, Android id) take effect only after the commands below.

## F-00 and F-03: public seed function

The repo no longer exports `seedDatabase`. The copy already deployed is still public until it is deleted. Do not delete or edit the test accounts until Mohamed reviews them.

```bash
gcloud functions delete seedDatabase --region=us-central1 --project=tashil-proptech-os
gcloud functions delete syncMarketIndexManual --region=us-central1 --project=tashil-proptech-os
```

After the new functions are deployed, `syncMarketIndexManual` is an admin callable, not a public HTTP endpoint. The old HTTP service must be deleted first so the name is not left public.

Review, do not blindly delete:

- Auth users `agency@test.com`, `owner@test.com`, `tenant@test.com`
- Their `Users/{uid}` documents
- `MarketIndices/EG` if it was rewritten during the audit

## F-02: rotate the Gemini key

The hardcoded key was removed from the client. Mohamed rotates it. History purge is out of scope.

1. Revoke the leaked key in Google AI Studio / GCP credentials.
2. Create a new key and store it:

```bash
gcloud services enable secretmanager.googleapis.com --project=tashil-proptech-os
printf '%s' 'NEW_KEY' | gcloud secrets create GEMINI_API_KEY --data-file=- --project=tashil-proptech-os
# If the secret already exists:
printf '%s' 'NEW_KEY' | gcloud secrets versions add GEMINI_API_KEY --data-file=- --project=tashil-proptech-os
```

3. Grant the functions runtime service account `roles/secretmanager.secretAccessor` on that secret.
4. Deploy functions only after that binding exists. `geminiGenerateContent` reads `defineSecret('GEMINI_API_KEY')`.

## F-08: backups and delete protection

```bash
gcloud firestore databases update --project=tashil-proptech-os --database='(default)' --enable-pitr --delete-protection
gcloud firestore backups schedules create --project=tashil-proptech-os --database='(default)' --recurrence=daily --retention=14d
gcloud storage buckets update gs://tashil-proptech-os.appspot.com --soft-delete-duration=7d --versioning
```

PITR and backup schedules add cost.

## F-10 and F-14: App Check, MFA, SMS, localhost

Register a reCAPTCHA Enterprise site key for `tashilaqar.com` and pass it at build time:

```bash
flutter build web --dart-define=RECAPTCHA_SITE_KEY=THE_SITE_KEY
```

The app no longer ships a placeholder key. Functions are marked `enforceAppCheck: true`, so do not deploy them until App Check can issue tokens.

```bash
# Identity Platform / Auth settings are console or Identity Toolkit admin API.
# Enable TOTP MFA for admins, a password policy, and reCAPTCHA Enterprise SMS defense.
# Remove localhost from authorized domains on the production project.
# Drop US and GB from the SMS allowlist unless a product reason remains.
```

## F-12 and F-19: region

Firestore location cannot be changed after the database is created. `nam5` stays until a new project is created in `me-central1` or `me-central2` and data is migrated. Functions in this repo still declare `us-central1` because moving them is a new deploy, not a code-only switch of the existing services.

```bash
gcloud firestore databases create --project=NEW_PROJECT --location=me-central2 --database='(default)'
```

Set a billing budget alert in the Cloud console. That API was not available to this change.

The app now asks for consent before voice, photo, and document-image AI calls, and JPEG uploads drop the EXIF segment before they leave the device. The callable still uses the Gemini Developer API. Moving that call to Vertex AI in `me-central2` is a project decision, not a client change. A privacy policy and a record of processing activities need legal review.

A second Firebase project is not created here. When Mohamed wants a dev project:

```bash
firebase projects:create tashil-dev --display-name "Tashil Dev"
firebase use --add tashil-dev
```

Identity Platform must be enabled before a `beforeUserCreated` blocking function can set the default `Tenant` claim. Do not deploy that function until the product is enabled. MFA, the SMS allowlist, and removing `localhost` stay in the Auth console.

## F-15: Android app registration

The Gradle application id is now `ae.tashilaqar.app`. Register that Android app in the Firebase console and download a matching `google-services.json` before shipping a store build. Release signing reads an untracked `frontend/android/key.properties`. No keystore is committed. Play App Signing stays in the Play Console.

## F-16 and F-17: hosting headers and email DNS

Hosting headers are in `firebase.json`. They apply on the next hosting deploy:

```bash
firebase deploy --only hosting --project=tashil-proptech-os
```

DNS is at GoDaddy, not in this repo. After a mail provider is chosen:

```text
CAA 0 issue "pki.goog"
MX  as the provider specifies
TXT v=spf1 include:PROVIDER -all
TXT the provider DKIM records
TXT _dmarc.tashilaqar.com v=DMARC1; p=quarantine; rua=mailto:ADDRESS_YOU_OWN
```

Put SMTP host, user, and password in Secret Manager, not in the function source. `email_service.js` already reads `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, and `SMTP_PASS`.

## F-22: API key restrictions

Restrict the browser key to `https://tashilaqar.com/*`, `https://*.web.app/*`, and `https://*.firebaseapp.com/*`, and to the Firebase APIs actually used. Restrict the Android key by package `ae.tashilaqar.app` and the release SHA-1. Restrict the iOS key by bundle id `com.tashil.realestate`.

## Deploy order, when approved

1. Secret Manager key and App Check site key.
2. Delete the old public `seedDatabase` and HTTP `syncMarketIndexManual`.
3. `firebase deploy --only firestore:rules,storage,functions,hosting --project=tashil-proptech-os`
4. Call `setUserRole` once for each real admin so the custom claim matches `Users/{uid}.role`.
5. Enable PITR and the backup schedule.
