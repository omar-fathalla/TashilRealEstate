import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/marketplace_visitor_preview_dialog.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';

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

  final testProperty = PropertyItem(
    id: 'test-prop-1',
    countryCode: 'EG',
    currencyCode: 'EGP',
    titles: {'ar': 'شقة فاخرة بالتجمع الخامس', 'en': 'Luxury Apartment', 'hi': 'लक्जरी अपार्टमेंट'},
    descriptions: {'ar': 'وصف تجريبي', 'en': 'Test desc', 'hi': 'विवरण'},
    propertyTypeCode: 'apartment',
    locations: {'ar': 'التجمع الخامس، القاهرة', 'en': 'New Cairo', 'hi': 'न्यू काहिरा'},
    cityCode: 'new_cairo',
    pricePerMonth: 22000,
    bedrooms: 3,
    bathrooms: 2,
    areaSqM: 185,
    imageUrls: const ['https://example.com/image.jpg'],
    amenitiesMap: const {
      'ar': ['مفروش بالكامل'],
      'en': ['Fully Furnished'],
      'hi': ['पूरी तरह सुसज्जित'],
    },
    isFurnished: true,
    isFeatured: true,
    agencyNames: const {'ar': 'شركة تسهيل', 'en': 'Tashil', 'hi': 'तशिल'},
    agencyPhone: '+20 100 123 4567',
    rating: 5.0,
  );

  setUp(() {
    LocaleController.setLanguage('ar');
  });

  group('MarketplaceVisitorPreviewDialog M3 Connected Button Group Tests', () {
    testWidgets('Renders TashilConnectedButtonGroup in dialog footer with shortened labels', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MarketplaceVisitorPreviewDialog.show(context, testProperty),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap to open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify Connected Button Group is present
      expect(find.byType(TashilConnectedButtonGroup<String>), findsWidgets);

      // Verify shortened labels
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('عرض التفاصيل'), findsOneWidget);
      expect(find.text('الانتقال إلى السوق'), findsOneWidget);

      // Verify icons in the connected button group
      expect(find.byIcon(Icons.close_rounded), findsWidgets);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsWidgets);

      // Verify M3 shaded close button in header
      expect(find.byType(TashilIconButton), findsWidgets);
    });

    testWidgets('Tapping cancel segment dismisses dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MarketplaceVisitorPreviewDialog.show(context, testProperty),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(MarketplaceVisitorPreviewDialog), findsOneWidget);

      // Tap cancel button segment
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(MarketplaceVisitorPreviewDialog), findsNothing);
    });
  });
}
