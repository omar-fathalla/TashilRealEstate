import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/create_rent_invoice_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestDialog({Locale locale = const Locale('ar'), String country = 'EG'}) {
    LocaleController.setLocale(locale);
    CountryController.setCountry(country);

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
      home: const Scaffold(
        body: CreateRentInvoiceDialog(),
      ),
    );
  }

  group('CreateRentInvoiceDialog M3 Tests', () {
    testWidgets('Renders in Arabic with pure translations, no raw keys, and shortened button label', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(locale: const Locale('ar'), country: 'EG'));
      await tester.pumpAndSettle();

      // Verify that no raw dictionary keys are shown
      expect(find.text('tenantDetailsTitle'), findsNothing);
      expect(find.text('district'), findsNothing);
      expect(find.text('tenantPhoneNumber'), findsNothing);
      expect(find.text('tenantEmail'), findsNothing);
      expect(find.text('gracePeriodDays 5'), findsNothing);

      // Verify Arabic localized titles and labels
      expect(find.text('بيانات المستأجر'), findsOneWidget);
      expect(find.text('الحي / المنطقة'), findsOneWidget);
      expect(find.text('رقم الهاتف / الجوال'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('فترة السماح'), findsOneWidget);

      // Verify submit button has shortened label strictly without "وإرسال رابط السداد"
      expect(find.text('إصدار وتوثيق الفاتورة'), findsOneWidget);
      expect(find.textContaining('وإرسال رابط السداد'), findsNothing);

      // Verify TashilIconButton.close is present
      expect(find.byType(TashilIconButton), findsOneWidget);

      // Verify TashilDropdownMenu is used for registered units and grace period
      expect(find.byType(TashilDropdownMenu<String>), findsOneWidget);
      expect(find.byType(TashilDropdownMenu<int>), findsOneWidget);
    });

    testWidgets('Autofills fields when selecting a registered unit from dropdown', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(locale: const Locale('ar'), country: 'EG'));
      await tester.pumpAndSettle();

      // Initial unit is "شقة فاخرة بالتجمع الخامس"
      expect(find.text('شقة فاخرة بالتجمع الخامس'), findsOneWidget);
      expect(find.text('EG-2026-CAI-7719'), findsOneWidget);
      expect(find.text('302'), findsOneWidget);
      expect(find.text('عمارة النرجس 88'), findsOneWidget);
      expect(find.text('القاهرة الجديدة'), findsOneWidget);
      expect(find.text('محمود عبدالحميد السعدني'), findsOneWidget);
      expect(find.text('+201098765432'), findsOneWidget);

      // Open the registered units dropdown
      final unitDropdown = find.byType(TashilDropdownMenu<String>);
      await tester.tap(unitDropdown);
      await tester.pumpAndSettle();

      // Find the option "فيلا مستقلة بحمام سباحة" in the opened overlay menu
      final villaOption = find.text('فيلا مستقلة بحمام سباحة').last;
      await tester.tap(villaOption);
      await tester.pumpAndSettle();

      // Verify all fields are autofilled with the selected villa's details
      expect(find.text('فيلا مستقلة بحمام سباحة'), findsOneWidget);
      expect(find.text('EG-2026-ZAYED-1104'), findsOneWidget);
      expect(find.text('Villa 12'), findsOneWidget);
      expect(find.text('كمبوند الربوة'), findsOneWidget);
      expect(find.text('الشيخ زايد'), findsOneWidget);
      expect(find.text('سارة خالد الدسوقي'), findsOneWidget);
      expect(find.text('+201123456789'), findsOneWidget);
      expect(find.text('sara.desouky@gmail.com'), findsOneWidget);
      expect(find.text('55000'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('Renders properly in English and UAE context', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(locale: const Locale('en'), country: 'AE'));
      await tester.pumpAndSettle();

      // Verify English labels and UAE defaults
      expect(find.text('Tenant Details'), findsOneWidget);
      expect(find.text('District / Area'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Grace Period'), findsOneWidget);
      expect(find.text('Issue & Authenticate Invoice'), findsOneWidget);

      expect(find.text('Luxury Marina View 2BR'), findsOneWidget);
      expect(find.text('AE-2026-DXB-9042'), findsOneWidget);
      expect(find.text('Alexander Wright'), findsOneWidget);
      expect(find.text('+971501234567'), findsOneWidget);
    });

    testWidgets('Renders properly in Hindi locale', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(locale: const Locale('hi'), country: 'EG'));
      await tester.pumpAndSettle();

      expect(find.text('किरायेदार का विवरण'), findsOneWidget);
      expect(find.text('जिला / क्षेत्र'), findsOneWidget);
      expect(find.text('फ़ोन नंबर'), findsOneWidget);
      expect(find.text('ईमेल पता'), findsOneWidget);
      expect(find.text('रियायत अवधि'), findsOneWidget);
      expect(find.text('चालान जारी और प्रमाणित करें'), findsOneWidget);
    });
  });
}
