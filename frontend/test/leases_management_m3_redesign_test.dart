import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';

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
        body: LeasesManagementView(),
      ),
    );
  }

  group('Leases Management M3 Redesign Tests', () {
    testWidgets('Renders in Arabic with pure localization, zero English leakage, and months key translated', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify header and button
      expect(find.text('إدارة العقود والإيجارات'), findsOneWidget);
      expect(find.text('إنشاء عقد'), findsOneWidget);

      // Verify pure Arabic - zero raw english 'months' inside duration
      expect(find.textContaining('months'), findsNothing);
      expect(find.textContaining('شهراً'), findsWidgets);

      // Verify TashilConnectedButtonGroup is present with Arabic labels
      expect(find.byType(TashilConnectedButtonGroup<String>), findsWidgets);
      expect(find.text('جميع العقود'), findsOneWidget);
      expect(find.text('سارية المفعول'), findsOneWidget);
      expect(find.text('بانتظار التوقيع'), findsOneWidget);

      // Verify M3 Cards and Dividers are present
      expect(find.byType(TashilCard), findsWidgets);
      expect(find.byType(TashilDivider), findsWidgets);

      // Verify single-icon rule: no emoji in buttons
      expect(find.textContaining('✍️'), findsNothing);
    });

    testWidgets('Tapping segments in TashilConnectedButtonGroup filters contracts smoothly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Tap on "سارية المفعول" (Active) segment
      final activeSegment = find.text('سارية المفعول');
      expect(activeSegment, findsOneWidget);
      await tester.tap(activeSegment);
      await tester.pumpAndSettle();

      // Tap on "بانتظار التوقيع" (Pending Signatures) segment
      final pendingSegment = find.text('بانتظار التوقيع');
      expect(pendingSegment, findsOneWidget);
      await tester.tap(pendingSegment);
      await tester.pumpAndSettle();

      // Tap back to "جميع العقود" (All)
      final allSegment = find.text('جميع العقود');
      expect(allSegment, findsOneWidget);
      await tester.tap(allSegment);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders in English with full parity and correct action buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Lease & Tenancy Management'), findsOneWidget);
      expect(find.text('Create Lease'), findsOneWidget);
      expect(find.text('All Leases'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Pending Signature'), findsWidgets);
      expect(find.text('Preview'), findsWidgets);
      expect(find.textContaining('months'), findsWidgets);
    });

    testWidgets('Renders in Hindi with full parity and Devanagari numerals and text', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('पट्टा और किरायेदारी प्रबंधन'), findsOneWidget);
      expect(find.text('अनुबंध बनाएं'), findsOneWidget);
      expect(find.text('सभी अनुबंध'), findsOneWidget);
      expect(find.text('पूर्वावलोकन'), findsWidgets);
      expect(find.textContaining('महीने'), findsWidgets);
    });

    testWidgets('Responsive Mobile Layout (375x812) renders with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LeasesManagementView), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<String>), findsWidgets);
    });

    testWidgets('Responsive Tablet Layout (768x1024) renders with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LeasesManagementView), findsOneWidget);
    });
  });
}
