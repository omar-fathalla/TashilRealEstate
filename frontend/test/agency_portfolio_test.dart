import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/agency_workspace/views/overview_view.dart';
import 'package:tashil_real_estate/features/agency_workspace/views/properties_view.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_stats.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import 'support/portfolio_fakes.dart';

final _now = DateTime(2026, 11, 26, 12);

PortfolioController _controller(FakePortfolioBackend backend, [FakeRequestsBackendForPortfolio? requests]) {
  return PortfolioController(
    data: PortfolioDataService(backend: backend),
    requests: RequestsService(backend: requests ?? FakeRequestsBackendForPortfolio()),
  );
}

Future<PortfolioController> _started(FakePortfolioBackend backend, [FakeRequestsBackendForPortfolio? requests, WidgetTester? tester]) async {
  final c = _controller(backend, requests);
  addTearDown(c.dispose);
  Future<void> run() async {
    await c.start();
    await Future<void>.delayed(Duration.zero);
  }

  if (tester != null) {
    await tester.runAsync(run);
  } else {
    await run();
  }
  return c;
}

void main() {
  setUp(() => CountryController.setCountry('AE'));
  tearDown(() => CountryController.setCountry('EG'));

  group('PortfolioController scope', () {
    test('reads only the agency-scoped records of the caller claim', () async {
      final backend = FakePortfolioBackend(agency: 'agency-7');
      final requests = FakeRequestsBackendForPortfolio();
      await _started(backend, requests);
      expect(backend.scopes, isNotEmpty);
      expect(backend.scopes.every((s) => s.field == 'agency_id' && s.value == 'agency-7'), isTrue);
      expect(requests.lastScope?.field, 'agency_id');
      expect(requests.lastScope?.value, 'agency-7');
    });

    test('an agency admin without an agency claim sees no agency (never every agency)', () async {
      final backend = FakePortfolioBackend(agency: '');
      final c = await _started(backend);
      expect(c.snapshot.load, PortfolioLoad.noAgency);
      expect(backend.scopes, isEmpty);
    });

    test('signed out reads nothing', () async {
      final backend = FakePortfolioBackend(signedIn: false);
      final c = await _started(backend);
      expect(c.snapshot.load, PortfolioLoad.signedOut);
      expect(backend.scopes, isEmpty);
    });

    test('a denied or failed read becomes the error state', () async {
      final backend = FakePortfolioBackend()..failStreams = true;
      final c = await _started(backend);
      expect(c.snapshot.load, PortfolioLoad.error);
    });

    test('an owner scope uses owner_id', () async {
      final backend = FakePortfolioBackend(agency: '', uid: 'owner-3');
      final c = PortfolioController(
        data: PortfolioDataService(backend: backend),
        requests: RequestsService(backend: FakeRequestsBackendForPortfolio()),
        agencyOnly: false,
      );
      addTearDown(c.dispose);
      await c.start();
      expect(backend.scopes.first.field, 'owner_id');
      expect(backend.scopes.first.value, 'owner-3');
    });
  });

  group('PortfolioStats', () {
    test('an empty portfolio is all zeros', () {
      final stats = PortfolioStats.compute(const PortfolioSnapshot(load: PortfolioLoad.ready), const [], countryCode: 'AE', now: _now);
      expect(stats.properties, 0);
      expect(stats.activeLeases, 0);
      expect(stats.openMaintenance, 0);
      expect(stats.collectedThisMonth, 0);
      expect(stats.occupancyPercent, isNull);
      expect(stats.collectionPercent, isNull);
      expect(stats.activity, isEmpty);
      expect(stats.isEmpty, isTrue);
    });

    test('counts real records for the selected country only', () {
      final snapshot = PortfolioSnapshot(
        load: PortfolioLoad.ready,
        leases: [
          lease('a'),
          lease('b', status: 'pending_tenant_approval'),
          lease('c', status: 'draft'),
          lease('eg', country: 'EG'),
        ],
        transactions: [
          const PortfolioTransaction(id: 'a_2026-11', leaseId: 'a', period: '2026-11', amount: 8000, status: 'paid', currencyCode: 'AED'),
          const PortfolioTransaction(id: 'old', leaseId: 'a', period: '2026-10', amount: 8000, status: 'paid', currencyCode: 'AED'),
          const PortfolioTransaction(id: 'eg', leaseId: 'eg', period: '2026-11', amount: 5000, status: 'paid', currencyCode: 'EGP'),
          const PortfolioTransaction(id: 'pend', leaseId: 'a', period: '2026-11', amount: 999, status: 'pending', currencyCode: 'AED'),
        ],
        maintenance: [
          const PortfolioMaintenance(id: 'm1', leaseId: 'a', status: 'pending'),
          const PortfolioMaintenance(id: 'm2', leaseId: 'a', status: 'escalated'),
          const PortfolioMaintenance(id: 'm3', leaseId: 'a', status: 'resolved'),
          const PortfolioMaintenance(id: 'm4', leaseId: 'eg', status: 'pending'),
        ],
      );
      final stats = PortfolioStats.compute(
        snapshot,
        [unit('p1', rented: true), unit('p2'), unit('p3', rented: true), unit('p4', country: 'EG', rented: true)],
        countryCode: 'AE',
        now: _now,
      );
      expect(stats.properties, 3);
      expect(stats.rented, 2);
      expect(stats.vacant, 1);
      expect(stats.occupancyPercent, 67);
      expect(stats.activeLeases, 1);
      expect(stats.pendingOffers, 1);
      expect(stats.draftLeases, 1);
      expect(stats.collectedThisMonth, 8000);
      expect(stats.expectedThisMonth, 8000);
      expect(stats.collectionPercent, 100);
      expect(stats.currencyCode, 'AED');
      expect(stats.openMaintenance, 2);
      expect(stats.escalatedMaintenance, 1);
    });

    test('the activity feed is newest first, real, and capped', () {
      final snapshot = PortfolioSnapshot(
        load: PortfolioLoad.ready,
        leases: [for (var i = 0; i < 8; i++) lease('l$i', changed: DateTime(2026, 11, 10 + i))],
        viewings: [
          ViewingRequestItem(id: 'v1', listingId: 'p1', requesterName: 'Sara', createdAt: DateTime(2026, 11, 25)),
          ViewingRequestItem(id: 'v2', listingId: 'p1', requesterName: 'Done', status: 'confirmed', createdAt: DateTime(2026, 11, 26)),
        ],
      );
      final stats = PortfolioStats.compute(snapshot, const [], countryCode: 'AE', now: _now);
      expect(stats.activity.length, 6);
      expect(stats.activity.first.kind, ActivityKind.viewing);
      expect(stats.activity.first.params['name'], 'Sara');
      final times = stats.activity.map((e) => e.time).toList();
      expect([...times]..sort((a, b) => b.compareTo(a)), times);
      expect(stats.newViewings, 1);
    });
  });

  group('OverviewView', () {
    Future<void> pumpOverview(
      WidgetTester tester,
      PortfolioController controller, {
      List<ManagedPropertyModel> properties = const [],
      void Function(int)? onNavigate,
      VoidCallback? onAdd,
      Locale locale = const Locale('en'),
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(
        OverviewView(
          controller: controller,
          properties: ValueNotifier(properties),
          onNavigate: onNavigate,
          onAddProperty: onAdd,
          clock: () => _now,
        ),
        locale: locale,
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('a new agency shows zeros and an empty state, never 120 or 85', (tester) async {
      final c = await _started(FakePortfolioBackend(), null, tester);
      await pumpOverview(tester, c);
      expect(find.text('120'), findsNothing);
      expect(find.text('85'), findsNothing);
      expect(find.text('450,000 ج.م'), findsNothing);
      expect(find.text('No activity yet'), findsOneWidget);
      expect(find.text('No units yet'), findsOneWidget);
      expect(find.text('No rent due'), findsOneWidget);
      expect(find.text('None urgent'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3));
    });

    testWidgets('shows the real numbers and feed from the agency records', (tester) async {
      final backend = FakePortfolioBackend()
        ..leases = [lease('a', title: 'Marina Tower 1204', changed: DateTime(2026, 11, 26, 11, 30))]
        ..transactions = [const PortfolioTransaction(id: 'a_2026-11', leaseId: 'a', period: '2026-11', amount: 8000, status: 'paid')]
        ..maintenance = [const PortfolioMaintenance(id: 'm1', leaseId: 'a', status: 'escalated', title: 'Leak')];
      final c = await _started(backend, null, tester);
      await pumpOverview(tester, c, properties: [unit('p1', rented: true), unit('p2')]);
      expect(find.text('8,000 AED'), findsOneWidget);
      expect(find.text('100% of rent due collected'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('50% occupied'), findsOneWidget);
      expect(find.text('1 escalated'), findsOneWidget);
      expect(find.text('Lease active - Marina Tower 1204'), findsOneWidget);
      expect(find.text('30 min ago'), findsOneWidget);
    });

    testWidgets('starter samples in the properties list are never counted', (tester) async {
      final c = await _started(FakePortfolioBackend(), null, tester);
      await pumpOverview(tester, c, properties: [unit('prop-ae-101', rented: true)]);
      expect(find.text('No units yet'), findsOneWidget);
    });

    testWidgets('a feed row and a KPI card open the tab that holds the record; Add property works', (tester) async {
      final backend = FakePortfolioBackend()..leases = [lease('a')];
      final c = await _started(backend, null, tester);
      final tabs = <int>[];
      var added = 0;
      await pumpOverview(tester, c, onNavigate: tabs.add, onAdd: () => added++);
      await tester.tap(find.text('Lease active - Marina Tower 1204'));
      await tester.tap(find.text('Active Leases'));
      await tester.tap(find.text('Add Property'));
      await tester.tap(find.text('View All'));
      expect(tabs, [AgencyTab.leases, AgencyTab.leases, AgencyTab.requests]);
      expect(added, 1);
    });

    testWidgets('a failed read shows a retry that reloads', (tester) async {
      final backend = FakePortfolioBackend()..failStreams = true;
      final c = await _started(backend, null, tester);
      await pumpOverview(tester, c);
      expect(find.text('Could not load your data'), findsOneWidget);
      backend.failStreams = false;
      await tester.tap(find.text('Try again'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your data'), findsNothing);
      expect(find.text('No activity yet'), findsOneWidget);
    });

    testWidgets('an admin with no agency sees why instead of numbers', (tester) async {
      final c = await _started(FakePortfolioBackend(agency: ''), null, tester);
      await pumpOverview(tester, c);
      expect(find.text('Your account is not linked to an agency'), findsOneWidget);
    });

    for (final entry in {
      const Locale('ar'): 'لا أنشطة بعد',
      const Locale('hi'): 'अभी कोई गतिविधि नहीं',
    }.entries) {
      testWidgets('empty state is translated (${entry.key.languageCode})', (tester) async {
        final c = await _started(FakePortfolioBackend(), null, tester);
        await pumpOverview(tester, c, locale: entry.key);
        expect(find.text(entry.value), findsOneWidget);
      });
    }
  });

  group('PropertiesView', () {
    Future<void> pumpProps(
      WidgetTester tester,
      List<ManagedPropertyModel> items, {
      VoidCallback? onAdd,
      void Function(ManagedPropertyModel)? onOpen,
      bool hydrating = false,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(PropertiesView(
        properties: ValueNotifier(items),
        hydrating: ValueNotifier(hydrating),
        onAdd: onAdd,
        onOpen: onOpen,
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('no properties shows an empty state with a working Add property action', (tester) async {
      var added = 0;
      await pumpProps(tester, const [], onAdd: () => added++);
      expect(find.text('No properties yet'), findsOneWidget);
      expect(find.text('Dubai Marina Luxury Tower'), findsNothing);
      await tester.tap(find.text('Add Property'));
      expect(added, 1);
    });

    testWidgets('lists the real units with their status and opens one on tap', (tester) async {
      ManagedPropertyModel? opened;
      await pumpProps(tester, [unit('p1', rented: true, title: 'Marina Tower 1204'), unit('p2', title: 'Palm Villa 7')], onOpen: (p) => opened = p);
      expect(find.text('Marina Tower 1204'), findsOneWidget);
      expect(find.text('Palm Villa 7'), findsOneWidget);
      expect(find.text('Rented'), findsOneWidget);
      expect(find.text('Vacant'), findsOneWidget);
      await tester.tap(find.text('Palm Villa 7'));
      expect(opened?.id, 'p2');
    });

    testWidgets('starter samples and the other country are not listed', (tester) async {
      await pumpProps(tester, [unit('prop-ae-101', title: 'Sample'), unit('p9', country: 'EG', title: 'Cairo flat'), unit('p1', title: 'Real one')]);
      expect(find.text('Sample'), findsNothing);
      expect(find.text('Cairo flat'), findsNothing);
      expect(find.text('Real one'), findsOneWidget);
    });
  });
}
