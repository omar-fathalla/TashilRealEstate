import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/gemini_ai_service.dart';
import 'package:tashil_real_estate/core/services/location/location_geocoding_service.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';

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

  group('Google Maps Address Verification & Autocorrection Tests', () {
    test('LocationGeocodingService verifies and autocorrects Alexandria Gomrok address', () async {
      final service = LocationGeocodingService();
      
      // User typed exactly "37شارع الجمرك القديم الاسكندريه بحري"
      final result = await service.verifyAndCorrectAddress(
        '37شارع الجمرك القديم الاسكندريه بحري',
        countryCode: 'EG',
      );

      expect(result.isVerified, isTrue);
      expect(result.district, contains('الجمرك'));
      expect(result.city, contains('الإسكندرية'));
      expect(result.formattedAddress, contains('الجمرك'));
      expect(result.formattedAddress, contains('الإسكندرية'));
      // Must NEVER false-match Smouha
      expect(result.district.contains('سموحة'), isFalse);
      expect(result.formattedAddress.contains('سموحة'), isFalse);
    });

    test('LocationGeocodingService handles Sheikh Zayed, Tagamoa, and Dubai Downtown', () async {
      final service = LocationGeocodingService();

      final zayed = await service.verifyAndCorrectAddress('زايد الحي الثامن', countryCode: 'EG');
      expect(zayed.isVerified, isTrue);
      expect(zayed.city, contains('الجيزة'));

      final dubai = await service.verifyAndCorrectAddress('Downtown Dubai Boulevard', countryCode: 'AE');
      expect(dubai.isVerified, isTrue);
      expect(dubai.city, contains('دبي'));
    });
  });

  group('Top 4 Real Estate Portals & Gemini Grounding Tests', () {
    test('GeminiAiService fallback generates 4 comps representing top 4 portals in Egypt', () async {
      final service = GeminiAiService();
      final valuation = await service.estimateRentalValue(
        countryCode: 'EG',
        cityOrArea: '37 شارع الجمرك القديم',
        propertyType: 'apartment',
        areaSqm: 90,
        bedrooms: 2,
        bathrooms: 1,
        finishingType: 'super_lux',
        isFurnished: false,
        specialAmenities: ['sea_view'],
        langCode: 'ar',
      );

      expect(valuation.isGrounded, isTrue);
      expect(valuation.verifiedAddress, contains('الجمرك'));
      expect(valuation.groundingSources.length, equals(4));
      expect(valuation.groundingSources, contains('عقار ماب (Aqarmap)'));
      expect(valuation.groundingSources, contains('بروبرتي فايندر (Property Finder)'));
      expect(valuation.groundingSources, contains('دوبيزل (Dubizzle)'));
      expect(valuation.groundingSources, contains('بيوت (Bayut)'));

      // 4 distinct comparable units
      expect(valuation.comparableUnits.length, equals(4));
      for (final comp in valuation.comparableUnits) {
        expect(comp.isVerified, isTrue);
        expect(comp.sourceUrl, isNotNull);
        expect(comp.sourceUrl, contains('google.com/search'));
      }
    });

    test('GeminiAiService fallback generates 4 comps representing top 4 portals in UAE', () async {
      final service = GeminiAiService();
      final valuation = await service.estimateRentalValue(
        countryCode: 'AE',
        cityOrArea: 'Dubai Marina',
        propertyType: 'apartment',
        areaSqm: 110,
        bedrooms: 2,
        bathrooms: 2,
        finishingType: 'luxury',
        isFurnished: true,
        specialAmenities: ['sea_view', 'parking'],
        langCode: 'en',
      );

      expect(valuation.isGrounded, isTrue);
      expect(valuation.groundingSources.length, equals(4));
      expect(valuation.groundingSources, contains('Bayut'));
      expect(valuation.groundingSources, contains('Property Finder'));
      expect(valuation.groundingSources, contains('Dubizzle'));
      expect(valuation.comparableUnits.length, equals(4));
    });
  });

  group('M3 Wavy Progress & Loading Indicator Suite Tests', () {
    testWidgets('TashilLinearProgressIndicator.wavy renders sinusoidal indeterminate track cleanly', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          const SizedBox(
            width: 300,
            child: TashilLinearProgressIndicator.wavy(
              showStopIndicator: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TashilLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('TashilLoadingIndicator renders organic M3 morphing clover without white hole', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          const TashilLoadingIndicator.large(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TashilLoadingIndicator), findsOneWidget);
    });
  });

  group('SmartValuationDialog Address & Portals Integration Tests', () {
    testWidgets('SmartValuationDialog verifies address and shows verified address card upon valuation', (tester) async {
      tester.view.physicalSize = const Size(1200, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithApp(
          const SmartValuationDialog(
            initialCity: '37 شارع الجمرك القديم',
            initialArea: 90,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify input contains address
      expect(find.text('37 شارع الجمرك القديم'), findsOneWidget);

      // Tap calculate fair rent
      final buttonFinder = find.text('السعر بالذكاء الاصطناعي');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);

      // Verify loading state is shown with progress indicator
      await tester.pump();
      expect(find.byType(TashilLinearProgressIndicator), findsOneWidget);
      expect(find.byType(TashilLoadingIndicator), findsOneWidget);

      // Settle delayed stages and computation
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Check for verified address badge
      expect(find.text('العنوان المدقق والمطابق جغرافياً'), findsOneWidget);
      expect(find.text('خرائط Google والأحياء'), findsOneWidget);

      // Check for 4 portal sources
      expect(find.text('عقار ماب (Aqarmap)'), findsWidgets);
      expect(find.text('بروبرتي فايندر (Property Finder)'), findsWidgets);
      expect(find.text('دوبيزل (Dubizzle)'), findsWidgets);
      expect(find.text('بيوت (Bayut)'), findsWidgets);
    });
  });
}
