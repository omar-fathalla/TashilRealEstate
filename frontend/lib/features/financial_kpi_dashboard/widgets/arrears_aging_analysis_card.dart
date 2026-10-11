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
                        color: colorScheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('arrearsAgingAnalysisChartTitle'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.tr('arrearsAgingAnalysisSubtitle'),
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
                  color: colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${loc.tr('totalOverdueArrears')}: ${CurrencyFormatter.formatAmount(totalOverdue, langCode: lang)} $currency',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: colorScheme.error),
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
              final bucketColor = index == 0 ? colorScheme.tertiary : colorScheme.error;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHighRisk ? colorScheme.error : colorScheme.outlineVariant,
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
                              index == 0 ? Icons.timer_outlined : index == 1 ? Icons.warning_rounded : Icons.gavel_rounded,
                              size: 16,
                              color: bucketColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rangeLabel,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface),
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
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${CurrencyFormatter.formatAmount(b.amount, langCode: lang)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: bucketColor,
                          ),
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
                    icon: Icons.gavel_rounded,
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

