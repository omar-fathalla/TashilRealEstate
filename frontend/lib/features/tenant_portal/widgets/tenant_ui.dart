import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/currency_formatter.dart';

/// "8,500 د.إ" in the active language. The currency comes from the record, never from a switcher.
String formatMoney(BuildContext context, double amount, String currencyCode) {
  final loc = AppLocalizations.of(context);
  final word = loc.tr(currencyCode.toUpperCase() == 'EGP' ? 'currency_eg' : 'currency_ae');
  return '${CurrencyFormatter.formatAmount(amount, langCode: LocaleController.languageCode)} $word';
}

enum TenantTone { good, warn, bad, neutral }

class TenantChip extends StatelessWidget {
  final String label;
  final TenantTone tone;
  const TenantChip({super.key, required this.label, this.tone = TenantTone.neutral});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      TenantTone.good => (scheme.primaryContainer, scheme.onPrimaryContainer),
      TenantTone.warn => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      TenantTone.bad => (scheme.errorContainer, scheme.onErrorContainer),
      TenantTone.neutral => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

TenantTone toneForStatus(String status) {
  switch (status) {
    case 'active':
    case 'paid':
    case 'confirmed':
    case 'approved':
      return TenantTone.good;
    case 'pending':
    case 'pending_tenant_approval':
      return TenantTone.warn;
    case 'failed':
    case 'rejected':
    case 'declined':
    case 'terminated':
      return TenantTone.bad;
    default:
      return TenantTone.neutral;
  }
}

class TenantSectionTitle extends StatelessWidget {
  final String text;
  const TenantSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class TenantDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const TenantDetailRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }
}
