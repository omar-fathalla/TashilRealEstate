import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';

class LegalWarningNoticeDialog extends StatelessWidget {
  final RentInvoiceModel invoice;

  const LegalWarningNoticeDialog({super.key, required this.invoice});

  static void show(BuildContext context, RentInvoiceModel invoice) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LegalWarningNoticeDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = invoice.countryCode == 'AE';
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Red Alert Header with M3 Shaded Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gavel_rounded, color: theme.colorScheme.error, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isUAE ? loc.tr('rdcOfficialNotice') : loc.tr('egLegalEvictionNotice'),
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TashilIconButton.close(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Official Emblem & Notice Header
              Center(
                child: Column(
                  children: [
                    Text(
                      isUAE ? loc.tr('uaeGovHeader') : loc.tr('egGovHeader'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUAE ? loc.tr('dubaiLandDept') : loc.tr('egyptMinistryJustice'),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isUAE ? loc.tr('legalNoticeTitle_ae') : loc.tr('legalNoticeTitle_eg'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loc.tr('contractNumber')}: ${invoice.contractNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Overdue Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            loc.tr('overdueDaysCount'),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        Text(
                          '${invoice.overdueDays} ${loc.tr('days')}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 16, color: theme.colorScheme.error.withValues(alpha: 0.2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            loc.tr('unpaidBaseRent'),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.formatAmount(invoice.baseAmount, langCode: lang)} $currency',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            loc.tr('accumulatedLateFee'),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        Text(
                          '+ ${CurrencyFormatter.formatAmount(invoice.latePenaltyAmount, langCode: lang)} $currency',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 16, color: theme.colorScheme.error.withValues(alpha: 0.2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            loc.tr('totalDueClaimed'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.formatAmount(invoice.totalAmountDue, langCode: lang)} $currency',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Legal Body Text
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  isUAE ? loc.tr('legalNoticeBody_ae') : loc.tr('legalNoticeBody_eg'),
                  style: TextStyle(fontSize: 12, height: 1.6, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 24),

              // Official M3 Connected Button Group Action Footer
              TashilConnectedButtonGroup<String>(
                isFullWidth: true,
                height: 48.0,
                selectedValue: 'export',
                showCheckmark: false,
                onSelectionChanged: (action) {
                  if (action == 'remind') {
                    RentCollectionService().sendReminder(invoice.id);
                    TashilSnackBar.showSuccess(
                      context: context,
                      message: loc.tr('reminderSentViaWhatsAppSuccess'),
                    );
                    Navigator.of(context).pop();
                  } else if (action == 'export') {
                    RentCollectionService().issueLegalNotice(invoice.id);
                    TashilSnackBar.showSuccess(
                      context: context,
                      message: loc.tr('officialLegalWarningGenerated'),
                    );
                    Navigator.of(context).pop();
                  }
                },
                segments: [
                  TashilConnectedButtonSegment(
                    value: 'export',
                    label: loc.tr('exportOfficialWarningPdf'),
                    icon: Icons.print_rounded,
                  ),
                  TashilConnectedButtonSegment(
                    value: 'remind',
                    label: loc.tr('sendViaWhatsAppSMS'),
                    icon: Icons.send_to_mobile_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
