import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';

void main() {
  group('RouteAccess', () {
    test('keeps marketplace, valuation, market index, and auth links public', () {
      for (final path in ['/', '/login', '/valuation', '/market-index', '/auth/action', '/auth/verify', '/admin/login']) {
        expect(
          RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: path),
          isNull,
          reason: path,
        );
      }
    });

    test('sends signed-out visitors away from protected portals', () {
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/investor-dashboard'),
        '/login?redirect=%2Finvestor-dashboard',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/financial-dashboard'),
        '/login?redirect=%2Ffinancial-dashboard',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/rent-collection'),
        '/login?redirect=%2Frent-collection',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/image-moderation'),
        '/login?redirect=%2Fimage-moderation',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/lease-builder'),
        '/login?redirect=%2Flease-builder',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/fast-onboarding'),
        '/login?redirect=%2Ffast-onboarding',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/checkout'),
        '/login?redirect=%2Fcheckout',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/super-admin'),
        '/admin/login',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: false, role: null, roleKnown: false, location: '/admin'),
        '/admin/login',
      );
    });

    test('allows each role only on its portals', () {
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'Owner', roleKnown: true, location: '/financial-dashboard'),
        isNull,
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'Owner', roleKnown: true, location: '/investor-dashboard'),
        isNull,
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'AgencyAdmin', roleKnown: true, location: '/lease-builder'),
        isNull,
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'Tenant', roleKnown: true, location: '/checkout'),
        isNull,
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'Tenant', roleKnown: true, location: '/rent-collection'),
        '/tenant',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'Owner', roleKnown: true, location: '/agency'),
        '/owner',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'AgencyAdmin', roleKnown: true, location: '/super-admin'),
        '/agency',
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'SuperAdmin', roleKnown: true, location: '/image-moderation'),
        isNull,
      );
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: 'SuperAdmin', roleKnown: true, location: '/admin'),
        '/super-admin',
      );
    });

    test('does not guess a role while the profile is still loading', () {
      expect(
        RouteAccess.redirect(isLoggedIn: true, role: null, roleKnown: false, location: '/financial-dashboard'),
        isNull,
      );
    });
  });
}
