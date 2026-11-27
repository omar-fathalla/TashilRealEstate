import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/portfolio/services/rent_schedule_builder.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import 'support/portfolio_fakes.dart';

// TAQ-163: Rent Collection row actions on server rows are stored by updateRentRow and read back
// from RentRowStates, so every device and teammate sees them.
void main() {
  final now = DateTime(2026, 11, 26, 12);
  setUp(() => CountryController.setCountry('AE'));
  tearDown(() {
    CountryController.setCountry('EG');
    RentCollectionService().leaveServerMode(signedIn: false);
  });

  PortfolioSnapshot snap({List<PortfolioRentRowState> states = const []}) => PortfolioSnapshot(
        load: PortfolioLoad.ready,
        leases: [lease('l1', start: '2026-08-10', end: '2027-08-09')],
        rentRowStates: states,
      );

  group('RentScheduleBuilder applies the row states', () {
    test('trash, notes, reminders and the legal notice come from the server', () {
      final rows = RentScheduleBuilder.build(snap(states: [
        PortfolioRentRowState(id: 'l1_2026-09', leaseId: 'l1', period: '2026-09', hidden: true, hiddenAt: DateTime(2026, 11, 20)),
        PortfolioRentRowState(id: 'l1_2026-10', leaseId: 'l1', period: '2026-10', notes: 'cheque pending', reminderCount: 2, lastReminderAt: DateTime(2026, 11, 1), legalNoticeAt: DateTime(2026, 11, 2)),
      ]), now: now);
      final sep = rows.singleWhere((r) => r.monthKey == '2026-09');
      expect(sep.isDeleted, isTrue);
      expect(sep.deletedAt, DateTime(2026, 11, 20));
      final oct = rows.singleWhere((r) => r.monthKey == '2026-10');
      expect(oct.notes, 'cheque pending');
      expect(oct.reminderCount, 2);
      expect(oct.legalWarningIssued, isTrue);
      expect(rows.singleWhere((r) => r.monthKey == '2026-11').isDeleted, isFalse);
    });

    test('a deleted row is left out', () {
      final rows = RentScheduleBuilder.build(snap(states: const [PortfolioRentRowState(id: 'l1_2026-09', leaseId: 'l1', period: '2026-09', hidden: true, deleted: true)]), now: now);
      expect(rows.where((r) => r.monthKey == '2026-09'), isEmpty);
      expect(rows, isNotEmpty);
    });

    test('the state parses from Firestore data', () {
      final s = PortfolioRentRowState.fromMap('l1_2026-09', {'lease_id': 'l1', 'period': '2026-09', 'hidden': true, 'reminder_count': 3, 'notes': 'x'});
      expect(s.key, 'l1_2026-09');
      expect(s.hidden, isTrue);
      expect(s.deleted, isFalse);
      expect(s.reminderCount, 3);
    });
  });

  group('RentCollectionService with a server hook', () {
    late List<List<String?>> calls;
    late RentCollectionService service;
    setUp(() {
      calls = [];
      service = RentCollectionService();
      service.applyServerInvoices(RentScheduleBuilder.build(snap(), now: now));
      service.serverRowAction = (leaseId, period, action, {notes}) async => calls.add([leaseId, period, action, notes]);
    });

    test('trash, restore and delete go to the server with the lease and month', () {
      service.softDeleteInvoice('inv_l1_2026-09');
      expect(service.getInvoiceById('inv_l1_2026-09')!.isDeleted, isTrue);
      service.restoreInvoice('inv_l1_2026-09');
      expect(service.getInvoiceById('inv_l1_2026-09')!.isDeleted, isFalse);
      service.permanentlyDeleteInvoice('inv_l1_2026-10');
      expect(service.getInvoiceById('inv_l1_2026-10'), isNull);
      expect(calls, [
        ['l1', '2026-09', 'trash', null],
        ['l1', '2026-09', 'restore', null],
        ['l1', '2026-10', 'delete', null],
      ]);
    });

    test('a refresh with the server state does not bring back local-only trash', () {
      service.softDeleteInvoice('inv_l1_2026-09');
      // The server says restored (another device): the row is back.
      service.applyServerInvoices(RentScheduleBuilder.build(snap(), now: now));
      expect(service.getInvoiceById('inv_l1_2026-09')!.isDeleted, isFalse);
    });

    test('reminders, legal notices and notes go to the server; amount and due date do not change', () {
      final before = service.getInvoiceById('inv_l1_2026-11')!;
      service.sendReminder('inv_l1_2026-11');
      service.issueLegalNotice('inv_l1_2026-11');
      service.updateInvoice(invoiceId: 'inv_l1_2026-11', baseAmount: 1, dueDate: DateTime(2030), notes: 'called');
      final after = service.getInvoiceById('inv_l1_2026-11')!;
      expect(after.baseAmount, before.baseAmount);
      expect(after.dueDate, before.dueDate);
      expect(after.notes, 'called');
      expect(calls.map((c) => c[2]), ['reminder', 'legal_notice', 'note']);
      expect(calls.last[3], 'called');
    });

    test('empty trash deletes every trashed row on the server', () {
      service.softDeleteInvoice('inv_l1_2026-09');
      service.softDeleteInvoice('inv_l1_2026-10');
      calls.clear();
      service.emptyTrash(countryCode: 'AE');
      expect(calls.map((c) => '${c[1]}:${c[2]}').toSet(), {'2026-09:delete', '2026-10:delete'});
    });
  });

  testWidgets('the screen wires its row actions to updateRentRow and survives unreadable row states', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 1600);
    addTearDown(tester.view.reset);
    final backend = FakePortfolioBackend()
      ..leases = [lease('l1', start: '2020-01-01', end: '2099-12-31')]
      ..failRowStates = true;
    final c = PortfolioController(data: PortfolioDataService(backend: backend), requests: RequestsService(backend: FakeRequestsBackendForPortfolio()), includeRequests: false);
    addTearDown(c.dispose);
    await tester.runAsync(() async {
      await c.start();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpWidget(testApp(RentCollectionView(portfolio: c)));
    await tester.pumpAndSettle();
    expect(c.snapshot.load, PortfolioLoad.ready);
    expect(find.text('Tenant l1'), findsWidgets);
    final service = RentCollectionService();
    expect(service.serverRowAction, isNotNull);
    final first = service.invoicesNotifier.value.first;
    service.softDeleteInvoice(first.id);
    await tester.pump();
    expect(backend.rowActions.single['action'], 'trash');
    expect(backend.rowActions.single['leaseId'], 'l1');
    await tester.pumpWidget(const SizedBox());
    expect(service.serverRowAction, isNull);
  });
}
