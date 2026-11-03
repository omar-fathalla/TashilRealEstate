/// VM / mobile stub. Auth emulator connection is `useAuthEmulator` after
/// `Firebase.initializeApp`, which on those platforms runs before session use.
Future<void> prepareAuthEmulatorBeforeInit(String origin) async {}
