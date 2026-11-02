import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/text_fields/tashil_phone_text_field.dart';
import 'package:tashil_real_estate/core/design_system/text_fields/tashil_text_field.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/core/utils/digit_utils.dart';

void main() {
  group('DigitUtils Unit Tests', () {
    test('Converts Eastern Arabic numerals (٠-٩) to Western digits (0-9)', () {
      const arabicNumerals = '٠١٢٣٤٥٦٧٨٩';
      expect(DigitUtils.normalize(arabicNumerals), equals('0123456789'));
    });

    test('Converts Extended Persian/Urdu numerals (۰-۹) to Western digits (0-9)', () {
      const persianNumerals = '۰۱۲۳۴۵۶۷۸۹';
      expect(DigitUtils.normalize(persianNumerals), equals('0123456789'));
    });

    test('Normalizes Egyptian and UAE bank account numbers from screenshot', () {
      const arabicBankAcc = '٢١١٥٠٠١٣٨٠٤١٦٧٠١٠١';
      expect(DigitUtils.normalize(arabicBankAcc), equals('211500138041670101'));
    });

    test('Normalizes mixed address and national ID strings', () {
      const arabicAddress = '٣٧ شارع الجمرك القديم، الجمرك، الإسكندرية';
      expect(
        DigitUtils.normalize(arabicAddress),
        equals('37 شارع الجمرك القديم، الجمرك، الإسكندرية'),
      );

      const arabicId = '٢٨٧٠٩٠٤٠٢٠٠١١٢';
      expect(DigitUtils.normalize(arabicId), equals('28709040200112'));
    });

    test('Handles null, empty, and already-western strings gracefully', () {
      expect(DigitUtils.normalize(null), equals(''));
      expect(DigitUtils.normalize(''), equals(''));
      expect(DigitUtils.normalize('0123456789'), equals('0123456789'));
      expect(DigitUtils.normalize('Hello World!'), equals('Hello World!'));
      expect(DigitUtils.normalizeNullable(null), isNull);
      expect(DigitUtils.normalizeNullable('١٢٣'), equals('123'));
    });

    test('tryParseInt and tryParseDouble correctly parse Arabic numerals', () {
      expect(DigitUtils.tryParseInt('١٥٠٠٠'), equals(15000));
      expect(DigitUtils.tryParseInt('٢٥٠'), equals(250));
      expect(DigitUtils.tryParseDouble('١٥٠٠٠٫٥٠'), equals(15000.50));
      expect(DigitUtils.tryParseDouble('٢٨,٠٠٠'), equals(28000.0));
      expect(DigitUtils.tryParseInt(null), isNull);
      expect(DigitUtils.tryParseDouble(null), isNull);
    });
  });

  group('ArabicToEnglishDigitsFormatter TextInputFormatter Tests', () {
    const formatter = ArabicToEnglishDigitsFormatter();

    test('Replaces typed Eastern Arabic digits with Western digits preserving cursor', () {
      const oldValue = TextEditingValue(
        text: '12',
        selection: TextSelection.collapsed(offset: 2),
      );
      const newValue = TextEditingValue(
        text: '12٣',
        selection: TextSelection.collapsed(offset: 3),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('123'));
      expect(result.selection.baseOffset, equals(3));
      expect(result.selection.extentOffset, equals(3));
    });

    test('Leaves non-numeral and Western digits unchanged', () {
      const oldValue = TextEditingValue(
        text: 'Cairo',
        selection: TextSelection.collapsed(offset: 5),
      );
      const newValue = TextEditingValue(
        text: 'Cairo 2',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('Cairo 2'));
    });
  });

  group('Widget Integration Tests for TashilTextField & TashilPhoneTextField', () {
    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
        home: Scaffold(body: child),
      );
    }

    testWidgets('TashilTextField automatically normalizes Arabic numerals on input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestableWidget(
          TashilTextField(
            controller: controller,
            labelText: 'رقم الحساب',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Eastern Arabic numerals
      await tester.enterText(find.byType(TashilTextField), '٢١١٥٠٠١٣٨٠٤١٦٧٠١٠١');
      await tester.pumpAndSettle();

      // Verify that controller and text field now have Western English digits
      expect(controller.text, equals('211500138041670101'));
      expect(find.text('211500138041670101'), findsOneWidget);
    });

    testWidgets('TashilPhoneTextField converts Arabic digits before digitsOnly filter', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestableWidget(
          TashilPhoneTextField(
            controller: controller,
            countryCode: '+20',
            onCountryCodeChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter phone number with Arabic numerals
      await tester.enterText(find.byType(TextFormField), '٠١٢١١٨٥٧٧٢٥');
      await tester.pumpAndSettle();

      // Verify that phone number is normalized to Western English digits
      expect(controller.text, equals('01211857725'));
      expect(find.text('01211857725'), findsOneWidget);
    });

    test('UserProfileData fromMap normalizes Arabic digits in bank, national ID, and phone', () {
      final data = UserProfileData.fromMap({
        'uid': 'test_uid',
        'email': 'test@example.com',
        'fullName': 'عمر طارق',
        'phone': '+20 ٠١٢١١٨٥٧٧٢٥',
        'nationalId': '٢٨٧٠٩٠٤٠٢٠٠١١٢',
        'address': '٣٧ شارع الجمرك القديم',
        'bankName': 'البنك الأهلي المصري',
        'bankAccountNumber': '٢١١٥٠٠١٣٨٠٤١٦٧٠١٠١',
        'iban': '٢١١٥٠٠١٣٨٠٤١٦٧٠١٠١',
      });

      expect(data.phone, equals('+20 01211857725'));
      expect(data.nationalId, equals('28709040200112'));
      expect(data.address, equals('37 شارع الجمرك القديم'));
      expect(data.bankAccountNumber, equals('211500138041670101'));
      expect(data.iban, equals('211500138041670101'));
    });
  });
}
