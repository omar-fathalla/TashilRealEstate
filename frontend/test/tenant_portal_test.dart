import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';
import 'package:tashil_real_estate/features/tenant_portal/models/tenant_models.dart';
import 'package:tashil_real_estate/features/tenant_portal/services/tenant_lease_service.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_home_view.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_notifications_view.dart';
import 'package:tashil_real_estate/features/tenant_portal/views/tenant_payments_view.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';

class FakeTenantBackend implements TenantBackend {
  String? uid;
  List<TenantLease> leases = const [];
  List<TenantTransaction> transactions = const [];
  List<TenantInvoice> invoices = const [];
  List<TenantNotification> notifications = const [];
  Object? failDecision;
  final decisions = <String, bool>{};
  final read = <String>[];
  final watched = <String>[];

  FakeTenantBackend({this.uid = 'tenant1'});

  @override
  String? get currentUserId => uid;
  @override
  Stream<List<TenantLease>> watchLeases(String uid) {
    watched.add('leases:$uid');
    return Stream.value(leases);
  }

  @override
  Stream<List<TenantTransaction>> watchTransactions(String uid) {
    watched.add('transactions:$uid');
    return Stream.value(transactions);
  }

  @override
  Stream<List<TenantInvoice>> watchInvoices(String uid) {
    watched.add('invoices:$uid');
    return Stream.value(invoices);
  }

  @override
  Stream<List<TenantNotification>> watchNotifications(String uid) {
    watched.add('notifications:$uid');
    return Stream.value(notifications);
  }

  @override
  Future<void> decideLease(String leaseId, {required bool approve}) async {
    if (failDecision != null) throw failDecision!;
    decisions[leaseId] = approve;
  }

  @override
  Future<void> markNotificationRead(String uid, String notificationId) async => read.add(notificationId);
}

class FakeRequestsBackend implements RequestsBackend {
  List<ViewingRequestItem> viewings = const [];
  List<RentalApplicationItem> applications = const [];
  @override
  String? get currentUserId => 'tenant1';
  @override
  bool get isSignedIn => true;
  @override
  Future<String> currentAgencyId() async => '';
  @override
  Stream<List<ViewingRequestItem>> watchViewings(RequestScope scope) => Stream.value(viewings);
  @override
  Stream<List<RentalApplicationItem>> watchApplications(RequestScope scope) => Stream.value(applications);
  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> data) async => {};
  @override
  Stream<String> watchLeaseStatus(String leaseId) => Stream.value('');
  @override
  Future<void> sendLeaseOffer(String leaseId) async {}
}

const activeLease = TenantLease(
  id: 'l1',
  status: 'active',
  propertyTitle: 'Marina Apartment',
  monthlyRent: 8500,
  currencyCode: 'AED',
  startDate: '2026-01-01',
  endDate: '2027-12-31',
);

const offer = TenantLease(
  id: 'l2',
  status: 'pending_tenant_approval',
  propertyTitle: 'Palm Villa',
  monthlyRent: 12000,
  currencyCode: 'AED',
  startDate: '2026-12-01',
  endDate: '2027-11-30',
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

TenantHomeView home(FakeTenantBackend backend, {FakeRequestsBackend? requests, VoidCallback? onFind}) => TenantHomeView(
      key: UniqueKey(),
      service: TenantLeaseService(backend: backend),
      requests: RequestsService(backend: requests ?? FakeRequestsBackend()),
      onFindProperty: onFind,
    );

void main() {
  group('models and service', () {
    test('leases read the new fields and the legacy rent fields, and hide drafts', () {
      final a = TenantLease.fromMap('a', {'status': 'active', 'monthly_rent': 5000, 'country_code': 'EG'});
      expect(a.monthlyRent, 5000);
      expect(a.currencyCode, 'EGP');
      final b = TenantLease.fromMap('b', {'financialTerms': {'annualRent': 120000}, 'status': 'active'});
      expect(b.monthlyRent, 10000);
      expect(TenantLease.fromMap('c', {'status': 'draft'}).visibleToTenant, isFalse);
      expect(TenantLease.fromMap('d', {'status': 'weird'}).visibleToTenant, isFalse);
      expect(TenantLease.fromMap('e', {'status': 'pending_tenant_approval'}).visibleToTenant, isTrue);
    });

    test('streams are scoped to the signed-in tenant; signed out gets nothing', () async {
      final backend = FakeTenantBackend()..leases = const [activeLease, TenantLease(id: 'd', status: 'draft')];
      final service = TenantLeaseService(backend: backend);
      expect((await service.watchLeases().first).map((l) => l.id), ['l1']);
      await service.watchTransactions().first;
      await service.watchInvoices().first;
      await service.watchNotifications().first;
      expect(backend.watched, ['leases:tenant1', 'transactions:tenant1', 'invoices:tenant1', 'notifications:tenant1']);
      final out = TenantLeaseService(backend: FakeTenantBackend(uid: null));
      expect(await out.watchLeases().first, isEmpty);
      expect(await out.watchNotifications().first, isEmpty);
    });

    test('nextDuePeriod: current month, skips paid months, respects the lease range', () {
      final now = DateTime(2026, 11, 25);
      TenantTransaction paid(String period) => TenantTransaction(id: 'l1_$period', leaseId: 'l1', period: period, status: 'paid');
      expect(nextDuePeriod(activeLease, const [], now), '2026-11');
      expect(nextDuePeriod(activeLease, [paid('2026-11')], now), '2026-12');
      expect(nextDuePeriod(activeLease, [paid('2026-11'), paid('2026-12')], now), '2027-01');
      expect(nextDuePeriod(activeLease, [const TenantTransaction(id: 'x', leaseId: 'l1', period: '2026-11', status: 'pending')], now), '2026-11');
      expect(nextDuePeriod(activeLease, [const TenantTransaction(id: 'x', leaseId: 'other', period: '2026-11', status: 'paid')], now), '2026-11');
      expect(nextDuePeriod(offer, const [], now), isNull);
      const ending = TenantLease(id: 'l1', status: 'active', startDate: '2026-01-01', endDate: '2026-11-30');
      expect(nextDuePeriod(ending, [paid('2026-11')], now), isNull);
      const later = TenantLease(id: 'l1', status: 'active', startDate: '2027-02-01', endDate: '2027-12-31');
      expect(nextDuePeriod(later, const [], now), '2027-02');
      expect(nextDuePeriod(activeLease, [paid('2026-12')], DateTime(2026, 12, 31)), '2027-01');
    });
  });

  group('home', () {
    testWidgets('shows the tenant\'s real active lease, not demo data', (tester) async {
      final backend = FakeTenantBackend()..leases = const [activeLease];
      await pump(tester, home(backend));
      expect(find.text('Marina Apartment'), findsOneWidget);
      expect(find.textContaining('8,500'), findsOneWidget);
      expect(find.text('2026-01-01 → 2027-12-31'), findsOneWidget);
      expect(find.textContaining('Karim'), findsNothing);
      expect(find.textContaining('Beverly'), findsNothing);
      expect(find.text('2026-11-01'), findsNothing);
      expect(find.text('Find a property'), findsNothing);
    });

    testWidgets('no lease: welcome with the Find a property button, requests and applications with statuses', (tester) async {
      var found = 0;
      final requests = FakeRequestsBackend()
        ..viewings = const [ViewingRequestItem(id: 'v1', listingId: 'p1', status: 'confirmed', listingTitles: {'en': 'Marina Apartment'}, preferredDate: '2026-12-02')]
        ..applications = const [RentalApplicationItem(id: 'a1', listingId: 'p2', status: 'pending', listingTitles: {'en': 'Palm Villa'})];
      await pump(tester, home(FakeTenantBackend(), requests: requests, onFind: () => found++));
      expect(find.text('Welcome to your tenant account'), findsOneWidget);
      expect(find.textContaining('lease offer, you will be notified and can approve it here'), findsOneWidget);
      expect(find.text('Marina Apartment'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Palm Villa'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      await tester.tap(find.text('Find a property'));
      expect(found, 1);
    });

    testWidgets('no lease and nothing sent yet: empty hints', (tester) async {
      await pump(tester, home(FakeTenantBackend()));
      expect(find.text('You have not requested any viewings yet.'), findsOneWidget);
      expect(find.text('You have not applied to rent anything yet.'), findsOneWidget);
    });

    testWidgets('a lease offer can be approved after confirming', (tester) async {
      final backend = FakeTenantBackend()..leases = const [offer];
      await pump(tester, home(backend));
      expect(find.text('A lease offer is waiting for you'), findsOneWidget);
      expect(find.text('Welcome to your tenant account'), findsNothing);
      await tester.tap(find.text('Approve lease'));
      await tester.pumpAndSettle();
      expect(backend.decisions, isEmpty, reason: 'nothing is sent before confirming');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(backend.decisions, {'l2': true});
      expect(find.textContaining('now active'), findsOneWidget);
    });

    testWidgets('a lease offer can be rejected, and cancelling sends nothing', (tester) async {
      final backend = FakeTenantBackend()..leases = const [offer];
      await pump(tester, home(backend));
      await tester.tap(find.text('Reject lease'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.decisions, isEmpty);
      await tester.tap(find.text('Reject lease'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(backend.decisions, {'l2': false});
    });

    testWidgets('a refused decision is reported', (tester) async {
      final backend = FakeTenantBackend()
        ..leases = const [offer]
        ..failDecision = Exception('permission-denied');
      await pump(tester, home(backend));
      await tester.tap(find.text('Approve lease'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('We could not save your decision. Please try again.'), findsOneWidget);
    });

    testWidgets('past leases are listed with their status; drafts are hidden', (tester) async {
      final backend = FakeTenantBackend()
        ..leases = const [
          activeLease,
          TenantLease(id: 'old', status: 'expired', propertyTitle: 'Old Flat', startDate: '2024-01-01', endDate: '2024-12-31'),
          TenantLease(id: 'dr', status: 'draft', propertyTitle: 'Secret Draft'),
        ];
      await pump(tester, home(backend));
      expect(find.text('Old Flat'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Secret Draft'), findsNothing);
    });

    testWidgets('renders in Arabic and Hindi', (tester) async {
      await pump(tester, home(FakeTenantBackend()), locale: const Locale('ar'));
      expect(find.text('ابحث عن عقار'), findsOneWidget);
      await pump(tester, home(FakeTenantBackend()), locale: const Locale('hi'));
      expect(find.text('संपत्ति खोजें'), findsOneWidget);
    });
  });

  group('payments', () {
    TenantPaymentsView payments(FakeTenantBackend backend) => TenantPaymentsView(
          key: UniqueKey(),
          service: TenantLeaseService(backend: backend),
          now: () => DateTime(2026, 11, 25),
        );

    testWidgets('shows rent due with a visible but disabled Pay now', (tester) async {
      final backend = FakeTenantBackend()..leases = const [activeLease];
      await pump(tester, payments(backend));
      expect(find.text('Rent for 2026-11'), findsOneWidget);
      expect(find.textContaining('8,500'), findsOneWidget);
      expect(find.text('Online payment is coming soon.'), findsOneWidget);
      final button = find.ancestor(of: find.text('Pay Now Online'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      expect(button, findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
      await tester.tap(find.text('Pay Now Online'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('history lists real transactions with receipt details; invoices are not invented', (tester) async {
      final backend = FakeTenantBackend()
        ..leases = const [activeLease]
        ..transactions = const [
          TenantTransaction(id: 'l1_2026-10', leaseId: 'l1', period: '2026-10', amount: 8500, status: 'paid', invoiceNumber: 'TASHIL-INV-l1_2026-10'),
          TenantTransaction(id: 'l1_2026-11', leaseId: 'l1', period: '2026-11', amount: 8500, status: 'failed'),
        ]
        ..invoices = const [
          TenantInvoice(invoiceNumber: 'TASHIL-INV-l1_2026-10', transactionId: 'l1_2026-10', paymentMethod: 'cash', paymentReference: 'RCPT-77'),
        ];
      await pump(tester, payments(backend));
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.textContaining('TASHIL-INV-l1_2026-10'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('RCPT-77'), findsOneWidget);
      expect(find.text('Rent for 2026-11'), findsNWidgets(2), reason: 'the due card and the failed attempt');
    });

    testWidgets('a paid month moves the due card to the next month', (tester) async {
      final backend = FakeTenantBackend()
        ..leases = const [activeLease]
        ..transactions = const [TenantTransaction(id: 'l1_2026-11', leaseId: 'l1', period: '2026-11', amount: 8500, status: 'paid')];
      await pump(tester, payments(backend));
      expect(find.text('Rent for 2026-12'), findsOneWidget);
    });

    testWidgets('no lease: empty state and no Pay now', (tester) async {
      await pump(tester, payments(FakeTenantBackend()));
      expect(find.text('No active lease yet'), findsOneWidget);
      expect(find.text('Pay Now Online'), findsNothing);
      expect(find.text('No payments yet.'), findsOneWidget);
    });

    testWidgets('the legacy checkout dialog never marks an invoice paid and its button is disabled', (tester) async {
      final service = RentCollectionService();
      final invoice = RentInvoiceModel(
        id: 'inv-x',
        invoiceNumber: 'INV-X',
        contractNumber: 'C-1',
        countryCode: 'AE',
        unitTitle: 'Unit',
        unitNumber: '1',
        buildingName: 'B',
        district: 'D',
        tenant: TenantInfo(name: 'T', phone: '1', email: 't@example.com', idNumber: '1'),
        owner: OwnerPayoutInfo(name: 'O', bankName: 'Bank', iban: 'AE000', accountNumber: '1', walletOrVpa: 'o'),
        baseAmount: 1000,
        dueDate: DateTime(2026, 12, 1),
        status: 'due_soon',
      );
      await pump(tester, TenantCheckoutDialog(invoice: invoice));
      final button = find.ancestor(of: find.text('Pay Now Online'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
      expect(find.text('Online payment is coming soon.'), findsOneWidget);
      expect(invoice.status, 'due_soon');
      expect(service.invoicesNotifier.value.where((i) => i.id == 'inv-x'), isEmpty, reason: 'showing the dialog does not touch the service');
    });
  });

  group('notifications', () {
    final unread = TenantNotification(id: 'n1', type: 'lease_offer', title: const {'en': 'A lease offer is waiting', 'ar': 'عرض عقد'}, body: const {'en': 'Review it.'}, createdAt: DateTime(2026, 11, 25));
    final readOne = TenantNotification(id: 'n2', title: const {'en': 'Rent payment confirmed'}, body: const {'en': 'Paid.'}, read: true, createdAt: DateTime(2026, 11, 1));

    TenantNotificationsView view(FakeTenantBackend backend) => TenantNotificationsView(key: UniqueKey(), service: TenantLeaseService(backend: backend));

    testWidgets('lists notifications newest first with a read state', (tester) async {
      final backend = FakeTenantBackend()..notifications = [readOne, unread];
      await pump(tester, view(backend));
      expect(find.text('A lease offer is waiting'), findsOneWidget);
      expect(find.text('Rent payment confirmed'), findsOneWidget);
      expect(tester.getTopLeft(find.text('A lease offer is waiting')).dy, lessThan(tester.getTopLeft(find.text('Rent payment confirmed')).dy));
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('tapping an unread notification marks it read; read ones are left alone', (tester) async {
      final backend = FakeTenantBackend()..notifications = [unread, readOne];
      await pump(tester, view(backend));
      await tester.tap(find.text('Rent payment confirmed'));
      await tester.pumpAndSettle();
      expect(backend.read, isEmpty);
      await tester.tap(find.text('A lease offer is waiting'));
      await tester.pumpAndSettle();
      expect(backend.read, ['n1']);
    });

    testWidgets('mark all read only touches unread ones', (tester) async {
      final backend = FakeTenantBackend()..notifications = [unread, readOne];
      await pump(tester, view(backend));
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();
      expect(backend.read, ['n1']);
    });

    testWidgets('empty state, and the text follows the language', (tester) async {
      await pump(tester, view(FakeTenantBackend()));
      expect(find.text('No notifications yet.'), findsOneWidget);
      expect(find.text('Mark all as read'), findsNothing);
      final backend = FakeTenantBackend()..notifications = [unread];
      await pump(tester, view(backend), locale: const Locale('ar'));
      expect(find.text('عرض عقد'), findsOneWidget);
    });
  });
}
