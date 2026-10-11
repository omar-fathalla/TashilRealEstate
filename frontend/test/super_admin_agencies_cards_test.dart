import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_dashboard.dart';

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
        ),
      ),
      home: child,
    );
  }

  group('Super Admin Agencies & Subscribers 8-Cards Architecture Tests', () {
    testWidgets('Renders all 4 Top Metric Cards with unified M3 tokens and values', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard(initialIndex: 1)));
      await tester.pumpAndSettle();

      // Verify the 4 Top Metric Cards
      expect(find.text('48'), findsWidgets); // Active agencies metric
      expect(find.text('+12%'), findsOneWidget);

      expect(find.text('1,420'), findsWidgets); // Verified units metric
      expect(find.text('98.5%'), findsOneWidget);

      expect(find.text('142'), findsOneWidget); // Certified brokers metric
      expect(find.text('100%'), findsWidgets);

      expect(find.text('99.4%'), findsOneWidget); // Compliance rate metric
      expect(find.text('ISO 27001'), findsOneWidget);

      // Verify TashilConnectedButtonGroup component
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.text('كافة الوكالات'), findsOneWidget);
      expect(find.text('مصر'), findsOneWidget);
      expect(find.text('الإمارات'), findsOneWidget);

      // Verify the 4 Agency Cards exist
      expect(find.text('إعمار مصر للإدارة العقارية'), findsOneWidget);
      expect(find.text('الدار العقارية دبي'), findsOneWidget);
      expect(find.text('بالم هيلز للوساطة والتسويق'), findsOneWidget);
      expect(find.text('داماك العقارية أبوظبي'), findsOneWidget);
    });

    testWidgets('TashilConnectedButtonGroup filters agency cards by country accurately', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard(initialIndex: 1)));
      await tester.pumpAndSettle();

      // Tap Egypt Connected Button Segment
      final egFilterFinder = find.text('مصر');
      expect(egFilterFinder, findsOneWidget);
      await tester.tap(egFilterFinder);
      await tester.pumpAndSettle();

      // Only Egyptian agencies should be visible
      expect(find.text('إعمار مصر للإدارة العقارية'), findsOneWidget);
      expect(find.text('بالم هيلز للوساطة والتسويق'), findsOneWidget);
      expect(find.text('الدار العقارية دبي'), findsNothing);
      expect(find.text('داماك العقارية أبوظبي'), findsNothing);

      // Tap UAE Connected Button Segment
      final uaeFilterFinder = find.text('الإمارات');
      expect(uaeFilterFinder, findsOneWidget);
      await tester.tap(uaeFilterFinder);
      await tester.pumpAndSettle();

      // Only UAE agencies should be visible
      expect(find.text('الدار العقارية دبي'), findsOneWidget);
      expect(find.text('داماك العقارية أبوظبي'), findsOneWidget);
      expect(find.text('إعمار مصر للإدارة العقارية'), findsNothing);
      expect(find.text('بالم هيلز للوساطة والتسويق'), findsNothing);
    });

    testWidgets('Clicking addNewAgency opens TashilModalDialog with form fields and creates new agency', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard(initialIndex: 1)));
      await tester.pumpAndSettle();

      // Tap "إضافة وكالة جديدة"
      final addBtnFinder = find.widgetWithText(TashilButton, 'إضافة وكالة جديدة');
      expect(addBtnFinder, findsOneWidget);
      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      // Verify modal opened
      expect(find.text('تسجيل واعتماد وكالة وساطة عقارية جديدة في المنصة'), findsOneWidget);
      expect(find.text('اسم الوكالة العقارية'), findsOneWidget);
      expect(find.text('رقم السجل التجاري أو ترخيص الوساطة'), findsOneWidget);

      // Enter agency name
      await tester.enterText(find.widgetWithText(TextFormField, 'اسم الوكالة العقارية'), 'وكالة النيل العقارية الدولية');
      await tester.pumpAndSettle();

      // Tap submit button in dialog
      final submitBtn = find.widgetWithText(TashilButton, 'اعتماد وتسجيل الوكالة');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify agency was added to directory
      expect(find.text('وكالة النيل العقارية الدولية'), findsOneWidget);
    });

    testWidgets('Clicking viewAgencyDetails opens registry credentials dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard(initialIndex: 1)));
      await tester.pumpAndSettle();

      // Tap first "عرض السجل والتحقق"
      final viewRecordFinder = find.text('عرض السجل والتحقق').first;
      await tester.tap(viewRecordFinder);
      await tester.pumpAndSettle();

      // Verify registry dialog content
      expect(find.text('الجهة الرقابية المشرفة'), findsOneWidget);
      expect(find.text('مستوى الامتثال والرقابة'), findsOneWidget);
      expect(find.text('ISO 27001 / AML Tier 1'), findsOneWidget);

      // Close dialog
      final closeBtn = find.text('إغلاق');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('Clicking shield icon opens governance & permissions dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard(initialIndex: 1)));
      await tester.pumpAndSettle();

      // Tap first shield icon button
      final shieldBtnFinder = find.byIcon(Icons.shield_rounded).first;
      await tester.tap(shieldBtnFinder);
      await tester.pumpAndSettle();

      // Verify permissions dialog content
      expect(find.text('إدارة صلاحيات وحوكمة الوكالة'), findsOneWidget);
      expect(find.text('منح شارة وسيط عقاري معتمد'), findsOneWidget);
      expect(find.text('إصدار وتوثيق العقود الرقمية المباشرة'), findsOneWidget);
      expect(find.text('الربط المالي مع حساب الضمان العقاري'), findsOneWidget);

      // Tap save permissions
      final saveBtn = find.widgetWithText(TashilButton, 'حفظ الصلاحيات');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
    });
  });
}
