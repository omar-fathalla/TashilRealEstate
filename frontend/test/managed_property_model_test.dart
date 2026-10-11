import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';

void main() {
  group('ManagedPropertyModel & MonthlyInstallment Firestore Serialization Tests', () {
    test('MonthlyInstallment serialization and deserialization preserves all fields', () {
      final installment = MonthlyInstallment(
        monthKey: '2026-03',
        monthNumber: '03',
        monthNames: const {
          'ar': 'مارس 2026',
          'en': 'March 2026',
          'hi': 'मार्च 2026',
        },
        amount: 35000,
        dueDate: DateTime(2026, 3, 1),
        paidAt: DateTime(2026, 3, 2),
        status: InstallmentPaymentStatus.paidOnline,
        paymentMethod: 'google_pay',
        transactionRef: 'TXN-REC-12345',
        receiptNumber: 'REC-2026-03',
        notes: 'Paid on time via online portal',
      );

      final map = installment.toMap();
      final reconstructed = MonthlyInstallment.fromMap(map);

      expect(reconstructed.monthKey, equals('2026-03'));
      expect(reconstructed.monthNumber, equals('03'));
      expect(reconstructed.monthNames['ar'], equals('مارس 2026'));
      expect(reconstructed.monthNames['en'], equals('March 2026'));
      expect(reconstructed.monthNames['hi'], equals('मार्च 2026'));
      expect(reconstructed.amount, equals(35000));
      expect(reconstructed.status, equals(InstallmentPaymentStatus.paidOnline));
      expect(reconstructed.paymentMethod, equals('google_pay'));
      expect(reconstructed.transactionRef, equals('TXN-REC-12345'));
      expect(reconstructed.receiptNumber, equals('REC-2026-03'));
      expect(reconstructed.notes, equals('Paid on time via online portal'));
      expect(reconstructed.isPaid, isTrue);
    });

    test('ManagedPropertyModel serialization and deserialization preserves entire tree', () {
      final prop = ManagedPropertyModel(
        id: 'prop-test-999',
        countryCode: 'EG',
        currencyCode: 'EGP',
        titles: const {
          'ar': 'شقة فاخرة معدلة بالتجمع الخامس',
          'en': 'Modified Luxury Apartment New Cairo',
          'hi': 'संशोधित लक्जरी अपार्टमेंट न्यू काहिरा',
        },
        descriptions: const {
          'ar': 'شقة مميزة تم تعديل مواصفاتها',
          'en': 'Modified specifications apartment',
          'hi': 'संशोधित विनिर्देश अपार्टमेंट',
        },
        locations: const {
          'ar': 'النرجس، القاهرة الجديدة',
          'en': 'El Narges, New Cairo',
          'hi': 'अल नरगिस, न्यू काहिरा',
        },
        cityCode: 'new_cairo',
        propertyTypeCode: 'apartment',
        unitNumber: 'شقة 402',
        buildingName: 'برج الياسمين 3',
        pricePerMonth: 25000,
        bedrooms: 3,
        bathrooms: 2,
        areaSqM: 190,
        image: 'https://images.unsplash.com/photo-1',
        imageUrls: const [
          'https://images.unsplash.com/photo-1',
          'https://images.unsplash.com/photo-2',
        ],
        isPublished: true,
        rentalStatus: PropertyRentalStatus.available,
        installments: [
          MonthlyInstallment(
            monthKey: '2026-01',
            monthNumber: '01',
            monthNames: const {'ar': 'يناير 2026'},
            amount: 25000,
            dueDate: DateTime(2026, 1, 1),
            status: InstallmentPaymentStatus.upcoming,
          ),
        ],
      );

      final map = prop.toMap();
      final restored = ManagedPropertyModel.fromMap(map, docId: 'prop-test-999');

      expect(restored.id, equals('prop-test-999'));
      expect(restored.countryCode, equals('EG'));
      expect(restored.currencyCode, equals('EGP'));
      expect(restored.getTitle('ar'), equals('شقة فاخرة معدلة بالتجمع الخامس'));
      expect(restored.pricePerMonth, equals(25000));
      expect(restored.areaSqM, equals(190));
      expect(restored.isPublished, isTrue);
      expect(restored.rentalStatus, equals(PropertyRentalStatus.available));
      expect(restored.imageUrls.length, equals(2));
      expect(restored.installments.length, equals(1));
      expect(restored.installments.first.monthKey, equals('2026-01'));
    });

    test('PropertyItem serialization and deserialization preserves marketplace model', () {
      const item = PropertyItem(
        id: 'market-test-1',
        countryCode: 'AE',
        currencyCode: 'AED',
        titles: {
          'ar': 'شقة مارينا دبي',
          'en': 'Dubai Marina Apartment',
          'hi': 'दुबई मरीना अपार्टमेंट',
        },
        descriptions: {
          'ar': 'إطلالة بحرية خلابة',
          'en': 'Stunning sea view',
          'hi': 'शानदार समुद्री दृश्य',
        },
        propertyTypeCode: 'apartment',
        locations: {
          'ar': 'دبي مارينا، دبي',
          'en': 'Dubai Marina, Dubai',
          'hi': 'दुबई मरीना, दुबई',
        },
        cityCode: 'dubai',
        pricePerMonth: 15000,
        bedrooms: 2,
        bathrooms: 2,
        areaSqM: 130,
        imageUrls: ['https://photo1.jpg', 'https://photo2.jpg'],
        amenitiesMap: {
          'ar': ['مسبح', 'موقف خاص'],
          'en': ['Pool', 'Parking'],
          'hi': ['पूल', 'पार्किंग'],
        },
        isFurnished: true,
        isFeatured: true,
        agencyNames: {
          'ar': 'شركة تسهيل لإدارة الأملاك',
          'en': 'Tashil Property Management',
          'hi': 'तशिल संपत्ति प्रबंधन',
        },
        agencyPhone: '+971 4 123 4567',
        rating: 4.9,
      );

      final map = item.toMap();
      final restored = PropertyItem.fromMap(map, docId: 'market-test-1');

      expect(restored.id, equals('market-test-1'));
      expect(restored.countryCode, equals('AE'));
      expect(restored.currencyCode, equals('AED'));
      expect(restored.pricePerMonth, equals(15000));
      expect(restored.isFurnished, isTrue);
      expect(restored.isFeatured, isTrue);
      expect(restored.getTitle('ar'), equals('شقة مارينا دبي'));
      expect(restored.getTitle('en'), equals('Dubai Marina Apartment'));
      expect(restored.getAmenities('ar'), contains('مسبح'));
    });
  });
}
