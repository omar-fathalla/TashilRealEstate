import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/repositories/property_repository.dart';

void main() {
  test('Marina matches the same listings in Arabic and English', () {
    final repo = PropertyRepository();
    final sample = PropertyItem.sampleProperties.firstWhere(
      (property) => property.locations['en']!.toLowerCase().contains('marina'),
    );
    repo.addProperty(sample);
    addTearDown(() => repo.removeProperty(sample.id));

    final english = repo.queryProperties(
      countryCode: sample.countryCode,
      langCode: 'en',
      searchQuery: 'Marina',
      pageSize: 50,
    );
    final arabic = repo.queryProperties(
      countryCode: sample.countryCode,
      langCode: 'ar',
      searchQuery: 'Marina',
      pageSize: 50,
    );

    expect(english.totalCount, greaterThan(0));
    expect(arabic.totalCount, english.totalCount);
    expect(arabic.items.map((item) => item.id), english.items.map((item) => item.id));
  });
}
