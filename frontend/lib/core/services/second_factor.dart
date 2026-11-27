import 'package:firebase_auth/firebase_auth.dart';

/// TAQ-25: sign-in with an authenticator app (TOTP) as the second step.
///
/// The backend only demands a second factor from a SuperAdmin whose account carries the
/// `mfa_required` claim (set by `role_claims.js --require-mfa`, off by default). Any account that
/// has enrolled a factor is still asked for it at sign-in, because Firebase Auth does that itself.
class SecondFactor {
  SecondFactor._();

  static const String totpFactorId = 'totp';

  /// The enrolment id of the account's authenticator app, or null when it has none.
  static String? totpEnrollmentId(List<MultiFactorInfo> hints) {
    for (final hint in hints) {
      if (hint.factorId == totpFactorId) return hint.uid;
    }
    return null;
  }

  /// Six digits, ignoring spaces the user may type between groups.
  static String? normaliseCode(String raw) {
    final code = raw.replaceAll(RegExp(r'\s'), '');
    return RegExp(r'^\d{6}$').hasMatch(code) ? code : null;
  }

  /// Runs [signIn]; if Firebase asks for a second factor, asks the user for the code with
  /// [askCode] and completes the sign-in. A null code (the user cancelled) rethrows the
  /// original error, so the caller shows its usual failure message.
  static Future<UserCredential?> signInWithSecondFactor(
    Future<UserCredential?> Function() signIn,
    Future<String?> Function() askCode,
  ) async {
    try {
      return await signIn();
    } on FirebaseAuthMultiFactorException catch (e) {
      final enrollmentId = totpEnrollmentId(e.resolver.hints);
      if (enrollmentId == null) rethrow;
      final code = await askCode();
      if (code == null) rethrow;
      final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(enrollmentId, code);
      return e.resolver.resolveSignIn(assertion);
    }
  }
}
