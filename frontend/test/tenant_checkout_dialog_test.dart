import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({Locale locale = const Locale('ar'), String country = 'EG'}) {
    LocaleController.setLocale(locale);
    CountryController.setCountry(country);

    final invoices = RentCollectionService().invoicesNotifier.value;
    final invoice = invoices.firstWhere(
      (inv) => inv.countryCode == country,
      orElse: () => invoices.first,
    );

    return MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
        ),
      ),
      home: Scaffold(
        body: TenantCheckoutDialog(invoice: invoice),
      ),
    );
  }

  group('Tenant Checkout Dialog Numeric LTR Standards Tests', () {
    testWidgets('Credit card inputs (Card Number, Expiry, CVV) are strictly LTR and left-aligned in Arabic RTL', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar'), country: 'EG'));
      await tester.pumpAndSettle();

      // Verify Dialog renders with title
      expect(find.text('سداد الإيجار والتحويل الفوري'), findsOneWidget);

      // Find all TextFields in Card Payment mode
      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, 3, reason: 'Card payment must have Card Number, Expiry, and CVV fields');

      final cardNumberField = textFields[0];
      final cardExpiryField = textFields[1];
      final cardCvvField = textFields[2];

      // 1. Card Number field must be strictly LTR and left-aligned
      expect(cardNumberField.textDirection, TextDirection.ltr, reason: 'Card number must be LTR');
      expect(cardNumberField.textAlign, TextAlign.left, reason: 'Card number must be left-aligned');
      expect(cardNumberField.controller?.text, '4111 2222 3333 4444');

      // 2. Card Expiry field must be strictly LTR and left-aligned
      expect(cardExpiryField.textDirection, TextDirection.ltr, reason: 'Card expiry must be LTR');
      expect(cardExpiryField.textAlign, TextAlign.left, reason: 'Card expiry must be left-aligned');
      expect(cardExpiryField.controller?.text, '12/28');

      // 3. Card CVV field must be strictly LTR and left-aligned
      expect(cardCvvField.textDirection, TextDirection.ltr, reason: 'Card CVV must be LTR');
      expect(cardCvvField.textAlign, TextAlign.left, reason: 'Card CVV must be left-aligned');
      expect(cardCvvField.obscureText, isTrue);

      // 4. In the horizontal Row, Expiry Date must be positioned on the LEFT of CVV
      final expiryPos = tester.getTopLeft(find.byWidget(cardExpiryField));
      final cvvPos = tester.getTopLeft(find.byWidget(cardCvvField));
      expect(expiryPos.dx, lessThan(cvvPos.dx), reason: 'Expiry Date field must be to the left of CVV field');
    });

    testWidgets('Vodafone Cash and InstaPay inputs are strictly LTR and left-aligned', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar'), country: 'EG'));
      await tester.pumpAndSettle();

      // Switch to Vodafone Cash
      final vodafoneOption = find.text('محفظة إلكترونية');
      expect(vodafoneOption, findsOneWidget);
      await tester.tap(vodafoneOption);
      await tester.pumpAndSettle();

      final phoneField = tester.widget<TextField>(find.byType(TextField));
      expect(phoneField.textDirection, TextDirection.ltr, reason: 'Wallet phone number must be LTR');
      expect(phoneField.textAlign, TextAlign.left, reason: 'Wallet phone number must be left-aligned');
      expect(phoneField.controller?.text, '01012345678');

      // Switch to InstaPay
      final instaPayOption = find.text('شبكة المدفوعات اللحظية (إنستاباي)');
      expect(instaPayOption, findsOneWidget);
      await tester.tap(instaPayOption);
      await tester.pumpAndSettle();

      final vpaField = tester.widget<TextField>(find.byType(TextField));
      expect(vpaField.textDirection, TextDirection.ltr, reason: 'InstaPay VPA must be LTR');
      expect(vpaField.textAlign, TextAlign.left, reason: 'InstaPay VPA must be left-aligned');
      expect(vpaField.controller?.text, 'tenant@instapay');
    });

    testWidgets('Card inputs maintain LTR and left alignment in English and Hindi', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final locale in [const Locale('en'), const Locale('hi')]) {
        await tester.pumpWidget(buildTestApp(locale: locale, country: 'EG'));
        await tester.pumpAndSettle();

        final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
        expect(textFields.length, 3);

        for (final tf in textFields) {
          expect(tf.textDirection, TextDirection.ltr);
          expect(tf.textAlign, TextAlign.left);
        }
      }
    });
  });
}
