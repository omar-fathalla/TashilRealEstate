import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/investor_dashboard/services/investor_analytics_service.dart';
import 'package:tashil_real_estate/features/investor_dashboard/widgets/investor_report_dialog.dart';

Widget wrapWithApp({required Widget child, Locale locale = const Locale('ar')}) {
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
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A),
        primary: const Color(0xFF0F172A),
        secondary: const Color(0xFF3B82F6),
        tertiary: const Color(0xFFF59E0B),
      ),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleController.setLanguage('ar');
    CountryController.setCountry('EG');
  });

  group('InvestorReportDialog M3 & Numerical Clarity Tests', () {
    testWidgets('Renders properly in Arabic with clean Western numerals and zero ellipsis distortion', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final summary = InvestorAnalyticsService().getSummaryForCountry('EG');

      await tester.pumpWidget(wrapWithApp(
        child: InvestorReportDialog(summary: summary),
      ));
      await tester.pumpAndSettle();

      // Verify header and document titles
      expect(find.text('تقرير المستثمر المالي وشهادة تقييم المحفظة'), findsOneWidget);
      expect(find.text('كشف مالي رسمي معتمد وموثق'), findsOneWidget);
      expect(find.text('توقيع واعتماد المستشار المالي المعتمد'), findsOneWidget);
      expect(find.text('معتمد وموثق رسمياً'), findsOneWidget);
      expect(find.textContaining('الهيئة العامة للرقابة المالية والوساطة العقارية'), findsOneWidget);

      // Verify numerals are clean Western Arabic (0-9) without Eastern zero dot confusion
      expect(find.textContaining('33,200,000 ج.م'), findsOneWidget);
      expect(find.textContaining('1,699,000 ج.م'), findsOneWidget);
      expect(find.textContaining('4,200,000 ج.م'), findsOneWidget);
      expect(find.textContaining('5,600,000 ج.م'), findsOneWidget);

      // No raw keys
      expect(find.text('certifiedFinancialAdvisorSignature'), findsNothing);
      expect(find.text('regulatoryAuthorityEg'), findsNothing);
      expect(find.text('officiallyVerified'), findsNothing);
    });

    testWidgets('Renders properly in English with localized date, authority, and verified stamp', (tester) async {
      LocaleController.setLanguage('en');
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final summary = InvestorAnalyticsService().getSummaryForCountry('EG');

      await tester.pumpWidget(wrapWithApp(
        locale: const Locale('en'),
        child: InvestorReportDialog(summary: summary),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Official Investor Statement & Portfolio Certificate'), findsOneWidget);
      expect(find.text('Certified & Audited Statement'), findsOneWidget);
      expect(find.text('Certified Financial Advisor Signature & Attestation'), findsOneWidget);
      expect(find.text('OFFICIALLY VERIFIED'), findsOneWidget);
      expect(find.textContaining('November 30, 2026'), findsOneWidget);
      expect(find.textContaining('Financial Regulatory Authority & Real Estate Brokerage'), findsOneWidget);
    });

    testWidgets('Renders properly in Hindi with full tri-language parity', (tester) async {
      LocaleController.setLanguage('hi');
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final summary = InvestorAnalyticsService().getSummaryForCountry('EG');

      await tester.pumpWidget(wrapWithApp(
        locale: const Locale('hi'),
        child: InvestorReportDialog(summary: summary),
      ));
      await tester.pumpAndSettle();

      expect(find.text('आधिकारिक निवेशक विवरण और पोर्टफोलियो प्रमाणपत्र'), findsOneWidget);
      expect(find.text('प्रमाणित वित्तीय सलाहकार हस्ताक्षर और सत्यापन'), findsOneWidget);
      expect(find.text('आधिकारिक रूप से सत्यापित'), findsOneWidget);
      expect(find.textContaining('30 नवंबर 2026'), findsOneWidget);
    });

    testWidgets('Close button and download button dismiss the dialog cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final summary = InvestorAnalyticsService().getSummaryForCountry('EG');

      await tester.pumpWidget(wrapWithApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => InvestorReportDialog.show(context, summary),
            child: const Text('Open Report'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorReportDialog), findsOneWidget);

      // Dismiss with top shaded close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorReportDialog), findsNothing);

      // Open dialog again
      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorReportDialog), findsOneWidget);

      // Dismiss with bottom download button
      await tester.tap(find.text('تنزيل التقرير المالي المعتمد'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorReportDialog), findsNothing);
      expect(find.textContaining('تم توليد وتنزيل تقرير المستثمر المالي الرسمي بنجاح'), findsOneWidget);
    });
  });
}
