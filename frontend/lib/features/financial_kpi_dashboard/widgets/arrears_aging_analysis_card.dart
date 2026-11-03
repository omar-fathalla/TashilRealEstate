import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/progress/tashil_progress.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/legal_warning_notice_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';

class ArrearsAgingAnalysisCard extends StatelessWidget {
  final List<ArrearsAgingBucket> buckets;
  final double totalOverdue;
  final String currency;
  final String lang;
  final bool isMobile;

  const ArrearsAgingAnalysisCard({
    super.key,
    required this.buckets,
    required this.totalOverdue,
    required this.currency,
    required this.lang,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TashilCard.outlined(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.warning_amber_rounded, color: colorScheme.tertiary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('arrearsAgingAnalysisChartTitle'),
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.tr('arrearsAgingAnalysisSubtitle'),
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${loc.tr('totalOverdueArrears')}: ${CurrencyFormatter.formatAmount(totalOverdue, langCode: lang)} $currency',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.tertiary),
                ),
              ),
            ],
          ),
          const TashilDivider.middleInset(height: 24),

          // Aging Buckets List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: buckets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = buckets[index];
              final rangeLabel = AiTranslationService.getLocalizedText(b.localizedRange, lang);
              final progress = totalOverdue > 0 ? (b.amount / totalOverdue) : 0.0;
              final isHighRisk = index == 2 && b.amount > 0;
              final bucketColor = colorScheme.tertiary;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighRisk ? colorScheme.tertiary : colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              index == 0 ? Symbols.timer_rounded : index == 1 ? Symbols.warning_rounded : Symbols.gavel_rounded,
                              size: 16,
                              color: bucketColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rangeLabel,
                              style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Text(
                                '${b.invoiceCount} ${loc.tr('invoicesWord')}',
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${CurrencyFormatter.formatAmount(b.amount, langCode: lang)} $currency',
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                            color: bucketColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TashilLinearProgressIndicator.flat(
                      value: progress.clamp(0.0, 1.0),
                      thickness: 6,
                      color: bucketColor,
                      trackColor: colorScheme.surfaceContainerHighest,
                      showStopIndicator: false,
                      useContainerInset: false,
                    ),
                  ],
                ),
              );
            },
          ),
          const TashilDivider.cardAction(height: 24),

          // Legal Warning Action Button Pinned Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: TashilButton.tonal(
                    onPressed: () {
                      final invoices = RentCollectionService().invoicesNotifier.value;
                      final overdue = invoices.firstWhere(
                        (inv) => inv.status == 'overdue',
                        orElse: () => invoices.first,
                      );
                      LegalWarningNoticeDialog.show(context, overdue);
                    },
                    icon: Symbols.gavel_rounded,
                    label: loc.tr('issueStatutoryNoticeForOverdueArrears'),
                    customColor: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

