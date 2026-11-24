import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/config/demo_data.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TAQ-26: builds without --dart-define=DEMO_DATA=true have demo data off and no demo password', () {
    expect(DemoData.enabled, isFalse);
    expect(DemoData.password, isEmpty);
  });

  for (final lang in ['ar', 'en', 'hi']) {
    testWidgets('TAQ-26: [$lang] the demo login suite is hidden when DEMO_DATA is false', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      LocaleController.setLanguage(lang);
      addTearDown(() => LocaleController.setLanguage('ar'));

      final locale = Locale(lang);
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(useMaterial3: true),
        home: const LoginScreen(),
      ));
      await tester.pumpAndSettle();

      final loc = AppLocalizations(locale);
      expect(find.text(loc.tr('browseAsVisitor')), findsOneWidget, reason: 'login screen rendered');
      expect(find.text(loc.tr('demoAccounts')), findsNothing);
      expect(find.text(loc.tr('roleSuperAdmin')), findsNothing);
      expect(find.text(loc.tr('roleAgency')), findsNothing);
      expect(find.byIcon(Icons.shield_rounded), findsNothing);
      expect(find.byIcon(Icons.business_rounded), findsNothing);
      expect(find.textContaining('@test.com'), findsNothing);
    });
  }
}
