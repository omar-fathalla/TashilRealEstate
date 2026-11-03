import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/font_theme_controller.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/widgets/font_picker_dialog.dart';
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
      home: Scaffold(body: child),
    );
  }

  group('AppSettingsDialog & FontPickerDialog M3 Suite Tests', () {
    setUp(() {
      UserProfileService().profileNotifier.value = const UserProfileData(
        uid: 'super-admin-test',
        email: 'admin@tashil.ae',
        fullName: 'مشرف عام',
        role: 'SuperAdmin',
      );
    });

    testWidgets('Renders AppSettingsDialog with M3 Connected Groups, Google Icons, and Typography Card', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSettingsDialog.show(context),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Verify header & close button
      expect(find.byIcon(Symbols.tune_rounded), findsWidgets);
      expect(find.byIcon(Symbols.close_rounded), findsWidgets);

      // Verify Google Icons in Quick Controls (Zero raw emojis)
      expect(find.byIcon(Symbols.flag_rounded), findsWidgets);
      expect(find.byIcon(Symbols.translate_rounded), findsWidgets);
      expect(find.byIcon(Symbols.light_mode_rounded), findsWidgets);
      expect(find.byIcon(Symbols.dark_mode_rounded), findsWidgets);

      // Verify Color Palette Section
      expect(find.byIcon(Symbols.palette_rounded), findsWidgets);
      expect(find.text('لوحة الألوان'), findsOneWidget);

      // Verify Typography Section contains a card and NOT the cluttered 12-button grid
      expect(find.byIcon(Symbols.font_download_rounded), findsWidgets);
      expect(find.text('الخطوط'), findsOneWidget);
      expect(find.text('تغيير الخط'), findsWidgets);
      // Ensure specific font names from the old raw grid are not scattered directly in the main dialog
      expect(find.text('Lemonada'), findsNothing);
      expect(find.text('Scheherazade'), findsNothing);
      expect(find.text('Lateef'), findsNothing);
    });

    testWidgets('Tapping change font opens dedicated FontPickerDialog with category filters & live previews', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSettingsDialog.show(context),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open settings dialog
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Tap on the Font Card to trigger FontPickerDialog
      await tester.tap(find.text('تغيير الخط').first);
      await tester.pumpAndSettle();

      // Verify FontPickerDialog is displayed
      expect(find.byType(FontPickerDialog), findsOneWidget);
      expect(find.text('اختيار خط التطبيق'), findsOneWidget);
      expect(find.text('جميع الخطوط'), findsOneWidget);
      expect(find.byIcon(Symbols.auto_awesome_rounded), findsWidgets);
      expect(find.byIcon(Symbols.title_rounded), findsWidgets);
      expect(find.byIcon(Symbols.menu_book_rounded), findsWidgets);

      // Only Cairo is offered. Tajawal and Lemonada are not choices.
      expect(find.textContaining('Cairo'), findsWidgets);
      expect(find.textContaining('Changa'), findsNothing);
      expect(find.textContaining('Lemonada'), findsNothing);
      expect(FontThemeController.instance.activeFont, AppFontTheme.cairo);

      // Close modal using Apply button
      await tester.tap(find.text('تطبيق الخط'));
      await tester.pumpAndSettle();

      // Reset back to Cairo
      FontThemeController.instance.setFont(AppFontTheme.cairo);
    });

    testWidgets('Works seamlessly in English LTR mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(
        wrapWithApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSettingsDialog.show(context),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Color palette'), findsOneWidget);
      expect(find.text('Fonts'), findsOneWidget);
      expect(find.text('Change font'), findsWidgets);
    });
  });
}
