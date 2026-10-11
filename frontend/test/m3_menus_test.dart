import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      locale: const Locale('ar'),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: child,
          ),
        ),
      ),
    );
  }

  group('Material Design 3 (M3) Menus Suite Tests', () {
    testWidgets('TashilDropdownMenu renders label, prefix icon, and initial value', (tester) async {
      String selected = 'new_cairo';

      await tester.pumpWidget(
        wrapWithApp(
          TashilDropdownMenu<String>(
            value: selected,
            labelText: 'المدينة',
            prefixIcon: Icons.location_city_rounded,
            items: const [
              TashilDropdownMenuItem(
                value: 'all',
                label: 'جميع المدن',
                icon: Icons.domain_rounded,
              ),
              TashilDropdownMenuItem.divider(value: 'div_1'),
              TashilDropdownMenuItem(
                value: 'new_cairo',
                label: 'القاهرة الجديدة',
                icon: Icons.location_city_rounded,
              ),
              TashilDropdownMenuItem(
                value: 'sheikh_zayed',
                label: 'الشيخ زايد',
                icon: Icons.holiday_village_rounded,
              ),
            ],
            onChanged: (val) {
              if (val != null) selected = val;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check label and selected value
      expect(find.text('المدينة'), findsOneWidget);
      expect(find.text('القاهرة الجديدة'), findsOneWidget);
      expect(find.byIcon(Icons.location_city_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('TashilDropdownMenu opens overlay with smooth animation on tap and displays checkmark for selected', (tester) async {
      String selected = 'new_cairo';

      await tester.pumpWidget(
        wrapWithApp(
          TashilDropdownMenu<String>(
            value: selected,
            labelText: 'المدينة',
            prefixIcon: Icons.location_city_rounded,
            items: const [
              TashilDropdownMenuItem(
                value: 'all',
                label: 'جميع المدن',
                icon: Icons.domain_rounded,
              ),
              TashilDropdownMenuItem(
                value: 'new_cairo',
                label: 'القاهرة الجديدة',
                icon: Icons.location_city_rounded,
              ),
              TashilDropdownMenuItem(
                value: 'sheikh_zayed',
                label: 'الشيخ زايد',
                icon: Icons.holiday_village_rounded,
              ),
            ],
            onChanged: (val) {
              if (val != null) selected = val;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to open dropdown
      await tester.tap(find.text('القاهرة الجديدة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      // Now all items in the overlay should be visible
      expect(find.text('جميع المدن'), findsOneWidget);
      expect(find.text('الشيخ زايد'), findsOneWidget);

      // Selected item should have a checkmark icon
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Close menu by selecting an item
      await tester.tap(find.text('جميع المدن'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      await tester.pumpAndSettle();
    });

    testWidgets('Selecting an item updates value, calls callback, and closes menu', (tester) async {
      String selected = 'new_cairo';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return wrapWithApp(
              TashilDropdownMenu<String>(
                value: selected,
                labelText: 'المدينة',
                prefixIcon: Icons.location_city_rounded,
                items: const [
                  TashilDropdownMenuItem(
                    value: 'all',
                    label: 'جميع المدن',
                    icon: Icons.domain_rounded,
                  ),
                  TashilDropdownMenuItem(
                    value: 'new_cairo',
                    label: 'القاهرة الجديدة',
                    icon: Icons.location_city_rounded,
                  ),
                  TashilDropdownMenuItem(
                    value: 'sheikh_zayed',
                    label: 'الشيخ زايد',
                    icon: Icons.holiday_village_rounded,
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selected = val);
                  }
                },
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap to open
      await tester.tap(find.text('القاهرة الجديدة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      // Tap on 'الشيخ زايد'
      await tester.tap(find.text('الشيخ زايد'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      // Selected value should now be 'الشيخ زايد'
      expect(selected, equals('sheikh_zayed'));
      expect(find.text('الشيخ زايد'), findsOneWidget);
    });

    testWidgets('M3MenusShowcaseDialog opens and allows interactive selection', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => M3MenusShowcaseDialog.show(ctx),
              child: const Text('Open Showcase'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Showcase'));
      await tester.pumpAndSettle();

      // Check header and specs
      expect(find.text('Google Material Design 3 Menus'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.text('Google Material Design 3 Menus'), findsNothing);
    });
  });
}
