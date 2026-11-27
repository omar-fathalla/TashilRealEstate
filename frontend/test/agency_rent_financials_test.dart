import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/services/financial_kpi_service.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/portfolio/services/rent_schedule_builder.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import 'support/portfolio_fakes.dart';

final _now = DateTime(2026, 11, 26, 12);

PortfolioSnapshot _snapshot() {
  return PortfolioSnapshot(
    load: PortfolioLoad.ready,
    leases: [
      lease('l1', start: '2026-08-10', end: '2027-08-09'),
      lease('l2', status: 'terminated', start: '2026-01-01', end: '2026-06-30', rent: 5000),
      lease('l3', status: 'draft'),
      lease('l4', status: 'pending_tenant_approval'),
      lease('l5', country: 'EG', start: '2026-10-01', end: '2027-09-30', rent: 9000),
    ],
    transactions: [
      PortfolioTransaction(id: 'l1_2026-08', leaseId: 'l1', period: '2026-08', amount: 8000, status: 'paid', method: 'card', reference: 'ref-1', invoiceNumber: 'TASHIL-INV-l1_2026-08', paidAt: DateTime(2026, 8, 11)),
      const PortfolioTransaction(id: 'l1_2026-09', leaseId: 'l1', period: '2026-09', amount: 8000, status: 'pending'),
      PortfolioTransaction(id: 'l2_2026-03', leaseId: 'l2', period: '2026-03', amount: 5000, status: 'paid', paidAt: DateTime(2026, 3, 2)),
    ],
    invoices: const [
      PortfolioInvoice(invoiceNumber: 'TASHIL-INV-l1_2026-08', leaseId: 'l1', transactionId: 'l1_2026-08', period: '2026-08', amount: 8000, platformFee: 200, agencyFee: 640, ownerPayout: 7160),
    ],
  );
}

void main() {
  setUp(() => CountryController.setCountry('AE'));
  tearDown(() {
    CountryController.setCountry('EG');
    RentCollectionService().leaveServerMode(signedIn: false);
  });

  group('RentScheduleBuilder', () {
    final rows = RentScheduleBuilder.build(_snapshot(), now: _now);
    String status(String lease, String period) => rows.singleWhere((r) => r.id == 'inv_${lease}_$period').status;

    test('builds the months an active lease owes, from its real start date', () {
      final l1 = rows.where((r) => r.contractNumber == 'l1').map((r) => r.monthKey).toList()..sort();
      expect(l1, ['2026-08', '2026-09', '2026-10', '2026-11', '2026-12']);
    });

    test('a month is paid only when the server recorded a paid payment', () {
      expect(status('l1', '2026-08'), 'paid');
      expect(status('l1', '2026-09'), 'overdue');
      expect(status('l1', '2026-10'), 'overdue');
      expect(status('l1', '2026-11'), 'overdue');
      expect(status('l1', '2026-12'), 'due_soon');
    });

    test('a paid month carries the real payment and the real fee deductions', () {
      final paid = rows.singleWhere((r) => r.id == 'inv_l1_2026-08');
      expect(paid.invoiceNumber, 'TASHIL-INV-l1_2026-08');
      expect(paid.transactionReference, 'ref-1');
      expect(paid.paymentMethod, 'card');
      expect(paid.paidAt, DateTime(2026, 8, 11));
      expect(paid.netPayoutToOwner, closeTo(7160, 0.001));
    });

    test('no late penalty is invented', () {
      expect(rows.every((r) => r.latePenaltyAmount == 0), isTrue);
      expect(rows.every((r) => r.totalAmountDue == r.baseAmount), isTrue);
    });

    test('an ended lease keeps its paid months and owes nothing', () {
      final l2 = rows.where((r) => r.contractNumber == 'l2').toList();
      expect(l2.map((r) => r.monthKey), ['2026-03']);
      expect(l2.single.status, 'paid');
    });

    test('drafts and offers owe nothing', () {
      expect(rows.where((r) => r.contractNumber == 'l3' || r.contractNumber == 'l4'), isEmpty);
    });

    test('rows keep their lease country', () {
      expect(rows.where((r) => r.contractNumber == 'l5').every((r) => r.countryCode == 'EG'), isTrue);
      expect(rows.where((r) => r.contractNumber == 'l1').every((r) => r.countryCode == 'AE'), isTrue);
    });

    test('nothing is built without leases', () {
      expect(RentScheduleBuilder.build(const PortfolioSnapshot(load: PortfolioLoad.ready), now: _now), isEmpty);
    });
  });

  group('FinancialKpiService.summaryFromPortfolio', () {
    final summary = FinancialKpiService().summaryFromPortfolio(
      role: FinancialPortalRole.agency,
      countryCode: 'AE',
      snapshot: _snapshot(),
      now: _now,
    );

    test('totals come from the real rows of the chosen country', () {
      expect(summary.invoiceCount, 6);
      expect(summary.totalGrossInvoiced, 45000);
      expect(summary.totalOverdueArrears, 24000);
      expect(summary.statusDistribution.paidCount, 2);
      expect(summary.statusDistribution.pendingCount, 1);
      expect(summary.statusDistribution.overdueCount, 3);
      expect(summary.collectionEfficiencyRate, closeTo(13000 / 45000 * 100, 0.001));
    });

    test('net collected is what the server paid out to owners', () {
      expect(summary.totalCollectedNet, closeTo(12160, 0.001));
      expect(summary.netProfitMargin, closeTo(12160 / 13000 * 100, 0.001));
    });

    test('a yield is not invented', () {
      expect(summary.grossRentalYield, isNull);
    });

    test('the cash flow history is six real months with the deductions as expenses', () {
      expect(summary.cashFlowHistory, hasLength(6));
      final august = summary.cashFlowHistory.firstWhere((p) => p.localizedMonth['en'] == 'Aug');
      expect(august.grossIncome, 8000);
      expect(august.operationalExpenses, closeTo(840, 0.001));
      expect(august.netProfit, closeTo(7160, 0.001));
      expect(summary.cashFlowHistory.last.localizedMonth['en'], 'Nov');
    });

    test('arrears are bucketed by how late the rent really is', () {
      expect(summary.arrearsAging.map((b) => b.amount), [0, 8000, 16000]);
      expect(summary.arrearsAging.map((b) => b.invoiceCount), [0, 1, 2]);
      expect(summary.arrearsAging.every((b) => b.accumulatedPenalties == 0), isTrue);
    });

    test('the other country is separate', () {
      final eg = FinancialKpiService().summaryFromPortfolio(role: FinancialPortalRole.agency, countryCode: 'EG', snapshot: _snapshot(), now: _now);
      expect(eg.totalGrossInvoiced, greaterThan(0));
      expect(eg.totalGrossInvoiced, isNot(45000));
      expect(eg.statusDistribution.paidCount, 0);
    });

    test('no leases gives zeros, not sample figures', () {
      final empty = FinancialKpiService().summaryFromPortfolio(
        role: FinancialPortalRole.agency,
        countryCode: 'AE',
        snapshot: const PortfolioSnapshot(load: PortfolioLoad.ready),
        now: _now,
      );
      expect(empty.totalGrossInvoiced, 0);
      expect(empty.collectionEfficiencyRate, 0);
      expect(empty.invoiceCount, 0);
    });
  });

  group('RentCollectionService server mode', () {
    test('real rows replace the local ones and survive a property sync', () {
      final service = RentCollectionService();
      service.applyServerInvoices(RentScheduleBuilder.build(_snapshot(), now: _now));
      final ids = service.invoicesNotifier.value.map((i) => i.id).toSet();
      expect(service.serverMode, isTrue);
      expect(ids, contains('inv_l1_2026-08'));
      expect(ids.any((id) => id.startsWith('inv_eg_00') || id.startsWith('inv_ae_00')), isFalse);
      service.syncFromProperties();
      expect(service.invoicesNotifier.value.map((i) => i.id).toSet(), ids);
    });

    test('reminders and the trash stay on the rows through a refresh', () {
      final service = RentCollectionService();
      service.applyServerInvoices(RentScheduleBuilder.build(_snapshot(), now: _now));
      service.sendReminder('inv_l1_2026-09');
      service.softDeleteInvoice('inv_l1_2026-10');
      service.applyServerInvoices(RentScheduleBuilder.build(_snapshot(), now: _now));
      expect(service.getInvoiceById('inv_l1_2026-09')!.reminderCount, 1);
      expect(service.getInvoiceById('inv_l1_2026-10')!.isDeleted, isTrue);
      service.restoreInvoice('inv_l1_2026-10');
    });
  });

  group('screens', () {
    Future<PortfolioController> controller(WidgetTester tester, FakePortfolioBackend backend) async {
      final c = PortfolioController(
        data: PortfolioDataService(backend: backend),
        requests: RequestsService(backend: FakeRequestsBackendForPortfolio()),
        includeRequests: false,
      );
      addTearDown(c.dispose);
      await tester.runAsync(() async {
        await c.start();
        await Future<void>.delayed(Duration.zero);
      });
      return c;
    }

    void big(WidgetTester tester) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1600);
      addTearDown(tester.view.reset);
    }

    testWidgets('rent collection shows the real tenant and no sample rows', (tester) async {
      big(tester);
      final backend = FakePortfolioBackend()..leases = [lease('l1', start: '2020-01-01', end: '2099-12-31')];
      final c = await controller(tester, backend);
      await tester.pumpWidget(testApp(RentCollectionView(portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('Tenant l1'), findsWidgets);
      expect(find.textContaining('Khaled'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(RentCollectionService().serverMode, isFalse);
    });

    testWidgets('rent collection with no leases says so', (tester) async {
      big(tester);
      final c = await controller(tester, FakePortfolioBackend());
      await tester.pumpWidget(testApp(RentCollectionView(portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('No rent to collect yet'), findsOneWidget);
    });

    testWidgets('rent collection offers a retry when the read fails, not an empty list', (tester) async {
      big(tester);
      final backend = FakePortfolioBackend()..failStreams = true;
      final c = await controller(tester, backend);
      await tester.pumpWidget(testApp(RentCollectionView(portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your data'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('No rent to collect yet'), findsNothing);
    });

    testWidgets('an agency admin without an agency sees the no-agency message', (tester) async {
      big(tester);
      final c = await controller(tester, FakePortfolioBackend(agency: ''));
      await tester.pumpWidget(testApp(RentCollectionView(portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('Your account is not linked to an agency'), findsOneWidget);
    });

    testWidgets('financials with no leases show the empty state', (tester) async {
      big(tester);
      final c = await controller(tester, FakePortfolioBackend());
      await tester.pumpWidget(testApp(FinancialKpiDashboardView(role: FinancialPortalRole.agency, portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('No financial data yet'), findsOneWidget);
      expect(find.text('Net Collected Profits'), findsNothing);
    });

    testWidgets('financials show the real invoice count instead of an invented yield', (tester) async {
      big(tester);
      final backend = FakePortfolioBackend()..leases = [lease('l1', start: '2020-01-01', end: '2099-12-31')];
      final c = await controller(tester, backend);
      await tester.pumpWidget(testApp(FinancialKpiDashboardView(role: FinancialPortalRole.agency, portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('Net Collected Profits'), findsOneWidget);
      expect(find.textContaining('Total Invoices Count:'), findsWidgets);
      expect(find.textContaining('Gross Rental Yield'), findsNothing);
    });

    testWidgets('Arabic financials empty state is Arabic', (tester) async {
      big(tester);
      final c = await controller(tester, FakePortfolioBackend());
      await tester.pumpWidget(testApp(FinancialKpiDashboardView(role: FinancialPortalRole.agency, portfolio: c), locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد بيانات مالية بعد'), findsOneWidget);
    });
  });
}
