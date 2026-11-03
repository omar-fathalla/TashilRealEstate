import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:material_symbols_icons/symbols.dart';

class FinancialKpiSummaryGrid extends StatelessWidget {
  final FinancialKpiSummary summary;
  final String currency;
  final String lang;
  final bool isMobile;

  const FinancialKpiSummaryGrid({
    super.key,
    required this.summary,
    required this.currency,
    required this.lang,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cards = [
      _buildCard(
        context: context,
        title: loc.tr('netCollectedProfitsKpi'),
        value: '${CurrencyFormatter.formatAmount(summary.totalCollectedNet, langCode: lang)} $currency',
        subtitle: '${loc.tr('netMarginRatio')}: ${summary.netProfitMargin.toStringAsFixed(1)}%',
        icon: Symbols.account_balance_wallet_rounded,
        color: colorScheme.secondary,
        bgColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        colorScheme: colorScheme,
      ),
      _buildCard(
        context: context,
        title: loc.tr('grossInvoicedTotalKpi'),
        value: '${CurrencyFormatter.formatAmount(summary.totalGrossInvoiced, langCode: lang)} $currency',
        subtitle: '${loc.tr('grossRentalYield')}: ${summary.grossRentalYield.toStringAsFixed(1)}%',
        icon: Symbols.receipt_long_rounded,
        color: colorScheme.primary,
        bgColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        colorScheme: colorScheme,
      ),
      _buildCard(
        context: context,
        title: loc.tr('collectionEfficiencyRateKpi'),
        value: '${summary.collectionEfficiencyRate.toStringAsFixed(1)}%',
        subtitle: loc.tr('onTimeCollectionHighPerformance'),
        icon: Symbols.speed_rounded,
        color: colorScheme.tertiary,
        bgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        colorScheme: colorScheme,
      ),
      _buildCard(
        context: context,
        title: loc.tr('totalOverdueArrearsKpi'),
        value: '${CurrencyFormatter.formatAmount(summary.totalOverdueArrears, langCode: lang)} $currency',
        subtitle: loc.tr('escalationNoticeActiveNotice'),
        icon: Symbols.warning_amber_rounded,
        color: colorScheme.tertiary,
        bgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        colorScheme: colorScheme,
      ),
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;
        final isSingleColumn = constraints.maxWidth < 620;
        final crossAxisCount = isSingleColumn ? 1 : (isNarrow ? 2 : 4);
        final aspectRatio = isSingleColumn ? 2.5 : (isNarrow ? 1.75 : 1.35);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: cards,
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required ColorScheme colorScheme,
  }) {
    return TashilCard.outlined(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600,
                        color: color),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

