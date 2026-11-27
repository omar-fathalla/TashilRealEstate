// TAQ-178: a failed Google or Apple sign-in must never sign the user into a made-up account.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider sign-in has no mock-account fallback', () {
    final src = File('lib/core/services/firebase_auth_service.dart').readAsStringSync();
    expect(src, isNot(contains('mockEmail')));
    expect(src, isNot(contains('google.user.')));
    expect(src, isNot(contains('apple.user.')));
    expect(RegExp(r"AuthPass\d").hasMatch(src), isFalse, reason: 'no shared passwords in the client');
    for (final provider in ['Google', 'Apple']) {
      final start = src.indexOf('Future<UserCredential?> signInWith$provider(');
      expect(start, greaterThanOrEqualTo(0));
      final end = src.indexOf('\n  }\n', start);
      final body = src.substring(start, end);
      expect(body, isNot(contains('signInWithEmailAndPassword')), reason: provider);
      expect(body, contains('rethrow;'), reason: '$provider errors reach the screen');
    }
  });

  test('no lib file signs in with a hard-coded password', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (RegExp(r"signInWithEmailAndPassword\([^,)]*,\s*'[^']+'\)").hasMatch(f.readAsStringSync())) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
