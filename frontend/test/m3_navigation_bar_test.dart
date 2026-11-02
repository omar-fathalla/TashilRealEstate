import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/navigation_bar/tashil_navigation_bar.dart';

void main() {
  group('Material Design 3 (M3) TashilNavigationBar & Badges Tests', () {
    testWidgets('renders 4 navigation destinations with labels, icons, and 80dp height',
        (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return TashilNavigationBar(
                  destinations: [
                    TashilNavigationDestination(
                      icon: Icons.add_home_work_outlined,
                      selectedIcon: Icons.add_home_work_rounded,
                      label: 'رفع العقار',
                      isSelected: selected == 0,
                      onTap: () => setState(() => selected = 0),
                    ),
                    TashilNavigationDestination(
                      icon: Icons.auto_awesome_outlined,
                      selectedIcon: Icons.auto_awesome_rounded,
                      label: 'التقييم',
                      badgeLabel: 'AI',
                      isSelected: selected == 1,
                      onTap: () => setState(() => selected = 1),
                    ),
                    TashilNavigationDestination(
                      icon: Icons.analytics_outlined,
                      selectedIcon: Icons.analytics_rounded,
                      label: 'عقار ماب',
                      hasBadgeDot: true,
                      isSelected: selected == 2,
                      onTap: () => setState(() => selected = 2),
                    ),
                    TashilNavigationDestination(
                      icon: Icons.tune_outlined,
                      selectedIcon: Icons.tune_rounded,
                      label: 'الإعدادات',
                      isSelected: selected == 3,
                      onTap: () => setState(() => selected = 3),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify all 4 labels are rendered
      expect(find.text('رفع العقار'), findsOneWidget);
      expect(find.text('التقييم'), findsOneWidget);
      expect(find.text('عقار ماب'), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);

      // Verify AI Badge is rendered
      expect(find.text('AI'), findsOneWidget);

      // Tap on destination 1 (التقييم)
      await tester.tap(find.text('التقييم'));
      await tester.pumpAndSettle();

      expect(selected, equals(1));
    });

    testWidgets('TashilBadge renders text and dot modes accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                TashilBadge.label(
                  label: 'AI',
                  child: Icon(Icons.star),
                ),
                TashilBadge.dot(
                  child: Icon(Icons.notifications),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('AI'), findsOneWidget);
      expect(find.byType(TashilBadge), findsNWidgets(2));
    });
  });
}
