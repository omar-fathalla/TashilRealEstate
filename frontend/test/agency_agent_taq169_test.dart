// TAQ-169: the AgencyAgent role in the app: routing, the agency workspace without admin-only
// controls, the AgencyAdmin's team tab and the invitee's invite card.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/auth/trusted_role.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_dashboard.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_staff_scope.dart';
import 'package:tashil_real_estate/features/agency_workspace/services/agency_identity.dart';
import 'package:tashil_real_estate/features/agency_workspace/services/agency_team_service.dart';
import 'package:tashil_real_estate/features/agency_workspace/views/agency_team_view.dart';
import 'package:tashil_real_estate/features/agency_workspace/widgets/agency_invites_card.dart';

import 'agency_ux_test.dart' show FakeIdentitySource, pumpApp, sara;

class FakeTeamBackend implements AgencyTeamBackend {
  AgencyTeam team;
  List<AgencyInviteItem> mine;
  final calls = <String>[];
  Object? failWith;

  FakeTeamBackend({this.team = const AgencyTeam(), this.mine = const []});

  Future<void> _record(String call) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
  }

  @override
  Future<AgencyTeam> listTeam() async => team;
  @override
  Future<void> invite(String email) => _record('invite:$email');
  @override
  Future<void> revokeInvite(String inviteId) => _record('revoke:$inviteId');
  @override
  Future<void> removeAgent(String uid) => _record('remove:$uid');
  @override
  Future<List<AgencyInviteItem>> myInvites() async => mine;
  @override
  Future<void> acceptInvite(String inviteId) => _record('accept:$inviteId');
  @override
  Future<void> declineInvite(String inviteId) => _record('decline:$inviteId');
}

const agent = AgencyIdentity(
  displayName: 'Omar Agent',
  email: 'omar@agency.example',
  agencyId: 'ag1',
  agencyName: 'Marina Realty',
  isAgent: true,
);

void desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('role and routes', () {
    test('AgencyAgent counts only as a claim', () {
      expect(TrustedRole.fromSources(claimRole: 'AgencyAgent'), 'AgencyAgent');
      expect(TrustedRole.fromSources(profileRole: 'AgencyAgent'), '');
    });

    test('an agent opens /agency and nothing admin-only', () {
      expect(RouteAccess.canAccess('/agency', TrustedRole.agencyAgent), isTrue);
      expect(RouteAccess.homeFor(TrustedRole.agencyAgent), '/agency');
      for (final path in ['/admin', '/super-admin', '/owner', '/fast-onboarding', '/payment-schedule']) {
        expect(RouteAccess.canAccess(path, TrustedRole.agencyAgent), isFalse, reason: path);
      }
    });

    testWidgets('AgencyStaffScope is false outside the agency workspace', (tester) async {
      final seen = <bool>[];
      Widget probe() => Builder(builder: (context) {
            seen.add(AgencyStaffScope.isAgentOf(context));
            return const SizedBox();
          });
      await tester.pumpWidget(probe());
      await tester.pumpWidget(AgencyStaffScope(isAgent: true, child: probe()));
      expect(seen, [false, true]);
      expect(const AgencyIdentity().isAgent, isFalse);
    });
  });

  group('agency workspace', () {
    testWidgets('an agent gets no Financials or Team entries', (tester) async {
      desktop(tester);
      await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(agent)));
      expect(find.byIcon(Icons.analytics_outlined), findsNothing);
      expect(find.byIcon(Icons.groups_outlined), findsNothing);
      expect(find.text('Add Property'), findsNothing);
      expect(find.textContaining('Agency agent'), findsWidgets);
    });

    testWidgets('the AgencyAdmin still has Financials and gets Team', (tester) async {
      desktop(tester);
      await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(sara)));
      expect(find.byIcon(Icons.analytics_outlined), findsWidgets);
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    });

    testWidgets('an agent phone bar shows rent collection instead of financials', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpApp(tester, AgencyDashboard(identitySource: FakeIdentitySource(agent)));
      final bar = find.byType(NavigationBar);
      expect(find.descendant(of: bar, matching: find.byIcon(Icons.analytics_outlined)), findsNothing);
      expect(find.descendant(of: bar, matching: find.byIcon(Icons.payments_outlined)), findsOneWidget);
    });
  });

  group('team tab', () {
    testWidgets('lists agents and invites, invites, revokes and removes', (tester) async {
      desktop(tester);
      final backend = FakeTeamBackend(
        team: const AgencyTeam(
          agents: [AgencyAgentItem(uid: 'u1', email: 'a@x.test', displayName: 'Ali')],
          invites: [AgencyInviteItem(id: 'i1', email: 'b@x.test')],
        ),
      );
      await pumpApp(tester, SizedBox(width: 900, height: 700, child: AgencyTeamView(backend: backend)));
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('b@x.test'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('agencyTeamEmail')), ' new@x.test ');
      await tester.tap(find.byKey(const Key('agencyTeamInviteButton')));
      await tester.pumpAndSettle();
      expect(backend.calls, ['invite:new@x.test']);

      await tester.tap(find.text('Cancel invite'));
      await tester.pumpAndSettle();
      expect(backend.calls.last, 'revoke:i1');

      await tester.tap(find.descendant(of: find.byKey(const ValueKey('agencyAgent_u1')), matching: find.text('Remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Remove')).last);
      await tester.pumpAndSettle();
      expect(backend.calls.last, 'remove:u1');
    });

    testWidgets('shows the empty states in Arabic', (tester) async {
      desktop(tester);
      await pumpApp(tester, SizedBox(width: 900, height: 700, child: AgencyTeamView(backend: FakeTeamBackend())), locale: const Locale('ar'));
      expect(find.text('لا يوجد وكلاء بعد.'), findsOneWidget);
      expect(find.text('لا توجد دعوات مفتوحة.'), findsOneWidget);
    });
  });

  group('invite card', () {
    testWidgets('shows nothing without invites', (tester) async {
      await pumpApp(tester, AgencyInvitesCard(backend: FakeTeamBackend()));
      expect(find.byKey(const Key('agencyInvitesCard')), findsNothing);
    });

    testWidgets('accepting calls the server and signs out', (tester) async {
      desktop(tester);
      var signedOut = false;
      final backend = FakeTeamBackend(mine: const [AgencyInviteItem(id: 'i9', agencyName: 'Marina Realty')]);
      await pumpApp(
        tester,
        SizedBox(width: 600, child: AgencyInvitesCard(backend: backend, signOut: () async => signedOut = true)),
      );
      expect(find.text('Marina Realty invited you to join as an agent.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('agencyInviteAccept_i9')));
      await tester.pumpAndSettle();
      expect(backend.calls, ['accept:i9']);
      expect(signedOut, isTrue);
    });

    testWidgets('declining calls the server and stays signed in', (tester) async {
      desktop(tester);
      var signedOut = false;
      final backend = FakeTeamBackend(mine: const [AgencyInviteItem(id: 'i9', agencyName: 'Marina Realty')]);
      await pumpApp(
        tester,
        SizedBox(width: 600, child: AgencyInvitesCard(backend: backend, signOut: () async => signedOut = true)),
      );
      await tester.tap(find.byKey(const ValueKey('agencyInviteDecline_i9')));
      await tester.pumpAndSettle();
      expect(backend.calls, ['decline:i9']);
      expect(signedOut, isFalse);
    });
  });
}
