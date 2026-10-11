import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/sliders/tashil_slider.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_builder_wizard_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({Locale locale = const Locale('ar'), String country = 'EG'}) {
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
        body: LeaseBuilderWizardDialog(),
      ),
    );
  }

  group('LeaseBuilderWizardDialog M3 Redesign & LTR Numbers Tests', () {
    testWidgets('Header uses TashilConnectedButtonGroup for Country & TashilIconButton.close for dismiss', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify Dialog Title
      expect(find.text('منشئ العقود الرقمية'), findsOneWidget);

      // Verify Official TashilConnectedButtonGroup is used for Country Switcher
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.text('مصر'), findsOneWidget);
      expect(find.text('الإمارات'), findsOneWidget);

      // Verify Shaded Close Button is present
      expect(find.byType(TashilIconButton), findsWidgets);
      final closeButtonFinder = find.byWidgetPredicate(
        (widget) => widget is TashilIconButton && widget.variant == TashilIconButtonVariant.close,
      );
      expect(closeButtonFinder, findsOneWidget);

      // Verify full-width divider under stepper
      expect(find.byType(TashilDivider), findsWidgets);
    });

    testWidgets('Step 1: All Phone Numbers, National IDs, and Codes enforce strict LTR directionality', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify Pure Arabic Party Titles (no mixed english parentheses)
      expect(find.text('الطرف الأول: المؤجر'), findsOneWidget);
      expect(find.text('الطرف الثاني: المستأجر'), findsOneWidget);
      expect(find.text('مسح ضوئي ذكي لبطاقة المؤجر'), findsOneWidget);
      expect(find.text('مسح ضوئي ذكي لبطاقة المستأجر'), findsOneWidget);

      // Verify zero (AI OCR) language mixing in Arabic
      expect(find.textContaining('(AI OCR)'), findsNothing);

      // Find all TextFields
      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, greaterThanOrEqualTo(8));

      // Check Lessor National ID & Phone fields (index 1 & 2)
      final lessorIdField = textFields[1];
      final lessorPhoneField = textFields[2];

      expect(lessorIdField.textDirection, TextDirection.ltr, reason: 'National ID must be LTR');
      expect(lessorIdField.textAlign, TextAlign.left);

      expect(lessorPhoneField.textDirection, TextDirection.ltr, reason: 'Phone must be LTR');
      expect(lessorPhoneField.textAlign, TextAlign.left);
      expect(lessorPhoneField.keyboardType, TextInputType.phone);
      expect(lessorPhoneField.controller?.text.startsWith('+'), isTrue);

      // Check Tenant National ID & Phone fields (index 6 & 7)
      final tenantIdField = textFields[6];
      final tenantPhoneField = textFields[7];

      expect(tenantIdField.textDirection, TextDirection.ltr, reason: 'Tenant ID must be LTR');
      expect(tenantIdField.textAlign, TextAlign.left);

      expect(tenantPhoneField.textDirection, TextDirection.ltr, reason: 'Tenant Phone must be LTR');
      expect(tenantPhoneField.textAlign, TextAlign.left);
      expect(tenantPhoneField.keyboardType, TextInputType.phone);
      expect(tenantPhoneField.controller?.text.startsWith('+'), isTrue);
    });

    testWidgets('Step 2: Property Codes (Unit, Area, Makani, DEWA, Title Deed) are strictly LTR', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Navigate to Step 2 (بيانات العقار)
      final nextStepBtn = find.text('الخطوة التالية');
      expect(nextStepBtn, findsOneWidget);
      await tester.tap(nextStepBtn);
      await tester.pumpAndSettle();

      // Verify Step 2 banner
      expect(find.text('مواصفات العين المؤجرة ومحدداتها'), findsOneWidget);
      expect(find.text('مسح ضوئي ذكي لصك الملكية'), findsOneWidget);

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();

      // Unit Number field (index 1)
      final unitField = textFields[1];
      expect(unitField.textDirection, TextDirection.ltr, reason: 'Unit number must be LTR');
      expect(unitField.textAlign, TextAlign.left);

      // Area sqm field (index 5)
      final areaField = textFields[5];
      expect(areaField.textDirection, TextDirection.ltr, reason: 'Area must be LTR');
      expect(areaField.keyboardType, TextInputType.number);

      // Title deed number field (last index)
      final deedField = textFields.last;
      expect(deedField.textDirection, TextDirection.ltr, reason: 'Title Deed number must be LTR');
      expect(deedField.textAlign, TextAlign.left);
    });

    testWidgets('Step 3: Financials features TashilConnectedButtonGroup for frequency & cheques and TashilSlider', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Navigate to Step 3 (الشروط المالية)
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();

      // Verify Step 3 banner
      expect(find.text('الشروط المالية وجدول سداد الإيجار'), findsOneWidget);

      // Verify Rent and Deposit amounts are LTR
      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      final rentField = textFields[0];
      final depositField = textFields[1];
      expect(rentField.textDirection, TextDirection.ltr);
      expect(depositField.textDirection, TextDirection.ltr);

      // Verify TashilConnectedButtonGroup for Payment Frequency & Cheques
      expect(find.byType(TashilConnectedButtonGroup<String>), findsWidgets);
      expect(find.byType(TashilConnectedButtonGroup<int>), findsOneWidget);

      // Verify Official M3 TashilSlider for annual escalation
      expect(find.byType(TashilSlider), findsOneWidget);
      expect(find.byType(Slider), findsNothing, reason: 'Raw Flutter Slider must be replaced by TashilSlider');
    });

    testWidgets('Step 4: Legal Clauses uses TashilSwitchListTile for M3 compliant clause switches', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Navigate to Step 4 (البنود القانونية)
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();

      // Verify Step 4 banner
      expect(find.text('البنود والاشتراطات القانونية المعتمدة'), findsOneWidget);

      // Verify TashilSwitchListTile is used
      expect(find.byType(TashilSwitchListTile), findsWidgets);
      expect(find.byType(CheckboxListTile), findsNothing, reason: 'Raw CheckboxListTile replaced with TashilSwitchListTile');

      // Verify AI Legal Advisor CTA banner
      expect(find.text('المستشار القانوني العقاري الذكي'), findsOneWidget);
    });

    testWidgets('Country switching between EG and AE updates defaults and labels dynamically', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Initial country is EG: shows nationalId label
      expect(find.text('الرقم القومي (14 رقماً)'), findsWidgets);

      // Tap on UAE segment in header
      final uaeSegment = find.text('الإمارات');
      expect(uaeSegment, findsOneWidget);
      await tester.tap(uaeSegment);
      await tester.pumpAndSettle();

      // Now shows Emirates ID label
      expect(find.text('رقم الهوية الإماراتية'), findsWidgets);
    });

    testWidgets('Step 5 & Global: Zero raw translation keys, zero Gemini RAG mixing, and pure LTR phone numbers', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Step 1: Verify no raw keys in Step 1
      expect(find.text('nationality'), findsNothing);

      // Step 2: Navigate to Step 2
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();

      // Verify buildingName and districtCity are localized in Arabic, NOT raw keys
      expect(find.text('buildingName'), findsNothing);
      expect(find.text('districtCity'), findsNothing);
      expect(find.text('اسم المبنى / العقار'), findsOneWidget);
      expect(find.text('الحي / المنطقة'), findsOneWidget);

      // Step 3: Navigate to Step 3
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();

      // Step 4: Navigate to Step 4
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();

      // Verify AI CTA has zero Gemini RAG mixing
      expect(find.textContaining('Gemini RAG'), findsNothing);
      expect(find.text('تدقيق البند بالذكاء الاصطناعي'), findsOneWidget);

      // Step 5: Navigate to Step 5 (المعاينة والتوثيق)
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();

      // Verify certificate elements in Step 5
      expect(find.text('عقد إيجار سكني خاضع لأحكام القانون رقم 4 لسنة 1996'), findsOneWidget);
      expect(find.textContaining('الجنسية'), findsWidgets);
      expect(find.text('مصري'), findsWidgets);
      expect(find.text('nationality'), findsNothing);
      expect(find.text('buildingName'), findsNothing);
      expect(find.text('districtCity'), findsNothing);
      expect(find.textContaining('/ month'), findsNothing);
      expect(find.textContaining('cheques 12'), findsNothing);

      // Verify LTR phone numbers present with + prefix
      expect(find.textContaining('+201002345678'), findsWidgets);
      expect(find.textContaining('+201145678901'), findsWidgets);

      // Verify M3 Action buttons and Finish button
      expect(find.text('تصدير PDF'), findsOneWidget);
      expect(find.text('اعتماد وحفظ العقد الرقمي'), findsOneWidget);
    });

    testWidgets('Mobile view: Header moves title down without overflow and AI Legal Advisor renders in 3 coordinated lines', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify title is rendered cleanly
      expect(find.text('منشئ العقود الرقمية'), findsOneWidget);

      // Navigate to Step 4
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الخطوة التالية'));
      await tester.pumpAndSettle();

      // Verify AI Legal Advisor components on mobile
      expect(find.text('المستشار القانوني العقاري الذكي'), findsOneWidget);
      expect(find.text('تدقيق وصياغة البنود التعاقدية ومطابقتها لقوانين الإيجار بالذكاء الاصطناعي'), findsOneWidget);
      expect(find.text('تدقيق البند بالذكاء الاصطناعي'), findsOneWidget);

      // Verify no exceptions or overflows caught by widgets library
      expect(tester.takeException(), isNull);
    });
  });
}
