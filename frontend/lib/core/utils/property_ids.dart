import 'dart:math';

import 'package:firebase_core/firebase_core.dart';

const _idAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/// A new property id that nobody can guess ahead of time (TAQ-110): `prop-` plus 20 random
/// characters from a secure generator, the same strength as a Firestore auto-id. Property ids are
/// global, so the first owner to save an id holds it; ids based on the clock could be taken first.
/// Existing properties keep their ids.
String newPropertyId([Random? random]) {
  final rng = random ?? Random.secure();
  final chars = List.generate(20, (_) => _idAlphabet[rng.nextInt(_idAlphabet.length)]);
  return 'prop-${chars.join()}';
}

/// The dictionary key for a failed save of a property. Creating an id that already belongs to
/// another owner is refused by the security rules (`permission-denied`); saving again picks a new id.
String propertySaveErrorKey(Object error, {required bool creating}) {
  if (creating && error is FirebaseException && error.code == 'permission-denied') return 'propIdTakenError';
  return 'propSaveFailedError';
}
