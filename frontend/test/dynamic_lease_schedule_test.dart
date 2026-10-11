import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

void main() {
  group('Dynamic Lease Schedule Generator Tests', () {

    test('generates exactly specified duration months (6, 12, 24)', () {
      final now = DateTime.now();

      final schedule6 = PropertyLifecycleService.generateDynamicSchedule(
        monthlyAmount: 2500,
        startDate: now,
        durationMonths: 6,
        firstMonthPaid: false,
      );
      expect(schedule6.length, 6);
      expect(schedule6.first.amount, 2500);

      final schedule12 = PropertyLifecycleService.generateDynamicSchedule(
        monthlyAmount: 3000,
        startDate: now,
        durationMonths: 12,
        firstMonthPaid: false,
      );
      expect(schedule12.length, 12);

      final schedule24 = PropertyLifecycleService.generateDynamicSchedule(
        monthlyAmount: 5000,
        startDate: now,
        durationMonths: 24,
        firstMonthPaid: false,
      );
      expect(schedule24.length, 24);
    });

    test('firstMonthPaid = false does NOT mark month 0 as paid and has zero mock Apple Pay', () {
      final now = DateTime.now();
      final schedule = PropertyLifecycleService.generateDynamicSchedule(
        monthlyAmount: 1000,
        startDate: now,
        durationMonths: 12,
        firstMonthPaid: false,
      );

      expect(schedule.first.isPaid, isFalse);
      expect(schedule.first.paymentMethod, isNull);
      expect(schedule.first.status, InstallmentPaymentStatus.due);
      // Ensure no mock Apple Pay exists anywhere in unpaid schedule
      for (final inst in schedule) {
        expect(inst.paymentMethod, isNot('apple_pay'));
      }
    });

    test('firstMonthPaid = true with cash marks only month 0 as paidCash and rest unpaid', () {
      final now = DateTime.now();
      final schedule = PropertyLifecycleService.generateDynamicSchedule(
        monthlyAmount: 1500,
        startDate: now,
        durationMonths: 12,
        firstMonthPaid: true,
        firstMonthPaymentMethod: 'cash',
      );

      expect(schedule.first.isPaid, isTrue);
      expect(schedule.first.status, InstallmentPaymentStatus.paidCash);
      expect(schedule.first.paymentMethod, 'cash');
      expect(schedule.first.receiptNumber, isNotNull);

      // Remaining months must be unpaid
      for (int i = 1; i < schedule.length; i++) {
        expect(schedule[i].isPaid, isFalse);
        expect(schedule[i].paymentMethod, isNull);
      }
    });

    test('past months are marked overdue and future months are marked upcoming', () {
      // Lease started 3 months ago
      final pastDate = DateTime(2025, 1, 1);
      final schedule = PropertyLifecycleService.generateDynamicSchedule(
        monthlyAmount: 2000,
        startDate: pastDate,
        durationMonths: 12,
        firstMonthPaid: false,
      );

      // 2025 months are strictly in the past relative to 2026
      expect(schedule.first.status, InstallmentPaymentStatus.overdue);
    });

    test('trilingual month names are generated with zero language mixing', () {
      final date = DateTime(2026, 5, 1);
      final schedule = PropertyLifecycleService.generateDynamicSchedule(
        monthlyAmount: 1000,
        startDate: date,
        durationMonths: 1,
      );

      final inst = schedule.first;
      expect(inst.getMonthName('ar'), contains('مايو'));
      expect(inst.getMonthName('en'), contains('May'));
      expect(inst.getMonthName('hi'), contains('मई'));
    });
  });

  group('Dynamic Real Payouts Ledger Tests', () {
    test('getRealPayouts returns only owner active properties and zero fake units', () {
      final service = PropertyLifecycleService();
      // Set single property in Alexandria rented for 500 EGP
      final alexProp = ManagedPropertyModel(
        id: 'prop-alex-90',
        countryCode: 'EG',
        currencyCode: 'EGP',
        titles: {
          'ar': 'شقة فاخرة 90 م² في بحري، الإسكندرية',
          'en': 'Luxury 90m² Apartment in Bahary, Alexandria',
          'hi': 'बहरी, अलेक्जेंड्रिया में लक्जरी 90 वर्ग मीटर का अपार्टमेंट',
        },
        descriptions: {
          'ar': 'تشطيب سوبر لوكس',
          'en': 'Super lux finish',
          'hi': 'सुपर लक्स फिनिश',
        },
        locations: {
          'ar': 'حي الجمرك - بحري، الإسكندرية',
          'en': 'Gomrok, Alexandria',
          'hi': 'गोमरोक, अलेक्जेंड्रिया',
        },
        cityCode: 'alexandria',
        propertyTypeCode: 'apartment',
        unitNumber: 'شقة 1',
        buildingName: 'عمارة بحري',
        pricePerMonth: 500,
        bedrooms: 2,
        bathrooms: 1,
        areaSqM: 90,
        image: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        imageUrls: const ['https://images.unsplash.com/photo-1545324418-cc1a3fa10c00'],
        isPublished: false,
        rentalStatus: PropertyRentalStatus.rented,
        tenantName: 'omar ahmed hassan',
        tenantPhone: '01508899965',
        leaseStartDate: DateTime(2026, 10, 10),
        installments: PropertyLifecycleService.generateDynamicSchedule(
          monthlyAmount: 500,
          startDate: DateTime(2026, 10, 10),
          durationMonths: 12,
          firstMonthPaid: false,
        ),
      );

      service.propertiesNotifier.value = [alexProp];

      final payouts = service.getRealPayouts(countryCode: 'EG');
      expect(payouts, isNotEmpty);
      expect(payouts.length, 1);
      expect(payouts.first['amount'], 500.0);
      expect(payouts.first['titles']['ar'], contains('الإسكندرية'));
      expect(payouts.first['titles']['ar'], isNot(contains('التجمع الخامس')));
      expect(payouts.first['titles']['ar'], isNot(contains('بيفرلي هيلز')));
      expect(payouts.first['titles']['ar'], isNot(contains('جاردن سيتي')));
    });

    test('getRealPayouts returns empty when owner has no rented properties', () {
      final service = PropertyLifecycleService();
      final vacantProp = ManagedPropertyModel(
        id: 'prop-vacant-1',
        countryCode: 'EG',
        currencyCode: 'EGP',
        titles: const {'ar': 'شقة شاغرة', 'en': 'Vacant Apt', 'hi': 'खाली अपार्टमेंट'},
        descriptions: const {'ar': 'وصف', 'en': 'Desc', 'hi': 'विवरण'},
        locations: const {'ar': 'القاهرة', 'en': 'Cairo', 'hi': 'काहिरा'},
        cityCode: 'cairo',
        propertyTypeCode: 'apartment',
        unitNumber: '1',
        buildingName: 'برج 1',
        pricePerMonth: 1000,
        bedrooms: 1,
        bathrooms: 1,
        areaSqM: 50,
        image: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        imageUrls: const ['https://images.unsplash.com/photo-1545324418-cc1a3fa10c00'],
        isPublished: true,
        rentalStatus: PropertyRentalStatus.available,
        installments: const [],
      );

      service.propertiesNotifier.value = [vacantProp];

      final payouts = service.getRealPayouts(countryCode: 'EG');
      expect(payouts, isEmpty);
    });
  });
}
