import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_financials_view.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import 'support/portfolio_fakes.dart';

// TAQ-162: the owner portal and the SuperAdmin dashboard read real leases and payments, like the
// agency portal (TAQ-145).
void main() {
  setUp(() => CountryController.setCountry('AE'));
  tearDown(() {
    CountryController.setCountry('EG');
    RentCollectionService().leaveServerMode(signedIn: false);
  });

  group('scopes', () {
    test('an owner (no agency claim) reads by owner_id', () async {
      final data = PortfolioDataService(backend: FakePortfolioBackend(agency: '', uid: 'owner-1'));
      expect(await data.scopeFor(), const PortfolioScope.owner('owner-1'));
    });

    test('the platform scope is given to a SuperAdmin only', () async {
      final admin = FakePortfolioBackend(agency: '')..superAdmin = true;
      expect(await PortfolioDataService(backend: admin).scopeFor(platform: true), const PortfolioScope.platform());
      expect(const PortfolioScope.platform().isPlatform, isTrue);
      expect(const PortfolioScope.owner('x').isPlatform, isFalse);
      final owner = FakePortfolioBackend(agency: '');
      expect(await PortfolioDataService(backend: owner).scopeFor(platform: true), isNull, reason: 'never "all" for anyone else');
      final signedOut = FakePortfolioBackend(signedIn: false)..superAdmin = true;
      expect(await PortfolioDataService(backend: signedOut).scopeFor(platform: true), isNull);
    });

    test('a platform controller reads the platform scope and no requests', () async {
      final backend = FakePortfolioBackend(agency: '')..superAdmin = true;
      final requests = FakeRequestsBackendForPortfolio();
      final c = PortfolioController(data: PortfolioDataService(backend: backend), requests: RequestsService(backend: requests), platform: true);
      addTearDown(c.dispose);
      await c.start();
      await Future<void>.delayed(Duration.zero);
      expect(backend.scopes, isNotEmpty);
      expect(backend.scopes.every((s) => s.isPlatform), isTrue);
      expect(requests.lastScope, isNull);
      expect(c.snapshot.load, PortfolioLoad.ready);
    });

    test('a non-SuperAdmin platform controller shows nothing', () async {
      final backend = FakePortfolioBackend(agency: '');
      final c = PortfolioController(data: PortfolioDataService(backend: backend), requests: RequestsService(backend: FakeRequestsBackendForPortfolio()), platform: true);
      addTearDown(c.dispose);
      await c.start();
      expect(backend.scopes, isEmpty);
      expect(c.snapshot.load, PortfolioLoad.noAgency);
    });
  });

  group('screens', () {
    Future<PortfolioController> controller(WidgetTester tester, FakePortfolioBackend backend, {bool platform = false}) async {
      final c = PortfolioController(
        data: PortfolioDataService(backend: backend),
        requests: RequestsService(backend: FakeRequestsBackendForPortfolio()),
        agencyOnly: false,
        includeRequests: false,
        platform: platform,
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
      tester.view.physicalSize = const Size(1400, 1800);
      addTearDown(tester.view.reset);
    }

    FakePortfolioBackend ownerWithPaidMonth() => FakePortfolioBackend(agency: '', uid: 'o1')
      ..leases = [lease('l1', start: '2026-08-10', end: '2099-08-09', title: 'Nile View 7')]
      ..transactions = [
        PortfolioTransaction(id: 'l1_2026-08', leaseId: 'l1', period: '2026-08', amount: 8000, status: 'paid', reference: 'pay-ref-1', paidAt: DateTime(2026, 8, 11)),
      ];

    testWidgets('owner rent collection shows the real tenant and no sample rows', (tester) async {
      big(tester);
      final c = await controller(tester, ownerWithPaidMonth());
      await tester.pumpWidget(testApp(RentCollectionView(portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('Tenant l1'), findsWidgets);
      expect(find.textContaining('Khaled'), findsNothing);
    });

    testWidgets('owner financials list the real paid month as a payout, not the sample ledger', (tester) async {
      big(tester);
      final c = await controller(tester, ownerWithPaidMonth());
      await tester.pumpWidget(testApp(OwnerFinancialsView(portfolio: c)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transfers Ledger').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Nile View 7 (2026-08)'), findsWidgets);
      expect(find.textContaining('ENBD-AE-44109'), findsNothing);
      expect(find.textContaining('ADCB'), findsNothing);
    });

    testWidgets('owner financials with no leases show no sample payouts', (tester) async {
      big(tester);
      final c = await controller(tester, FakePortfolioBackend(agency: '', uid: 'o1'));
      await tester.pumpWidget(testApp(OwnerFinancialsView(portfolio: c)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transfers Ledger').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('ENBD-AE-44109'), findsNothing);
      expect(find.textContaining('Rent Deposit'), findsNothing);
    });

    testWidgets('owner financials offer a retry when the read fails', (tester) async {
      big(tester);
      final c = await controller(tester, FakePortfolioBackend(agency: '', uid: 'o1')..failStreams = true);
      await tester.pumpWidget(testApp(OwnerFinancialsView(portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your data'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('SuperAdmin financials compute from the platform records', (tester) async {
      big(tester);
      final backend = FakePortfolioBackend(agency: '')
        ..superAdmin = true
        ..leases = [lease('l1', start: '2020-01-01', end: '2099-12-31')];
      final c = await controller(tester, backend, platform: true);
      await tester.pumpWidget(testApp(FinancialKpiDashboardView(role: FinancialPortalRole.superAdmin, portfolio: c)));
      await tester.pumpAndSettle();
      expect(backend.scopes.every((s) => s.isPlatform), isTrue);
      expect(find.textContaining('Total Invoices Count:'), findsWidgets);
      expect(find.textContaining('Gross Rental Yield'), findsNothing);
    });

    testWidgets('SuperAdmin financials with no platform leases show the empty state', (tester) async {
      big(tester);
      final c = await controller(tester, FakePortfolioBackend(agency: '')..superAdmin = true, platform: true);
      await tester.pumpWidget(testApp(FinancialKpiDashboardView(role: FinancialPortalRole.superAdmin, portfolio: c)));
      await tester.pumpAndSettle();
      expect(find.text('No financial data yet'), findsOneWidget);
    });
  });
}
