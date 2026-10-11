import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/navigation_rail/tashil_navigation_rail.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';

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
        body: child,
      ),
    );
  }

  group('TashilNavigationRail & Header Alignment Suite', () {
    testWidgets('TashilNavigationRail does not contain the word "القائمة" in expanded mode', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          TashilNavigationRail(
            isExpanded: true,
            railWidth: 80.0,
            expandedWidth: 280.0,
            onToggleExpanded: () {},
            menuTooltip: 'طي القائمة',
            destinations: [
              TashilRailDestination(
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics_rounded,
                label: 'المؤشرات',
                isSelected: true,
                isExpanded: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure 'القائمة' or 'Menu' is not rendered in the widget tree
      expect(find.text('القائمة'), findsNothing);
      expect(find.text('Menu'), findsNothing);

      // Verify the toggle button is present with menu_open_rounded icon
      expect(find.byIcon(Icons.menu_open_rounded), findsOneWidget);
    });

    testWidgets('TashilNavigationRail renders toggle button and concise labels correctly in collapsed mode', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          TashilNavigationRail(
            isExpanded: false,
            railWidth: 80.0,
            expandedWidth: 280.0,
            onToggleExpanded: () {},
            menuTooltip: 'توسيع القائمة',
            destinations: [
              TashilRailDestination(
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics_rounded,
                label: 'المؤشرات',
                isSelected: true,
                isExpanded: false,
                onTap: () {},
              ),
              TashilRailDestination(
                icon: Icons.business_outlined,
                selectedIcon: Icons.business_rounded,
                label: 'الوكالات',
                badgeCount: '48',
                isSelected: false,
                isExpanded: false,
                onTap: () {},
              ),
              TashilRailDestination(
                icon: Icons.verified_user_outlined,
                selectedIcon: Icons.verified_user_rounded,
                label: 'الضمان',
                isSelected: false,
                isExpanded: false,
                onTap: () {},
              ),
              TashilRailDestination(
                icon: Icons.palette_outlined,
                selectedIcon: Icons.palette_rounded,
                label: 'المعايير',
                isSelected: false,
                isExpanded: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify collapsed menu icon
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Verify concise labels are present
      expect(find.text('المؤشرات'), findsOneWidget);
      expect(find.text('الوكالات'), findsOneWidget);
      expect(find.text('الضمان'), findsOneWidget);
      expect(find.text('المعايير'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
    });

    test('Trilingual parity for concise navigation labels', () {
      final locAr = AppLocalizations(const Locale('ar'));
      final locEn = AppLocalizations(const Locale('en'));
      final locHi = AppLocalizations(const Locale('hi'));

      expect(locAr.tr('kpiCompact'), 'المؤشرات');
      expect(locEn.tr('kpiCompact'), 'KPIs');
      expect(locHi.tr('kpiCompact'), 'केपीआई');

      expect(locAr.tr('agenciesCompact'), 'الوكالات');
      expect(locEn.tr('agenciesCompact'), 'Agencies');
      expect(locHi.tr('agenciesCompact'), 'एजेंसियां');

      expect(locAr.tr('escrowCompact'), 'الضمان');
      expect(locEn.tr('escrowCompact'), 'Escrow');
      expect(locHi.tr('escrowCompact'), 'एस्क्रो');

      expect(locAr.tr('standardsCompact'), 'المعايير');
      expect(locEn.tr('standardsCompact'), 'Standards');
      expect(locHi.tr('standardsCompact'), 'मानक');
    });
  });
}
