import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(
    Widget child, {
    Locale locale = const Locale('ar'),
    M3ThemePalette palette = M3ThemePalette.forestGreen,
  }) {
    ThemePaletteController.instance.setPalette(palette);

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
          seedColor: palette.color,
          primary: palette.color,
        ),
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Google Material Design 3 (M3) SnackBar Suite Tests', () {
    testWidgets('TashilSnackBar.showSuccess renders message, icon, and floating container', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          palette: M3ThemePalette.forestGreen,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TashilSnackBar.showSuccess(
                  context: context,
                  message: 'تم نسخ رابط العقار بنجاح',
                );
              },
              child: const Text('Show Success'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Check message and success icon
      expect(find.text('تم نسخ رابط العقار بنجاح'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Verify SnackBar attributes (floating behavior, 8dp radius)
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.elevation, 6.0);
      expect(snackBar.shape, isA<RoundedRectangleBorder>());
      final shape = snackBar.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8.0));
      expect(snackBar.width, 520.0); // Clamped on wide screen (1200dp)
    });

    testWidgets('TashilSnackBar.showError renders error tone, action button, and close icon', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        wrapWithTheme(
          palette: M3ThemePalette.warmTerracotta,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TashilSnackBar.showError(
                  context: context,
                  title: 'خطأ في الشبكة',
                  message: 'تعذر الاتصال بالخادم الرئيسي',
                  action: TashilSnackBarAction(
                    label: 'إعادة المحاولة',
                    onPressed: () {
                      actionTriggered = true;
                    },
                  ),
                  showCloseIcon: true,
                );
              },
              child: const Text('Show Error'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('خطأ في الشبكة'), findsOneWidget);
      expect(find.text('تعذر الاتصال بالخادم الرئيسي'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap action button
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
      // SnackBar dismissed after action tap
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('TashilSnackBar close affordance dismisses snackbar immediately', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TashilSnackBar.showInfo(
                  context: context,
                  message: 'تحديث بيانات العقار',
                  showCloseIcon: true,
                );
              },
              child: const Text('Show Info'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('TashilSnackBar responsive layout adapts to mobile screen width', (tester) async {
      tester.view.physicalSize = const Size(380, 700); // Mobile width < 600dp
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TashilSnackBar.showWarning(
                  context: context,
                  message: 'مهلة الحجز أوشكت على الانتهاء',
                );
              },
              child: const Text('Show Warning'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      // On mobile screen (< 600dp), width is null and margin is used
      expect(snackBar.width, isNull);
      expect(snackBar.margin, isNotNull);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('TashilSnackBar enforces No Stacking rule by dismissing active snackbar', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    TashilSnackBar.showInfo(
                      context: context,
                      message: 'الإشعار الأول',
                    );
                  },
                  child: const Text('First SnackBar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    TashilSnackBar.showSuccess(
                      context: context,
                      message: 'الإشعار الثاني',
                    );
                  },
                  child: const Text('Second SnackBar'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('First SnackBar'));
      await tester.pumpAndSettle();
      expect(find.text('الإشعار الأول'), findsOneWidget);

      await tester.tap(find.text('Second SnackBar'));
      await tester.pumpAndSettle();

      // Only the second snackbar should be visible (No stacking)
      expect(find.text('الإشعار الأول'), findsNothing);
      expect(find.text('الإشعار الثاني'), findsOneWidget);
    });

    testWidgets('M3SnackbarShowcaseDialog renders all 4 tone previews and 5 theme palettes', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => M3SnackbarShowcaseDialog.show(context),
              child: const Text('Open Showcase'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Showcase'));
      await tester.pumpAndSettle();

      expect(find.byType(M3SnackbarShowcaseDialog), findsOneWidget);
      // Verify preview buttons exist for all 4 tones
      expect(find.text('معاينة'), findsNWidgets(4));

      // Verify M3 specification rules are displayed
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });
  });
}
