import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';

void main() {
  group('listing contact (TAQ-150)', () {
    test('a listing without agency data shows the platform name and no phone', () {
      final item = PropertyItem.fromMap({'titles': {'en': 'Flat'}}, docId: 'p1');
      expect(item.agencyNames, PropertyItem.platformAgencyNames);
      expect(item.agencyPhone, isEmpty);
      expect(item.isVerifiedAgency, isFalse);
      expect(item.getAgencyName('ar'), 'تسهيل عقار');
      expect(item.getAgencyName('en'), 'Tashil Real Estate');
    });

    test('an agency listing keeps the agency name, and only a verified one carries an ORN', () {
      final unverified = PropertyItem.fromMap({
        'agencyNames': {'ar': 'مارينا العقارية', 'en': 'Marina Realty', 'hi': 'Marina Realty'},
        'agencyPhone': '',
      }, docId: 'p2');
      expect(unverified.getAgencyName('en'), 'Marina Realty');
      expect(unverified.isVerifiedAgency, isFalse);

      final verified = PropertyItem.fromMap({
        'agencyNames': {'en': 'Marina Realty'},
        'agencyOrn': '12345',
      }, docId: 'p3');
      expect(verified.isVerifiedAgency, isTrue);
      expect(verified.agencyOrn, '12345');
      expect(verified.toMap()['agencyOrn'], '12345');
    });

    test('the platform name has no placeholder company or Egyptian number', () {
      for (final name in PropertyItem.platformAgencyNames.values) {
        expect(name.contains('Property Management'), isFalse);
        expect(name.contains('لإدارة الأملاك'), isFalse);
      }
      expect(const PropertyItem(
        id: 'x', titles: {}, descriptions: {}, propertyTypeCode: 'apartment', locations: {}, cityCode: 'dubai',
        pricePerMonth: 1, bedrooms: 1, bathrooms: 1, areaSqM: 1, imageUrls: [], amenitiesMap: {}, agencyNames: {},
      ).agencyPhone, isEmpty);
    });
  });
}
