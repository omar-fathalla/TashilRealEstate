import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/publish_listing_dialog.dart';

// TAQ-64: owners are told that contact details are removed from the public description.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expected = {
    'ar': 'أرقام التليفون وبيانات التواصل بتتشال من الوصف العام تلقائيًا. التواصل بيتم من خلال المنصة.',
    'en': 'Phone numbers and contact details are removed from the public description automatically. '
        'Buyers contact you through the platform.',
    'hi': 'फ़ोन नंबर और संपर्क विवरण सार्वजनिक विवरण से अपने-आप हटा दिए जाते हैं। '
        'खरीदार प्लेटफ़ॉर्म के ज़रिए आपसे संपर्क करते हैं।',
  };

  final draftProperty = ManagedPropertyModel(
    id: 'test-unpublished-1',
    countryCode: 'EG',
    currencyCode: 'EGP',
    titles: const {'ar': 'شقة', 'en': 'Apartment', 'hi': 'अपार्टमेंट'},
    descriptions: const {'ar': 'وصف', 'en': 'Description', 'hi': 'विवरण'},
    locations: const {'ar': 'القاهرة', 'en': 'Cairo', 'hi': 'काहिरा'},
    cityCode: 'cairo',
    propertyTypeCode: 'apartment',
    unitNumber: '402',
    buildingName: 'Tower',
    pricePerMonth: 22000,
    bedrooms: 3,
    bathrooms: 2,
    areaSqM: 185,
    image: 'assets/images/properties/prop_eg_1_1.jpg',
    imageUrls: const ['assets/images/properties/prop_eg_1_1.jpg'],
    isPublished: false,
    rentalStatus: PropertyRentalStatus.available,
  );

  Widget app(String lang) {
    return MaterialApp(
      locale: Locale(lang),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A))),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PublishListingDialog.show(context, draftProperty),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  test('the notice key is defined in Arabic, English and Hindi', () {
    for (final entry in expected.entries) {
      expect(AppLocalizations(Locale(entry.key)).tr('publicDescriptionContactNotice'), entry.value, reason: entry.key);
    }
  });

  for (final lang in ['ar', 'en', 'hi']) {
    testWidgets('the publish dialog shows the contact notice ($lang)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      LocaleController.setLanguage(lang);

      await tester.pumpWidget(app(lang));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(expected[lang]!), findsOneWidget);
    });
  }
}
