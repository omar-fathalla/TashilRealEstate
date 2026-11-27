// TAQ-159: the header palette switcher and the rent-collection row actions have 48dp tap targets.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';

Widget _app(Widget body) {
  LocaleController.setLocale(const Locale('ar'));
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: body),
  );
}

void _setView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _expectAtLeast48(WidgetTester tester, Finder target, String what) {
  final size = tester.getSize(target);
  expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension),
      reason: '$what width $size');
  expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension),
      reason: '$what height $size');
}

Finder _inkWellAround(Finder child) =>
    find.ancestor(of: child, matching: find.byType(InkWell)).first;

void main() {
  testWidgets('palette swatches and the dark toggle are 48x48 on a wide screen',
      (tester) async {
    _setView(tester, const Size(1366, 900));
    await tester.pumpWidget(
        _app(const Center(child: ThemePaletteSwitcher(isCompact: true))));
    await tester.pumpAndSettle();

    final swatches = find.descendant(
        of: find.byType(ThemePaletteSwitcher), matching: find.byType(InkWell));
    // 5 swatches + the IconButton's own InkWell.
    expect(swatches, findsNWidgets(M3ThemePalette.values.length + 1));
    for (var i = 0; i < M3ThemePalette.values.length + 1; i++) {
      _expectAtLeast48(tester, swatches.at(i), 'swatch/toggle $i');
    }
    _expectAtLeast48(tester, find.byType(IconButton), 'dark toggle');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'compact switcher on a phone folds the swatches into one 48dp menu',
      (tester) async {
    _setView(tester, const Size(390, 844));
    await tester.pumpWidget(
        _app(const Center(child: ThemePaletteSwitcher(isCompact: true))));
    await tester.pumpAndSettle();

    final menu = find.byKey(const ValueKey('theme-palette-menu'));
    expect(menu, findsOneWidget);
    _expectAtLeast48(tester, menu, 'palette menu');
    _expectAtLeast48(tester, find.byType(IconButton), 'dark toggle');

    await tester.tap(menu);
    await tester.pumpAndSettle();
    final target = M3ThemePalette.values.last;
    await tester.tap(find.text(target.getLocalizedName('ar')).last);
    await tester.pumpAndSettle();
    expect(ThemePaletteController.instance.currentPalette.value, target);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'rent-collection row actions and تذكير have 48dp targets and do not collapse',
      (tester) async {
    _setView(tester, const Size(1366, 900));
    await tester.pumpWidget(_app(const RentCollectionView()));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);

    for (final tip in ['عرض التفاصيل', 'تعديل الفاتورة', 'نقل إلى المحذوفات']) {
      final tips = find.byTooltip(tip);
      expect(tips, findsWidgets, reason: tip);
      for (var i = 0; i < tips.evaluate().length; i++) {
        _expectAtLeast48(
            tester,
            find
                .descendant(of: tips.at(i), matching: find.byType(InkWell))
                .first,
            '$tip #$i');
      }
    }

    final reminders = find.text('تذكير');
    expect(reminders, findsWidgets);
    for (var i = 0; i < reminders.evaluate().length; i++) {
      _expectAtLeast48(tester, _inkWellAround(reminders.at(i)), 'تذكير #$i');
      // The label itself is laid out at full width (not clipped to a sliver).
      expect(tester.getSize(reminders.at(i)).width, greaterThan(15),
          reason: 'تذكير #$i label');
    }
    expect(tester.takeException(), isNull);
  });
}
