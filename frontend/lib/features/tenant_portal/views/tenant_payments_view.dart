import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';

import '../models/tenant_models.dart';
import '../services/tenant_lease_service.dart';
import '../widgets/tenant_ui.dart';

/// Rent due, payment history and receipts from the tenant's own Transactions and Invoices.
/// "Pay now" stays visible but disabled until the gateway is live; nothing here marks anything paid.
class TenantPaymentsView extends StatefulWidget {
  final TenantLeaseService? service;
  final DateTime Function()? now;

  const TenantPaymentsView({super.key, this.service, this.now});

  @override
  State<TenantPaymentsView> createState() => _TenantPaymentsViewState();
}

class _TenantPaymentsViewState extends State<TenantPaymentsView> {
  late final TenantLeaseService _service = widget.service ?? TenantLeaseService.instance;
  late final Stream<List<TenantLease>> _leases = _service.watchLeases();
  late final Stream<List<TenantTransaction>> _transactions = _service.watchTransactions();
  late final Stream<List<TenantInvoice>> _invoices = _service.watchInvoices();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final padding = ResponsiveLayout.isMobile(context) ? 16.0 : 24.0;
        return StreamBuilder<List<TenantLease>>(
          stream: _leases,
          builder: (context, leaseSnap) {
            return StreamBuilder<List<TenantTransaction>>(
              stream: _transactions,
              builder: (context, txSnap) {
                return StreamBuilder<List<TenantInvoice>>(
                  stream: _invoices,
                  builder: (context, invSnap) {
                    if (leaseSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final leases = (leaseSnap.data ?? const <TenantLease>[]).where((l) => l.isActive).toList();
                    final transactions = txSnap.data ?? const <TenantTransaction>[];
                    final invoices = {for (final i in invSnap.data ?? const <TenantInvoice>[]) i.transactionId: i};
                    final now = (widget.now ?? DateTime.now)();
                    return ListView(
                      padding: EdgeInsetsDirectional.all(padding),
                      children: [
                        Text(loc.tr('rentCollectionTitle'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (leases.isEmpty)
                          _noLease(context, loc)
                        else
                          for (final lease in leases) _dueCard(context, loc, lease, nextDuePeriod(lease, transactions, now)),
                        TenantSectionTitle(loc.tr('tnHistory')),
                        if (transactions.isEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
                            child: Text(loc.tr('tnNoPayments'), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                          )
                        else
                          for (final tx in transactions) _historyTile(context, loc, tx, invoices[tx.id]),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _noLease(BuildContext context, AppLocalizations loc) {
    final scheme = Theme.of(context).colorScheme;
    return TashilCard.outlined(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(loc.tr('tnNoLeaseTitle'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(loc.tr('tnNoLeasePayments'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _dueCard(BuildContext context, AppLocalizations loc, TenantLease lease, String? period) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: TashilCard.filled(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lease.propertyTitle.isNotEmpty) Text(lease.propertyTitle, style: TextStyle(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(
              period == null ? loc.tr('tnNothingDue') : '${loc.tr('tnRentFor')} $period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer),
            ),
            if (period != null) ...[
              const SizedBox(height: 4),
              Text(
                formatMoney(context, lease.monthlyRent, lease.currencyCode),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              TashilButton(label: loc.tr('payNowOnline'), icon: Icons.credit_card_rounded, onPressed: null),
              const SizedBox(height: 6),
              Text(loc.tr('tnPayOnlineSoon'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.8), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historyTile(BuildContext context, AppLocalizations loc, TenantTransaction tx, TenantInvoice? invoice) {
    final scheme = Theme.of(context).colorScheme;
    final lines = [
      if (tx.isPaid && tx.invoiceNumber.isNotEmpty) '${loc.tr('invoiceNo')}: ${tx.invoiceNumber}',
      if (invoice != null && invoice.paymentMethod.isNotEmpty) loc.tr('tnMethod_${invoice.paymentMethod}'),
      if (invoice != null && invoice.paymentReference.isNotEmpty) invoice.paymentReference,
    ];
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
                  Text('${loc.tr('tnRentFor')} ${tx.period}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatMoney(context, tx.amount, tx.currencyCode)),
                  for (final line in lines) Text(line, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TenantChip(label: loc.tr('tnPayStatus_${tx.status}'), tone: toneForStatus(tx.status)),
          ],
        ),
      ),
    );
  }
}
