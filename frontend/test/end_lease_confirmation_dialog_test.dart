import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/end_lease_confirmation_dialog.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  setUp(() {
    LocaleController.setLocale(const Locale('ar'));
  });

  Widget createTestWidget({
    required Widget child,
    Locale locale = const Locale('ar'),
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
      ),
      home: Scaffold(body: child),
    );
  }

  ManagedPropertyModel createMockRentedProperty() {
    return ManagedPropertyModel(
      id: 'test-rented-prop-1',
      countryCode: 'EG',
      currencyCode: 'EGP',
      titles: {
        'ar': 'شقة فاخرة 90 م² في بحري',
        'en': 'Luxury 90m² Apartment in Bahary',
        'hi': 'बहरी में लक्जरी 90 वर्ग मीटर का अपार्टमेंट',
      },
      descriptions: {
        'ar': 'شقة مميزة بتشطيب سوبر لوكس',
        'en': 'Prime apartment with super lux finishing',
        'hi': 'सुपर लक्स फिनिशिंग वाला प्रमुख अपार्टमेंट',
      },
      locations: {
        'ar': 'بحري، الإسكندرية',
        'en': 'Bahary, Alexandria',
        'hi': 'बहरी, अलेक्जेंड्रिया',
      },
      cityCode: 'alexandria',
      propertyTypeCode: 'apartment',
      unitNumber: 'شقة 402',
      buildingName: 'برج القلعة',
      pricePerMonth: 500,
      bedrooms: 2,
      bathrooms: 1,
      areaSqM: 90,
      image: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
      imageUrls: const [],
      isPublished: false,
      rentalStatus: PropertyRentalStatus.rented,
      tenantName: 'عمر أحمد حسن',
      tenantPhone: '+20 150 889 9965',
      leaseStartDate: DateTime(2026, 10, 1),
      leaseEndDate: DateTime(2027, 9, 30),
      installments: [
        MonthlyInstallment(
          monthNumber: '01',
          monthKey: '2026-10',
          dueDate: DateTime(2026, 10, 10),
          monthNames: {'ar': 'أكتوبر 2026', 'en': 'October 2026', 'hi': 'अक्टूबर 2026'},
          amount: 500,
          status: InstallmentPaymentStatus.paidCash,
          paidAt: DateTime(2026, 10, 10),
          paymentMethod: 'cash',
          receiptNumber: 'REC-2026-1001',
          transactionRef: 'TXN-CASH-1001',
        ),
        MonthlyInstallment(
          monthNumber: '02',
          monthKey: '2026-11',
          dueDate: DateTime(2026, 11, 10),
          monthNames: {'ar': 'نوفمبر 2026', 'en': 'November 2026', 'hi': 'नवंबर 2026'},
          amount: 500,
          status: InstallmentPaymentStatus.upcoming,
        ),
      ],
      archivedInstallments: const [],
    );
  }

  testWidgets('EndLeaseConfirmationDialog renders all 4 consequence points and unit info in Arabic', (tester) async {
    final mockProp = createMockRentedProperty();

    await tester.pumpWidget(createTestWidget(
      child: EndLeaseConfirmationDialog(property: mockProp),
      locale: const Locale('ar'),
    ));
    await tester.pumpAndSettle();

    // Verify title and property info
    expect(find.text('تأكيد إنهاء العقد وإعادة طرح الوحدة'), findsOneWidget);
    expect(find.text('شقة فاخرة 90 م² في بحري'), findsOneWidget);
    expect(find.textContaining('عمر أحمد حسن'), findsOneWidget);

    // Verify all 4 consequence items are present
    expect(find.text('حفظ وأرشفة السجل المالي بالكامل (لن يُحذف شيء)'), findsOneWidget);
    expect(find.text('إغلاق الأقساط المستقبلية المتبقية'), findsOneWidget);
    expect(find.text('إخلاء طرف المستأجر الحالي'), findsOneWidget);
    expect(find.text('إعادة إتاحة الوحدة في السوق فوراً'), findsOneWidget);

    // Verify move-out & handover clearance box
    expect(find.text('ملاحظة تسليم الوحدة ومخالصة التأمين'), findsOneWidget);

    // Verify action buttons
    expect(find.text('إلغاء والتراجع'), findsOneWidget);
    expect(find.text('تأكيد الإنهاء والأرشفة'), findsOneWidget);
  });

  testWidgets('Toggling switch changes republish mode between immediate and draft', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockProp = createMockRentedProperty();

    await tester.pumpWidget(createTestWidget(
      child: EndLeaseConfirmationDialog(property: mockProp),
      locale: const Locale('ar'),
    ));
    await tester.pumpAndSettle();

    // Initially true: immediate republish
    expect(find.text('إعادة نشر الوحدة فوراً في السوق العام'), findsOneWidget);

    // Tap switch to toggle to private draft
    final switchFinder = find.byType(TashilSwitch);
    expect(switchFinder, findsOneWidget);
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Mode switches to private draft
    expect(find.text('حفظ كمسودة خاصة (للصيانة والتجهيز قبل العرض)'), findsOneWidget);
  });

  testWidgets('Confirming termination archives paid installment and preserves financial ledger', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockProp = createMockRentedProperty();
    PropertyLifecycleService().propertiesNotifier.value = [mockProp];

    await tester.pumpWidget(createTestWidget(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => EndLeaseConfirmationDialog.show(context, property: mockProp),
          child: const Text('Open'),
        ),
      ),
      locale: const Locale('ar'),
    ));
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap confirm termination button
    await tester.tap(find.text('تأكيد الإنهاء والأرشفة'));
    await tester.pumpAndSettle();

    // Verify property state in service
    final updatedProp = PropertyLifecycleService().propertiesNotifier.value.firstWhere((p) => p.id == mockProp.id);
    expect(updatedProp.rentalStatus, PropertyRentalStatus.available);
    expect(updatedProp.isPublished, isTrue);
    expect(updatedProp.tenantName, isNull);
    expect(updatedProp.installments, isEmpty);

    // ZERO DATA LOSS: 1 paid installment preserved in archivedInstallments!
    expect(updatedProp.archivedInstallments.length, 1);
    expect(updatedProp.archivedInstallments.first.monthKey, '2026-10');
    expect(updatedProp.archivedInstallments.first.amount, 500);
    expect(updatedProp.archivedInstallments.first.isPaid, isTrue);
    expect(updatedProp.totalCollectedRevenue, 500);
    expect(updatedProp.paidMonthsCount, 1);
  });

  testWidgets('EndLeaseConfirmationDialog renders cleanly in English and Hindi', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      LocaleController.setLocale(const Locale('ar'));
    });

    final mockProp = createMockRentedProperty();

    // Test English
    LocaleController.setLocale(const Locale('en'));
    await tester.pumpWidget(createTestWidget(
      child: EndLeaseConfirmationDialog(property: mockProp),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Lease Termination & Re-list Unit'), findsOneWidget);
    expect(find.text('Full Financial Ledger Preserved (Zero Data Loss)'), findsOneWidget);
    expect(find.text('Remaining Future Installments Closed'), findsOneWidget);
    expect(find.text('Confirm Termination & Archive'), findsOneWidget);

    // Test Hindi
    LocaleController.setLocale(const Locale('hi'));
    await tester.pumpWidget(createTestWidget(
      child: EndLeaseConfirmationDialog(property: mockProp),
      locale: const Locale('hi'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('पट्टा समाप्ति और इकाई को पुनः सूचीबद्ध करने की पुष्टि करें'), findsOneWidget);
    expect(find.text('पूर्ण वित्तीय बहीखाता संरक्षित (शून्य डेटा हानि)'), findsOneWidget);
    expect(find.text('समाप्ति और संग्रह की पुष्टि करें'), findsOneWidget);
  });
}
