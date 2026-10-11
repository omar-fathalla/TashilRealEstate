import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/services/bank_directory_service.dart';

void main() {
  group('BankDirectoryService Comprehensive Tests', () {
    test('Egyptian Banks Directory contains 30+ CBE accredited banks and Other option', () {
      final banks = BankDirectoryService.getBanksForCountry('EG');
      expect(banks.length, greaterThanOrEqualTo(31));

      // Key banks verification
      final nbe = banks.firstWhere((b) => b.code == 'NBE');
      expect(nbe.nameAr, contains('البنك الأهلي المصري'));
      expect(nbe.nameEn, equals('National Bank of Egypt (NBE)'));
      expect(nbe.countryCode, equals('EG'));

      final cib = banks.firstWhere((b) => b.code == 'CIB');
      expect(cib.nameAr, contains('البنك التجاري الدولي'));
      expect(cib.nameEn, equals('Commercial International Bank (CIB)'));

      final misr = banks.firstWhere((b) => b.code == 'MISR');
      expect(misr.nameAr, equals('بنك مصر'));

      final other = banks.firstWhere((b) => b.code == BankDirectoryService.otherBankCode);
      expect(other.isOther, isTrue);
    });

    test('UAE Banks Directory contains 24 CBUAE accredited banks and Other option', () {
      final banks = BankDirectoryService.getBanksForCountry('AE');
      expect(banks.length, greaterThanOrEqualTo(24));

      // Key banks verification
      final enbd = banks.firstWhere((b) => b.code == 'ENBD');
      expect(enbd.nameAr, contains('بنك الإمارات دبي الوطني'));
      expect(enbd.nameEn, equals('Emirates NBD'));
      expect(enbd.countryCode, equals('AE'));

      final fab = banks.firstWhere((b) => b.code == 'FAB');
      expect(fab.nameAr, contains('بنك أبوظبي الأول'));
      expect(fab.nameEn, equals('First Abu Dhabi Bank (FAB)'));

      final adcb = banks.firstWhere((b) => b.code == 'ADCB');
      expect(adcb.nameAr, contains('بنك أبوظبي التجاري'));

      final dib = banks.firstWhere((b) => b.code == 'DIB');
      expect(dib.nameAr, contains('بنك دبي الإسلامي'));

      final other = banks.firstWhere((b) => b.code == BankDirectoryService.otherBankCode);
      expect(other.isOther, isTrue);
    });

    test('findBank accurately matches by code or name across languages', () {
      // Egypt searches
      expect(BankDirectoryService.findBank('NBE', 'EG')?.code, equals('NBE'));
      expect(BankDirectoryService.findBank('البنك الأهلي المصري (NBE)', 'EG')?.code, equals('NBE'));
      expect(BankDirectoryService.findBank('National Bank of Egypt (NBE)', 'EG')?.code, equals('NBE'));
      expect(BankDirectoryService.findBank('CIB', 'EG')?.code, equals('CIB'));

      // UAE searches
      expect(BankDirectoryService.findBank('ENBD', 'AE')?.code, equals('ENBD'));
      expect(BankDirectoryService.findBank('Emirates NBD', 'AE')?.code, equals('ENBD'));
      expect(BankDirectoryService.findBank('FAB', 'AE')?.code, equals('FAB'));
      expect(BankDirectoryService.findBank('ADCB', 'AE')?.code, equals('ADCB'));

      // Unknown query returns null
      expect(BankDirectoryService.findBank('RandomNonExistentBank', 'EG'), isNull);
    });

    test('Trilingual pure localizedName produces correct output for AR, EN, and HI', () {
      final nbe = BankDirectoryService.egyptianBanks.firstWhere((b) => b.code == 'NBE');
      expect(nbe.localizedName('ar'), equals('البنك الأهلي المصري (NBE)'));
      expect(nbe.localizedName('en'), equals('National Bank of Egypt (NBE)'));
      expect(nbe.localizedName('hi'), equals('नेशनल बैंक ऑफ मिस्र (NBE)'));

      final enbd = BankDirectoryService.uaeBanks.firstWhere((b) => b.code == 'ENBD');
      expect(enbd.localizedName('ar'), equals('بنك الإمارات دبي الوطني (Emirates NBD)'));
      expect(enbd.localizedName('en'), equals('Emirates NBD'));
      expect(enbd.localizedName('hi'), equals('एमिरेट्स एनबीडी'));
    });

    test('resolveBankName resolves recognized code to localized name or preserves custom text', () {
      expect(
        BankDirectoryService.resolveBankName('NBE', 'EG', 'ar'),
        equals('البنك الأهلي المصري (NBE)'),
      );
      expect(
        BankDirectoryService.resolveBankName('ENBD', 'AE', 'en'),
        equals('Emirates NBD'),
      );
      expect(
        BankDirectoryService.resolveBankName('My Offshore Private Bank', 'EG', 'ar'),
        equals('My Offshore Private Bank'),
      );
    });
  });
}
