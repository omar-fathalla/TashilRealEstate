import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/remote_config_service.dart';
import 'package:tashil_real_estate/core/services/crash_reporting_service.dart';
import 'package:tashil_real_estate/core/services/invoice_receipt_service.dart';
import 'package:tashil_real_estate/core/design_system/firebase_hub/firebase_enterprise_hub_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child, {Locale locale = const Locale('ar')}) {
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
        body: child,
      ),
    );
  }

  group('Firebase Enterprise Services Unit Tests', () {
    test('RemoteConfigService resolves correct parameters and fallback defaults', () {
      final config = RemoteConfigService();
      expect(config.platformFeePercentage, equals(2.5));
      expect(config.getVatRate('EG'), equals(0.14));
      expect(config.getVatRate('AE'), equals(0.05));
      expect(config.getMaxSearchPrice('EG'), equals(100000.0));
      expect(config.getMaxSearchPrice('AE'), equals(50000.0));
      expect(config.isLegalAiEnabled, isTrue);
      expect(config.isVirtualStagingEnabled, isTrue);
      expect(config.isAiValuationEnabled, isTrue);
    });

    test('CrashReportingService records errors in observable stream', () async {
      final crashService = CrashReportingService();
      final initialCount = crashService.recentErrors.value.length;

      await crashService.recordError(
        'Test Simulated Exception',
        StackTrace.current,
        reason: 'Unit Test Verification',
      );

      expect(crashService.recentErrors.value.length, equals(initialCount + 1));
      expect(crashService.recentErrors.value.first.message, contains('Test Simulated Exception'));
    });

    test('InvoiceReceiptService generates structured receipt with correct VAT for Egypt & UAE', () async {
      final invoiceService = InvoiceReceiptService();

      // Egypt test (14% VAT)
      final egReceipt = await invoiceService.generateReceipt(
        leaseId: 'LS-EG-TEST',
        tenantName: 'أحمد علي',
        propertyTitle: 'شقة المعادي',
        rentalAmount: 10000.0,
        countryCode: 'EG',
      );

      expect(egReceipt.currencyCode, equals('EGP'));
      expect(egReceipt.rentalAmount, equals(10000.0));
      // Platform fee: 2.5% = 250, Agency fee: 8% = 800, Total fees = 1050
      // VAT: 1050 * 0.14 = 147
      expect(egReceipt.platformFee, equals(250.0));
      expect(egReceipt.agencyFee, equals(800.0));
      expect(egReceipt.vatAmount, closeTo(147.0, 0.01));
      expect(egReceipt.totalPaid, closeTo(10147.0, 0.01));
      expect(egReceipt.verificationQrData, contains('TASHIL_VERIFIED'));

      // UAE test (5% VAT)
      final aeReceipt = await invoiceService.generateReceipt(
        leaseId: 'LS-AE-TEST',
        tenantName: 'John Doe',
        propertyTitle: 'Marina Flat',
        rentalAmount: 10000.0,
        countryCode: 'AE',
      );

      expect(aeReceipt.currencyCode, equals('AED'));
      expect(aeReceipt.vatAmount, closeTo(1050 * 0.05, 0.01));
    });
  });

  group('FirebaseEnterpriseHubDialog Widget Tests', () {
    testWidgets('Renders all 6 testing stations in Arabic RTL mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        const FirebaseEnterpriseHubDialog(),
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      // Dialog Title
      expect(find.text('مركز خدمات فايربيز المؤسسي'), findsOneWidget);

      // Station 1: App Check
      expect(find.text('درع الحماية السحابي'), findsOneWidget);
      expect(find.text('فحص أمان الاتصال'), findsOneWidget);

      // Station 2: FCM
      expect(find.text('منظومة الإشعارات اللحظية'), findsOneWidget);
      expect(find.text('إرسال إشعار تجريبي'), findsOneWidget);

      // Station 3: Remote Config
      expect(find.text('التحكم السحابي الحي'), findsOneWidget);
      expect(find.text('تحديث الإعدادات من السحابة'), findsOneWidget);

      // Station 4: Performance Monitoring
      expect(find.text('مراقبة الأداء والسرعة'), findsOneWidget);
      expect(find.text('تشغيل فحص سرعة النظام'), findsOneWidget);

      // Station 5: Error Telemetry
      expect(find.text('تسجيل ورصد الأخطاء السحابي'), findsOneWidget);
      expect(find.text('محاكاة معالجة خطأ آمن'), findsOneWidget);

      // Station 6: Digital Invoicing
      expect(find.text('أتمتة الفواتير الرقمية والإيصالات'), findsOneWidget);
      expect(find.text('توليد سند إيجار رسمي'), findsOneWidget);
    });

    testWidgets('Renders all 6 testing stations in English LTR mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('en');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(
        const FirebaseEnterpriseHubDialog(),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Firebase Enterprise Services Hub'), findsOneWidget);
      expect(find.text('App Check Cloud Shield'), findsOneWidget);
      expect(find.text('Real-time Push Notifications'), findsOneWidget);
      expect(find.text('Live Remote Config'), findsOneWidget);
      expect(find.text('Performance Monitoring'), findsOneWidget);
      expect(find.text('Cloud Error Telemetry'), findsOneWidget);
      expect(find.text('Digital Invoices & Receipts Automation'), findsOneWidget);
    });

    testWidgets('Renders all 6 testing stations in Hindi Devanagari mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LocaleController.setLanguage('hi');
      addTearDown(() => LocaleController.setLanguage('ar'));

      await tester.pumpWidget(wrapWithApp(
        const FirebaseEnterpriseHubDialog(),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('फ़ायरबेस एंटरप्राइज सेवा केंद्र'), findsOneWidget);
      expect(find.text('ऐप चेक क्लाउड शील्ड'), findsOneWidget);
      expect(find.text('वास्तविक समय पुश सूचनाएं'), findsOneWidget);
      expect(find.text('लाइव रिमोट कॉन्फ़िगरेशन'), findsOneWidget);
      expect(find.text('प्रदर्शन और गति निगरानी'), findsOneWidget);
      expect(find.text('क्लाउड त्रुटि टेलीमेट्री'), findsOneWidget);
      expect(find.text('डिजिटल चालान और रसीद स्वचालन'), findsOneWidget);
    });
  });
}
