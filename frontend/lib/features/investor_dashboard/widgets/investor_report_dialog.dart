import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/features/investor_dashboard/models/investor_portfolio_model.dart';

class InvestorReportDialog extends StatelessWidget {
  final InvestorPortfolioSummary summary;

  const InvestorReportDialog({super.key, required this.summary});

  static Future<void> show(BuildContext context, InvestorPortfolioSummary summary) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => InvestorReportDialog(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = CountryController.isUAE;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    final String reportDate;
    if (lang == 'ar') {
      reportDate = '30 نوفمبر 2026';
    } else if (lang == 'hi') {
      reportDate = '30 नवंबर 2026';
    } else {
      reportDate = 'November 30, 2026';
    }
    final refNumber = isUAE ? 'INV-AE-2026-8819' : 'INV-EG-2026-9941';

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      elevation: 6.0,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.25),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 36,
        vertical: isMobile ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 20 : 28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 820),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Actions
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
                            Icons.picture_as_pdf_rounded,
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
                                loc.tr('officialInvestorReportTitle'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Ref: $refNumber • $reportDate',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TashilIconButton.close(
                    tooltip: loc.tr('close'),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ],
              ),
              const TashilDivider.middleInset(height: 24),

              // Printable Document Container
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Legal Entity Letterhead
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.domain_verification_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        loc.tr('appName'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isUAE
                                        ? loc.tr('regulatoryAuthorityAe')
                                        : loc.tr('regulatoryAuthorityEg'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Text(
                                loc.tr('certifiedAuditedStatement'),
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Summary Statistics Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildReportMetric(
                                  theme,
                                  loc.tr('livePortfolioValuation'),
                                  '${CurrencyFormatter.formatAmount(summary.totalPortfolioValue, langCode: lang)} $currency',
                                ),
                              ),
                              Container(height: 36, width: 1, color: theme.colorScheme.outlineVariant),
                              Expanded(
                                child: _buildReportMetric(
                                  theme,
                                  loc.tr('netAnnualCashFlow'),
                                  '${CurrencyFormatter.formatAmount(summary.netAnnualCashFlow, langCode: lang)} $currency',
                                ),
                              ),
                              Container(height: 36, width: 1, color: theme.colorScheme.outlineVariant),
                              Expanded(
                                child: _buildReportMetric(
                                  theme,
                                  loc.tr('netRoi'),
                                  '${summary.portfolioNetRoi.toStringAsFixed(2)}%',
                                ),
                              ),
                              Container(height: 36, width: 1, color: theme.colorScheme.outlineVariant),
                              Expanded(
                                child: _buildReportMetric(
                                  theme,
                                  loc.tr('portfolioOccupancy'),
                                  '${summary.occupancyRate.toStringAsFixed(0)}% (${summary.occupiedUnitsCount}/${summary.totalUnitsCount})',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Asset Inventory Table
                        Text(
                          loc.tr('assetInventoryTitle'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              theme.colorScheme.surfaceContainerHigh,
                            ),
                            columnSpacing: isMobile ? 16 : 28,
                            horizontalMargin: 12,
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 56,
                            columns: [
                              DataColumn(label: Text(loc.tr('propertyName'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface))),
                              DataColumn(label: Text(loc.tr('purchasePrice'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface))),
                              DataColumn(label: Text(loc.tr('currentMarketValuation'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface))),
                              DataColumn(label: Text(loc.tr('grossYield'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface))),
                              DataColumn(label: Text(loc.tr('netRoi'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface))),
                              DataColumn(label: Text(loc.tr('status'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface))),
                            ],
                            rows: summary.assets.map((a) {
                              final name = AiTranslationService.getLocalizedText(a.name, lang);
                              final isOccupied = a.status == AssetStatus.occupied;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface)),
                                        Text(AiTranslationService.getLocalizedText(a.location, lang), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text('${CurrencyFormatter.formatAmount(a.purchasePrice, langCode: lang)} $currency', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))),
                                  DataCell(Text('${CurrencyFormatter.formatAmount(a.currentMarketValue, langCode: lang)} $currency', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                                  DataCell(Text('${a.grossYieldPercentage.toStringAsFixed(2)}%', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                                  DataCell(Text('${a.netRoiPercentage.toStringAsFixed(2)}%', style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOccupied
                                            ? theme.colorScheme.primaryContainer
                                            : theme.colorScheme.tertiaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isOccupied ? loc.tr('statusOccupied') : loc.tr('statusVacant'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isOccupied
                                              ? theme.colorScheme.onPrimaryContainer
                                              : theme.colorScheme.onTertiaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Auditor Stamp & QR Code Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr('certifiedFinancialAdvisorSignature'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 44,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.verified_user_rounded, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.tr('appName'),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.primary),
                                  ),
                                  Text(
                                    loc.tr('officiallyVerified'),
                                    style: TextStyle(fontSize: 8, letterSpacing: 1.1, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const TashilDivider.cardAction(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TashilButton.tonal(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    label: loc.tr('close'),
                  ),
                  const SizedBox(width: 12),
                  TashilButton.filled(
                    onPressed: () {
                      TashilSnackBar.showSuccess(
                        context: context,
                        message: loc.tr('investorReportExportedSuccess'),
                      );
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    icon: Icons.download_rounded,
                    label: loc.tr('downloadOfficialPdfStatement'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportMetric(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
