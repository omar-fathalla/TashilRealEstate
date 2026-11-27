import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_staff_scope.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';
import 'package:tashil_real_estate/features/lease_builder/views/real_leases_view.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/create_lease_dialog.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import 'support/portfolio_fakes.dart';

Future<PortfolioController> _controller(WidgetTester tester, FakePortfolioBackend backend) async {
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

void _big(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 1400);
  addTearDown(tester.view.reset);
}

FirebaseFunctionsException _refusal(String reason) =>
    FirebaseFunctionsException(code: 'failed-precondition', message: 'server text', details: {'reason': reason});

void main() {
  setUp(() => CountryController.setCountry('AE'));
  tearDown(() => CountryController.setCountry('EG'));

  group('PortfolioDataService.createLease', () {
    test('sends the lease to the createLease function and returns the server id', () async {
      final backend = FakePortfolioBackend();
      final id = await PortfolioDataService(backend: backend).createLease(
        ownerId: 'u1',
        propertyId: 'p1',
        tenantId: 't1',
        startDate: '2026-12-01',
        endDate: '2027-11-30',
        monthlyRent: 8000,
        sendOffer: true,
      );
      expect(id, 'lease_new');
      expect(backend.created.single, {
        'ownerId': 'u1',
        'propertyId': 'p1',
        'tenantId': 't1',
        'startDate': '2026-12-01',
        'endDate': '2027-11-30',
        'monthlyRent': 8000.0,
        'sendOffer': true,
      });
    });

    test('a refusal is thrown, never swallowed into a fake success', () async {
      final backend = FakePortfolioBackend()..createFailure = _refusal('property_already_leased');
      await expectLater(
        PortfolioDataService(backend: backend).createLease(
          ownerId: 'u1',
          propertyId: 'p1',
          tenantId: 't1',
          startDate: '2026-12-01',
          endDate: '2027-11-30',
          monthlyRent: 1,
          sendOffer: false,
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
      expect(backend.created, isEmpty);
    });

    test('maps the server reasons to translated messages', () {
      expect(leaseCreateErrorKey('property_already_leased'), 'ldPropertyAlreadyLeased');
      expect(leaseCreateErrorKey('tenant_not_found'), 'ldTenantNotFound');
      expect(leaseCreateErrorKey('property_not_managed'), 'ldPropertyNotManaged');
      expect(leaseCreateErrorKey('something_else'), 'ldCreateFailed');
    });
  });

  group('RealLeasesView', () {
    Future<FakePortfolioBackend> pump(
      WidgetTester tester, {
      List<dynamic> leases = const [],
      Locale locale = const Locale('en'),
      bool fail = false,
      bool agent = false,
    }) async {
      _big(tester);
      final backend = FakePortfolioBackend()
        ..leases = [for (final l in leases) l]
        ..failStreams = fail;
      final c = await _controller(tester, backend);
      final view = RealLeasesView(controller: c, service: PortfolioDataService(backend: backend));
      await tester.pumpWidget(testApp(agent ? AgencyStaffScope(isAgent: true, child: view) : view, locale: locale));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('reads the agency leases: no sample contracts, a real empty state', (tester) async {
      final backend = await pump(tester);
      expect(backend.scopes.every((s) => s.field == 'agency_id' && s.value == 'agency-1'), isTrue);
      expect(find.text('No leases'), findsOneWidget);
      expect(find.textContaining('LC-'), findsNothing);
    });

    testWidgets('shows real leases with their server status and rent', (tester) async {
      await pump(tester, leases: [
        lease('a', title: 'Marina Tower 1204'),
        lease('b', status: 'pending_tenant_approval', title: 'Palm Villa 7'),
        lease('c', status: 'draft', title: 'Draft Flat'),
        lease('eg', country: 'EG', title: 'Cairo Flat'),
      ]);
      expect(find.text('Marina Tower 1204'), findsOneWidget);
      expect(find.text('Palm Villa 7'), findsOneWidget);
      expect(find.text('Draft Flat'), findsOneWidget);
      expect(find.text('Cairo Flat'), findsNothing);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Awaiting tenant'), findsWidgets);
      expect(find.text('8,000 AED'), findsWidgets);
    });

    testWidgets('TAQ-196: an AgencyAgent sees the leases and details but none of the AgencyAdmin actions', (tester) async {
      await pump(tester, agent: true, leases: [
        lease('a', title: 'Marina Tower 1204'),
        lease('b', status: 'pending_tenant_approval', title: 'Palm Villa 7'),
        lease('c', status: 'draft', title: 'Draft Flat'),
      ]);
      expect(find.text('Marina Tower 1204'), findsOneWidget);
      expect(find.text('Palm Villa 7'), findsOneWidget);
      expect(find.text('Draft Flat'), findsOneWidget);
      expect(find.text('Details'), findsNWidgets(3));
      for (final label in const [
        'Create Lease',
        'Record a cash or bank transfer rent payment',
        'Delete Contract',
        'Send offer to tenant',
        'Withdraw offer',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    testWidgets('TAQ-196: an agent with no leases gets the empty state without a create action', (tester) async {
      await pump(tester, agent: true);
      expect(find.text('No leases'), findsOneWidget);
      expect(find.text('Create Lease'), findsNothing);
    });

    testWidgets('the AgencyAdmin still sees every action', (tester) async {
      await pump(tester, leases: [lease('b', status: 'pending_tenant_approval'), lease('c', status: 'draft')]);
      expect(find.text('Create Lease'), findsOneWidget);
      expect(find.text('Record a cash or bank transfer rent payment'), findsOneWidget);
      expect(find.text('Delete Contract'), findsOneWidget);
      expect(find.text('Send offer to tenant'), findsOneWidget);
      expect(find.text('Withdraw offer'), findsOneWidget);
    });

    testWidgets('filters by status', (tester) async {
      await pump(tester, leases: [lease('a', title: 'Marina Tower 1204'), lease('c', status: 'draft', title: 'Draft Flat')]);
      await tester.tap(find.textContaining('Drafts'));
      await tester.pumpAndSettle();
      expect(find.text('Draft Flat'), findsOneWidget);
      expect(find.text('Marina Tower 1204'), findsNothing);
    });

    testWidgets('a draft can be offered; the offer goes through the server status change', (tester) async {
      final backend = await pump(tester, leases: [lease('c', status: 'draft')]);
      await tester.tap(find.text('Send offer to tenant'));
      await tester.pumpAndSettle();
      expect(backend.statusChanges.single.key, 'c');
      expect(backend.statusChanges.single.value, 'pending_tenant_approval');
      expect(find.text('The offer was sent to the tenant.'), findsOneWidget);
    });

    testWidgets('an offer can be withdrawn back to a draft', (tester) async {
      final backend = await pump(tester, leases: [lease('b', status: 'pending_tenant_approval')]);
      await tester.tap(find.text('Withdraw offer'));
      await tester.pumpAndSettle();
      expect(backend.statusChanges.single.key, 'b');
      expect(backend.statusChanges.single.value, 'draft');
    });

    testWidgets('only drafts offer delete, and it asks first', (tester) async {
      final backend = await pump(tester, leases: [lease('c', status: 'draft'), lease('a')]);
      expect(find.text('Delete Contract'), findsOneWidget);
      await tester.tap(find.text('Delete Contract'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this draft lease?'), findsOneWidget);
      expect(backend.deleted, isEmpty);
      await tester.tap(find.text('Delete Contract').last);
      await tester.pumpAndSettle();
      expect(backend.deleted, ['c']);
    });

    testWidgets('a failed action shows an error and claims no success', (tester) async {
      final backend = await pump(tester, leases: [lease('c', status: 'draft')]);
      backend.statusFailure = StateError('denied');
      await tester.tap(find.text('Send offer to tenant'));
      await tester.pumpAndSettle();
      expect(find.text('The action failed. Nothing changed. Please try again.'), findsOneWidget);
      expect(find.text('The offer was sent to the tenant.'), findsNothing);
    });

    testWidgets('a failed read shows retry, not an empty list', (tester) async {
      await pump(tester, fail: true);
      expect(find.text('Could not load your data'), findsOneWidget);
    });

    testWidgets('details open the real lease', (tester) async {
      await pump(tester, leases: [lease('a')]);
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Lease ID'), findsOneWidget);
      expect(find.text('a'), findsWidgets);
    });

    testWidgets('translates to Arabic', (tester) async {
      await pump(tester, locale: const Locale('ar'));
      expect(find.text('لا توجد عقود'), findsOneWidget);
    });
  });

  group('LeasesManagementView mode', () {
    testWidgets('signed in shows the real list instead of the local contracts', (tester) async {
      _big(tester);
      final backend = FakePortfolioBackend()..leases = [lease('a', title: 'Marina Tower 1204')];
      final c = await _controller(tester, backend);
      await tester.pumpWidget(testApp(LeasesManagementView(controller: c, service: PortfolioDataService(backend: backend))));
      await tester.pumpAndSettle();
      expect(find.byType(RealLeasesView), findsOneWidget);
      expect(find.text('Marina Tower 1204'), findsOneWidget);
    });

    testWidgets('signed out keeps the local sample contracts view', (tester) async {
      _big(tester);
      final backend = FakePortfolioBackend(signedIn: false);
      await tester.pumpWidget(testApp(LeasesManagementView(service: PortfolioDataService(backend: backend))));
      await tester.pumpAndSettle();
      expect(find.byType(RealLeasesView), findsNothing);
    });
  });

  group('CreateLeaseDialog', () {
    const applicant = RentalApplicationItem(id: 'app1', listingId: 'p1', applicantId: 'tenant-9', applicantName: 'Sara Ali', status: 'approved');
    const pending = RentalApplicationItem(id: 'app2', listingId: 'p1', applicantId: 'tenant-8', applicantName: 'Pending Person');
    const other = RentalApplicationItem(id: 'app3', listingId: 'p2', applicantId: 'tenant-7', applicantName: 'Other Listing', status: 'approved');

    Future<FakePortfolioBackend> open(
      WidgetTester tester, {
      List<RentalApplicationItem> applications = const [applicant, pending, other],
      Locale locale = const Locale('en'),
      Object? failWith,
      void Function(String?)? onResult,
    }) async {
      _big(tester);
      final backend = FakePortfolioBackend()..createFailure = failWith;
      final requests = FakeRequestsBackendForPortfolio()..applications = applications;
      await tester.pumpWidget(testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final id = await showDialog<String>(
                context: context,
                builder: (_) => CreateLeaseDialog(
                  properties: [unit('p1', title: 'Marina Tower 1204'), unit('p2', title: 'Palm Villa 7')],
                  service: PortfolioDataService(backend: backend),
                  requests: RequestsService(backend: requests),
                  now: () => DateTime(2026, 11, 26),
                ),
              );
              onResult?.call(id);
            },
            child: const Text('open'),
          ),
        ),
        locale: locale,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return backend;
    }

    Future<void> chooseProperty(WidgetTester tester, String title) async {
      await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(title).last);
      await tester.pumpAndSettle();
    }

    Future<void> chooseTenant(WidgetTester tester, String name) async {
      await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    testWidgets('offers only the approved applicants of the chosen property', (tester) async {
      await open(tester);
      await chooseProperty(tester, 'Marina Tower 1204');
      await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Sara Ali'), findsWidgets);
      expect(find.text('Pending Person'), findsNothing);
      expect(find.text('Other Listing'), findsNothing);
    });

    testWidgets('says so when nobody is approved for the property', (tester) async {
      await open(tester, applications: const [pending]);
      await chooseProperty(tester, 'Marina Tower 1204');
      expect(find.text('No approved applicant for this property yet. Approve a rental application in Requests first.'), findsOneWidget);
    });

    testWidgets('sending the offer creates the lease on the server and closes with its id', (tester) async {
      String? result;
      final backend = await open(tester, onResult: (id) => result = id);
      await chooseProperty(tester, 'Marina Tower 1204');
      await chooseTenant(tester, 'Sara Ali');
      await tester.tap(find.text('Send offer to tenant'));
      await tester.pumpAndSettle();
      expect(backend.created.single['tenantId'], 'tenant-9');
      expect(backend.created.single['propertyId'], 'p1');
      expect(backend.created.single['ownerId'], 'u1');
      expect(backend.created.single['sendOffer'], true);
      expect(backend.created.single['monthlyRent'], 12000.0);
      expect(backend.created.single['startDate'], '2026-11-26');
      expect(backend.created.single['endDate'], '2027-11-26');
      expect(result, 'lease_new');
      expect(find.byType(CreateLeaseDialog), findsNothing);
    });

    testWidgets('save as draft does not send the offer', (tester) async {
      final backend = await open(tester);
      await chooseProperty(tester, 'Marina Tower 1204');
      await chooseTenant(tester, 'Sara Ali');
      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();
      expect(backend.created.single['sendOffer'], false);
    });

    Future<void> fillOptional(WidgetTester tester, {String fee = '', String grace = '', String bank = '', String iban = ''}) async {
      final tile = find.byKey(const ValueKey('lease_optional_terms'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      for (final e in {'lease_late_fee': fee, 'lease_grace_days': grace, 'lease_payout_bank': bank, 'lease_payout_iban': iban}.entries) {
        if (e.value.isEmpty) continue;
        final field = find.byKey(ValueKey(e.key));
        await tester.ensureVisible(field);
        await tester.enterText(field, e.value);
      }
      await tester.pumpAndSettle();
    }

    Future<void> sendOffer(WidgetTester tester) async {
      final button = find.text('Send offer to tenant');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('TAQ-164: without optional terms nothing extra is sent, so the server keeps the 0 fee', (tester) async {
      final backend = await open(tester);
      await chooseProperty(tester, 'Marina Tower 1204');
      await chooseTenant(tester, 'Sara Ali');
      await sendOffer(tester);
      final sent = backend.created.single;
      expect(sent.containsKey('lateFeeAmount'), isFalse);
      expect(sent.containsKey('lateFeeGraceDays'), isFalse);
      expect(sent.containsKey('payoutIban'), isFalse);
    });

    testWidgets('TAQ-164: the late fee, grace days and payout bank go to the server, the IBAN normalised', (tester) async {
      final backend = await open(tester);
      await chooseProperty(tester, 'Marina Tower 1204');
      await chooseTenant(tester, 'Sara Ali');
      await fillOptional(tester, fee: '250', grace: '3', bank: 'FAB', iban: 'ae07 0331 2345 6789 0123 456');
      await sendOffer(tester);
      final sent = backend.created.single;
      expect(sent['lateFeeAmount'], 250.0);
      expect(sent['lateFeeGraceDays'], 3);
      expect(sent['payoutBankName'], 'FAB');
      expect(sent['payoutIban'], 'AE070331234567890123456');
    });

    testWidgets('TAQ-164: a bad IBAN or grace period is refused before any call', (tester) async {
      final backend = await open(tester);
      await chooseProperty(tester, 'Marina Tower 1204');
      await chooseTenant(tester, 'Sara Ali');
      await fillOptional(tester, iban: '12345');
      await sendOffer(tester);
      expect(backend.created, isEmpty);
      expect(find.text('That IBAN is not valid.'), findsOneWidget);
      final iban = find.byKey(const ValueKey('lease_payout_iban'));
      await tester.enterText(iban, '');
      final grace = find.byKey(const ValueKey('lease_grace_days'));
      await tester.ensureVisible(grace);
      await tester.enterText(grace, '90');
      await sendOffer(tester);
      expect(backend.created, isEmpty);
      expect(find.text('Check the late fee and grace days (0 to 60 days).'), findsOneWidget);
    });

    testWidgets('missing fields are refused before any call', (tester) async {
      final backend = await open(tester);
      await tester.tap(find.text('Send offer to tenant'));
      await tester.pumpAndSettle();
      expect(backend.created, isEmpty);
      expect(find.text('Choose the property and tenant, and enter a valid rent and both dates.'), findsOneWidget);
    });

    for (final entry in {
      'property_already_leased': 'This property already has a live lease or an open offer for another tenant.',
      'tenant_not_found': 'The tenant account is not valid. Choose another approved tenant.',
      'property_not_managed': 'You cannot create a lease for this property: it is not managed by your agency or account, or it is not registered yet.',
      'unexpected_reason': 'The lease could not be created. Nothing was saved. Please try again.',
    }.entries) {
      testWidgets('refusal ${entry.key} shows a translated inline error and keeps the dialog', (tester) async {
        String? result = 'unset';
        final backend = await open(tester, failWith: _refusal(entry.key), onResult: (id) => result = id);
        await chooseProperty(tester, 'Marina Tower 1204');
        await chooseTenant(tester, 'Sara Ali');
        await tester.tap(find.text('Send offer to tenant'));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
        expect(find.textContaining('server text'), findsNothing);
        expect(find.byType(CreateLeaseDialog), findsOneWidget);
        expect(result, 'unset');
        expect(backend.created, isEmpty);
      });
    }

    testWidgets('an Arabic refusal is in Arabic', (tester) async {
      await open(tester, locale: const Locale('ar'), failWith: _refusal('property_already_leased'));
      await chooseProperty(tester, 'Marina Tower 1204');
      await chooseTenant(tester, 'Sara Ali');
      await tester.tap(find.text('إرسال العرض للمستأجر'));
      await tester.pumpAndSettle();
      expect(find.text('هذا العقار عليه عقد ساري أو عرض قائم لمستأجر آخر.'), findsOneWidget);
    });
  });
}
