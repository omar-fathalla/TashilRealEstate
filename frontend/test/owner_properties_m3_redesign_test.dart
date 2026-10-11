import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/lists/tashil_lists.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_properties_view.dart';

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

  group('OwnerPropertiesView M3 Redesign Tests', () {
    testWidgets('Renders TashilConnectedButtonGroup for quick actions and view toggle', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // Verify connected button groups are used (at least 2: quick actions and view switcher)
      expect(find.byType(TashilConnectedButtonGroup<PropertyQuickAction>), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<bool>), findsOneWidget);

      // Verify Google icons in quick actions
      expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      // Verify Google icons in view switcher
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.table_rows_rounded), findsOneWidget);
    });

    testWidgets('Renders prominent primary action TashilButton for fast onboarding (رفع العقار)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // Verify standalone primary action button for "رفع العقار"
      final uploadBtn = find.widgetWithText(TashilButton, 'رفع العقار');
      expect(uploadBtn, findsOneWidget);
      expect(find.descendant(of: uploadBtn, matching: find.byIcon(Icons.rocket_launch_rounded)), findsOneWidget);
    });

    testWidgets('Table view renders M3 clean banner with drag hint and table header', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // Verify banner drag hint icon
      expect(find.byIcon(Icons.drag_indicator_rounded), findsWidgets);

      // Verify M3 table card
      expect(find.byType(TashilCard), findsWidgets);
    });

    testWidgets('Desktop table row contains connected action group with Google icons', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // Verify action buttons inside table rows
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      expect(find.byIcon(Icons.share_rounded), findsWidgets);
    });

    testWidgets('Toggling view mode switches smoothly between table view and cards view', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // Tap "عرض الكروت"
      final cardsViewBtn = find.text('عرض الكروت');
      expect(cardsViewBtn, findsOneWidget);

      await tester.tap(cardsViewBtn);
      await tester.pumpAndSettle();

      // Now Cards View (GridView) is active
      expect(find.byType(GridView), findsOneWidget);

      // Tap "عرض الجدول" to switch back
      final tableViewBtn = find.text('عرض الجدول');
      expect(tableViewBtn, findsOneWidget);

      await tester.tap(tableViewBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('Dragging table row to reorder triggers proxyDecorator without assertion error', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // Find drag handles
      final dragHandles = find.byType(TashilReorderHandle);
      expect(dragHandles, findsWidgets);

      // Perform drag on first handle
      final firstHandle = dragHandles.first;
      await tester.drag(firstHandle, const Offset(0, 160));
      await tester.pumpAndSettle();

      // Verify no exception was thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('Property type badges have distinct colors and status badges have high contrast', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // Verify property type chips exist with their respective labels
      final aptChip = find.text('شقة 402');
      final villaChip = find.text('فيلا 12');
      final chaletChip = find.text('شاليه 104');

      expect(aptChip, findsOneWidget);
      expect(villaChip, findsOneWidget);
      expect(chaletChip, findsOneWidget);

      // Verify different text colors for apartment (blue) vs villa (green) vs chalet (amber)
      final aptText = tester.widget<Text>(aptChip);
      final villaText = tester.widget<Text>(villaChip);
      final chaletText = tester.widget<Text>(chaletChip);

      expect(aptText.style?.color, const Color(0xFF1D4ED8)); // Royal Blue 700
      expect(villaText.style?.color, const Color(0xFF047857)); // Emerald 700
      expect(chaletText.style?.color, const Color(0xFFB45309)); // Amber 700

      // Verify status badges are present with high contrast icons
      expect(find.byIcon(Icons.storefront_rounded), findsWidgets); // Published
      expect(find.byIcon(Icons.vpn_key_rounded), findsWidgets); // Occupied
    });

    testWidgets('Table and Cards view render chic Property Type Chips and stylized Location Badges', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const Scaffold(body: OwnerPropertiesView())));
      await tester.pumpAndSettle();

      // 1. Verify Property Type Chips in Table View
      expect(find.text('شقة سكنية'), findsWidgets);
      expect(find.text('فيلا مستقلة'), findsWidgets);
      expect(find.text('شاليه مصيفي'), findsWidgets);

      // Verify M3 semantic icons for property types
      expect(find.byIcon(Icons.apartment_rounded), findsWidgets);
      expect(find.byIcon(Icons.villa_rounded), findsWidgets);
      expect(find.byIcon(Icons.beach_access_rounded), findsWidgets);

      // 2. Verify stylized Location Badges with solid M3 pin
      expect(find.byIcon(Icons.location_on_rounded), findsWidgets);

      // 3. Switch to Cards View and verify Property Type Chips floating on cards
      final cardsViewBtn = find.byIcon(Icons.grid_view_rounded);
      expect(cardsViewBtn, findsOneWidget);
      await tester.tap(cardsViewBtn);
      await tester.pumpAndSettle();

      // Verify Property Type Chips on Cards
      expect(find.textContaining('شقة سكنية'), findsWidgets);
      expect(find.textContaining('فيلا مستقلة'), findsWidgets);
      expect(find.byIcon(Icons.location_on_rounded), findsWidgets);
    });
  });
}
