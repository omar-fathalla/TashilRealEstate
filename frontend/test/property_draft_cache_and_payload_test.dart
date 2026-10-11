import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/core/services/storage/property_draft_cache_service.dart';

void main() {
  group('FastPropertyDraft & PropertyDraftCacheService Tests', () {
    setUp(() async {
      await PropertyDraftCacheService().clearDraft();
    });

    test('FastPropertyDraft serializes and deserializes accurately with all 5 sections', () {
      final original = FastPropertyDraft(
        countryCode: 'EG',
        city: 'الإسكندرية',
        district: 'سموحة',
        streetAddress: 'شارع فوزي معاذ 15',
        buildingName: 'برج الأندلس',
        unitNumber: '502',
        monthlyRent: 35000,
        currency: 'EGP',
        paymentFrequency: PaymentFrequency.quarterly,
        securityDeposit: 70000,
        isBillsIncluded: true,
        isNegotiable: false,
        propertyType: 'apartment',
        areaSqm: 220,
        bedrooms: 4,
        bathrooms: 3,
        floor: 5,
        buildingAge: BuildingAge.oneToFive,
        hasMaidsRoom: true,
        furnishingStatus: FurnishingStatus.fullyFurnished,
        hasParking: true,
        hasCentralAc: true,
        hasPoolGym: true,
        hasSecurity: true,
        hasBalconyView: true,
        isPetFriendly: true,
        photoUrls: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ],
        titleAr: 'شقة فاخرة بسموحة على شارع فوزي معاذ',
        titleEn: 'Luxury Apartment in Smouha',
        titleHi: 'स्मोहा में लक्जरी अपार्टमेंट',
        descriptionAr: 'شقة واسعة بإطلالة رائعة وتشطيب ألترا لوكس',
        descriptionEn: 'Spacious apartment with prime view and ultra lux finish',
        descriptionHi: 'शानदार दृश्य के साथ विशाल अपार्टमेंट',
        videoTourUrl: 'https://youtube.com/watch?v=sample',
        availableFrom: DateTime(2026, 11, 1),
      );

      final jsonMap = original.toJson();
      final reconstructed = FastPropertyDraft.fromJson(jsonMap);

      expect(reconstructed.countryCode, 'EG');
      expect(reconstructed.city, 'الإسكندرية');
      expect(reconstructed.district, 'سموحة');
      expect(reconstructed.streetAddress, 'شارع فوزي معاذ 15');
      expect(reconstructed.buildingName, 'برج الأندلس');
      expect(reconstructed.unitNumber, '502');
      expect(reconstructed.monthlyRent, 35000);
      expect(reconstructed.currency, 'EGP');
      expect(reconstructed.paymentFrequency, PaymentFrequency.quarterly);
      expect(reconstructed.securityDeposit, 70000);
      expect(reconstructed.isBillsIncluded, isTrue);
      expect(reconstructed.isNegotiable, isFalse);
      expect(reconstructed.propertyType, 'apartment');
      expect(reconstructed.areaSqm, 220);
      expect(reconstructed.bedrooms, 4);
      expect(reconstructed.bathrooms, 3);
      expect(reconstructed.floor, 5);
      expect(reconstructed.buildingAge, BuildingAge.oneToFive);
      expect(reconstructed.hasMaidsRoom, isTrue);
      expect(reconstructed.furnishingStatus, FurnishingStatus.fullyFurnished);
      expect(reconstructed.hasParking, isTrue);
      expect(reconstructed.hasCentralAc, isTrue);
      expect(reconstructed.photoUrls.length, 3);
      expect(reconstructed.titleAr, 'شقة فاخرة بسموحة على شارع فوزي معاذ');
      expect(reconstructed.titleEn, 'Luxury Apartment in Smouha');
      expect(reconstructed.descriptionAr, 'شقة واسعة بإطلالة رائعة وتشطيب ألترا لوكس');
      expect(reconstructed.videoTourUrl, 'https://youtube.com/watch?v=sample');
      expect(reconstructed.availableFrom, DateTime(2026, 11, 1));
    });

    test('PropertyDraftCacheService preserves, retrieves, and clears draft in cache', () async {
      final cacheService = PropertyDraftCacheService();
      expect(cacheService.hasDraft(), isFalse);
      expect(cacheService.getDraft(), isNull);

      final draft = FastPropertyDraft(
        city: 'دبي',
        district: 'وسط مدينة دبي',
        monthlyRent: 120000,
        currency: 'AED',
        countryCode: 'AE',
        photoUrls: ['https://example.com/dubai1.jpg', 'https://example.com/dubai2.jpg', 'https://example.com/dubai3.jpg'],
        titleAr: 'شقة برج خليفة بإطلالة ساحرة',
      );

      await cacheService.saveDraft(draft);
      expect(cacheService.hasDraft(), isTrue);

      final restored = cacheService.getDraft();
      expect(restored, isNotNull);
      expect(restored!.city, 'دبي');
      expect(restored.district, 'وسط مدينة دبي');
      expect(restored.monthlyRent, 120000);
      expect(restored.currency, 'AED');
      expect(restored.countryCode, 'AE');
      expect(restored.titleAr, 'شقة برج خليفة بإطلالة ساحرة');
      expect(restored.photoUrls.length, 3);

      await cacheService.clearDraft();
      expect(cacheService.hasDraft(), isFalse);
      expect(cacheService.getDraft(), isNull);
    });

    test('Compressed image payloads stay safely under Firestore 1MB document limit', () {
      // Create 10 compressed base64 images (~60KB each)
      final sample60KbStr = 'data:image/jpeg;base64,${'A' * 60000}';
      final photoUrls = List.generate(10, (i) => sample60KbStr);

      final draft = FastPropertyDraft(
        city: 'القاهرة',
        district: 'التجمع الخامس',
        monthlyRent: 45000,
        photoUrls: photoUrls,
      );

      final jsonPayload = jsonEncode(draft.toJson());
      final byteSize = utf8.encode(jsonPayload).length;

      // Firestore limit is 1,048,576 bytes
      const firestoreLimit = 1048576;
      expect(byteSize, lessThan(firestoreLimit));
      // 10 compressed photos + metadata takes ~605 KB, comfortably below 1MB
      expect(byteSize, lessThan(700000));
    });
  });
}
