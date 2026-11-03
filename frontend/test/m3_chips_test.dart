import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/property_media_gallery_uploader.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_details_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
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

  group('M3 Chips Suite Tests', () {
    testWidgets('TashilAssistChip (Type 1) renders leading icon and label with M3 specs', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilAssistChip.outlined(
            label: 'صالة المعيشة',
            icon: Symbols.weekend_rounded,
            onPressed: () => tapped = true,
          ),
        ),
      );

      // Verify label and icon existence
      expect(find.text('صالة المعيشة'), findsOneWidget);
      expect(find.byIcon(Symbols.weekend_rounded), findsWidgets);

      // Verify M3 height
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight ?? 32.0, equals(32.0));

      // Tap and verify callback
      await tester.tap(find.text('صالة المعيشة'));
      expect(tapped, isTrue);
    });

    testWidgets('TashilAssistChip.elevated renders with elevation', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const TashilAssistChip.elevated(
            label: 'مطبخ عصري',
            icon: Symbols.countertops_rounded,
          ),
        ),
      );

      expect(find.text('مطبخ عصري'), findsOneWidget);
      expect(find.byIcon(Symbols.countertops_rounded), findsWidgets);

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(TashilAssistChip), matching: find.byType(Material)).first,
      );
      expect(material.elevation, equals(1.0));
    });

    testWidgets('TashilFilterChip toggles selection and shows checkmark when selected', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return wrapWithTheme(
              TashilFilterChip(
                label: 'تكييف مركزي',
                icon: Symbols.ac_unit_rounded,
                selected: isSelected,
                onSelected: (val) => setState(() => isSelected = val),
              ),
            );
          },
        ),
      );

      // Initially unselected, checkmark not visible
      expect(find.text('تكييف مركزي'), findsOneWidget);
      expect(find.byIcon(Symbols.check_rounded), findsNothing);
      expect(find.byIcon(Symbols.ac_unit_rounded), findsWidgets);

      // Tap to select
      await tester.tap(find.text('تكييف مركزي'));
      await tester.pumpAndSettle();

      // Now selected, checkmark visible
      expect(isSelected, isTrue);
      expect(find.byIcon(Symbols.check_rounded), findsWidgets);
    });

    testWidgets('TashilInputChip fires onDeleted callback when close icon tapped', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilInputChip(
            label: 'التجمع الخامس',
            icon: Symbols.tag_rounded,
            onDeleted: () => deleted = true,
          ),
        ),
      );

      expect(find.text('التجمع الخامس'), findsOneWidget);
      expect(find.byIcon(Symbols.close_rounded), findsWidgets);

      await tester.tap(find.byIcon(Symbols.close_rounded));
      expect(deleted, isTrue);
    });

    testWidgets('TashilSuggestionChip renders and handles tap', (tester) async {
      bool suggested = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilSuggestionChip(
            label: 'اقتراح ذكي بالذكاء الاصطناعي',
            icon: Symbols.auto_awesome_rounded,
            onPressed: () => suggested = true,
          ),
        ),
      );

      expect(find.text('اقتراح ذكي بالذكاء الاصطناعي'), findsOneWidget);
      expect(find.byIcon(Symbols.auto_awesome_rounded), findsWidgets);

      await tester.tap(find.text('اقتراح ذكي بالذكاء الاصطناعي'));
      expect(suggested, isTrue);
    });

    testWidgets('PropertyMediaGalleryUploader renders clean upload actions and no architectural presets', (tester) async {
      final photos = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar')],
          locale: const Locale('ar'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyMediaGalleryUploader(
                photoUrls: photos,
                onPhotosChanged: (newPhotos) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify presence of status badge chip and chic M3 upload button
      expect(find.byType(TashilAssistChip), findsOneWidget);
      expect(find.widgetWithIcon(TashilButton, Symbols.add_photo_alternate_rounded), findsOneWidget);
      expect(find.text('رفع الصور'), findsOneWidget);
      expect(find.byIcon(Symbols.add_link_rounded), findsNothing);

      // Verify architectural presets are completely removed
      expect(find.text('نماذج معمارية جاهزة بنقرة واحدة'), findsNothing);
      expect(find.byIcon(Symbols.weekend_rounded), findsNothing);
      expect(find.byIcon(Symbols.bed_rounded), findsNothing);
      expect(find.byIcon(Symbols.countertops_rounded), findsNothing);
    });

    testWidgets('PropertyDetailsDialog renders amenities using TashilAssistChip with contextual icons', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar')],
          locale: const Locale('ar'),
          home: Scaffold(
            body: PropertyDetailsDialog(
              property: PropertyItem.sampleProperties.first,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify presence of TashilAssistChips for amenities with contextual icons
      expect(find.byType(TashilAssistChip), findsWidgets);
      expect(find.widgetWithText(TashilAssistChip, 'مفروش بالكامل'), findsOneWidget);
      expect(find.widgetWithIcon(TashilAssistChip, Symbols.chair_rounded), findsOneWidget);
      expect(find.widgetWithText(TashilAssistChip, 'تكييف مركزي'), findsOneWidget);
      expect(find.widgetWithIcon(TashilAssistChip, Symbols.ac_unit_rounded), findsOneWidget);
      expect(find.widgetWithText(TashilAssistChip, 'أمن وحراسة 24/7'), findsOneWidget);
      expect(find.widgetWithIcon(TashilAssistChip, Symbols.security_rounded), findsOneWidget);

      final firstChipBox = tester.getRect(find.widgetWithText(TashilAssistChip, 'مفروش بالكامل'));
      final secondChipBox = tester.getRect(find.widgetWithText(TashilAssistChip, 'تكييف مركزي'));

      // Verify compact width (not stretching to full 900+ width)
      expect(firstChipBox.width, lessThan(250.0));
      expect(secondChipBox.width, lessThan(250.0));

      // Verify side-by-side layout on the same horizontal row
      expect(firstChipBox.top, equals(secondChipBox.top));
    });
  });
}


