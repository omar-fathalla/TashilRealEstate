import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/widgets/font_picker_dialog.dart';
import 'package:tashil_real_estate/features/smart_valuation/widgets/district_location_picker_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget home, {Locale locale = const Locale('en')}) {
    LocaleController.setLocale(locale);
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }

  Future<void> openSheet(WidgetTester tester, String label, Type sheet) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () {
            if (sheet == AppSettingsDialog) {
              AppSettingsDialog.show(context);
            } else {
              FontPickerDialog.show(context);
            }
          },
          child: Text(label),
        ),
      ),
    )));
    await tester.pump();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.byWidgetPredicate((widget) => widget.runtimeType == sheet), findsOneWidget);
  }

  testWidgets('settings opens as a sheet on a phone', (tester) async {
    await openSheet(tester, 'open-settings', AppSettingsDialog);
  });

  testWidgets('font picker opens as a sheet on a phone', (tester) async {
    await openSheet(tester, 'open-fonts', FontPickerDialog);
  });

  testWidgets('English district picker uses Select', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => DistrictLocationPickerDialog.show(context, countryCode: 'AE'),
          child: const Text('open-district'),
        ),
      ),
    )));
    await tester.pump();
    await tester.tap(find.text('open-district'));
    await tester.pumpAndSettle();

    expect(find.text('Select'), findsWidgets);
    expect(find.text('Select country'), findsNothing);
  });
}
