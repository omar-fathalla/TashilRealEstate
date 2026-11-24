import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';
import 'package:tashil_real_estate/features/public_marketplace/public_marketplace_screen.dart';

/// TAQ-91: the "list your property" call to action is only offered to roles that can use it.
void main() {
  group('RouteAccess.showListPropertyCta', () {
    test('visitors and loading sessions see it, since it leads to sign-in', () {
      expect(RouteAccess.showListPropertyCta(signedIn: false, role: ''), isTrue);
    });

    test('Owner and AgencyAdmin see it', () {
      expect(RouteAccess.showListPropertyCta(signedIn: true, role: 'Owner'), isTrue);
      expect(RouteAccess.showListPropertyCta(signedIn: true, role: 'AgencyAdmin'), isTrue);
    });

    test('Investor, Tenant, Admin, SuperAdmin and a role-less user do not', () {
      for (final role in ['Investor', 'Tenant', 'Admin', 'SuperAdmin', '']) {
        expect(RouteAccess.showListPropertyCta(signedIn: true, role: role), isFalse, reason: role);
      }
    });

    test('it matches who can actually open the onboarding route', () {
      for (final role in ['Owner', 'AgencyAdmin', 'Investor', 'Tenant', 'Admin', 'SuperAdmin', '']) {
        expect(
          RouteAccess.showListPropertyCta(signedIn: true, role: role),
          RouteAccess.canAccess('/fast-onboarding', role),
          reason: role,
        );
      }
    });
  });

  group('the marketplace hero', () {
    setUp(() {
      LocaleController.setLocale(const Locale('ar'));
      CountryController.setCountry('EG');
    });
    tearDown(() {
      LocaleController.setLocale(const Locale('ar'));
      RoleSession.instance.debugSet(RoleSessionStatus.signedOut);
    });

    Future<void> pumpHero(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(useMaterial3: true),
        home: const PublicMarketplaceScreen(),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    String label() => AppLocalizations(const Locale('ar')).tr('listPropertyBtn');

    testWidgets('a visitor sees the button', (tester) async {
      RoleSession.instance.debugSet(RoleSessionStatus.signedOut);
      await pumpHero(tester);
      expect(find.text(label()), findsOneWidget);
    });

    testWidgets('an Owner sees the button', (tester) async {
      RoleSession.instance.debugSet(RoleSessionStatus.signedIn, 'Owner');
      await pumpHero(tester);
      expect(find.text(label()), findsOneWidget);
    });

    for (final role in ['Investor', 'Tenant', 'Admin']) {
      testWidgets('$role does not see the button, and it disappears when the role changes', (tester) async {
        RoleSession.instance.debugSet(RoleSessionStatus.signedIn, 'Owner');
        await pumpHero(tester);
        expect(find.text(label()), findsOneWidget);
        RoleSession.instance.debugSet(RoleSessionStatus.signedIn, role);
        await tester.pump();
        expect(find.text(label()), findsNothing);
      });
    }
  });
}
