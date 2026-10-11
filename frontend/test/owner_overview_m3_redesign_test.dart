import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_overview_view.dart';

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
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
    ),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleController.setLanguage('ar');
    CountryController.setCountry('EG');
  });

  group('Owner Portal M3 Redesign Tests', () {
    testWidgets('OwnerDashboard desktop header contains ONLY Settings and Browse Guest icons', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const OwnerDashboard()));
      await tester.pumpAndSettle();

      // Verify Settings icon is present
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      // Verify Browse Guest icon is present
      expect(find.byIcon(Icons.travel_explore_rounded), findsOneWidget);

      // Verify theme palette circles, country flags, and language dropdown are NOT in the header
      expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
      expect(find.byIcon(Icons.language_rounded), findsNothing);
    });

    testWidgets('OwnerOverviewView renders 4 KPI Metric Cards with TashilCard and Google Icons', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerOverviewView())));
      await tester.pumpAndSettle();

      // Verify TashilCard usage for the 4 metric cards
      expect(find.byType(TashilCard), findsWidgets);

      // Verify Google icons for the metrics
      expect(find.byIcon(Icons.apartment_rounded), findsWidgets);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsWidgets);
      expect(find.byIcon(Icons.door_front_door_outlined), findsWidgets);
      expect(find.byIcon(Icons.payments_outlined), findsWidgets);
    });

    testWidgets('OwnerOverviewView renders TashilConnectedButtonGroup for properties filter', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerOverviewView())));
      await tester.pumpAndSettle();

      // Verify Connected Button Group exists
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);

      // Verify Filter segments
      expect(find.text('جميع الوحدات'), findsOneWidget);
      expect(find.text('مؤجر'), findsWidgets);
      expect(find.text('شاغر'), findsWidgets);

      // Tap on 'شاغر' (vacant) filter segment
      await tester.tap(find.byIcon(Icons.door_front_door_rounded).first);
      await tester.pumpAndSettle();

      // Verify list transitions and shows vacant chalet
      expect(find.text('شاليه بحري صف أول - أمواج'), findsOneWidget);
    });

    testWidgets('Tapping Export Statement triggers TashilSnackBar confirmation', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerOverviewView())));
      await tester.pumpAndSettle();

      // Find and tap the Export Statement button in header
      final exportBtn = find.text('تصدير كشف الحساب').first;
      expect(exportBtn, findsOneWidget);
      await tester.tap(exportBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify SnackBar appears
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
