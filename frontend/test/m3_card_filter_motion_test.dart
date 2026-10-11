import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TashilCardFilterMotion Suite Tests', () {
    testWidgets('renders items with Staggered Entrance and updates smoothly on filterKey change', (tester) async {
      final items = ['Card 1', 'Card 2', 'Card 3'];
      String currentFilter = 'all';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => currentFilter = 'filtered'),
                      child: const Text('Filter'),
                    ),
                    TashilCardFilterMotion<String>(
                      items: currentFilter == 'all' ? items : [items.first],
                      filterKey: currentFilter,
                      itemBuilder: (context, item, index) => Text(item),
                      emptyState: const Text('No cards found'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('Card 3'), findsOneWidget);
      expect(find.byType(TashilStaggeredEntrance), findsNWidgets(3));

      // Tap to filter
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsNothing);
      expect(find.text('Card 3'), findsNothing);
      expect(find.byType(TashilStaggeredEntrance), findsOneWidget);
    });

    testWidgets('renders emptyState when items list is empty with smooth transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TashilCardFilterMotion<String>(
              items: const [],
              filterKey: 'empty',
              itemBuilder: (context, item, index) => Text(item),
              emptyState: const Text('فارغ تماماً'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فارغ تماماً'), findsOneWidget);
      expect(find.byType(TashilStaggeredEntrance), findsNothing);
    });
  });
}
