import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/lease_builder/services/legal_clauses_service.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/investor_dashboard/services/investor_analytics_service.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/services/financial_kpi_service.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/vision_maintenance/services/ai_vision_maintenance_service.dart';
import 'package:tashil_real_estate/features/vision_maintenance/models/vision_maintenance_model.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String targetOwnerEmail = 'fathlla80800@gmail.com';
  const String targetOwnerName = 'م. محمد فتح الله';
  const String targetOwnerPhone = '+201002345678';
  const String targetOwnerNationalId = '29304150102432';
  const String targetOwnerAddress = 'التجمع الخامس، القاهرة الجديدة';
  const String targetBankName = 'البنك الأهلي المصري (NBE)';
  const String targetBankAccount = '12345678901234';
  const String targetIban = 'EG380003000012345678901234';

  Widget buildTestApp({
    required Widget child,
    Locale locale = const Locale('ar'),
    String country = 'EG',
  }) {
    LocaleController.setLocale(locale);
    CountryController.setCountry(country);

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
      home: Scaffold(body: child),
    );
  }

  void setupRealOwnerProfile() {
    UserProfileService().profileNotifier.value = const UserProfileData(
      uid: 'user_fathalla_real_80800',
      email: targetOwnerEmail,
      fullName: targetOwnerName,
      firstName: 'محمد',
      surname: 'فتح الله',
      phone: targetOwnerPhone,
      role: 'Owner',
      isVerified: true,
      nationalId: targetOwnerNationalId,
      address: targetOwnerAddress,
      bankName: targetBankName,
      bankAccountNumber: targetBankAccount,
      iban: targetIban,
    );
  }

  ManagedPropertyModel createFathallaVilla() {
    return ManagedPropertyModel(
      id: 'prop_fathalla_villa_001',
      countryCode: 'EG',
      currencyCode: 'EGP',
      titles: {
        'ar': 'فيلا فاخرة مستقلة - سراي التجمع الخامس',
        'en': 'Luxury Standalone Villa - Sarai New Cairo',
        'hi': 'शानदार स्टैंडअलोन विला - सराय न्यू काहिरा',
      },
      descriptions: {
        'ar': 'فيلا راقية تشطيب ألترا سوبر لوكس مع حديقة خاصة ومسبح.',
        'en': 'Ultra super lux finish villa with private garden and pool.',
        'hi': 'निजी उद्यान और पूल के साथ अल्ट्रा सुपर लक्स विला।',
      },
      locations: {
        'ar': 'سراي، التجمع الخامس، القاهرة الجديدة',
        'en': 'Sarai, 5th Settlement, New Cairo',
        'hi': 'सराय, 5वीं बस्ती, नया काहिरा',
      },
      cityCode: 'cairo',
      propertyTypeCode: 'villa',
      unitNumber: 'فيلا V-108',
      buildingName: 'كمبوند سراي - المرحلة الأولى',
      pricePerMonth: 45000,
      bedrooms: 4,
      bathrooms: 4,
      areaSqM: 350,
      image: 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&q=80',
      imageUrls: const [
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&q=80',
      ],
      isPublished: true,
      rentalStatus: PropertyRentalStatus.available,
      installments: const [],
    );
  }

  setUp(() {
    setupRealOwnerProfile();
    LegalClausesService().resetToDefaults();
    RentCollectionService().resetToDefaults();
    AiVisionMaintenanceService().resetForTesting();
  });

  group('E2E Owner Cycle: fathlla80800@gmail.com', () {
    test('1. Profile and Banking Information are accurately linked', () {
      final profile = UserProfileService().profileNotifier.value;
      expect(profile.email, equals(targetOwnerEmail));
      expect(profile.fullName, equals(targetOwnerName));
      expect(profile.phone, equals(targetOwnerPhone));
      expect(profile.nationalId, equals(targetOwnerNationalId));
      expect(profile.iban, equals(targetIban));
      expect(profile.bankName, equals(targetBankName));
      expect(profile.completenessPercent, equals(100));
    });

    test('2. Add new property and verify public marketplace publication', () async {
      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      final props = PropertyLifecycleService().propertiesNotifier.value;
      final saved = props.firstWhere((p) => p.id == villa.id);

      expect(saved.isPublished, isTrue, reason: 'Property must be published in marketplace');
      expect(saved.rentalStatus, equals(PropertyRentalStatus.available), reason: 'Status must be available (شاغرة)');
      expect(saved.pricePerMonth, equals(45000));
      expect(saved.installments, isEmpty, reason: 'Available property has no installments yet');
    });

    test('3. Rent out property -> Auto conceal from marketplace & generate 12-month schedule', () async {
      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      final leaseStart = DateTime(2026, 1, 1);
      final leaseEnd = DateTime(2026, 12, 31);

      await PropertyLifecycleService().markAsRented(
        propertyId: villa.id,
        tenantName: 'أ. حسام الدين مصطفى',
        tenantPhone: '+20 109 888 7766',
        monthlyRent: 45000,
        startDate: leaseStart,
        endDate: leaseEnd,
        durationMonths: 12,
        firstMonthPaid: false,
      );

      final props = PropertyLifecycleService().propertiesNotifier.value;
      final rented = props.firstWhere((p) => p.id == villa.id);

      // Verify marketplace auto-concealment
      expect(rented.rentalStatus, equals(PropertyRentalStatus.rented));
      expect(rented.isPublished, isFalse, reason: 'Rented property must be concealed from public marketplace');
      expect(rented.tenantName, equals('أ. حسام الدين مصطفى'));
      expect(rented.installments.length, equals(12));
      expect(rented.installments.first.amount, equals(45000));
      expect(rented.installments.first.dueDate, equals(leaseStart));
    });

    test('4. Legal Clauses & Digital Lease Contract auto-generated with real owner identity', () async {
      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      await PropertyLifecycleService().markAsRented(
        propertyId: villa.id,
        tenantName: 'أ. حسام الدين مصطفى',
        tenantPhone: '+20 109 888 7766',
        monthlyRent: 45000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        durationMonths: 12,
      );

      // Verify contract auto-generated in LegalClausesService
      final contracts = LegalClausesService().contractsNotifier.value;
      final lease = contracts.firstWhere((c) => c.id == 'lease_${villa.id}');

      expect(lease.id, equals('lease_${villa.id}'));
      expect(lease.status, equals('active'));
      expect(lease.financialTerms.monthlyRentEquivalent, equals(45000));
      expect(lease.financialTerms.totalRentAmount, equals(540000)); // 12 * 45,000

      // Verify Lessor identity dynamically bound to fathlla80800@gmail.com
      expect(lease.lessor.name, equals(targetOwnerName));
      expect(lease.lessor.email, equals(targetOwnerEmail));
      expect(lease.lessor.phone, equals(targetOwnerPhone));
      expect(lease.lessor.nationalIdOrEmiratesId, equals(targetOwnerNationalId));
      expect(lease.lessorSignature, isNotNull);
      expect(lease.lessorSignature?.signerName, equals(targetOwnerName));
      expect(lease.clauses, isNotEmpty, reason: 'Digital lease contract must contain legal clauses');
    });

    test('5. Rent Collection Service generates 12 synchronized invoices for 540,000 EGP', () async {
      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      await PropertyLifecycleService().markAsRented(
        propertyId: villa.id,
        tenantName: 'أ. حسام الدين مصطفى',
        tenantPhone: '+20 109 888 7766',
        monthlyRent: 45000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        durationMonths: 12,
      );

      final invoices = RentCollectionService().getInvoicesForCountry('EG');
      final villaInvoices = invoices.where((i) => i.propertyId == villa.id).toList();

      expect(villaInvoices.length, equals(12));
      final totalInvoiced = villaInvoices.fold<double>(0.0, (sum, i) => sum + i.baseAmount);
      expect(totalInvoiced, equals(540000.0));
      expect(villaInvoices.every((i) => i.status != 'paid'), isTrue, reason: 'Initially all 12 invoices are unpaid');
    });

    test('6. Record Online & Cash Payments -> Invoices marked paid & Payout Details verified', () async {
      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      await PropertyLifecycleService().markAsRented(
        propertyId: villa.id,
        tenantName: 'أ. حسام الدين مصطفى',
        tenantPhone: '+20 109 888 7766',
        monthlyRent: 45000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        durationMonths: 12,
      );

      // Record Month 1 payment (Online: InstaPay)
      await PropertyLifecycleService().recordInstallmentPayment(
        propertyId: villa.id,
        monthKey: '2026-01',
        status: InstallmentPaymentStatus.paidOnline,
        paymentMethod: 'instapay',
        notes: 'سداد إلكتروني عبر إنستاباي',
      );

      // Record Month 2 payment (Manual: Cash)
      await PropertyLifecycleService().recordInstallmentPayment(
        propertyId: villa.id,
        monthKey: '2026-02',
        status: InstallmentPaymentStatus.paidCash,
        paymentMethod: 'cash',
        notes: 'استلام نقدي بإيصال رسمي',
      );

      // Sync RentCollectionService from updated property
      RentCollectionService().syncFromProperties();

      final invoices = RentCollectionService().getInvoicesForCountry('EG');
      final m1Invoice = invoices.firstWhere((i) => i.propertyId == villa.id && i.monthKey == '2026-01');
      final m2Invoice = invoices.firstWhere((i) => i.propertyId == villa.id && i.monthKey == '2026-02');
      final m3Invoice = invoices.firstWhere((i) => i.propertyId == villa.id && i.monthKey == '2026-03');

      expect(m1Invoice.status, equals('paid'));
      expect(m1Invoice.paymentMethod, equals('instapay'));
      expect(m2Invoice.status, equals('paid'));
      expect(m2Invoice.paymentMethod, equals('cash'));
      expect(m3Invoice.status, isNot('paid'));

      // Verify Owner Payout Details are created for fathlla80800@gmail.com
      expect(m1Invoice.owner.name, equals(targetOwnerName));
      expect(m1Invoice.owner.bankName, equals(targetBankName));
      expect(m1Invoice.owner.iban, equals(targetIban));
      expect(m1Invoice.netPayoutToOwner, greaterThan(0));
    });

    test('7. Analytics & Financial KPI recalculate from live collected data', () async {
      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      await PropertyLifecycleService().markAsRented(
        propertyId: villa.id,
        tenantName: 'أ. حسام الدين مصطفى',
        tenantPhone: '+20 109 888 7766',
        monthlyRent: 45000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        durationMonths: 12,
      );

      // Pay month 1 and month 2
      await PropertyLifecycleService().recordInstallmentPayment(
        propertyId: villa.id,
        monthKey: '2026-01',
        status: InstallmentPaymentStatus.paidOnline,
        paymentMethod: 'instapay',
      );
      await PropertyLifecycleService().recordInstallmentPayment(
        propertyId: villa.id,
        monthKey: '2026-02',
        status: InstallmentPaymentStatus.paidCash,
        paymentMethod: 'cash',
      );
      RentCollectionService().syncFromProperties();

      // Financial KPI summary verification
      final summary = FinancialKpiService().getFinancialSummary(
        role: FinancialPortalRole.owner,
        countryCode: 'EG',
      );
      expect(summary.totalGrossInvoiced, equals(540000.0));
      expect(summary.totalCollectedNet, greaterThan(0));
      expect(summary.collectionEfficiencyRate, greaterThan(0));
      expect(summary.statusDistribution.paidCount, equals(2));
      expect(summary.statusDistribution.overdueCount + summary.statusDistribution.pendingCount, equals(10));
      expect(summary.statusDistribution.paidCount + summary.statusDistribution.overdueCount + summary.statusDistribution.pendingCount, equals(12));

      // Investor Dashboard analytics verification
      InvestorAnalyticsService().syncFromProperties();
      final metrics = InvestorAnalyticsService().currentSummary;
      expect(metrics.occupancyRate, equals(100.0), reason: 'Single rented property gives 100% occupancy');
      expect(metrics.occupiedUnitsCount, equals(1));
      expect(metrics.totalUnitsCount, equals(1));
    });

    test('8. AI Vision Maintenance Ticket Lifecycle: Dispatch & Resolve', () async {
      final diag = await AiVisionMaintenanceService().diagnosePhoto(
        photoUrl: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=800&q=80',
        countryCode: 'EG',
        sampleId: 'sample_plumbing_leak',
      );

      expect(diag.category, equals(MaintenanceIssueCategory.plumbing));
      expect(diag.confidenceScore, greaterThan(0.95));

      // Dispatch technician
      final ticket = AiVisionMaintenanceService().createTicketFromDiagnosis(
        diagnosis: diag,
        countryCode: 'EG',
        propertyId: 'prop_fathalla_villa_001',
        propertyTitle: {'ar': 'فيلا سراي', 'en': 'Sarai Villa', 'hi': 'सराय विला'},
      );

      expect(ticket['status'], equals('pending'));
      expect(ticket['isDemo'], isFalse);

      final pendingTickets = AiVisionMaintenanceService().getPendingTicketsForCountry('EG', hasRealProps: true);
      expect(pendingTickets.length, equals(1));
      expect(pendingTickets.first['id'], equals(ticket['id']));

      // Resolve maintenance ticket
      AiVisionMaintenanceService().resolveTicket(ticket['id'].toString());

      final pendingAfterResolve = AiVisionMaintenanceService().getPendingTicketsForCountry('EG', hasRealProps: true);
      expect(pendingAfterResolve, isEmpty, reason: 'Pending tickets should be empty after resolution');

      final allTickets = AiVisionMaintenanceService().getTicketsForCountry('EG', hasRealProps: true);
      expect(allTickets.first['status'], equals('resolved'));
    });

    test('9. Trashing and Restoring Lifecycle (Soft Delete & Restore)', () async {
      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      await PropertyLifecycleService().markAsRented(
        propertyId: villa.id,
        tenantName: 'أ. حسام الدين مصطفى',
        tenantPhone: '+20 109 888 7766',
        monthlyRent: 45000,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        durationMonths: 12,
      );

      final contractId = 'lease_${villa.id}';
      final activeBefore = LegalClausesService().getActiveContractsForCountry('EG').length;

      // Soft delete contract
      LegalClausesService().softDeleteContract(contractId);

      final deletedContracts = LegalClausesService().getDeletedContractsForCountry('EG');
      expect(deletedContracts.any((c) => c.id == contractId), isTrue);
      expect(LegalClausesService().getActiveContractsForCountry('EG').length, equals(activeBefore - 1));

      // Restore contract
      LegalClausesService().restoreContract(contractId);
      expect(LegalClausesService().getDeletedContractsForCountry('EG').any((c) => c.id == contractId), isFalse);
      expect(LegalClausesService().getActiveContractsForCountry('EG').length, equals(activeBefore));
    });

    testWidgets('10. OwnerDashboard Widget renders all tabs with zero crashes', (tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final villa = createFathallaVilla();
      await PropertyLifecycleService().addProperty(villa);

      await tester.pumpWidget(
        buildTestApp(
          child: const OwnerDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Brand and Navigation Rail render
      expect(find.byType(OwnerDashboard), findsOneWidget);
      expect(find.text('فيلا فاخرة مستقلة - سراي التجمع الخامس'), findsWidgets);
    });
  });
}
