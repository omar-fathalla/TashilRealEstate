import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tashil_real_estate/core/config/firebase_emulator_prepare_stub.dart'
    if (dart.library.js_interop) 'package:tashil_real_estate/core/config/firebase_emulator_prepare_web.dart';

/// Points Auth, Firestore, and Storage at the local emulators.
///
/// Production builds leave this off. Screenshot and local runs pass
/// `--dart-define=USE_FIREBASE_EMULATOR=true`.
class FirebaseEmulatorConfig {
  FirebaseEmulatorConfig._();

  static const bool enabled = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );

  static const String host = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int storagePort = 9199;

  /// Loopback only. Production hosts such as identitytoolkit.googleapis.com fail.
  static bool isLoopbackHost(String host) {
    final normalized = host.trim().toLowerCase();
    if (normalized == 'localhost' || normalized == '::1') return true;
    return normalized.startsWith('127.');
  }

  /// `http://127.0.0.1:9099`. Throws when [host] is not loopback.
  static String authOriginFor(String host, {int port = authPort}) {
    if (!isLoopbackHost(host)) {
      throw StateError(
        'Firebase emulator host must be loopback. Refusing "$host".',
      );
    }
    return 'http://$host:$port';
  }

  /// Call before [Firebase.initializeApp] so web Auth session restore
  /// cannot reach a non-local host.
  static Future<void> prepareBeforeInitializeApp() async {
    if (!enabled) return;
    await prepareAuthEmulatorBeforeInit(authOriginFor(host));
  }

  /// Call immediately after [Firebase.initializeApp] and before any
  /// `authStateChanges` listener in application code.
  static Future<void> connect() async {
    if (!enabled) return;
    authOriginFor(host);
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    await FirebaseStorage.instance.useStorageEmulator(host, storagePort);
  }
}
