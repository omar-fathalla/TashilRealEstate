import 'package:tashil_real_estate/core/auth/trusted_role.dart';

/// The single source of truth for which roles may open which route.
///
/// A `null` entry is public. Every other route requires sign-in and one of the
/// listed trusted roles (see [TrustedRole]). The router redirect and [RoleGate]
/// both read this table; Firestore rules and Cloud Functions remain the real
/// enforcement for the data behind each screen.
class RouteAccess {
  RouteAccess._();

  static const String authCheck = '/auth-check';
  static const String login = '/login';

  static const Map<String, Set<String>?> table = {
    '/': null,
    login: null,
    authCheck: null,
    '/valuation': null,
    '/lease-builder': null,
    '/image-moderation': null,
    '/investor-dashboard': null,
    '/market-index': null,
    '/financial-dashboard': null,
    '/super-admin': {TrustedRole.superAdmin},
    '/agency': {TrustedRole.agencyAdmin},
    '/owner': {TrustedRole.owner},
    '/tenant': {TrustedRole.tenant},
    '/checkout': {TrustedRole.tenant},
    '/payment-schedule': {TrustedRole.owner},
    '/rent-collection': {TrustedRole.owner, TrustedRole.agencyAdmin},
    '/fast-onboarding': {TrustedRole.owner, TrustedRole.agencyAdmin},
  };

  /// Roles allowed on [path], or null when the route is public (or unknown, in which
  /// case go_router shows its not-found page).
  static Set<String>? allowedRoles(String path) => table[_normalize(path)];

  static bool isProtected(String path) => allowedRoles(path) != null;

  static bool canAccess(String path, String role) {
    final allowed = allowedRoles(path);
    return allowed == null || allowed.contains(role);
  }

  /// Where a signed-in user with [role] belongs. Always accessible for that role.
  static String homeFor(String role) {
    switch (role) {
      case TrustedRole.superAdmin:
        return '/super-admin';
      case TrustedRole.agencyAdmin:
        return '/agency';
      case TrustedRole.owner:
        return '/owner';
      case TrustedRole.tenant:
        return '/tenant';
      default:
        return '/';
    }
  }

  static String _normalize(String path) {
    if (path.length > 1 && path.endsWith('/')) return path.substring(0, path.length - 1);
    return path.isEmpty ? '/' : path;
  }
}
