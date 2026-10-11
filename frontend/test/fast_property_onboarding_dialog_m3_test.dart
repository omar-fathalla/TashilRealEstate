import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/fast_property_onboarding_dialog.dart';

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
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
    ),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDraft = FastPropertyDraft(
    countryCode: 'EG',
    currency: 'EGP',
    city: 'الساحل الشمالي',
    district: 'سيدي عبد الرحمن',
    buildingName: 'قرية أمواج - سيدي عبد الرحمن',
    unitNumber: 'شاليه 104',
    monthlyRent: 25000,
    areaSqm: 140,
    bedrooms: 3,
    bathrooms: 2,
    propertyType: 'chalet',
    furnishingStatus: FurnishingStatus.fullyFurnished,
    titleAr: 'شاليه بحري صف أول - أمواج',
    descriptionAr: 'شاليه مفروش بالكامل صف أول على البحر واللاجون، 140م²، 3 غرف نوم.',
    photoUrls: [
      'https://example.com/photo1.jpg',
      'https://example.com/photo2.jpg',
      'https://example.com/photo3.jpg',
    ],
  );

  setUp(() {
    LocaleController.setLanguage('ar');
  });

  group('FastPropertyOnboardingDialog M3 Design Standards Tests', () {
    testWidgets('Renders M3 Connected Button Groups, shaded close button, and generalized unit label', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FastPropertyOnboardingDialog.show(
                context,
                initialDraft: testDraft,
                existingPropertyId: 'prop-edit-1',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header title in editing mode
      expect(find.text('تعديل بيانات الإعلان'), findsOneWidget);

      // Verify M3 shaded close button is present in the dialog
      expect(find.byType(TashilIconButton), findsWidgets);

      // Verify generalized unit label (no restriction to "شقة")
      expect(find.textContaining('رقم الوحدة العقارية'), findsOneWidget);

      // Verify Connected Button Group for Furnishing Status
      expect(find.byType(TashilConnectedButtonGroup<FurnishingStatus>), findsOneWidget);
      expect(find.text('مفروش بالكامل'), findsOneWidget);
      expect(find.text('نصف مفروش'), findsOneWidget);
      expect(find.text('غير مفروش'), findsOneWidget);

      // Verify Connected Button Group in Footer with cancel & save segments
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('حفظ التعديلات'), findsOneWidget);
    });

    testWidgets('Clicking cancel segment closes the onboarding dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FastPropertyOnboardingDialog.show(
                context,
                initialDraft: testDraft,
                existingPropertyId: 'prop-edit-1',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FastPropertyOnboardingDialog), findsOneWidget);

      // Tap the cancel segment in the footer
      await tester.tap(find.text('إلغاء'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FastPropertyOnboardingDialog), findsNothing);
    });
  });
}
