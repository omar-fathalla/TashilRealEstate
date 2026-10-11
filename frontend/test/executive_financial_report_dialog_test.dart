import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_icon_button.dart';
import 'package:tashil_real_estate/features/executive_reporting/widgets/executive_financial_report_dialog.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('ar')}) {
  LocaleController.setLocale(locale);
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
    LocaleController.setLanguage('ar');
  });

  group('Executive Financial Report Dialog i18n & M3 Tests', () {
    testWidgets('Renders all KPI cards, alert tags, and action buttons in Arabic without raw keys', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ExecutiveFinancialReportDialog.show(context),
            child: const Text('Open Report'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap to open report dialog
      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();

      // Verify NO raw dictionary keys appear
      expect(find.text('capRateLabel'), findsNothing);
      expect(find.text('rentCollectionEfficiency'), findsNothing);
      expect(find.text('tenantLabel'), findsNothing);
      expect(find.text('shareWhatsAppDigestBtn'), findsNothing);
      expect(find.text('pdfReportExportedNotification'), findsNothing);
      expect(find.text('csvExportedNotification'), findsNothing);

      // Verify correct Arabic translations are rendered
      expect(find.text('معدل الرسملة الرأسمالي'), findsOneWidget);
      expect(find.text('كفاءة تحصيل الإيجار'), findsOneWidget);
      expect(find.textContaining('المستأجر:'), findsWidgets);
      expect(find.text('مشاركة موجز واتساب'), findsOneWidget);
      expect(find.text('تحميل تقرير PDF'), findsOneWidget);
      expect(find.text('تصدير إكسل CSV'), findsOneWidget);

      // Verify M3 Shaded Close Button is present
      expect(find.byType(TashilIconButton), findsWidgets);
    });

    testWidgets('Renders correctly in English without raw keys', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ExecutiveFinancialReportDialog.show(context),
            child: const Text('Open Report'),
          ),
        ),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();

      // Verify NO raw keys
      expect(find.text('capRateLabel'), findsNothing);
      expect(find.text('rentCollectionEfficiency'), findsNothing);
      expect(find.text('tenantLabel'), findsNothing);
      expect(find.text('shareWhatsAppDigestBtn'), findsNothing);

      // Verify English translations
      expect(find.text('Capitalization Rate (Cap Rate)'), findsOneWidget);
      expect(find.text('Rent Collection Efficiency'), findsOneWidget);
      expect(find.textContaining('Tenant:'), findsWidgets);
      expect(find.text('Share WhatsApp Digest'), findsOneWidget);
    });

    testWidgets('Renders correctly in Hindi without raw keys', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ExecutiveFinancialReportDialog.show(context),
            child: const Text('Open Report'),
          ),
        ),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();

      // Verify NO raw keys
      expect(find.text('capRateLabel'), findsNothing);
      expect(find.text('rentCollectionEfficiency'), findsNothing);
      expect(find.text('tenantLabel'), findsNothing);
      expect(find.text('shareWhatsAppDigestBtn'), findsNothing);

      // Verify Hindi translations
      expect(find.text('पूंजीकरण दर (कैप दर)'), findsOneWidget);
      expect(find.text('किराया संग्रह दक्षता'), findsOneWidget);
      expect(find.textContaining('किरायेदार:'), findsWidgets);
      expect(find.text('व्हाट्सएप सारांश साझा करें'), findsOneWidget);
    });
  });
}
