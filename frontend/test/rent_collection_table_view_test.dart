import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';

void main() {
  Widget buildTestApp({Locale locale = const Locale('ar')}) {
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
        ),
      ),
      home: const Scaffold(
        body: RentCollectionView(),
      ),
    );
  }

  group('Rent Collection M3 Table View & Details Modal Tests', () {
    testWidgets('Defaults to Table View with all required columns in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify Table View widget is rendered
      expect(find.byType(DataTable), findsOneWidget);

      // Verify Column Headers
      expect(find.text('الوحدة ورقم الفاتورة'), findsOneWidget);
      expect(find.text('المستأجر'), findsOneWidget);
      expect(find.text('المالك / المؤجر'), findsWidgets);
      expect(find.text('تاريخ الاستحقاق'), findsOneWidget);
      expect(find.text('القيمة الإجمالية'), findsOneWidget);
      expect(find.text('حالة السداد'), findsOneWidget);
      expect(find.text('التحويل للمالك'), findsOneWidget);
      expect(find.text('السداد والتذكير'), findsOneWidget);
      expect(find.text('الإجراءات'), findsWidgets);

      // Verify view mode switcher buttons
      expect(find.text('عرض الجدول'), findsOneWidget);
      expect(find.text('عرض البطاقات'), findsOneWidget);
    });

    testWidgets('Tapping view mode switcher toggles to Cards and back to Table smoothly', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Initially in Table View
      expect(find.byType(DataTable), findsOneWidget);

      // Switch to Cards View
      final cardsBtn = find.text('عرض البطاقات');
      expect(cardsBtn, findsOneWidget);
      await tester.tap(cardsBtn);
      await tester.pumpAndSettle();

      // DataTable is replaced by cards
      expect(find.byType(DataTable), findsNothing);

      // Switch back to Table View
      final tableBtn = find.text('عرض الجدول');
      expect(tableBtn, findsOneWidget);
      await tester.tap(tableBtn);
      await tester.pumpAndSettle();

      // DataTable is back
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('Tapping Details opens comprehensive M3 Invoice Details Modal', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Find "عرض التفاصيل" button in the table by tooltip
      final detailsBtn = find.byTooltip('عرض التفاصيل');
      expect(detailsBtn, findsWidgets);

      await tester.ensureVisible(detailsBtn.first);
      await tester.tap(detailsBtn.first);
      await tester.pumpAndSettle();

      // Verify modal is open with details
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('تفاصيل المعاملة المالية والتحويل'), findsOneWidget);
      expect(find.text('قيمة الإيجار الأساسية'), findsOneWidget);
      expect(find.text('صافي التحويل البنكي للمالك'), findsOneWidget);

      // Verify close button dismisses modal
      final closeBtn = find.byType(TashilIconButton);
      expect(closeBtn, findsWidgets);
      await tester.tap(closeBtn.last);
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل المعاملة المالية والتحويل'), findsNothing);
    });

    testWidgets('Table renders cleanly in English and Hindi', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        LocaleController.setLocale(const Locale('ar'));
      });

      // Test English
      await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Table View'), findsOneWidget);
      expect(find.text('Cards View'), findsOneWidget);
      expect(find.text('Unit & Invoice No.'), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Payment & Reminder'), findsOneWidget);
      expect(find.text('Actions'), findsWidgets);

      // Test Hindi
      await tester.pumpWidget(buildTestApp(locale: const Locale('hi')));
      await tester.pumpAndSettle();
      expect(find.text('तालिका दृश्य'), findsOneWidget);
      expect(find.text('कार्ड दृश्य'), findsOneWidget);
      expect(find.text('इकाई और चालान संख्या'), findsOneWidget);
      expect(find.text('भुगतान स्थिति'), findsOneWidget);
      expect(find.text('भुगतान और स्मरण'), findsOneWidget);
      expect(find.text('कार्रवाई'), findsWidgets);
    });

    testWidgets('Header does not show Trash button by default', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Trash button is not in header by default
      expect(find.byIcon(Icons.auto_delete_outlined), findsNothing);
      expect(find.text('إنشاء فاتورة'), findsOneWidget);
    });

    testWidgets('Tapping WhatsApp reminder opens confirmation dialog with Connected Button Group and sends on confirm', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Find first 'تذكير' button in the table
      final remindBtn = find.text('تذكير');
      expect(remindBtn, findsWidgets);

      await tester.ensureVisible(remindBtn.first);
      await tester.tap(remindBtn.first);
      await tester.pumpAndSettle();

      // Confirmation dialog should be shown
      expect(find.text('تأكيد إرسال التذكير عبر واتساب'), findsOneWidget);
      expect(find.text('هل ترغب في إرسال إشعار تذكير بالسداد للمستأجر عبر تطبيق واتساب؟'), findsOneWidget);

      // Connected Button Group in dialog actions: 'إلغاء' and 'إرسال التذكير'
      expect(find.text('إلغاء'), findsOneWidget);
      final confirmSendBtn = find.text('إرسال التذكير');
      expect(confirmSendBtn, findsOneWidget);

      // Tap confirm
      await tester.tap(confirmSendBtn);
      await tester.pumpAndSettle();

      // Dialog is dismissed and success snackbar appears
      expect(find.text('تأكيد إرسال التذكير عبر واتساب'), findsNothing);
      expect(find.text('تم إرسال التذكير الذكي بنجاح للمستأجر عبر واتساب والرسائل القصيرة'), findsOneWidget);
    });
  });
}

