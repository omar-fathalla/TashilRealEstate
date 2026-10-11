import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/cards/tashil_cards.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';

class TransferDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> payout;
  final String currency;
  final String lang;

  const TransferDetailsDialog({
    super.key,
    required this.payout,
    required this.currency,
    required this.lang,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> payout,
    required String currency,
    required String lang,
  }) {
    return TashilTransitions.showM3Dialog(
      context: context,
      builder: (_) => TransferDetailsDialog(
        payout: payout,
        currency: currency,
        lang: lang,
      ),
    );
  }

  String _getLocalizedBankName(String ref, String lang) {
    if (ref.startsWith('CIB')) {
      if (lang == 'ar') return 'البنك التجاري الدولي';
      if (lang == 'hi') return 'कमर्शियल इंटरनेशनल बैंक';
      return 'Commercial International Bank';
    } else if (ref.startsWith('HSBC')) {
      if (lang == 'ar') return 'بنك إتش إس بي سي الشرق الأوسط';
      if (lang == 'hi') return 'एचएसबीसी बैंक मिडिल ईस्ट';
      return 'HSBC Bank Middle East';
    } else if (ref.startsWith('QNB')) {
      if (lang == 'ar') return 'بنك قطر الوطني الأهلي';
      if (lang == 'hi') return 'क्यूएनबी अहली';
      return 'QNB Alahli';
    } else if (ref.startsWith('ENBD')) {
      if (lang == 'ar') return 'بنك الإمارات دبي الوطني';
      if (lang == 'hi') return 'अमीरात एनबीडी';
      return 'Emirates NBD';
    } else {
      if (lang == 'ar') return 'بنك أبوظبي الأول';
      if (lang == 'hi') return 'फर्स्ट अबू धाबी बैंक';
      return 'First Abu Dhabi Bank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final amount = (payout['amount'] as num).toDouble();
    final title = (payout['titles'] as Map<String, dynamic>)[lang] ??
        (payout['titles'] as Map<String, dynamic>)['ar'] ??
        '';
    final date = (payout['dates'] as Map<String, dynamic>)[lang] ??
        (payout['dates'] as Map<String, dynamic>)['ar'] ??
        '';
    final ref = payout['ref'] as String? ?? 'REF-000000';
    final bankName = _getLocalizedBankName(ref, lang);

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerLowest,
      elevation: 6.0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 20 : 28)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 16 : 24,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. M3 Header Row with Shaded Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.account_balance_rounded, color: colorScheme.onPrimaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('transferDetailsTitle'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 13, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                loc.tr('settlementCompleted'),
                                style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  TashilIconButton.close(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: loc.tr('close'),
                  ),
                ],
              ),
              const TashilDivider.middleInset(height: 22),

              // 2. Prominent Amount Hero Card
              TashilCard.outlined(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                color: colorScheme.surfaceContainerLow,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        loc.tr('payoutCompleted'),
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+ ${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Detail List Items
              _buildInfoRow(
                icon: Icons.tag_rounded,
                label: loc.tr('bankReferenceNumber'),
                value: ref,
                colorScheme: colorScheme,
                trailing: TashilIconButton.standard(
                  icon: Icons.copy_rounded,
                  tooltip: loc.tr('copyRefSuccess'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ref));
                    TashilSnackBar.showSuccess(
                      context: context,
                      message: loc.tr('copyRefSuccess'),
                    );
                  },
                ),
              ),
              const TashilDivider.middleInset(height: 16),
              _buildInfoRow(
                icon: Icons.account_balance_outlined,
                label: loc.tr('transferredToAccount'),
                value: bankName,
                colorScheme: colorScheme,
              ),
              const TashilDivider.middleInset(height: 16),
              _buildInfoRow(
                icon: Icons.apartment_rounded,
                label: loc.tr('linkedUnitAndTenant'),
                value: title,
                colorScheme: colorScheme,
              ),
              const TashilDivider.middleInset(height: 16),
              _buildInfoRow(
                icon: Icons.receipt_long_rounded,
                label: loc.tr('linkedTaxInvoice'),
                value: 'INV-${ref.replaceAll(RegExp(r'[^0-9]'), '')}',
                colorScheme: colorScheme,
              ),
              const TashilDivider.cardAction(height: 24),

              // 4. Pinned Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TashilButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    label: loc.tr('close'),
                  ),
                  const SizedBox(width: 10),
                  TashilButton.filled(
                    onPressed: () {
                      Navigator.of(context).pop();
                      TashilSnackBar.showSuccess(
                        context: context,
                        message: loc.tr('downloadTransferReceipt'),
                      );
                    },
                    icon: Icons.download_rounded,
                    label: loc.tr('downloadTransferReceipt'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}

