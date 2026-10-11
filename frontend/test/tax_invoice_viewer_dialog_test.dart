import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tax_invoice_viewer_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({Locale locale = const Locale('ar'), String country = 'EG', bool forcePaid = true}) {
    LocaleController.setLocale(locale);
    CountryController.setCountry(country);

    final invoices = RentCollectionService().invoicesNotifier.value;
    final baseInvoice = invoices.firstWhere(
      (inv) => inv.countryCode == country,
      orElse: () => invoices.first,
    );

    final testInvoice = baseInvoice.copyWith(
      status: forcePaid ? 'paid' : 'pending',
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
        body: TaxInvoiceViewerDialog(invoice: testInvoice),
      ),
    );
  }

  group('Tax Invoice Viewer Dialog M3 & Dynamic QR Tests', () {
    testWidgets('Renders Arabic tax invoice with dynamic enlarged QR code, no raw propertyTitle, and Action button', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar'), country: 'EG', forcePaid: true));
      await tester.pumpAndSettle();

      // 1. Verify Header & Shaded Close Button
      expect(find.text('فاتورة إلكترونية ضريبية معتمدة'), findsOneWidget);
      expect(find.byType(TashilIconButton), findsOneWidget);

      // 2. Verify that raw unlocalized key "propertyTitle" does NOT exist, and translated "العين المؤجرة" is shown
      expect(find.text('propertyTitle'), findsNothing, reason: 'Raw propertyTitle key must not be displayed');
      expect(find.text('العين المؤجرة'), findsOneWidget, reason: 'Must display localized label for leased property');

      // 3. Verify Dynamic Enlarged QR code widget
      final qrFinder = find.byType(QrImageView);
      expect(qrFinder, findsOneWidget, reason: 'Dynamic QR Image must be rendered');
      final qrWidget = tester.widget<QrImageView>(qrFinder);
      expect(qrWidget.size, greaterThanOrEqualTo(140.0), reason: 'QR Code size must be enlarged for camera scanning');

      // 4. Verify QR Verification details
      expect(find.text('رمز التحقق الضريبي المعتمد (QR)'), findsOneWidget);
      expect(find.text('موثقة رقمياً ومسجلة'), findsOneWidget);

      // 5. Verify Bottom Action Button: label must be "تنزيل الفاتورة" and must be an M3 action button (TashilButton filled)
      expect(find.text('تنزيل الفاتورة الضريبية المعتمدة'), findsNothing, reason: 'Old long label must be replaced');
      expect(find.text('تنزيل الفاتورة'), findsOneWidget, reason: 'Must display short action label');
      expect(find.byType(TashilButton), findsOneWidget, reason: 'Must be an official TashilButton action button');
    });

    testWidgets('Pending invoice renders action buttons suite (Pay Now + Download Invoice)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar'), country: 'EG', forcePaid: false));
      await tester.pumpAndSettle();

      expect(find.text('تنزيل الفاتورة'), findsOneWidget);
      expect(find.text('دفع إلكتروني فوري'), findsOneWidget);
      expect(find.byType(TashilButton), findsNWidgets(2));
    });

    testWidgets('Renders in English and Hindi with full parity and correct action button labels', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // English
      await tester.pumpWidget(buildTestApp(locale: const Locale('en'), country: 'EG', forcePaid: true));
      await tester.pumpAndSettle();

      expect(find.text('Official Electronic Tax Invoice'), findsOneWidget);
      expect(find.text('Leased Property'), findsOneWidget);
      expect(find.text('Download Invoice'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      // Hindi
      await tester.pumpWidget(buildTestApp(locale: const Locale('hi'), country: 'EG', forcePaid: true));
      await tester.pumpAndSettle();

      expect(find.text('आधिकारिक इलेक्ट्रॉनिक कर चालान'), findsOneWidget);
      expect(find.text('पट्टे पर दी गई संपत्ति'), findsOneWidget);
      expect(find.text('चालान डाउनलोड करें'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });
}
