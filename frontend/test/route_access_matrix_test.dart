import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';

/// TAQ-24: role × route matrix. The expectations are written out here on purpose
/// (not read from RouteAccess) so that any change to who can open what is explicit.
const Set<String>? public = null;

const Map<String, Set<String>?> expectedAccess = {
  '/': public,
  '/login': public,
  '/auth-check': public,
  '/valuation': public,
  '/lease-builder': public,
  '/image-moderation': public,
  '/investor-dashboard': public,
  '/market-index': public,
  '/financial-dashboard': public,
  '/super-admin': {'SuperAdmin'},
  '/admin': {'Admin', 'SuperAdmin'},
  '/agency': {'AgencyAdmin', 'AgencyAgent'},
  '/owner': {'Owner'},
  '/tenant': {'Tenant'},
  '/checkout': {'Tenant'},
  '/payment-schedule': {'Owner'},
  '/rent-collection': {'Owner', 'AgencyAdmin'},
  '/fast-onboarding': {'Owner', 'AgencyAdmin'},
};

const Map<String, String> expectedHome = {
  'SuperAdmin': '/super-admin',
  'Admin': '/admin',
  'Investor': '/',
  'AgencyAdmin': '/agency',
  'AgencyAgent': '/agency',
  'Owner': '/owner',
  'Tenant': '/tenant',
  '': '/',
};

const roles = ['SuperAdmin', 'Admin', 'AgencyAdmin', 'AgencyAgent', 'Owner', 'Tenant', 'Investor', ''];

void main() {
  test('the route_access table matches the expected matrix', () {
    expect(RouteAccess.table, expectedAccess);
    for (final role in roles) {
      expect(RouteAccess.homeFor(role), expectedHome[role]);
    }
  });

  test('every router route has an entry in the route_access table', () {
    final router = buildAppRouter(session: RoleSession());
    final paths = router.configuration.routes.whereType<GoRoute>().map((r) => r.path).toSet();
    expect(paths, expectedAccess.keys.toSet());
  });

  group('signed in: role × route', () {
    for (final role in roles) {
      for (final entry in expectedAccess.entries) {
        final route = entry.key;
        if (route == '/auth-check') continue;
        final allowed = entry.value == null || entry.value!.contains(role);
        final label = role.isEmpty ? 'no role' : role;
        test('$label → $route ${allowed ? 'is allowed' : 'goes to ${expectedHome[role]}'}', () {
          final redirect = guardRedirect(Uri.parse(route), RoleSessionStatus.signedIn, role);
          expect(redirect, allowed ? isNull : expectedHome[role]);
        });
      }
    }
  });

  group('signed out', () {
    for (final entry in expectedAccess.entries) {
      final route = entry.key;
      if (route == '/auth-check') continue;
      test('$route ${entry.value == null ? 'is public' : 'requires sign-in'}', () {
        final redirect = guardRedirect(Uri.parse(route), RoleSessionStatus.signedOut, '');
        if (entry.value == null) {
          expect(redirect, isNull);
        } else {
          final target = Uri.parse(redirect!);
          expect(target.path, '/login');
          expect(target.queryParameters['redirect'], route);
        }
      });
    }
  });

  group('while the role is loading', () {
    for (final entry in expectedAccess.entries) {
      final route = entry.key;
      if (route == '/auth-check') continue;
      test('$route ${entry.value == null ? 'opens immediately' : 'waits on /auth-check'}', () {
        final redirect = guardRedirect(Uri.parse(route), RoleSessionStatus.loading, '');
        if (entry.value == null) {
          expect(redirect, isNull);
        } else {
          final target = Uri.parse(redirect!);
          expect(target.path, '/auth-check');
          expect(target.queryParameters['from'], route);
        }
      });
    }
  });

  group('reported bypasses', () {
    test('a Tenant cannot open the SuperAdmin, agency, or owner portals', () {
      expect(guardRedirect(Uri.parse('/super-admin'), RoleSessionStatus.signedIn, 'Tenant'), '/tenant');
      expect(guardRedirect(Uri.parse('/agency'), RoleSessionStatus.signedIn, 'Tenant'), '/tenant');
      expect(guardRedirect(Uri.parse('/owner'), RoleSessionStatus.signedIn, 'Tenant'), '/tenant');
    });

    test('an Owner cannot open the SuperAdmin, agency, or tenant portals', () {
      expect(guardRedirect(Uri.parse('/super-admin'), RoleSessionStatus.signedIn, 'Owner'), '/owner');
      expect(guardRedirect(Uri.parse('/agency'), RoleSessionStatus.signedIn, 'Owner'), '/owner');
      expect(guardRedirect(Uri.parse('/tenant'), RoleSessionStatus.signedIn, 'Owner'), '/owner');
    });

    test('a trailing slash or query string does not skip the guard', () {
      expect(guardRedirect(Uri.parse('/super-admin/'), RoleSessionStatus.signedIn, 'Owner'), '/owner');
      expect(guardRedirect(Uri.parse('/super-admin?tab=users'), RoleSessionStatus.signedIn, 'Tenant'), '/tenant');
    });
  });

  group('TAQ-91: Admin and Investor', () {
    test('an Admin opens /admin but not the SuperAdmin portal or any owner, tenant or agency route', () {
      expect(guardRedirect(Uri.parse('/admin'), RoleSessionStatus.signedIn, 'Admin'), isNull);
      for (final route in ['/super-admin', '/owner', '/tenant', '/agency', '/checkout', '/payment-schedule', '/rent-collection']) {
        expect(guardRedirect(Uri.parse(route), RoleSessionStatus.signedIn, 'Admin'), '/admin', reason: route);
      }
    });

    test('a SuperAdmin may open /admin, and every other role is sent home from it', () {
      expect(guardRedirect(Uri.parse('/admin'), RoleSessionStatus.signedIn, 'SuperAdmin'), isNull);
      expect(guardRedirect(Uri.parse('/admin'), RoleSessionStatus.signedIn, 'Investor'), '/');
      expect(guardRedirect(Uri.parse('/admin'), RoleSessionStatus.signedIn, 'Owner'), '/owner');
      expect(guardRedirect(Uri.parse('/admin/'), RoleSessionStatus.signedIn, 'Tenant'), '/tenant');
      expect(guardRedirect(Uri.parse('/admin?tab=users'), RoleSessionStatus.signedIn, 'AgencyAdmin'), '/agency');
    });

    test('an Investor reaches public pages and nothing role-gated', () {
      for (final route in ['/', '/market-index', '/valuation', '/investor-dashboard']) {
        expect(guardRedirect(Uri.parse(route), RoleSessionStatus.signedIn, 'Investor'), isNull, reason: route);
      }
      for (final route in ['/owner', '/tenant', '/agency', '/super-admin', '/admin', '/fast-onboarding', '/rent-collection']) {
        expect(guardRedirect(Uri.parse(route), RoleSessionStatus.signedIn, 'Investor'), '/', reason: route);
      }
    });

    test('post-login redirect never lets Admin or Investor into a portal they lack', () {
      expect(postLoginDestination(role: 'Admin', redirect: '/super-admin'), '/admin');
      expect(postLoginDestination(role: 'Admin', redirect: '/admin'), '/admin');
      expect(postLoginDestination(role: 'Investor', redirect: '/admin'), '/');
      expect(postLoginDestination(role: 'Investor', redirect: '/market-index'), '/market-index');
      expect(postLoginDestination(role: 'Investor', hasDraft: true), '/');
    });
  });

  group('/auth-check', () {
    Uri check(String from) => Uri(path: '/auth-check', queryParameters: {'from': from});

    test('stays while loading', () {
      expect(guardRedirect(check('/owner'), RoleSessionStatus.loading, ''), isNull);
    });

    test('continues to the original route once the role allows it', () {
      expect(guardRedirect(check('/owner'), RoleSessionStatus.signedIn, 'Owner'), '/owner');
      expect(guardRedirect(check('/checkout?lease=1'), RoleSessionStatus.signedIn, 'Tenant'), '/checkout?lease=1');
    });

    test('sends a wrong role home and a signed-out user to login', () {
      expect(guardRedirect(check('/owner'), RoleSessionStatus.signedIn, 'Tenant'), '/tenant');
      expect(Uri.parse(guardRedirect(check('/owner'), RoleSessionStatus.signedOut, '')!).path, '/login');
    });

    test('never follows an external or looping target', () {
      expect(guardRedirect(check('https://evil.example.com/owner'), RoleSessionStatus.signedIn, 'Owner'), '/');
      expect(guardRedirect(check('//evil.example.com/owner'), RoleSessionStatus.signedIn, 'Owner'), '/');
      expect(guardRedirect(check('/auth-check'), RoleSessionStatus.signedIn, 'Owner'), '/');
    });
  });

  group('post-login destination', () {
    test('honours a redirect only when the role may open it', () {
      expect(postLoginDestination(role: 'Owner', redirect: '/fast-onboarding'), '/fast-onboarding');
      expect(postLoginDestination(role: 'Tenant', redirect: '/fast-onboarding'), '/tenant');
      expect(postLoginDestination(role: 'Tenant', redirect: '/super-admin'), '/tenant');
      expect(postLoginDestination(role: 'Tenant', redirect: '/checkout'), '/checkout');
      expect(postLoginDestination(role: 'AgencyAdmin', redirect: '/rent-collection'), '/rent-collection');
    });

    test('ignores external, unknown, and auth redirects', () {
      expect(postLoginDestination(role: 'Owner', redirect: 'https://evil.example.com/owner'), '/owner');
      expect(postLoginDestination(role: 'Owner', redirect: '//evil.example.com/owner'), '/owner');
      expect(postLoginDestination(role: 'Owner', redirect: '/nowhere'), '/owner');
      expect(postLoginDestination(role: 'Owner', redirect: '/login'), '/owner');
    });

    test('a pending draft resumes only for roles that can list properties', () {
      expect(postLoginDestination(role: 'Owner', hasDraft: true), '/fast-onboarding');
      expect(postLoginDestination(role: 'Tenant', hasDraft: true), '/tenant');
    });

    test('without a trusted role the user lands on the public page', () {
      expect(postLoginDestination(role: '', redirect: '/owner'), '/');
      expect(postLoginDestination(role: ''), '/');
    });
  });
}
