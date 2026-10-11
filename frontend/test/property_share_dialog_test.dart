import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/property_share_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocaleController.currentLocale.value = const Locale('ar');
  });

  Widget wrapWithTheme(Widget child, {Locale locale = const Locale('ar')}) {
    LocaleController.currentLocale.value = locale;
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
        body: child,
      ),
    );
  }

  group('PropertyShareDialog M3 Redesign Tests', () {
    testWidgets('Renders outlined close button, Google Material social icons, localized shareOptions, and connected button group in Arabic', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          PropertyShareDialog(
            id: 'prop-eg-3',
            imageUrl: '',
            pricePerMonth: 45000,
            titleGetter: (_) => 'شاليه صف أول على البحر مباشرة في مراسي',
            locationGetter: (_) => 'سيدي عبد الرحمن، الساحل الشمالي',
            countryCode: 'EG',
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Outlined Close Button
      expect(find.byIcon(Icons.close_rounded), findsWidgets);
      final outlinedIconButtons = find.byWidgetPredicate(
        (w) => w is TashilIconButton && w.variant == TashilIconButtonVariant.outlined,
      );
      expect(outlinedIconButtons, findsOneWidget);

      // 2. Verify Localized Share Options Title (Must NOT be raw 'shareOptions')
      expect(find.text('خيارات المشاركة'), findsOneWidget);
      expect(find.text('shareOptions'), findsNothing);

      // 3. Verify Google Material Design Icons for Social Channels
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget); // WhatsApp
      expect(find.byIcon(Icons.public_rounded), findsOneWidget); // Facebook
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget); // Messenger

      // 4. Verify TashilConnectedButtonGroup in footer with 'معاينة' and 'إلغاء'
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.text('معاينة'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      // Ensure deprecated 'معاينة كزائر' is replaced
      expect(find.text('معاينة كزائر'), findsNothing);
    });

    testWidgets('Renders localized elements accurately in English', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          PropertyShareDialog(
            id: 'prop-eg-3',
            imageUrl: '',
            pricePerMonth: 45000,
            titleGetter: (_) => 'Beachfront Chalet in Marassi',
            locationGetter: (_) => 'Sidi Abdel Rahman, North Coast',
            countryCode: 'EG',
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Options'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
    });

    testWidgets('Renders localized elements accurately in Hindi', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithTheme(
          PropertyShareDialog(
            id: 'prop-eg-3',
            imageUrl: '',
            pricePerMonth: 45000,
            titleGetter: (_) => 'मरासी में समुद्र तट शैले',
            locationGetter: (_) => 'सिदी अब्देल रहमान, उत्तरी तट',
            countryCode: 'EG',
          ),
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('साझाकरण विकल्प'), findsOneWidget);
      expect(find.text('पूर्वावलोकन'), findsOneWidget);
      expect(find.text('रद्द करें'), findsOneWidget);
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
    });

    testWidgets('Tapping cancel button in connected group closes the dialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool dialogClosed = false;

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => TashilButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => PropertyShareDialog(
                    id: 'prop-eg-3',
                    imageUrl: '',
                    pricePerMonth: 45000,
                    titleGetter: (_) => 'شاليه صف أول على البحر مباشرة في مراسي',
                    locationGetter: (_) => 'سيدي عبد الرحمن، الساحل الشمالي',
                    countryCode: 'EG',
                  ),
                );
                dialogClosed = true;
              },
              label: 'فتح المشاركة',
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('فتح المشاركة'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyShareDialog), findsOneWidget);

      // Tap 'إلغاء' segment in TashilConnectedButtonGroup
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyShareDialog), findsNothing);
      expect(dialogClosed, isTrue);
    });

    testWidgets('Tapping close X button closes the dialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool dialogClosed = false;

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => TashilButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => PropertyShareDialog(
                    id: 'prop-eg-3',
                    imageUrl: '',
                    pricePerMonth: 45000,
                    titleGetter: (_) => 'شاليه صف أول على البحر مباشرة في مراسي',
                    locationGetter: (_) => 'سيدي عبد الرحمن، الساحل الشمالي',
                    countryCode: 'EG',
                  ),
                );
                dialogClosed = true;
              },
              label: 'فتح المشاركة',
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('فتح المشاركة'));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyShareDialog), findsOneWidget);

      // Tap top close X button
      final closeButton = find.byWidgetPredicate(
        (w) => w is TashilIconButton && w.variant == TashilIconButtonVariant.outlined,
      );
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(PropertyShareDialog), findsNothing);
      expect(dialogClosed, isTrue);
    });
  });
}
