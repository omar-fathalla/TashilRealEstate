import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/market_index/views/market_index_view.dart';
import 'package:tashil_real_estate/features/market_index/widgets/market_historical_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child, {Locale locale = const Locale('ar')}) {
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
        ),
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('MarketIndexView Responsiveness & Feature Tests', () {
    testWidgets('Renders properly on desktop without overflow and displays table and chart', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const MarketIndexView()));
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('مؤشر السوق'), findsOneWidget);

      // Check table is rendered on desktop by default
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('دبي مارينا'), findsOneWidget);

      // Check historical trajectory chart
      expect(find.byType(MarketHistoricalChart), findsOneWidget);
      expect(find.text('المسار التاريخي لحركة المؤشر والطلب العقاري'), findsOneWidget);
      expect(find.text('بيانات تجريبية'), findsOneWidget);
    });

    testWidgets('Renders properly on narrow mobile (375x800) without any overflow error', (tester) async {
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const MarketIndexView()));
      await tester.pumpAndSettle();

      // Ensure no flutter overflow errors occurred
      expect(tester.takeException(), isNull);

      // On mobile, card view is displayed for top districts
      final pageScrollable = find.byType(Scrollable).first;
      final districtFinder = find.text('دبي مارينا');
      await tester.scrollUntilVisible(districtFinder, 300, scrollable: pageScrollable);
      expect(districtFinder, findsOneWidget);

      // Verify chart renders without errors
      final chartFinder = find.byType(MarketHistoricalChart);
      await tester.scrollUntilVisible(chartFinder, 300, scrollable: pageScrollable);
      expect(chartFinder, findsOneWidget);
    });

    testWidgets('Toggles between Table and Cards view modes', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const MarketIndexView()));
      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);

      // Find and tap the cards view button
      final cardsBtn = find.text('عرض الكروت');
      expect(cardsBtn, findsOneWidget);
      await tester.ensureVisible(cardsBtn);
      await tester.pumpAndSettle();
      await tester.tap(cardsBtn);
      await tester.pumpAndSettle();

      // Table should be gone, cards should be active
      expect(find.byType(Table), findsNothing);

      // Tap table view button back
      final tableBtn = find.text('عرض الجدول');
      expect(tableBtn, findsOneWidget);
      await tester.ensureVisible(tableBtn);
      await tester.pumpAndSettle();
      await tester.tap(tableBtn);
      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('Switches test data scenarios and chart modes in MarketHistoricalChart', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const MarketIndexView()));
      await tester.pumpAndSettle();

      // Tap 12-Month scenario chip
      final twelveMonthsChip = find.text('١٢ شهراً');
      expect(twelveMonthsChip, findsOneWidget);
      await tester.ensureVisible(twelveMonthsChip);
      await tester.pumpAndSettle();
      await tester.tap(twelveMonthsChip);
      await tester.pumpAndSettle();

      // Tap Bullish scenario chip
      final bullishChip = find.text('سيناريو نمو قوي');
      expect(bullishChip, findsOneWidget);
      await tester.ensureVisible(bullishChip);
      await tester.pumpAndSettle();
      await tester.tap(bullishChip);
      await tester.pumpAndSettle();

      // Switch to bar chart mode
      final barModeBtn = find.text('أعمدة بيانية');
      expect(barModeBtn, findsOneWidget);
      await tester.ensureVisible(barModeBtn);
      await tester.pumpAndSettle();
      await tester.tap(barModeBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Supports English locale cleanly without mixing', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(const MarketIndexView(), locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Market index'), findsOneWidget);
      expect(find.text('Market index & demand historical trajectory'), findsOneWidget);
      expect(find.text('6 Months'), findsOneWidget);
      expect(find.text('12 Months'), findsOneWidget);
      expect(find.text('Strong growth scenario'), findsOneWidget);
      expect(find.text('Market pulse'), findsOneWidget);
      expect(find.text('Live — updated today at 09:00 am'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Verified market data sources'), findsOneWidget);
    });

    testWidgets('Renders Live Market Pulse and triggers instant refresh', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const MarketIndexView()));
      await tester.pumpAndSettle();

      // Verify ticker title and 09:00 AM update badge
      expect(find.text('نبض السوق'), findsOneWidget);
      expect(find.text('مباشر — تحديث اليوم 09:00 ص'), findsOneWidget);
      expect(find.text('تحديث'), findsWidgets);

      // Verify verified sources footer
      final pageScrollable = find.byType(Scrollable).first;
      final sourcesFinder = find.text('مصادر التحقق ومؤشرات السوق');
      await tester.scrollUntilVisible(sourcesFinder, 300, scrollable: pageScrollable);
      expect(sourcesFinder, findsOneWidget);

      // Tap instant refresh button
      final refreshBtn = find.text('تحديث');
      await tester.ensureVisible(refreshBtn);
      await tester.pumpAndSettle();
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      // Verify snackbar feedback
      expect(find.text('جاري تحديث نبض السوق بواسطة الذكاء الاصطناعي وبحث Google...'), findsOneWidget);
    });

    testWidgets('Supports Hindi locale cleanly for live market ticker and verified sources', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('hi');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(const MarketIndexView(), locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('बाज़ार सूचकांक'), findsOneWidget);
      expect(find.text('लाइव मार्केट पल्स और ब्रेकिंग संकेत'), findsOneWidget);
      expect(find.text('लाइव — आज सुबह 09:00 बजे अपडेट किया गया'), findsOneWidget);
      expect(find.text('अभी तुरंत रीफ्रेश करें'), findsOneWidget);
    });
  });
}
