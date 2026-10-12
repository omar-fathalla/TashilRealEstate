import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/features/ai_engine_hub/models/ai_model_definition.dart';
import 'package:tashil_real_estate/features/ai_engine_hub/services/ai_engine_config_controller.dart';
import 'package:tashil_real_estate/features/ai_engine_hub/views/ai_engine_hub_view.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_dashboard.dart';
import 'package:tashil_real_estate/features/architecture_hub/widgets/google_ai_architecture_hub_dialog.dart';

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

  group('AI Engine Hub & Model Switcher Tests', () {
    test('AiEngineConfigController manages 6 services, top 3 models, and token analytics', () {
      final controller = AiEngineConfigController();
      expect(controller.categories.length, equals(6));

      // Verify each service has exactly 3 modern models
      for (final cat in controller.categories) {
        expect(cat.top3Models.length, equals(3));
      }

      // Check default model for property ingestion
      expect(controller.getModelName(AiServiceType.propertyIngestion), equals('gemini-3.8-flash'));

      // Switch to Gemini 2.5 Flash
      controller.switchModel(AiServiceType.propertyIngestion, 'gemini-2.5-flash');
      expect(controller.getModelName(AiServiceType.propertyIngestion), equals('gemini-2.5-flash'));

      // Verify calculations
      final tokens = controller.calculateEstimatedMonthlyTokens();
      final cost = controller.calculateEstimatedMonthlyCost();
      final savings = controller.calculateEstimatedSavingsPercentage();

      expect(tokens, greaterThan(0));
      expect(cost, greaterThan(0.0));
      expect(savings, greaterThan(0));

      // Reset to defaults
      controller.resetToDefaults();
      expect(controller.getModelName(AiServiceType.propertyIngestion), equals('gemini-3.8-flash'));
      expect(controller.getModelName(AiServiceType.legalAdvisor), equals('gemini-3.8-flash'));
      expect(controller.getActiveModel(AiServiceType.legalAdvisor).name, equals('Gemini 3.8 Flash Legal'));
    });

    testWidgets('AiEngineHubView renders Hero KPI metrics and 6 AI service cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const Scaffold(body: AiEngineHubView())));
      await tester.pumpAndSettle();

      // Verify Header & Hero Section
      expect(find.text('مركز إدارة محركات ونماذج الذكاء الاصطناعي'), findsOneWidget);
      expect(find.text('Gemini & Imagen Mesh'), findsOneWidget);
      expect(find.text('6 / 6'), findsOneWidget);

      // Verify Service Cards Titles
      expect(find.text('استخراج وتفريغ مواصفات العقار (الصوت والنص)'), findsOneWidget);
      expect(find.text('صياغة الوصف التسويقي والإعلانات العقارية'), findsOneWidget);
      expect(find.text('التقييم المالي الذكي ومقارنات السوق (Zestimate)'), findsOneWidget);
      expect(find.text('البحث الدلالي الذكي والمتجهات (Vector Embeddings)'), findsOneWidget);
      expect(find.text('المستشار القانوني وفحص بنود العقود الإيجارية'), findsOneWidget);
      expect(find.text('الفرش الافتراضي والتوليد البصري (Visual AI)'), findsOneWidget);

      // Verify Token Level Badges
      expect(find.text('توكن منخفض جداً'), findsWidgets);
      expect(find.text('توكن متوازن'), findsWidgets);

      // Verify switching a model
      expect(find.text('Gemini 3.8 Flash'), findsWidgets);
      await tester.tap(find.text('Gemini 2.5 Flash').first);
      await tester.pumpAndSettle();

      // Controller should reflect active selection
      expect(AiEngineConfigController().getModelName(AiServiceType.propertyIngestion), equals('gemini-2.5-flash'));
    });

    testWidgets('SuperAdminDashboard includes AI Engine Hub at index 6 and in Desktop header', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const SuperAdminDashboard(initialIndex: 6)));
      await tester.pumpAndSettle();

      // Verify AiEngineHubView is rendered
      expect(find.byType(AiEngineHubView), findsOneWidget);
      expect(find.text('مركز إدارة محركات ونماذج الذكاء الاصطناعي'), findsOneWidget);

      // Verify Rail item
      expect(find.text('محركات الذكاء الاصطناعي'), findsWidgets);

      // Verify Header button
      expect(find.byIcon(Icons.smart_toy_rounded), findsWidgets);
    });

    testWidgets('AppSettingsDialog includes AI Engine section with open hub button', (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(const Scaffold(body: AppSettingsDialog())));
      await tester.pumpAndSettle();

      // Verify Section 5 is present
      expect(find.text('محركات ونماذج الذكاء الاصطناعي'), findsOneWidget);
      expect(find.text('Gemini 3.8 & 2.5 Active'), findsOneWidget);
      expect(find.text('فتح مركز إدارة نماذج AI'), findsOneWidget);
    });

    testWidgets('GoogleAiArchitectureHubDialog includes model switcher button and active models', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithApp(Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => GoogleAiArchitectureHubDialog.show(ctx),
          child: const Text('Open Hub'),
        ),
      )));
      await tester.pumpAndSettle();

      // Tap to open dialog
      await tester.tap(find.text('Open Hub'));
      await tester.pumpAndSettle();

      // Verify Switch Models button is rendered in the dialog
      expect(find.text('تبديل وإدارة الموديلات'), findsOneWidget);
      expect(find.text('تغيير الموديل النشط'), findsOneWidget);

      // Tap on Switch Models button to open AI Engine Hub
      await tester.tap(find.text('تبديل وإدارة الموديلات'));
      await tester.pumpAndSettle();

      // Verify AI Engine Hub Dialog is now displayed
      expect(find.byType(AiEngineHubView), findsOneWidget);
    });
  });
}
