import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/services/callable_error.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';

/// True when a callable refused the caller's ID token as revoked or stale (TAQ-158 on the server:
/// `unauthenticated` with `details.reason == 'token_revoked'`). That happens after a role change,
/// a demotion, or when the account was disabled or deleted.
bool isTokenRevoked(Object error) => describeCallableError(error).reason == 'token_revoked';

/// Handles `token_revoked` for every callable: it refreshes the ID token once and repeats the
/// call. The server refuses a revoked token before it acts, so repeating the call is safe. If the
/// refresh fails (the session really is revoked, or the account is disabled or deleted) or the
/// repeat is refused again, it signs out, and the router sends the user to the sign-in page.
/// The original error is still thrown to the caller in that case.
class SessionGuard {
  SessionGuard({Future<void> Function()? refreshToken, Future<void> Function()? signOut})
      : _refreshToken = refreshToken ?? _firebaseRefresh,
        _signOut = signOut ?? _firebaseSignOut;

  static SessionGuard instance = SessionGuard();

  final Future<void> Function() _refreshToken;
  final Future<void> Function() _signOut;

  static Future<void> _firebaseRefresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('signed out');
    await user.getIdToken(true);
  }

  static Future<void> _firebaseSignOut() => FirebaseAuthService().signOut();

  Future<void> _signOutQuietly() async {
    try {
      await _signOut();
    } catch (_) {}
  }

  Future<T> run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error, stack) {
      if (!isTokenRevoked(error)) rethrow;
      try {
        await _refreshToken();
      } catch (_) {
        await _signOutQuietly();
        Error.throwWithStackTrace(error, stack);
      }
      try {
        return await call();
      } catch (again) {
        if (isTokenRevoked(again)) await _signOutQuietly();
        rethrow;
      }
    }
  }
}
