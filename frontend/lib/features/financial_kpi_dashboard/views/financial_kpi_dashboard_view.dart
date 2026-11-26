import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button.dart';
import 'package:tashil_real_estate/core/design_system/empty_state/tashil_empty_state.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/services/financial_kpi_service.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/widgets/financial_kpi_summary_grid.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/widgets/revenue_vs_expense_chart_card.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/widgets/invoice_status_pie_chart_card.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/widgets/arrears_aging_analysis_card.dart';
import 'package:tashil_real_estate/features/investor_dashboard/services/investor_analytics_service.dart';
import 'package:tashil_real_estate/features/investor_dashboard/widgets/investor_report_dialog.dart';
import 'package:tashil_real_estate/features/executive_reporting/widgets/executive_financial_report_dialog.dart';

class FinancialKpiDashboardView extends StatelessWidget {
  final FinancialPortalRole role;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  /// When given, every figure is computed from that portfolio's real leases and payments.
  final PortfolioController? portfolio;

  const FinancialKpiDashboardView({
    super.key,
    this.role = FinancialPortalRole.owner,
    this.physics,
    this.padding,
    this.portfolio,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final service = FinancialKpiService();

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, countryCode, _) {
            final isUAE = countryCode == 'AE';
            final currency =
                isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
            final lang = locale.languageCode;

            Widget content(FinancialKpiSummary summary) {
              return SingleChildScrollView(
                physics: physics,
                padding: padding ?? EdgeInsets.all(isMobile ? 14 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Banner with Export Button
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getRoleTitle(role, loc),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.tr('financialKpiDashboardSubtitle'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (role == FinancialPortalRole.superAdmin ||
                                role == FinancialPortalRole.agency)
                              TashilButton.tonal(
                                onPressed: () =>
                                    ExecutiveFinancialReportDialog.show(
                                        context),
                                icon: Icons.analytics_rounded,
                                label: loc.tr('executiveReportTitle'),
                              ),
                            TashilButton(
                              onPressed: () {
                                final investorSummary =
                                    InvestorAnalyticsService().currentSummary;
                                InvestorReportDialog.show(
                                    context, investorSummary);
                              },
                              icon: Icons.picture_as_pdf_rounded,
                              label: loc.tr('exportOfficialAuditStatementBtn'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. KPI 4-Tokens Summary Grid
                    FinancialKpiSummaryGrid(
                      summary: summary,
                      currency: currency,
                      lang: lang,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),

                    // 2. Revenue vs Expense 12-Month Net Profit Chart
                    RevenueVsExpenseChartCard(
                      history: summary.cashFlowHistory,
                      currency: currency,
                      lang: lang,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),

                    // 3. Invoice Distribution Donut + Arrears Aging Row
                    if (isMobile) ...[
                      InvoiceStatusPieChartCard(
                        distribution: summary.statusDistribution,
                        currency: currency,
                        lang: lang,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 16),
                      ArrearsAgingAnalysisCard(
                        buckets: summary.arrearsAging,
                        totalOverdue: summary.totalOverdueArrears,
                        currency: currency,
                        lang: lang,
                        isMobile: isMobile,
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: InvoiceStatusPieChartCard(
                              distribution: summary.statusDistribution,
                              currency: currency,
                              lang: lang,
                              isMobile: isMobile,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: ArrearsAgingAnalysisCard(
                              buckets: summary.arrearsAging,
                              totalOverdue: summary.totalOverdueArrears,
                              currency: currency,
                              lang: lang,
                              isMobile: isMobile,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }

            final live = portfolio;
            if (live == null) {
              return content(service.getFinancialSummary(
                  role: role, countryCode: countryCode));
            }
            return ListenableBuilder(
              listenable: live,
              builder: (context, _) {
                final snapshot = live.snapshot;
                if (snapshot.load == PortfolioLoad.signedOut) {
                  return content(service.getFinancialSummary(role: role, countryCode: countryCode));
                }
                if (snapshot.isLoading) {
                  return const Center(child: TashilLoadingIndicator());
                }
                if (snapshot.load == PortfolioLoad.error) {
                  return TashilEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: loc.tr('ovLoadFailedTitle'),
                    message: loc.tr('ovLoadFailedMessage'),
                    primaryActionLabel: loc.tr('ovRetry'),
                    primaryActionIcon: Icons.refresh_rounded,
                    onPrimaryAction: live.start,
                  );
                }
                if (snapshot.load == PortfolioLoad.noAgency) {
                  return TashilEmptyState(
                    icon: Icons.business_outlined,
                    title: loc.tr('ovNoAgencyTitle'),
                    message: loc.tr('ovNoAgencyMessage'),
                  );
                }
                if (FinancialKpiService.realInvoiceCount(
                        snapshot, countryCode) ==
                    0) {
                  return TashilEmptyState(
                    icon: Icons.insights_outlined,
                    title: loc.tr('fkEmptyTitle'),
                    message: loc.tr('fkEmptyMessage'),
                  );
                }
                return content(service.summaryFromPortfolio(
                    role: role, countryCode: countryCode, snapshot: snapshot));
              },
            );
          },
        );
      },
    );
  }

  String _getRoleTitle(FinancialPortalRole role, AppLocalizations loc) {
    switch (role) {
      case FinancialPortalRole.owner:
        return loc.tr('ownerFinancialKpiTitle');
      case FinancialPortalRole.agency:
        return loc.tr('agencyFinancialKpiTitle');
      case FinancialPortalRole.superAdmin:
        return loc.tr('superAdminFinancialKpiTitle');
    }
  }
}
