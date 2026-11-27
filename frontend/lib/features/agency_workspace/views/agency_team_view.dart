import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/agency_workspace/services/agency_team_service.dart';

/// The AgencyAdmin's team tab (TAQ-169): invite agents by email, see open invites and agents,
/// cancel an invite or remove an agent.
class AgencyTeamView extends StatefulWidget {
  final AgencyTeamBackend? backend;

  const AgencyTeamView({super.key, this.backend});

  @override
  State<AgencyTeamView> createState() => _AgencyTeamViewState();
}

class _AgencyTeamViewState extends State<AgencyTeamView> {
  late final AgencyTeamBackend _backend = widget.backend ?? FirebaseAgencyTeamBackend();
  final _email = TextEditingController();
  AgencyTeam _team = const AgencyTeam();
  bool _loading = true;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final team = await _backend.listTeam();
      if (mounted) setState(() => (_team = team, _failed = false, _loading = false));
    } catch (_) {
      if (mounted) setState(() => (_failed = true, _loading = false));
    }
  }

  Future<void> _run(Future<void> Function() action, String successKey) async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      TashilSnackBar.showSuccess(context: context, message: loc.tr(successKey));
      await _load();
    } catch (e) {
      if (mounted) TashilSnackBar.showError(context: context, message: loc.tr(agencyTeamErrorKey(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    await _run(() async {
      await _backend.invite(email);
      _email.clear();
    }, 'agencyTeamInvited');
  }

  Future<void> _remove(AgencyAgentItem agent) async {
    final loc = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('agencyTeamRemove')),
        content: Text('${loc.tr('agencyTeamRemoveConfirm')}\n${agent.label}'),
        actions: [
          TashilButton.text(label: loc.tr('cancel'), onPressed: () => Navigator.pop(ctx, false)),
          TashilButton.filled(label: loc.tr('agencyTeamRemove'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok == true) await _run(() => _backend.removeAgent(agent.uid), 'agencyTeamRemoved');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsetsDirectional.all(24),
      children: [
        Text(loc.tr('agencyTeamTitle'), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(loc.tr('agencyTeamSubtitle'), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        TashilCard.outlined(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('agencyTeamEmail'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: loc.tr('agencyTeamInviteHint'), border: const OutlineInputBorder()),
                    onSubmitted: (_) => _busy ? null : _invite(),
                  ),
                ),
                const SizedBox(width: 12),
                TashilButton.filled(
                  key: const Key('agencyTeamInviteButton'),
                  label: loc.tr('agencyTeamInvite'),
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: _busy ? null : _invite,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsetsDirectional.all(24), child: CircularProgressIndicator()))
        else if (_failed)
          Text(loc.tr('agencyTeamError'), style: TextStyle(color: colorScheme.error))
        else ...[
          Text(loc.tr('agencyTeamAgents'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_team.agents.isEmpty)
            Text(loc.tr('agencyTeamEmpty'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
          for (final agent in _team.agents)
            ListTile(
              key: ValueKey('agencyAgent_${agent.uid}'),
              leading: const Icon(Icons.badge_outlined),
              title: Text(agent.label),
              subtitle: agent.displayName.isNotEmpty ? Text(agent.email) : null,
              trailing: TashilButton.text(
                label: loc.tr('agencyTeamRemove'),
                onPressed: _busy ? null : () => _remove(agent),
              ),
            ),
          const SizedBox(height: 16),
          Text(loc.tr('agencyTeamPending'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_team.invites.isEmpty)
            Text(loc.tr('agencyTeamNoInvites'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
          for (final invite in _team.invites)
            ListTile(
              key: ValueKey('agencyInvite_${invite.id}'),
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text(invite.email),
              trailing: TashilButton.text(
                label: loc.tr('agencyTeamRevoke'),
                onPressed: _busy ? null : () => _run(() => _backend.revokeInvite(invite.id), 'agencyTeamRevoked'),
              ),
            ),
        ],
      ],
    );
  }
}
