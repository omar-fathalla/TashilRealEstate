import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/lists/tashil_lists.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child, {TextDirection direction = TextDirection.rtl}) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Material Design 3 Lists & Reordering Suite Tests', () {
    testWidgets('TashilListTile.oneLine adheres to 56dp height and 48dp dense spec', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: [
              TashilListTile.oneLine(
                headline: const Text('عنوان السطر الواحد'),
                leading: const Icon(Icons.apartment_rounded),
                trailing: const Text('23,000 ج.م'),
              ),
              TashilListTile.oneLine(
                headline: const Text('سطر واحد مكثف'),
                dense: true,
              ),
            ],
          ),
        ),
      );

      final standardTile = find.byWidgetPredicate(
        (w) => w is TashilListTile && !w.dense,
      );
      final denseTile = find.byWidgetPredicate(
        (w) => w is TashilListTile && w.dense,
      );

      expect(tester.getSize(standardTile).height, greaterThanOrEqualTo(56.0));
      expect(tester.getSize(denseTile).height, greaterThanOrEqualTo(48.0));
      expect(find.text('عنوان السطر الواحد'), findsOneWidget);
    });

    testWidgets('TashilListTile.twoLine adheres to 72dp height and 64dp dense spec', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: [
              TashilListTile.twoLine(
                headline: const Text('شقة فاخرة بالتجمع الخامس'),
                supportingText: const Text('القاهرة الجديدة • برج الياسمين'),
                leading: const Icon(Icons.home_work_rounded),
              ),
              TashilListTile.twoLine(
                headline: const Text('فيلا مستقلة'),
                supportingText: const Text('الشيخ زايد'),
                dense: true,
              ),
            ],
          ),
        ),
      );

      final standardTile = find.byWidgetPredicate(
        (w) => w is TashilListTile && !w.dense,
      );
      final denseTile = find.byWidgetPredicate(
        (w) => w is TashilListTile && w.dense,
      );

      expect(tester.getSize(standardTile).height, greaterThanOrEqualTo(72.0));
      expect(tester.getSize(denseTile).height, greaterThanOrEqualTo(64.0));
      expect(find.text('شقة فاخرة بالتجمع الخامس'), findsOneWidget);
      expect(find.text('القاهرة الجديدة • برج الياسمين'), findsOneWidget);
    });

    testWidgets('TashilListTile.threeLine adheres to 88dp height spec', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilListTile.threeLine(
            overline: const Text('عقار متميز'),
            headline: const Text('شقة مطلة على النيل - جاردن سيتي'),
            supportingText: const Text('3 غرف نوم • 2 حمام • 210 متر مربع'),
            leading: const Icon(Icons.water_rounded),
            trailing: const Text('21,000 ج.م'),
          ),
        ),
      );

      final threeLineTile = find.byType(TashilListTile);
      expect(tester.getSize(threeLineTile).height, greaterThanOrEqualTo(88.0));
      expect(find.text('عقار متميز'), findsOneWidget);
      expect(find.text('شقة مطلة على النيل - جاردن سيتي'), findsOneWidget);
      expect(find.text('3 غرف نوم • 2 حمام • 210 متر مربع'), findsOneWidget);
    });

    testWidgets('TashilReorderableList renders items and fires onReorder callback', (tester) async {
      final items = ['عقار أ', 'عقار ب', 'عقار ج'];
      int? reorderOld;
      int? reorderNew;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilReorderableList<String>(
            items: items,
            onReorder: (oldIdx, newIdx) {
              reorderOld = oldIdx;
              reorderNew = newIdx;
            },
            itemBuilder: (context, index, item) {
              return TashilListTile(
                key: ValueKey('item-$item'),
                leading: TashilReorderHandle(index: index),
                headline: Text(item),
              );
            },
          ),
        ),
      );

      expect(find.text('عقار أ'), findsOneWidget);
      expect(find.text('عقار ب'), findsOneWidget);
      expect(find.text('عقار ج'), findsOneWidget);

      // Verify drag handles are present
      expect(find.byType(TashilReorderHandle), findsNWidgets(3));

      // Test drag from handle of first item to third item
      final firstHandle = find.byType(TashilReorderHandle).first;
      await tester.drag(firstHandle, const Offset(0, 150));
      await tester.pumpAndSettle();

      expect(reorderOld, isNotNull);
      expect(reorderNew, isNotNull);
    });

    testWidgets('TashilListTile responds to selection and tap interactions', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilListTile(
            headline: const Text('عنصر قابل للنقر'),
            selected: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('عنصر قابل للنقر'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('M3ListsShowcaseDialog opens and displays 1, 2, 3 line items and reorderable list', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => M3ListsShowcaseDialog.show(context),
              child: const Text('عرض القوائم'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('عرض القوائم'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.byType(M3ListsShowcaseDialog), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is TashilReorderableList), findsOneWidget);
    });
  });
}
