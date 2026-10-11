import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/monthly_payment_schedule_dialog.dart';

Widget wrapWithApp({required Widget child, Locale locale = const Locale('ar')}) {
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
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testInstallments = [
    MonthlyInstallment(
      monthKey: '2026-01',
      monthNumber: '01',
      monthNames: const {'ar': 'يناير 2026', 'en': 'January 2026', 'hi': 'जनवरी 2026'},
      amount: 35000,
      dueDate: DateTime(2026, 1, 5),
      status: InstallmentPaymentStatus.paidOnline,
      paymentMethod: 'apple_pay',
      receiptNumber: 'REC-2026-01',
      transactionRef: 'TXN-AP-101',
    ),
    MonthlyInstallment(
      monthKey: '2026-02',
      monthNumber: '02',
      monthNames: const {'ar': 'فبراير 2026', 'en': 'February 2026', 'hi': 'फ़रवरी 2026'},
      amount: 35000,
      dueDate: DateTime(2026, 2, 5),
      status: InstallmentPaymentStatus.paidOnline,
      paymentMethod: 'google_pay',
      receiptNumber: 'REC-2026-02',
      transactionRef: 'TXN-GP-102',
    ),
    MonthlyInstallment(
      monthKey: '2026-03',
      monthNumber: '03',
      monthNames: const {'ar': 'مارس 2026', 'en': 'March 2026', 'hi': 'मार्च 2026'},
      amount: 35000,
      dueDate: DateTime(2026, 3, 5),
      status: InstallmentPaymentStatus.overdue,
    ),
  ];

  final testVilla = ManagedPropertyModel(
    id: 'test-managed-villa-12',
    countryCode: 'EG',
    currencyCode: 'EGP',
    titles: const {
      'ar': 'فيلا مستقلة بحمام سباحة - بيفرلي هيلز',
      'en': 'Stand-alone Villa with Pool - Beverly Hills',
      'hi': 'पूल के साथ स्टैंड-अलोन विला',
    },
    descriptions: const {'ar': 'وصف فيلا', 'en': 'Villa desc', 'hi': 'विवरण'},
    locations: const {'ar': 'الشيخ زايد، الجيزة', 'en': 'Sheikh Zayed', 'hi': 'शेख जायद'},
    cityCode: 'sheikh_zayed',
    propertyTypeCode: 'villa',
    unitNumber: 'فيلا 12',
    buildingName: 'كمبوند بيفرلي هيلز',
    pricePerMonth: 35000,
    bedrooms: 5,
    bathrooms: 4,
    areaSqM: 450,
    image: 'https://example.com/villa.jpg',
    imageUrls: const ['https://example.com/villa.jpg'],
    isPublished: false,
    rentalStatus: PropertyRentalStatus.rented,
    tenantName: 'سارة خالد الدسوقي',
    tenantPhone: '+20 112 345 6789',
    installments: testInstallments,
  );

  setUp(() {
    LocaleController.setLanguage('ar');
    PropertyLifecycleService().propertiesNotifier.value = [testVilla];
  });

  group('MonthlyPaymentScheduleDialog M3 Redesign Tests', () {
    testWidgets('Renders M3 Connected Button Group, shaded close button, and generalized title', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MonthlyPaymentScheduleDialog.show(context, testVilla),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify generalized title without hardcoded "للشقة"
      expect(find.text('سجل وجدول الدفعات الشهرية'), findsOneWidget);
      expect(find.textContaining('للشقة'), findsNothing);

      // Verify M3 shaded close button is present
      expect(find.byType(TashilIconButton), findsWidgets);

      // Verify M3 Connected Button Group is present
      expect(find.byType(TashilConnectedButtonGroup<String>), findsOneWidget);
      expect(find.text('إنهاء العقد وإعادة النشر في السوق'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);

      // Verify zero language mixing in payment method badges (pure Arabic: أبل باي / جوجل باي)
      expect(find.text('مدفوع إلكترونياً (أبل باي)'), findsOneWidget);
      expect(find.text('مدفوع إلكترونياً (جوجل باي)'), findsOneWidget);
      // Ensure no raw English "Apple Pay" or "Google Pay" leaked in Arabic mode
      expect(find.textContaining('(Apple Pay)'), findsNothing);
      expect(find.textContaining('(Google Pay)'), findsNothing);
    });

    testWidgets('Clicking close segment closes the dialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MonthlyPaymentScheduleDialog.show(context, testVilla),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyPaymentScheduleDialog), findsOneWidget);

      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyPaymentScheduleDialog), findsNothing);
    });
  });
}
