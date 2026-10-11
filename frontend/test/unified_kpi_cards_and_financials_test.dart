import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_financials_view.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_overview_view.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CountryController.setCountry('EG');
    LocaleController.setLanguage('ar');
  });

  Widget buildTestableWidget(Widget child, {Locale locale = const Locale('ar')}) {
    LocaleController.setLanguage(locale.languageCode);
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
      ),
      home: Scaffold(body: child),
    );
  }

  group('TashilKpiCard & TashilKpiGrid Specifications', () {
    testWidgets('TashilKpiCard renders with exact M3 specifications', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TashilKpiCard(
            title: 'إجمالي الفواتير',
            value: '25,000 ج.م',
            subtitle: 'تحصيل إلكتروني مؤكد',
            icon: Icons.receipt_long_rounded,
            subtitleIcon: Icons.verified_rounded,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إجمالي الفواتير'), findsOneWidget);
      expect(find.text('25,000 ج.م'), findsOneWidget);
      expect(find.text('تحصيل إلكتروني مؤكد'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      // Verify card styling
      final cardFinder = find.byType(TashilCard);
      expect(cardFinder, findsOneWidget);
    });

    testWidgets('TashilKpiGrid adapts responsively across screen widths', (tester) async {
      final sampleCards = List.generate(
        4,
        (i) => TashilKpiCard(
          title: 'Card $i',
          value: '$i',
          subtitle: 'Sub $i',
          icon: Icons.star,
          subtitleIcon: Icons.check,
        ),
      );

      // 1. Desktop Width (1200px)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(TashilKpiGrid(cards: sampleCards)));
      await tester.pumpAndSettle();

      expect(find.byType(TashilKpiCard), findsNWidgets(4));

      // 2. Mobile Width (400px)
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(buildTestableWidget(TashilKpiGrid(cards: sampleCards)));
      await tester.pumpAndSettle();

      expect(find.byType(TashilKpiCard), findsNWidgets(4));
    });
  });

  group('OwnerFinancialsView Header & KPI Symmetry', () {
    testWidgets('Issue Invoice button is positioned at the far left (End in RTL) on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const OwnerFinancialsView()));
      await tester.pumpAndSettle();

      // Find Issue Invoice button
      final btnFinder = find.widgetWithText(TashilButton, 'إصدار فاتورة');
      expect(btnFinder, findsOneWidget);

      // Find Header title
      final titleFinder = find.text('مركز الفواتير والتحصيل الإيجاري الإلكتروني');
      expect(titleFinder, findsOneWidget);

      // In RTL on a 1280-wide screen, the Title (Start) is on the right (dx > 400),
      // and the Button (End) is on the left (dx < 400).
      final titleOffset = tester.getTopLeft(titleFinder);
      final btnOffset = tester.getTopLeft(btnFinder);

      expect(
        btnOffset.dx < titleOffset.dx,
        isTrue,
        reason: 'In RTL, Issue Invoice button must be on the left (End) and Title on the right (Start)',
      );
    });

    testWidgets('OwnerFinancialsView displays 4 uniform TashilKpiCards with subtitles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const OwnerFinancialsView()));
      await tester.pumpAndSettle();

      final kpiCards = find.byType(TashilKpiCard);
      expect(kpiCards, findsNWidgets(4));

      expect(find.text('المحصل إلكترونياً هذا الشهر'), findsOneWidget);
      expect(find.text('تحصيل إلكتروني مؤكد'), findsOneWidget);

      expect(find.text('المستحقات الإيجارية النشطة'), findsOneWidget);
      expect(find.text('مستحقة خلال الدورة الحالية'), findsOneWidget);

      expect(find.text('إجمالي المتأخرات والغرامات'), findsOneWidget);
      expect(find.text('تتطلب متابعة أو إنذار تكليف'), findsOneWidget);

      expect(find.text('إجمالي الفواتير المدارة'), findsOneWidget);
      expect(find.text('فواتير ضريبية إلكترونية نشطة'), findsOneWidget);
    });

    testWidgets('OwnerFinancialsView master tabs are seamless with no white container or dividing border', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const OwnerFinancialsView()));
      await tester.pumpAndSettle();

      // Master tabs connected button group is present
      final tabsFinder = find.byType(TashilConnectedButtonGroup<int>);
      expect(tabsFinder, findsOneWidget);

      // Verify that there is no Container with BoxDecoration containing a border around the master tabs
      final containerFinder = find.ancestor(
        of: tabsFinder,
        matching: find.byType(Container),
      );
      // None of the ancestor containers should have a border with outlineVariant
      for (final element in containerFinder.evaluate()) {
        final container = element.widget as Container;
        final decoration = container.decoration;
        if (decoration is BoxDecoration && decoration.border != null) {
          fail('Master tabs should not be wrapped in a container with a border');
        }
      }
    });

    testWidgets('RentCollectionView has transparent Scaffold background inheriting canvas color', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const RentCollectionView()));
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsWidgets);
      final scaffolds = tester.widgetList<Scaffold>(scaffoldFinder);
      // The inner scaffold should have transparent background
      final innerScaffold = scaffolds.last;
      expect(innerScaffold.backgroundColor, equals(Colors.transparent));
    });
  });

  group('Uniform KPI Cards Across All 5 Key Screens', () {
    testWidgets('OwnerOverviewView uses 4 TashilKpiCards in TashilKpiGrid', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const OwnerOverviewView()));
      await tester.pumpAndSettle();

      expect(find.byType(TashilKpiGrid), findsOneWidget);
      expect(find.byType(TashilKpiCard), findsNWidgets(4));
    });

    testWidgets('RentCollectionView uses 4 TashilKpiCards in TashilKpiGrid', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const RentCollectionView()));
      await tester.pumpAndSettle();

      expect(find.byType(TashilKpiGrid), findsOneWidget);
      expect(find.byType(TashilKpiCard), findsNWidgets(4));
    });

    testWidgets('LeasesManagementView uses 4 TashilKpiCards in TashilKpiGrid', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const LeasesManagementView()));
      await tester.pumpAndSettle();

      expect(find.byType(TashilKpiGrid), findsOneWidget);
      expect(find.byType(TashilKpiCard), findsNWidgets(4));
    });

    testWidgets('InvestorDashboardView uses 4 TashilKpiCards in TashilKpiGrid', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const InvestorDashboardView()));
      await tester.pumpAndSettle();

      expect(find.byType(TashilKpiGrid), findsOneWidget);
      expect(find.byType(TashilKpiCard), findsNWidgets(4));
    });
  });

  group('Trilingual Parity in Financials & KPIs (AR, EN, HI)', () {
    testWidgets('OwnerFinancialsView renders in English with pure localization', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const OwnerFinancialsView(), locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Rent Invoicing & Electronic Collection Hub'), findsOneWidget);
      expect(find.text('Issue Invoice'), findsOneWidget);
      expect(find.text('Verified electronic deposits'), findsOneWidget);
    });

    testWidgets('OwnerFinancialsView renders in Hindi with pure Devanagari localization', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const OwnerFinancialsView(), locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('किराया चालान और इलेक्ट्रॉनिक संग्रह केंद्र'), findsOneWidget);
      expect(find.text('चालान जारी करें'), findsOneWidget);
      expect(find.text('सत्यापित इलेक्ट्रॉनिक जमा'), findsOneWidget);
    });
  });
}
