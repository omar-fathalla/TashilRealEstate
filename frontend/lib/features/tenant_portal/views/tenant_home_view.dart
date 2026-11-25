import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';

import '../models/tenant_models.dart';
import '../services/tenant_lease_service.dart';
import '../widgets/tenant_ui.dart';

/// The tenant's overview: lease offers to answer, the active lease, or a welcome screen when the
/// tenant has no lease yet. Everything comes from the tenant's own records (TAQ-110).
class TenantHomeView extends StatefulWidget {
  final TenantLeaseService? service;
  final RequestsService? requests;
  final VoidCallback? onFindProperty;

  const TenantHomeView({super.key, this.service, this.requests, this.onFindProperty});

  @override
  State<TenantHomeView> createState() => _TenantHomeViewState();
}

class _TenantHomeViewState extends State<TenantHomeView> {
  late final TenantLeaseService _service = widget.service ?? TenantLeaseService.instance;
  late final RequestsService _requests = widget.requests ?? RequestsService.instance;
  late final Stream<List<TenantLease>> _leases = _service.watchLeases();
  late final Stream<List<ViewingRequestItem>> _viewings = _requests.watchMyViewings();
  late final Stream<List<RentalApplicationItem>> _applications = _requests.watchMyApplications();
  final Set<String> _busy = {};

  void _findProperty() {
    final callback = widget.onFindProperty;
    if (callback != null) {
      callback();
    } else {
      context.go('/');
    }
  }

  Future<void> _decide(TenantLease lease, bool approve) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr(approve ? 'tnApprove' : 'tnReject')),
        content: Text(loc.tr(approve ? 'tnApproveConfirm' : 'tnRejectConfirm')),
        actions: [
          TashilButton(label: loc.tr('cancel'), variant: TashilButtonVariant.text, onPressed: () => Navigator.of(ctx).pop(false)),
          TashilButton(label: loc.tr('confirm'), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(lease.id));
    try {
      await _service.decideLease(lease.id, approve: approve);
      if (mounted) TashilSnackBar.showSuccess(context: context, message: loc.tr(approve ? 'tnOfferApproved' : 'tnOfferRejected'));
    } catch (_) {
      if (mounted) TashilSnackBar.showError(context: context, message: loc.tr('tnDecisionFailed'));
    } finally {
      if (mounted) setState(() => _busy.remove(lease.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final padding = ResponsiveLayout.isMobile(context) ? 16.0 : 32.0;
        return StreamBuilder<List<TenantLease>>(
          stream: _leases,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final leases = snapshot.data ?? const <TenantLease>[];
            final offers = leases.where((l) => l.isOffer).toList();
            final active = leases.where((l) => l.isActive).toList();
            final history = leases.where((l) => !l.isOffer && !l.isActive).toList();
            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final offer in offers) _offerCard(context, loc, offer),
                  for (final lease in active) _leaseCard(context, loc, lease),
                  if (active.isEmpty && offers.isEmpty) _welcome(context, loc, locale),
                  if (history.isNotEmpty) ...[
                    TenantSectionTitle(loc.tr('tnLeaseHistory')),
                    for (final lease in history) _leaseCard(context, loc, lease, compact: true),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _leaseDetails(BuildContext context, AppLocalizations loc, TenantLease lease, {bool showTitle = true}) {
    return Column(
      children: [
        if (showTitle && lease.propertyTitle.isNotEmpty) TenantDetailRow(loc.tr('unit'), lease.propertyTitle),
        TenantDetailRow(loc.tr('monthlyRent'), formatMoney(context, lease.monthlyRent, lease.currencyCode)),
        if (lease.startDate.isNotEmpty || lease.endDate.isNotEmpty)
          TenantDetailRow(loc.tr('leasePeriod'), '${lease.startDate} → ${lease.endDate}'),
      ],
    );
  }

  Widget _offerCard(BuildContext context, AppLocalizations loc, TenantLease lease) {
    final busy = _busy.contains(lease.id);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: TashilCard.filled(
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.assignment_turned_in_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(loc.tr('tnOfferTitle'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              TenantChip(label: loc.tr('tnLeaseStatus_pending_tenant_approval'), tone: TenantTone.warn),
            ]),
            const SizedBox(height: 8),
            Text(loc.tr('tnOfferBody')),
            const SizedBox(height: 8),
            _leaseDetails(context, loc, lease),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              TashilButton(label: loc.tr('tnApprove'), icon: Icons.check_rounded, isLoading: busy, onPressed: busy ? null : () => _decide(lease, true)),
              TashilButton(label: loc.tr('tnReject'), icon: Icons.close_rounded, variant: TashilButtonVariant.outlined, onPressed: busy ? null : () => _decide(lease, false)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _leaseCard(BuildContext context, AppLocalizations loc, TenantLease lease, {bool compact = false}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: TashilCard.outlined(
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(compact ? lease.propertyTitle : loc.tr('stepProperty'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
              TenantChip(label: loc.tr('tnLeaseStatus_${lease.status}'), tone: toneForStatus(lease.status)),
            ]),
            const SizedBox(height: 8),
            _leaseDetails(context, loc, lease, showTitle: !compact),
          ],
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context, AppLocalizations loc, Locale locale) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TashilCard.filled(
          color: scheme.primaryContainer.withValues(alpha: 0.6),
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            children: [
              Icon(Icons.home_work_outlined, size: 44, color: scheme.onPrimaryContainer),
              const SizedBox(height: 12),
              Text(loc.tr('tnWelcomeTitle'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
              const SizedBox(height: 8),
              Text(loc.tr('tnWelcomeBody'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onPrimaryContainer)),
              const SizedBox(height: 16),
              TashilButton(label: loc.tr('tnFindProperty'), icon: Icons.search_rounded, onPressed: _findProperty),
            ],
          ),
        ),
        TenantSectionTitle(loc.tr('tnMyViewings')),
        StreamBuilder<List<ViewingRequestItem>>(
          stream: _viewings,
          builder: (context, snapshot) {
            final items = [...?snapshot.data]..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            if (items.isEmpty) return _hint(context, loc.tr('tnNoViewings'));
            return Column(children: [
              for (final v in items) _requestTile(context, loc, v.titleFor(locale.languageCode), v.status, v.preferredDate, v.responseNote),
            ]);
          },
        ),
        TenantSectionTitle(loc.tr('tnMyApplications')),
        StreamBuilder<List<RentalApplicationItem>>(
          stream: _applications,
          builder: (context, snapshot) {
            final items = [...?snapshot.data]..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            if (items.isEmpty) return _hint(context, loc.tr('tnNoApplications'));
            return Column(children: [
              for (final a in items) _requestTile(context, loc, a.titleFor(locale.languageCode), a.status, a.moveInDate, a.responseNote),
            ]);
          },
        ),
      ],
    );
  }

  Widget _hint(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
    );
  }

  Widget _requestTile(BuildContext context, AppLocalizations loc, String title, String status, String date, String note) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: TashilCard.outlined(
        padding: const EdgeInsetsDirectional.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.isEmpty ? '—' : title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (date.isNotEmpty) Text(date, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (note.isNotEmpty) Text(note, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TenantChip(label: loc.tr('rqStatus_$status'), tone: toneForStatus(status)),
          ],
        ),
      ),
    );
  }
}
