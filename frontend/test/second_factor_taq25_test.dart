import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/services/second_factor.dart';
import 'package:tashil_real_estate/features/auth/widgets/second_factor_dialogs.dart';

// TAQ-25: authenticator-app (TOTP) second factor at sign-in and its enrolment.
void main() {
  test('picks the authenticator app enrolment and ignores phone factors', () {
    const phone = PhoneMultiFactorInfo(displayName: null, enrollmentTimestamp: 0, factorId: 'phone', uid: 'p1', phoneNumber: '+10000000000');
    const totp = TotpMultiFactorInfo(enrollmentTimestamp: 0, factorId: 'totp', uid: 't1');
    expect(SecondFactor.totpEnrollmentId([phone, totp]), 't1');
    expect(SecondFactor.totpEnrollmentId([phone]), isNull);
    expect(SecondFactor.totpEnrollmentId(const []), isNull);
  });

  test('accepts six digits, with or without spaces, and nothing else', () {
    expect(SecondFactor.normaliseCode('123456'), '123456');
    expect(SecondFactor.normaliseCode(' 123 456 '), '123456');
    expect(SecondFactor.normaliseCode('12345'), isNull);
    expect(SecondFactor.normaliseCode('12345a'), isNull);
    expect(SecondFactor.normaliseCode('1234567'), isNull);
  });

  test('a sign-in without a second factor passes straight through', () async {
    var asked = false;
    final result = await SecondFactor.signInWithSecondFactor(() async => null, () async {
      asked = true;
      return '123456';
    });
    expect(result, isNull);
    expect(asked, isFalse);
  });

  test('other sign-in errors are not swallowed', () async {
    await expectLater(
      SecondFactor.signInWithSecondFactor(() => Future.error(FirebaseAuthException(code: 'wrong-password')), () async => '123456'),
      throwsA(isA<FirebaseAuthException>().having((e) => e.code, 'code', 'wrong-password')),
    );
  });

  testWidgets('the code dialog returns the typed code and refuses a short one', (tester) async {
    String? result = 'unset';
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await askSecondFactorCode(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mfaCodeField')), '123');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mfaCodeField')), findsOneWidget, reason: 'stays open on a short code');
    await tester.enterText(find.byKey(const Key('mfaCodeField')), '654321');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(result, '654321');
  });
}
