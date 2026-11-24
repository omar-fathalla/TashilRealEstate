import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:tashil_real_estate/firebase_options.dart';
import 'package:tashil_real_estate/firebase_options_dev.dart';

/// Picks the Firebase project at build time with `--dart-define=FIREBASE_ENV=prod|dev`.
/// Without the define the build uses prod, exactly as before, so existing build commands and
/// the generated `firebase_options.dart` are unchanged. Any other value is a typo and fails.
class AppFirebaseOptions {
  AppFirebaseOptions._();

  static const String environment = String.fromEnvironment('FIREBASE_ENV', defaultValue: 'prod');

  static FirebaseOptions get currentPlatform => forEnvironment(environment);

  static FirebaseOptions forEnvironment(String env, {FirebaseOptions Function()? devOptions}) {
    switch (env) {
      case 'prod':
        return DefaultFirebaseOptions.currentPlatform;
      case 'dev':
        return (devOptions ?? () => DevFirebaseOptions.currentPlatform)();
      default:
        throw ArgumentError.value(env, 'FIREBASE_ENV', 'must be "prod" or "dev"');
    }
  }
}
