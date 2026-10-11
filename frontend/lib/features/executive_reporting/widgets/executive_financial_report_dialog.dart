import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/loading/tashil_loading.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../models/executive_report_model.dart';
import '../services/ai_executive_reporting_service.dart';

class ExecutiveFinancialReportDialog extends StatefulWidget {
  final String? initialPeriod;

  const ExecutiveFinancialReportDialog({
    super.key,
    this.initialPeriod,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialPeriod,
  }) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ExecutiveFinancialReportDialog(
        initialPeriod: initialPeriod,
      ),
    );
  }

  @override
  State<ExecutiveFinancialReportDialog> createState() =>
      _ExecutiveFinancialReportDialogState();
}

class _ExecutiveFinancialReportDialogState
    extends State<ExecutiveFinancialReportDialog> {
  final _service = AiExecutiveReportingService();

  String _selectedPeriod = 'Q3 2026';
  bool _isLoading = true;
  ExecutiveFinancialReport? _report;

  @override
  void initState() {
    super.initState();
    if (widget.initialPeriod != null) {
      _selectedPeriod = widget.initialPeriod!;
    }
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final country = CountryController.countryCode;
    final rpt = await _service.generateExecutiveReport(
      countryCode: country,
      period: _selectedPeriod,
    );

    if (mounted) {
      setState(() {
        _report = rpt;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1040,
        height: 780,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // Top Header
            _buildHeader(loc),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 14),

            // Content Area
            Expanded(
              child: _isLoading || _report == null
                  ? _buildLoadingState(loc)
                  : _buildReportContent(loc, lang),
            ),
            const TashilDivider.cardAction(),
            const SizedBox(height: 12),

            // Bottom Multi-Format Export Actions
            if (_report != null && !_isLoading)
              _buildBottomActionToolbar(loc, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final theme = Theme.of(context);
    final periods = ['Q1 2026', 'Q2 2026', 'Q3 2026', '2026 Annual'];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.analytics_rounded, color: theme.colorScheme.onPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    loc.tr('executiveReportTitle'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Gemini Pro Insights',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('executiveReportSubtitle'),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // Period Selector dropdown / pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: theme.colorScheme.surface,
              items: periods
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null && val != _selectedPeriod) {
                  setState(() => _selectedPeriod = val);
                  _loadReport();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        TashilIconButton.standard(
          tooltip: loc.tr('regenerateReportBtn'),
          onPressed: _loadReport,
          icon: Icons.refresh_rounded,
        ),
        const SizedBox(width: 6),
        TashilIconButton.close(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: loc.tr('close'),
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppLocalizations loc) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TashilLoadingIndicator(size: 48.0),
          const SizedBox(height: 16),
          Text(
            loc.tr('generatingExecutiveReportProgress'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            loc.tr('geminiAggregatingFinancialMetrics'),
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(AppLocalizations loc, String lang) {
    final report = _report!;
    final isAE = report.countryCode == 'AE';
    final currency = isAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Executive Financial KPI Cards
          _buildExecutiveKpiCards(report, loc, lang, currency),
          const SizedBox(height: 18),

          // Gemini Executive Summary Box
          _buildExecutiveSummaryBox(report, loc, lang),
          const SizedBox(height: 18),

          // Monthly Financial Breakdown
          _buildMonthlyBreakdownSection(report, loc, lang, currency),
          const SizedBox(height: 18),

          // Lease Expiration Risk Alerts & Recommendations
          _buildLeaseExpirationRisksSection(report, loc, lang, currency),
          const SizedBox(height: 18),

          // Strategic Growth Recommendations
          _buildStrategicGrowthSection(report, loc, lang),
        ],
      ),
    );
  }

  Widget _buildExecutiveKpiCards(
    ExecutiveFinancialReport report,
    AppLocalizations loc,
    String lang,
    String currency,
  ) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 650;
      final cardWidth = isCompact ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildKpiCard(
            title: loc.tr('grossRentalIncomeLabel'),
            value: '${CurrencyFormatter.formatAmount(report.grossRentalIncome, langCode: lang)} $currency',
            subtitle: '${loc.tr('operatingExpensesShort')}: ${CurrencyFormatter.formatAmount(report.operatingExpenses, langCode: lang)}',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: theme.colorScheme.primary,
            width: cardWidth,
          ),
          _buildKpiCard(
            title: loc.tr('netOperatingIncomeNoi'),
            value: '${CurrencyFormatter.formatAmount(report.netOperatingIncome, langCode: lang)} $currency',
            subtitle: '${loc.tr('growthQuarterly')}: +14.2%',
            icon: Icons.trending_up_rounded,
            accentColor: theme.colorScheme.secondary,
            width: cardWidth,
          ),
          _buildKpiCard(
            title: loc.tr('capRateLabel'),
            value: '${report.capRatePercentage}%',
            subtitle: '${loc.tr('cashOnCashReturn')}: ${report.cashOnCashReturnPercentage}%',
            icon: Icons.pie_chart_rounded,
            accentColor: theme.colorScheme.tertiary,
            width: cardWidth,
          ),
          _buildKpiCard(
            title: loc.tr('rentCollectionEfficiency'),
            value: '${report.rentCollectionEfficiencyPercentage}%',
            subtitle: '${loc.tr('occupancy')}: ${report.occupancyRatePercentage}% (${report.activeLeasesCount}/${report.totalManagedUnits})',
            icon: Icons.verified_user_rounded,
            accentColor: theme.colorScheme.primary,
            width: cardWidth,
          ),
        ],
      );
    });
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummaryBox(
    ExecutiveFinancialReport report,
    AppLocalizations loc,
    String lang,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.onPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                loc.tr('geminiExecutiveSummaryHeading'),
                style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.getExecutiveSummary(lang),
            style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.9), fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, size: 16, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.getCashFlowOutlook(lang),
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdownSection(
    ExecutiveFinancialReport report,
    AppLocalizations loc,
    String lang,
    String currency,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr('monthlyFinancialTrends'),
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: report.monthlyTrends.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        item.getMonthLabel(lang),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.netIncome / item.grossIncome).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${loc.tr('netOperatingIncomeNoi')}: ${CurrencyFormatter.formatAmount(item.netIncome, langCode: lang)} $currency',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaseExpirationRisksSection(
    ExecutiveFinancialReport report,
    AppLocalizations loc,
    String lang,
    String currency,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 6),
            Text(
              loc.tr('leaseExpirationAlertsTitle'),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.colorScheme.error),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...report.leaseExpirationRisks.map((risk) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${risk.daysRemaining} ${loc.tr('daysRemaining')}',
                    style: TextStyle(color: theme.colorScheme.onError, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${risk.getTitle(lang)} • ${loc.tr('tenantLabel')}: ${risk.tenantName}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${loc.tr('recommendedAction')}: ${risk.getRecommendation(lang)}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onErrorContainer),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${CurrencyFormatter.formatAmount(risk.currentMonthlyRent, langCode: lang)} $currency / ${loc.tr('perMonth')}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStrategicGrowthSection(
    ExecutiveFinancialReport report,
    AppLocalizations loc,
    String lang,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rocket_launch_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              loc.tr('strategicGrowthOpportunitiesTitle'),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...report.strategicGrowthRecommendations.map((rec) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up_rounded, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rec.getTitle(lang),
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${rec.projectedRoiPercentage}% ROI',
                              style: TextStyle(color: theme.colorScheme.onTertiaryContainer, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.getDescription(lang),
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${loc.tr('targetRegion')}: ${rec.targetRegion} • ${loc.tr('capitalRequired')}: ${rec.estimatedCapitalRequired}',
                        style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomActionToolbar(AppLocalizations loc, String lang) {
    return Row(
      children: [
        // Export PDF
        Expanded(
          child: TashilButton(
            onPressed: () {
              TashilSnackBar.showSuccess(
                context: context,
                message: loc.tr('pdfReportExportedNotification'),
              );
            },
            icon: Icons.picture_as_pdf_outlined,
            label: loc.tr('exportPdfReportBtn'),
            variant: TashilButtonVariant.filled,
          ),
        ),
        const SizedBox(width: 8),

        // Export CSV
        Expanded(
          child: TashilButton.outlined(
            onPressed: () {
              TashilSnackBar.showSuccess(
                context: context,
                message: loc.tr('csvExportedNotification'),
              );
            },
            icon: Icons.table_chart_outlined,
            label: loc.tr('exportCsvBtn'),
          ),
        ),
        const SizedBox(width: 8),

        // Share WhatsApp
        Expanded(
          child: TashilButton.tonal(
            onPressed: () {
              TashilSnackBar.showSuccess(
                context: context,
                message: loc.tr('whatsAppDigestCopiedNotification'),
              );
            },
            icon: Icons.share_rounded,
            label: loc.tr('shareWhatsAppDigestBtn'),
          ),
        ),
      ],
    );
  }
}
