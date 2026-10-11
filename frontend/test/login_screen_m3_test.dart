import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button_group.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp({
    Locale locale = const Locale('ar'),
    required Widget child,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
        ),
      ),
      home: child,
    );
  }

  group('LoginScreen M3 Suite Tests', () {
    testWidgets('Header retains ONLY Settings icon without country/language/theme switchers', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify the AppBar actions have only the Settings icon
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Verify country, language, and theme switchers are REMOVED from the AppBar
      expect(find.text('مصر'), findsNothing);
      expect(find.text('الإمارات'), findsNothing);
      expect(find.text('عربي'), findsNothing);
    });

    testWidgets('Renders M3 TashilConnectedButtonGroup for Role Selection and Auth Methods', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify Connected Button Groups exist (Role + Auth Method)
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<AuthMethod>), findsOneWidget);

      // Verify Role Segments with Google Icons
      expect(find.byIcon(Icons.person_rounded), findsWidgets);
      expect(find.byIcon(Icons.business_rounded), findsWidgets);
      expect(find.byIcon(Icons.home_rounded), findsWidgets);
      expect(find.byIcon(Icons.shield_rounded), findsWidgets);

      // Verify Auth Method Segments
      expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);
      expect(find.byIcon(Icons.apple_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.smartphone_rounded), findsOneWidget);
    });

    testWidgets('Switching auth methods transitions smoothly to Google and Phone OTP forms', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Switch to Google Auth
      await tester.tap(find.byIcon(Icons.g_mobiledata_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.account_circle_rounded), findsOneWidget);

      // Switch to Phone OTP
      await tester.tap(find.byIcon(Icons.smartphone_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Empty email submission triggers TashilSnackBar validation notification', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Switch to Email Auth tab
      await tester.tap(find.byIcon(Icons.mail_outline_rounded));
      await tester.pumpAndSettle();

      // Tap Sign In button with empty fields
      await tester.tap(find.byIcon(Icons.login_rounded));
      await tester.pump(); // Start snackbar animation
      await tester.pump(const Duration(milliseconds: 300));

      // Verify SnackBar appears
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Renders properly in English LTR mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(locale: const Locale('en'), child: const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('Phone OTP input row is strictly LTR even in Arabic RTL mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('ar');

      await tester.pumpWidget(wrapWithApp(locale: const Locale('ar'), child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Switch to Phone OTP tab
      await tester.tap(find.byIcon(Icons.smartphone_rounded));
      await tester.pumpAndSettle();

      // Ensure translated label is present, and raw key is absent
      expect(find.text('رقم الهاتف'), findsOneWidget);
      expect(find.text('phoneNumberLabel'), findsNothing);

      // Verify dial code (+20) is on the LEFT of the phone TextField in Arabic RTL
      final dialCodePos = tester.getTopLeft(find.text('+20'));
      final textFieldPos = tester.getTopLeft(find.byType(TextField));
      expect(dialCodePos.dx, lessThan(textFieldPos.dx));

      // Verify TextField properties
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textDirection, TextDirection.ltr);
      expect(textField.textAlign, TextAlign.left);
    });
  });
}
