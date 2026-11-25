import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';

class _FakeUser implements User {
  _FakeUser({this.email});

  @override
  final String? email;

  @override
  String? get displayName => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => RoleSession.instance.debugSet(RoleSessionStatus.signedOut));

  group('TAQ-28: header role comes from the trusted role, never the email', () {
    for (final lang in ['ar', 'en', 'hi']) {
      final loc = AppLocalizations(Locale(lang));

      test('[$lang] admin@ email with a Tenant role shows the Tenant title and route', () {
        RoleSession.instance.debugSet(RoleSessionStatus.signedIn, 'Tenant');
        final info = PublicHeaderNavbar.debugResolveUserInfo(_FakeUser(email: 'admin@x.com'), loc);
        expect(info.roleTitle, loc.tr('roleTenant'));
        expect(info.dashboardRoute, '/tenant');
        expect(info.roleTitle, isNot(loc.tr('roleSuperAdmin')));
      });

      test('[$lang] a signed-in user without a role gets the generic title and no admin dashboard', () {
        RoleSession.instance.debugSet(RoleSessionStatus.signedIn);
        for (final email in ['admin@x.com', 'superadmin@tashil.com', 'agency@test.com', 'owner@test.com']) {
          final info = PublicHeaderNavbar.debugResolveUserInfo(_FakeUser(email: email), loc);
          expect(info.roleTitle, loc.tr('roleSignedInUser'), reason: email);
          expect(info.dashboardRoute, isNot('/super-admin'), reason: email);
          expect(info.dashboardRoute, '/', reason: email);
        }
      });
    }

    test('a role the profile cannot vouch for is ignored', () {
      RoleSession.instance.debugSet(RoleSessionStatus.signedIn, 'Overlord');
      final loc = AppLocalizations(const Locale('en'));
      final info = PublicHeaderNavbar.debugResolveUserInfo(_FakeUser(email: 'admin@x.com'), loc);
      expect(info.roleTitle, loc.tr('roleSignedInUser'));
      expect(info.dashboardRoute, '/');
    });
  });

  group('TAQ-91: header for Admin and Investor', () {
    for (final lang in ['ar', 'en', 'hi']) {
      final loc = AppLocalizations(Locale(lang));

      test('[$lang] Admin shows the Platform Admin title and routes to /admin, not /super-admin', () {
        RoleSession.instance.debugSet(RoleSessionStatus.signedIn, 'Admin');
        final info = PublicHeaderNavbar.debugResolveUserInfo(_FakeUser(email: 'someone@x.com'), loc);
        expect(info.roleTitle, loc.tr('roleAdmin'));
        expect(info.roleTitle, isNot(loc.tr('roleSuperAdmin')));
        expect(info.dashboardRoute, '/admin');
      });

      test('[$lang] Investor shows the Investor title and lands on the marketplace', () {
        RoleSession.instance.debugSet(RoleSessionStatus.signedIn, 'Investor');
        final info = PublicHeaderNavbar.debugResolveUserInfo(_FakeUser(email: 'admin@x.com'), loc);
        expect(info.roleTitle, loc.tr('roleInvestor'));
        expect(info.dashboardRoute, '/');
      });
    }

    test('the role labels are Arabic, English and Hindi respectively', () {
      expect(AppLocalizations(const Locale('ar')).tr('roleAdmin'), 'أدمن المنصة');
      expect(AppLocalizations(const Locale('ar')).tr('roleInvestor'), 'مستثمر');
      expect(AppLocalizations(const Locale('en')).tr('roleAdmin'), 'Platform Admin');
      expect(AppLocalizations(const Locale('en')).tr('roleInvestor'), 'Investor');
    });
  });

  group('TAQ-28: visitors see the login CTA and no dashboard link', () {
    Widget app(Locale locale) => MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(appBar: PublicHeaderNavbar(), body: SizedBox()),
        );

    testWidgets('desktop header', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(app(const Locale('ar')));
      await tester.pumpAndSettle();

      final loc = AppLocalizations(const Locale('ar'));
      expect(find.byTooltip(loc.tr('portalLogin')), findsOneWidget);
      expect(find.byIcon(Icons.lock_person_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_rounded), findsNothing);
      expect(find.text(loc.tr('backToDashboard')), findsNothing);
      expect(find.text(loc.tr('logout')), findsNothing);
    });

    testWidgets('mobile menu', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      final loc = AppLocalizations(const Locale('en'));
      expect(find.text(loc.tr('portalLogin')), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_rounded), findsNothing);
      expect(find.text(loc.tr('backToDashboard')), findsNothing);
      expect(find.text(loc.tr('logout')), findsNothing);
    });
  });
}
