import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/features/agency_mandates/models/mandate_models.dart';
import 'package:tashil_real_estate/features/agency_mandates/services/mandate_service.dart';
import 'package:tashil_real_estate/features/agency_mandates/widgets/agency_application_widgets.dart';
import 'package:tashil_real_estate/features/agency_mandates/widgets/mandate_panels.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/create_lease_dialog.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import 'support/portfolio_fakes.dart';

class FakeMandateBackend implements MandateBackend {
  String? uid;
  List<PropertyMandate> owner = const [];
  List<PropertyMandate> agency = const [];
  AgencyApplicationItem? application;
  List<AgencyApplicationItem> pending = const [];
  Object? failWith;
  final calls = <MapEntry<String, Map<String, dynamic>>>[];
  int opened = 0;

  FakeMandateBackend({this.uid = 'u1'});

  @override
  String? get currentUserId => uid;

  @override
  Stream<List<PropertyMandate>> watchOwnerMandates(String ownerId) {
    opened++;
    return Stream.value(owner);
  }

  @override
  Stream<List<PropertyMandate>> watchAgencyMandates(String agencyId) => Stream.value(agency);

  @override
  Stream<AgencyApplicationItem?> watchApplication(String uid) => Stream.value(application);

  @override
  Stream<List<AgencyApplicationItem>> watchPendingApplications() => Stream.value(pending);

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    calls.add(MapEntry(name, data));
    if (failWith != null) throw failWith!;
    return {'ok': true};
  }
}

final _now = DateTime(2026, 11, 27);
DateTime _clock() => _now;

PropertyMandate _invite(String id, {String status = 'invited', DateTime? expires}) => PropertyMandate(
      propertyId: id,
      ownerId: 'owner-1',
      agencyId: 'agM',
      agencyName: 'Marina Homes',
      propertyTitle: 'Title $id',
      pricePerMonth: 9000,
      status: status,
      expiresAt: expires ?? _now.add(const Duration(days: 10)),
    );

FirebaseFunctionsException _refusal(String reason) =>
    FirebaseFunctionsException(code: 'failed-precondition', message: 'server text', details: {'reason': reason});

void _big(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 1400);
  addTearDown(tester.view.reset);
}

Future<void> _openDialog(WidgetTester tester, Widget Function(BuildContext) dialog) async {
  await tester.pumpWidget(testApp(Builder(
    builder: (context) => TextButton(onPressed: () => showDialog<void>(context: context, builder: dialog), child: const Text('open')),
  )));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => CountryController.setCountry('AE'));
  tearDown(() => CountryController.setCountry('EG'));

  group('PropertyMandate', () {
    test('reads the server doc and knows open invites from expired ones', () {
      final m = PropertyMandate.fromMap('p1', {
        'owner_id': 'o',
        'agency_id': 'a',
        'status': 'invited',
        'country_code': 'EG',
        'price_per_month': 5000,
        'expires_at': DateTime(2026, 12, 1),
      });
      expect(m.countryCode, 'EG');
      expect(m.pricePerMonth, 5000);
      expect(m.isOpenInvite(DateTime(2026, 11, 30)), isTrue);
      expect(m.isOpenInvite(DateTime(2026, 12, 2)), isFalse);
      expect(PropertyMandate.fromMap('p2', {'status': 'active'}).isCurrent(DateTime(2030)), isTrue);
      expect(PropertyMandate.fromMap('p3', {'status': 'revoked'}).isCurrent(DateTime(2020)), isFalse);
    });

    test('maps server reasons to messages', () {
      expect(mandateErrorKey('mandate_lease_live'), 'mdLeaseLive');
      expect(mandateErrorKey('mandate_pending_other'), 'mdPendingOther');
      expect(mandateErrorKey('applicant_has_open_leases'), 'aaBlockedLeases');
      expect(mandateErrorKey('name_contact'), 'aaNameInvalid');
      // TAQ-208: a refused agency name says what was refused, in every language.
      expect(mandateErrorKey('name_phone'), 'aaNamePhone');
      expect(mandateErrorKey('name_link'), 'aaNameLink');
      expect(mandateErrorKey('name_email'), 'aaNameEmail');
      for (final lang in ['ar', 'en', 'hi']) {
        final loc = AppLocalizations(Locale(lang));
        for (final key in ['aaNamePhone', 'aaNameLink', 'aaNameEmail']) {
          expect(loc.tr(key), isNot(key), reason: '$lang $key');
        }
        expect(loc.tr('aaNamePhone'), isNot(loc.tr('aaNameLink')), reason: lang);
      }
      expect(mandateErrorKey('something_new'), 'mdFailed');
    });
  });

  group('OwnerMandatesPanel', () {
    testWidgets('shows nothing when signed out or with nothing current', (tester) async {
      final backend = FakeMandateBackend(uid: null);
      await tester.pumpWidget(testApp(OwnerMandatesPanel(service: MandateService(backend: backend), now: _clock)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('owner_mandates_panel')), findsNothing);

      final expired = FakeMandateBackend()..owner = [_invite('p1', expires: _now.subtract(const Duration(days: 1))), _invite('p2', status: 'declined')];
      await tester.pumpWidget(testApp(OwnerMandatesPanel(service: MandateService(backend: expired), now: _clock)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('owner_mandates_panel')), findsNothing);
    });

    testWidgets('accepts and declines an invite', (tester) async {
      _big(tester);
      final backend = FakeMandateBackend()..owner = [_invite('p1'), _invite('p2')];
      await tester.pumpWidget(testApp(OwnerMandatesPanel(service: MandateService(backend: backend), now: _clock)));
      await tester.pumpAndSettle();
      expect(find.text('Invitation to manage from Marina Homes'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('mandate_accept_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mandate_decline_p2')));
      await tester.pumpAndSettle();
      expect(backend.calls.map((c) => '${c.key}:${c.value['propertyId']}:${c.value['accept']}'), [
        'respondToMandate:p1:true',
        'respondToMandate:p2:false',
      ]);
    });

    testWidgets('ending a mandate asks first and explains a refusal', (tester) async {
      _big(tester);
      final backend = FakeMandateBackend()
        ..owner = [_invite('p1', status: 'active')]
        ..failWith = _refusal('mandate_lease_live');
      await tester.pumpWidget(testApp(OwnerMandatesPanel(service: MandateService(backend: backend), now: _clock)));
      await tester.pumpAndSettle();
      expect(find.text('Managed by Marina Homes'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mandate_revoke_p1')));
      await tester.pumpAndSettle();
      expect(find.text("End the agency's management?"), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(backend.calls, isEmpty);

      await tester.tap(find.byKey(const ValueKey('mandate_revoke_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mandate_confirm')));
      await tester.pumpAndSettle();
      expect(backend.calls.single.key, 'revokeMandate');
      expect(find.text('A running lease holds this property; wait until it ends.'), findsOneWidget);
    });

    testWidgets('a rebuild does not reopen the listener', (tester) async {
      final backend = FakeMandateBackend()..owner = [_invite('p1')];
      final svc = MandateService(backend: backend);
      final tick = ValueNotifier(0);
      await tester.pumpWidget(testApp(ValueListenableBuilder<int>(
        valueListenable: tick,
        builder: (_, v, __) => Column(children: [Text('$v'), OwnerMandatesPanel(service: svc, now: _clock)]),
      )));
      await tester.pumpAndSettle();
      tick.value = 1;
      await tester.pumpAndSettle();
      expect(backend.opened, 1);
    });
  });

  group('AgencyMandatesPanel', () {
    testWidgets('invites by property number and lists current mandates', (tester) async {
      _big(tester);
      final backend = FakeMandateBackend()..agency = [_invite('p1'), _invite('p2', status: 'active'), _invite('p3', status: 'revoked')];
      await tester.pumpWidget(testApp(SingleChildScrollView(child: AgencyMandatesPanel(service: MandateService(backend: backend), agencyId: 'agM', now: _clock))));
      await tester.pumpAndSettle();
      expect(find.text('p1 · Waiting for the owner'), findsOneWidget);
      expect(find.text('p2 · Managed by you'), findsOneWidget);
      expect(find.textContaining('p3'), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('mandate_invite_field')), '  p9 ');
      await tester.tap(find.byKey(const ValueKey('mandate_invite_send')));
      await tester.pumpAndSettle();
      expect(backend.calls.single.key, 'inviteMandate');
      expect(backend.calls.single.value['propertyId'], 'p9');
      expect(find.text('Invitation sent to the owner.'), findsOneWidget);
    });

    testWidgets('withdrawing an invite needs no confirmation; a refusal is explained', (tester) async {
      _big(tester);
      final backend = FakeMandateBackend()..agency = [_invite('p1')];
      await tester.pumpWidget(testApp(SingleChildScrollView(child: AgencyMandatesPanel(service: MandateService(backend: backend), agencyId: 'agM', now: _clock))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mandate_revoke_p1')));
      await tester.pumpAndSettle();
      expect(backend.calls.single.key, 'revokeMandate');

      backend.failWith = _refusal('mandate_pending_other');
      await tester.enterText(find.byKey(const ValueKey('mandate_invite_field')), 'p5');
      await tester.tap(find.byKey(const ValueKey('mandate_invite_send')));
      await tester.pumpAndSettle();
      expect(find.text("Another agency's invitation is waiting for the owner."), findsOneWidget);
    });

    testWidgets('shows nothing without an agency', (tester) async {
      await tester.pumpWidget(testApp(AgencyMandatesPanel(service: MandateService(backend: FakeMandateBackend()), agencyId: '')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('agency_mandates_panel')), findsNothing);
    });
  });

  group('AgencyApplicationDialog', () {
    testWidgets('submits the form', (tester) async {
      _big(tester);
      final backend = FakeMandateBackend();
      await _openDialog(tester, (_) => AgencyApplicationDialog(service: MandateService(backend: backend)));
      await tester.enterText(find.byKey(const ValueKey('aa_name')), 'Marina Homes');
      await tester.enterText(find.byKey(const ValueKey('aa_city')), 'Dubai');
      await tester.enterText(find.byKey(const ValueKey('aa_orn')), 'ORN-123');
      await tester.enterText(find.byKey(const ValueKey('aa_licence')), 'TL-9');
      await tester.enterText(find.byKey(const ValueKey('aa_phone')), '+971 50 000 0000');
      await tester.tap(find.byKey(const ValueKey('aa_submit')));
      await tester.pumpAndSettle();
      final call = backend.calls.single;
      expect(call.key, 'applyForAgency');
      expect(call.value, {
        'name': 'Marina Homes',
        'countryCode': 'AE',
        'phone': '+971 50 000 0000',
        'city': 'Dubai',
        'orn': 'ORN-123',
        'licenceNumber': 'TL-9',
      });
      expect(find.byType(AgencyApplicationDialog), findsNothing);
      expect(find.text('Your request was sent for review.'), findsOneWidget);
    });

    testWidgets('a pending request shows its status and no submit', (tester) async {
      final backend = FakeMandateBackend()..application = const AgencyApplicationItem(uid: 'u1', name: 'X');
      await _openDialog(tester, (_) => AgencyApplicationDialog(service: MandateService(backend: backend)));
      expect(find.text('Your request is being reviewed.'), findsOneWidget);
      expect(find.byKey(const ValueKey('aa_submit')), findsNothing);
    });

    testWidgets('a rejected request shows the note and can be sent again; a refusal stays open', (tester) async {
      _big(tester);
      final backend = FakeMandateBackend()
        ..application = const AgencyApplicationItem(uid: 'u1', status: 'rejected', reviewNote: 'Licence unclear.')
        ..failWith = _refusal('phone_invalid');
      await _openDialog(tester, (_) => AgencyApplicationDialog(service: MandateService(backend: backend)));
      expect(find.text('Your last request was declined. Licence unclear.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('aa_submit')));
      await tester.pumpAndSettle();
      expect(find.text('That phone number is not valid.'), findsOneWidget);
      expect(find.byType(AgencyApplicationDialog), findsOneWidget);
    });
  });

  group('AgencyApplicationsReviewPanel', () {
    testWidgets('approves and rejects with a note', (tester) async {
      _big(tester);
      final backend = FakeMandateBackend()
        ..pending = const [
          AgencyApplicationItem(uid: 'a1', name: 'Marina Homes', city: 'Dubai', orn: 'ORN-1', phone: '+97150'),
          AgencyApplicationItem(uid: 'a2', name: 'Nile Homes', countryCode: 'EG', phone: '+2010'),
        ];
      await tester.pumpWidget(testApp(AgencyApplicationsReviewPanel(service: MandateService(backend: backend))));
      await tester.pumpAndSettle();
      expect(find.text('Agency registration requests (2)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('aa_approve_a1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('aa_reject_a2')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('aa_reject_note')), 'No licence');
      await tester.tap(find.byKey(const ValueKey('aa_reject_confirm')));
      await tester.pumpAndSettle();
      expect(backend.calls.map((c) => c.value), [
        {'uid': 'a1', 'approve': true},
        {'uid': 'a2', 'approve': false, 'note': 'No licence'},
      ]);
    });

    testWidgets('shows nothing when no request waits', (tester) async {
      await tester.pumpWidget(testApp(AgencyApplicationsReviewPanel(service: MandateService(backend: FakeMandateBackend()))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('agency_applications_panel')), findsNothing);
    });
  });

  group('CreateLeaseDialog with mandates', () {
    testWidgets('offers a mandated property and sends its owner', (tester) async {
      _big(tester);
      final backend = FakePortfolioBackend(agency: 'agM');
      final requests = FakeRequestsBackendForPortfolio()
        ..applications = const [RentalApplicationItem(id: 'app1', listingId: 'm1', applicantId: 'tenant-9', applicantName: 'Sara Ali', status: 'approved')];
      await _openDialog(
        tester,
        (_) => CreateLeaseDialog(
          properties: [unit('p1', title: 'Own Unit')],
          service: PortfolioDataService(backend: backend),
          requests: RequestsService(backend: requests),
          now: () => DateTime(2026, 11, 26),
          mandates: [
            _invite('m1', status: 'active'),
            _invite('m2'), // still an invite: not offered
          ],
        ),
      );
      await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      expect(find.text('Title m2'), findsNothing);
      await tester.tap(find.text('Title m1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sara Ali').last);
      await tester.pumpAndSettle();
      final send = find.text('Send offer to tenant');
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(backend.created.single['propertyId'], 'm1');
      expect(backend.created.single['ownerId'], 'owner-1');
      expect(backend.created.single['monthlyRent'], 9000.0);
    });

    testWidgets('looks up the agency mandates when not given', (tester) async {
      _big(tester);
      final previous = MandateService.instance;
      addTearDown(() => MandateService.instance = previous);
      MandateService.instance = MandateService(backend: FakeMandateBackend()..agency = [_invite('m1', status: 'active')]);
      final backend = FakePortfolioBackend(agency: 'agM');
      await _openDialog(
        tester,
        (_) => CreateLeaseDialog(
          properties: [unit('p1', title: 'Own Unit')],
          service: PortfolioDataService(backend: backend),
          requests: RequestsService(backend: FakeRequestsBackendForPortfolio()),
        ),
      );
      await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      expect(find.text('Title m1'), findsWidgets);
    });
  });
}
