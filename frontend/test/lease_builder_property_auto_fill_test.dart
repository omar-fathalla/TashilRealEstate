import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_dropdown_menu.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/storage/local_storage_service.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_builder_wizard_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProperty = ManagedPropertyModel(
    id: 'prop-real-alex-500',
    countryCode: 'EG',
    currencyCode: 'EGP',
    titles: const {
      'ar': 'شقة فاخرة 90 م² في بحري، الإسكندرية',
      'en': 'Luxury 90m² Apartment in Bahary, Alexandria',
      'hi': 'बहरी, अलेक्जेंड्रिया में 90 वर्ग मीटर का लक्जरी अपार्टमेंट',
    },
    descriptions: const {
      'ar': 'شقة مميزة مطلة على البحر',
      'en': 'Sea view apartment',
      'hi': 'समुद्र दृश्य अपार्टमेंट',
    },
    locations: const {
      'ar': 'حي الجمرك - بحري، الإسكندرية',
      'en': 'Gomrok, Alexandria',
      'hi': 'गोमरोक, अलेक्जेंड्रिया',
    },
    cityCode: 'ALEX',
    propertyTypeCode: 'apartment',
    unitNumber: '3B',
    buildingName: 'برج البحر',
    pricePerMonth: 500.0,
    bedrooms: 2,
    bathrooms: 1,
    areaSqM: 90.0,
    image: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
    imageUrls: const ['https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800'],
    rentalStatus: PropertyRentalStatus.rented,
    tenantName: 'خالد أحمد حسن',
    tenantPhone: '+20 109 876 5432',
  );

  Widget createTestWidget({Locale locale = const Locale('ar')}) {
    LocaleController.setLocale(locale);
    CountryController.setCountry('EG');
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: LeaseBuilderWizardDialog(),
      ),
    );
  }

  setUp(() {
    LocalStorageService().setString('tashil_last_authenticated_owner_id', 'owner_alex_80800');
    PropertyLifecycleService().propertiesNotifier.value = [testProperty];
  });

  group('LeaseBuilderWizardDialog Property Dropdown & Auto-Fill Tests', () {
    testWidgets('Automatically pre-selects registered property and auto-fills all Step 2 fields in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Step 1: Parties -> Click 'الخطوة التالية' to move to Step 2 (Property)
      final nextBtn = find.text('الخطوة التالية');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Verify Step 2 is active
      expect(find.text('مواصفات العين المؤجرة ومحدداتها'), findsOneWidget);

      // Verify TashilDropdownMenu is rendered
      expect(find.byType(TashilDropdownMenu<String>), findsOneWidget);

      // Verify auto-fill banner is displayed
      expect(
        find.text('تم استيراد مواصفات العقار وبيانات الوحدة تلقائياً من محفظتك العقارية (يمكنك التعديل عليها)'),
        findsOneWidget,
      );

      // Verify all fields are auto-filled with real property data
      expect(find.text('شقة فاخرة 90 م² في بحري، الإسكندرية'), findsWidgets);
      expect(find.text('3B'), findsOneWidget);
      expect(find.text('برج البحر'), findsOneWidget);
      expect(find.text('حي الجمرك - بحري'), findsOneWidget);
      expect(find.text('الإسكندرية'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);

      // Move to Step 3: Financials
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Verify Step 3 Financials auto-fills rent from property (500 EGP/month)
      expect(find.text('500'), findsOneWidget);
      // Verify deposit auto-fills (1000 EGP = 2 months)
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('Renders with English localization and fills English property title and city', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Step 1 -> Next Step
      final nextBtn = find.text('Next Step');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Verify Step 2 English title
      expect(find.text('Leased Property Specifications & Location'), findsOneWidget);
      expect(find.byType(TashilDropdownMenu<String>), findsOneWidget);

      // Verify English property title and city
      expect(find.text('Luxury 90m² Apartment in Bahary, Alexandria'), findsWidgets);
      expect(find.text('Alexandria'), findsOneWidget);
    });

    testWidgets('Renders with Hindi localization and Devanagari property details', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      // Step 1 -> Next Step
      final nextBtn = find.text('अगला चरण');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Verify Step 2 Hindi title
      expect(find.text('पट्टे पर दी गई संपत्ति का विवरण और स्थान'), findsOneWidget);
      expect(find.byType(TashilDropdownMenu<String>), findsOneWidget);
      expect(find.text('बहरी, अलेक्जेंड्रिया में 90 वर्ग मीटर का लक्जरी अपार्टमेंट'), findsWidgets);
      expect(find.text('अलेक्जेंड्रिया'), findsOneWidget);
    });
  });
}
