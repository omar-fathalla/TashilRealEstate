import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/gemini_ai_service.dart';
import 'package:tashil_real_estate/features/smart_valuation/models/smart_valuation_model.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import 'package:tashil_real_estate/features/smart_valuation/widgets/district_location_picker_dialog.dart';

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
      body: Center(
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocaleController.currentLocale.value = const Locale('ar');
  });

  group('Smart Valuation Model & Google Search Grounding Unit Tests', () {
    test('SmartValuationModel serializes and deserializes grounding fields correctly', () {
      final json = {
        'estimatedRent': 18500.0,
        'minRent': 16500.0,
        'maxRent': 20500.0,
        'pricePerSqm': 132.0,
        'confidenceScore': 96,
        'marketDemand': 'very_high',
        'marketAnalysis': 'طلب إيجاري متزايد في التجمع الخامس مع سرعة تأجير مرتفعة.',
        'isGrounded': true,
        'groundingSources': ['عقار ماب (Aqarmap)', 'Property Finder'],
        'searchQueries': ['شقق للايجار في التجمع الخامس 140 متر'],
        'comparableUnits': [
          {
            'title': 'شقة ممتازة بالتجمع الخامس - النرجس',
            'location': 'التجمع الخامس',
            'rentPrice': 18000.0,
            'areaSqm': 140,
            'sourcePortal': 'عقار ماب (Aqarmap)',
            'isVerified': true,
            'sourceUrl': 'https://www.google.com/search?q=aqarmap+tagamoa',
          },
          {
            'title': 'عقار حديث مجاور - كامل الخدمات',
            'location': 'التجمع الخامس',
            'rentPrice': 19000.0,
            'areaSqm': 150,
            'sourcePortal': 'Property Finder',
            'isVerified': true,
            'sourceUrl': 'https://www.google.com/search?q=propertyfinder+tagamoa',
          }
        ],
        'optimizationTips': ['فرش الوحدة بفرش فندقي حديث'],
      };

      final model = SmartValuationModel.fromJson(json, 'EGP', 'EG');

      expect(model.isGrounded, isTrue);
      expect(model.groundingSources, contains('عقار ماب (Aqarmap)'));
      expect(model.groundingSources, contains('Property Finder'));
      expect(model.searchQueries.first, contains('التجمع الخامس'));
      expect(model.comparableUnits.length, equals(2));
      expect(model.comparableUnits.first.sourcePortal, equals('عقار ماب (Aqarmap)'));
      expect(model.comparableUnits.first.isVerified, isTrue);
      expect(model.comparableUnits.first.sourceUrl, contains('google.com'));
    });

    test('GeminiAiService fallback generates verified grounded portal comps', () async {
      final service = GeminiAiService();
      final valuation = await service.estimateRentalValue(
        countryCode: 'EG',
        cityOrArea: 'التجمع الخامس',
        propertyType: 'apartment',
        areaSqm: 140,
        bedrooms: 2,
        bathrooms: 2,
        finishingType: 'luxury',
        isFurnished: true,
        specialAmenities: ['sea_view', 'parking'],
        langCode: 'ar',
      );

      expect(valuation.isGrounded, isTrue);
      expect(valuation.groundingSources, isNotEmpty);
      expect(valuation.comparableUnits, isNotEmpty);
      expect(valuation.comparableUnits.first.sourcePortal, isNotEmpty);
      expect(valuation.comparableUnits.first.isVerified, isTrue);
      expect(valuation.comparableUnits.first.sourceUrl, isNotNull);
      expect(valuation.searchQueries, isNotEmpty);
    });
  });

  group('DistrictLocationPickerDialog Interactive Tests', () {
    testWidgets('Renders all districts and filters by search query in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithApp(
          const DistrictLocationPickerDialog(
            countryCode: 'EG',
            currentDistrict: 'التجمع الخامس',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & GPS button presence
      expect(find.text('اختر الحي أو الكمبوند'), findsOneWidget);
      expect(find.text('خرائط Google والأحياء'), findsOneWidget);
      expect(find.text('تحديد موقعي عبر GPS'), findsOneWidget);

      // Verify popular Cairo districts exist in initial list
      expect(find.text('التجمع الخامس (القاهرة الجديدة)'), findsOneWidget);

      // Search for Zayed
      await tester.enterText(find.byType(TextField).first, 'زايد');
      await tester.pumpAndSettle();

      // Verify New Cairo filtered out and Sheikh Zayed appears
      expect(find.text('مدينة الشيخ زايد'), findsOneWidget);
      expect(find.text('التجمع الخامس (القاهرة الجديدة)'), findsNothing);

      // Tap on Sheikh Zayed to select
      await tester.tap(find.text('مدينة الشيخ زايد'));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders properly for UAE with Dubai & Abu Dhabi districts', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.currentLocale.value = const Locale('en');

      await tester.pumpWidget(
        wrapWithApp(
          const DistrictLocationPickerDialog(
            countryCode: 'AE',
            currentDistrict: 'Dubai Marina',
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose District or Compound'), findsOneWidget);
      expect(find.text('Dubai Marina'), findsOneWidget);
      expect(find.text('Downtown Dubai'), findsOneWidget);
      expect(find.text('Business Bay'), findsOneWidget);
    });
  });

  group('SmartValuationDialog Interactive Flow & Grounding UI Tests', () {
    testWidgets('Contains GPS button, Map Picker button, and popular quick district chips', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithApp(
          const SmartValuationDialog(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify GPS location icon button exists
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      // Verify Map picker icon button exists
      expect(find.byIcon(Icons.map_rounded), findsOneWidget);

      // Verify popular areas chips row exists
      expect(find.text('المناطق الأكثر طلباً:'), findsOneWidget);
      expect(find.text('الشيخ زايد'), findsOneWidget);
      expect(find.text('المعادي'), findsOneWidget);
      expect(find.text('مصر الجديدة'), findsOneWidget);

      // Tap on 'الشيخ زايد' chip to autofill city
      await tester.tap(find.text('الشيخ زايد'));
      await tester.pumpAndSettle();

      final cityField = tester.widget<TextField>(find.byType(TextField).first);
      expect(cityField.controller?.text, equals('الشيخ زايد'));
    });

    testWidgets('Completes valuation and displays Google Search Grounding badge with verified portal comps', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithApp(
          const SmartValuationDialog(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap calculate button "السعر بالذكاء الاصطناعي"
      final calculateBtn = find.text('السعر بالذكاء الاصطناعي');
      expect(calculateBtn, findsOneWidget);
      await tester.tap(calculateBtn);
      await tester.pump();

      // Wait for valuation to finish and result to appear
      await tester.pumpAndSettle();

      // Verify Result view headline and fair rent
      expect(find.text('السعر العادل المقترح شهرياً'), findsOneWidget);

      // Verify Google Search Grounding & Real Portals Verification Banner
      expect(find.text('تقييم مدعوم بالبحث المباشر في Google وبوابات العقارات'), findsOneWidget);
      expect(
        find.text('تمت مطابقة مواصفات شقتك مع إعلانات حقيقية معروضة حالياً في السوق الفعلي'),
        findsOneWidget,
      );

      // Verify neighbor comps with real portal tags (Aqarmap or Property Finder)
      expect(find.text('عقارات مقارنة في نفس الحي والمحيط'), findsOneWidget);
      expect(find.text('عقار ماب (Aqarmap)'), findsWidgets);
      expect(find.text('عرض الإعلان في المصدر'), findsWidgets);
    });

    testWidgets('Trilingual parity: English and Hindi display verified grounding titles', (tester) async {
      // English
      LocaleController.currentLocale.value = const Locale('en');
      final enLoc = AppLocalizations(const Locale('en'));
      expect(enLoc.tr('googleSearchGroundingTitle'), contains('Google Search'));
      expect(enLoc.tr('useCurrentGpsLocation'), contains('GPS'));
      expect(enLoc.tr('pickDistrictOrCompound'), contains('District'));

      // Hindi
      LocaleController.currentLocale.value = const Locale('hi');
      final hiLoc = AppLocalizations(const Locale('hi'));
      expect(hiLoc.tr('googleSearchGroundingTitle'), contains('गूगल खोज'));
      expect(hiLoc.tr('useCurrentGpsLocation'), contains('जीपीएस'));
      expect(hiLoc.tr('pickDistrictOrCompound'), contains('कंपाउंड'));
    });
  });
}
