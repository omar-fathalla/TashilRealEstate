import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase options for the Tashil Aqar dev project (`tashil-aqar-dev`), used by builds made
/// with `--dart-define=FIREBASE_ENV=dev` (see [AppFirebaseOptions]).
///
/// Web only for now: there is no Android or iOS app registered in the dev project, so other
/// platforms fail with an [UnsupportedError] instead of silently using prod.
///
/// The web API key is a public Firebase browser key restricted to dev referrers. It is not
/// kept in the repo; pass it at build time:
///
/// ```bash
/// flutter build web --dart-define=FIREBASE_ENV=dev --dart-define=DEV_FIREBASE_WEB_API_KEY=KEY
/// ```
class DevFirebaseOptions {
  DevFirebaseOptions._();

  static const String webApiKeyDefine = 'DEV_FIREBASE_WEB_API_KEY';
  static const String _webApiKey = String.fromEnvironment(webApiKeyDefine);

  static FirebaseOptions get currentPlatform => forPlatform(isWeb: kIsWeb, webApiKey: _webApiKey);

  static FirebaseOptions forPlatform({required bool isWeb, required String webApiKey}) {
    if (!isWeb) {
      throw UnsupportedError(
        'FIREBASE_ENV=dev is configured for web only. Register an Android or iOS app in '
        'tashil-aqar-dev and add its options to firebase_options_dev.dart first.',
      );
    }
    final key = webApiKey.trim();
    if (key.isEmpty) {
      throw StateError(
        'FIREBASE_ENV=dev needs the dev web API key. Build with '
        '--dart-define=$webApiKeyDefine=<key> (see docs/DEV_ENVIRONMENT.md).',
      );
    }
    return web(key);
  }

  static FirebaseOptions web(String apiKey) => FirebaseOptions(
        apiKey: apiKey,
        appId: '1:169661829655:web:0251892e514a30e54c4252',
        messagingSenderId: '169661829655',
        projectId: 'tashil-aqar-dev',
        authDomain: 'tashil-aqar-dev.firebaseapp.com',
        storageBucket: 'tashil-aqar-dev.firebasestorage.app',
      );
}
