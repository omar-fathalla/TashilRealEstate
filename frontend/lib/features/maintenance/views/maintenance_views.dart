import 'package:flutter/material.dart';

import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../models/maintenance_ticket.dart';
import '../services/maintenance_service.dart';
import '../widgets/maintenance_ticket_card.dart';
import '../widgets/new_maintenance_dialog.dart';

List<MaintenanceTicket> _newestFirst(List<MaintenanceTicket>? items) {
  final list = [...?items];
  list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
  return list;
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// The tenant's maintenance requests, with a "+" button to send a new one.
class TenantMaintenanceView extends StatelessWidget {
  final MaintenanceService? service;
  const TenantMaintenanceView({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final svc = service ?? MaintenanceService.instance;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: TashilFloatingActionButton(
            icon: Icons.add,
            tooltip: loc.tr('mtNewRequest'),
            onPressed: () async {
              final sent = await NewMaintenanceDialog.show(context, service: svc);
              if (sent == true && context.mounted) {
                TashilSnackBar.showSuccess(context: context, message: loc.tr('mtSent'));
              }
            },
          ),
          body: Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.tr('maintenanceTickets'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<List<MaintenanceTicket>>(
                    stream: svc.streamMine(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final tickets = _newestFirst(snapshot.data);
                      if (tickets.isEmpty) return _EmptyState(loc.tr('mtEmptyTenant'));
                      return ListView(children: [for (final t in tickets) MaintenanceTicketCard(key: ValueKey(t.id), ticket: t)]);
                    },
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

/// Requests addressed to the signed-in owner or agency, with status updates.
class MaintenanceManagerView extends StatefulWidget {
  final bool agency;
  final MaintenanceService? service;
  final Widget? headerAction;

  const MaintenanceManagerView({super.key, this.agency = false, this.service, this.headerAction});

  @override
  State<MaintenanceManagerView> createState() => _MaintenanceManagerViewState();
}

class _MaintenanceManagerViewState extends State<MaintenanceManagerView> {
  late final MaintenanceService _service = widget.service ?? MaintenanceService.instance;
  late final Stream<List<MaintenanceTicket>> _stream = _service.streamForManager(agency: widget.agency);
  final Set<String> _busy = {};

  Future<void> _setStatus(MaintenanceTicket ticket, String status) async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy.add(ticket.id));
    try {
      await _service.setStatus(ticket.id, status);
      if (mounted) TashilSnackBar.showSuccess(context: context, message: loc.tr('mtUpdated'));
    } catch (_) {
      if (mounted) TashilSnackBar.showError(context: context, message: loc.tr('mtUpdateFailed'));
    } finally {
      if (mounted) setState(() => _busy.remove(ticket.id));
    }
  }

  Widget? _actions(MaintenanceTicket t, AppLocalizations loc) {
    if (t.status == 'escalated') return null;
    final busy = _busy.contains(t.id);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (t.status == 'pending')
          TashilButton(label: loc.tr('mtMarkInProgress'), icon: Icons.build_outlined, isLoading: busy, onPressed: busy ? null : () => _setStatus(t, 'in_progress')),
        if (t.status != 'resolved')
          TashilButton(label: loc.tr('mtMarkResolved'), icon: Icons.check_circle_outline, variant: TashilButtonVariant.tonal, isLoading: busy, onPressed: busy ? null : () => _setStatus(t, 'resolved')),
        if (t.status == 'resolved')
          TashilButton(label: loc.tr('mtReopen'), icon: Icons.refresh_rounded, variant: TashilButtonVariant.outlined, isLoading: busy, onPressed: busy ? null : () => _setStatus(t, 'pending')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsetsDirectional.all(24),
          children: [
            Row(
              children: [
                Expanded(child: Text(loc.tr('maintenanceTickets'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                if (widget.headerAction != null) widget.headerAction!,
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<MaintenanceTicket>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsetsDirectional.all(32), child: Center(child: CircularProgressIndicator()));
                }
                final tickets = _newestFirst(snapshot.data);
                if (tickets.isEmpty) return _EmptyState(loc.tr('mtEmptyManager'));
                return Column(
                  children: [
                    for (final t in tickets)
                      MaintenanceTicketCard(key: ValueKey(t.id), ticket: t, showTenant: true, actions: _actions(t, loc)),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
