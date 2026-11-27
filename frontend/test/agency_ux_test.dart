import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/config/demo_data.dart';
import 'package:tashil_real_estate/core/config/feature_flags.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_dashboard.dart';
import 'package:tashil_real_estate/features/agency_workspace/services/agency_identity.dart';
import 'package:tashil_real_estate/features/agency_workspace/widgets/agency_profile_dialog.dart';
import 'package:tashil_real_estate/features/agency_workspace/views/crm_view.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';

class FakeIdentitySource implements AgencyIdentitySource {
  final AgencyIdentity identity;
  final sent = <String>[];
  Object? failWith;
  FakeIdentitySource(this.identity);

  @override
  Future<AgencyIdentity> load() async => identity;

  @override
  Future<void> sendPasswordReset(String email) async {
    sent.add(email);
    if (failWith != null) throw failWith!;
  }
}

const sara = AgencyIdentity(
  displayName: 'Sara Ali',
  email: 'sara@agency.example',
  agencyId: 'ag1',
  agencyName: 'Marina Realty',
  agencyNames: {'ar': 'مارينا العقارية'},
);

Widget app(Widget child, {Locale locale = const Locale('en')}) {
  LocaleController.setLocale(locale);
  return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: Center(child: child)),
    );
}

Future<void> pumpApp(WidgetTester tester, Widget child, {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(app(child, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  group('AgencyIdentity', () {
    test('initials come from the name, else the email, and are empty with neither', () {
      expect(sara.initials, 'SA');
      expect(const AgencyIdentity(displayName: 'مها حسن').initials, 'مح');
      expect(const AgencyIdentity(displayName: 'Omar').initials, 'O');
      expect(const AgencyIdentity(email: 'agency@test.tashilaqar.com').initials, 'A');
      expect(const AgencyIdentity(email: 'sara.ali@agency.example').initials, 'SA');
      expect(AgencyIdentity.empty.initials, '');
    });

    test('the person falls back to the email and the agency name is localized', () {
      expect(const AgencyIdentity(email: 'a@b.co').personName, 'a@b.co');
      expect(sara.agencyNameFor('ar'), 'مارينا العقارية');
      expect(sara.agencyNameFor('en'), 'Marina Realty');
      expect(sara.agencyNameFor('hi'), 'Marina Realty');
    });
  });

  group('TashilIconButton hit area (TAQ-153)', () {
    final variants = <String, Widget Function(VoidCallback)>{
      'standard': (tap) => TashilIconButton.standard(icon: Icons.menu_rounded, size: 34, onPressed: tap),
      'tonal': (tap) => TashilIconButton.tonal(icon: Icons.tune_rounded, size: 38, onPressed: tap),
      'filled': (tap) => TashilIconButton.filled(icon: Icons.add_rounded, size: 36, onPressed: tap),
      'outlined': (tap) => TashilIconButton.outlined(icon: Icons.phone_outlined, size: 34, onPressed: tap),
      'close': (tap) => TashilIconButton.close(size: 34, onPressed: tap),
    };

    for (final entry in variants.entries) {
      for (final platform in [TargetPlatform.android, TargetPlatform.linux]) {
        testWidgets('${entry.key} on ${platform.name}: at least 48x48 and tappable outside the drawn circle', (tester) async {
          var taps = 0;
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true, platform: platform),
            home: Scaffold(body: Center(child: entry.value(() => taps++))),
          ));
          final target = find.byType(IconButton);
          final size = tester.getSize(target);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
          // 21dp from the centre is outside a 34-38dp circle but inside the 48dp target.
          await tester.tapAt(tester.getCenter(target) + const Offset(21, 0));
          await tester.pump();
          expect(taps, 1);
        });
      }
    }
  });

  group('AgencyProfileDialog', () {
    testWidgets('shows the signed-in name, email and agency, and no invented counters', (tester) async {
      await pumpApp(tester, AgencyProfileDialog(
        identity: sara,
        onDashboard: () {},
        onSettings: () {},
        onBrowse: () {},
        onSecurity: () {},
        onLogout: () {},
      ));
      expect(find.text('Sara Ali'), findsOneWidget);
      expect(find.text('sara@agency.example'), findsOneWidget);
      expect(find.text('Marina Realty'), findsOneWidget);
      expect(find.text('SA'), findsOneWidget);
      expect(find.text('AG'), findsNothing);
      expect(find.text('120'), findsNothing);
      expect(find.text('85'), findsNothing);
    });

    testWidgets('Arabic shows the Arabic agency name', (tester) async {
      await pumpApp(tester, 
        AgencyProfileDialog(identity: sara, onDashboard: () {}, onSettings: () {}, onBrowse: () {}, onSecurity: () {}, onLogout: () {}),
        locale: const Locale('ar'),
      );
      expect(find.text('مارينا العقارية'), findsOneWidget);
    });

    testWidgets('Account security is a real action; it is hidden when the account has no email', (tester) async {
      var security = 0;
      await pumpApp(tester, AgencyProfileDialog(
        identity: sara,
        onDashboard: () {},
        onSettings: () {},
        onBrowse: () {},
        onSecurity: () => security++,
        onLogout: () {},
      ));
      await tester.tap(find.text('Security & Credentials'));
      expect(security, 1);

      await pumpApp(tester, AgencyProfileDialog(
        identity: const AgencyIdentity(displayName: 'No Email'),
        onDashboard: () {},
        onSettings: () {},
        onBrowse: () {},
        onSecurity: () {},
        onLogout: () {},
      ));
      expect(find.text('Security & Credentials'), findsNothing);
    });

    testWidgets('every menu row is at least 48dp tall', (tester) async {
      await pumpApp(tester, AgencyProfileDialog(
        identity: sara,
        onDashboard: () {},
        onSettings: () {},
        onBrowse: () {},
        onSecurity: () {},
        onLogout: () {},
      ));
      for (final label in ['Dashboard', 'Security & Credentials', 'Logout']) {
        final row = find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48), reason: label);
      }
    });
  });

  group('password reset dialog', () {
    Future<void> open(WidgetTester tester, FakeIdentitySource source, List<bool> results) async {
      await pumpApp(tester, Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await showAgencyPasswordResetDialog(context, email: 'sara@agency.example', send: source.sendPasswordReset)),
          child: const Text('open'),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('sends the reset link to the account email and closes', (tester) async {
      final source = FakeIdentitySource(sara);
      final results = <bool>[];
      await open(tester, source, results);
      expect(find.textContaining('sara@agency.example'), findsOneWidget);
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(source.sent, ['sara@agency.example']);
      expect(results, [true]);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a failure is shown inside the dialog, which stays open, and sending can be retried', (tester) async {
      final source = FakeIdentitySource(sara)..failWith = Exception('network');
      final results = <bool>[];
      await open(tester, source, results);
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('security-reset-error')), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      source.failWith = null;
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(source.sent.length, 2);
      expect(results, [true]);
    });

    testWidgets('cancel sends nothing', (tester) async {
      final source = FakeIdentitySource(sara);
      final results = <bool>[];
      await open(tester, source, results);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(source.sent, isEmpty);
      expect(results, [false]);
    });
  });

  testWidgets('the dashboard profile tile shows the signed-in user instead of AG', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(sara)));
    await tester.pumpAndSettle();
    expect(find.text('Sara Ali'), findsWidgets);
    expect(find.text('Marina Realty'), findsWidgets);
    expect(find.text('AG'), findsNothing);
  });

  group('mockup tabs (TAQ-152)', () {
    test('stay behind the AGENCY_MOCK_TABS define, off by default', () {
      expect(FeatureFlags.agencyMockTabs, isFalse);
    });

    testWidgets('CRM and Investor are left out of the rail by default', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(sara)));
      expect(find.text('Clients'), findsNothing);
      expect(find.byType(CrmView), findsNothing);
      expect(find.byType(InvestorDashboardView), findsNothing);
      expect(find.text('Contracts'), findsWidgets);
    });

    testWidgets('the phone bar opens Leases and Financials, not the hidden views', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(sara)));
      final bar = find.byType(NavigationBar);
      expect(find.descendant(of: bar, matching: find.byType(NavigationDestination)), findsNWidgets(4));
      await tester.tap(find.descendant(of: bar, matching: find.byIcon(Icons.analytics_outlined)));
      await tester.pumpAndSettle();
      expect(find.byType(FinancialKpiDashboardView), findsOneWidget);
      expect(find.byType(CrmView), findsNothing);
    });
  });

  group('demo accounts (TAQ-153)', () {
    test('use the test.tashilaqar.com set, one per role, none on the old @test.com', () {
      expect(DemoData.accounts.map((a) => a.email), [
        'owner@test.tashilaqar.com',
        'agency@test.tashilaqar.com',
        'tenant@test.tashilaqar.com',
        'superadmin@test.tashilaqar.com',
      ]);
      expect(DemoData.accounts.map((a) => a.role), ['Owner', 'AgencyAdmin', 'Tenant', 'SuperAdmin']);
      for (final account in DemoData.accounts) {
        expect(account.email.endsWith('@test.com'), isFalse);
      }
    });

    test('demo buttons stay behind the DEMO_DATA define, off by default', () {
      expect(DemoData.enabled, isFalse);
    });
  });
}
