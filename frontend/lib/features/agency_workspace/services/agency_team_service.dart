import 'package:cloud_functions/cloud_functions.dart';
import 'package:tashil_real_estate/core/services/session_guard.dart';

/// An agent of the agency (TAQ-169).
class AgencyAgentItem {
  final String uid;
  final String email;
  final String displayName;

  const AgencyAgentItem({required this.uid, required this.email, this.displayName = ''});

  String get label => displayName.trim().isNotEmpty ? displayName.trim() : email;

  factory AgencyAgentItem.fromMap(Map<dynamic, dynamic> m) => AgencyAgentItem(
        uid: '${m['uid'] ?? ''}',
        email: '${m['email'] ?? ''}',
        displayName: '${m['displayName'] ?? ''}',
      );
}

/// An open invite, as the agency sees it or as the invitee sees it.
class AgencyInviteItem {
  final String id;
  final String email;
  final String agencyName;
  final DateTime? expiresAt;

  const AgencyInviteItem({required this.id, this.email = '', this.agencyName = '', this.expiresAt});

  factory AgencyInviteItem.fromMap(Map<dynamic, dynamic> m) {
    final expires = m['expiresAt'];
    return AgencyInviteItem(
      id: '${m['id'] ?? ''}',
      email: '${m['email'] ?? ''}',
      agencyName: '${m['agencyName'] ?? ''}',
      expiresAt: expires is num ? DateTime.fromMillisecondsSinceEpoch(expires.toInt()) : null,
    );
  }
}

class AgencyTeam {
  final List<AgencyAgentItem> agents;
  final List<AgencyInviteItem> invites;
  const AgencyTeam({this.agents = const [], this.invites = const []});
}

/// The agency_team.js callables. Tests pass a fake.
abstract class AgencyTeamBackend {
  Future<AgencyTeam> listTeam();
  Future<void> invite(String email);
  Future<void> revokeInvite(String inviteId);
  Future<void> removeAgent(String uid);
  Future<List<AgencyInviteItem>> myInvites();
  Future<void> acceptInvite(String inviteId);
  Future<void> declineInvite(String inviteId);
}

class FirebaseAgencyTeamBackend implements AgencyTeamBackend {
  FirebaseFunctions get _fn => FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<dynamic, dynamic>> _call(String name, [Map<String, dynamic> data = const {}]) async {
    final result = await SessionGuard.instance.run(() => _fn.httpsCallable(name).call<dynamic>(data));
    final value = result.data;
    return value is Map ? value : const {};
  }

  static List<Map<dynamic, dynamic>> _list(Object? value) =>
      value is List ? value.whereType<Map<dynamic, dynamic>>().toList() : const [];

  @override
  Future<AgencyTeam> listTeam() async {
    final data = await _call('listAgencyTeam');
    return AgencyTeam(
      agents: _list(data['agents']).map(AgencyAgentItem.fromMap).toList(),
      invites: _list(data['invites']).map(AgencyInviteItem.fromMap).toList(),
    );
  }

  @override
  Future<void> invite(String email) => _call('inviteAgencyAgent', {'email': email});

  @override
  Future<void> revokeInvite(String inviteId) => _call('revokeAgencyInvite', {'inviteId': inviteId});

  @override
  Future<void> removeAgent(String uid) => _call('removeAgencyAgent', {'uid': uid});

  @override
  Future<List<AgencyInviteItem>> myInvites() async =>
      _list((await _call('listMyAgencyInvites'))['invites']).map(AgencyInviteItem.fromMap).toList();

  @override
  Future<void> acceptInvite(String inviteId) => _call('acceptAgencyInvite', {'inviteId': inviteId});

  @override
  Future<void> declineInvite(String inviteId) => _call('declineAgencyInvite', {'inviteId': inviteId});
}

/// The translation key for a refused team call.
String agencyTeamErrorKey(Object error) {
  if (error is FirebaseFunctionsException) {
    final details = error.details;
    final reason = details is Map ? details['reason'] : null;
    switch (reason) {
      case 'invite_exists':
        return 'agencyTeamInviteExists';
      case 'too_many_invites':
      case 'too_many_agents':
      case 'invite_daily_limit':
        return 'agencyTeamLimit';
      case 'email_invalid':
      case 'self_invite':
        return 'agencyTeamEmailInvalid';
      case 'email_not_verified':
        return 'agencyInviteVerifyEmail';
      case 'applicant_has_open_leases':
      case 'applicant_has_mandates':
      case 'role_not_self_service':
        return 'agencyInviteBlocked';
      case 'invite_not_open':
        return 'agencyInviteClosed';
    }
  }
  return 'agencyTeamError';
}
