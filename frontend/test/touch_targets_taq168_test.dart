// TAQ-168: 48dp tap targets on web and desktop for buttons, icon buttons, chips and the
// connected button groups (rent view toggle, login role and sign-in method).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';

Widget _app(Widget body, {MaterialTapTargetSize? tapTargetSize}) => MaterialApp(
      theme: ThemeData(useMaterial3: true, materialTapTargetSize: tapTargetSize),
      home: Scaffold(body: Center(child: body)),
    );

Finder _inkWellAround(Finder child) => find.ancestor(of: child, matching: find.byType(InkWell)).first;

void main() {
  test('the app theme pads tap targets on every platform', () {
    final src = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(src, contains('materialTapTargetSize: MaterialTapTargetSize.padded'));
  });

  testWidgets('on desktop and web, a padded theme gives buttons, icon buttons and chips 48dp', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      // Flutter's desktop default shrink-wraps an icon button to 40dp: the reason for the theme.
      await tester.pumpWidget(_app(IconButton(onPressed: () {}, icon: const Icon(Icons.logout))));
      expect(tester.getSize(find.byType(IconButton)).height, lessThan(kMinInteractiveDimension));

      await tester.pumpWidget(_app(
        Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(key: const ValueKey('icon'), onPressed: () {}, icon: const Icon(Icons.logout)),
          TextButton(key: const ValueKey('text'), onPressed: () {}, child: const Text('Create an account')),
          TashilButton(key: const ValueKey('filled'), onPressed: () {}, icon: Icons.add, label: 'Create invoice'),
          ChoiceChip(key: const ValueKey('chip'), label: const Text('Paid'), selected: false, onSelected: (_) {}),
        ]),
        tapTargetSize: MaterialTapTargetSize.padded,
      ));
      for (final key in ['icon', 'text', 'filled', 'chip']) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension), reason: '$key $size');
        expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension), reason: '$key $size');
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a connected button group at minTapHeight has 48dp segments; the old 44 did not', (tester) async {
    Future<double> segmentHeight(double height) async {
      await tester.pumpWidget(_app(TashilConnectedButtonGroup<String>(
        height: height,
        selectedValue: 'table',
        onSelectionChanged: (_) {},
        segments: const [
          TashilConnectedButtonSegment(value: 'table', label: 'Table', icon: Icons.table_chart_rounded),
          TashilConnectedButtonSegment(value: 'cards', label: 'Cards', icon: Icons.grid_view_rounded),
        ],
      )));
      return tester.getSize(_inkWellAround(find.text('Cards'))).height;
    }

    expect(await segmentHeight(44), lessThan(kMinInteractiveDimension));
    expect(await segmentHeight(TashilConnectedButtonGroup.minTapHeight), greaterThanOrEqualTo(kMinInteractiveDimension));
  });

  test('the reported groups use minTapHeight', () {
    final login = File('lib/features/auth/login_screen.dart').readAsStringSync();
    final rent = File('lib/features/rent_collection/views/rent_collection_view.dart').readAsStringSync();
    expect('height: TashilConnectedButtonGroup.minTapHeight'.allMatches(login).length, 2);
    expect(rent, contains('final viewModeWidget = TashilConnectedButtonGroup<String>(\n      height: TashilConnectedButtonGroup.minTapHeight,'));
  });
}
