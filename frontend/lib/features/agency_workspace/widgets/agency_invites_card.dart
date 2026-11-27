import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/features/agency_workspace/services/agency_team_service.dart';

/// Open agency invites for the signed-in user's verified email (TAQ-169). Shows nothing when
/// there are none. Accepting makes the user that agency's agent; their sign-in is revoked by the
/// server, so they sign in again to open the agency workspace.
class AgencyInvitesCard extends StatefulWidget {
  final AgencyTeamBackend? backend;

  /// Signs the user out after they join. Tests pass a fake.
  final Future<void> Function()? signOut;

  const AgencyInvitesCard({super.key, this.backend, this.signOut});

  @override
  State<AgencyInvitesCard> createState() => _AgencyInvitesCardState();
}

class _AgencyInvitesCardState extends State<AgencyInvitesCard> {
  late final AgencyTeamBackend _backend = widget.backend ?? FirebaseAgencyTeamBackend();
  List<AgencyInviteItem> _invites = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invites = await _backend.myInvites();
      if (mounted) setState(() => _invites = invites);
    } catch (_) {
      // No verified email or no connection: nothing to show.
    }
  }

  Future<void> _answer(AgencyInviteItem invite, {required bool accept}) async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (accept) {
        await _backend.acceptInvite(invite.id);
      } else {
        await _backend.declineInvite(invite.id);
      }
      if (!mounted) return;
      TashilSnackBar.showSuccess(context: context, message: loc.tr(accept ? 'agencyInviteAccepted' : 'agencyInviteDeclined'));
      if (accept) {
        await (widget.signOut ?? FirebaseAuthService().signOut)();
        return;
      }
      await _load();
    } catch (e) {
      if (mounted) TashilSnackBar.showError(context: context, message: loc.tr(agencyTeamErrorKey(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_invites.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 20),
      child: TashilCard.outlined(
        key: const Key('agencyInvitesCard'),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.tr('agencyInvitesTitle'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final invite in _invites) ...[
                Text(loc.tr('agencyInviteFrom').replaceAll('{agency}', invite.agencyName)),
                const SizedBox(height: 4),
                Text(loc.tr('agencyInviteNote'), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TashilButton.filled(
                      key: ValueKey('agencyInviteAccept_${invite.id}'),
                      label: loc.tr('agencyInviteAccept'),
                      onPressed: _busy ? null : () => _answer(invite, accept: true),
                    ),
                    TashilButton.outlined(
                      key: ValueKey('agencyInviteDecline_${invite.id}'),
                      label: loc.tr('agencyInviteDecline'),
                      onPressed: _busy ? null : () => _answer(invite, accept: false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
