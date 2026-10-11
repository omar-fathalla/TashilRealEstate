import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/dynamic_pricing/widgets/dynamic_pricing_tab_view.dart';
import 'package:tashil_real_estate/features/dynamic_pricing/widgets/dynamic_yield_curve_tab_view.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_financials_view.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('ar')}) {
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
        secondary: const Color(0xFF3B82F6),
        tertiary: const Color(0xFFF59E0B),
      ),
    ),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CountryController.setCountry('EG');
    LocaleController.setLocale(const Locale('ar'));
  });

  group('Dynamic Pricing Relocation & Interactive Curve Suite', () {
    testWidgets('OwnerFinancialsView no longer contains dynamic pricing tab and has only 3 financial tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(const OwnerFinancialsView()));
      await tester.pumpAndSettle();

      final loc = AppLocalizations(const Locale('ar'));

      // Verify the 3 financial tabs exist
      expect(find.text(loc.tr('rentInvoicingAndCollectionTab')), findsOneWidget);
      expect(find.text(loc.tr('arrearsAndLegalNoticesTab')), findsOneWidget);
      expect(find.text(loc.tr('recentPayouts')), findsOneWidget);

      // Verify Dynamic Pricing is NOT in Owner Financials
      expect(find.text(loc.tr('dynamicYieldOptimizerTitle')), findsNothing);
      expect(find.byType(DynamicPricingTabView), findsNothing);
    });

    testWidgets('InvestorDashboardView contains Dynamic Pricing Engine and Full Interactive Curve as independent tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(const InvestorDashboardView()));
      await tester.pumpAndSettle();

      final loc = AppLocalizations(const Locale('ar'));

      // Verify both tabs exist in the connected button group
      final dynamicPricingTab = find.text(loc.tr('dynamicYieldOptimizerTitle'));
      final fullCurveTab = find.text(loc.tr('fullInteractiveCurveTab'));

      expect(dynamicPricingTab, findsOneWidget);
      expect(fullCurveTab, findsOneWidget);

      // Tap Dynamic Pricing tab
      await tester.ensureVisible(dynamicPricingTab);
      await tester.tap(dynamicPricingTab);
      await tester.pumpAndSettle();

      // Verify DynamicPricingTabView is loaded
      expect(find.byType(DynamicPricingTabView), findsOneWidget);
      expect(find.text(loc.tr('managedUnitsDynamicPricingTitle')), findsOneWidget);

      // Tap Full Interactive Curve tab
      await tester.ensureVisible(fullCurveTab);
      await tester.tap(fullCurveTab);
      await tester.pumpAndSettle();

      // Verify DynamicYieldCurveTabView is loaded
      expect(find.byType(DynamicYieldCurveTabView), findsOneWidget);
      expect(find.text(loc.tr('dynamicYieldOptimizerSubtitle')), findsOneWidget);
    });

    testWidgets('Tapping "عرض المنحنى التفاعلي الكامل" inside DynamicPricingTabView switches to curve tab in InvestorDashboardView', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(const InvestorDashboardView()));
      await tester.pumpAndSettle();

      final loc = AppLocalizations(const Locale('ar'));

      // Switch to Dynamic Pricing tab
      final dynamicPricingTab = find.text(loc.tr('dynamicYieldOptimizerTitle'));
      await tester.ensureVisible(dynamicPricingTab);
      await tester.tap(dynamicPricingTab);
      await tester.pumpAndSettle();

      expect(find.byType(DynamicPricingTabView), findsOneWidget);

      // Tap "عرض المنحنى التفاعلي الكامل" action button
      final openCurveBtn = find.text(loc.tr('openFullYieldDialogBtn'));
      expect(openCurveBtn, findsOneWidget);
      await tester.ensureVisible(openCurveBtn);
      await tester.tap(openCurveBtn);
      await tester.pumpAndSettle();

      // Verify it switched directly to DynamicYieldCurveTabView without opening a dialog
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(DynamicYieldCurveTabView), findsOneWidget);
      expect(find.text(loc.tr('dynamicYieldOptimizerSubtitle')), findsOneWidget);
    });

    testWidgets('Interactive Curve Tab renders cleanly in English and Hindi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Test English
      LocaleController.setLocale(const Locale('en'));
      await tester.pumpWidget(_buildTestApp(const InvestorDashboardView(), locale: const Locale('en')));
      await tester.pumpAndSettle();

      final enLoc = AppLocalizations(const Locale('en'));
      final enCurveTab = find.text(enLoc.tr('fullInteractiveCurveTab'));
      expect(enCurveTab, findsOneWidget);
      await tester.ensureVisible(enCurveTab);
      await tester.tap(enCurveTab);
      await tester.pumpAndSettle();

      expect(find.byType(DynamicYieldCurveTabView), findsOneWidget);
      expect(find.text(enLoc.tr('dynamicYieldOptimizerSubtitle')), findsOneWidget);
      expect(find.text(enLoc.tr('recommendedDynamicRent')), findsWidgets);

      // Test Hindi
      LocaleController.setLocale(const Locale('hi'));
      await tester.pumpWidget(_buildTestApp(const InvestorDashboardView(), locale: const Locale('hi')));
      await tester.pumpAndSettle();

      final hiLoc = AppLocalizations(const Locale('hi'));
      final hiCurveTab = find.text(hiLoc.tr('fullInteractiveCurveTab'));
      expect(hiCurveTab, findsOneWidget);
      await tester.ensureVisible(hiCurveTab);
      await tester.tap(hiCurveTab);
      await tester.pumpAndSettle();

      expect(find.byType(DynamicYieldCurveTabView), findsOneWidget);
      expect(find.text(hiLoc.tr('dynamicYieldOptimizerSubtitle')), findsOneWidget);
      expect(find.text(hiLoc.tr('recommendedDynamicRent')), findsWidgets);
    });
  });
}
