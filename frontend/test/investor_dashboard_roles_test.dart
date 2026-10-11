import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_dashboard.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_dashboard.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/features/image_moderation/widgets/ai_image_moderator_dialog.dart';

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
          tertiary: const Color(0xFFF59E0B),
        ),
      ),
      home: Material(
        child: child,
      ),
    );
  }

  group('Investor Dashboard Role Scoping & M3 Architecture Tests', () {
    testWidgets('PublicHeaderNavbar does NOT expose Investor Dashboard in dropdown or drawer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          appBar: PublicHeaderNavbar(),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();

      // Ensure investor dashboard title is NOT in the public navbar
      expect(find.text('لوحة المستثمر وتحليلات المحفظة العقارية'), findsNothing);
      expect(find.text('Investor & Portfolio Analytics'), findsNothing);
    });

    testWidgets('OwnerDashboard includes Investor Dashboard in Rail and Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const OwnerDashboard()));
      await tester.pumpAndSettle();

      // Verify the Investor Dashboard destination is present in Owner Navigation
      expect(find.text('التحليلات'), findsWidgets);
    });

    testWidgets('AgencyDashboard includes Investor Dashboard in Rail and Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const AgencyDashboard()));
      await tester.pumpAndSettle();

      // Verify the Investor Dashboard destination is present in Agency Navigation
      expect(find.text('لوحة المستثمر وتحليلات المحفظة العقارية'), findsWidgets);
    });

    testWidgets('SuperAdminDashboard includes and renders Investor Dashboard at index 5', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard(initialIndex: 5)));
      await tester.pumpAndSettle();

      // Verify InvestorDashboardView is actively rendered
      expect(find.byType(InvestorDashboardView), findsOneWidget);
      expect(find.text('لوحة المستثمر وتحليلات المحفظة العقارية'), findsWidgets);
    });

    testWidgets('InvestorDashboardView renders M3 Connected Button Group and Elevated Cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const InvestorDashboardView()));
      await tester.pumpAndSettle();

      // 1. Verify 4 M3 elevated KPI Hero cards exist
      expect(find.byType(TashilCard), findsWidgets);
      expect(find.text('قيمة المحفظة العقارية الحية'), findsOneWidget);
      expect(find.text('صافي التدفقات النقدية السنوية'), findsOneWidget);
      expect(find.text('صافي عائد الاستثمار'), findsOneWidget);
      expect(find.text('معدل إشغال المحفظة'), findsOneWidget);

      // 2. Verify M3 TashilConnectedButtonGroup<int> subtab switcher
      expect(find.byType(TashilConnectedButtonGroup<int>), findsOneWidget);
      expect(find.text('أصول المحفظة والعوائد'), findsOneWidget);
      expect(find.text('التقرير المالي والتحليلي التنفيذي'), findsOneWidget);
      expect(find.text('حركة التدفقات النقدية'), findsOneWidget);
      expect(find.text('سجل التحويلات'), findsOneWidget);
      expect(find.text('الرسوم والمؤشرات'), findsOneWidget);

      // 3. Verify AnimatedSwitcher is present for smooth transitions
      expect(find.byType(AnimatedSwitcher), findsWidgets);

      // 4. Test switching subtab to Monthly Cash Flow
      final cashFlowTabFinder = find.text('حركة التدفقات النقدية');
      await tester.ensureVisible(cashFlowTabFinder);
      await tester.tap(cashFlowTabFinder);
      await tester.pumpAndSettle();

      // Verify cash flow subtab content is displayed
      expect(find.text('اضغط لعرض تفاصيل الوحدات والتحصيل'), findsOneWidget);
    });

    testWidgets('PublicHeaderNavbar does NOT expose AI Image Moderation in dropdown or drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          appBar: PublicHeaderNavbar(),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();

      // Ensure AI Image Moderation title is NOT in the public navbar
      expect(find.text('فحص وتدقيق الصور بالذكاء الاصطناعي'), findsNothing);
      expect(find.text('AI Property Image Moderation'), findsNothing);
    });

    testWidgets('SuperAdminDashboard includes AI Image Moderation and opens dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard()));
      await tester.pumpAndSettle();

      // Verify AI Image Moderation destination is in Super Admin rail/menu
      expect(find.text('فحص وتدقيق الصور بالذكاء الاصطناعي'), findsWidgets);

      // Tap on AI Image Moderation in Rail
      await tester.tap(find.text('فحص وتدقيق الصور بالذكاء الاصطناعي').first);
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.byType(AiImageModeratorDialog), findsOneWidget);

      // Verify M3 shaded close button exists in dialog
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify TashilConnectedButtonGroup<String> is used for filter tabs
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
    });
  });
}
