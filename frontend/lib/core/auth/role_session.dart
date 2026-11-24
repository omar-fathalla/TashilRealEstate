import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/auth/trusted_role.dart';

enum RoleSessionStatus { loading, signedOut, signedIn }

/// The signed-in user's trusted role (custom claim first, see [TrustedRole]),
/// kept current across sign-in, sign-out, and ID-token refreshes. The router
/// listens to it so guards re-run as soon as the role is known.
class RoleSession extends ChangeNotifier {
  RoleSession();

  static final RoleSession instance = RoleSession();

  RoleSessionStatus _status = RoleSessionStatus.loading;
  String _role = '';
  String? _uid;
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _subscription;
  int _generation = 0;

  RoleSessionStatus get status => _status;

  /// One of [TrustedRole.all], or '' when signed out, still loading, or without a role.
  String get role => _role;

  bool get isResolved => _status != RoleSessionStatus.loading;

  /// Follows Firebase Auth. Custom claims arrive with the ID token, so token
  /// changes (not just sign-in changes) trigger a new resolution.
  void bindToFirebaseAuth([FirebaseAuth? auth]) {
    _auth = auth ?? FirebaseAuth.instance;
    _subscription?.cancel();
    _subscription = _auth!.idTokenChanges().listen(_resolve);
  }

  /// Re-reads the role, e.g. after login wrote the self-service role to the profile.
  Future<void> refresh() async {
    final auth = _auth;
    if (auth == null) return;
    await _resolve(auth.currentUser);
  }

  Future<void> _resolve(User? user) async {
    final generation = ++_generation;
    if (user == null) {
      _uid = null;
      _update(RoleSessionStatus.signedOut, '');
      return;
    }
    if (_uid != user.uid) _update(RoleSessionStatus.loading, '');

    String role;
    try {
      role = await TrustedRole.resolve(user);
    } catch (e) {
      debugPrint('RoleSession: could not resolve role: $e');
      role = '';
    }
    if (generation != _generation) return;
    _uid = user.uid;
    _update(RoleSessionStatus.signedIn, role);
  }

  void _update(RoleSessionStatus status, String role) {
    if (_status == status && _role == role) return;
    _status = status;
    _role = role;
    notifyListeners();
  }

  @visibleForTesting
  void debugSet(RoleSessionStatus status, [String role = '']) {
    _generation++;
    _update(status, status == RoleSessionStatus.signedIn ? TrustedRole.fromSources(claimRole: role) : '');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
