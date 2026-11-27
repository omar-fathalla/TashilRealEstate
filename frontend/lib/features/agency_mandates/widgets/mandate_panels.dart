import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/callable_error.dart';
import 'package:tashil_real_estate/features/agency_mandates/models/mandate_models.dart';
import 'package:tashil_real_estate/features/agency_mandates/services/mandate_service.dart';
import 'package:tashil_real_estate/features/agency_mandates/widgets/mandate_stream.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';

/// Runs a mandate or application call and says how it went.
Future<bool> runMandateCall(BuildContext context, Future<void> Function() call, String successKey) async {
  final loc = AppLocalizations.of(context);
  try {
    await call();
    if (context.mounted) TashilSnackBar.showSuccess(context: context, message: loc.tr(successKey));
    return true;
  } catch (e) {
    if (context.mounted) {
      TashilSnackBar.showError(context: context, message: loc.tr(mandateErrorKey(describeCallableError(e).reason)));
    }
    return false;
  }
}

Future<bool> _confirm(BuildContext context, String titleKey, String bodyKey) async {
  final loc = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(loc.tr(titleKey)),
      content: Text(loc.tr(bodyKey)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(loc.tr('cancel'))),
        FilledButton(key: const ValueKey('mandate_confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: Text(loc.tr('mdRevoke'))),
      ],
    ),
  );
  return ok == true;
}

/// The owner's invites and active mandates (TAQ-149): accept or decline an agency's invite, or end
/// an agency's management. Shows nothing when there are none, or while signed out.
class OwnerMandatesPanel extends StatelessWidget {
  final MandateService? service;
  final DateTime Function()? now;

  const OwnerMandatesPanel({super.key, this.service, this.now});

  @override
  Widget build(BuildContext context) {
    final svc = service ?? MandateService.instance;
    final uid = svc.backend.currentUserId;
    if (uid == null) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MandateStream<List<PropertyMandate>>(
      cacheKey: uid,
      open: () => svc.backend.watchOwnerMandates(uid),
      builder: (context, snapshot) {
        final today = (now ?? DateTime.now)();
        final items = (snapshot.data ?? const <PropertyMandate>[]).where((m) => m.isCurrent(today)).toList();
        if (snapshot.hasError || items.isEmpty) return const SizedBox.shrink();
        return Card(
          key: const ValueKey('owner_mandates_panel'),
          margin: const EdgeInsetsDirectional.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.tr('mdOwnerTitle'), style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final m in items)
                  ListTile(
                    contentPadding: EdgeInsetsDirectional.zero,
                    leading: Icon(m.isActive ? Icons.handshake_outlined : Icons.mail_outline_rounded),
                    title: Text(m.propertyTitle.isEmpty ? m.propertyId : m.propertyTitle),
                    subtitle: Text('${loc.tr(m.isActive ? 'mdManagedBy' : 'mdInvitedBy')} ${m.agencyName}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: m.isActive
                          ? [
                              TextButton(
                                key: ValueKey('mandate_revoke_${m.propertyId}'),
                                onPressed: () async {
                                  if (await _confirm(context, 'mdRevokeConfirmTitle', 'mdRevokeConfirmBody') && context.mounted) {
                                    await runMandateCall(context, () => svc.revoke(m.propertyId), 'mdRevoked');
                                  }
                                },
                                child: Text(loc.tr('mdRevoke')),
                              ),
                            ]
                          : [
                              TextButton(
                                key: ValueKey('mandate_decline_${m.propertyId}'),
                                onPressed: () => runMandateCall(context, () => svc.respond(m.propertyId, accept: false), 'mdDeclined'),
                                child: Text(loc.tr('mdDecline')),
                              ),
                              FilledButton(
                                key: ValueKey('mandate_accept_${m.propertyId}'),
                                onPressed: () => runMandateCall(context, () => svc.respond(m.propertyId, accept: true), 'mdAccepted'),
                                child: Text(loc.tr('mdAccept')),
                              ),
                            ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The agency's side (TAQ-149): invite an owner by the property's id, and see, withdraw or end its
/// mandates. Shows nothing for an account without an agency.
class AgencyMandatesPanel extends StatefulWidget {
  final MandateService? service;

  /// The agency id; looked up from the signed-in account when not given.
  final String? agencyId;
  final DateTime Function()? now;

  const AgencyMandatesPanel({super.key, this.service, this.agencyId, this.now});

  @override
  State<AgencyMandatesPanel> createState() => _AgencyMandatesPanelState();
}

class _AgencyMandatesPanelState extends State<AgencyMandatesPanel> {
  late final MandateService _service = widget.service ?? MandateService.instance;
  final _propertyId = TextEditingController();
  String? _agencyId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _agencyId = widget.agencyId;
    if (_agencyId == null) _lookUpAgency();
  }

  Future<void> _lookUpAgency() async {
    try {
      final scope = await PortfolioDataService.instance.scopeFor(agencyOnly: true);
      if (mounted && scope != null && scope.isAgency) setState(() => _agencyId = scope.value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _propertyId.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final id = _propertyId.text.trim();
    if (id.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await runMandateCall(context, () => _service.invite(id), 'mdInviteSent');
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _propertyId.clear();
  }

  @override
  Widget build(BuildContext context) {
    final agencyId = _agencyId;
    if (agencyId == null || agencyId.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('agency_mandates_panel'),
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.tr('mdAgencyTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(loc.tr('mdAgencyHelp'), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('mandate_invite_field'),
                    controller: _propertyId,
                    enabled: !_sending,
                    decoration: InputDecoration(labelText: loc.tr('mdPropertyIdField'), border: const OutlineInputBorder(), isDense: true),
                    onSubmitted: (_) => _invite(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  key: const ValueKey('mandate_invite_send'),
                  onPressed: _sending ? null : _invite,
                  child: Text(loc.tr('mdInvite')),
                ),
              ],
            ),
            MandateStream<List<PropertyMandate>>(
              cacheKey: agencyId,
              open: () => _service.backend.watchAgencyMandates(agencyId),
              builder: (context, snapshot) {
                final today = (widget.now ?? DateTime.now)();
                final items = (snapshot.data ?? const <PropertyMandate>[]).where((m) => m.isCurrent(today)).toList();
                return Column(
                  children: [
                    for (final m in items)
                      ListTile(
                        contentPadding: EdgeInsetsDirectional.zero,
                        title: Text(m.propertyTitle.isEmpty ? m.propertyId : m.propertyTitle),
                        subtitle: Text('${m.propertyId} · ${loc.tr(m.isActive ? 'mdStatusActive' : 'mdStatusInvited')}'),
                        trailing: TextButton(
                          key: ValueKey('mandate_revoke_${m.propertyId}'),
                          onPressed: () async {
                            if (m.isActive && !await _confirm(context, 'mdRevokeConfirmTitle', 'mdRevokeConfirmBody')) return;
                            if (context.mounted) await runMandateCall(context, () => _service.revoke(m.propertyId), 'mdRevoked');
                          },
                          child: Text(loc.tr(m.isActive ? 'mdEnd' : 'mdWithdraw')),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
