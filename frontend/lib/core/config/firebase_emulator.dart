import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  static Future<void> connect() async {
    if (!enabled) return;
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
}
