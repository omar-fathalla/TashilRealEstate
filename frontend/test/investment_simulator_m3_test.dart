import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/sliders/tashil_sliders.dart';
import 'package:tashil_real_estate/features/investor_dashboard/widgets/investment_simulator_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

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
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F172A),
        primary: const Color(0xFF0F172A),
        secondary: const Color(0xFF3B82F6),
        tertiary: const Color(0xFFF59E0B),
      ),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleController.setLanguage('ar');
    CountryController.setCountry('EG');
  });

  group('InvestmentSimulatorDialog M3 Redesign & Localization Tests', () {
    testWidgets('Renders properly in Arabic with zero language mixing and no raw translation keys', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const InvestmentSimulatorDialog()));
      await tester.pumpAndSettle();

      // Verify no raw key names appear anywhere on screen
      expect(find.text('propertyName'), findsNothing);
      expect(find.text('purchasePrice'), findsNothing);
      expect(find.text('purchasePrice (ج.م)'), findsNothing);
      expect(find.text('years'), findsNothing);
      expect(find.textContaining('Cap Rate'), findsNothing);

      // Verify pure Arabic translated labels
      expect(find.text('اسم العقار'), findsOneWidget);
      expect(find.textContaining('سعر الشراء'), findsOneWidget);
      expect(find.textContaining('معدل الرسملة'), findsNWidgets(2));
      expect(find.textContaining('سنة'), findsOneWidget);
      expect(find.text('محاكي الاستثمار'), findsOneWidget);
      expect(find.text('بيانات الوحدة الاستثمارية'), findsOneWidget);
      expect(find.text('المؤشرات المالية ومعدلات العائد'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);

      // Verify M3 Shaded Close Button is present
      expect(find.byType(TashilIconButton), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify TashilSlider is used for both down payment and appreciation
      expect(find.byType(TashilSlider), findsNWidgets(2));
      // Standard raw Slider must NOT be present
      expect(find.byType(Slider), findsNothing);

      // Verify TashilCard is used for the 4 metric tiles
      expect(find.byType(TashilCard), findsNWidgets(4));
    });

    testWidgets('Renders properly in English with correct English translations', (tester) async {
      LocaleController.setLanguage('en');
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        locale: const Locale('en'),
        child: const InvestmentSimulatorDialog(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Property Name'), findsOneWidget);
      expect(find.textContaining('Purchase Price'), findsOneWidget);
      expect(find.textContaining('Cap Rate:'), findsOneWidget);
      expect(find.textContaining('years'), findsOneWidget);
      expect(find.text('Investment Simulator'), findsOneWidget);
      expect(find.text('Investment Unit Parameters'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Renders properly in Hindi with correct Hindi translations', (tester) async {
      LocaleController.setLanguage('hi');
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        locale: const Locale('hi'),
        child: const InvestmentSimulatorDialog(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('संपत्ति का नाम'), findsOneWidget);
      expect(find.textContaining('खरीद मूल्य'), findsOneWidget);
      expect(find.textContaining('कैप दर:'), findsOneWidget);
      expect(find.textContaining('वर्ष'), findsOneWidget);
      expect(find.text('निवेश सिम्युलेटर'), findsOneWidget);
      expect(find.text('निवेश इकाई विवरण'), findsOneWidget);
      expect(find.text('बंद करें'), findsOneWidget);
    });

    testWidgets('Top close button and footer close button dismiss dialog cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => InvestmentSimulatorDialog.show(context),
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Open dialog and dismiss via top X shaded button
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestmentSimulatorDialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(InvestmentSimulatorDialog), findsNothing);

      // 2. Open again and dismiss via footer Close button
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestmentSimulatorDialog), findsOneWidget);

      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestmentSimulatorDialog), findsNothing);
    });

    testWidgets('Simulator does NOT alter PropertyLifecycleService or live portfolio', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final initialPropCount = PropertyLifecycleService().propertiesNotifier.value.length;

      await tester.pumpWidget(wrapWithApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => InvestmentSimulatorDialog.show(context),
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestmentSimulatorDialog), findsOneWidget);

      // Close the simulator
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();

      // Verify that properties in PropertyLifecycleService remain exactly unchanged
      expect(PropertyLifecycleService().propertiesNotifier.value.length, equals(initialPropCount));
      expect(PropertyLifecycleService().propertiesNotifier.value.any((p) => p.id.startsWith('SIM-')), isFalse);
    });
  });
}
