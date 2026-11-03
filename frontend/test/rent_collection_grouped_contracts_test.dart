import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/rent_collection/models/contract_invoice_group_model.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  setUp(() {
    CountryController.setCountry('EG');
    LocaleController.setLocale(const Locale('ar'));
    PropertyLifecycleService().resetToSampleData();
    RentCollectionService().resetToDefaults();
  });

  tearDown(() {
    RentCollectionService().resetToDefaults();
    PropertyLifecycleService().resetToSampleData();
  });

  Widget buildTestApp({Locale locale = const Locale('ar')}) {
    LocaleController.setLocale(locale);
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
      home: const Scaffold(
        body: RentCollectionView(),
      ),
    );
  }

  group('ContractInvoiceGroup Model Tests', () {
    test('Groups 12 installments under 1 contract with correct totals, progress and spotlight', () {
      final now = DateTime.now();
      final invoices = List.generate(12, (index) {
        final dueDate = DateTime(now.year, now.month + index, 11);
        final isPaid = index == 0;
        return RentInvoiceModel(
          id: 'inv_test_$index',
          invoiceNumber: 'INV-EG-${dueDate.year}${dueDate.month.toString().padLeft(2, '0')}-TEST',
          contractNumber: 'EG-2026-ALX-7250',
          propertyId: 'prop-7250',
          unitTitle: 'شقة سكنية - حي الجمرك',
          unitNumber: '4B',
          buildingName: 'عمارة الفيروز',
          district: 'حي الجمرك - بحري، الإسكندرية',
          propertyTypeCode: 'apartment',
          countryCode: 'EG',
          tenant: const TenantInfo(
            name: 'خالد أحمد حسن',
            phone: '+20 101 234 5678',
            email: 'khaled@gmail.com',
            idNumber: '29201011234567',
          ),
          owner: const OwnerPayoutInfo(
            name: 'محمد أحمد حسن فتح الله حسن',
            bankName: 'البنك الأهلي المصري (NBE)',
            iban: 'EG00000',
            accountNumber: '123456',
          ),
          baseAmount: 500,
          dueDate: dueDate,
          status: isPaid ? 'paid' : 'due_soon',
        );
      });

      final groups = ContractInvoiceGroup.groupInvoices(invoices);

      expect(groups.length, equals(1));
      final group = groups.first;

      expect(group.propertyId, equals('prop-7250'));
      expect(group.contractNumber, equals('EG-2026-ALX-7250'));
      expect(group.totalCount, equals(12));
      expect(group.paidCount, equals(1));
      expect(group.dueSoonCount, equals(11));
      expect(group.totalContractAmount, equals(6000.0));
      expect(group.totalCollectedAmount, equals(500.0));
      expect(group.totalRemainingAmount, equals(5500.0));
      expect(group.progressRatio, closeTo(1 / 12, 0.001));
      expect(group.hasCurrentMonthInvoice, isTrue);
      expect(group.currentMonthInvoice, isNotNull);
      expect(group.currentMonthInvoice!.status, equals('paid'));
    });
  });

  group('Rent Collection Grouped Contracts & Current Month Spotlight Widget Tests', () {
    testWidgets('Defaults to Grouped by Contract mode with expandable accordion and spotlight', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify the mode switcher displays "تجميع حسب العقود والوحدات" and "عرض جميع الفواتير"
      expect(find.text('تجميع حسب العقود والوحدات'), findsOneWidget);
      expect(find.text('عرض جميع الفواتير'), findsOneWidget);

      // Verify Contract Group Card elements
      expect(find.textContaining('العقود'), findsWidgets);
      expect(find.textContaining('أقساط العقد'), findsWidgets);

      // Verify Current Month Spotlight badge
      expect(find.textContaining('الشهر الحالي'), findsWidgets);

      // Because the first group is expanded by default, DataTable is visible
      expect(find.byType(DataTable), findsOneWidget);

      // Verify the spotlight star icon is rendered
      expect(find.byIcon(Symbols.stars_rounded), findsWidgets);
    });

    testWidgets('Tapping the group header collapses and expands the installments sub-table', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Initially expanded
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('طي الأقساط'), findsOneWidget);

      // Tap "طي الأقساط"
      await tester.tap(find.text('طي الأقساط'));
      await tester.pumpAndSettle();

      // Sub-table is collapsed
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('عرض الأقساط الـ 12'), findsWidgets);

      // Tap "عرض الأقساط الـ 12" to expand again
      await tester.tap(find.text('عرض الأقساط الـ 12').first);
      await tester.pumpAndSettle();

      // Sub-table is restored
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('طي الأقساط'), findsOneWidget);
    });

    testWidgets('Toggling between Grouped by Contract and Flat Invoices works seamlessly', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Initially in Grouped mode
      expect(find.text('تجميع حسب العقود والوحدات'), findsOneWidget);

      // Switch to Flat mode
      await tester.tap(find.text('عرض جميع الفواتير'));
      await tester.pumpAndSettle();

      // In flat mode, DataTable is rendered directly without the group header cards
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('طي الأقساط'), findsNothing);

      // Switch back to Grouped mode
      await tester.tap(find.text('تجميع حسب العقود والوحدات'));
      await tester.pumpAndSettle();

      // Group header is restored
      expect(find.text('طي الأقساط'), findsOneWidget);
    });

    testWidgets('Trilingual Parity for all grouping and current month spotlight keys', (tester) async {
      final locAr = AppLocalizations(const Locale('ar'));
      final locEn = AppLocalizations(const Locale('en'));
      final locHi = AppLocalizations(const Locale('hi'));

      const keys = [
        'groupByContract',
        'flatInvoices',
        'currentMonthSpot',
        'contractInstallmentsCount',
        'expandAll',
        'collapseAll',
        'contractPeriod',
        'annualContract12Months',
        'viewInstallments',
        'hideInstallments',
        'totalContractValue',
        'installmentsPaidRatio',
        'installmentNumber',
        'ofInstallments',
      ];

      for (final key in keys) {
        final valAr = locAr.tr(key);
        final valEn = locEn.tr(key);
        final valHi = locHi.tr(key);

        expect(valAr != key && valAr.isNotEmpty, isTrue, reason: 'Missing AR translation for: $key');
        expect(valEn != key && valEn.isNotEmpty, isTrue, reason: 'Missing EN translation for: $key');
        expect(valHi != key && valHi.isNotEmpty, isTrue, reason: 'Missing HI translation for: $key');
      }
    });
  });
}
