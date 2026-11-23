import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Centralized Enterprise Firebase App Check Service for Tashil Real Estate.
/// Protects Firestore, Cloud Storage, and Cloud Functions from scraping, abuse, and billing fraud.
class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();
  factory AppCheckService() => _instance;
  AppCheckService._internal();

  /// reCAPTCHA v3 site key registered for the web app in Firebase App Check, supplied at
  /// build time with `--dart-define=RECAPTCHA_SITE_KEY=...` (see docs/SECURITY_SETUP.md).
  static const String webSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

  /// Release web builds without a site key skip App Check instead of attesting with an
  /// invalid key; the server keeps enforcement off (ENFORCE_APP_CHECK) until a key ships.
  static bool shouldActivateOnWeb({required bool debug, required String siteKey}) =>
      debug || siteKey.trim().isNotEmpty;

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
        // Web Provider: Debug in dev, ReCaptcha V3 in release
        providerWeb: kDebugMode
            ? WebDebugProvider()
            : ReCaptchaV3Provider(webSiteKey.trim()),
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
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
