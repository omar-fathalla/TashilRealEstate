import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/end_lease_confirmation_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/publish_listing_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/record_manual_payment_dialog.dart';

class MonthlyPaymentScheduleDialog extends StatefulWidget {
  final ManagedPropertyModel property;

  const MonthlyPaymentScheduleDialog({super.key, required this.property});

  static void show(BuildContext context, ManagedPropertyModel property) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MonthlyPaymentScheduleDialog(property: property),
    );
  }

  @override
  State<MonthlyPaymentScheduleDialog> createState() => _MonthlyPaymentScheduleDialogState();
}

class _MonthlyPaymentScheduleDialogState extends State<MonthlyPaymentScheduleDialog> {
  String _selectedAction = 'close';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final isMobile = ResponsiveLayout.isMobile(context);
        final lang = locale.languageCode;
        final currency = widget.property.countryCode == 'AE' ? loc.tr('currency_ae') : loc.tr('currency_eg');

        return ValueListenableBuilder<List<ManagedPropertyModel>>(
          valueListenable: PropertyLifecycleService().propertiesNotifier,
          builder: (context, properties, _) {
            final currentProp = properties.firstWhere(
              (p) => p.id == widget.property.id,
              orElse: () => widget.property,
            );

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: theme.colorScheme.surface,
              insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.tr('monthlyPaymentLedgerTitle'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '${currentProp.getTitle(lang)} (${currentProp.unitNumber})',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TashilIconButton.tonal(
                                icon: Icons.edit_calendar_rounded,
                                tooltip: loc.tr('editLeaseTermsBtn'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  PublishListingDialog.show(
                                    context,
                                    currentProp,
                                    initialRentMode: true,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              TashilIconButton.close(
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- TENANT & SUMMARY CARDS ---
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.tr('currentTenantName'), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentProp.tenantName ?? loc.tr('noActiveTenant'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (currentProp.tenantPhone != null)
                                    Text(currentProp.tenantPhone!, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Container(height: 36, width: 1, color: theme.colorScheme.outlineVariant),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.tr('collectedTotal'), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyFormatter.formatAmount(currentProp.totalCollectedRevenue, langCode: lang)} $currency',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${currentProp.paidMonthsCount} ${loc.tr('monthsPaidOutOfTotal')} ${currentProp.installments.isNotEmpty ? currentProp.installments.length : 12} ${loc.tr('month')}',
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- DYNAMIC INSTALLMENT LIST ---
                      Text(
                        '${loc.tr('installmentScheduleForDuration')} (${currentProp.installments.isNotEmpty ? currentProp.installments.length : 12} ${loc.tr('month')})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: currentProp.installments.isEmpty
                            ? Center(
                                child: Text(
                                  loc.tr('noInstallmentScheduleAvailable'),
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                itemCount: currentProp.installments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final inst = currentProp.installments[index];
                                  return _buildInstallmentRow(
                                    context,
                                    loc: loc,
                                    lang: lang,
                                    currency: currency,
                                    prop: currentProp,
                                    installment: inst,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),

                      // --- BOTTOM ACTIONS (M3 CONNECTED BUTTON GROUP) ---
                      const TashilDivider.cardAction(),
                      const SizedBox(height: 12),
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: TashilConnectedButtonGroup<String>(
                            selectedValue: _selectedAction,
                            onSelectionChanged: (action) {
                              setState(() => _selectedAction = action);
                              if (action == 'close') {
                                Navigator.of(context).pop();
                              } else if (action == 'republish') {
                                EndLeaseConfirmationDialog.show(
                                  context,
                                  property: currentProp,
                                ).then((confirmed) {
                                  if (confirmed == true && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                });
                              }
                            },
                            segments: [
                              TashilConnectedButtonSegment(
                                value: 'republish',
                                label: loc.tr('endLeaseAndRepublishBtn'),
                                icon: Icons.storefront_rounded,
                              ),
                              TashilConnectedButtonSegment(
                                value: 'close',
                                label: loc.tr('closeModalBtn'),
                                icon: Icons.close_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstallmentRow(
    BuildContext context, {
    required AppLocalizations loc,
    required String lang,
    required String currency,
    required ManagedPropertyModel prop,
    required MonthlyInstallment installment,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color badgeBg;
    Color badgeFg;
    Color badgeBorder;
    String statusText;
    IconData statusIcon;

    switch (installment.status) {
      case InstallmentPaymentStatus.paidOnline:
        badgeBg = isDark ? const Color(0xFF0F2E1E) : const Color(0xFFE6F4EA);
        badgeFg = isDark ? const Color(0xFF81C995) : const Color(0xFF137333);
        badgeBorder = isDark ? const Color(0xFF34A853).withValues(alpha: 0.5) : const Color(0xFFA8DAB5);
        final methodLabel = installment.paymentMethod == 'apple_pay'
            ? loc.tr('paymentMethodApplePay')
            : installment.paymentMethod == 'google_pay'
                ? loc.tr('paymentMethodGooglePay')
                : loc.tr('paymentMethodOnline');
        statusText = '${loc.tr('paidOnlineBadge')} ($methodLabel)';
        statusIcon = Icons.check_circle_rounded;
        break;
      case InstallmentPaymentStatus.paidCash:
        badgeBg = isDark ? const Color(0xFF132B3A) : const Color(0xFFE8F0FE);
        badgeFg = isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8);
        badgeBorder = isDark ? const Color(0xFF4285F4).withValues(alpha: 0.5) : const Color(0xFFAECBFA);
        statusText = loc.tr('paidCashHandBadge');
        statusIcon = Icons.payments_rounded;
        break;
      case InstallmentPaymentStatus.paidBankWire:
        badgeBg = isDark ? const Color(0xFF2C2211) : const Color(0xFFFEF7E0);
        badgeFg = isDark ? const Color(0xFFFDD663) : const Color(0xFFB06000);
        badgeBorder = isDark ? const Color(0xFFFBBC04).withValues(alpha: 0.5) : const Color(0xFFFEEFC3);
        statusText = loc.tr('paidBankWireBadge');
        statusIcon = Icons.account_balance_rounded;
        break;
      case InstallmentPaymentStatus.overdue:
        badgeBg = isDark ? const Color(0xFF371714) : const Color(0xFFFCE8E6);
        badgeFg = isDark ? const Color(0xFFF28B82) : const Color(0xFFC5221F);
        badgeBorder = isDark ? const Color(0xFFEA4335).withValues(alpha: 0.5) : const Color(0xFFF6AEA9);
        statusText = loc.tr('statusOverdue');
        statusIcon = Icons.warning_amber_rounded;
        break;
      case InstallmentPaymentStatus.due:
        badgeBg = isDark ? const Color(0xFF302008) : const Color(0xFFFFF0D4);
        badgeFg = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
        badgeBorder = isDark ? const Color(0xFFFF9800).withValues(alpha: 0.5) : const Color(0xFFFFCC80);
        statusText = loc.tr('statusDueNow');
        statusIcon = Icons.schedule_rounded;
        break;
      case InstallmentPaymentStatus.upcoming:
        badgeBg = isDark ? const Color(0xFF282A2D) : const Color(0xFFF1F3F4);
        badgeFg = isDark ? const Color(0xFFBDC1C6) : const Color(0xFF5F6368);
        badgeBorder = isDark ? const Color(0xFF5F6368) : const Color(0xFFDADCE0);
        statusText = loc.tr('statusUpcoming');
        statusIcon = Icons.hourglass_empty_rounded;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: isCompact
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                installment.monthNumber,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  installment.getMonthName(lang),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${loc.tr('dueOnDate')}: ${installment.dueDate.year}/${installment.dueDate.month}/${installment.dueDate.day}',
                                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeBorder, width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: badgeFg),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(color: badgeFg, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 14, color: theme.colorScheme.outlineVariant),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${CurrencyFormatter.formatAmount(installment.amount, langCode: lang)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (installment.isPaid)
                          TashilButton.text(
                            onPressed: () {
                              TashilSnackBar.showInfo(
                                context: context,
                                message: '${loc.tr('receiptIssuedLabel')}: ${installment.receiptNumber ?? "REC-2026"} (${installment.transactionRef ?? "DIRECT"})',
                              );
                            },
                            icon: Icons.receipt_rounded,
                            label: loc.tr('receiptIssuedLabel'),
                          )
                        else
                          TashilButton.tonal(
                            onPressed: () => RecordManualPaymentDialog.show(
                              context,
                              property: prop,
                              installment: installment,
                            ),
                            label: loc.tr('recordPaymentBtn'),
                          ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Column 1: Month Name & Due Date
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              installment.monthNumber,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  installment.getMonthName(lang),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${loc.tr('dueOnDate')}: ${installment.dueDate.year}/${installment.dueDate.month}/${installment.dueDate.day}',
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Column 2: Amount
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${CurrencyFormatter.formatAmount(installment.amount, langCode: lang)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Column 3: Status Badge
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeBorder, width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 13, color: badgeFg),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  statusText,
                                  style: TextStyle(color: badgeFg, fontSize: 11, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Column 4: Actions
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: installment.isPaid
                            ? TashilIconButton.tonal(
                                tooltip: loc.tr('viewReceiptTooltip'),
                                icon: Icons.receipt_rounded,
                                onPressed: () {
                                  TashilSnackBar.showInfo(
                                    context: context,
                                    message: '${loc.tr('receiptIssuedLabel')}: ${installment.receiptNumber ?? "REC-2026"} (${installment.transactionRef ?? "DIRECT"})',
                                  );
                                },
                              )
                            : TashilButton.tonal(
                                onPressed: () => RecordManualPaymentDialog.show(
                                  context,
                                  property: prop,
                                  installment: installment,
                                ),
                                label: loc.tr('recordPaymentBtn'),
                              ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
