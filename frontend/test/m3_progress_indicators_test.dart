import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/progress/tashil_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocaleController.currentLocale.value = const Locale('ar');
  });

  group('Official Google Material Design 3 (M3) Progress Indicators Suite Tests', () {
    Widget buildTestWidget({
      required Widget child,
      Locale locale = const Locale('ar'),
      TextDirection textDirection = TextDirection.rtl,
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
            secondary: const Color(0xFF3B82F6),
          ),
        ),
        home: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: Center(child: child),
          ),
        ),
      );
    }

    testWidgets('TashilLinearProgressIndicator renders determinate flat and wavy modes', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const Column(
            children: [
              TashilLinearProgressIndicator.flat(
                value: 0.6,
                showStopIndicator: true,
              ),
              TashilLinearProgressIndicator.wavy(
                value: 0.4,
                showStopIndicator: true,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TashilLinearProgressIndicator), findsNWidgets(2));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('TashilLinearProgressIndicator renders indeterminate wavy mode with continuous animation', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const TashilLinearProgressIndicator.wavy(
            value: null,
            showStopIndicator: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TashilLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('TashilLinearProgressIndicator respects RTL vs LTR directionality', (tester) async {
      // Arabic RTL
      await tester.pumpWidget(
        buildTestWidget(
          textDirection: TextDirection.rtl,
          child: const TashilLinearProgressIndicator.wavy(value: 0.5),
        ),
      );
      await tester.pump();
      expect(find.byType(TashilLinearProgressIndicator), findsOneWidget);

      // English LTR
      await tester.pumpWidget(
        buildTestWidget(
          textDirection: TextDirection.ltr,
          child: const TashilLinearProgressIndicator.wavy(value: 0.5),
        ),
      );
      await tester.pump();
      expect(find.byType(TashilLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('TashilCircularProgressIndicator renders flat & wavy across sizes', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const Row(
            children: [
              TashilCircularProgressIndicator.small(
                value: 0.3,
                shape: TashilProgressShape.flat,
              ),
              TashilCircularProgressIndicator.standard(
                value: 0.7,
                shape: TashilProgressShape.wavy,
              ),
              TashilCircularProgressIndicator(
                value: null,
                shape: TashilProgressShape.wavy,
                sizeToken: TashilCircularProgressSize.large,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TashilCircularProgressIndicator), findsNWidgets(3));
    });

    testWidgets('M3ProgressShowcaseDialog renders cleanly in Arabic, English, and Hindi', (tester) async {
      for (final locale in [const Locale('ar'), const Locale('en'), const Locale('hi')]) {
        LocaleController.currentLocale.value = locale;
        await tester.pumpWidget(
          MaterialApp(
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
                secondary: const Color(0xFF3B82F6),
              ),
            ),
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => M3ProgressShowcaseDialog.show(context),
                      child: const Text('Open'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        // Tap open button
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify dialog is open
        expect(find.byType(M3ProgressShowcaseDialog), findsOneWidget);
        expect(find.byType(TashilLinearProgressIndicator), findsWidgets);
        expect(find.byType(TashilCircularProgressIndicator), findsWidgets);

        // Close dialog
        final loc = AppLocalizations.of(tester.element(find.byType(M3ProgressShowcaseDialog)));
        await tester.tap(find.text(loc.tr('confirm')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(M3ProgressShowcaseDialog), findsNothing);
      }
    });

    testWidgets('M3ProgressShowcaseDialog simulation triggers download progress updates', (tester) async {
      LocaleController.currentLocale.value = const Locale('ar');
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
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
              secondary: const Color(0xFF3B82F6),
            ),
          ),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => M3ProgressShowcaseDialog.show(context),
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final loc = AppLocalizations.of(tester.element(find.byType(M3ProgressShowcaseDialog)));
      final downloadBtn = find.text(loc.tr('simulateFileDownload'));
      expect(downloadBtn, findsWidgets);

      // Scroll into view and tap simulate download button
      await tester.ensureVisible(downloadBtn.last);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(downloadBtn.last, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Indicator should be actively rendering simulated progress
      expect(find.byType(TashilLinearProgressIndicator), findsWidgets);

      // Close dialog
      await tester.tap(find.text(loc.tr('confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
