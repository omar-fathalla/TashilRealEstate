import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/publish_listing_dialog.dart';

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

  final testProperty = ManagedPropertyModel(
    id: 'test-managed-1',
    countryCode: 'EG',
    currencyCode: 'EGP',
    titles: {'ar': 'شقة فاخرة بالتجمع الخامس', 'en': 'Luxury Apartment', 'hi': 'लक्जरी अपार्टमेंट'},
    descriptions: {'ar': 'وصف تجريبي', 'en': 'Test desc', 'hi': 'विवरण'},
    locations: {'ar': 'التجمع الخامس، القاهرة', 'en': 'New Cairo', 'hi': 'न्यू काहिरा'},
    cityCode: 'new_cairo',
    propertyTypeCode: 'apartment',
    unitNumber: 'شقة 402',
    buildingName: 'برج الياسمين',
    pricePerMonth: 22000,
    bedrooms: 3,
    bathrooms: 2,
    areaSqM: 185,
    image: 'https://example.com/image.jpg',
    imageUrls: const ['https://example.com/image.jpg'],
    isPublished: true,
    rentalStatus: PropertyRentalStatus.available,
  );

  setUp(() {
    LocaleController.setLanguage('ar');
  });

  group('PublishListingDialog M3 Connected Button Group Tests', () {
    testWidgets('Renders TashilConnectedButtonGroup in rent mode with cancel and confirm segments', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PublishListingDialog.show(context, testProperty, initialRentMode: true),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify Connected Button Groups are present (first month payment status + bottom action group)
      expect(find.byType(TashilConnectedButtonGroup<String>), findsWidgets);
      expect(find.byType(TashilConnectedButtonGroup<int>), findsOneWidget);

      // Verify cancel and confirm segments
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('تأكيد'), findsOneWidget);

      // Verify Google icons in the button group
      expect(find.byIcon(Icons.close_rounded), findsWidgets);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);

      // Verify M3 shaded close button in header
      expect(find.byType(TashilIconButton), findsWidgets);

      // Verify updated concise labels for first month payment status
      expect(find.text('مستحق السداد'), findsOneWidget);
      expect(find.text('استلمت نقداً'), findsOneWidget);
      expect(find.text('استلمت بتحويل بنكي'), findsOneWidget);

      // Verify dynamic default lease start date shows today's date
      final now = DateTime.now();
      final expectedDateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
      expect(find.text(expectedDateStr), findsOneWidget);

      // Verify certified lease action
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    });

    testWidgets('Renders TashilConnectedButtonGroup in Mode 1 for unpublish and rent out', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PublishListingDialog.show(context, testProperty, initialRentMode: false),
              child: const Text('Open Mode 1'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Mode 1'));
      await tester.pumpAndSettle();

      // Verify Connected Button Group is present
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);

      // Verify segments: unpublish button and rent button
      expect(find.byIcon(Icons.visibility_off_rounded), findsWidgets);
      expect(find.byIcon(Icons.vpn_key_rounded), findsOneWidget);
    });
  });
}
