import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';

/// Blocks a protected screen until the signed-in role is known, then
/// redirects when the role is not allowed.
class RoleGate extends StatelessWidget {
  final Set<String> allowedRoles;
  final Widget child;

  /// Test hooks. Production reads Firebase Auth and [UserProfileService].
  final bool Function()? isLoggedIn;
  final String? Function()? currentRole;
  final bool Function()? isRoleKnown;

  const RoleGate({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.isLoggedIn,
    this.currentRole,
    this.isRoleKnown,
  });

  bool _loggedIn() {
    if (isLoggedIn != null) return isLoggedIn!();
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn != null || currentRole != null || isRoleKnown != null) {
      return _decide(
        context,
        loggedIn: _loggedIn(),
        role: currentRole?.call(),
        known: isRoleKnown?.call() ?? true,
      );
    }

    return ValueListenableBuilder<UserProfileData>(
      valueListenable: UserProfileService().profileNotifier,
      builder: (context, profile, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: UserProfileService().roleConfirmed,
          builder: (context, confirmed, _) {
            final user = _currentUser();
            final matches = user != null && profile.uid == user.uid;
            return _decide(
              context,
              loggedIn: user != null,
              role: matches ? profile.role : null,
              known: user != null && confirmed && matches,
            );
          },
        );
      },
    );
  }

  User? _currentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Widget _decide(
    BuildContext context, {
    required bool loggedIn,
    required String? role,
    required bool known,
  }) {
    if (!loggedIn) {
      return const _Go('/login');
    }
    if (!known || role == null || role.isEmpty) {
      return const Scaffold(
        body: Center(child: TashilLoadingIndicator.medium()),
      );
    }
    if (!allowedRoles.contains(role)) {
      return _Go(RouteAccess.homeForRole(role));
    }
    return child;
  }
}

class _Go extends StatefulWidget {
  final String location;
  const _Go(this.location);

  @override
  State<_Go> createState() => _GoState();
}

class _GoState extends State<_Go> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = GoRouterState.of(context).uri.path;
      if (current == widget.location) return;
      context.go(widget.location);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: TashilLoadingIndicator.medium()),
    );
  }
}
