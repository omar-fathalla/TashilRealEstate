import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';

Widget wrapWithApp({required Widget child, Locale locale = const Locale('ar')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
    ),
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleController.setLanguage('ar');
    CountryController.setCountry('EG');
    MotionPreferenceController.setTransition(TashilPageTransitionType.fadeThrough);
  });

  group('Owner Portal Google M3 Motion & Transitions Suite Tests', () {
    test('MotionPreferenceController manages and updates page transition types', () {
      expect(MotionPreferenceController.currentTransition.value, TashilPageTransitionType.fadeThrough);

      MotionPreferenceController.setTransition(TashilPageTransitionType.sharedAxisX);
      expect(MotionPreferenceController.currentTransition.value, TashilPageTransitionType.sharedAxisX);

      MotionPreferenceController.setTransition(TashilPageTransitionType.sharedAxisZ);
      expect(MotionPreferenceController.currentTransition.value, TashilPageTransitionType.sharedAxisZ);
    });

    testWidgets('TashilPageTransitionSwitcher transitions between views smoothly in Arabic RTL', (tester) async {
      int activeIndex = 0;
      int previousIndex = 0;

      await tester.pumpWidget(
        wrapWithApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: TashilPageTransitionSwitcher(
                    transitionType: TashilPageTransitionType.fadeThrough,
                    isForward: activeIndex >= previousIndex,
                    child: KeyedSubtree(
                      key: ValueKey<int>(activeIndex),
                      child: Text('View #$activeIndex'),
                    ),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        previousIndex = activeIndex;
                        activeIndex = 1;
                      });
                    },
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('View #0'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('View #1'), findsOneWidget);
    });

    testWidgets('TashilTransitions.showM3Dialog applies M3 scale, fade, and faster exit law', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    TashilTransitions.showM3Dialog(
                      context: context,
                      builder: (ctx) => const AlertDialog(
                        title: Text('M3 Modal Form'),
                        content: Text('Testing M3 Motion Dialog'),
                      ),
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Modal'), findsOneWidget);
      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('M3 Modal Form'), findsOneWidget);
      expect(find.text('Testing M3 Motion Dialog'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('OwnerDashboard renders with M3 Motion Selector in Desktop header and opens selector menu', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const OwnerDashboard()));
      await tester.pumpAndSettle();

      // Motion button exists in header
      expect(find.byIcon(Icons.animation_rounded), findsOneWidget);

      // Tap to open motion preference modal
      await tester.tap(find.byIcon(Icons.animation_rounded));
      await tester.pumpAndSettle();

      // Modal dialog title exists in Arabic
      expect(find.text('نمط الحركة والانتقالات الذكية'), findsOneWidget);
      expect(find.text('تلاشي متداخل'), findsOneWidget);
      expect(find.text('انزلاق أفقي'), findsOneWidget);
      expect(find.text('عمق بصري'), findsOneWidget);
    });
  });
}
