import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
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

  group('Official Google Material Design 3 (M3) Split Button Suite Tests', () {
    testWidgets('TashilSplitButton renders primary button and trailing menu button', (tester) async {
      bool primaryClicked = false;
      String? selectedValue;

      await tester.pumpWidget(
        wrapWithApp(
          TashilSplitButton<String>(
            label: 'بحث بالمدينة والحي',
            icon: Icons.location_on_outlined,
            onPressed: () => primaryClicked = true,
            selectedValue: 'location',
            items: const [
              TashilSplitButtonItem(
                value: 'location',
                label: 'بحث بالمدينة والحي',
                subtitle: 'البحث السريع المباشر',
                icon: Icons.location_on_outlined,
              ),
              TashilSplitButtonItem(
                value: 'ai',
                label: 'بحث الذكاء الاصطناعي',
                subtitle: 'البحث باللغة الطبيعية',
                icon: Icons.auto_awesome_rounded,
              ),
              TashilSplitButtonItem(
                value: 'visual',
                label: 'بحث بالطراز والمعمار',
                subtitle: 'معرض الطرز والمودبورد',
                icon: Icons.photo_camera_outlined,
              ),
            ],
            onItemSelected: (val) => selectedValue = val,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify label and icon exist
      expect(find.text('بحث بالمدينة والحي'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap primary action button
      await tester.tap(find.text('بحث بالمدينة والحي'));
      await tester.pumpAndSettle();
      expect(primaryClicked, isTrue);

      // Tap chevron to open popup menu
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();

      // Verify popup items are visible
      expect(find.text('بحث الذكاء الاصطناعي'), findsOneWidget);
      expect(find.text('بحث بالطراز والمعمار'), findsOneWidget);

      // Tap AI search item
      await tester.tap(find.text('بحث الذكاء الاصطناعي'));
      await tester.pumpAndSettle();
      expect(selectedValue, equals('ai'));
    });

    testWidgets('TashilSplitButton operates cleanly across Arabic, English, and Hindi', (tester) async {
      for (final locale in [const Locale('ar'), const Locale('en'), const Locale('hi')]) {
        await tester.pumpWidget(
          wrapWithApp(
            Builder(
              builder: (ctx) {
                final loc = AppLocalizations.of(ctx);
                return TashilSplitButton<String>(
                  label: loc.tr('searchModeLocation'),
                  icon: Icons.location_on_outlined,
                  onPressed: () {},
                  items: [
                    TashilSplitButtonItem(
                      value: 'location',
                      label: loc.tr('searchModeLocation'),
                      icon: Icons.location_on_outlined,
                    ),
                    TashilSplitButtonItem(
                      value: 'ai',
                      label: loc.tr('searchModeAi'),
                      icon: Icons.auto_awesome_rounded,
                    ),
                  ],
                );
              },
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TashilSplitButton<String>), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      }
    });

    testWidgets('TashilSplitButton morphs trailing button into circle with rotating chevron on open', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          TashilSplitButton<String>(
            label: 'تعديل',
            icon: Icons.edit_rounded,
            onPressed: () {},
            items: const [
              TashilSplitButtonItem(value: 'opt1', label: 'الخيار الأول'),
              TashilSplitButtonItem(value: 'opt2', label: 'الخيار الثاني'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially chevron rotation turns is 0.0 (pointing down)
      final initialRotations = tester.widgetList<AnimatedRotation>(find.byType(AnimatedRotation));
      expect(initialRotations.first.turns, equals(0.0));

      // Tap chevron to open menu
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump(const Duration(milliseconds: 50));

      // After opening, chevron turns to 0.5 (180 deg pointing up)
      final openRotations = tester.widgetList<AnimatedRotation>(find.byType(AnimatedRotation));
      expect(openRotations.first.turns, equals(0.5));
      await tester.pumpAndSettle();
    });
  });
}
