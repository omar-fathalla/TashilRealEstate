import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/app_theme.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Arabic mobile header keeps the brand on the right and a mirrored back arrow', (tester) async {
    LocaleController.setLocale(const Locale('ar'));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_app(const PublicHeaderNavbar(isSubPage: true)));
    await tester.pump();

    expect(find.text('تسهيل عقار'), findsOneWidget);
    expect(find.text('Tashil Aqar'), findsNothing);
    expect(find.byIcon(Symbols.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.arrow_forward_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English mobile header uses the English brand and a back arrow', (tester) async {
    LocaleController.setLocale(const Locale('en'));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_app(const PublicHeaderNavbar(isSubPage: true)));
    await tester.pump();

    expect(find.text('Tashil Aqar'), findsOneWidget);
    expect(find.byIcon(Symbols.arrow_back_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home) {
  return MaterialApp(
    locale: LocaleController.currentLocale.value,
    theme: AppTheme.getTheme(brightness: Brightness.light, locale: LocaleController.currentLocale.value),
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(appBar: home as PreferredSizeWidget),
  );
}
