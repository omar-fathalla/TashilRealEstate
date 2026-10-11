import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/ai_translation_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../models/investor_portfolio_model.dart';

class MonthlyCashFlowDetailsDialog extends StatelessWidget {
  final MonthlyCashFlowItem flow;
  final InvestorPortfolioSummary summary;
  final String currency;
  final String lang;

  const MonthlyCashFlowDetailsDialog({
    super.key,
    required this.flow,
    required this.summary,
    required this.currency,
    required this.lang,
  });

  static Future<void> show(
    BuildContext context, {
    required MonthlyCashFlowItem flow,
    required InvestorPortfolioSummary summary,
    required String currency,
    required String lang,
  }) {
    return TashilTransitions.showM3Dialog(
      context: context,
      builder: (_) => MonthlyCashFlowDetailsDialog(
        flow: flow,
        summary: summary,
        currency: currency,
        lang: lang,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final monthName = AiTranslationService.getLocalizedText(flow.monthName, lang);

    // Identify active rented units for this month
    final isExpandedQuarter = flow.monthKey == '2026-10' || flow.monthKey == '2026-11';
    final activeAssets = summary.assets.where((asset) {
      if (asset.status == AssetStatus.occupied) return true;
      if (isExpandedQuarter && asset.assetType == AssetType.office) return true;
      return false;
    }).toList();

    final totalExpenses = flow.operatingExpensesOutflow + flow.maintenanceOutflow;

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
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        child: Icon(Icons.calendar_month_rounded, color: colorScheme.onPrimaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loc.tr('monthCashFlowDetails')} - $monthName',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            flow.monthKey,
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
              const TashilDivider.middleInset(height: 20),

              // KPI Tri-Card Balance Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: loc.tr('inflows'),
                        amount: '+ ${CurrencyFormatter.formatAmount(flow.grossRentalInflow, langCode: lang)} $currency',
                        color: colorScheme.primary,
                      ),
                    ),
                    Container(width: 1, height: 36, color: colorScheme.outlineVariant),
                    Expanded(
                      child: _buildMetricTile(
                        label: loc.tr('expenses'),
                        amount: '- ${CurrencyFormatter.formatAmount(totalExpenses, langCode: lang)} $currency',
                        color: colorScheme.error,
                      ),
                    ),
                    Container(width: 1, height: 36, color: colorScheme.outlineVariant),
                    Expanded(
                      child: _buildMetricTile(
                        label: loc.tr('netCashFlowLabel'),
                        amount: '+ ${CurrencyFormatter.formatAmount(flow.netCashFlow, langCode: lang)} $currency',
                        color: colorScheme.secondary,
                        isBold: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Status Bubbles / Highlights
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    icon: Icons.check_circle_rounded,
                    label: '${activeAssets.length} ${loc.tr('rentedUnitsCountInMonth')}',
                    color: colorScheme.primary,
                    bgColor: colorScheme.primaryContainer,
                  ),
                  _buildChip(
                    icon: Icons.pie_chart_rounded,
                    label: '${loc.tr('portfolioOccupancy')}: ${isExpandedQuarter ? '100%' : '75%'}',
                    color: colorScheme.secondary,
                    bgColor: colorScheme.secondaryContainer,
                  ),
                  _buildChip(
                    icon: Icons.verified_rounded,
                    label: loc.tr('settlementCompleted'),
                    color: colorScheme.tertiary,
                    bgColor: colorScheme.tertiaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section: Rented Units Breakdown
              Text(
                loc.tr('rentedUnitsCountInMonth'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ...activeAssets.map((asset) {
                final assetName = AiTranslationService.getLocalizedText(asset.name, lang);
                final assetLocation = AiTranslationService.getLocalizedText(asset.location, lang);
                final rent = asset.monthlyRent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.apartment_rounded, color: colorScheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assetName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${loc.tr('tenant')}: ${asset.tenantName ?? loc.tr('statusOccupied')} • $assetLocation',
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+ ${CurrencyFormatter.formatAmount(rent, langCode: lang)} $currency',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Section: Expenses Breakdown
              Text(
                loc.tr('expenses'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    _buildDeductionRow(
                      label: loc.tr('operatingAndManagementFees'),
                      amount: flow.operatingExpensesOutflow,
                      currency: currency,
                      lang: lang,
                      colorScheme: colorScheme,
                    ),
                    const Divider(height: 14),
                    _buildDeductionRow(
                      label: loc.tr('maintenanceFeesDeducted'),
                      amount: flow.maintenanceOutflow,
                      currency: currency,
                      lang: lang,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
              const TashilDivider.cardAction(height: 24),

              // Footer Actions
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
                        message: '${loc.tr('exportMonthStatement')} ($monthName)',
                      );
                    },
                    icon: Icons.picture_as_pdf_outlined,
                    label: loc.tr('exportMonthStatement'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String amount,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionRow({
    required String label,
    required double amount,
    required String currency,
    required String lang,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        Text(
          '- ${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.error),
        ),
      ],
    );
  }
}
