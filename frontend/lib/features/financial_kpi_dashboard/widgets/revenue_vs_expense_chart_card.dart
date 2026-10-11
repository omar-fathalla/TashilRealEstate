import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';

class RevenueVsExpenseChartCard extends StatelessWidget {
  final List<MonthlyCashFlowPoint> history;
  final String currency;
  final String lang;
  final bool isMobile;

  const RevenueVsExpenseChartCard({
    super.key,
    required this.history,
    required this.currency,
    required this.lang,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxIncome = history.map((e) => e.grossIncome).fold<double>(0, max);
    final safeMax = maxIncome > 0 ? maxIncome : 1.0;

    return TashilCard.outlined(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bar_chart_rounded, color: colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('monthlyRevenueVsExpensesChartTitle'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.tr('netProfitCashFlowTrendSubtitle'),
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildLegendItem(loc.tr('grossIncomeLegend'), colorScheme.primary, colorScheme),
                  _buildLegendItem(loc.tr('expensesLegend'), colorScheme.error, colorScheme),
                  _buildLegendItem(loc.tr('netProfitLegend'), colorScheme.secondary, colorScheme),
                ],
              ),
            ],
          ),
          const TashilDivider.middleInset(height: 24),

          // Visual Multi-Bar & Progress Chart
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: history.map((pt) {
                final monthName = AiTranslationService.getLocalizedText(pt.localizedMonth, lang);
                final incomeHeightRatio = (pt.grossIncome / safeMax) * 140;
                final expenseHeightRatio = (pt.operationalExpenses / safeMax) * 140;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Net Profit Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${(pt.netProfit / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Dual Bar (Income & Expense)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Income Bar
                            Container(
                              width: isMobile ? 8 : 14,
                              height: max(incomeHeightRatio, 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 3),
                            // Expense Bar
                            Container(
                              width: isMobile ? 6 : 10,
                              height: max(expenseHeightRatio, 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.error, colorScheme.error.withValues(alpha: 0.7)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Month Label
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const TashilDivider.cardAction(height: 24),

          // Pinned Summary Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 18, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${loc.tr('averageMonthlyNetProfit')}: ${CurrencyFormatter.formatAmount(history.last.netProfit, langCode: lang)} $currency',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  loc.tr('yoyProfitGrowthRate'),
                  style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

