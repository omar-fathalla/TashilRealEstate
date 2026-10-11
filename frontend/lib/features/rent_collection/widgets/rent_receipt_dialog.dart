import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

class RentReceiptDialog extends StatelessWidget {
  final RentInvoiceModel invoice;

  const RentReceiptDialog({super.key, required this.invoice});

  static void show(BuildContext context, RentInvoiceModel invoice) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RentReceiptDialog(invoice: invoice),
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

    final token = '0x${invoice.id.hashCode.toRadixString(16).toUpperCase()}';
    final paymentDate = invoice.paidAt ?? invoice.dueDate;
    final formattedDate =
        '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')} ${paymentDate.hour.toString().padLeft(2, '0')}:${paymentDate.minute.toString().padLeft(2, '0')}';

    final qrData = 'https://tashil.estate/verify/receipt/RCP-${invoice.invoiceNumber}'
        '?ref=${invoice.id}&token=$token&total=${invoice.totalAmountDue}'
        '&country=${invoice.countryCode}&date=${paymentDate.toIso8601String().split('T').first}';

    final ibanSuffix = invoice.owner.iban.length > 6
        ? invoice.owner.iban.substring(invoice.owner.iban.length - 6)
        : invoice.owner.iban;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 36,
        vertical: isMobile ? 16 : 28,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 820),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pinned Header with M3 Shaded Close Button
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
                                loc.tr('officialPaymentReceiptTitle'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
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

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Receipt Reference Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      loc.tr('receiptVerifiedStamp'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: theme.colorScheme.primary,
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
                                'RCP-${invoice.invoiceNumber}',
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
                      const SizedBox(height: 14),

                      // Amount Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.88),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              loc.tr('totalAmountPaid'),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${CurrencyFormatter.formatAmount(invoice.totalAmountDue, langCode: lang)} $currency',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.payment_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${loc.tr('paymentMethod')}: ${_getPaymentMethodLabel(loc, invoice.paymentMethod ?? 'card')}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Transaction Details Table
                      _buildSectionHeader(context, loc.tr('paymentTransactionDetails')),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _buildRow(context, loc.tr('tenantFullName'), invoice.tenant.name),
                            _buildDivider(context),
                            _buildRow(context, loc.tr('propertyTitle'), '${invoice.unitTitle} (${invoice.unitNumber})'),
                            _buildDivider(context),
                            _buildRow(context, loc.tr('contractNumber'), invoice.contractNumber, isLtr: true),
                            _buildDivider(context),
                            _buildRow(
                              context,
                              loc.tr('paymentGatewayTxnId'),
                              invoice.transactionReference ?? 'PAY-MEEZA-994821',
                              isLtr: true,
                            ),
                            _buildDivider(context),
                            _buildRow(
                              context,
                              loc.tr('paidOnTimestamp'),
                              formattedDate,
                              isLtr: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Split Payout Breakdown
                      _buildSectionHeader(context, loc.tr('instantSplitPayoutBreakdown')),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          children: [
                            _buildRow(
                              context,
                              loc.tr('netTransferredToOwner'),
                              '${CurrencyFormatter.formatAmount(invoice.netPayoutToOwner, langCode: lang)} $currency',
                              isBold: true,
                              color: theme.colorScheme.primary,
                            ),
                            _buildDivider(context),
                            _buildRow(context, loc.tr('landlordName'), invoice.owner.name),
                            _buildDivider(context),
                            _buildBankIbanRow(context, loc, invoice.owner.bankName, ibanSuffix),
                            _buildDivider(context),
                            _buildRow(
                              context,
                              loc.tr('payoutSettlementRef'),
                              invoice.payoutReference ?? 'SETTLE-NBE-882194',
                              isLtr: true,
                            ),
                            _buildDivider(context),
                            _buildRow(
                              context,
                              loc.tr('platformProcessingFee'),
                              '${CurrencyFormatter.formatAmount(invoice.platformFeeAmount, langCode: lang)} $currency (1.5%)',
                              color: theme.colorScheme.onSurfaceVariant,
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
                                size: isMobile ? 115.0 : 135.0,
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
                                    loc.tr('receiptQrVerificationTitle'),
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
                                      'Token: $token • ${loc.tr('escrowSecured')}',
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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Pinned Bottom Action Footer
              TashilDivider.cardAction(),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TashilButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.tr('downloadPdfNotice'))),
                          );
                        },
                        icon: Icons.download_rounded,
                        label: loc.tr('exportPdf'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TashilButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icons.check_rounded,
                        label: loc.tr('doneAction'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    bool isLtr = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Directionality(
            textDirection: isLtr ? TextDirection.ltr : Directionality.of(context),
            child: Text(
              value,
              textAlign: isLtr ? TextAlign.start : TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankIbanRow(
    BuildContext context,
    AppLocalizations loc,
    String bankName,
    String ibanSuffix,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.tr('ownerBank'),
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  bankName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '(${loc.tr('iban')}: ...$ibanSuffix)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
    );
  }

  String _getPaymentMethodLabel(AppLocalizations loc, String method) {
    switch (method) {
      case 'card':
        return loc.tr('paymentMethodCard');
      case 'vodafone_cash':
        return loc.tr('paymentMethodVodafoneCash');
      case 'orange_cash':
        return loc.tr('paymentMethodOrangeCash');
      case 'instapay':
        return loc.tr('paymentMethodInstaPay');
      case 'fawry':
        return loc.tr('paymentMethodFawry');
      case 'apple_pay':
        return loc.tr('paymentMethodApplePay');
      case 'google_pay':
        return loc.tr('paymentMethodGooglePay');
      case 'direct_debit':
        return loc.tr('paymentMethodDirectDebit');
      case 'iban_wire':
        return loc.tr('paymentMethodIbanWire');
      default:
        return method;
    }
  }
}
