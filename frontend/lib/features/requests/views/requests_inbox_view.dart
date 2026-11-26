import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/cards/tashil_cards.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../models/request_models.dart';
import '../services/requests_service.dart';
import '../widgets/request_inline_error.dart';

/// The owner's or agency's inbox of viewing requests and rental applications (TAQ-112).
/// Confirm, decline, approve and reject go through the server so the requester is notified.
class RequestsInboxView extends StatefulWidget {
  final bool agency;
  final RequestsService? service;

  const RequestsInboxView({super.key, this.agency = false, this.service});

  @override
  State<RequestsInboxView> createState() => _RequestsInboxViewState();
}

class _RequestsInboxViewState extends State<RequestsInboxView> {
  late final RequestsService _service = widget.service ?? RequestsService.instance;
  late final Future<RequestScope?> _scope = _service.inboxScope(agency: widget.agency);
  String _tab = 'viewings';
  final Set<String> _busy = {};

  Future<void> _run(String id, Future<void> Function() action, String successKey) async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy.add(id));
    try {
      await action();
      if (mounted) TashilSnackBar.showSuccess(context: context, message: loc.tr(successKey));
    } catch (e) {
      if (mounted) TashilSnackBar.showError(context: context, message: loc.tr(requestErrorKey(e)));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  /// Confirm, decline, approve or reject with an optional note to the requester. The dialog sends
  /// the answer itself and shows a rejection (for example a note with a phone number) inside the
  /// dialog, so it stays open with the note kept (TAQ-132). [onSend] gets the trimmed note.
  Future<void> _respond({
    required String actionLabel,
    required String successKey,
    required Future<void> Function(String note) onSend,
  }) async {
    final loc = AppLocalizations.of(context);
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _RespondDialog(actionLabel: actionLabel, onSend: onSend),
    );
    if (!mounted) return;
    if (sent == true) TashilSnackBar.showSuccess(context: context, message: loc.tr(successKey));
  }

  Future<void> _openWhatsApp(String phone, String title) async {
    final loc = AppLocalizations.of(context);
    final uri = whatsAppUri(phone, message: title.isEmpty ? null : title);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!opened && mounted) {
      TashilSnackBar.showError(context: context, message: loc.tr('rqFailed'));
    }
  }

  Future<void> _createLease(RentalApplicationItem item) async {
    final input = await showDialog<_LeaseInput>(context: context, builder: (_) => const _LeaseDraftDialog());
    if (input == null) return;
    await _run(
      item.id,
      () => _service.createLeaseDraft(
        applicationId: item.id,
        startDate: input.start,
        endDate: input.end,
        monthlyRent: input.rent,
      ),
      'rqLeaseDraftCreated',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return FutureBuilder<RequestScope?>(
          future: _scope,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final scope = snapshot.data;
            if (scope == null) return _Empty(message: loc.tr('rqEmptyInbox'));
            return ListView(
              padding: const EdgeInsetsDirectional.all(16),
              children: [
                Text(loc.tr('rqInboxTitle'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TashilConnectedButtonGroup<String>(
                  selectedValue: _tab,
                  onSelectionChanged: (v) => setState(() => _tab = v),
                  segments: [
                    TashilConnectedButtonSegment(value: 'viewings', label: loc.tr('rqViewingsTab'), icon: Icons.event_available_outlined),
                    TashilConnectedButtonSegment(value: 'applications', label: loc.tr('rqApplicationsTab'), icon: Icons.assignment_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                if (_tab == 'viewings') _viewings(scope, loc, locale) else _applications(scope, loc, locale),
              ],
            );
          },
        );
      },
    );
  }

  Widget _viewings(RequestScope scope, AppLocalizations loc, Locale locale) {
    return StreamBuilder<List<ViewingRequestItem>>(
      stream: _service.watchViewings(scope),
      builder: (context, snapshot) {
        final items = [...?snapshot.data]..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        if (items.isEmpty) return _Empty(message: loc.tr('rqEmptyViewings'));
        return Column(
          children: [
            for (final item in items)
              _RequestCard(
                key: ValueKey('viewing_${item.id}'),
                title: item.titleFor(locale.languageCode),
                name: item.requesterName,
                phone: item.requesterPhone,
                status: item.status,
                details: [
                  if (item.preferredDate.isNotEmpty) '${loc.tr('rqPreferredDate')}: ${item.preferredDate}',
                  if (item.message.isNotEmpty) item.message,
                ],
                busy: _busy.contains(item.id),
                onWhatsApp: () => _openWhatsApp(item.requesterPhone, item.titleFor(locale.languageCode)),
                actions: item.isPending
                    ? [
                        _Action(loc.tr('rqConfirm'), Icons.check_rounded, () => _respond(actionLabel: loc.tr('rqConfirm'), successKey: 'rqViewingConfirmed', onSend: (note) => _service.respondToViewing(item.id, confirm: true, note: note))),
                        _Action(loc.tr('rqDecline'), Icons.close_rounded, () => _respond(actionLabel: loc.tr('rqDecline'), successKey: 'rqViewingDeclined', onSend: (note) => _service.respondToViewing(item.id, confirm: false, note: note)), outlined: true),
                      ]
                    : const [],
              ),
          ],
        );
      },
    );
  }

  Widget _applications(RequestScope scope, AppLocalizations loc, Locale locale) {
    return StreamBuilder<List<RentalApplicationItem>>(
      stream: _service.watchApplications(scope),
      builder: (context, snapshot) {
        final items = [...?snapshot.data]..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        if (items.isEmpty) return _Empty(message: loc.tr('rqEmptyApplications'));
        return Column(
          children: [
            for (final item in items)
              if (item.leaseId.isEmpty)
                _applicationCard(item, loc, locale, '')
              else
                StreamBuilder<String>(
                  key: ValueKey('application_${item.id}'),
                  stream: _service.watchLeaseStatus(item.leaseId),
                  builder: (context, lease) => _applicationCard(item, loc, locale, lease.data ?? ''),
                ),
          ],
        );
      },
    );
  }

  Widget _applicationCard(RentalApplicationItem item, AppLocalizations loc, Locale locale, String leaseStatus) {
    return _RequestCard(
      key: ValueKey('application_card_${item.id}'),
      title: item.titleFor(locale.languageCode),
      name: item.applicantName,
      phone: item.applicantPhone,
      status: item.status,
      details: [
        if (item.moveInDate.isNotEmpty) '${loc.tr('rqMoveInDate')}: ${item.moveInDate}',
        '${loc.tr('rqOccupants')}: ${item.occupants}',
        if (item.message.isNotEmpty) item.message,
      ],
      busy: _busy.contains(item.id),
      onWhatsApp: () => _openWhatsApp(item.applicantPhone, item.titleFor(locale.languageCode)),
      actions: [
        if (item.isPending) ...[
          _Action(loc.tr('rqApprove'), Icons.check_rounded, () => _respond(actionLabel: loc.tr('rqApprove'), successKey: 'rqApplicationApproved', onSend: (note) => _service.decideApplication(item.id, approve: true, note: note))),
          _Action(loc.tr('rqReject'), Icons.close_rounded, () => _respond(actionLabel: loc.tr('rqReject'), successKey: 'rqApplicationRejected', onSend: (note) => _service.decideApplication(item.id, approve: false, note: note)), outlined: true),
        ],
        if (item.canCreateLease) _Action(loc.tr('rqCreateLeaseDraft'), Icons.description_outlined, () => _createLease(item)),
        if (item.leaseId.isNotEmpty && leaseStatus == 'draft')
          _Action(loc.tr('tnSendLeaseOffer'), Icons.send_rounded, () => _run(item.id, () => _service.sendLeaseOffer(item.leaseId), 'tnLeaseOfferSent')),
        if (item.leaseId.isNotEmpty && leaseStatus != 'draft')
          _Action(
            leaseStatus.isEmpty
                ? loc.tr('rqLeaseDraftCreated')
                : loc.tr(leaseStatus == 'pending_tenant_approval' ? 'tnOfferAwaitingTenant' : 'tnLeaseStatus_$leaseStatus'),
            Icons.task_alt_rounded,
            null,
            outlined: true,
          ),
      ],
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;
  const _Action(this.label, this.icon, this.onPressed, {this.outlined = false});
}

class _RequestCard extends StatelessWidget {
  final String title;
  final String name;
  final String phone;
  final String status;
  final List<String> details;
  final bool busy;
  final VoidCallback onWhatsApp;
  final List<_Action> actions;

  const _RequestCard({
    super.key,
    required this.title,
    required this.name,
    required this.phone,
    required this.status,
    required this.details,
    required this.busy,
    required this.onWhatsApp,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: TashilCard.outlined(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.isEmpty ? name : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.person_outline, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.phone_outlined, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Text(phone, style: theme.textTheme.bodyMedium))),
            ]),
            for (final line in details)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Text(line, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions)
                  TashilButton(
                    label: action.label,
                    icon: action.icon,
                    variant: action.outlined ? TashilButtonVariant.outlined : TashilButtonVariant.filled,
                    isLoading: busy,
                    onPressed: busy ? null : action.onPressed,
                  ),
                TashilButton(
                  label: loc.tr('rqWhatsApp'),
                  icon: Icons.chat_bubble_outline_rounded,
                  variant: TashilButtonVariant.tonal,
                  onPressed: phone.isEmpty ? null : onWhatsApp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final good = status == 'confirmed' || status == 'approved';
    final bad = status == 'declined' || status == 'rejected';
    final background = good ? scheme.primaryContainer : (bad ? scheme.errorContainer : scheme.secondaryContainer);
    final foreground = good ? scheme.onPrimaryContainer : (bad ? scheme.onErrorContainer : scheme.onSecondaryContainer);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(loc.tr('rqStatus_$status'), style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(32),
      child: Center(
        child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

class _RespondDialog extends StatefulWidget {
  final String actionLabel;
  final Future<void> Function(String note) onSend;
  const _RespondDialog({required this.actionLabel, required this.onSend});

  @override
  State<_RespondDialog> createState() => _RespondDialogState();
}

class _RespondDialogState extends State<_RespondDialog> {
  final _note = TextEditingController();
  final _errorKey = GlobalKey();
  bool _sending = false;
  String? _error;

  bool get _contactError => _error == 'rqContactInMessage';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSend(_note.text.trim());
      if (mounted) navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = requestErrorKey(e);
      });
      revealInlineError(_errorKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.actionLabel),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _note,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) {
                if (_contactError) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: loc.tr('rqResponseNoteOptional'),
                errorText: _contactError ? loc.tr('rqContactInMessageField') : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              RequestInlineError(key: _errorKey, message: loc.tr(_error!)),
            ],
          ],
        ),
      ),
      actions: [
        TashilButton(label: loc.tr('cancel'), variant: TashilButtonVariant.text, onPressed: _sending ? null : () => Navigator.of(context).pop(false)),
        TashilButton(label: widget.actionLabel, isLoading: _sending, onPressed: _sending ? null : _submit),
      ],
    );
  }
}

class _LeaseInput {
  final String start;
  final String end;
  final double? rent;
  const _LeaseInput(this.start, this.end, this.rent);
}

class _LeaseDraftDialog extends StatefulWidget {
  const _LeaseDraftDialog();

  @override
  State<_LeaseDraftDialog> createState() => _LeaseDraftDialogState();
}

class _LeaseDraftDialogState extends State<_LeaseDraftDialog> {
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _rent = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _rent.dispose();
    super.dispose();
  }

  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  void _submit() {
    final start = _start.text.trim();
    final end = _end.text.trim();
    final rentText = _rent.text.trim();
    final rent = rentText.isEmpty ? null : double.tryParse(rentText);
    final valid = _date.hasMatch(start) &&
        _date.hasMatch(end) &&
        end.compareTo(start) > 0 &&
        (rentText.isEmpty || (rent != null && rent > 0));
    if (!valid) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(_LeaseInput(start, end, rent));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.tr('rqCreateLeaseDraft')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _start, decoration: InputDecoration(labelText: loc.tr('rqLeaseStart'), hintText: loc.tr('rqDateHint')), keyboardType: TextInputType.datetime),
            TextField(controller: _end, decoration: InputDecoration(labelText: loc.tr('rqLeaseEnd'), hintText: loc.tr('rqDateHint')), keyboardType: TextInputType.datetime),
            TextField(controller: _rent, decoration: InputDecoration(labelText: loc.tr('rqMonthlyRentOptional')), keyboardType: TextInputType.number),
            if (_invalid)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: Text(loc.tr('rqInvalidInput'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TashilButton(label: loc.tr('cancel'), variant: TashilButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        TashilButton(label: loc.tr('rqCreateLeaseDraft'), onPressed: _submit),
      ],
    );
  }
}
