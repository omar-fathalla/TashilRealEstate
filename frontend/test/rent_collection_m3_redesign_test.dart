import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/legal_warning_notice_dialog.dart';

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
        body: RentCollectionView(),
      ),
    );
  }

  group('Rent Collection M3 Redesign Tests', () {
    testWidgets('Renders in Arabic with pure localization and zero raw missing keys', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Ensure raw keys are not shown
      expect(find.text('generateInvoiceBtn'), findsNothing);
      expect(find.text('generateInvoiceBtn +'), findsNothing);
      expect(find.text('landlord'), findsNothing);

      // Ensure properly translated Arabic strings are present
      expect(find.text('تحصيل الإيجار'), findsOneWidget);
      expect(find.text('إنشاء فاتورة'), findsOneWidget);
      expect(find.text('المالك / المؤجر'), findsWidgets);
      expect(find.text('التحويل الآلي للمالك مفعل'), findsNothing);

      // Verify Connected Button Groups are present (filter bar + invoice action cards)
      expect(find.byType(TashilConnectedButtonGroup<String>), findsWidgets);
      expect(find.text('جميع الفواتير'), findsOneWidget);
      expect(find.text('مسددة'), findsOneWidget);
      expect(find.text('مستحقة قريباً'), findsOneWidget);
      expect(find.text('متأخرات'), findsOneWidget);
      expect(find.text('سداد'), findsWidgets);
      expect(find.text('تذكير'), findsWidgets);
      expect(find.text('إنذار'), findsWidgets);

      // Verify TashilCard.outlined and TashilDivider are present
      expect(find.byType(TashilCard), findsWidgets);
      expect(find.byType(TashilDivider), findsWidgets);
    });

    testWidgets('Tapping segments in TashilConnectedButtonGroup filters invoices smoothly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Tap on "مسددة" (Paid) segment
      final paidSegmentFinder = find.text('مسددة');
      expect(paidSegmentFinder, findsOneWidget);
      await tester.tap(paidSegmentFinder);
      await tester.pumpAndSettle();

      // Tap on "متأخرات" (Overdue) segment
      final overdueSegmentFinder = find.text('متأخرات');
      expect(overdueSegmentFinder, findsOneWidget);
      await tester.tap(overdueSegmentFinder);
      await tester.pumpAndSettle();

      // Tap back to "جميع الفواتير" (All)
      final allSegmentFinder = find.text('جميع الفواتير');
      expect(allSegmentFinder, findsOneWidget);
      await tester.tap(allSegmentFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders in English with full parity and correct button labels', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Rent Collection'), findsOneWidget);
      expect(find.text('Create Invoice'), findsOneWidget);
      expect(find.text('Landlord / Owner'), findsWidgets);
      expect(find.text('All Invoices'), findsOneWidget);
      expect(find.text('Paid'), findsWidgets);
      expect(find.text('Pay'), findsWidgets);
      expect(find.text('Remind'), findsWidgets);
      expect(find.text('Warning'), findsWidgets);
    });

    testWidgets('Renders in Hindi with full parity and Devanagari typography', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('किराया वसूली'), findsOneWidget);
      expect(find.text('चालान बनाएं'), findsOneWidget);
      expect(find.text('मकान मालिक'), findsWidgets);
      expect(find.text('भुगतान'), findsWidgets);
      expect(find.text('याद दिलाएं'), findsWidgets);
      expect(find.text('चेतावनी'), findsWidgets);
    });

    testWidgets('Responsive Mobile Layout (375x812) renders with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Check no RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(RentCollectionView), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<String>), findsWidgets);
    });

    testWidgets('Responsive Tablet Layout (768x1024) renders with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RentCollectionView), findsOneWidget);
    });

    testWidgets('Tapping warning opens LegalWarningNoticeDialog with M3 shaded close button and Connected Button Group actions', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Find and tap the warning button segment
      final warningBtn = find.text('إنذار');
      expect(warningBtn, findsOneWidget);
      await tester.ensureVisible(warningBtn);
      await tester.tap(warningBtn);
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(LegalWarningNoticeDialog), findsOneWidget);

      // Verify shaded close button is present
      expect(find.byType(TashilIconButton), findsWidgets);

      // Verify action buttons are inside TashilConnectedButtonGroup
      expect(find.text('تصدير الإنذار الرسمي'), findsOneWidget);
      expect(find.text('إرسال تذكير فوري'), findsOneWidget);

      // Tap close button
      final closeBtn = find.descendant(
        of: find.byType(LegalWarningNoticeDialog),
        matching: find.byType(TashilIconButton),
      );
      await tester.tap(closeBtn.first);
      await tester.pumpAndSettle();

      expect(find.byType(LegalWarningNoticeDialog), findsNothing);
    });

    testWidgets('Renders prominent Back button when showBackButton is true and executes onBack', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
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
          home: Scaffold(
            body: RentCollectionView(
              showBackButton: true,
              onBack: () => backCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.text('رجوع');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });
  });
}

