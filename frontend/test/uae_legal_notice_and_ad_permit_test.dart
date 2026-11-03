import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/advertising_permit.dart';
import 'package:tashil_real_estate/core/utils/uae_emirate.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_card.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_details_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/legal_warning_notice_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UAE emirate legal notice', () {
    test('maps city codes and district text to the right authority', () {
      expect(resolveUaeEmirate(cityCode: 'dubai'), UaeEmirate.dubai);
      expect(resolveUaeEmirate(cityCode: 'abu_dhabi'), UaeEmirate.abuDhabi);
      expect(resolveUaeEmirate(cityCode: 'sharjah'), UaeEmirate.sharjah);
      expect(resolveUaeEmirate(cityCode: 'ajman'), UaeEmirate.ajman);
      expect(resolveUaeEmirate(cityCode: 'umm_al_quwain'), UaeEmirate.ummAlQuwain);
      expect(resolveUaeEmirate(cityCode: 'ras_al_khaimah'), UaeEmirate.rasAlKhaimah);
      expect(resolveUaeEmirate(cityCode: 'fujairah'), UaeEmirate.fujairah);
      expect(resolveUaeEmirate(district: 'Dubai Marina'), UaeEmirate.dubai);
      expect(resolveUaeEmirate(city: 'أبوظبي'), UaeEmirate.abuDhabi);
      expect(resolveUaeEmirate(city: 'الشارقة'), UaeEmirate.sharjah);
      expect(legalNoticeBodyKey(UaeEmirate.dubai), 'legalNoticeBody_ae');
      expect(legalNoticeBodyKey(UaeEmirate.abuDhabi), 'legalNoticeBody_ad');
      expect(legalNoticeBodyKey(UaeEmirate.sharjah), 'legalNoticeBody_shj');
      expect(legalNoticeBodyKey(UaeEmirate.ajman), 'legalNoticeBody_ae_other');
      expect(legalNoticeBodyKey(UaeEmirate.fujairah), 'legalNoticeBody_ae_other');
      expect(legalNoticeBodyKey(UaeEmirate.unspecified), 'legalNoticeBody_ae_other');
    });

    test('deriveCityCode keeps Fujairah and Umm Al Quwain off the Dubai fallback', () {
      expect(
        deriveCityCode(city: 'الفجيرة', district: 'البدية', countryCode: 'AE'),
        'fujairah',
      );
      expect(
        deriveCityCode(city: 'Umm Al Quwain', district: 'Al Salamah', countryCode: 'AE'),
        'umm_al_quwain',
      );
      expect(
        deriveCityCode(city: 'دبي', district: 'دبي مارينا', countryCode: 'AE'),
        'dubai',
      );
    });

    testWidgets('Abu Dhabi, Sharjah, and Ajman notices name the right authority', (tester) async {
      Future<void> expectNotice(String cityCode, String text) async {
        LocaleController.setLocale(const Locale('en'));
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LegalWarningNoticeDialog(invoice: _invoice(cityCode)),
        ));
        await tester.pumpAndSettle();
        expect(find.textContaining(text), findsWidgets);
      }

      await expectNotice('abu_dhabi', 'Rental Dispute Settlement Committees');
      await expectNotice('sharjah', 'Rental Disputes Center, Sharjah');
      await expectNotice('ajman', 'competent rental dispute authority in the emirate');
      await expectNotice('dubai', 'Rental Disputes Center (RDC)');
    });
  });

  group('Advertising permit', () {
    test('Dubai requires 6 to 15 digits and other emirates may omit it', () {
      expect(AdvertisingPermit.errorKey(value: '', cityCode: 'dubai'), 'adPermitRequired');
      expect(AdvertisingPermit.errorKey(value: '123', cityCode: 'dubai'), 'adPermitInvalid');
      expect(AdvertisingPermit.errorKey(value: '71A3456789', cityCode: 'dubai'), 'adPermitInvalid');
      expect(AdvertisingPermit.errorKey(value: '7123456789', cityCode: 'dubai'), isNull);
      expect(AdvertisingPermit.errorKey(value: '', cityCode: 'abu_dhabi'), isNull);
      expect(AdvertisingPermit.errorKey(value: '12', cityCode: 'sharjah'), 'adPermitInvalid');
    });

    test('draft and marketplace models keep the permit number', () {
      final draft = FastPropertyDraft(countryCode: 'AE', advertisingPermitNumber: '7123456789');
      final restored = FastPropertyDraft.fromJson(draft.toJson());
      expect(restored.advertisingPermitNumber, '7123456789');

      final item = PropertyItem(
        id: 'p1',
        countryCode: 'AE',
        currencyCode: 'AED',
        titles: const {'ar': 'شقة', 'en': 'Flat', 'hi': 'फ्लैट'},
        descriptions: const {'ar': 'وصف', 'en': 'Text', 'hi': 'पाठ'},
        propertyTypeCode: 'apartment',
        locations: const {'ar': 'دبي', 'en': 'Dubai', 'hi': 'दुबई'},
        cityCode: 'dubai',
        pricePerMonth: 10000,
        bedrooms: 1,
        bathrooms: 1,
        areaSqM: 70,
        imageUrls: const ['assets/images/properties/prop_eg_1_1.jpg'],
        amenitiesMap: const {'en': []},
        agencyNames: const {'en': 'Agency'},
        advertisingPermitNumber: '7123456789',
      );
      final fromMap = PropertyItem.fromMap(item.toMap());
      expect(fromMap.advertisingPermitNumber, '7123456789');
    });

    testWidgets('property card and details show the permit number and a QR code', (tester) async {
      LocaleController.setLocale(const Locale('ar'));
      final property = PropertyItem(
        id: 'permit-card',
        countryCode: 'AE',
        currencyCode: 'AED',
        titles: const {'ar': 'شقة', 'en': 'Marina flat', 'hi': 'फ्लैट'},
        descriptions: const {'ar': 'وصف', 'en': 'A listing', 'hi': 'पाठ'},
        propertyTypeCode: 'apartment',
        locations: const {'ar': 'دبي مارينا', 'en': 'Dubai Marina', 'hi': 'दुबई मरीना'},
        cityCode: 'dubai',
        pricePerMonth: 12000,
        bedrooms: 2,
        bathrooms: 2,
        areaSqM: 90,
        imageUrls: const ['assets/images/properties/prop_eg_1_1.jpg'],
        amenitiesMap: const {'en': ['Pool']},
        agencyNames: const {'en': 'Agency', 'ar': 'وكالة', 'hi': 'एजेंसी'},
        advertisingPermitNumber: '7123456789',
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('hi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 420, child: PropertyCard(property: property)),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('رقم تصريح الإعلان'), findsOneWidget);
      expect(find.text('7123456789'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('hi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: PropertyDetailsDialog(property: property),
      ));
      await tester.pumpAndSettle();
      expect(find.text('7123456789'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });
}

RentInvoiceModel _invoice(String cityCode) {
  return RentInvoiceModel(
    id: 'inv-$cityCode',
    invoiceNumber: 'INV-$cityCode',
    contractNumber: 'AE-2026-001',
    countryCode: 'AE',
    unitTitle: 'Unit',
    unitNumber: '12',
    buildingName: 'Tower',
    district: 'District',
    cityCode: cityCode,
    tenant: const TenantInfo(name: 'Tenant', phone: '+971500000000', email: 't@example.com', idNumber: '784'),
    owner: const OwnerPayoutInfo(name: 'Owner', bankName: 'Bank', iban: 'AE00', accountNumber: '1'),
    baseAmount: 10000,
    dueDate: DateTime(2026, 1, 1),
    status: 'overdue',
    dailyPenaltyRate: 0,
  );
}
