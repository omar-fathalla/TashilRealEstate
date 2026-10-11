import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/financial_kpi_screen.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
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
          secondary: const Color(0xFF3B82F6),
        ),
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Financial Roles & Admin Google AI Hub Suite Tests', () {
    testWidgets('FinancialKpiScreen does NOT display public role selector tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const FinancialKpiScreen(initialRole: FinancialPortalRole.owner)));
      await tester.pumpAndSettle();

      // Ensure NO role tabs exist at the top
      expect(find.text('بوابة المالك'), findsNothing);
      expect(find.text('الوكالة العقارية'), findsNothing);
      expect(find.text('الإدارة العامة'), findsNothing);

      // Verify it directly renders the Owner's financial dashboard
      expect(find.text('الأداء المالي لمحفظة المالك'), findsOneWidget);
    });

    testWidgets('Renders specific dashboard for Agency without role tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const FinancialKpiDashboardView(role: FinancialPortalRole.agency)));
      await tester.pumpAndSettle();

      expect(find.text('مؤشرات الأداء المالي والعمولات للوكالة'), findsOneWidget);
      expect(find.text('التقرير المالي والتحليلي التنفيذي'), findsOneWidget);
    });

    testWidgets('Renders specific dashboard for SuperAdmin with Executive Report action', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const FinancialKpiDashboardView(role: FinancialPortalRole.superAdmin)));
      await tester.pumpAndSettle();

      expect(find.text('مؤشرات الأداء المالي العام للمنصة'), findsOneWidget);
      expect(find.text('التقرير المالي والتحليلي التنفيذي'), findsOneWidget);
    });

    testWidgets('PublicHeaderNavbar does NOT show Google AI Hub or Financials in public header', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const PublicHeaderNavbar(currentRoute: '/')));
      await tester.pumpAndSettle();

      // Ensure Google AI Hub and Financials are NOT present in the public header
      expect(find.text('خريطة Google AI والخدمات'), findsNothing);
      expect(find.text('الرسوم والمؤشرات المالية'), findsNothing);
    });

    testWidgets('SuperAdminDashboard includes Google AI Hub in desktop header and rail', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard()));
      await tester.pumpAndSettle();

      // Verify Google AI Hub button is present in Super Admin
      expect(find.text('خريطة Google AI والخدمات'), findsWidgets);
    });
  });
}
