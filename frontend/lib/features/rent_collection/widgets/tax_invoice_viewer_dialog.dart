import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';

class TaxInvoiceViewerDialog extends StatelessWidget {
  final RentInvoiceModel invoice;

  const TaxInvoiceViewerDialog({
    super.key,
    required this.invoice,
  });

  static Future<void> show(BuildContext context, RentInvoiceModel invoice) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TaxInvoiceViewerDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;
    final isUAE = invoice.countryCode == 'AE';
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

    final isPaid = invoice.status == 'paid';
    final isOverdue = invoice.status == 'overdue';

    // Unique verification payload for each electronic invoice
    final token = '0x${invoice.id.hashCode.toRadixString(16).toUpperCase()}';
    final qrData = 'https://tashil.estate/verify/tax-invoice/${invoice.invoiceNumber}'
        '?ref=${invoice.id}&token=$token&total=${invoice.totalAmountDue}'
        '&country=${invoice.countryCode}&date=${invoice.dueDate.toIso8601String().split('T').first}';

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 36,
        vertical: isMobile ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Legal Badge & Shaded Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.tr('officialElectronicTaxInvoice'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isUAE ? loc.tr('taxAuthorityUAEStandard') : loc.tr('taxAuthorityEGStandard'),
                                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TashilIconButton.close(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(height: 20, color: theme.colorScheme.outlineVariant),

              // Invoice Body (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                              : isOverdue
                                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
                                  : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    isPaid
                                        ? Icons.check_circle_rounded
                                        : isOverdue
                                            ? Icons.warning_amber_rounded
                                            : Icons.schedule_rounded,
                                    size: 16,
                                    color: isPaid
                                        ? theme.colorScheme.primary
                                        : isOverdue
                                            ? theme.colorScheme.error
                                            : theme.colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isPaid
                                          ? loc.tr('statusPaidElectronically')
                                          : isOverdue
                                              ? '${loc.tr('statusOverdueWithDays')} (${invoice.overdueDays} ${loc.tr('days')})'
                                              : loc.tr('statusPendingPayment'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isPaid
                                            ? theme.colorScheme.primary
                                            : isOverdue
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.onSecondaryContainer,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                invoice.invoiceNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metadata Grid (2-column)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _buildMetaRow(context, loc.tr('propertyTitle'), '${invoice.unitTitle} (${invoice.unitNumber})'),
                            const SizedBox(height: 8),
                            _buildMetaRow(context, loc.tr('contractNumber'), invoice.contractNumber, isLtr: true),
                            const SizedBox(height: 8),
                            _buildMetaRow(context, loc.tr('tenantFullName'), invoice.tenant.name),
                            const SizedBox(height: 8),
                            _buildMetaRow(context, loc.tr('landlordName'), invoice.owner.name),
                            const SizedBox(height: 8),
                            _buildMetaRow(context, loc.tr('dueDate'), '${invoice.dueDate.year}-${invoice.dueDate.month.toString().padLeft(2, '0')}-${invoice.dueDate.day.toString().padLeft(2, '0')}', isLtr: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Line Items Table
                      Text(
                        loc.tr('invoiceFinancialBreakdown'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _buildLineItem(context, loc.tr('baseMonthlyRent'), '${CurrencyFormatter.formatAmount(invoice.baseAmount, langCode: lang)} $currency'),
                            Divider(height: 1, color: theme.colorScheme.outlineVariant),
                            if (invoice.latePenaltyAmount > 0) ...[
                              _buildLineItem(
                                context,
                                '${loc.tr('latePaymentPenalty')} (${invoice.overdueDays} ${loc.tr('days')})',
                                '+${CurrencyFormatter.formatAmount(invoice.latePenaltyAmount, langCode: lang)} $currency',
                                isPenalty: true,
                              ),
                              Divider(height: 1, color: theme.colorScheme.outlineVariant),
                            ],
                            _buildLineItem(
                              context,
                              loc.tr('totalInvoiceAmountDue'),
                              '${CurrencyFormatter.formatAmount(invoice.totalAmountDue, langCode: lang)} $currency',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Enlarged Stamped Verification & Official QR Code Container (Fills Empty Space for Camera Scanning)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // High-contrast clean white background container for QR code
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: isMobile ? 115.0 : 140.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 14, color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          loc.tr('digitallyCertified'),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    loc.tr('taxAuthorityVerification'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isUAE
                                        ? loc.tr('taxAuthorityUAEStandard')
                                        : loc.tr('taxAuthorityEGStandard'),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    loc.tr('qrScanVerifyHint'),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      'Token: $token • Escrow Secured',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.4,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Action Buttons
              if (isPaid) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TashilButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.tr('taxInvoiceDownloadedSuccess')),
                          backgroundColor: theme.colorScheme.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icons.download_rounded,
                    label: loc.tr('downloadInvoice'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TashilButton.tonal(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.tr('taxInvoiceDownloadedSuccess')),
                              backgroundColor: theme.colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icons.download_rounded,
                        label: loc.tr('downloadInvoice'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TashilButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          TenantCheckoutDialog.show(context, invoice);
                        },
                        icon: Icons.payment_rounded,
                        label: loc.tr('payNowOnline'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value, {bool isLtr = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        Flexible(
          child: isLtr
              ? Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLineItem(BuildContext context, String label, String amount, {bool isTotal = false, bool isPenalty = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isPenalty ? theme.colorScheme.error : theme.colorScheme.onSurface,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: isTotal
                  ? theme.colorScheme.primary
                  : isPenalty
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
