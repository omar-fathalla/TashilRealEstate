import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/rent_receipt_dialog.dart';

class TenantPaymentsView extends StatelessWidget {
  const TenantPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;

    return ValueListenableBuilder<String>(
      valueListenable: CountryController.currentCountry,
      builder: (context, currentCountry, _) {
        final isUAE = currentCountry == 'AE';
        final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

        return ValueListenableBuilder<List<RentInvoiceModel>>(
          valueListenable: RentCollectionService().invoicesNotifier,
          builder: (context, allInvoices, _) {
            final countryInvoices = allInvoices.where((inv) => inv.countryCode == currentCountry).toList();

            return Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('rentCollectionTitle'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: colorScheme.onSecondaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              loc.tr('automatedSplitActive'),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (countryInvoices.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(loc.tr('noInvoicesFound'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: countryInvoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final inv = countryInvoices[index];
                          final isPaid = inv.status == 'paid';
                          final isOverdue = inv.status == 'overdue';

                          Color statusColor = colorScheme.onSecondaryContainer;
                          Color statusBg = colorScheme.secondaryContainer;
                          String statusText = loc.tr('statusPaid');

                          if (!isPaid) {
                            if (isOverdue) {
                              statusColor = colorScheme.onErrorContainer;
                              statusBg = colorScheme.errorContainer;
                              statusText = '${loc.tr('statusOverdue')} (${inv.overdueDays} ${loc.tr('days')})';
                            } else {
                              statusColor = colorScheme.onTertiaryContainer;
                              statusBg = colorScheme.tertiaryContainer;
                              statusText = loc.tr('statusDueSoon');
                            }
                          }

                          return TashilCard.outlined(
                            color: colorScheme.surfaceContainerLowest,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: statusBg,
                                            radius: 18,
                                            child: Icon(
                                              isPaid ? Icons.check_rounded : (isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded),
                                              color: statusColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${inv.unitTitle} (${inv.unitNumber})',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                                              ),
                                              Text(
                                                '${loc.tr('invoiceNo')}: ${inv.invoiceNumber}',
                                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(height: 20, color: colorScheme.outlineVariant),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(loc.tr('totalDueToPay'), style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${CurrencyFormatter.formatAmount(inv.totalAmountDue, langCode: lang)} $currency',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOverdue ? colorScheme.error : colorScheme.onSurface),
                                          ),
                                        ],
                                      ),
                                      if (isPaid)
                                        TashilButton(
                                          onPressed: () => RentReceiptDialog.show(context, inv),
                                          icon: Icons.receipt_long_rounded,
                                          label: loc.tr('viewOfficialReceipt'),
                                          variant: TashilButtonVariant.outlined,
                                        )
                                      else
                                        TashilButton(
                                          onPressed: () => TenantCheckoutDialog.show(context, inv),
                                          icon: Icons.payment_rounded,
                                          label: loc.tr('payRentNowAction'),
                                          variant: TashilButtonVariant.filled,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
