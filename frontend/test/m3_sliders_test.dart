import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/sliders/tashil_sliders.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: child,
          ),
        ),
      ),
    );
  }

  group('Material Design 3 (M3) Sliders Suite Tests', () {
    testWidgets('TashilSlider renders with default M3 Expressive vertical bar handle', (tester) async {
      double currentValue = 50.0;

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 300,
            child: TashilSlider(
              value: currentValue,
              min: 0.0,
              max: 100.0,
              onChanged: (val) => currentValue = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TashilSlider), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Dragging TashilSlider in LTR updates value and calls onChanged', (tester) async {
      double currentValue = 20.0;

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 200,
            child: TashilSlider(
              value: currentValue,
              min: 0.0,
              max: 100.0,
              onChanged: (val) => currentValue = val,
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(TashilSlider);
      await tester.drag(sliderFinder, const Offset(60, 0));
      await tester.pump();

      // In LTR, dragging to the right increases value
      expect(currentValue, greaterThan(20.0));
    });

    testWidgets('Dragging TashilSlider in RTL updates value correctly (drag left increases)', (tester) async {
      double currentValue = 20.0;

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 200,
            child: TashilSlider(
              value: currentValue,
              min: 0.0,
              max: 100.0,
              onChanged: (val) => currentValue = val,
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(TashilSlider);
      // In RTL, dragging towards the left increases value
      await tester.drag(sliderFinder, const Offset(-60, 0));
      await tester.pump();

      expect(currentValue, greaterThan(20.0));
    });

    testWidgets('Tapping on TashilSlider updates value smoothly', (tester) async {
      double currentValue = 10.0;

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 200,
            child: TashilSlider(
              value: currentValue,
              min: 0.0,
              max: 100.0,
              onChanged: (val) => currentValue = val,
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      final sliderRect = tester.getRect(find.byType(TashilSlider));
      final tapTarget = Offset(sliderRect.left + sliderRect.width * 0.8, sliderRect.center.dy);

      await tester.tapAt(tapTarget);
      await tester.pumpAndSettle();

      expect(currentValue, greaterThan(60.0));
    });

    testWidgets('M3SlidersShowcaseDialog opens and displays all 3 variants', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => M3SlidersShowcaseDialog.show(context),
                child: const Text('Open Showcase'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Showcase'));
      await tester.pumpAndSettle();

      expect(find.byType(M3SlidersShowcaseDialog), findsOneWidget);
      expect(find.byType(TashilSlider), findsNWidgets(3));
      expect(find.text('Google Material Design 3 Expressive Sliders'), findsOneWidget);
    });

    testWidgets('TashilSlider default gap is 2.0dp and showDivisionTicks is false for unified continuous surface', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 250,
            child: TashilSlider(
              value: 40.0,
              min: 0.0,
              max: 100.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final slider = tester.widget<TashilSlider>(find.byType(TashilSlider));
      expect(slider.gap, equals(2.0));
      expect(slider.showDivisionTicks, isFalse);
      expect(slider.trackHeight, equals(16.0));
      expect(slider.handleType, equals(TashilSliderHandleType.verticalBar));
    });

    test('TashilAudioFeedback generates sound ticks without throwing exceptions', () {
      expect(() => TashilAudioFeedback.playSliderTick(fraction: 0.0), returnsNormally);
      expect(() => TashilAudioFeedback.playSliderTick(fraction: 0.5), returnsNormally);
      expect(() => TashilAudioFeedback.playSliderTick(fraction: 1.0), returnsNormally);
      expect(() => TashilAudioFeedback.playStepTick(stepRatio: 0.8), returnsNormally);
    });
  });
}
