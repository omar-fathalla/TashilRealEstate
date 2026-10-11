import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/lists/tashil_reorderable_list.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/features/dynamic_pricing/widgets/dynamic_pricing_tab_view.dart';
import 'package:tashil_real_estate/features/dynamic_pricing/widgets/dynamic_yield_curve_tab_view.dart';
import 'package:tashil_real_estate/features/executive_reporting/widgets/executive_reporting_tab_view.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/investor_dashboard/models/investor_portfolio_model.dart';
import 'package:tashil_real_estate/features/investor_dashboard/services/investor_analytics_service.dart';
import 'package:tashil_real_estate/features/investor_dashboard/widgets/investment_simulator_dialog.dart';
import '../widgets/investor_report_dialog.dart';
import '../widgets/monthly_cash_flow_details_dialog.dart';

class InvestorDashboardView extends StatefulWidget {
  const InvestorDashboardView({super.key});

  @override
  State<InvestorDashboardView> createState() => _InvestorDashboardViewState();
}

class _InvestorDashboardViewState extends State<InvestorDashboardView> {
  final _service = InvestorAnalyticsService();
  int _selectedTab = 0; // 0: Assets & ROI, 1: KPI Charts, 2: Dynamic Pricing, 3: Full Curve, 4: Executive Report, 5: Cash Flow, 6: Payouts
  String? _expandedMonthKey;
  String? _expandedPayoutRef;
  List<PortfolioAssetItem>? _customOrderedAssets;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: CountryController.currentCountry,
      builder: (context, countryCode, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isMobile = ResponsiveLayout.isMobile(context);
        final isUAE = countryCode == 'AE';
        final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
        final lang = LocaleController.languageCode;

        return ValueListenableBuilder<InvestorPortfolioSummary>(
          valueListenable: _service.currentSummaryNotifier as ValueNotifier<InvestorPortfolioSummary>,
          builder: (context, summary, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Block - Fully Responsive Layout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('investorDashboardTitle'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.tr('investorDashboardSubtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Responsive Action Toolbar with M3 Button Group Suite
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TashilConnectedButtonGroup<String>(
                            selectedValue: null,
                            onSelectionChanged: (action) {
                              if (action == 'simulator') {
                                InvestmentSimulatorDialog.show(context);
                              } else if (action == 'exportPdf') {
                                InvestorReportDialog.show(context, summary);
                              }
                            },
                            segments: [
                              TashilConnectedButtonSegment<String>(
                                value: 'simulator',
                                label: loc.tr('investmentSimulatorTitle'),
                                icon: Icons.calculate_outlined,
                              ),
                              TashilConnectedButtonSegment<String>(
                                value: 'exportPdf',
                                label: loc.tr('exportInvestorReportPdf'),
                                icon: Icons.picture_as_pdf_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4 Live KPI Hero Cards
                  _buildKpiHeroGrid(summary, currency, lang, loc, isMobile, colorScheme),
                  const SizedBox(height: 24),

                  // Official M3 Expressive Connected Button Group Sub-Tab Switcher
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TashilConnectedButtonGroup<int>(
                      selectedValue: _selectedTab,
                      onSelectionChanged: (tabIndex) {
                        setState(() {
                          _selectedTab = tabIndex;
                        });
                      },
                      segments: [
                        TashilConnectedButtonSegment<int>(
                          value: 0,
                          label: loc.tr('portfolioAssetsBreakdown'),
                          icon: Icons.apartment_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 1,
                          label: loc.tr('financialKpiChartsTab'),
                          icon: Icons.analytics_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 2,
                          label: loc.tr('dynamicYieldOptimizerTitle'),
                          icon: Icons.bolt_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 3,
                          label: loc.tr('fullInteractiveCurveTab'),
                          icon: Icons.show_chart_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 4,
                          label: loc.tr('recentPayouts'),
                          icon: Icons.receipt_long_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 5,
                          label: loc.tr('executiveReportTitle'),
                          icon: Icons.auto_awesome_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 6,
                          label: loc.tr('monthlyCashFlowHistory'),
                          icon: Icons.waterfall_chart_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected Tab Content with M3 Motion Transition
                  AnimatedSwitcher(
                    duration: TashilMotionDuration.medium2,
                    switchInCurve: TashilMotionEasing.emphasizedDecelerate,
                    switchOutCurve: TashilMotionEasing.emphasizedAccelerate,
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedTab),
                      child: _buildCurrentTab(summary, currency, lang, loc, isMobile, colorScheme),
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

  Widget _buildCurrentTab(
    InvestorPortfolioSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    if (_selectedTab == 0) {
      return _buildAssetsBreakdownTab(summary, currency, lang, loc, isMobile, colorScheme);
    } else if (_selectedTab == 1) {
      return const FinancialKpiDashboardView(
        role: FinancialPortalRole.owner,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
      );
    } else if (_selectedTab == 2) {
      return DynamicPricingTabView(
        onOpenFullYieldCurve: () => setState(() => _selectedTab = 3),
      );
    } else if (_selectedTab == 3) {
      return const DynamicYieldCurveTabView();
    } else if (_selectedTab == 4) {
      return _buildPayoutsTab(summary, currency, lang, loc, colorScheme);
    } else if (_selectedTab == 5) {
      return const ExecutiveReportingTabView();
    } else {
      return _buildCashFlowTab(summary, currency, lang, loc, isMobile, colorScheme);
    }
  }

  Widget _buildKpiHeroGrid(
    InvestorPortfolioSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return TashilKpiGrid(
      cards: [
        TashilKpiCard(
          title: loc.tr('livePortfolioValuation'),
          value: '${CurrencyFormatter.formatAmount(summary.totalPortfolioValue, langCode: lang)} $currency',
          subtitle: '+${summary.portfolioCapitalGrowthRate.toStringAsFixed(1)}% ${loc.tr('capitalAppreciationRate')}',
          icon: Icons.account_balance_rounded,
          subtitleIcon: Icons.trending_up_rounded,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.surfaceContainerHigh,
        ),
        TashilKpiCard(
          title: loc.tr('netAnnualCashFlow'),
          value: '${CurrencyFormatter.formatAmount(summary.netAnnualCashFlow, langCode: lang)} $currency',
          subtitle: '${loc.tr('grossRent')}: ${CurrencyFormatter.formatAmount(summary.grossAnnualRentalIncome, langCode: lang)}',
          icon: Icons.trending_up_rounded,
          subtitleIcon: Icons.payments_outlined,
          iconColor: colorScheme.secondary,
          iconBgColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('netRoi'),
          value: '${summary.portfolioNetRoi.toStringAsFixed(2)}%',
          subtitle: '${loc.tr('grossYield')}: ${summary.portfolioGrossYield.toStringAsFixed(2)}%',
          icon: Icons.pie_chart_rounded,
          subtitleIcon: Icons.analytics_outlined,
          iconColor: colorScheme.tertiary,
          iconBgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('portfolioOccupancy'),
          value: '${summary.occupancyRate.toStringAsFixed(0)}%',
          subtitle: '${summary.occupiedUnitsCount} ${loc.tr('leasedUnits')} • ${summary.vacantUnitsCount} ${loc.tr('statusVacant')}',
          icon: Icons.domain_rounded,
          subtitleIcon: Icons.apartment_rounded,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.surfaceContainerHigh,
        ),
      ],
    );
  }


  Widget _buildAssetsBreakdownTab(
    InvestorPortfolioSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    if (_customOrderedAssets == null || _customOrderedAssets!.length != summary.assets.length) {
      _customOrderedAssets = List<PortfolioAssetItem>.from(summary.assets);
    }
    final assets = _customOrderedAssets!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                '${loc.tr('assetInventoryTitle')} (${assets.length})',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_indicator_rounded, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      loc.tr('reorderableListHint'),
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                loc.tr('liveZestimateValuationsActive'),
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        TashilReorderableList<PortfolioAssetItem>(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          showDividers: false,
          items: assets,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _customOrderedAssets!.removeAt(oldIndex);
              _customOrderedAssets!.insert(newIndex, item);
            });
            TashilSnackBar.showSuccess(
              context: context,
              message: loc.tr('reorderSuccessHint'),
            );
          },
          itemBuilder: (context, index, asset) {
            final name = AiTranslationService.getLocalizedText(asset.name, lang);
            final location = AiTranslationService.getLocalizedText(asset.location, lang);
            final isOccupied = asset.status == AssetStatus.occupied;

            return TashilStaggeredEntrance(
              key: ValueKey(asset.id),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TashilCard.outlined(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(14),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                TashilReorderHandle(
                                  index: index,
                                  tooltip: loc.tr('dragHandleTooltip'),
                                ),
                                const SizedBox(width: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    asset.imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 70,
                                      height: 70,
                                      color: colorScheme.surfaceContainerHighest,
                                      child: Icon(Icons.apartment, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(location, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOccupied ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isOccupied ? loc.tr('statusOccupied') : loc.tr('statusVacant'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isOccupied ? colorScheme.onPrimaryContainer : colorScheme.onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 20, color: colorScheme.outlineVariant),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniMetric(loc.tr('currentMarketValuation'), '${CurrencyFormatter.formatAmount(asset.currentMarketValue, langCode: lang)} $currency', colorScheme),
                                _buildMiniMetric(loc.tr('monthlyRent'), '${CurrencyFormatter.formatAmount(asset.monthlyRent, langCode: lang)} $currency', colorScheme),
                                _buildMiniMetric(loc.tr('netRoi'), '${asset.netRoiPercentage.toStringAsFixed(2)}%', colorScheme),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            TashilReorderHandle(
                              index: index,
                              tooltip: loc.tr('dragHandleTooltip'),
                            ),
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                asset.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.apartment, color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (isOccupied)
                                    Text(
                                      '${loc.tr('tenant')}: ${asset.tenantName} • ${loc.tr('leaseExpires')}: ${asset.leaseEndDate}',
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.tr('currentMarketValuation'), style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyFormatter.formatAmount(asset.currentMarketValue, langCode: lang)} $currency',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                                  ),
                                  Text(
                                    '+${asset.capitalGainPercentage.toStringAsFixed(1)}% ${loc.tr('capitalAppreciationRate')}',
                                    style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.tr('monthlyRent'), style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyFormatter.formatAmount(asset.monthlyRent, langCode: lang)} $currency',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                                  ),
                                  Text(
                                    '${loc.tr('grossYield')}: ${asset.grossYieldPercentage.toStringAsFixed(2)}%',
                                    style: TextStyle(fontSize: 10, color: colorScheme.secondary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOccupied ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOccupied ? loc.tr('statusOccupied') : loc.tr('statusVacant'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOccupied ? colorScheme.onPrimaryContainer : colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCashFlowTab(
    InvestorPortfolioSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.tr('monthlyCashFlowHistory'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
            ),
            Text(
              loc.tr('clickToViewMonthDetails'),
              style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summary.cashFlowHistory.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final flow = summary.cashFlowHistory[index];
            final monthName = AiTranslationService.getLocalizedText(flow.monthName, lang);
            final isExpanded = _expandedMonthKey == flow.monthKey;
            final totalExpenses = flow.operatingExpensesOutflow + flow.maintenanceOutflow;

            final isExpandedQuarter = flow.monthKey == '2026-10' || flow.monthKey == '2026-11';
            final activeAssets = summary.assets.where((asset) {
              if (asset.status == AssetStatus.occupied) return true;
              if (isExpandedQuarter && asset.assetType == AssetType.office) return true;
              return false;
            }).toList();

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isExpanded ? colorScheme.primary : colorScheme.outlineVariant,
                  width: isExpanded ? 1.5 : 1.0,
                ),
                boxShadow: isExpanded
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedMonthKey = isExpanded ? null : flow.monthKey;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Header Row (Always visible)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isExpanded ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    color: isExpanded ? colorScheme.onPrimary : colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        monthName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${loc.tr('inflowShort')}: ${CurrencyFormatter.formatAmount(flow.grossRentalInflow, langCode: lang)} $currency • ${loc.tr('outflowShort')}: ${CurrencyFormatter.formatAmount(totalExpenses, langCode: lang)} $currency',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+ ${CurrencyFormatter.formatAmount(flow.netCashFlow, langCode: lang)} $currency',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.tr('netCashFlowLabel'),
                                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: isExpanded ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Animated In-Place Details (Visible when expanded)
                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        Divider(color: colorScheme.outlineVariant, height: 1),
                        const SizedBox(height: 14),

                        // Status Bubbles / Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMonthChip(
                              icon: Icons.check_circle_rounded,
                              label: '${activeAssets.length} ${loc.tr('rentedUnitsCountInMonth')}',
                              color: colorScheme.primary,
                              bgColor: colorScheme.primaryContainer,
                            ),
                            _buildMonthChip(
                              icon: Icons.pie_chart_rounded,
                              label: '${loc.tr('portfolioOccupancy')}: ${isExpandedQuarter ? '100%' : '75%'}',
                              color: colorScheme.secondary,
                              bgColor: colorScheme.secondaryContainer,
                            ),
                            _buildMonthChip(
                              icon: Icons.verified_rounded,
                              label: loc.tr('settlementCompleted'),
                              color: colorScheme.tertiary,
                              bgColor: colorScheme.tertiaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Section Title: Units Rented
                        Text(
                          loc.tr('rentedUnitsCountInMonth'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        ...activeAssets.map((asset) {
                          final assetName = AiTranslationService.getLocalizedText(asset.name, lang);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.apartment_rounded, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$assetName (${asset.tenantName ?? loc.tr('statusOccupied')})',
                                    style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '+ ${CurrencyFormatter.formatAmount(asset.monthlyRent, langCode: lang)} $currency',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 10),

                        // Deductions Breakdown Tile
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${loc.tr('operatingAndManagementFees')}: - ${CurrencyFormatter.formatAmount(flow.operatingExpensesOutflow, langCode: lang)} $currency',
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                              Text(
                                '${loc.tr('maintenanceFeesDeducted')}: - ${CurrencyFormatter.formatAmount(flow.maintenanceOutflow, langCode: lang)} $currency',
                                style: TextStyle(fontSize: 11, color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Expansion Actions Toolbar with M3 Connected Button Group
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TashilConnectedButtonGroup<String>(
                            selectedValue: null,
                            onSelectionChanged: (action) {
                              if (action == 'details') {
                                MonthlyCashFlowDetailsDialog.show(
                                  context,
                                  flow: flow,
                                  summary: summary,
                                  currency: currency,
                                  lang: lang,
                                );
                              } else if (action == 'exportPdf') {
                                TashilSnackBar.showSuccess(
                                  context: context,
                                  message: '${loc.tr('exportMonthStatement')} ($monthName)',
                                );
                              }
                            },
                            segments: [
                              TashilConnectedButtonSegment<String>(
                                value: 'details',
                                icon: Icons.open_in_new_rounded,
                                label: loc.tr('monthCashFlowDetails'),
                              ),
                              TashilConnectedButtonSegment<String>(
                                value: 'exportPdf',
                                icon: Icons.picture_as_pdf_outlined,
                                label: loc.tr('exportMonthStatement'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _getLocalizedBankName(String ref, String lang) {
    if (ref.startsWith('CIB')) {
      if (lang == 'ar') return 'البنك التجاري الدولي';
      if (lang == 'hi') return 'कमर्शियल इंटरनेशनल बैंक';
      return 'Commercial International Bank';
    } else if (ref.startsWith('HSBC')) {
      if (lang == 'ar') return 'بنك إتش إس بي سي الشرق الأوسط';
      if (lang == 'hi') return 'एचएसबीसी बैंक मिडिल ईस्ट';
      return 'HSBC Bank Middle East';
    } else if (ref.startsWith('QNB')) {
      if (lang == 'ar') return 'بنك قطر الوطني الأهلي';
      if (lang == 'hi') return 'क्यूएनबी अहली';
      return 'QNB Alahli';
    } else if (ref.startsWith('ENBD')) {
      if (lang == 'ar') return 'بنك الإمارات دبي الوطني';
      if (lang == 'hi') return 'अमीरात एनबीडी';
      return 'Emirates NBD';
    } else if (ref.startsWith('ADCB')) {
      if (lang == 'ar') return 'بنك أبوظبي التجاري';
      if (lang == 'hi') return 'अबू धाबी कमर्शियल बैंक';
      return 'Abu Dhabi Commercial Bank';
    } else {
      if (lang == 'ar') return 'بنك أبوظبي الأول';
      if (lang == 'hi') return 'फर्स्ट अबू धाबी बैंक';
      return 'First Abu Dhabi Bank';
    }
  }

  Widget _buildPayoutsTab(
    InvestorPortfolioSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final payouts = CountryController.isUAE ? _payoutsUAE : _payoutsEG;

    if (payouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_outlined, size: 26, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Text(
                loc.tr('noRecentPayoutsTitle'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  loc.tr('noRecentPayoutsDesc'),
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.tr('recentPayouts'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
            ),
            Text(
              loc.tr('clickToViewMonthDetails'),
              style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ...payouts.map((p) {
          final amount = (p['amount'] as num).toDouble();
          final title = AiTranslationService.getLocalizedText(p['titles'], lang);
          final date = AiTranslationService.getLocalizedText(p['dates'], lang);
          final ref = p['ref'] as String? ?? 'REF-000000';
          final bankName = _getLocalizedBankName(ref, lang);
          final isExpanded = _expandedPayoutRef == ref;
          final invoiceNo = 'INV-${ref.replaceAll(RegExp(r'[^0-9]'), '')}';
          final grossAmount = amount * 1.12;
          final managementFee = amount * 0.12;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpanded ? colorScheme.primary : colorScheme.outlineVariant,
                width: isExpanded ? 1.5 : 1.0,
              ),
              boxShadow: isExpanded
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedPayoutRef = isExpanded ? null : ref;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Header Row (Always visible)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isExpanded ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  color: isExpanded ? colorScheme.onPrimary : colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$date • $bankName • Ref: $ref',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+ ${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc.tr('payoutCompleted'),
                                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isExpanded ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Animated In-Place Details (Visible when expanded)
                    if (isExpanded) ...[
                      const SizedBox(height: 14),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: 14),

                      // Status Chips / Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMonthChip(
                            icon: Icons.verified_rounded,
                            label: loc.tr('settlementCompleted'),
                            color: colorScheme.primary,
                            bgColor: colorScheme.primaryContainer,
                          ),
                          _buildMonthChip(
                            icon: Icons.account_balance_wallet_rounded,
                            label: loc.tr('bankTransferDeposit'),
                            color: colorScheme.secondary,
                            bgColor: colorScheme.secondaryContainer,
                          ),
                          _buildMonthChip(
                            icon: Icons.account_balance_rounded,
                            label: bankName,
                            color: colorScheme.tertiary,
                            bgColor: colorScheme.tertiaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Detailed Meta Items Table
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            // Bank Reference Number with Copy Action
                            Row(
                              children: [
                                Icon(Icons.tag_rounded, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('bankReferenceNumber')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ref,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TashilIconButton.standard(
                                  icon: Icons.copy_rounded,
                                  tooltip: loc.tr('copyRefSuccess'),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: ref));
                                    TashilSnackBar.showSuccess(
                                      context: context,
                                      message: '${loc.tr('copyRefSuccess')}: $ref',
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 10),
                            // Receiving Bank Account
                            Row(
                              children: [
                                Icon(Icons.account_balance_outlined, size: 16, color: colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('transferredToAccount')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    bankName,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 10),
                            // Linked Tax Invoice
                            Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 16, color: colorScheme.tertiary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('linkedTaxInvoice')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    invoiceNo,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 10),
                            // Linked Unit & Tenant
                            Row(
                              children: [
                                Icon(Icons.apartment_rounded, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('linkedUnitAndTenant')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Financial Breakdown Tile
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${loc.tr('grossRentalCollected')}: + ${CurrencyFormatter.formatAmount(grossAmount, langCode: lang)} $currency',
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${loc.tr('managementFeeDeduction')}: - ${CurrencyFormatter.formatAmount(managementFee, langCode: lang)} $currency',
                              style: TextStyle(fontSize: 11, color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action Toolbar with TashilConnectedButtonGroup
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TashilConnectedButtonGroup<String>(
                          selectedValue: null,
                          onSelectionChanged: (action) {
                            if (action == 'downloadReceipt') {
                              TashilSnackBar.showSuccess(
                                context: context,
                                message: '${loc.tr('downloadTransferReceipt')} ($ref)',
                              );
                            } else if (action == 'shareNotice') {
                              final shareText = '$title\n${loc.tr('bankReferenceNumber')}: $ref\n${loc.tr('transferredToAccount')}: $bankName\n${loc.tr('netSettledAmount')}: ${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency\n$date';
                              Clipboard.setData(ClipboardData(text: shareText));
                              TashilSnackBar.showSuccess(
                                context: context,
                                message: loc.tr('transferNoticeCopied'),
                              );
                            } else if (action == 'copyRef') {
                              Clipboard.setData(ClipboardData(text: ref));
                              TashilSnackBar.showSuccess(
                                context: context,
                                message: '${loc.tr('copyRefSuccess')}: $ref',
                              );
                            }
                          },
                          segments: [
                            TashilConnectedButtonSegment<String>(
                              value: 'downloadReceipt',
                              label: loc.tr('downloadTransferReceipt'),
                              icon: Icons.download_rounded,
                            ),
                            TashilConnectedButtonSegment<String>(
                              value: 'shareNotice',
                              label: loc.tr('shareTransferNotice'),
                              icon: Icons.share_rounded,
                            ),
                            TashilConnectedButtonSegment<String>(
                              value: 'copyRef',
                              label: loc.tr('copyRef'),
                              icon: Icons.copy_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface)),
      ],
    );
  }

  static const List<Map<String, dynamic>> _payoutsEG = [
    {
      'titles': {
        'ar': 'إيداع إيجار - شقة التجمع الخامس النرجس',
        'en': 'Rent Deposit - 5th Settlement Apartment (El Narges)',
        'hi': 'किराया जमा - 5वां सेटलमेंट अपार्टमेंट (अल नरगिस)',
      },
      'dates': {
        'ar': '25 نوفمبر 2026',
        'en': 'Nov 25, 2026',
        'hi': '25 नवंबर 2026',
      },
      'ref': 'CIB-EG-998124',
      'amount': 26000,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - فيلا بيفرلي هيلز زايد',
        'en': 'Rent Deposit - Beverly Hills Villa (Zayed)',
        'hi': 'किराया जमा - बेवर्ली हिल्स विला (जायद)',
      },
      'dates': {
        'ar': '20 نوفمبر 2026',
        'en': 'Nov 20, 2026',
        'hi': '20 नवंबर 2026',
      },
      'ref': 'HSBC-EG-997102',
      'amount': 55000,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - شقة جاردن سيتي النيل',
        'en': 'Rent Deposit - Garden City Nile Apartment',
        'hi': 'किराया जमा - गार्डन सिटी नाइल अपार्टमेंट',
      },
      'dates': {
        'ar': '15 نوفمبر 2026',
        'en': 'Nov 15, 2026',
        'hi': '15 नवंबर 2026',
      },
      'ref': 'QNB-EG-996410',
      'amount': 35000,
    },
  ];

  static const List<Map<String, dynamic>> _payoutsUAE = [
    {
      'titles': {
        'ar': 'إيداع إيجار - شقة دبي مارينا كراون',
        'en': 'Rent Deposit - Dubai Marina Crown Apartment',
        'hi': 'किराया जमा - दुबई मरीना क्राउन अपार्टमेंट',
      },
      'dates': {
        'ar': '25 نوفمبر 2026',
        'en': 'Nov 25, 2026',
        'hi': '25 नवंबर 2026',
      },
      'ref': 'ENBD-AE-44109',
      'amount': 16500,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - بنتهاوس داون تاون برج خليفة',
        'en': 'Rent Deposit - Downtown Burj Khalifa Penthouse',
        'hi': 'किराया जमा - डाउनटाउन बुर्ज खलीफा पेंटहाउस',
      },
      'dates': {
        'ar': '20 نوفمبر 2026',
        'en': 'Nov 20, 2026',
        'hi': '20 नवंबर 2026',
      },
      'ref': 'ADCB-AE-43981',
      'amount': 32000,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - فيلا نخلة جميرا',
        'en': 'Rent Deposit - Palm Jumeirah Villa',
        'hi': 'किराया जमा - पाम जुमेराह विला',
      },
      'dates': {
        'ar': '10 نوفمبر 2026',
        'en': 'Nov 10, 2026',
        'hi': '10 नवंबर 2026',
      },
      'ref': 'FAB-AE-99210',
      'amount': 75000,
    },
  ];
}
