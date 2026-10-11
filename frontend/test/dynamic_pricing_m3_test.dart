import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/dynamic_pricing/services/dynamic_pricing_optimizer_service.dart';
import 'package:tashil_real_estate/features/dynamic_pricing/widgets/dynamic_pricing_tab_view.dart';
import 'package:tashil_real_estate/features/dynamic_pricing/widgets/dynamic_yield_optimizer_dialog.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('ar')}) {
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
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CountryController.setCountry('EG');
    LocaleController.setLanguage('ar');
    DynamicPricingOptimizerService().reset();
  });

  group('Dynamic Pricing M3 & Table View Standard Tests', () {
    testWidgets('DynamicPricingTabView defaults to Table View with full columns and data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(const DynamicPricingTabView()));
      await tester.pumpAndSettle();

      // Verify both Connected Button Group view switchers exist and default to 'table'
      final connectedGroupFinder = find.byType(TashilConnectedButtonGroup<String>);
      expect(connectedGroupFinder, findsNWidgets(2));

      final unitsGroup = tester.widget<TashilConnectedButtonGroup<String>>(connectedGroupFinder.first);
      expect(unitsGroup.selectedValue, equals('table'));

      final multipliersGroup = tester.widget<TashilConnectedButtonGroup<String>>(connectedGroupFinder.at(1));
      expect(multipliersGroup.selectedValue, equals('table'));

      // Verify Table 1: Managed Units Header columns are present
      expect(find.text('الوحدة والعقار'), findsOneWidget);
      expect(find.text('مضاعف الذروة'), findsOneWidget);
      expect(find.text('مقارنة الإيجار'), findsOneWidget);
      expect(find.text('استراتيجية التسعير الذكي'), findsWidgets);
      expect(find.text('الإجراءات'), findsOneWidget);

      // Verify Table 2: Peak Multipliers Header columns are present
      expect(find.text('الموسم والحدث العقاري'), findsOneWidget);
      expect(find.text('الفترة النشطة'), findsOneWidget);
      expect(find.text('مضاعف الذروة المقترح'), findsOneWidget);
      expect(find.text('نسبة الإشغال المتوقعة'), findsOneWidget);
      expect(find.text('المنطقة المستهدفة'), findsOneWidget);

      // Verify Seasonality banner has translated insight without raw keys
      expect(find.textContaining('egyptSeasonalityInsight'), findsNothing);
      expect(find.textContaining('سوق مصر: ذروة موسم الطلاب والشركات'), findsOneWidget);

      // Verify action buttons exist in table rows with concise label 'تطبيق'
      expect(find.text('تطبيق'), findsWidgets);

      // Verify view switcher can toggle to cards view on first group
      await tester.tap(find.text('عرض الكروت').first);
      await tester.pumpAndSettle();

      final updatedUnitsGroup = tester.widget<TashilConnectedButtonGroup<String>>(connectedGroupFinder.first);
      expect(updatedUnitsGroup.selectedValue, equals('grid'));
    });

    testWidgets('Tapping on "تطبيق" opens confirmation explanation dialog and applying updates state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(const DynamicPricingTabView()));
      await tester.pumpAndSettle();

      // Find first "تطبيق" button and tap it
      final applyButtonFinder = find.text('تطبيق').first;
      await tester.tap(applyButtonFinder);
      await tester.pumpAndSettle();

      // Verify confirmation explanation dialog opened with Connected Button Group
      expect(find.text('تأكيد تطبيق السعر المقترح'), findsOneWidget);
      expect(find.text('الإيجار الحالي قبل التعديل'), findsOneWidget);
      expect(find.text('الإيجار الجديد الموصى به'), findsOneWidget);
      expect(find.text('تأكيد'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      expect(find.byIcon(Icons.close_rounded), findsWidgets);

      // Tap confirm button in Connected Button Group
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and button updated to applied state
      expect(find.text('تأكيد تطبيق السعر المقترح'), findsNothing);
      expect(find.text('تم تطبيق السعر'), findsWidgets);
    });

    testWidgets('Seasonality insight adapts to UAE when country is AE', (tester) async {
      CountryController.setCountry('AE');
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(const DynamicPricingTabView()));
      await tester.pumpAndSettle();

      expect(find.textContaining('uaeSeasonalityInsight'), findsNothing);
      expect(find.textContaining('سوق الإمارات: ذروة السياحة الشتوية'), findsOneWidget);
    });

    testWidgets('DynamicYieldOptimizerDialog conforms to M3 shaded close, 28dp radius, and zero mixing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DynamicYieldOptimizerDialog.show(context, countryCode: 'EG'),
            child: const Text('Open Dialog'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(DynamicYieldOptimizerDialog), findsOneWidget);

      // Verify M3 28dp radius and Level 3 elevation
      final dialogFinder = find.descendant(
        of: find.byType(DynamicYieldOptimizerDialog),
        matching: find.byType(Dialog),
      );
      expect(dialogFinder, findsOneWidget);
      final dialog = tester.widget<Dialog>(dialogFinder);
      expect(dialog.elevation, equals(6.0));
      expect(dialog.shape, isA<RoundedRectangleBorder>());
      final shape = dialog.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, equals(28.0));

      // Verify M3 Shaded Close Button is present
      final closeButtonFinder = find.byType(TashilIconButton);
      expect(closeButtonFinder, findsWidgets);

      // Verify Zero Language Mixing in Arabic: no '(Auto-Pilot Yield)' text
      expect(find.textContaining('(Auto-Pilot Yield)'), findsNothing);
      expect(find.text('تفعيل نظام التسعير التلقائي الذكي للمردود'), findsOneWidget);

      // Verify localized country badge
      expect(find.text('🇪🇬 مصر'), findsOneWidget);
      expect(find.text('Egypt'), findsNothing);

      // Verify M3 Dividers
      expect(find.byType(TashilDivider), findsWidgets);

      // Verify currency is present in current rent subtitle
      expect(find.textContaining('ج.م'), findsWidgets);

      // Tap apply dynamic price button
      await tester.tap(find.widgetWithText(TashilButton, 'تطبيق السعر'));
      await tester.pumpAndSettle();

      // Verify button changes to priceApplied
      expect(find.text('تم تطبيق السعر'), findsWidgets);
    });

    testWidgets('DynamicYieldOptimizerDialog renders cleanly in English and Hindi without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Test English
      LocaleController.setLanguage('en');
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DynamicYieldOptimizerDialog.show(context, countryCode: 'EG'),
            child: const Text('Open Dialog EN'),
          ),
        ),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog EN'));
      await tester.pumpAndSettle();

      expect(find.byType(DynamicYieldOptimizerDialog), findsOneWidget);
      expect(find.text('Dynamic Pricing Engine'), findsOneWidget);
      expect(find.textContaining('EGP'), findsWidgets);

      // Close dialog
      await tester.tap(find.byType(TashilIconButton).last);
      await tester.pumpAndSettle();

      // Test Hindi
      LocaleController.setLanguage('hi');
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DynamicYieldOptimizerDialog.show(context, countryCode: 'EG'),
            child: const Text('Open Dialog HI'),
          ),
        ),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog HI'));
      await tester.pumpAndSettle();

      expect(find.byType(DynamicYieldOptimizerDialog), findsOneWidget);
      expect(find.text('गतिशील मूल्य निर्धारण इंजन'), findsOneWidget);
    });

    testWidgets('Apply Price Confirmation dialog uses TashilConnectedButtonGroup with official Google Icons and pure labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Arabic Test
      LocaleController.setLanguage('ar');
      await tester.pumpWidget(_buildTestApp(const DynamicPricingTabView(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تطبيق').first);
      await tester.pumpAndSettle();

      // Find Connected Button Group in dialog
      final dialogConnectedGroupFinder = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TashilConnectedButtonGroup<String>),
      );
      expect(dialogConnectedGroupFinder, findsOneWidget);

      final groupWidget = tester.widget<TashilConnectedButtonGroup<String>>(dialogConnectedGroupFinder);
      expect(groupWidget.isFullWidth, isTrue);
      expect(groupWidget.segments.length, equals(2));

      // Verify Cancel segment
      expect(groupWidget.segments[0].value, equals('cancel'));
      expect(groupWidget.segments[0].label, equals('إلغاء'));
      expect(groupWidget.segments[0].icon, equals(Icons.close_rounded));

      // Verify Confirm segment: exact 'تأكيد' label with Google check_rounded icon
      expect(groupWidget.segments[1].value, equals('confirm'));
      expect(groupWidget.segments[1].label, equals('تأكيد'));
      expect(groupWidget.segments[1].icon, equals(Icons.check_rounded));

      // Tap cancel to close without applying
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('تم تطبيق السعر'), findsNothing);

      // 2. English Test
      LocaleController.setLanguage('en');
      await tester.pumpWidget(_buildTestApp(const DynamicPricingTabView(), locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply').first);
      await tester.pumpAndSettle();

      final enDialogGroupFinder = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TashilConnectedButtonGroup<String>),
      );
      expect(enDialogGroupFinder, findsOneWidget);

      final enGroup = tester.widget<TashilConnectedButtonGroup<String>>(enDialogGroupFinder);
      expect(enGroup.segments[0].label, equals('Cancel'));
      expect(enGroup.segments[1].label, equals('Confirm'));

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Price Applied'), findsWidgets);
    });
  });
}
