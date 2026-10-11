import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child, {TextDirection direction = TextDirection.rtl}) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF3B82F6),
          tertiary: const Color(0xFFF59E0B),
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('Google Material Design 3 Expressive Loading Indicator Suite Tests', () {
    testWidgets('TashilLoadingIndicator sizes adhere to M3 specifications (24dp, 48dp, 72dp)', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const Column(
            children: [
              TashilLoadingIndicator.small(),
              TashilLoadingIndicator.medium(),
              TashilLoadingIndicator.large(),
            ],
          ),
        ),
      );
      await tester.pump();

      final smallFinder = find.byWidgetPredicate(
        (w) => w is TashilLoadingIndicator && w.size == TashilLoadingSize.small.dimension,
      );
      final mediumFinder = find.byWidgetPredicate(
        (w) => w is TashilLoadingIndicator && w.size == TashilLoadingSize.medium.dimension,
      );
      final largeFinder = find.byWidgetPredicate(
        (w) => w is TashilLoadingIndicator && w.size == TashilLoadingSize.large.dimension,
      );

      expect(smallFinder, findsOneWidget);
      expect(mediumFinder, findsOneWidget);
      expect(largeFinder, findsOneWidget);

      expect(tester.getSize(smallFinder).width, equals(24.0));
      expect(tester.getSize(smallFinder).height, equals(24.0));

      expect(tester.getSize(mediumFinder).width, equals(48.0));
      expect(tester.getSize(mediumFinder).height, equals(48.0));

      expect(tester.getSize(largeFinder).width, equals(72.0));
      expect(tester.getSize(largeFinder).height, equals(72.0));
    });

    testWidgets('TashilLoadingIndicator container variant wraps in elevated surface container', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilLoadingIndicator.medium(
            hasContainer: true,
            containerElevation: 3.0,
          ),
        ),
      );
      await tester.pump();

      // Container adds 24dp total padding (12dp each side) -> 48 + 24 = 72dp
      final indicatorFinder = find.byType(TashilLoadingIndicator);
      expect(indicatorFinder, findsOneWidget);
      expect(tester.getSize(indicatorFinder).width, equals(72.0));
      expect(tester.getSize(indicatorFinder).height, equals(72.0));
    });

    testWidgets('TashilLoadingIndicator morphs smoothly across animation frames', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const TashilLoadingIndicator.medium(),
        ),
      );
      await tester.pump();

      // Advance animation by 500ms
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TashilLoadingIndicator), findsOneWidget);

      // Advance animation by another 1000ms
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(TashilLoadingIndicator), findsOneWidget);
    });

    testWidgets('TashilLoadingIndicator provides accessibility semantics label', (tester) async {
      const semanticLabel = 'جاري تحليل بيانات العقار بالذكاء الاصطناعي';
      await tester.pumpWidget(
        wrapWithTheme(
          const TashilLoadingIndicator.medium(
            semanticLabel: semanticLabel,
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel(semanticLabel), findsOneWidget);
    });

    testWidgets('TashilLoadingOverlay renders message, scrim and absorbs pointer events', (tester) async {
      bool buttonClicked = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilLoadingOverlay(
            isLoading: true,
            message: 'جاري الحفظ والتحقق من الصلاحيات...',
            child: ElevatedButton(
              onPressed: () => buttonClicked = true,
              child: const Text('زر خلفي'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('جاري الحفظ والتحقق من الصلاحيات...'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(TashilLoadingIndicator), findsOneWidget);

      // Verify that the button cannot be tapped through the loading overlay
      await tester.tap(find.text('زر خلفي'), warnIfMissed: false);
      await tester.pump();
      expect(buttonClicked, isFalse);
    });

    testWidgets('TashilLoadingOverlay.show and hide modal lifecycle works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    TashilLoadingOverlay.show(
                      context,
                      message: 'جاري تحميل تفاصيل الوحدات...',
                    );
                  },
                  child: const Text('بدء التحميل'),
                ),
              ),
            ),
          ),
        ),
      );

      // Initially overlay is not shown
      expect(find.byType(TashilLoadingOverlay), findsNothing);

      // Tap button to show overlay
      await tester.tap(find.text('بدء التحميل'));
      await tester.pump(); // Start transition
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TashilLoadingOverlay), findsOneWidget);
      expect(find.text('جاري تحميل تفاصيل الوحدات...'), findsOneWidget);

      // Hide overlay
      final overlayContext = tester.element(find.byType(TashilLoadingOverlay));
      TashilLoadingOverlay.hide(overlayContext);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TashilLoadingOverlay), findsNothing);
    });
  });
}
