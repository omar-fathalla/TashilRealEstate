import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Centralized Enterprise Firebase App Check Service for Tashil Real Estate.
/// Protects Firestore, Cloud Storage, and Cloud Functions from scraping, abuse, and billing fraud.
class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();
  factory AppCheckService() => _instance;
  AppCheckService._internal();

  /// reCAPTCHA Enterprise site key registered for the web app in Firebase App Check, supplied at
  /// build time with `--dart-define=RECAPTCHA_SITE_KEY=...` (see docs/SECURITY_SETUP.md).
  /// The key is public by design, but it lives in build config, not in this repository.
  static const String webSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

  /// Release web builds without a site key skip App Check instead of attesting with an
  /// invalid key; the server keeps enforcement off (ENFORCE_APP_CHECK) until a key ships.
  static bool shouldActivateOnWeb({required bool debug, required String siteKey}) =>
      debug || siteKey.trim().isNotEmpty;

  /// Web: reCAPTCHA Enterprise in release builds (the Firebase key is an Enterprise key, which a
  /// v3 provider cannot attest with); the debug provider in debug builds.
  static WebProvider webProvider({required bool debug, required String siteKey}) =>
      debug ? WebDebugProvider() : ReCaptchaEnterpriseProvider(siteKey.trim());

  /// Android: Play Integrity in release builds. It only verifies once the app is published as
  /// ae.tashilaqar.app with a real release signing key (see docs/SECURITY_SETUP.md).
  static AndroidAppCheckProvider androidProvider({required bool debug}) =>
      debug ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider();

  /// iOS: App Attest, falling back to DeviceCheck on devices without App Attest. DeviceCheck is
  /// not registered in the Firebase console, so those devices stay unverified for now.
  static AppleAppCheckProvider appleProvider({required bool debug}) => debug
      ? const AppleDebugProvider()
      : const AppleAppAttestWithDeviceCheckFallbackProvider();

  bool _isActivated = false;

  /// Initializes and activates App Check with appropriate providers per environment
  Future<void> initialize() async {
    if (_isActivated) return;

    if (kIsWeb && !shouldActivateOnWeb(debug: kDebugMode, siteKey: webSiteKey)) {
      debugPrint('ℹ️ App Check not activated on web: no RECAPTCHA_SITE_KEY was provided.');
      _isActivated = true;
      return;
    }

    try {
      await FirebaseAppCheck.instance.activate(
        providerWeb: webProvider(debug: kDebugMode, siteKey: webSiteKey),
        providerAndroid: androidProvider(debug: kDebugMode),
        providerApple: appleProvider(debug: kDebugMode),
      );

      _isActivated = true;
      debugPrint('🛡️ Firebase App Check activated successfully.');
    } catch (e) {
      debugPrint('ℹ️ App Check initialization note (graceful bypass in local dev): $e');
      _isActivated = true;
    }
  }

  /// Sets token auto refresh
  Future<void> setTokenAutoRefreshEnabled(bool enabled) async {
    try {
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(enabled);
    } catch (e) {
      debugPrint('Error setting App Check token auto refresh: $e');
    }
  }

  /// Gets current App Check attestation token or null in debug/offline
  Future<String?> getToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return token;
    } catch (e) {
      debugPrint('Error getting App Check token: $e');
      return null;
    }
  }
}
