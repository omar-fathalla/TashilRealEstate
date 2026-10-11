import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_details_dialog.dart';
import 'package:tashil_real_estate/features/virtual_staging/widgets/ai_virtual_staging_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child, {Locale locale = const Locale('ar')}) {
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

  group('M3 Connected Button Group & Property Details Suite Tests', () {
    testWidgets('TashilConnectedButtonGroup renders checkmark on selected segment and animates on selection change', (tester) async {
      String selected = 'opt1';

      await tester.pumpWidget(
        wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return TashilConnectedButtonGroup<String>(
                selectedValue: selected,
                showCheckmark: true,
                onSelectionChanged: (val) {
                  setState(() => selected = val);
                },
                segments: const [
                  TashilConnectedButtonSegment(
                    value: 'opt1',
                    label: 'الخيار الأول',
                    icon: Icons.first_page,
                  ),
                  TashilConnectedButtonSegment(
                    value: 'opt2',
                    label: 'الخيار الثاني',
                    icon: Icons.chair_rounded,
                  ),
                  TashilConnectedButtonSegment(
                    value: 'opt3',
                    label: 'الخيار الثالث',
                    icon: Icons.forum_rounded,
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Selected opt1 displays checkmark
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // Unselected opt2 and opt3 display their icons
      expect(find.byIcon(Icons.chair_rounded), findsOneWidget);
      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
      // opt1 icon was replaced by the checkmark
      expect(find.byIcon(Icons.first_page), findsNothing);

      // Tap opt2
      await tester.tap(find.text('الخيار الثاني'));
      await tester.pumpAndSettle();

      expect(selected, equals('opt2'));
      // Now opt2 has the checkmark
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // opt1 has returned to its original icon
      expect(find.byIcon(Icons.first_page), findsOneWidget);
      // opt2 original icon is now replaced by checkmark
      expect(find.byIcon(Icons.chair_rounded), findsNothing);
      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
    });

    testWidgets('TashilConnectedButtonGroup applies subtle elevation shadow to both selected and unselected segments', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilConnectedButtonGroup<String>(
            selectedValue: 'opt1',
            onSelectionChanged: (_) {},
            segments: const [
              TashilConnectedButtonSegment(
                value: 'opt1',
                label: 'الخيار الأول',
                icon: Icons.first_page,
              ),
              TashilConnectedButtonSegment(
                value: 'opt2',
                label: 'الخيار الثاني',
                icon: Icons.chair_rounded,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(TashilConnectedButtonGroup<String>),
          matching: find.byType(AnimatedContainer),
        ),
      ).toList();

      expect(animatedContainers.length, equals(2));
      for (final container in animatedContainers) {
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.isNotEmpty, isTrue);
      }
    });

    testWidgets('PropertyDetailsDialog bottom bar conditionally includes Virtual Staging for unfurnished properties', (tester) async {
      // prop-eg-2 is unfurnished (isFurnished: false)
      final unfurnishedProperty = PropertyItem.sampleProperties[1];
      expect(unfurnishedProperty.isFurnished, isFalse);

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          PropertyDetailsDialog(property: unfurnishedProperty),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify TashilConnectedButtonGroup is rendered in bottom bar
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);

      // Verify the 2 segments exist for unfurnished property
      expect(find.text('طلب معاينة / حجز'), findsOneWidget);
      expect(find.text('التأثيث الافتراضي'), findsOneWidget);
      expect(find.text('التفاوض الذكي'), findsNothing);

      // Verify checkmark is active on initial selected segment (booking)
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Verify Voice Broker icon button is in the header
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      // Verify redundant floating button on the hero photo is removed
      expect(find.widgetWithIcon(TashilButton, Icons.chair_rounded), findsNothing);
    });

    testWidgets('PropertyDetailsDialog bottom bar excludes Virtual Staging for already furnished properties', (tester) async {
      // prop-eg-1 is furnished (isFurnished: true)
      final furnishedProperty = PropertyItem.sampleProperties.first;
      expect(furnishedProperty.isFurnished, isTrue);

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          PropertyDetailsDialog(property: furnishedProperty),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify bottom bar has booking button only (single action renders TashilButton directly)
      expect(find.text('طلب معاينة / حجز'), findsOneWidget);
      expect(find.byType(TashilButton), findsWidgets);
      expect(find.text('التفاوض الذكي'), findsNothing);
      expect(find.text('التأثيث الافتراضي'), findsNothing);
    });

    testWidgets('AiVirtualStagingDialog uses Connected Button Group with 3-attempt quota limit', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          const AiVirtualStagingDialog(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Connected Button Group in staging dialog
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.text('إعادة التأثيث (3/3)'), findsOneWidget);
      expect(find.text('حفظ الصورة ومشاركتها'), findsOneWidget);

      // Tap regenerate once -> decrements to 2/3
      await tester.ensureVisible(find.text('إعادة التأثيث (3/3)'));
      await tester.tap(find.text('إعادة التأثيث (3/3)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();

      expect(find.text('إعادة التأثيث (2/3)'), findsOneWidget);
    });
  });
}

