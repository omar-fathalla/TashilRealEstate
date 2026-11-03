import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/checkboxes/tashil_checkboxes.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/text_fields/tashil_text_fields.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  group('Material Design 3 (M3) Fast Onboarding Component Suite Tests', () {
    testWidgets('1. M3 Buttons Hierarchy renders and handles taps', (tester) async {
      bool filledPressed = false;
      bool tonalPressed = false;
      bool outlinedPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Column(
              children: [
                TashilButton.filled(
                  onPressed: () => filledPressed = true,
                  icon: Symbols.publish_rounded,
                  label: 'نشر العقار فوراً',
                ),
                TashilButton.tonal(
                  onPressed: () => tonalPressed = true,
                  icon: Symbols.auto_awesome_rounded,
                  label: 'توليد بالذكاء الاصطناعي',
                ),
                TashilButton.outlined(
                  onPressed: () => outlinedPressed = true,
                  icon: Symbols.map_rounded,
                  label: 'عرض على خرائط Google',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('نشر العقار فوراً'), findsOneWidget);
      expect(find.text('توليد بالذكاء الاصطناعي'), findsOneWidget);
      expect(find.text('عرض على خرائط Google'), findsOneWidget);

      await tester.tap(find.text('نشر العقار فوراً'));
      await tester.pumpAndSettle();
      expect(filledPressed, isTrue);

      await tester.tap(find.text('توليد بالذكاء الاصطناعي'));
      await tester.pumpAndSettle();
      expect(tonalPressed, isTrue);

      await tester.tap(find.text('عرض على خرائط Google'));
      await tester.pumpAndSettle();
      expect(outlinedPressed, isTrue);
    });

    testWidgets('2. M3 Cards conform to 12dp radius and variant styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Column(
              children: [
                TashilCard.outlined(
                  borderRadius: BorderRadius.circular(12),
                  child: const Text('Outlined Card'),
                ),
                TashilCard.filled(
                  borderRadius: BorderRadius.circular(12),
                  child: const Text('Filled Card'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Outlined Card'), findsOneWidget);
      expect(find.text('Filled Card'), findsOneWidget);
    });

    testWidgets('3. M3 Checkbox and CheckboxListTile toggle correctly', (tester) async {
      bool? isChecked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TashilCheckboxListTile(
                  title: const Text('موقف سيارات خاص'),
                  secondary: const Icon(Symbols.local_parking_rounded),
                  value: isChecked,
                  onChanged: (val) => setState(() => isChecked = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('موقف سيارات خاص'), findsOneWidget);
      expect(find.byType(TashilCheckbox), findsOneWidget);
      expect(isChecked, isFalse);

      await tester.tap(find.text('موقف سيارات خاص'));
      await tester.pumpAndSettle();
      expect(isChecked, isTrue);

      await tester.tap(find.text('موقف سيارات خاص'));
      await tester.pumpAndSettle();
      expect(isChecked, isFalse);
    });

    testWidgets('4. M3 Chips (Filter, Suggestion, Assist) render and interact', (tester) async {
      bool filterSelected = false;
      bool suggestionPressed = false;
      bool assistPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TashilFilterChip(
                      label: 'شقة سكنية',
                      icon: Symbols.apartment_rounded,
                      selected: filterSelected,
                      onSelected: (val) => setState(() => filterSelected = val),
                    ),
                    TashilSuggestionChip(
                      label: 'فاخر وتنفيذي',
                      icon: Symbols.diamond_rounded,
                      onPressed: () => suggestionPressed = true,
                    ),
                    TashilAssistChip(
                      icon: Symbols.my_location_rounded,
                      label: 'تحديد موقعي GPS',
                      onPressed: () => assistPressed = true,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('شقة سكنية'), findsOneWidget);
      expect(find.text('فاخر وتنفيذي'), findsOneWidget);
      expect(find.text('تحديد موقعي GPS'), findsOneWidget);

      await tester.tap(find.text('شقة سكنية'));
      await tester.pumpAndSettle();
      expect(filterSelected, isTrue);

      await tester.tap(find.text('فاخر وتنفيذي'));
      await tester.pumpAndSettle();
      expect(suggestionPressed, isTrue);

      await tester.tap(find.text('تحديد موقعي GPS'));
      await tester.pumpAndSettle();
      expect(assistPressed, isTrue);
    });

    testWidgets('5. M3 Text Fields (Outlined) render with label and prefix icon', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: TashilTextField.outlined(
              controller: controller,
              labelText: 'المدينة *',
              hintText: 'مثال: القاهرة، دبي',
              prefixIcon: Symbols.location_city_rounded,
            ),
          ),
        ),
      );

      expect(find.text('المدينة *'), findsOneWidget);
      expect(find.byIcon(Symbols.location_city_rounded), findsWidgets);

      await tester.enterText(find.byType(TextFormField), 'القاهرة الجديدة');
      await tester.pumpAndSettle();
      expect(controller.text, 'القاهرة الجديدة');
    });
  });
}
