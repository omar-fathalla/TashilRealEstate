import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocaleController.currentLocale.value = const Locale('ar');
  });

  Widget wrapWithApp(Widget child, {Locale locale = const Locale('ar')}) {
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
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  group('Public Marketplace M3 Smart Valuation Button Tests', () {
    testWidgets('Renders M3 Elevated Button with prompt text and single sparkle icon', (tester) async {
      LocaleController.currentLocale.value = const Locale('ar');
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithApp(
          Builder(
            builder: (ctx) {
              final loc = AppLocalizations.of(ctx);
              return TashilButton.elevated(
                label: loc.tr('aiValuationBannerPrompt'),
                icon: Icons.auto_awesome_rounded,
                height: 48.0,
                borderRadius: BorderRadius.circular(24),
                onPressed: () => SmartValuationDialog.show(ctx),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the prompt text is directly in the button
      expect(find.text('هل تريد معرفة السعر العادل لإيجارك؟'), findsOneWidget);

      // Verify single icon rule: only auto_awesome_rounded exists
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.text('اضغط هنا'), findsNothing);

      // Verify TashilButton variant is elevated
      final buttonWidget = tester.widget<TashilButton>(find.byType(TashilButton));
      expect(buttonWidget.variant, equals(TashilButtonVariant.elevated));

      // Tap button to open dialog
      await tester.tap(find.byType(TashilButton));
      await tester.pumpAndSettle();

      // Verify SmartValuationDialog is opened
      expect(find.byType(SmartValuationDialog), findsOneWidget);
    });

    testWidgets('Trilingual parity: displays correct prompt in English and Hindi', (tester) async {
      // English
      LocaleController.currentLocale.value = const Locale('en');
      await tester.pumpWidget(
        wrapWithApp(
          Builder(
            builder: (ctx) {
              final loc = AppLocalizations.of(ctx);
              return TashilButton.elevated(
                label: loc.tr('aiValuationBannerPrompt'),
                icon: Icons.auto_awesome_rounded,
                onPressed: () {},
              );
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Want to know the fair rent for your property?'), findsOneWidget);

      // Hindi
      LocaleController.currentLocale.value = const Locale('hi');
      await tester.pumpWidget(
        wrapWithApp(
          Builder(
            builder: (ctx) {
              final loc = AppLocalizations.of(ctx);
              return TashilButton.elevated(
                label: loc.tr('aiValuationBannerPrompt'),
                icon: Icons.auto_awesome_rounded,
                onPressed: () {},
              );
            },
          ),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('क्या आप अपनी संपत्ति का उचित किराया जानना चाहते हैं?'), findsOneWidget);
    });

    testWidgets('TashilConnectedButtonGroup renders All, Featured, and Furnished segments and switches selection', (tester) async {
      String currentFilter = 'all';

      await tester.pumpWidget(
        wrapWithApp(
          StatefulBuilder(
            builder: (ctx, setState) {
              final loc = AppLocalizations.of(ctx);
              return TashilConnectedButtonGroup<String>(
                selectedValue: currentFilter,
                onSelectionChanged: (val) {
                  setState(() => currentFilter = val);
                },
                segments: [
                  TashilConnectedButtonSegment<String>(
                    value: 'all',
                    label: loc.tr('all'),
                    icon: Icons.grid_view_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'featured',
                    label: loc.tr('chipFeatured'),
                    icon: Icons.star_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'furnished',
                    label: loc.tr('chipFurnished'),
                    icon: Icons.chair_rounded,
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all three segments are rendered
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('عقارات مميزة'), findsOneWidget);
      expect(find.text('مفروشة فقط'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chair_rounded), findsOneWidget);

      // Select Featured
      await tester.tap(find.text('عقارات مميزة'));
      await tester.pumpAndSettle();
      expect(currentFilter, equals('featured'));

      // Select Furnished
      await tester.tap(find.text('مفروشة فقط'));
      await tester.pumpAndSettle();
      expect(currentFilter, equals('furnished'));
    });
  });
}
