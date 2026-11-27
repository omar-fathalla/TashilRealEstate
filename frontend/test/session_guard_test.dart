// TAQ-173: callables refused with token_revoked refresh the token once, else sign out.
// TAQ-172: the first profile write never makes a name up from the email.
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';
import 'package:tashil_real_estate/core/services/session_guard.dart';

FirebaseFunctionsException _revoked() => FirebaseFunctionsException(
    code: 'unauthenticated', message: 'Your session has expired.', details: {'reason': 'token_revoked'});

void main() {
  group('SessionGuard', () {
    late int refreshes;
    late int signOuts;
    late bool refreshFails;
    late SessionGuard guard;

    setUp(() {
      refreshes = 0;
      signOuts = 0;
      refreshFails = false;
      guard = SessionGuard(
        refreshToken: () async {
          refreshes++;
          if (refreshFails) throw StateError('refresh token revoked');
        },
        signOut: () async => signOuts++,
      );
    });

    test('passes results and other errors straight through', () async {
      expect(await guard.run(() async => 7), 7);
      final other = FirebaseFunctionsException(code: 'failed-precondition', message: 'x', details: {'reason': 'lease_not_active'});
      await expectLater(guard.run<int>(() async => throw other), throwsA(same(other)));
      expect(refreshes, 0);
      expect(signOuts, 0);
    });

    test('a revoked token is refreshed and the call repeated once', () async {
      var calls = 0;
      final result = await guard.run(() async {
        calls++;
        if (calls == 1) throw _revoked();
        return 'ok';
      });
      expect(result, 'ok');
      expect(calls, 2);
      expect(refreshes, 1);
      expect(signOuts, 0);
    });

    test('when the refresh fails it signs out and rethrows the refusal', () async {
      refreshFails = true;
      var calls = 0;
      await expectLater(
        guard.run<void>(() async {
          calls++;
          throw _revoked();
        }),
        throwsA(isA<FirebaseFunctionsException>().having((e) => e.details['reason'], 'reason', 'token_revoked')),
      );
      expect(calls, 1);
      expect(signOuts, 1);
    });

    test('a second refusal after a refresh signs out', () async {
      var calls = 0;
      await expectLater(guard.run<void>(() async {
        calls++;
        throw _revoked();
      }), throwsA(isA<FirebaseFunctionsException>()));
      expect(calls, 2);
      expect(refreshes, 1);
      expect(signOuts, 1);
    });

    test('isTokenRevoked reads details.reason only', () {
      expect(isTokenRevoked(_revoked()), isTrue);
      expect(isTokenRevoked(FirebaseFunctionsException(code: 'unauthenticated', message: 'Sign in is required.')), isFalse);
      expect(isTokenRevoked(StateError('x')), isFalse);
    });
  });

  group('userRoleProfile', () {
    test('keeps the typed name and never derives one from the email', () {
      final typed = FirestoreService.userRoleProfile(uid: 'u', email: 'sara.ali@example.com', role: 'Tenant', fullName: '  Sara Ali ');
      expect(typed['full_name'], 'Sara Ali');
      for (final name in [null, '', '   ']) {
        final none = FirestoreService.userRoleProfile(uid: 'u', email: 'sara.ali@example.com', role: 'Tenant', fullName: name);
        expect(none.containsKey('full_name'), isFalse, reason: '$name');
        expect(none.values, isNot(contains('sara.ali')));
      }
      expect(FirestoreService.userRoleProfile(uid: 'u', email: 'e', role: 'Owner', photoUrl: ' ').containsKey('photo_url'), isFalse);
    });
  });

  test('every callable in lib/ goes through the session guard', () {
    // A callable called directly would show a plain failure on token_revoked instead of
    // refreshing or signing out.
    final direct = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final src = file.readAsStringSync();
      for (final m in RegExp(r'^.*\.call<[^\n]*$', multiLine: true).allMatches(src)) {
        if (!m.group(0)!.contains('SessionGuard.instance.run(')) direct.add('${file.path}: ${m.group(0)!.trim()}');
      }
    }
    expect(direct, isEmpty);
  });
}
