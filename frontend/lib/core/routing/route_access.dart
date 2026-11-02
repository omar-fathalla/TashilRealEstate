/// Role-aware route policy for Tashil Aqar.
///
/// Visitors may open the marketplace, smart valuation, and the market index.
/// Investor, financial, rent collection, image moderation, lease builder,
/// onboarding, checkout, and payment-schedule routes require a matching role.
///
/// There is no separate investor account in the sign-in gateway. Owners,
/// agencies, and super admins may open `/investor-dashboard` (the same view
/// is embedded in those portals).
class RouteAccess {
  static const Set<String> publicPaths = {
    '/',
    '/login',
    '/valuation',
    '/market-index',
    '/auth/action',
    '/auth/verify',
    '/admin/login',
  };

  static const Map<String, String> roleHomes = {
    'SuperAdmin': '/super-admin',
    'AgencyAdmin': '/agency',
    'Owner': '/owner',
    'Tenant': '/tenant',
    'Investor': '/investor-dashboard',
  };

  static const Map<String, Set<String>> protectedPaths = {
    '/investor-dashboard': {'Owner', 'AgencyAdmin', 'SuperAdmin', 'Investor'},
    '/financial-dashboard': {'Owner', 'AgencyAdmin', 'SuperAdmin'},
    '/rent-collection': {'Owner', 'AgencyAdmin', 'SuperAdmin'},
    '/image-moderation': {'Owner', 'AgencyAdmin', 'SuperAdmin'},
    '/lease-builder': {'Owner', 'AgencyAdmin', 'SuperAdmin'},
    '/fast-onboarding': {'Owner', 'AgencyAdmin', 'SuperAdmin'},
    '/payment-schedule': {'Owner', 'AgencyAdmin', 'SuperAdmin'},
    '/checkout': {'Tenant', 'Owner', 'AgencyAdmin', 'SuperAdmin'},
    '/owner': {'Owner', 'SuperAdmin'},
    '/agency': {'AgencyAdmin', 'SuperAdmin'},
    '/tenant': {'Tenant', 'SuperAdmin'},
    '/super-admin': {'SuperAdmin'},
  };

  static String homeForRole(String? role) => roleHomes[role] ?? '/owner';

  /// Returns a redirect location, or null when navigation may continue.
  ///
  /// When [roleKnown] is false the signed-in profile is still loading.
  /// Protected routes are then allowed through so the screen gate can wait,
  /// instead of guessing the default owner role.
  static String? redirect({
    required bool isLoggedIn,
    required String? role,
    required bool roleKnown,
    required String location,
  }) {
    if (location == '/admin') {
      if (!isLoggedIn) return '/admin/login';
      if (!roleKnown || role == null || role.isEmpty) return null;
      if (role == 'SuperAdmin') return '/super-admin';
      return homeForRole(role);
    }

    if (!protectedPaths.containsKey(location)) return null;

    if (!isLoggedIn) {
      if (location == '/super-admin') return '/admin/login';
      return '/login?redirect=${Uri.encodeComponent(location)}';
    }

    if (!roleKnown || role == null || role.isEmpty) return null;

    final allowed = protectedPaths[location]!;
    if (allowed.contains(role)) return null;
    return homeForRole(role);
  }
}
