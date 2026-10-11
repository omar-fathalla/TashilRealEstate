import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_card.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_details_dialog.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/features/virtual_staging/widgets/ai_virtual_staging_dialog.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(
    Widget child, {
    Locale locale = const Locale('ar'),
    Brightness brightness = Brightness.light,
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
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF3B82F6),
          brightness: brightness,
        ),
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Google Material Design 3 Elevated Card Interactive States Suite Tests', () {
    testWidgets('TashilCard.elevated renders resting state with Level 1 elevation (1.0dp)', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.elevated(
            child: const Text('Resting Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.elevation, equals(1.0)); // M3 Level 1
    });

    testWidgets('TashilCard.elevated renders hovered state with Level 2 elevation (3.0dp) and 8% state layer', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.elevated(
            isHovered: true,
            child: const Text('Hovered Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(3.0)); // M3 Level 2
      expect(find.text('Hovered Card'), findsOneWidget);
    });

    testWidgets('TashilCard.elevated renders focused state with 3dp M3 secondary focus ring', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.elevated(
            isFocused: true,
            child: const Text('Focused Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(1.0)); // M3 Level 1
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(3.0)); // Official 3dp focus outline
    });

    testWidgets('TashilCard.elevated renders dragged state with Level 4 elevation (8.0dp)', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.elevated(
            isDragged: true,
            child: const Text('Dragged Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(8.0)); // M3 Level 4
    });

    testWidgets('TashilCard.elevated renders disabled state with Level 0 elevation and 38% opacity', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.elevated(
            enabled: false,
            onTap: () => tapped = true,
            child: const Text('Disabled Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(0.0)); // M3 Level 0

      // Verify 38% content opacity
      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, equals(0.38));

      // Tap card: should NOT trigger onTap
      await tester.tap(find.byType(TashilCard));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });

    testWidgets('TashilCard.elevated adapts to Dark Mode seamlessly', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.elevated(
            isHovered: true,
            child: const Text('Dark Mode Elevated Card'),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(3.0));
      expect(find.text('Dark Mode Elevated Card'), findsOneWidget);
    });

    // ----------------------------------------------------
    // TashilCard.outlined Interactive States Tests
    // ----------------------------------------------------
    testWidgets('TashilCard.outlined renders resting state with Level 0 elevation (0.0dp) and 1dp outlineVariant border', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.outlined(
            child: const Text('Resting Outlined Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.elevation, equals(0.0)); // M3 Level 0 for Outlined
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(1.0));
    });

    testWidgets('TashilCard.outlined renders hovered state with Level 1 elevation (1.0dp) and 8% state layer', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.outlined(
            isHovered: true,
            enableHoverAnimation: true,
            child: const Text('Hovered Outlined Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.elevation, equals(1.0)); // M3 Level 1 on hover
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(1.0));
    });

    testWidgets('TashilCard.outlined renders focused state with 3dp M3 secondary focus ring', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.outlined(
            isFocused: true,
            child: const Text('Focused Outlined Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(3.0)); // 3dp secondary focus ring
      expect(shape.side.color, equals(const Color(0xFF3B82F6)));
    });

    testWidgets('TashilCard.outlined renders dragged state with Level 4 elevation (8.0dp)', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.outlined(
            isDragged: true,
            child: const Text('Dragged Outlined Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.elevation, equals(8.0)); // M3 Level 4 on drag
    });

    testWidgets('TashilCard.outlined renders disabled state with Level 0 elevation and 38% opacity', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.outlined(
            enabled: false,
            onTap: () => tapped = true,
            child: const Text('Disabled Outlined Card'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.elevation, equals(0.0));

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsWidgets);
      final opacityWidget = tester.widget<Opacity>(opacityFinder.first);
      expect(opacityWidget.opacity, equals(0.38)); // M3 disabled opacity

      await tester.tap(find.text('Disabled Outlined Card'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });

    testWidgets('TashilCard.outlined adapts to Dark Mode seamlessly', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TashilCard.outlined(
            isHovered: true,
            child: const Text('Dark Mode Outlined Card'),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, equals(1.0));
      expect(find.text('Dark Mode Outlined Card'), findsOneWidget);
    });

    testWidgets('M3CardsShowcaseDialog renders Outlined states, Elevated states, and types tabs with 5 numbered states', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          const M3CardsShowcaseDialog(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(M3CardsShowcaseDialog), findsOneWidget);

      // Verify the 5 interactive Outlined states are rendered by default
      expect(find.text('1. تحويم'), findsOneWidget);
      expect(find.text('2. تركيز'), findsOneWidget);
      expect(find.text('3. ضغط'), findsOneWidget);
      expect(find.text('4. سحب'), findsOneWidget);
      expect(find.text('5. معطل'), findsOneWidget);

      // Switch to Elevated States tab
      await tester.tap(find.text('حالات الكرت المرتفع'));
      await tester.pumpAndSettle();
      expect(find.text('1. تحويم'), findsOneWidget);

      // Switch to Types tab
      await tester.tap(find.text('أنواع الكروت'));
      await tester.pumpAndSettle();

      expect(find.text('1. كرت مرتفع'), findsOneWidget);
      expect(find.text('2. كرت ممتلئ'), findsOneWidget);
      expect(find.text('3. كرت محدد بإطار'), findsOneWidget);
    });

    testWidgets('PropertyCard renders all semantic information icons and TashilConnectedButtonGroup', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testProperty = PropertyItem.sampleProperties.first;

      await tester.pumpWidget(
        wrapWithTheme(
          SizedBox(
            width: 380,
            child: PropertyCard(property: testProperty),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify M3 Elevated Card container
      expect(find.byType(PropertyCard), findsOneWidget);
      expect(find.byType(TashilCard), findsOneWidget);

      // 1. Price icon (Icons.payments_outlined)
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);

      // 2. Rating star icon (Icons.star_rounded)
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // 3. Property Type building icon (Icons.apartment_rounded)
      expect(find.byIcon(Icons.apartment_rounded), findsOneWidget);

      // 4. Location icon (Icons.location_on_outlined)
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

      // 5. Specs icons: Bed, Bathtub, Square Foot, Weekend/Furnishing
      expect(find.byIcon(Icons.bed_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bathtub_outlined), findsOneWidget);
      expect(find.byIcon(Icons.square_foot_outlined), findsOneWidget);
      expect(find.byIcon(Icons.weekend_outlined), findsOneWidget);

      // 6. Agency business icon (Icons.business_rounded)
      expect(find.byIcon(Icons.business_rounded), findsOneWidget);

      // 7. Official M3 Connected Button Group in card footer (concise PropTech labels)
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.text('حجز معاينة'), findsOneWidget);
      expect(find.text('التفاصيل'), findsOneWidget);

      // Tap on 'حجز معاينة' -> Opens PropertyDetailsDialog
      await tester.tap(find.text('حجز معاينة'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailsDialog), findsOneWidget);
    });

    testWidgets('PropertyCard renders M3 Card Top Header with Virtual Staging, Gemini Live, Favorite, and 3-dots More Options', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testProperty = PropertyItem.sampleProperties.first;

      await tester.pumpWidget(
        wrapWithTheme(
          SizedBox(
            width: 380,
            child: PropertyCard(property: testProperty),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Virtual Staging pill (without 'متاح')
      expect(find.text('التأثيث الافتراضي'), findsOneWidget);
      expect(find.text('تأثيث افتراضي متاح'), findsNothing);

      // 2. Verify Gemini Live pill
      expect(find.text('Gemini Live'), findsOneWidget);

      // 3. Verify Favorite Heart Icon button and toggle behavior
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      // 4. Verify 3-dots More Options button
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // 5. Tap on 'التأثيث الافتراضي' -> Opens AiVirtualStagingDialog
      await tester.tap(find.text('التأثيث الافتراضي'));
      await tester.pumpAndSettle();
      expect(find.byType(AiVirtualStagingDialog), findsOneWidget);
    });

    testWidgets('TashilCard adheres strictly to official Google M3 Measurements specifications', (tester) async {
      // 1. Verify Default Card Shape is 12dp corner radius
      await tester.pumpWidget(
        wrapWithTheme(
          const TashilCard(child: Text('M3 Card Measurement')),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.circular(12)));

      // 2. Verify PropertyCard uses 12dp corner radius
      final sampleProperty = PropertyItem.sampleProperties.first;
      await tester.pumpWidget(
        wrapWithTheme(
          SizedBox(
            width: 400,
            height: 540,
            child: PropertyCard(property: sampleProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final propertyCardFinder = find.byType(TashilCard);
      expect(propertyCardFinder, findsOneWidget);
      final propertyCardWidget = tester.widget<TashilCard>(propertyCardFinder);
      expect(propertyCardWidget.borderRadius, equals(BorderRadius.circular(12)));

      // 3. Verify Google M3 Dividers rules in PropertyCard:
      // - Rule 1: Full-width divider for expandable / action footer
      // - Rule 2: Inset divider separating related content inside card
      final dividers = tester.widgetList<TashilDivider>(find.byType(TashilDivider)).toList();
      expect(dividers.any((d) => d.variant == TashilDividerVariant.cardAction), isTrue);
      expect(dividers.any((d) => d.variant == TashilDividerVariant.middleInset), isTrue);
    });

    testWidgets('TashilCardText adheres to official Google M3 Card Text Hierarchy (Headline, Subhead, Supporting text)', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const TashilCardText(
            headlineText: 'Luxury Apartment in Cairo',
            subheadText: 'New Cairo, 5th Settlement',
            subheadLeading: Icon(Icons.location_on_outlined, size: 14),
            supportingText: 'Modern ultra super-lux finished apartment, fully furnished with premium amenities.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Headline, Subhead, Supporting text, and Subhead leading icon
      expect(find.text('Luxury Apartment in Cairo'), findsOneWidget);
      expect(find.text('New Cairo, 5th Settlement'), findsOneWidget);
      expect(find.text('Modern ultra super-lux finished apartment, fully furnished with premium amenities.'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

      // Verify Typography: Headline has bold titleMedium
      final headlineFinder = find.text('Luxury Apartment in Cairo');
      final headlineWidget = tester.widget<Text>(headlineFinder);
      expect(headlineWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(headlineWidget.maxLines, equals(1));

      // Verify Typography: Supporting text has 2 max lines
      final supportingFinder = find.text('Modern ultra super-lux finished apartment, fully furnished with premium amenities.');
      final supportingWidget = tester.widget<Text>(supportingFinder);
      expect(supportingWidget.maxLines, equals(2));
      expect(supportingWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('PropertyCard integrates TashilCardText with Headline, Subhead, and Supporting Text', (tester) async {
      final sampleProperty = PropertyItem.sampleProperties.first;
      await tester.pumpWidget(
        wrapWithTheme(
          SizedBox(
            width: 400,
            height: 580,
            child: PropertyCard(property: sampleProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify TashilCardText component is present inside PropertyCard
      expect(find.byType(TashilCardText), findsOneWidget);

      // Verify Headline communicates the subject of the card (Title)
      expect(find.text(sampleProperty.getTitle('ar')), findsOneWidget);

      // Verify Subhead communicates the tagged location
      expect(find.text(sampleProperty.getLocation('ar')), findsOneWidget);

      // Verify Supporting text communicates the body description
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && w.data != null && w.data!.contains(sampleProperty.getDescription('ar'))),
        findsOneWidget,
      );
    });

    testWidgets('TashilCardText renders Linked text and Selection controls per Google M3 specifications', (tester) async {
      bool linkTapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilCardText(
            headlineText: 'Card with Interactive Controls',
            supportingText: 'This is body content explaining property details.',
            linkedText: 'Read more link',
            onLinkedTextTap: () => linkTapped = true,
            selectionControl: const Row(
              children: [
                Icon(Icons.check_box, size: 16),
                SizedBox(width: 4),
                Text('Select to compare'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Read more link'), findsOneWidget);
      expect(find.text('Select to compare'), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);

      // Tap linked text
      await tester.tap(find.text('Read more link'));
      await tester.pumpAndSettle();
      expect(linkTapped, isTrue);
    });

    testWidgets('PropertyCard integrates all 4 M3 interactive controls: Buttons, Icon buttons, and Linked text', (tester) async {
      final sampleProperty = PropertyItem.sampleProperties.first;
      await tester.pumpWidget(
        wrapWithTheme(
          SizedBox(
            width: 400,
            height: 580,
            child: PropertyCard(property: sampleProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Linked text
      expect(find.text('اقرأ المزيد'), findsOneWidget);

      // 2. Buttons: Connected Button Group
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);

      // 3. Icon buttons: Phone Call & Chat
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });

    testWidgets('M3HoverColorScheme derives darker tone and hover state layer from theme seed color (Terracotta & Green)', (tester) async {
      // 1. Warm Terracotta (#8F4C38)
      final terracottaScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF8F4C38),
        brightness: Brightness.light,
      );
      final terracottaDarkHover = terracottaScheme.primaryDarkenedHover;
      // Darkened hover should be slightly darker than base primary
      expect(terracottaDarkHover, isNot(equals(terracottaScheme.primary)));
      // Hover state layer and border must be derived from terracotta primary
      expect(terracottaScheme.primaryHoverStateLayer.r, equals(terracottaScheme.primary.r));
      expect(terracottaScheme.primaryHoverBorder.r, equals(terracottaScheme.primary.r));

      // 2. Forest Green (#2E6B48)
      final greenScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E6B48),
        brightness: Brightness.light,
      );
      final greenDarkHover = greenScheme.primaryDarkenedHover;
      expect(greenDarkHover, isNot(equals(greenScheme.primary)));
      expect(greenScheme.primaryHoverStateLayer.r, equals(greenScheme.primary.r));
      expect(greenScheme.primaryHoverBorder.r, equals(greenScheme.primary.r));
    });

    testWidgets('TashilCard.outlined applies primary-derived border when hovered', (tester) async {
      const customPrimary = Color(0xFF8F4C38); // Terracotta
      final customTheme = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: customPrimary),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: customTheme,
          home: Scaffold(
            body: Center(
              child: TashilCard.outlined(
                isHovered: true,
                enableHoverAnimation: true,
                child: const Text('Terracotta Hovered Card'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      final shape = cardWidget.shape as RoundedRectangleBorder;
      // Border color must be derived from primary (Terracotta)
      expect(shape.side.color, equals(customTheme.colorScheme.primary.withValues(alpha: 0.42)));
    });
  });
}

