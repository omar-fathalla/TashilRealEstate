import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/maintenance/models/maintenance_ticket.dart';
import 'package:tashil_real_estate/features/maintenance/services/maintenance_service.dart';
import 'package:tashil_real_estate/features/maintenance/views/maintenance_views.dart';
import 'package:tashil_real_estate/features/maintenance/widgets/new_maintenance_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/views/owner_maintenance_view.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_support_view.dart';

class FakeBackend implements MaintenanceBackend {
  String? uid;
  String agency;
  ActiveLeaseRef? lease;
  List<MaintenanceTicket> tickets = const [];
  Object? failCreate;
  Object? failUpdate;
  final created = <Map<String, dynamic>>[];
  final updates = <MapEntry<String, Map<String, dynamic>>>[];
  final watched = <String>[];

  FakeBackend({this.uid = 'tenant1', this.agency = '', this.lease});

  @override
  String? get currentUserId => uid;
  @override
  Future<String> currentAgencyId() async => agency;
  @override
  Stream<List<MaintenanceTicket>> watch(String field, String value) {
    watched.add('$field=$value');
    return Stream.value(tickets);
  }

  @override
  Future<ActiveLeaseRef?> activeLeaseFor(String tenantUid) async => lease;
  @override
  Future<void> create(Map<String, dynamic> data) async {
    if (failCreate != null) throw failCreate!;
    created.add(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    if (failUpdate != null) throw failUpdate!;
    updates.add(MapEntry(id, data));
  }
}

const activeLease = ActiveLeaseRef(
  id: 'lease1',
  ownerId: 'owner1',
  agencyId: 'ag1',
  propertyId: 'p1',
  propertyTitle: 'Marina Apartment',
  tenantName: 'Sara Ali',
);

Widget app(Widget child, {Locale locale = const Locale('en')}) {
  LocaleController.setLocale(locale);
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: child),
  );
}

Future<void> pump(WidgetTester tester, Widget child, {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(app(child, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  group('MaintenanceService', () {
    test('create copies tenant, owner and agency from the active lease and starts pending', () async {
      final backend = FakeBackend(lease: activeLease);
      await MaintenanceService(backend: backend).create(title: ' Leak ', description: 'Under sink', category: 'plumbing', photos: ['a', 'b', 'c', 'd']);
      expect(backend.created.single, {
        'lease_id': 'lease1',
        'tenant_id': 'tenant1',
        'owner_id': 'owner1',
        'agency_id': 'ag1',
        'property_id': 'p1',
        'property_title': 'Marina Apartment',
        'tenant_name': 'Sara Ali',
        'title': 'Leak',
        'description': 'Under sink',
        'category': 'plumbing',
        'photos': ['a', 'b', 'c'],
        'status': 'pending',
      });
    });

    test('no active lease means nothing is written', () async {
      final backend = FakeBackend();
      await expectLater(MaintenanceService(backend: backend).create(title: 'x'), throwsA(isA<NoActiveLeaseException>()));
      expect(backend.created, isEmpty);
      await expectLater(MaintenanceService(backend: FakeBackend(uid: null, lease: activeLease)).create(title: 'x'), throwsA(isA<NoActiveLeaseException>()));
    });

    test('unknown categories fall back to other', () async {
      final backend = FakeBackend(lease: activeLease);
      await MaintenanceService(backend: backend).create(title: 'x', category: 'magic');
      expect(backend.created.single['category'], 'other');
    });

    test('streams are scoped to the signed-in tenant, owner or agency', () async {
      final backend = FakeBackend(agency: 'ag9');
      final service = MaintenanceService(backend: backend);
      await service.streamMine().first;
      await service.streamForManager(agency: false).first;
      await service.streamForManager(agency: true).first;
      expect(backend.watched, ['tenant_id=tenant1', 'owner_id=tenant1', 'agency_id=ag9']);
      expect(await MaintenanceService(backend: FakeBackend(uid: null)).streamMine().first, isEmpty);
      expect(await MaintenanceService(backend: FakeBackend(agency: '')).streamForManager(agency: true).first, isEmpty);
    });

    test('tickets read server documents and ignore unknown values', () {
      final t = MaintenanceTicket.fromMap('m', {'title': 'x', 'status': 'open', 'category': 'magic', 'photos': ['a', 5]});
      expect(t.status, 'pending');
      expect(t.category, 'other');
      expect(t.photos, ['a']);
    });
  });

  group('tenant screen', () {
    testWidgets('shows real tickets with status chips, not the sample ones', (tester) async {
      final backend = FakeBackend(lease: activeLease)
        ..tickets = const [
          MaintenanceTicket(id: 'm1', title: 'Kitchen sink leaks', category: 'plumbing', status: 'in_progress', propertyTitle: 'Marina Apartment'),
          MaintenanceTicket(id: 'm2', title: 'Hallway light', category: 'electrical', status: 'resolved', resolutionNote: 'Bulb replaced'),
        ];
      await pump(tester, TenantMaintenanceView(service: MaintenanceService(backend: backend)));
      expect(find.text('Kitchen sink leaks'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.textContaining('Bulb replaced'), findsOneWidget);
      expect(find.textContaining('Central AC'), findsNothing);
    });

    testWidgets('empty state when there are no requests', (tester) async {
      await pump(tester, TenantMaintenanceView(service: MaintenanceService(backend: FakeBackend(lease: activeLease))));
      expect(find.textContaining('No maintenance requests yet'), findsOneWidget);
    });

    testWidgets('the plus button opens the form and a request is created on the active lease', (tester) async {
      final backend = FakeBackend(lease: activeLease);
      await pump(tester, TenantMaintenanceView(service: MaintenanceService(backend: backend)));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(backend.created, isEmpty, reason: 'a title is required');
      await tester.enterText(find.byType(TextField).first, 'Kitchen sink leaks');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(backend.created.single['lease_id'], 'lease1');
      expect(backend.created.single['title'], 'Kitchen sink leaks');
      expect(find.textContaining('was sent to the owner'), findsOneWidget);
    });

    testWidgets('no active lease: the form says so and nothing is created', (tester) async {
      final backend = FakeBackend();
      await pump(tester, TenantMaintenanceView(service: MaintenanceService(backend: backend)));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Leak');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(find.text('You need an active lease to send a maintenance request.'), findsOneWidget);
      expect(backend.created, isEmpty);
    });

    testWidgets('a server failure is shown and the dialog stays open', (tester) async {
      final backend = FakeBackend(lease: activeLease)..failCreate = Exception('permission-denied');
      await pump(tester, TenantMaintenanceView(service: MaintenanceService(backend: backend)));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Leak');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(find.text('We could not send the request. Please try again.'), findsOneWidget);
      expect(find.byType(NewMaintenanceDialog), findsOneWidget);
    });

    testWidgets('photos are kept inline, at most three, and oversized ones are refused', (tester) async {
      final backend = FakeBackend(lease: activeLease);
      final small = 'data:image/png;base64,${'A' * 100}';
      final big = 'data:image/png;base64,${'A' * (maxPhotoChars + 1)}';
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => NewMaintenanceDialog(service: MaintenanceService(backend: backend), pickPhotos: () async => [small, big, small, small, small]),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add photos'));
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      expect(find.textContaining('too large'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Leak');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect((backend.created.single['photos'] as List).length, 3);
    });

    testWidgets('the tenant support screen is the real one and renders in Arabic', (tester) async {
      MaintenanceService.instance = MaintenanceService(backend: FakeBackend(uid: null));
      await pump(tester, const TenantSupportView(), locale: const Locale('ar'));
      expect(find.text('الصيانة'), findsOneWidget);
      expect(find.textContaining('لا توجد طلبات صيانة'), findsOneWidget);
    });
  });

  group('owner and agency screen', () {
    final pending = MaintenanceTicket(id: 'm1', title: 'Kitchen sink leaks', category: 'plumbing', tenantName: 'Sara Ali', createdAt: DateTime(2026, 6, 1));

    testWidgets('owner sees their requests and updates the status through the backend', (tester) async {
      final backend = FakeBackend(uid: 'owner1')..tickets = [pending];
      await pump(tester, MaintenanceManagerView(service: MaintenanceService(backend: backend)));
      expect(backend.watched, ['owner_id=owner1']);
      expect(find.text('Kitchen sink leaks'), findsOneWidget);
      expect(find.textContaining('Sara Ali'), findsOneWidget);
      await tester.tap(find.text('Start work'));
      await tester.pumpAndSettle();
      expect(backend.updates.single.key, 'm1');
      expect(backend.updates.single.value, {'status': 'in_progress'});
      await tester.tap(find.text('Mark resolved'));
      await tester.pumpAndSettle();
      expect(backend.updates.last.value, {'status': 'resolved'});
    });

    testWidgets('resolved can be reopened; escalated has no actions', (tester) async {
      final backend = FakeBackend(uid: 'owner1')
        ..tickets = const [
          MaintenanceTicket(id: 'r', title: 'Done thing', status: 'resolved'),
          MaintenanceTicket(id: 'e', title: 'Escalated thing', status: 'escalated'),
        ];
      await pump(tester, MaintenanceManagerView(service: MaintenanceService(backend: backend)));
      expect(find.text('Reopen'), findsOneWidget);
      expect(find.text('Start work'), findsNothing);
      expect(find.text('Mark resolved'), findsNothing);
      await tester.tap(find.text('Reopen'));
      await tester.pumpAndSettle();
      expect(backend.updates.single.value, {'status': 'pending'});
    });

    testWidgets('an update the server refuses is reported', (tester) async {
      final backend = FakeBackend(uid: 'owner1')
        ..tickets = [pending]
        ..failUpdate = Exception('permission-denied');
      await pump(tester, MaintenanceManagerView(service: MaintenanceService(backend: backend)));
      await tester.tap(find.text('Start work'));
      await tester.pumpAndSettle();
      expect(find.text('We could not update the request.'), findsOneWidget);
    });

    testWidgets('agency scope and empty states', (tester) async {
      final backend = FakeBackend(uid: 'ag-admin', agency: 'ag1');
      await pump(tester, MaintenanceManagerView(agency: true, service: MaintenanceService(backend: backend)));
      expect(backend.watched, ['agency_id=ag1']);
      expect(find.text('No maintenance requests right now.'), findsOneWidget);
    });

    testWidgets('the owner maintenance screen shows no sample tickets', (tester) async {
      MaintenanceService.instance = MaintenanceService(backend: FakeBackend(uid: 'owner1'));
      await pump(tester, const OwnerMaintenanceView());
      expect(find.text('MNT-1021'), findsNothing);
      expect(find.text('No maintenance requests right now.'), findsOneWidget);
    });
  });
}
