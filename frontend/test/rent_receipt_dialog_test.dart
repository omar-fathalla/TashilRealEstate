import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/rent_receipt_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({Locale locale = const Locale('ar'), String country = 'EG'}) {
    LocaleController.setLocale(locale);
    CountryController.setCountry(country);

    final invoices = RentCollectionService().invoicesNotifier.value;
    final baseInvoice = invoices.firstWhere(
      (inv) => inv.countryCode == country,
      orElse: () => invoices.first,
    );

    final testInvoice = baseInvoice.copyWith(
      status: 'paid',
      paidAt: DateTime(2026, 9, 13, 17, 52),
      paymentMethod: 'card',
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
        body: RentReceiptDialog(invoice: testInvoice),
      ),
    );
  }

  group('Rent Receipt Dialog M3 & Dynamic QR Redesign Tests', () {
    testWidgets('Renders Arabic receipt with pinned header, enlarged QR code, zero language mixing, and M3 action buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar'), country: 'EG'));
      await tester.pumpAndSettle();

      // 1. Verify Header & Shaded Close Button
      expect(find.text('إيصال سداد القيمة الإيجارية'), findsOneWidget);
      expect(find.byType(TashilIconButton), findsOneWidget);

      // 2. Verify Zero Language Mixing: raw "paymentMethod" key must not appear
      expect(find.textContaining('paymentMethod:'), findsNothing, reason: 'Raw paymentMethod key must not be displayed');
      expect(find.text('طريقة الدفع: بطاقة بنكية مصرفية'), findsOneWidget, reason: 'Must display localized payment method');

      // 3. Verify Receipt Ref & Status
      expect(find.text('إيصال سداد رقمي معتمد وموثق'), findsOneWidget);
      expect(find.textContaining('RCP-INV-EG-2026-0801'), findsOneWidget);

      // 4. Verify Dynamic Enlarged QR code widget
      final qrFinder = find.byType(QrImageView);
      expect(qrFinder, findsOneWidget, reason: 'Dynamic QR Image must be rendered');
      final qrWidget = tester.widget<QrImageView>(qrFinder);
      expect(qrWidget.size, greaterThanOrEqualTo(135.0), reason: 'QR Code size must be enlarged for camera scanning');

      // 5. Verify QR Verification details
      expect(find.text('رمز التحقق الرقمي للإيصال (QR)'), findsOneWidget);
      expect(find.text('موثقة رقمياً ومسجلة'), findsOneWidget);

      // 6. Verify Action Buttons: Filled Export PDF + Tonal Done
      expect(find.text('تصدير PDF'), findsOneWidget);
      expect(find.text('تم الانتهاء'), findsOneWidget);
      expect(find.byType(TashilButton), findsNWidgets(2));
    });

    testWidgets('Renders in English and Hindi with full parity and localized payment method', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // English
      await tester.pumpWidget(buildTestApp(locale: const Locale('en'), country: 'AE'));
      await tester.pumpAndSettle();

      expect(find.text('Official Rent Payment Receipt'), findsOneWidget);
      expect(find.text('Payment Method: Debit / Credit Card'), findsOneWidget);
      expect(find.text('Certified Receipt Verification QR Code'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Hindi
      await tester.pumpWidget(buildTestApp(locale: const Locale('hi'), country: 'EG'));
      await tester.pumpAndSettle();

      expect(find.text('आधिकारिक किराया भुगतान रसीद'), findsOneWidget);
      expect(find.text('भुगतान विधि: डेबिट / क्रेडिट कार्ड'), findsOneWidget);
      expect(find.text('प्रमाणित रसीद सत्यापन क्यूआर कोड'), findsOneWidget);
      expect(find.text('पीडीएफ निर्यात'), findsOneWidget);
      expect(find.text('पूर्ण'), findsOneWidget);
    });
  });
}
