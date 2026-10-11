import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';

void main() {
  group('Material Design 3 (M3) Dividers Suite Tests', () {
    testWidgets('TashilDivider.fullWidth renders with 0 insets, 1dp thickness and outlineVariant color', (tester) async {
      const testColor = Color(0xFFE2E8F0);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(outlineVariant: testColor),
          ),
          home: const Scaffold(
            body: TashilDivider.fullWidth(),
          ),
        ),
      );

      final dividerFinder = find.byType(TashilDivider);
      expect(dividerFinder, findsOneWidget);

      final TashilDivider divider = tester.widget(dividerFinder);
      expect(divider.variant, equals(TashilDividerVariant.fullWidth));
      expect(divider.startIndent, equals(0.0));
      expect(divider.endIndent, equals(0.0));
      expect(divider.thickness, equals(1.0));
      expect(divider.height, equals(1.0));

      final containerFinder = find.descendant(
        of: dividerFinder,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);
      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(testColor));
    });

    testWidgets('TashilDivider.inset has correct startIndent and respects RTL / LTR directionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: const Scaffold(
              body: Column(
                children: [
                  TashilDivider.inset(startIndent: 16.0),
                  TashilDivider.listTextInset(),
                ],
              ),
            ),
          ),
        ),
      );

      final dividers = tester.widgetList<TashilDivider>(find.byType(TashilDivider)).toList();
      expect(dividers.length, equals(2));

      // 1. Standard inset
      expect(dividers[0].startIndent, equals(16.0));
      expect(dividers[0].endIndent, equals(0.0));

      // 2. List item text inset (72dp)
      expect(dividers[1].startIndent, equals(72.0));
      expect(dividers[1].endIndent, equals(0.0));

      // Check EdgeInsetsDirectional margin
      final containers = tester.widgetList<Container>(
        find.descendant(of: find.byType(TashilDivider), matching: find.byType(Container)),
      ).toList();
      final margin1 = containers[0].margin as EdgeInsetsDirectional;
      expect(margin1.start, equals(16.0));
      expect(margin1.end, equals(0.0));

      final margin2 = containers[1].margin as EdgeInsetsDirectional;
      expect(margin2.start, equals(72.0));
      expect(margin2.end, equals(0.0));
    });

    testWidgets('TashilDivider.middleInset applies symmetrical start and end insets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TashilDivider.middleInset(inset: 24.0),
          ),
        ),
      );

      final dividerFinder = find.byType(TashilDivider);
      expect(dividerFinder, findsOneWidget);

      final TashilDivider divider = tester.widget(dividerFinder);
      expect(divider.variant, equals(TashilDividerVariant.middleInset));
      expect(divider.startIndent, equals(24.0));
      expect(divider.endIndent, equals(24.0));
    });

    testWidgets('TashilDivider.cardAction implements M3 DO rule separating content from interactive actions', (tester) async {
      bool buttonClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TashilCard.outlined(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Non-interactive Card Body Content'),
                  ),
                  const TashilDivider.cardAction(),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TashilButton(
                      label: 'Read more',
                      onPressed: () => buttonClicked = true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Non-interactive Card Body Content'), findsOneWidget);
      expect(find.byType(TashilDivider), findsOneWidget);
      expect(find.text('Read more'), findsOneWidget);

      await tester.tap(find.text('Read more'));
      await tester.pump();
      expect(buttonClicked, isTrue);
    });

    testWidgets('TashilVerticalDivider renders with 1dp thickness and optional top/bottom insets', (tester) async {
      const testColor = Color(0xFF64748B);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(outlineVariant: testColor),
          ),
          home: const Scaffold(
            body: SizedBox(
              height: 100,
              child: Row(
                children: [
                  Text('Item 1'),
                  TashilVerticalDivider.inset(inset: 8.0),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        ),
      );

      final vDividerFinder = find.byType(TashilVerticalDivider);
      expect(vDividerFinder, findsOneWidget);

      final TashilVerticalDivider vDivider = tester.widget(vDividerFinder);
      expect(vDivider.thickness, equals(1.0));
      expect(vDivider.topIndent, equals(8.0));
      expect(vDivider.bottomIndent, equals(8.0));

      final containerFinder = find.descendant(
        of: vDividerFinder,
        matching: find.byType(Container),
      );
      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(testColor));
    });

    testWidgets('TashilDivider.withLabel renders text label flanked by divider lines and optional icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TashilDivider.withLabel(
              label: 'أو الاستمرار كزائر',
              leadingIcon: const Icon(Icons.person_outline),
            ),
          ),
        ),
      );

      expect(find.byType(TashilLabelledDivider), findsOneWidget);
      expect(find.text('أو الاستمرار كزائر'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      // Verify that there are 2 Expanded divider lines flanking the label
      final expandedLines = find.descendant(
        of: find.byType(TashilLabelledDivider),
        matching: find.byType(Expanded),
      );
      expect(expandedLines, findsNWidgets(2));
    });

    testWidgets('M3DividersShowcaseDialog renders and allows comparison toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: M3DividersShowcaseDialog(),
          ),
        ),
      );

      expect(find.byType(M3DividersShowcaseDialog), findsOneWidget);
      expect(find.text('DO'), findsNWidgets(2));
      expect(find.text('CAUTION'), findsOneWidget);

      // Verify toggle button exists
      final toggleBtnFinder = find.byType(TashilButton).first;
      expect(toggleBtnFinder, findsOneWidget);

      // Tap toggle to show cluttered comparison
      await tester.tap(toggleBtnFinder);
      await tester.pump();
    });
  });
}
