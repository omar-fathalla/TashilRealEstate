import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button_group.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/fast_onboarding/fast_onboarding_screen.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/fast_onboarding/services/gemini_onboarding_service.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/voice_property_input_modal.dart';

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
      home: child,
    );
  }

  group('FastOnboardingScreen M3 Redesign Tests', () {
    testWidgets('Renders all M3 components without layout overflows on tablet (720x1024)', (tester) async {
      tester.view.physicalSize = const Size(720, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const FastOnboardingScreen()));
      await tester.pumpAndSettle();

      // Verify zero layout overflows
      expect(tester.takeException(), isNull);

      // Verify M3 Outlined Cards are used for form sections
      expect(find.byType(TashilCard), findsWidgets);

      // Verify TashilConnectedButtonGroup is used for PaymentFrequency, BuildingAge, and FurnishingStatus
      expect(find.byType(TashilConnectedButtonGroup<PaymentFrequency>), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<BuildingAge>), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<FurnishingStatus>), findsOneWidget);

      // Verify TashilSwitchListTile is used for boolean toggles
      expect(find.byType(TashilSwitchListTile), findsWidgets);

      // Verify TashilFilterChip is used for amenities
      expect(find.byType(TashilFilterChip), findsWidgets);

      // Verify NO emojis in section headers (clean numbers and Google icons used)
      expect(find.textContaining('📍 1'), findsNothing);
      expect(find.textContaining('💰 2'), findsNothing);
      expect(find.textContaining('🏠 3'), findsNothing);
      expect(find.textContaining('✨ 4'), findsNothing);
      expect(find.textContaining('🖼️ 📝 5'), findsNothing);
    });

    testWidgets('Renders without layout overflows on mobile (390x844)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const FastOnboardingScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Interacting with TashilConnectedButtonGroup updates selection', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const FastOnboardingScreen()));
      await tester.pumpAndSettle();

      // Find the payment frequency button group and tap quarterly
      final quarterlyFinder = find.text('ربع سنوي (4 دفعات / شيكات)');
      expect(quarterlyFinder, findsOneWidget);

      await tester.tap(quarterlyFinder);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Interacting with TashilDropdownMenu updates property type', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const FastOnboardingScreen()));
      await tester.pumpAndSettle();

      // Scroll until dropdown is visible
      await tester.ensureVisible(find.byType(TashilDropdownMenu<String>));
      await tester.pumpAndSettle();

      // Find the property type dropdown menu (initially 'شقة سكنية')
      expect(find.byType(TashilDropdownMenu<String>), findsOneWidget);
      expect(find.text('شقة سكنية'), findsOneWidget);

      // Tap on the dropdown menu to open it
      await tester.tap(find.byType(TashilDropdownMenu<String>));
      await tester.pumpAndSettle();

      // Find the villa option in the opened menu overlay and tap it
      final villaOption = find.text('فيلا مستقلة');
      expect(villaOption, findsWidgets);
      await tester.tap(villaOption.last);
      await tester.pumpAndSettle();

      // Verify that 'فيلا مستقلة' is now selected and displayed in the dropdown
      expect(find.text('فيلا مستقلة'), findsOneWidget);
    });

    test('Amenities default to false in FastPropertyDraft', () {
      final draft = FastPropertyDraft();
      expect(draft.hasParking, isFalse);
      expect(draft.hasCentralAc, isFalse);
      expect(draft.hasPoolGym, isFalse);
      expect(draft.hasSecurity, isFalse);
      expect(draft.hasBalconyView, isFalse);
      expect(draft.isPetFriendly, isFalse);
    });

    test('Gemini copywriting fallback respects unselected amenities', () async {
      final draft = FastPropertyDraft(
        city: 'الإسكندرية',
        district: 'مدورة',
        monthlyRent: 3000,
        currency: 'EGP',
        furnishingStatus: FurnishingStatus.unfurnished,
        hasParking: false,
        hasCentralAc: false,
        hasPoolGym: false,
        hasSecurity: false,
        hasBalconyView: false,
        isPetFriendly: false,
      );

      final service = GeminiOnboardingService();
      final result = await service.generateMarketingDescriptions(
        draft: draft,
        tone: PropertyMarketingTone.luxuryExecutive,
      );

      final descAr = result['ar'] ?? '';
      expect(descAr.contains('موقف سيارات خاص'), isFalse);
      expect(descAr.contains('تكييف مركزي'), isFalse);
      expect(descAr.contains('شرفة'), isFalse);
      expect(descAr.contains('أمن وحراسة'), isFalse);
      expect(descAr.contains('مسبح'), isFalse);
      expect(descAr.contains('الحيوانات الأليفة'), isFalse);
    });

    test('Gemini copywriting fallback includes only selected amenities', () async {
      final draft = FastPropertyDraft(
        city: 'الإسكندرية',
        district: 'مدورة',
        monthlyRent: 3000,
        currency: 'EGP',
        furnishingStatus: FurnishingStatus.unfurnished,
        hasParking: true,
        hasCentralAc: false,
        hasPoolGym: false,
        hasSecurity: false,
        hasBalconyView: true,
        isPetFriendly: false,
      );

      final service = GeminiOnboardingService();
      final result = await service.generateMarketingDescriptions(
        draft: draft,
        tone: PropertyMarketingTone.luxuryExecutive,
      );

      final descAr = result['ar'] ?? '';
      expect(descAr.contains('موقف سيارات خاص'), isTrue);
      expect(descAr.contains('شرفة بإطلالة مفتوحة'), isTrue);
      expect(descAr.contains('تكييف مركزي'), isFalse);
      expect(descAr.contains('أمن وحراسة'), isFalse);
      expect(descAr.contains('مسبح'), isFalse);
      expect(descAr.contains('الحيوانات الأليفة'), isFalse);
    });

    test('Accurate Alexandria Bahari voice parsing with 2 bedrooms, 1 bathroom, and 5000 rent', () {
      final service = GeminiOnboardingService();
      const transcription = 'فرصة سكنية استثنائية في 37 شارع الجمرك القديم منطقة اسكندرية بحري. '
          'شقة مصممة بعناية فائقة بمساحة 90 متر مربع، تضم 2 غرفة و1 حمام مع تشطيب فاخر سوبر لوكس. '
          'الوحدة غير مفروشة وجاهزة للانتقال الفوري. '
          'القيمة الإيجارية الشهرية: 5000 جنيه شهرياً (قابلة للتفاوض البسيط).';

      final draft = service.parseVoiceHeuristically(transcription, 'EG');

      expect(draft.city, equals('الإسكندرية'));
      expect(draft.district, equals('بحري'));
      expect(draft.streetAddress, contains('37 شارع الجمرك القديم'));
      expect(draft.buildingName ?? '', isNot(contains('37 شارع')));
      expect(draft.areaSqm, equals(90));
      expect(draft.bedrooms, equals(2));
      expect(draft.bathrooms, equals(1));
      expect(draft.monthlyRent, equals(5000));
      expect(draft.furnishingStatus, equals(FurnishingStatus.unfurnished));
      expect(draft.isNegotiable, isTrue);
    });

    test('Accurate parsing with Eastern Arabic digits and colloquial phrasing', () {
      final service = GeminiOnboardingService();
      const transcription = 'شقة ٩٠ متر، غرفتين وحمام واحد، إيجار شهري ٥٠٠٠ ج.م في بحري الإسكندرية، غير مفروشة';

      final draft = service.parseVoiceHeuristically(transcription, 'EG');

      expect(draft.city, equals('الإسكندرية'));
      expect(draft.district, equals('بحري'));
      expect(draft.areaSqm, equals(90));
      expect(draft.bedrooms, equals(2));
      expect(draft.bathrooms, equals(1));
      expect(draft.monthlyRent, equals(5000));
      expect(draft.furnishingStatus, equals(FurnishingStatus.unfurnished));
    });

    testWidgets('VoicePropertyInputModal renders with guidance and displays missing field warning on incomplete input', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const Scaffold(body: VoicePropertyInputModal())));
      await tester.pumpAndSettle();

      // Verify header and shaded close button exist
      expect(find.byType(VoicePropertyInputModal), findsOneWidget);
      expect(find.text('إرشادات الحقول المطلوبة لعرض وحدة للإيجار'), findsOneWidget);

      // Verify mandatory progress capsule exists
      expect(find.textContaining('المعايير الإجبارية'), findsOneWidget);

      // Enter incomplete input (only area and location, without rent, beds, baths)
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'شقة 90 متر في بحري الإسكندرية');
      await tester.pumpAndSettle();

      // Tap Parse & Auto-fill button
      final parseButtonFinder = find.text('استخراج المواصفات وملء الحقول بالذكاء الاصطناعي');
      expect(parseButtonFinder, findsOneWidget);
      await tester.tap(parseButtonFinder);
      await tester.pumpAndSettle();

      // Verify that the missing mandatory warning card is displayed
      expect(find.text('تنبيه: حقول إجبارية غير مكتملة في الصوت'), findsOneWidget);
      expect(find.text('انطق البيانات الناقصة بالصوت الآن'), findsOneWidget);
      expect(find.text('المتابعة وتعبئتها يدوياً في النموذج'), findsOneWidget);
    });

    test('Accurate extraction of unitNumber and buildingName without pollution', () {
      final service = GeminiOnboardingService();
      const transcription = 'عندي وحدة 304 في برج الصفوة 37 شارع الجمرك القديم بحري الإسكندرية مساحة 120 متر 3 غرف وحمامين إيجار 8000';
      final draft = service.parseVoiceHeuristically(transcription, 'EG');

      expect(draft.unitNumber, equals('304'));
      expect(draft.buildingName, equals('برج الصفوة'));
      expect(draft.streetAddress, contains('37 شارع الجمرك القديم'));
      expect(draft.city, equals('الإسكندرية'));
      expect(draft.district, equals('بحري'));
      expect(draft.areaSqm, equals(120));
      expect(draft.bedrooms, equals(3));
      expect(draft.bathrooms, equals(2));
      expect(draft.monthlyRent, equals(8000));
    });

    testWidgets('VoicePropertyInputModal guidance removes location/rent/area/building chips and preserves bedrooms/bathrooms', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const Scaffold(body: VoicePropertyInputModal())));
      await tester.pumpAndSettle();

      // Verify NO chips for Location, Rent, Area, Building
      expect(find.text('بحري، الإسكندرية'), findsNothing);
      expect(find.text('إيجار 5,000 ج.م'), findsNothing);
      expect(find.text('شقة 90 متر'), findsNothing);
      expect(find.text('37 شارع الجمرك القديم'), findsNothing);
      expect(find.text('كمبوند هايد بارك'), findsNothing);

      // Verify chips ARE preserved for Bedrooms and Bathrooms
      expect(find.text('غرفتين نوم'), findsOneWidget);
      expect(find.text('2 حمام'), findsOneWidget);
    });
  });
}
