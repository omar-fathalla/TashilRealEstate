import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';

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
      home: Scaffold(
        appBar: const PublicHeaderNavbar(),
        body: child,
      ),
    );
  }

  group('PublicHeaderNavbar Clean Header Tests', () {
    testWidgets('Renders all-icon navigation suite in desktop without text clutter', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const SizedBox()));
      await tester.pumpAndSettle();

      // Verify the all-icon suite is present
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget); // Settings
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget); // Valuation
      expect(find.byIcon(Icons.analytics_rounded), findsOneWidget); // Market Index
      expect(find.byIcon(Icons.lock_person_outlined), findsOneWidget); // Login Icon

      // Verify text buttons are removed from header (as requested by user)
      expect(find.text('استكشف الوحدات'), findsNothing);
      expect(find.text('أضف عقارك'), findsNothing);
      expect(find.text('الخدمات والحلول الذكية'), findsNothing);
      expect(find.text('تسجيل الدخول'), findsNothing);
    });

    testWidgets('Renders all-icon navigation in English LTR mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(const SizedBox()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.byIcon(Icons.analytics_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_person_outlined), findsOneWidget);

      expect(find.text('List Property'), findsNothing);
      expect(find.text('Explore Units'), findsNothing);
    });

    testWidgets('Renders settings icon in mobile mode and mobile menu has no exploreUnits', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const SizedBox()));
      await tester.pumpAndSettle();

      // On mobile, the settings button and menu button are both available
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Open mobile menu
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Ensure explore units is NOT in mobile menu
      expect(find.text('استكشف الوحدات'), findsNothing);

      // Ensure Add Property is in mobile menu
      expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    });

    testWidgets('Header icon buttons have descriptive tooltips', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const SizedBox()));
      await tester.pumpAndSettle();

      // Tooltips for each icon
      expect(find.byTooltip('التقييم العقاري الذكي'), findsOneWidget);
      expect(find.byTooltip('مؤشر عقارماب'), findsOneWidget);
      expect(find.byTooltip('تسجيل الدخول'), findsOneWidget);
    });

    testWidgets('Header uses TashilConnectedIconButtonGroup for the 4 desktop actions', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const SizedBox()));
      await tester.pumpAndSettle();

      // Verify Connected Icon Button Group is present
      expect(find.byType(TashilConnectedIconButtonGroup), findsOneWidget);

      final group = tester.widget<TashilConnectedIconButtonGroup>(find.byType(TashilConnectedIconButtonGroup));
      expect(group.items.length, equals(4));
    });

    testWidgets('Header aligns brand title to the right (start) in Arabic RTL mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(const SizedBox(), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final brandFinder = find.byIcon(Icons.apartment_rounded);
      expect(brandFinder, findsOneWidget);

      final brandCenter = tester.getCenter(brandFinder);
      // On 1280 wide screen in Arabic RTL, brand should be on the right side (> 640)
      expect(brandCenter.dx, greaterThan(1000));
    });
  });
}

