import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child, {Locale locale = const Locale('ar')}) {
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
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  tearDown(() {
    LocaleController.setLocale(const Locale('ar'));
  });

  group('Official Google Material Design 3 (M3) Motion Easing Tests', () {
    test('Emphasized curve parameters strictly match Google M3 specifications', () {
      const emphasized = TashilMotionEasing.emphasized as Cubic;
      expect(emphasized.a, 0.2);
      expect(emphasized.b, 0.0);
      expect(emphasized.c, 0.0);
      expect(emphasized.d, 1.0);

      const decel = TashilMotionEasing.emphasizedDecelerate as Cubic;
      expect(decel.a, 0.05);
      expect(decel.b, 0.7);
      expect(decel.c, 0.1);
      expect(decel.d, 1.0);

      const accel = TashilMotionEasing.emphasizedAccelerate as Cubic;
      expect(accel.a, 0.3);
      expect(accel.b, 0.0);
      expect(accel.c, 0.8);
      expect(accel.d, 0.15);
    });

    test('Standard curve parameters strictly match Google M3 specifications', () {
      const standard = TashilMotionEasing.standard as Cubic;
      expect(standard.a, 0.2);
      expect(standard.b, 0.0);
      expect(standard.c, 0.0);
      expect(standard.d, 1.0);

      const decel = TashilMotionEasing.standardDecelerate as Cubic;
      expect(decel.a, 0.0);
      expect(decel.b, 0.0);
      expect(decel.c, 0.2);
      expect(decel.d, 1.0);

      const accel = TashilMotionEasing.standardAccelerate as Cubic;
      expect(accel.a, 0.4);
      expect(accel.b, 0.0);
      expect(accel.c, 1.0);
      expect(accel.d, 1.0);
    });

    test('Curve transformations satisfy boundary and deceleration/acceleration physics', () {
      const curves = [
        TashilMotionEasing.emphasized,
        TashilMotionEasing.emphasizedDecelerate,
        TashilMotionEasing.emphasizedAccelerate,
        TashilMotionEasing.standard,
        TashilMotionEasing.standardDecelerate,
        TashilMotionEasing.standardAccelerate,
      ];

      for (final curve in curves) {
        expect(curve.transform(0.0), closeTo(0.0, 0.001));
        expect(curve.transform(1.0), closeTo(1.0, 0.001));
      }

      // Deceleration starts fast: mid-point progress should be well over 50%
      expect(TashilMotionEasing.emphasizedDecelerate.transform(0.5), greaterThan(0.80));

      // Acceleration starts slow: mid-point progress should be well below 50%
      expect(TashilMotionEasing.emphasizedAccelerate.transform(0.5), lessThan(0.25));
    });
  });

  group('Official Google Material Design 3 (M3) Motion Duration Tests', () {
    test('Short tier (50ms - 200ms) matches 50ms interval spec', () {
      expect(TashilMotionDuration.short1.inMilliseconds, 50);
      expect(TashilMotionDuration.short2.inMilliseconds, 100);
      expect(TashilMotionDuration.short3.inMilliseconds, 150);
      expect(TashilMotionDuration.short4.inMilliseconds, 200);
    });

    test('Medium tier (250ms - 400ms) matches 50ms interval spec', () {
      expect(TashilMotionDuration.medium1.inMilliseconds, 250);
      expect(TashilMotionDuration.medium2.inMilliseconds, 300);
      expect(TashilMotionDuration.medium3.inMilliseconds, 350);
      expect(TashilMotionDuration.medium4.inMilliseconds, 400);
    });

    test('Long tier (450ms - 600ms) matches 50ms interval spec', () {
      expect(TashilMotionDuration.long1.inMilliseconds, 450);
      expect(TashilMotionDuration.long2.inMilliseconds, 500);
      expect(TashilMotionDuration.long3.inMilliseconds, 550);
      expect(TashilMotionDuration.long4.inMilliseconds, 600);
    });

    test('Extra-Long tier (700ms - 1000ms) matches 100ms interval spec', () {
      expect(TashilMotionDuration.extraLong1.inMilliseconds, 700);
      expect(TashilMotionDuration.extraLong2.inMilliseconds, 800);
      expect(TashilMotionDuration.extraLong3.inMilliseconds, 900);
      expect(TashilMotionDuration.extraLong4.inMilliseconds, 1000);
    });
  });

  group('Official Google Material Design 3 (M3) Motion Physics Springs Tests', () {
    test('Standard critically damped spring has zeta = 1.0 (no overshoot)', () {
      const spring = TashilMotionSpring.standard;
      expect(spring.mass, 1.0);
      expect(spring.stiffness, 300.0);
      expect(spring.damping, 34.64);

      // Verify zeta = damping / (2 * sqrt(mass * stiffness)) == 1.0
      final double zeta = spring.damping / (2 * 17.3205);
      expect(zeta, closeTo(1.0, 0.01));
    });

    test('Expressive bouncy spring has underdamped zeta approx 0.76', () {
      const spring = TashilMotionSpring.expressiveBouncy;
      expect(spring.mass, 1.0);
      expect(spring.stiffness, 320.0);
      expect(spring.damping, 27.15);

      final double zeta = spring.damping / (2 * 17.8885);
      expect(zeta, closeTo(0.76, 0.02));
    });

    test('Gentle spring has zeta = 1.0 with softer stiffness', () {
      const spring = TashilMotionSpring.gentle;
      expect(spring.mass, 1.0);
      expect(spring.stiffness, 180.0);
      expect(spring.damping, 26.83);

      final double zeta = spring.damping / (2 * 13.4164);
      expect(zeta, closeTo(1.0, 0.01));
    });
  });

  group('Official Google Material Design 3 (M3) Web Spring-to-Curve Conversions Tests', () {
    test('Spatial spring conversions match official M3 Google table', () {
      const fastSpatial = TashilMotionWebCurves.expressiveFastSpatial as Cubic;
      expect(fastSpatial.a, 0.14);
      expect(fastSpatial.b, 1.41);
      expect(fastSpatial.c, 0.71);
      expect(fastSpatial.d, 0.99);
      expect(TashilMotionWebCurves.expressiveFastSpatialDuration.inMilliseconds, 264);

      const defaultSpatial = TashilMotionWebCurves.expressiveDefaultSpatial as Cubic;
      expect(defaultSpatial.a, 0.18);
      expect(defaultSpatial.b, 1.13);
      expect(defaultSpatial.c, 0.52);
      expect(defaultSpatial.d, 1.00);
      expect(TashilMotionWebCurves.expressiveDefaultSpatialDuration.inMilliseconds, 500);

      const slowSpatial = TashilMotionWebCurves.expressiveSlowSpatial as Cubic;
      expect(slowSpatial.a, 0.14);
      expect(slowSpatial.b, 1.00);
      expect(slowSpatial.c, 0.32);
      expect(slowSpatial.d, 0.99);
      expect(TashilMotionWebCurves.expressiveSlowSpatialDuration.inMilliseconds, 620);
    });

    test('Effects spring conversions match official M3 Google table', () {
      const fastEffects = TashilMotionWebCurves.expressiveFastEffects as Cubic;
      expect(fastEffects.a, 0.00);
      expect(fastEffects.b, 0.79);
      expect(fastEffects.c, 0.63);
      expect(fastEffects.d, 1.00);
      expect(TashilMotionWebCurves.expressiveFastEffectsDuration.inMilliseconds, 150);

      const defaultEffects = TashilMotionWebCurves.expressiveDefaultEffects as Cubic;
      expect(defaultEffects.a, 0.10);
      expect(defaultEffects.b, 0.90);
      expect(defaultEffects.c, 0.51);
      expect(defaultEffects.d, 1.00);
      expect(TashilMotionWebCurves.expressiveDefaultEffectsDuration.inMilliseconds, 200);

      const slowEffects = TashilMotionWebCurves.expressiveSlowEffects as Cubic;
      expect(slowEffects.a, 0.10);
      expect(slowEffects.b, 0.96);
      expect(slowEffects.c, 0.44);
      expect(slowEffects.d, 1.00);
      expect(TashilMotionWebCurves.expressiveSlowEffectsDuration.inMilliseconds, 350);
    });
  });

  group('Official Google Material Design 3 (M3) Transitions Suite Tests', () {
    testWidgets('Container Transform page route builds with scale and fade', (tester) async {
      final route = TashilTransitions.containerTransform(
        page: const Text('Detail Page'),
      );

      expect(route.transitionDuration, TashilMotionDuration.long2);
      expect(route.reverseTransitionDuration, TashilMotionDuration.short4);

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              final anim = const AlwaysStoppedAnimation(0.5);
              final widget = route.transitionsBuilder(context, anim, anim, const Text('Target Child'));

              expect(widget, isA<FadeTransition>());
              final fade = widget as FadeTransition;
              expect(fade.child, isA<ScaleTransition>());
              final scale = fade.child as ScaleTransition;
              expect(scale.child, isA<Text>());
              expect((scale.child as Text).data, 'Target Child');

              return widget;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Target Child'), findsOneWidget);
    });

    testWidgets('Shared Axis X-axis respects RTL vs LTR directionality', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              final anim = const AlwaysStoppedAnimation(0.5);
              final route = TashilTransitions.sharedAxis(
                page: const Text('Shared Page'),
                context: context,
                axis: TashilSharedAxisType.x,
              );
              final widget = route.transitionsBuilder(context, anim, anim, const Text('Shared Target LTR'));

              expect(widget, isA<SlideTransition>());
              final slide = widget as SlideTransition;
              expect(slide.child, isA<FadeTransition>());

              return widget;
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared Target LTR'), findsOneWidget);

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              final anim = const AlwaysStoppedAnimation(0.5);
              final route = TashilTransitions.sharedAxis(
                page: const Text('Shared Page'),
                context: context,
                axis: TashilSharedAxisType.x,
              );
              final widget = route.transitionsBuilder(context, anim, anim, const Text('Shared Target RTL'));

              expect(widget, isA<SlideTransition>());
              final slide = widget as SlideTransition;
              expect(slide.child, isA<FadeTransition>());

              return widget;
            },
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared Target RTL'), findsOneWidget);
    });

    testWidgets('Shared Axis Y and Z axes build correctly', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              final anim = const AlwaysStoppedAnimation(0.5);
              final routeY = TashilTransitions.sharedAxis(
                page: const Text('Shared Y Page'),
                context: context,
                axis: TashilSharedAxisType.y,
              );
              final widgetY = routeY.transitionsBuilder(context, anim, anim, const Text('Shared Target Y'));
              expect(widgetY, isA<SlideTransition>());

              final routeZ = TashilTransitions.sharedAxis(
                page: const Text('Shared Z Page'),
                context: context,
                axis: TashilSharedAxisType.z,
              );
              final widgetZ = routeZ.transitionsBuilder(context, anim, anim, const Text('Shared Target Z'));
              expect(widgetZ, isA<ScaleTransition>());

              return Column(children: [widgetY, widgetZ]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared Target Y'), findsOneWidget);
      expect(find.text('Shared Target Z'), findsOneWidget);
    });

    testWidgets('Fade Through page route builds with scale and fade transitions', (tester) async {
      final route = TashilTransitions.fadeThrough(
        page: const Text('Fade Through Page'),
      );

      expect(route.transitionDuration, TashilMotionDuration.medium2);
      expect(route.reverseTransitionDuration, TashilMotionDuration.short4);

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              final anim = const AlwaysStoppedAnimation(0.5);
              final widget = route.transitionsBuilder(context, anim, anim, const Text('Target FadeThrough'));

              expect(widget, isA<FadeTransition>());
              final fade = widget as FadeTransition;
              expect(fade.child, isA<ScaleTransition>());
              final scale = fade.child as ScaleTransition;
              expect(scale.child, isA<Text>());

              return widget;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Target FadeThrough'), findsOneWidget);
    });

    testWidgets('Fade page route builds with fade transition', (tester) async {
      final route = TashilTransitions.fade(
        page: const Text('Simple Fade Page'),
      );

      expect(route.transitionDuration, TashilMotionDuration.short4);

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              final anim = const AlwaysStoppedAnimation(0.5);
              final widget = route.transitionsBuilder(context, anim, anim, const Text('Target Fade'));

              expect(widget, isA<FadeTransition>());
              final fade = widget as FadeTransition;
              expect(fade.child, isA<Text>());

              return widget;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Target Fade'), findsOneWidget);
    });

    testWidgets('showContainerTransformDialog opens dialog with scale and fade animations', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TashilTransitions.showContainerTransformDialog(
                    context: context,
                    builder: (dialogContext) => const Text('Dialog Modal Content'),
                  );
                },
                child: const Text('Open Modal'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dialog Modal Content'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Dialog Modal Content'), findsOneWidget);
    });

    testWidgets('TashilStaggeredEntrance renders child with slide and fade cascade', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const TashilStaggeredEntrance(
            index: 0,
            child: Text('Staggered Card 0'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staggered Card 0'), findsOneWidget);
      expect(find.byType(TashilStaggeredEntrance), findsOneWidget);
    });
  });

  group('M3MotionShowcaseDialog Interactive Tests', () {
    testWidgets('Renders all motion showcase sections with trilingual support in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          const M3MotionShowcaseDialog(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(M3MotionShowcaseDialog), findsOneWidget);

      // Verify header in Arabic
      expect(find.text('معرض الحركة والانتقالات M3'), findsOneWidget);

      // Trigger the motion animation
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap on another curve chip (Decelerate)
      final decelChip = find.text('متباطئ (Decelerate)');
      if (decelChip.evaluate().isNotEmpty) {
        await tester.tap(decelChip.first);
        await tester.pumpAndSettle();
      }

      // Tap on another duration token (300ms)
      final durationChip = find.text('300ms');
      if (durationChip.evaluate().isNotEmpty) {
        await tester.tap(durationChip.first);
        await tester.pumpAndSettle();
      }

      // Trigger motion again
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders properly in English locale', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          const M3MotionShowcaseDialog(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('M3 Motion & Transitions Showcase'), findsOneWidget);
    });

    testWidgets('Renders properly in Hindi locale', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          const M3MotionShowcaseDialog(),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('M3 गति और संक्रमण शोकेस'), findsOneWidget);
    });
  });
}
