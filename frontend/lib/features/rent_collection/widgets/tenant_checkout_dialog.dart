import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

/// Online rent payment is not live yet (TAQ-16 turns it on once the gateway keys exist), so this
/// dialog only shows what is due and a disabled "Pay now". It never marks an invoice paid.
class TenantCheckoutDialog extends StatelessWidget {
  final RentInvoiceModel invoice;

  const TenantCheckoutDialog({super.key, required this.invoice});

  static void show(BuildContext context, RentInvoiceModel invoice) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TenantCheckoutDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        final currency = loc.tr(invoice.countryCode == 'AE' ? 'currency_ae' : 'currency_eg');
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.payments_outlined, size: 40, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('${loc.tr('invoiceNo')}: ${invoice.invoiceNumber}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.formatAmount(invoice.totalAmountDue, langCode: locale.languageCode)} $currency',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TashilButton(label: loc.tr('payNowOnline'), icon: Icons.credit_card_rounded, onPressed: null),
                  const SizedBox(height: 8),
                  Text(loc.tr('tnPayOnlineSoon'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  TashilButton(label: loc.tr('close'), variant: TashilButtonVariant.text, onPressed: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
