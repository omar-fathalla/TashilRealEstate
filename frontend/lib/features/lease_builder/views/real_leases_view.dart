import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/empty_state/tashil_empty_state.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/create_lease_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/record_manual_payment_dialog.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';

/// Filter groups of the real leases list.
const _filters = ['all', 'draft', 'offered', 'active', 'ended'];

bool _inFilter(PortfolioLease l, String filter) {
  switch (filter) {
    case 'draft':
      return l.isDraft;
    case 'offered':
      return l.isOffer;
    case 'active':
      return l.isActive;
    case 'ended':
      return l.isEnded || l.status == 'rejected';
    default:
      return true;
  }
}

String leaseStatusKey(String status) {
  switch (status) {
    case 'pending_tenant_approval':
      return 'ldStatusOffered';
    case 'active':
      return 'ldStatusActive';
    case 'rejected':
      return 'ldStatusRejected';
    case 'expired':
      return 'ldStatusExpired';
    case 'terminated':
      return 'ldStatusTerminated';
    default:
      return 'ldStatusDraft';
  }
}

/// The signed-in owner's or agency's leases, read from the real `Leases` collection (TAQ-144).
/// A lease exists only once the server created it; offers reach the tenant through the same
/// `respondToLeaseOffer` flow the tenant portal uses. Nothing here is kept in memory or marks a
/// property rented.
class RealLeasesView extends StatefulWidget {
  final PortfolioController controller;
  final PortfolioDataService? service;

  const RealLeasesView({super.key, required this.controller, this.service});

  @override
  State<RealLeasesView> createState() => _RealLeasesViewState();
}

class _RealLeasesViewState extends State<RealLeasesView> {
  late final PortfolioDataService _service = widget.service ?? PortfolioDataService.instance;
  String _filter = 'all';
  final Set<String> _busy = {};

  Future<void> _create() async {
    final loc = AppLocalizations.of(context);
    final id = await CreateLeaseDialog.show(context);
    if (id != null && mounted) TashilSnackBar.showSuccess(context: context, message: loc.tr('ldCreated'));
  }

  Future<void> _run(PortfolioLease lease, Future<void> Function() action, String successKey) async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy.add(lease.id));
    try {
      await action();
      if (mounted) TashilSnackBar.showSuccess(context: context, message: loc.tr(successKey));
    } catch (_) {
      if (mounted) TashilSnackBar.showError(context: context, message: loc.tr('ldActionFailed'));
    } finally {
      if (mounted) setState(() => _busy.remove(lease.id));
    }
  }

  Future<void> _delete(PortfolioLease lease) async {
    final loc = AppLocalizations.of(context);
    final ok = await TashilAlertDialog.showConfirmation(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: loc.tr('ldDeleteTitle'),
      message: loc.tr('ldDeleteMessage'),
      confirmLabel: loc.tr('deleteContractBtn'),
      cancelLabel: loc.tr('cancel'),
      isDestructive: true,
    );
    if (ok && mounted) await _run(lease, () => _service.deleteDraft(lease.id), 'ldDraftDeleted');
  }

  void _details(PortfolioLease lease) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LeaseDetailsSheet(lease: lease),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: CountryController.currentCountry,
        builder: (context, country, __) => ListenableBuilder(
          listenable: widget.controller,
          builder: (context, ___) => _body(context, country),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, String country) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final snapshot = widget.controller.snapshot;
    final lang = LocaleController.languageCode;
    final leases = snapshot.leases.where((l) => l.countryCode == country).toList();
    final shown = leases.where((l) => _inFilter(l, _filter)).toList();
    final active = leases.where((l) => l.isActive).toList();
    final awaiting = leases.where((l) => l.isOffer).length;
    final yieldTotal = active.fold<double>(0, (s, l) => s + l.monthlyRent);
    final currencyCode = country == 'EG' ? 'EGP' : 'AED';

    Widget list;
    if (snapshot.isLoading) {
      list = const Padding(padding: EdgeInsets.all(48), child: Center(child: TashilLoadingIndicator()));
    } else if (snapshot.load == PortfolioLoad.error) {
      list = TashilEmptyState(
        icon: Icons.cloud_off_outlined,
        title: loc.tr('ovLoadFailedTitle'),
        message: loc.tr('ovLoadFailedMessage'),
        primaryActionLabel: loc.tr('ovRetry'),
        primaryActionIcon: Icons.refresh_rounded,
        onPrimaryAction: widget.controller.start,
      );
    } else if (snapshot.load == PortfolioLoad.noAgency) {
      list = TashilEmptyState(
        icon: Icons.business_outlined,
        title: loc.tr('ovNoAgencyTitle'),
        message: loc.tr('ovNoAgencyMessage'),
      );
    } else if (shown.isEmpty) {
      list = TashilEmptyState(
        icon: Icons.description_outlined,
        title: loc.tr('ldEmptyTitle'),
        message: loc.tr('ldEmptyMessage'),
        primaryActionLabel: _filter == 'all' ? loc.tr('createNewLease') : null,
        primaryActionIcon: Icons.add_rounded,
        onPrimaryAction: _create,
      );
    } else {
      list = ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shown.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _LeaseCard(
          lease: shown[i],
          busy: _busy.contains(shown[i].id),
          onDetails: () => _details(shown[i]),
          onSendOffer: () => _run(shown[i], () => _service.sendOffer(shown[i].id), 'ldOfferSent'),
          onWithdraw: () => _run(shown[i], () => _service.withdrawOffer(shown[i].id), 'ldOfferWithdrawn'),
          onDelete: () => _delete(shown[i]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 768;
          final titles = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('leasesManagementTitle'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 20 : 24, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                loc.tr(country == 'AE' ? 'leasesSubtitle_ae' : 'leasesSubtitle_eg'),
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ],
          );
          final create = TashilButton(onPressed: _create, icon: Icons.add_rounded, label: loc.tr('createNewLease'), height: 48);
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28, vertical: compact ? 20 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact) ...[titles, const SizedBox(height: 14), create] else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: titles), const SizedBox(width: 16), create]),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TashilButton(
                    label: loc.tr('mpTitle'),
                    icon: Icons.receipt_long_rounded,
                    variant: TashilButtonVariant.tonal,
                    height: 48,
                    onPressed: () => RecordManualPaymentDialog.show(context),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Kpi(label: loc.tr('ldKpiTotal'), value: '${leases.length}', icon: Icons.description_rounded),
                    _Kpi(label: loc.tr('activeLeases'), value: '${active.length}', icon: Icons.check_circle_rounded),
                    _Kpi(label: loc.tr('ldKpiAwaiting'), value: '$awaiting', icon: Icons.pending_actions_rounded),
                    _Kpi(
                      label: loc.tr('ldKpiYield'),
                      value: CurrencyFormatter.formatPriceWithCurrency(amount: yieldTotal, currencyCode: currencyCode, langCode: lang),
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: TashilConnectedButtonGroup<String>(
                    selectedValue: _filter,
                    height: 44,
                    onSelectionChanged: (v) => setState(() => _filter = v),
                    segments: [
                      for (final f in _filters)
                        TashilConnectedButtonSegment(
                          value: f,
                          label: '${loc.tr('ldFilter_$f')} (${leases.where((l) => _inFilter(l, f)).length})',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                list,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Kpi({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      child: TashilCard.filled(
        padding: const EdgeInsetsDirectional.all(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaseCard extends StatelessWidget {
  final PortfolioLease lease;
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onSendOffer;
  final VoidCallback onWithdraw;
  final VoidCallback onDelete;

  const _LeaseCard({
    required this.lease,
    required this.busy,
    required this.onDetails,
    required this.onSendOffer,
    required this.onWithdraw,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lang = LocaleController.languageCode;
    final rent = CurrencyFormatter.formatPriceWithCurrency(amount: lease.monthlyRent, currencyCode: lease.currencyCode, langCode: lang);
    final (bg, fg) = lease.isActive
        ? (scheme.tertiaryContainer, scheme.onTertiaryContainer)
        : lease.isOffer
            ? (scheme.secondaryContainer, scheme.onSecondaryContainer)
            : lease.isDraft
                ? (scheme.surfaceContainerHigh, scheme.onSurfaceVariant)
                : (scheme.errorContainer, scheme.onErrorContainer);

    return TashilCard.outlined(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                lease.propertyTitle.isEmpty ? lease.id : lease.propertyTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
              child: Text(loc.tr(leaseStatusKey(lease.status)), style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _Cell(icon: Icons.person_outline_rounded, label: loc.tr('tenant'), value: lease.tenantName.isEmpty ? '-' : lease.tenantName),
              _Cell(icon: Icons.payments_outlined, label: loc.tr('monthlyRent'), value: rent),
              _Cell(icon: Icons.calendar_month_outlined, label: loc.tr('leasePeriod'), value: '${lease.startDate} - ${lease.endDate}'),
            ],
          ),
          const SizedBox(height: 14),
          const TashilDivider.cardAction(),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TashilButton.tonal(label: loc.tr('ldDetails'), icon: Icons.visibility_rounded, height: 48, onPressed: onDetails),
                if (lease.isDraft) ...[
                  TashilButton.outlined(label: loc.tr('deleteContractBtn'), icon: Icons.delete_outline_rounded, height: 48, onPressed: busy ? null : onDelete),
                  TashilButton.filled(label: loc.tr('ldSendOffer'), icon: Icons.send_rounded, height: 48, isLoading: busy, onPressed: busy ? null : onSendOffer),
                ],
                if (lease.isOffer)
                  TashilButton.outlined(label: loc.tr('ldWithdrawOffer'), icon: Icons.undo_rounded, height: 48, isLoading: busy, onPressed: busy ? null : onWithdraw),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Cell({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: scheme.onSurfaceVariant),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
        ],
      ),
    ]);
  }
}

class _LeaseDetailsSheet extends StatelessWidget {
  final PortfolioLease lease;
  const _LeaseDetailsSheet({required this.lease});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = LocaleController.languageCode;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 130, child: Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
            Expanded(child: SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    return Padding(
      padding: const EdgeInsetsDirectional.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text(loc.tr('ldDetails'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              TashilIconButton.close(onPressed: () => Navigator.of(context).pop()),
            ]),
            const SizedBox(height: 8),
            row(loc.tr('ldProperty'), lease.propertyTitle.isEmpty ? '-' : lease.propertyTitle),
            row(loc.tr('tenant'), lease.tenantName.isEmpty ? '-' : lease.tenantName),
            row(loc.tr('monthlyRent'), CurrencyFormatter.formatPriceWithCurrency(amount: lease.monthlyRent, currencyCode: lease.currencyCode, langCode: lang)),
            row(loc.tr('ldStartDate'), lease.startDate),
            row(loc.tr('ldEndDate'), lease.endDate),
            row(loc.tr('ldStatus'), loc.tr(leaseStatusKey(lease.status))),
            row(loc.tr('ldLeaseId'), lease.id),
          ],
        ),
      ),
    );
  }
}
