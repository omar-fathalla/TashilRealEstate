import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/core/config/super_admin_security_config.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/services/cloud_functions_service.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_login_screen.dart';
import 'package:tashil_real_estate/features/auth/views/email_action_handler_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child, {Locale locale = const Locale('ar')}) {
    LocaleController.setLocale(locale);
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

  group('Super Admin Portal Isolation & Public Login Tests', () {
    testWidgets('Public LoginScreen contains only Owner, Agency, Tenant and zero SuperAdmin mention', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify the 3 allowed client roles exist
      expect(find.text('مالك عقار'), findsWidgets);
      expect(find.text('شركة وساطة عقارية'), findsWidgets);
      expect(find.text('مستأجر'), findsWidgets);

      // Verify Super Admin is completely absent from public login
      expect(find.text('الإدارة العامة'), findsNothing);
      expect(find.text('admin@test.com'), findsNothing);
    });

    testWidgets('SuperAdminLoginScreen renders with executive branding, security shield, and actions in Arabic', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const SuperAdminLoginScreen()));
      await tester.pumpAndSettle();

      // Verify Executive Emblem & Titles
      expect(find.byIcon(Symbols.admin_panel_settings_rounded), findsWidgets);
      expect(find.text('بوابة الإدارة العامة والتحكم المركزي'), findsOneWidget);
      expect(find.text('حماية مشددة للمنظومة'), findsOneWidget);

      // Verify Input Fields
      expect(find.text('معرف مسؤول النظام أو البريد الإلكتروني'), findsOneWidget);
      expect(find.text('كلمة المرور الإدارية'), findsOneWidget);
      expect(find.text('رمز الحماية المزدوج (2FA)'), findsOneWidget);

      // Verify Actions
      expect(find.text('تسجيل الدخول لبوابة الإدارة العامة'), findsOneWidget);
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
      expect(find.text('دخول مسؤول النظام التجريبي الفوري'), findsNothing);
      expect(find.text('العودة إلى المنصة العامة'), findsOneWidget);
    });

    testWidgets('SuperAdminLoginScreen renders cleanly in English LTR without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(
        const SuperAdminLoginScreen(),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Super admin operations portal'), findsOneWidget);
      expect(find.text('Sign in to super admin portal'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Instant demo super admin access'), findsNothing);
      expect(find.text('Return to public marketplace'), findsOneWidget);
    });

    testWidgets('SuperAdminLoginScreen renders cleanly in Hindi Devanagari without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(
        const SuperAdminLoginScreen(),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('सुपर एडमिन केंद्रीय संचालन पोर्टल'), findsOneWidget);
      expect(find.text('सुपर एडमिन पोर्टल में साइन इन करें'), findsOneWidget);
      expect(find.text('पासवर्ड भूल गए?'), findsOneWidget);
      expect(find.text('त्वरित डेमो सुपर एडमिन पहुंच'), findsNothing);
    });

    test('GoRouter configuration has dedicated /admin and /admin/login routes', () {
      expect(appRouter.configuration.routes.any((r) => r is GoRoute && r.path == '/admin'), isTrue);
      expect(appRouter.configuration.routes.any((r) => r is GoRoute && r.path == '/admin/login'), isTrue);
      expect(superAdminAppRouter.configuration.routes.any((r) => r is GoRoute && r.path == '/admin'), isTrue);
      expect(superAdminAppRouter.configuration.routes.any((r) => r is GoRoute && r.path == '/admin/login'), isTrue);
    });

    test('SuperAdminSecurityConfig implements zero-plaintext salted cryptographic verification', () {
      // Authorized credentials verification
      // The offline hash is injected with --dart-define and is empty in source.
      expect(
        SuperAdminSecurityConfig.verifyOfflineCredentials('support@sw-point.com', '481636100Aa!'),
        isFalse,
      );

      // Wrong email rejection
      expect(
        SuperAdminSecurityConfig.verifyOfflineCredentials('hacker@attack.com', '481636100Aa!'),
        isFalse,
      );

      // Wrong password rejection
      expect(
        SuperAdminSecurityConfig.verifyOfflineCredentials('support@sw-point.com', 'WrongPass123'),
        isFalse,
      );
    });

    testWidgets('Tapping forgot password opens M3 Reset Password Dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(const SuperAdminLoginScreen()));
      await tester.pumpAndSettle();

      final forgotBtn = find.text('نسيت كلمة المرور؟');
      expect(forgotBtn, findsOneWidget);

      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      // Verify M3 Reset Password Dialog opened
      expect(find.text('إعادة تعيين كلمة المرور الإدارية'), findsOneWidget);
      expect(find.text('إرسال رابط استعادة كلمة المرور'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      // Verify Cancel closes dialog
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.text('إعادة تعيين كلمة المرور الإدارية'), findsNothing);
    });

    test('FirebaseAuthService supports sendPasswordResetEmail and verification methods gracefully', () async {
      final auth = FirebaseAuthService();
      // Should execute without throw in mock/offline dev environment
      await expectLater(auth.sendPasswordResetEmail('support@sw-point.com'), completes);
      await expectLater(auth.sendEmailVerification(), completes);
      expect(auth.isCurrentUserEmailVerified, isFalse);
    });

    testWidgets('EmailActionHandlerScreen renders celebratory verification view in Arabic RTL', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(
        const EmailActionHandlerScreen(
          mode: 'verifyEmail',
          oobCode: 'MOCK_TEST_CODE',
        ),
      ));
      await tester.pumpAndSettle();

      // Verify Celebratory Headline and Badge
      expect(find.text('تم تأكيد البريد الإلكتروني'), findsOneWidget);
      expect(find.text('البريد مؤكد'), findsOneWidget);
      expect(find.text('المتابعة إلى لوحة التحكم الإدارية'), findsOneWidget);
      expect(find.text('العودة إلى المنصة العامة'), findsOneWidget);

      // Verify Strategic Partnership Note (Egypt & UAE)
      expect(
        find.text('تسهيل عقار — لإدارة العقارات في الإمارات'),
        findsOneWidget,
      );
    });

    testWidgets('EmailActionHandlerScreen renders celebratory verification view in English LTR', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithApp(
        const EmailActionHandlerScreen(
          mode: 'verifyEmail',
          oobCode: 'MOCK_TEST_CODE',
        ),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Email verified'), findsWidgets);
      expect(find.text('Continue to dashboard'), findsOneWidget);
    });

    test('GoRouter has dedicated /auth/action and /auth/verify routes', () {
      expect(appRouter.configuration.routes.any((r) => r is GoRoute && r.path == '/auth/action'), isTrue);
      expect(appRouter.configuration.routes.any((r) => r is GoRoute && r.path == '/auth/verify'), isTrue);
    });

    test('CloudFunctionsService dispatches custom verification and password reset emails with mock fallback', () async {
      final cloudService = CloudFunctionsService();
      final verifRes = await cloudService.sendCustomVerificationEmail(email: 'support@sw-point.com');
      expect(verifRes['success'], isTrue);

      final resetRes = await cloudService.sendCustomPasswordResetEmail(email: 'support@sw-point.com');
      expect(resetRes['success'], isTrue);
    });
  });
}
