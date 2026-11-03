import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/navigation_rail/tashil_navigation_rail.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/tenant_portal/tenant_dashboard.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_home_view.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_payments_view.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_support_view.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp({
    Locale locale = const Locale('ar'),
    required Widget child,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
        ),
      ),
      home: child,
    );
  }

  group('TenantDashboard M3 Adaptive Navigation Suite', () {
    testWidgets('Desktop viewport (1280x900) renders TashilScaffoldCanvas and TashilNavigationRail without bottom NavigationBar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const TenantDashboard()));
      await tester.pumpAndSettle();

      // Verify M3 Nested Canvas and Navigation Rail are present
      expect(find.byType(TashilScaffoldCanvas), findsOneWidget);
      expect(find.byType(TashilNavigationRail), findsOneWidget);

      // Verify bottom NavigationBar is completely absent on desktop
      expect(find.byType(NavigationBar), findsNothing);

      // Verify initial tab is TenantHomeView
      expect(find.byType(TenantHomeView), findsOneWidget);
      expect(find.byType(TenantPaymentsView), findsNothing);

      // Switch to Financials tab via Navigation Rail
      await tester.tap(find.byIcon(Symbols.payment_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(TenantPaymentsView), findsOneWidget);
      expect(find.byType(TenantHomeView), findsNothing);

      // Switch to Maintenance tab via Navigation Rail
      await tester.tap(find.byIcon(Symbols.handyman_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(TenantSupportView), findsOneWidget);
    });

    testWidgets('Tablet viewport (720x1024) renders compact TashilNavigationRail without bottom NavigationBar', (tester) async {
      tester.view.physicalSize = const Size(720, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const TenantDashboard()));
      await tester.pumpAndSettle();

      // Verify TashilScaffoldCanvas and TashilNavigationRail are present
      expect(find.byType(TashilScaffoldCanvas), findsOneWidget);
      expect(find.byType(TashilNavigationRail), findsOneWidget);

      // Verify bottom NavigationBar is absent
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Mobile viewport (390x844) renders bottom NavigationBar and hides TashilNavigationRail and TashilScaffoldCanvas', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const TenantDashboard()));
      await tester.pumpAndSettle();

      // Verify bottom NavigationBar is present
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify Desktop/Tablet Navigation Rail and Canvas are absent
      expect(find.byType(TashilScaffoldCanvas), findsNothing);
      expect(find.byType(TashilNavigationRail), findsNothing);

      // Verify default home view
      expect(find.byType(TenantHomeView), findsOneWidget);

      // Tap on financials navigation destination
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Symbols.payment_rounded),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TenantPaymentsView), findsOneWidget);
    });

    testWidgets('Trilingual support: renders cleanly in English and Hindi without overflow or errors', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Test English
      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(locale: const Locale('en'), child: const TenantDashboard()));
      await tester.pumpAndSettle();
      expect(find.byType(TashilScaffoldCanvas), findsOneWidget);

      // Test Hindi
      LocaleController.setLanguage('hi');
      await tester.pumpWidget(wrapWithApp(locale: const Locale('hi'), child: const TenantDashboard()));
      await tester.pumpAndSettle();
      expect(find.byType(TashilScaffoldCanvas), findsOneWidget);
    });
  });
}
