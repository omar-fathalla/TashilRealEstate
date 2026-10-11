import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/search/tashil_search.dart';
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

  group('Official Google Material Design 3 (M3) Search Suite Tests', () {
    testWidgets('TashilSearchBar renders with 56dp height and required controls', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 400,
            child: TashilSearchBar(
              controller: controller,
              hintText: 'ابحث عن عقارك المفضل...',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search icon and hint text
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('ابحث عن عقارك المفضل...'), findsOneWidget);

      // Verify container height is 56dp
      final searchBarFinder = find.byType(TashilSearchBar);
      final size = tester.getSize(searchBarFinder);
      expect(size.height, equals(56.0));
      expect(size.width, equals(400.0));
    });

    testWidgets('TashilSearchBar typing, clear button, and onSubmitted callbacks work correctly', (tester) async {
      final controller = TextEditingController();
      String submittedQuery = '';
      bool clearTriggered = false;

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 450,
            child: TashilSearchBar(
              controller: controller,
              onSubmitted: (q) => submittedQuery = q,
              onClear: () => clearTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear button should not be visible when empty
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Type text into search field
      await tester.enterText(find.byType(TextField), 'فيلا في الشيخ زايد');
      await tester.pumpAndSettle();

      expect(controller.text, equals('فيلا في الشيخ زايد'));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Test submit
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(submittedQuery, equals('فيلا في الشيخ زايد'));

      // Test clear
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(clearTriggered, isTrue);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('AI Semantic Search badge and Visual Search button trigger appropriate callbacks', (tester) async {
      final controller = TextEditingController();
      bool semanticToggled = false;
      bool visualSearchTriggered = false;

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 500,
            child: TashilSearchBar(
              controller: controller,
              isSemanticActive: false,
              onToggleSemantic: () => semanticToggled = true,
              onVisualSearch: () => visualSearchTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find camera visual search button and click
      final cameraFinder = find.byIcon(Icons.photo_camera_outlined);
      expect(cameraFinder, findsOneWidget);
      await tester.tap(cameraFinder);
      await tester.pumpAndSettle();
      expect(visualSearchTriggered, isTrue);

      // Find AI semantic badge and click
      final aiIconFinder = find.byIcon(Icons.auto_awesome_rounded);
      expect(aiIconFinder, findsOneWidget);
      await tester.tap(aiIconFinder);
      await tester.pumpAndSettle();
      expect(semanticToggled, isTrue);
    });

    testWidgets('Suggestions menu unfolds and selecting a suggestion populates text', (tester) async {
      final controller = TextEditingController();
      String selectedSuggestion = '';

      final suggestions = [
        'Apartment for rent in Dubai Marina',
        'Luxury Villa in Palm Jumeirah',
      ];

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 500,
            child: TashilSearchBar(
              controller: controller,
              suggestions: suggestions,
              onSelectSuggestion: (sugg) => selectedSuggestion = sugg,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Focus text field to open suggestions overlay
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Suggestions overlay should be displayed
      expect(find.text('Apartment for rent in Dubai Marina'), findsOneWidget);
      expect(find.text('Luxury Villa in Palm Jumeirah'), findsOneWidget);

      // Tap first suggestion
      await tester.tap(find.text('Apartment for rent in Dubai Marina'));
      await tester.pumpAndSettle();

      expect(selectedSuggestion, equals('Apartment for rent in Dubai Marina'));
      expect(controller.text, equals('Apartment for rent in Dubai Marina'));
    });

    testWidgets('M3SearchShowcaseDialog renders and operates cleanly in Arabic, English, and Hindi', (tester) async {
      for (final locale in [const Locale('ar'), const Locale('en'), const Locale('hi')]) {
        await tester.pumpWidget(
          wrapWithApp(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => M3SearchShowcaseDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        // Open Dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Verify Dialog is shown
        expect(find.byType(M3SearchShowcaseDialog), findsOneWidget);

        // Close dialog
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(M3SearchShowcaseDialog), findsNothing);
      }
    });

    testWidgets('TashilSearchBar with splitMenuItems morphs into circle and rotates chevron on open', (tester) async {
      final controller = TextEditingController();
      String? selectedMode;

      await tester.pumpWidget(
        wrapWithApp(
          SizedBox(
            width: 600,
            child: TashilSearchBar(
              controller: controller,
              splitMenuItems: const [
                TashilSplitButtonItem<String>(
                  value: 'location',
                  label: 'بحث بالمدينة',
                  icon: Icons.location_on_outlined,
                ),
                TashilSplitButtonItem<String>(
                  value: 'ai',
                  label: 'بحث الذكاء الاصطناعي',
                  icon: Icons.auto_awesome_rounded,
                ),
              ],
              selectedSplitMenuValue: 'location',
              onSplitMenuItemSelected: (v) => selectedMode = v,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify TextField has transparent decoration and no filled border
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.filled, isFalse);
      expect(textField.decoration?.border, equals(InputBorder.none));

      // Verify chevron arrow down exists initially
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Open split menu
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump(const Duration(milliseconds: 50));

      // Animated rotation turns to 0.5 (180° upward)
      final rotations = tester.widgetList<AnimatedRotation>(find.byType(AnimatedRotation));
      expect(rotations.any((r) => r.turns == 0.5), isTrue);

      await tester.pumpAndSettle();
      expect(find.text('بحث الذكاء الاصطناعي'), findsOneWidget);

      // Select AI item
      await tester.tap(find.text('بحث الذكاء الاصطناعي'));
      await tester.pumpAndSettle();
      expect(selectedMode, equals('ai'));
    });
  });
}
