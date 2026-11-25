import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';
import 'package:tashil_real_estate/features/requests/views/requests_inbox_view.dart';
import 'package:tashil_real_estate/features/requests/widgets/request_listing_sheet.dart';

class FakeBackend implements RequestsBackend {
  bool signedIn;
  String uid;
  String agency;
  Object? failWith;
  final calls = <MapEntry<String, Map<String, dynamic>>>[];
  final viewings = StreamController<List<ViewingRequestItem>>.broadcast();
  final applications = StreamController<List<RentalApplicationItem>>.broadcast();
  List<ViewingRequestItem> viewingItems = const [];
  List<RentalApplicationItem> applicationItems = const [];
  RequestScope? lastScope;

  FakeBackend({this.signedIn = true, this.uid = 'u1', this.agency = ''});

  @override
  String? get currentUserId => signedIn ? uid : null;
  @override
  bool get isSignedIn => signedIn;
  @override
  Future<String> currentAgencyId() async => agency;
  @override
  Stream<List<ViewingRequestItem>> watchViewings(RequestScope scope) {
    lastScope = scope;
    return Stream.value(viewingItems);
  }

  @override
  Stream<List<RentalApplicationItem>> watchApplications(RequestScope scope) {
    lastScope = scope;
    return Stream.value(applicationItems);
  }

  String leaseStatus = 'draft';
  final offers = <String>[];

  @override
  Stream<String> watchLeaseStatus(String leaseId) => Stream.value(leaseStatus);

  @override
  Future<void> sendLeaseOffer(String leaseId) async {
    if (failWith != null) throw failWith!;
    offers.add(leaseId);
  }

  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> data) async {
    calls.add(MapEntry(function, data));
    if (failWith != null) throw failWith!;
    return {'success': true, 'leaseId': 'app_x'};
  }
}

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

void main() {
  group('RequestListingSheet', () {
    testWidgets('signed out: asks to sign in and sends nothing', (tester) async {
      final backend = FakeBackend(signedIn: false);
      await tester.pumpWidget(app(RequestListingSheet(listingId: 'p1', listingTitle: 'Flat', service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to your account first to continue.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(backend.calls, isEmpty);
    });

    testWidgets('signed in: the viewing request goes to the server and success is shown only afterwards', (tester) async {
      final backend = FakeBackend();
      await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
          onPressed: () => RequestListingSheet.show(context, listingId: 'p1', listingTitle: 'Flat', service: RequestsService(backend: backend)),
          child: const Text('open'),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Sara Ali');
      await tester.enterText(find.byType(TextField).at(1), '+971501234567');
      await tester.tap(find.text('Send viewing request'));
      await tester.pumpAndSettle();
      expect(backend.calls.single.key, 'requestViewing');
      expect(backend.calls.single.value, {'listingId': 'p1', 'name': 'Sara Ali', 'phone': '+971501234567'});
      expect(find.textContaining('Your viewing request was sent'), findsOneWidget);
    });

    testWidgets('a server rejection shows an error and no success message', (tester) async {
      final backend = FakeBackend()..failWith = Exception('[firebase_functions/failed-precondition] listing_not_live');
      await tester.pumpWidget(app(RequestListingSheet(listingId: 'p1', listingTitle: 'Flat', service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Sara Ali');
      await tester.enterText(find.byType(TextField).at(1), '+971501234567');
      await tester.tap(find.text('Send viewing request'));
      await tester.pumpAndSettle();
      expect(find.text('This listing is no longer available.'), findsOneWidget);
      expect(find.textContaining('was sent'), findsNothing);
    });

    testWidgets('apply to rent calls applyForRental; empty fields call nothing', (tester) async {
      final backend = FakeBackend();
      await tester.pumpWidget(app(RequestListingSheet(listingId: 'p1', listingTitle: 'Flat', service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply to rent'));
      await tester.pumpAndSettle();
      expect(backend.calls, isEmpty);
      await tester.enterText(find.byType(TextField).at(0), 'Sara Ali');
      await tester.enterText(find.byType(TextField).at(1), '+971501234567');
      await tester.enterText(find.byType(TextField).at(2), 'Family of 3');
      await tester.tap(find.text('Apply to rent'));
      await tester.pumpAndSettle();
      expect(backend.calls.single.key, 'applyForRental');
      expect(backend.calls.single.value['message'], 'Family of 3');
    });

    testWidgets('renders in Arabic without Latin copy in the labels', (tester) async {
      final backend = FakeBackend();
      await tester.pumpWidget(app(RequestListingSheet(listingId: 'p1', listingTitle: 'Flat', service: RequestsService(backend: backend)), locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.text('إرسال طلب المعاينة'), findsOneWidget);
      expect(find.text('تقديم طلب إيجار'), findsOneWidget);
    });
  });

  group('RequestsInboxView', () {
    final viewing = ViewingRequestItem(
      id: 'v1',
      listingId: 'p1',
      ownerId: 'u1',
      requesterName: 'Sara Ali',
      requesterPhone: '+971501234567',
      message: 'After 6pm',
      listingTitles: const {'en': 'Marina Apartment'},
    );
    const application = RentalApplicationItem(
      id: 'p1_t1',
      listingId: 'p1',
      status: 'approved',
      applicantName: 'Omar Nabil',
      applicantPhone: '+971509999999',
      listingTitles: {'en': 'Marina Apartment'},
    );

    testWidgets('lists viewing requests for the owner and confirms through the server', (tester) async {
      final backend = FakeBackend()..viewingItems = [viewing];
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(backend.lastScope!.field, 'owner_id');
      expect(find.text('Marina Apartment'), findsOneWidget);
      expect(find.text('Sara Ali'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(backend.calls.single.key, 'respondToViewingRequest');
      expect(backend.calls.single.value, {'requestId': 'v1', 'decision': 'confirmed'});
    });

    testWidgets('decline sends declined; answered requests have no actions', (tester) async {
      final backend = FakeBackend()..viewingItems = [viewing];
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      expect(backend.calls.single.value['decision'], 'declined');

      final answered = FakeBackend()
        ..viewingItems = [
          ViewingRequestItem(id: 'v2', listingId: 'p1', requesterName: 'X Y', requesterPhone: '+971500000000', status: 'confirmed'),
        ];
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), service: RequestsService(backend: answered)), locale: const Locale('en')));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Contact on WhatsApp'), findsOneWidget);
    });

    testWidgets('an agency admin sees its own agency scope; no agency means an empty inbox', (tester) async {
      final backend = FakeBackend(agency: 'ag1')..viewingItems = [viewing];
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), agency: true, service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(backend.lastScope!.field, 'agency_id');
      expect(backend.lastScope!.value, 'ag1');

      final none = FakeBackend();
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), agency: true, service: RequestsService(backend: none))));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('No requests yet.'), findsOneWidget);
    });

    testWidgets('applications: approve, and create a lease draft after approval', (tester) async {
      final backend = FakeBackend()
        ..applicationItems = [
          const RentalApplicationItem(id: 'p1_t0', listingId: 'p1', applicantName: 'Pending Person', applicantPhone: '+971500000001'),
          application,
        ];
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(backend.calls.single.key, 'decideRentalApplication');
      expect(backend.calls.single.value, {'applicationId': 'p1_t0', 'decision': 'approved'});

      await tester.tap(find.text('Create lease draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Create lease draft')).last);
      await tester.pumpAndSettle();
      expect(find.text('Check the details you entered and try again.'), findsOneWidget);
      expect(backend.calls.length, 1, reason: 'bad dates are not sent');
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '2026-07-01');
      await tester.enterText(fields.at(1), '2027-06-30');
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Create lease draft')).last);
      await tester.pumpAndSettle();
      expect(backend.calls.last.key, 'createLeaseFromApplication');
      expect(backend.calls.last.value, {'applicationId': 'p1_t1', 'startDate': '2026-07-01', 'endDate': '2027-06-30'});
    });

    testWidgets('a draft lease from an application can be offered to the tenant; later statuses have no send button', (tester) async {
      final backend = FakeBackend()
        ..applicationItems = const [
          RentalApplicationItem(id: 'p1_t0', listingId: 'p1', applicantName: 'Sara', applicantPhone: '+971500000001', status: 'approved', leaseId: 'app_p1_t0'),
        ];
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send lease offer to tenant'));
      await tester.pumpAndSettle();
      expect(backend.offers, ['app_p1_t0']);
      expect(find.text('The lease offer was sent to the tenant.'), findsOneWidget);

      backend.leaseStatus = 'pending_tenant_approval';
      await tester.pumpWidget(app(RequestsInboxView(key: UniqueKey(), service: RequestsService(backend: backend))));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();
      expect(find.text('Send lease offer to tenant'), findsNothing);
      expect(find.text('Offer sent, awaiting the tenant'), findsOneWidget);
    });
  });

  group('helpers', () {
    test('whatsAppUri keeps digits only and carries the text', () {
      final uri = whatsAppUri('+971 50-123 4567', message: 'Marina Apartment');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/971501234567');
      expect(uri.queryParameters['text'], 'Marina Apartment');
      expect(whatsAppUri('0501234567').hasQuery, isFalse);
    });

    test('request errors map to translated messages', () {
      expect(requestErrorKey(Exception('listing_not_live')), 'rqListingUnavailable');
      expect(requestErrorKey(Exception('duplicate_pending')), 'rqDuplicate');
      expect(requestErrorKey(Exception('[firebase_functions/resource-exhausted]')), 'rqTooMany');
      expect(requestErrorKey(Exception('anything else')), 'rqFailed');
    });

    test('models read server documents', () {
      final v = ViewingRequestItem.fromMap('v', {'listing_id': 'p', 'status': 'declined', 'listing_titles': {'ar': 'شقة', 'en': 'Flat'}});
      expect(v.isPending, isFalse);
      expect(v.titleFor('ar'), 'شقة');
      expect(v.titleFor('hi'), 'Flat');
      final a = RentalApplicationItem.fromMap('a', {'status': 'approved', 'occupants': 4});
      expect(a.canCreateLease, isTrue);
      expect(a.occupants, 4);
      expect(RentalApplicationItem.fromMap('a', {'status': 'approved', 'lease_id': 'l'}).canCreateLease, isFalse);
    });
  });
}
