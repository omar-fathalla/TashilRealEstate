import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button_group.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';
import 'package:tashil_real_estate/features/rent_collection/tenant_checkout_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      expect(find.byIcon(Symbols.tune_rounded), findsWidgets);

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

      // Verify Role Segments with Google Icons (Owner, Agency, Tenant only - SuperAdmin is isolated to its dedicated portal)
      expect(find.byIcon(Symbols.person_rounded), findsWidgets);
      expect(find.byIcon(Symbols.business_rounded), findsWidgets);
      expect(find.byIcon(Symbols.home_rounded), findsWidgets);
      expect(find.byIcon(Symbols.shield_rounded), findsNothing);

      // Verify Auth Method Segments
      expect(find.byIcon(Symbols.g_mobiledata_rounded), findsWidgets);
      expect(find.byIcon(Icons.apple_rounded), findsOneWidget);
      expect(find.byIcon(Symbols.mail_outline_rounded), findsWidgets);
      expect(find.byIcon(Symbols.smartphone_rounded), findsWidgets);
    });

    testWidgets('Switching auth methods transitions smoothly to Google and Phone OTP forms', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Switch to Google Auth
      await tester.tap(find.byIcon(Symbols.g_mobiledata_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Symbols.account_circle_rounded), findsWidgets);

      // Switch to Phone OTP
      await tester.tap(find.byIcon(Symbols.smartphone_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Symbols.send_rounded), findsWidgets);
    });

    testWidgets('Empty email submission triggers TashilSnackBar validation notification', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Switch to Email Auth tab
      await tester.tap(find.byIcon(Symbols.mail_outline_rounded).first);
      await tester.pumpAndSettle();

      // Tap Sign In button with empty fields
      await tester.tap(find.byIcon(Symbols.login_rounded));
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

      expect(find.byIcon(Symbols.tune_rounded), findsWidgets);
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('Phone OTP input row is strictly LTR even in Arabic RTL mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('ar');

      await tester.pumpWidget(wrapWithApp(locale: const Locale('ar'), child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Switch to Phone OTP tab
      await tester.tap(find.byIcon(Symbols.smartphone_rounded));
      await tester.pumpAndSettle();

      // Ensure translated label is present, and raw key is absent
      expect(find.text('رقم الهاتف'), findsOneWidget);
      expect(find.text('phoneNumberLabel'), findsNothing);

      // Verify dial code (+971) is on the LEFT of the phone TextField in Arabic RTL
      final dialCodePos = tester.getTopLeft(find.text('+971'));
      final textFieldPos = tester.getTopLeft(find.byType(TextField));
      expect(dialCodePos.dx, lessThan(textFieldPos.dx));

      // Verify TextField properties
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textDirection, TextDirection.ltr);
      expect(textField.textAlign, TextAlign.left);
    });

    testWidgets('Demo accounts suite and hardcoded test credentials are completely removed for production in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(locale: const Locale('ar'), child: const LoginScreen()));
      await tester.pumpAndSettle();

      // Ensure demo accounts section header and quick login credentials are completely absent
      expect(find.text('حسابات تجريبية سريعة للتجربة:'), findsNothing);
      expect(find.text('Quick demo accounts:'), findsNothing);
      expect(find.text('owner@test.com'), findsNothing);
      expect(find.text('agency@test.com'), findsNothing);
      expect(find.text('tenant@test.com'), findsNothing);
      expect(find.text('password123'), findsNothing);

      // Verify that the public visitor browsing link remains functional
      expect(find.byIcon(Symbols.travel_explore_rounded), findsWidgets);
    });

    testWidgets('Demo accounts suite is completely absent in English LTR mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(locale: const Locale('en'), child: const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Quick demo accounts:'), findsNothing);
      expect(find.text('owner@test.com'), findsNothing);
      expect(find.text('agency@test.com'), findsNothing);
      expect(find.text('tenant@test.com'), findsNothing);
      expect(find.text('password123'), findsNothing);
    });

    test('FirebaseAuthService does not synthesize mock credentials on Google, Apple, or Email failures', () async {
      final auth = FirebaseAuthService();
      await expectLater(auth.signInWithGoogle(), throwsA(anything));
      await expectLater(auth.signInWithApple(), throwsA(anything));
      await expectLater(auth.signInWithEmailAndPassword('test@example.com', 'pass'), throwsA(anything));
    });

    testWidgets('TenantCheckoutScreen renders official production title without demo prefix', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const TenantCheckoutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('سداد الإيجار والتحويل الفوري'), findsWidgets);
      expect(find.text('تجربة الدفع الفوري (Google Pay / Apple Pay)'), findsNothing);
    });
  });
}
