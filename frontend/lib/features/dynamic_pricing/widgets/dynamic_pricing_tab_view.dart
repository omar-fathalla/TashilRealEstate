import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/design_system/switches/tashil_switches.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/responsive_layout.dart';
import '../models/dynamic_pricing_model.dart';
import '../services/dynamic_pricing_optimizer_service.dart';
import 'dynamic_yield_optimizer_dialog.dart';

class DynamicPricingTabView extends StatefulWidget {
  final VoidCallback? onOpenFullYieldCurve;

  const DynamicPricingTabView({
    super.key,
    this.onOpenFullYieldCurve,
  });

  @override
  State<DynamicPricingTabView> createState() => _DynamicPricingTabViewState();
}

class _DynamicPricingTabViewState extends State<DynamicPricingTabView> {
  final _service = DynamicPricingOptimizerService();
  bool _isLoading = true;
  PortfolioYieldOptimizationSummary? _summary;
  final Set<String> _appliedIds = {};
  String _viewMode = 'table'; // Default is Table view for managed units
  String _multipliersViewMode = 'table'; // Default is Table view for peak multipliers

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final data = await _service.generateOptimizationSummary();
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _applyPrice(AssetDynamicPricingItem item) async {
    final success = await _service.applyDynamicPrice(
      assetId: item.asset.id,
      newMonthlyRent: item.recommendedDynamicRent,
    );
    if (success && mounted) {
      setState(() {
        _appliedIds.add(item.asset.id);
      });
      TashilSnackBar.showSuccess(
        context: context,
        message: AppLocalizations.of(context).tr('dynamicPriceAppliedSuccess'),
      );
    }
  }

  void _showApplyPriceConfirmation(
    AssetDynamicPricingItem item,
    String currency,
    String lang,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final unitTitle = item.asset.name[lang] ?? item.asset.name['ar'] ?? '';
    final unitLocation = item.asset.location[lang] ?? item.asset.location['ar'] ?? '';
    final surgePct = ((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0);

    TashilTransitions.showM3Dialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: colorScheme.surfaceContainerLowest,
          elevation: 6.0,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 20 : 28)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 20 : 32,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 18 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with Icon and Shaded Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.bolt_rounded, color: colorScheme.onPrimaryContainer, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('confirmPriceApplicationTitle'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.tr('managedUnitsDynamicPricingTitle'),
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
                      TashilIconButton.close(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        tooltip: loc.tr('close'),
                      ),
                    ],
                  ),
                  const TashilDivider.middleInset(height: 20),

                  // 2. Unit Info Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ImageUtils.cachedImage(
                            imageUrl: item.asset.imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unitTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      unitLocation,
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Price Comparison Visual Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Before
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('oldRentLabel'),
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${CurrencyFormatter.formatAmount(item.currentBaseRent, langCode: lang)} $currency',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Directional Arrow & Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded, size: 14, color: colorScheme.onPrimaryContainer),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+$surgePct%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // After
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    loc.tr('newRentLabel'),
                                    style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${CurrencyFormatter.formatAmount(item.recommendedDynamicRent, langCode: lang)} $currency',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.6), height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                loc.tr('priceUpdateSummary'),
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${CurrencyFormatter.formatAmount(item.projectedAnnualNetGain, langCode: lang)} $currency / ${loc.tr('annualGainBadge')}',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: colorScheme.tertiary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. AI Strategy & Explanation Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology_outlined, size: 16, color: colorScheme.secondary),
                            const SizedBox(width: 6),
                            Text(
                              loc.tr('pricingStrategyReason'),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.getStrategy(lang),
                          style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.tr('confirmPriceApplicationDesc'),
                          style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const TashilDivider.cardAction(height: 24),

                  // 5. Action Buttons: Official M3 Connected Button Group
                  TashilConnectedButtonGroup<String>(
                    height: 44.0,
                    isFullWidth: true,
                    selectedValue: 'confirm',
                    showCheckmark: false,
                    onSelectionChanged: (action) {
                      if (action == 'cancel') {
                        Navigator.of(dialogContext).pop();
                      } else if (action == 'confirm') {
                        Navigator.of(dialogContext).pop();
                        _applyPrice(item);
                      }
                    },
                    segments: [
                      TashilConnectedButtonSegment<String>(
                        value: 'cancel',
                        label: loc.tr('cancel'),
                        icon: Icons.close_rounded,
                      ),
                      TashilConnectedButtonSegment<String>(
                        value: 'confirm',
                        label: loc.tr('confirm'),
                        icon: Icons.check_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;
    final isAE = CountryController.isUAE;
    final currency = isAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

    return ValueListenableBuilder<PortfolioYieldOptimizationSummary?>(
      valueListenable: _service.summaryNotifier,
      builder: (context, liveSummary, _) {
        final summary = liveSummary ?? _summary;

        if (_isLoading || summary == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.tr('loading') == 'loading' ? 'جاري تحليل التسعير الديناميكي...' : loc.tr('loading'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Yield Metrics Overview
              _buildSummaryKpiBanner(summary, currency, lang, loc, isMobile),
            const SizedBox(height: 20),

            // Seasonality Strategies Header & Launcher
            _buildSeasonalityBanner(loc, isAE),
            const SizedBox(height: 20),

            // Section Title & View Switcher Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Text(
                  loc.tr('managedUnitsDynamicPricingTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TashilConnectedButtonGroup<String>(
                      selectedValue: _viewMode,
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 'table',
                          label: loc.tr('tableView'),
                          icon: Icons.table_chart_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'grid',
                          label: loc.tr('cardsView'),
                          icon: Icons.grid_view_rounded,
                        ),
                      ],
                      onSelectionChanged: (mode) => setState(() => _viewMode = mode),
                    ),
                    const SizedBox(width: 10),
                    TashilButton.tonal(
                      onPressed: () {
                        if (widget.onOpenFullYieldCurve != null) {
                          widget.onOpenFullYieldCurve!();
                        } else {
                          DynamicYieldOptimizerDialog.show(context);
                        }
                      },
                      icon: Icons.show_chart_rounded,
                      label: loc.tr('openFullYieldDialogBtn'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content: Table View (default) or Cards Grid View for Managed Units
            if (_viewMode == 'table')
              _buildAssetPricingTable(summary.assetRecommendations, currency, lang, loc)
            else
              _buildAssetPricingGrid(summary.assetRecommendations, currency, lang, loc),

            const SizedBox(height: 32),

            // Section 2: Peak Multipliers & Seasonality Forecast Table (Distinct Table)
            _buildPeakMultipliersSection(theme, theme.colorScheme, loc, lang, isAE),
          ],
        ),
      );
    },
  );
  }

  Widget _buildSummaryKpiBanner(
    PortfolioYieldOptimizationSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bolt_rounded, color: theme.colorScheme.onPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('dynamicYieldOptimizerTitle'),
                      style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.tr('yieldEngineDescription'),
                      style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.75), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${summary.revenueIncreasePercentage.toStringAsFixed(1)}% ${loc.tr('annualYieldBoost')}',
                  style: TextStyle(color: theme.colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.onPrimary.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBannerKpiItem(
                  theme: theme,
                  title: loc.tr('projectedNetAnnualGain'),
                  value: '+${CurrencyFormatter.formatAmount(summary.netAnnualRevenueGain, langCode: lang)} $currency',
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: theme.colorScheme.onPrimary.withValues(alpha: 0.15)),
              Expanded(
                child: _buildBannerKpiItem(
                  theme: theme,
                  title: loc.tr('totalVacancyDaysSaved'),
                  value: '${summary.totalVacancyDaysSaved} ${loc.tr('daysSaved')}',
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: theme.colorScheme.onPrimary.withValues(alpha: 0.15)),
              Expanded(
                child: _buildBannerKpiItem(
                  theme: theme,
                  title: loc.tr('averageYieldIncrease'),
                  value: '+${summary.averageYieldIncreasePct.toStringAsFixed(1)}% ROI',
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerKpiItem({
    required ThemeData theme,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.75), fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalityBanner(AppLocalizations loc, bool isAE) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAE ? loc.tr('uaeSeasonalityInsight') : loc.tr('egyptSeasonalityInsight'),
              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetPricingCard(
    AssetDynamicPricingItem item,
    String currency,
    String lang,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isApplied = _appliedIds.contains(item.asset.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApplied ? colorScheme.primary : colorScheme.outlineVariant,
          width: isApplied ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Asset Header Row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageUtils.cachedImage(
                  imageUrl: item.asset.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.asset.name[lang] ?? item.asset.name['ar'] ?? '',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.asset.location[lang] ?? item.asset.location['ar'] ?? '',
                      style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}% ${loc.tr('multiplierBadge')}',
                  style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 9.5),
                ),
              ),
            ],
          ),

          // Price Comparison Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.tr('currentRent'), style: TextStyle(fontSize: 9.5, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 1),
                    Text(
                      '${CurrencyFormatter.formatAmount(item.currentBaseRent, langCode: lang)} $currency',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(loc.tr('recommendedDynamicRent'), style: TextStyle(fontSize: 9.5, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 1),
                    Text(
                      '${CurrencyFormatter.formatAmount(item.recommendedDynamicRent, langCode: lang)} $currency',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // AI Strategy Snippet (Compact)
          Text(
            item.getStrategy(lang),
            style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Actions Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Tooltip(
                message: loc.tr('autoPilotHeader'),
                child: TashilSwitch(
                  value: item.isAutoPilotEnabled,
                  onChanged: (_) {
                    setState(() {
                      _service.toggleAutoPilot(item.asset.id);
                    });
                  },
                ),
              ),
              TashilButton(
                onPressed: isApplied ? null : () => _showApplyPriceConfirmation(item, currency, lang, loc),
                icon: isApplied ? Icons.check_circle_rounded : Icons.bolt_rounded,
                label: isApplied ? loc.tr('priceApplied') : loc.tr('applyDynamicPriceBtn'),
                variant: isApplied ? TashilButtonVariant.tonal : TashilButtonVariant.filled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetPricingGrid(
    List<AssetDynamicPricingItem> items,
    String currency,
    String lang,
    AppLocalizations loc,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleCol = constraints.maxWidth < 750;
        final isWide = constraints.maxWidth >= 1300;
        final crossAxisCount = isSingleCol ? 1 : (isWide ? 3 : 2);
        final childAspectRatio = isSingleCol ? 1.75 : (isWide ? 1.55 : 1.65);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildAssetPricingCard(item, currency, lang, loc);
          },
        );
      },
    );
  }

  Widget _buildAssetPricingTable(
    List<AssetDynamicPricingItem> items,
    String currency,
    String lang,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < 1280 ? 1280.0 : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 320,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 16),
                            child: Text(
                              loc.tr('unitAndProperty'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 12),
                            child: Text(
                              loc.tr('surgeMultiplierHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 16),
                            child: Text(
                              loc.tr('rentComparisonHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                            child: Text(
                              loc.tr('aiStrategyHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Center(
                            child: Text(
                              loc.tr('actionsHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const TashilDivider.fullWidth(),

                  // Table Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const TashilDivider.fullWidth(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildTableRowItem(item, currency, lang, loc);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableRowItem(
    AssetDynamicPricingItem item,
    String currency,
    String lang,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isApplied = _appliedIds.contains(item.asset.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: isApplied ? colorScheme.primaryContainer.withValues(alpha: 0.08) : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Unit & Property (Generous width with directional end cushion)
          SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ImageUtils.cachedImage(
                      imageUrl: item.asset.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.asset.name[lang] ?? item.asset.name['ar'] ?? '',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                item.asset.location[lang] ?? item.asset.location['ar'] ?? '',
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Surge Multiplier
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 13, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '+${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}% ${loc.tr('multiplierBadge')}',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.getDemandDrivers(lang).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.getDemandDrivers(lang).first,
                      style: TextStyle(fontSize: 9.5, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Rent Comparison
          SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${CurrencyFormatter.formatAmount(item.recommendedDynamicRent, langCode: lang)} $currency',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${loc.tr('currentRent')}: ${CurrencyFormatter.formatAmount(item.currentBaseRent, langCode: lang)} $currency',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${CurrencyFormatter.formatAmount(item.projectedAnnualNetGain, langCode: lang)} $currency ${loc.tr('annualGainBadge')}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. AI Strategy
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.getStrategy(lang),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.getDemandDrivers(lang).length > 1) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: item.getDemandDrivers(lang).skip(1).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 5. Actions Group (Combined Auto-Pilot Switch & Apply Button)
          SizedBox(
            width: 250,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Auto-Pilot Switch with Tooltip
                    Tooltip(
                      message: loc.tr('autoPilotHeader'),
                      child: TashilSwitch(
                        value: item.isAutoPilotEnabled,
                        onChanged: (_) {
                          setState(() {
                            _service.toggleAutoPilot(item.asset.id);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Apply Button
                    Flexible(
                      child: TashilButton(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        onPressed: isApplied ? null : () => _showApplyPriceConfirmation(item, currency, lang, loc),
                        icon: isApplied ? Icons.check_rounded : Icons.bolt_rounded,
                        label: isApplied ? loc.tr('priceApplied') : loc.tr('applyBtn'),
                        variant: isApplied ? TashilButtonVariant.tonal : TashilButtonVariant.filled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Distinct Section 2: Peak Multipliers & Market Seasonality Table/Grid ---
  Widget _buildPeakMultipliersSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
    String lang,
    bool isAE,
  ) {
    final seasons = _getPeakSeasons(isAE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & View Switcher Row (Clean title without redundant subtitle)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Text(
              loc.tr('peakMultipliersTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            TashilConnectedButtonGroup<String>(
              selectedValue: _multipliersViewMode,
              segments: [
                TashilConnectedButtonSegment(
                  value: 'table',
                  label: loc.tr('tableView'),
                  icon: Icons.table_chart_rounded,
                ),
                TashilConnectedButtonSegment(
                  value: 'grid',
                  label: loc.tr('cardsView'),
                  icon: Icons.grid_view_rounded,
                ),
              ],
              onSelectionChanged: (mode) => setState(() => _multipliersViewMode = mode),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Content: Table View (default) or Cards Grid View
        if (_multipliersViewMode == 'table')
          _buildPeakMultipliersTable(seasons, colorScheme, lang, loc)
        else
          _buildPeakMultipliersGrid(seasons, colorScheme, lang, loc),
      ],
    );
  }

  Widget _buildPeakMultipliersTable(
    List<PeakMultiplierSeasonItem> seasons,
    ColorScheme colorScheme,
    String lang,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < 1280 ? 1280.0 : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 280,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 16),
                            child: Text(
                              loc.tr('seasonNameHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 14),
                            child: Text(
                              loc.tr('activeMonthsHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 14),
                            child: Text(
                              loc.tr('multiplierSurgeHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 16),
                            child: Text(
                              loc.tr('expectedOccupancyHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 14),
                            child: Text(
                              loc.tr('targetRegionHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8, end: 16),
                            child: Text(
                              loc.tr('seasonStrategyHeader'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const TashilDivider.fullWidth(),

                  // Table Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: seasons.length,
                    separatorBuilder: (_, __) => const TashilDivider.fullWidth(),
                    itemBuilder: (context, index) {
                      final item = seasons[index];
                      return _buildPeakMultiplierTableRow(item, colorScheme, lang, loc);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeakMultiplierTableRow(
    PeakMultiplierSeasonItem item,
    ColorScheme colorScheme,
    String lang,
    AppLocalizations loc,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Season Name & Icon (48x48 Squircle container with title + event tag)
          SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Icon(item.icon, size: 24, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.getSeasonName(lang),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.event_available_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                loc.tr('seasonalDemandWindow'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Active Months (M3 squircle icon container + bold text)
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Icon(Icons.calendar_month_rounded, size: 16, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.getActiveMonths(lang),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Multiplier Surge (Standard M3 capsule with bolt icon)
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.surgeMultiplierDisplay,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Expected Occupancy (Structured percentage badge + clean linear progress bar)
          SizedBox(
            width: 170,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.expectedOccupancyPct}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                      Text(
                        loc.tr('occupancy'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.expectedOccupancyPct / 100.0,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Target Region (M3 squircle icon container + location text)
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.getTargetRegion(lang),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. AI Strategy & Yield Boost (Matching Table 1 AI Strategy with trending up badge)
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, end: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.getAiStrategy(lang),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up_rounded, size: 12, color: colorScheme.onTertiaryContainer),
                        const SizedBox(width: 3),
                        Text(
                          item.getImpactOnYield(lang),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakMultipliersGrid(
    List<PeakMultiplierSeasonItem> seasons,
    ColorScheme colorScheme,
    String lang,
    AppLocalizations loc,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleCol = constraints.maxWidth < 750;
        final isWide = constraints.maxWidth >= 1300;
        final crossAxisCount = isSingleCol ? 1 : (isWide ? 3 : 2);
        final childAspectRatio = isSingleCol ? 1.85 : (isWide ? 1.6 : 1.7);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: seasons.length,
          itemBuilder: (context, index) {
            final item = seasons[index];
            return _buildPeakMultiplierCard(item, colorScheme, lang, loc);
          },
        );
      },
    );
  }

  Widget _buildPeakMultiplierCard(
    PeakMultiplierSeasonItem item,
    ColorScheme colorScheme,
    String lang,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.getSeasonName(lang),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.getActiveMonths(lang),
                      style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.surgeMultiplierDisplay,
                  style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      item.getTargetRegion(lang),
                      style: TextStyle(fontSize: 10.5, color: colorScheme.onSurface),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, size: 12, color: colorScheme.onTertiaryContainer),
                      const SizedBox(width: 3),
                      Text(
                        item.getImpactOnYield(lang),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.getAiStrategy(lang),
            style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<PeakMultiplierSeasonItem> _getPeakSeasons(bool isAE) {
    if (isAE) {
      return const [
        PeakMultiplierSeasonItem(
          id: 'uae_winter_tourism',
          icon: Icons.celebration_rounded,
          seasonName: {
            'ar': 'ذروة السياحة الشتوية والمعارض العالمية',
            'en': 'Winter Tourism & Global Expos Peak',
            'hi': 'शीतकालीन पर्यटन और वैश्विक एक्सपो शिखर',
          },
          activeMonths: {
            'ar': 'نوفمبر - مارس (٥ أشهر)',
            'en': 'November - March (5 Months)',
            'hi': 'नवंबर - मार्च (5 महीने)',
          },
          targetRegion: {
            'ar': 'دبي مارينا، داون تاون، نخلة جميرا',
            'en': 'Dubai Marina, Downtown, Palm Jumeirah',
            'hi': 'दुबई मरीना, डाउनटाउन, पाम जुमेराह',
          },
          surgeMultiplierDisplay: '+22% إلى +25%',
          expectedOccupancyPct: 97,
          aiStrategy: {
            'ar': 'زيادة سعر الإيجار للاستفادة من ذروة الموسم السياحي والمعارض العالمية في دبي مع ضمان إشغال 97%.',
            'en': 'Increase rent to capitalize on the high winter tourism & global expo season in Dubai with 97% target occupancy.',
            'hi': '97% लक्षित अधिभोग के साथ दुबई में शीतकालीन पर्यटन और वैश्विक एक्सपो सीजन का लाभ उठाने के लिए किराया बढ़ाएं।',
          },
          impactOnYield: {
            'ar': '+2.4% نمو سنوي',
            'en': '+2.4% Annual Boost',
            'hi': '+2.4% वार्षिक वृद्धि',
          },
        ),
        PeakMultiplierSeasonItem(
          id: 'uae_corporate_rera',
          icon: Icons.business_center_rounded,
          seasonName: {
            'ar': 'فترة الأعمال وتجديد عقود ريرا',
            'en': 'Business Inflow & RERA Index Window',
            'hi': 'व्यावसायिक प्रवाह और रेरा नवीनीकरण',
          },
          activeMonths: {
            'ar': 'أبريل - مايو، سبتمبر - أكتوبر',
            'en': 'April - May, September - October',
            'hi': 'अप्रैल - मई, सितंबर - अक्टूबर',
          },
          targetRegion: {
            'ar': 'الخليج التجاري، مركز دبي المالي، أبوظبي',
            'en': 'Business Bay, DIFC, Abu Dhabi',
            'hi': 'बिजनेस बे, डीआईएफसी, अबू धाबी',
          },
          surgeMultiplierDisplay: '+8% إلى +10%',
          expectedOccupancyPct: 91,
          aiStrategy: {
            'ar': 'تعديل الإيجار بزيادة متوافقة مع مؤشر حاسبة زيادة الإيجار لمؤسسة التنظيم العقاري (RERA).',
            'en': 'Adjust rent upward in accordance with RERA rental increase index guidelines.',
            'hi': 'रेरा रेंटल इंडेक्स दिशानिर्देशों के अनुसार किराए में वृद्धि करें।',
          },
          impactOnYield: {
            'ar': '+1.6% نمو سنوي',
            'en': '+1.6% Annual Boost',
            'hi': '+1.6% वार्षिक वृद्धि',
          },
        ),
        PeakMultiplierSeasonItem(
          id: 'uae_summer_promotion',
          icon: Icons.wb_sunny_rounded,
          seasonName: {
            'ar': 'العروض الصيفية وحماية الإشغال التام',
            'en': 'Summer Promotion & Zero Vacancy',
            'hi': 'ग्रीष्मकालीन प्रचार और शून्य रिक्ति',
          },
          activeMonths: {
            'ar': 'يونيو - أغسطس (٣ أشهر)',
            'en': 'June - August (3 Months)',
            'hi': 'जून - अगस्त (3 महीने)',
          },
          targetRegion: {
            'ar': 'كافة مناطق دبي وأبوظبي',
            'en': 'All Dubai & Abu Dhabi',
            'hi': 'सभी दुबई और अबू धाबी',
          },
          surgeMultiplierDisplay: '0.95x (-5%)',
          expectedOccupancyPct: 86,
          aiStrategy: {
            'ar': 'تقديم مرونة في الدفعات (4-6 شيكات) أو خصم رمزي 5% لتجنب شغور الوحدة نهائياً خلال فترة الصيف.',
            'en': 'Offer payment flexibility (4-6 cheques) or a 5% promotional incentive to prevent summer vacancy.',
            'hi': 'गर्मियों में रिक्ति को रोकने के लिए भुगतान लचीलापन (4-6 चेक) या 5% प्रचार प्रोत्साहन प्रदान करें।',
          },
          impactOnYield: {
            'ar': 'توفير 30 يوماً شغور',
            'en': 'Saves 30 Vacancy Days',
            'hi': '30 रिक्ति दिनों की बचत',
          },
        ),
      ];
    } else {
      return const [
        PeakMultiplierSeasonItem(
          id: 'eg_summer_coast',
          icon: Icons.beach_access_rounded,
          seasonName: {
            'ar': 'موسم صيف الساحل الشمالي والمصايف',
            'en': 'North Coast Summer Vacation Surge',
            'hi': 'उत्तरी तट ग्रीष्मकालीन अवकाश शिखर',
          },
          activeMonths: {
            'ar': 'يونيو - أغسطس (٣ أشهر)',
            'en': 'June - August (3 Months)',
            'hi': 'जून - अगस्त (3 महीने)',
          },
          targetRegion: {
            'ar': 'الساحل الشمالي والإسكندرية',
            'en': 'North Coast & Alexandria',
            'hi': 'उत्तरी तट और अलेक्जेंड्रिया',
          },
          surgeMultiplierDisplay: '+45% إلى +60%',
          expectedOccupancyPct: 98,
          aiStrategy: {
            'ar': 'تطبيق تسعير مرن مضاعف لموسم المصايف والساحل الشمالي لتوليد 70% من العائد السنوي في 4 أشهر.',
            'en': 'Apply surge summer pricing for North Coast vacation season generating 70% of annual yield.',
            'hi': 'उत्तर तट वेकेशन सीजन के लिए ग्रीष्मकालीन मूल्य वृद्धि लागू करें जो 4 महीनों में वार्षिक प्रतिफल का 70% उत्पन्न करता है।',
          },
          impactOnYield: {
            'ar': '+3.8% نمو سنوي',
            'en': '+3.8% Annual Boost',
            'hi': '+3.8% वार्षिक वृद्धि',
          },
        ),
        PeakMultiplierSeasonItem(
          id: 'eg_academic_influx',
          icon: Icons.school_rounded,
          seasonName: {
            'ar': 'موسم الطلاب والجامعات الدولية',
            'en': 'University & Expat Academic Influx',
            'hi': 'विश्वविद्यालय और प्रवासी शैक्षणिक प्रवाह',
          },
          activeMonths: {
            'ar': 'سبتمبر - نوفمبر، يناير - فبراير',
            'en': 'September - November, Jan - Feb',
            'hi': 'सितंबर - नवंबर, जनवरी - फरवरी',
          },
          targetRegion: {
            'ar': 'القاهرة الجديدة، التجمع، الشروق',
            'en': 'New Cairo, AUC & GUC',
            'hi': 'न्यू काहिरा, एयूसी और जीयूसी',
          },
          surgeMultiplierDisplay: '+18% إلى +20%',
          expectedOccupancyPct: 96,
          aiStrategy: {
            'ar': 'رفع الإيجار للوحدات المفروشة بالتزامن مع موسم طلاب الجامعة الأمريكية والألمانية والشركات متعددة الجنسيات.',
            'en': 'Elevate furnished rent catering to AUC/GUC students and multinational corporate expats.',
            'hi': 'एयूसी/जीयूसी छात्रों और बहुराष्ट्रीय कॉर्पोरेट प्रवासियों के लिए सुसज्जित किराए में वृद्धि करें।',
          },
          impactOnYield: {
            'ar': '+2.1% نمو سنوي',
            'en': '+2.1% Annual Boost',
            'hi': '+2.1% वार्षिक वृद्धि',
          },
        ),
        PeakMultiplierSeasonItem(
          id: 'eg_zayed_urban',
          icon: Icons.location_city_rounded,
          seasonName: {
            'ar': 'النمو السكني ومواكبة التضخم',
            'en': 'Urban Inflow & Inflation Benchmark',
            'hi': 'शहरी प्रवाह और मुद्रास्फीति बेंचमार्क',
          },
          activeMonths: {
            'ar': 'طوال العام (عقود سنوية)',
            'en': 'Year-Round (Annual Contracts)',
            'hi': 'पूरे वर्ष (वार्षिक अनुबंध)',
          },
          targetRegion: {
            'ar': 'الشيخ زايد و٦ أكتوبر',
            'en': 'Sheikh Zayed & 6th October',
            'hi': 'शेख जायद और 6 अक्टूबर',
          },
          surgeMultiplierDisplay: '+12%',
          expectedOccupancyPct: 90,
          aiStrategy: {
            'ar': 'تعديل السعر السنوي لمواكبة معدل التضخم ومتوسط أسعار المنطقة في الشيخ زايد وأكتوبر.',
            'en': 'Adjust annual price upward matching local inflation benchmark and Sheikh Zayed area average.',
            'hi': 'स्थानीय मुद्रास्फीति और शेख जायद क्षेत्र के औसत से मेल खाते हुए वार्षिक मूल्य समायोजित करें।',
          },
          impactOnYield: {
            'ar': '+1.5% نمو سنوي',
            'en': '+1.5% Annual Boost',
            'hi': '+1.5% वार्षिक वृद्धि',
          },
        ),
        PeakMultiplierSeasonItem(
          id: 'eg_coast_winter',
          icon: Icons.ac_unit_rounded,
          seasonName: {
            'ar': 'الموسم الشتوي المنخفض والعقود المرنة',
            'en': 'Winter Coast Low-Overhead Period',
            'hi': 'शीतकालीन तट कम ओवरहेड अवधि',
          },
          activeMonths: {
            'ar': 'أكتوبر - مايو (شتاء وخريف)',
            'en': 'October - May (Winter/Autumn)',
            'hi': 'अक्टूबर - मई (शीत/शरद)',
          },
          targetRegion: {
            'ar': 'الساحل الشمالي',
            'en': 'North Coast',
            'hi': 'उत्तरी तट',
          },
          surgeMultiplierDisplay: '0.85x (-15%)',
          expectedOccupancyPct: 75,
          aiStrategy: {
            'ar': 'إيجار شتوي منخفض التكلفة للعاملين عن بعد أو الشركات مع صيانة مؤمنة للوحدة لمنع التلف.',
            'en': 'Long-term winter tenancy for remote workers or corporate staff with minimized maintenance costs.',
            'hi': 'कम रखरखाव लागत के साथ रिमोट श्रमिकों के लिए दीर्घकालिक शीतकालीन किरायेदारी।',
          },
          impactOnYield: {
            'ar': 'توفير 45 يوماً شغور',
            'en': 'Saves 45 Vacancy Days',
            'hi': '45 रिक्ति दिनों की बचत',
          },
        ),
      ];
    }
  }
}

class PeakMultiplierSeasonItem {
  final String id;
  final IconData icon;
  final Map<String, String> seasonName;
  final Map<String, String> activeMonths;
  final Map<String, String> targetRegion;
  final String surgeMultiplierDisplay;
  final int expectedOccupancyPct;
  final Map<String, String> aiStrategy;
  final Map<String, String> impactOnYield;

  const PeakMultiplierSeasonItem({
    required this.id,
    required this.icon,
    required this.seasonName,
    required this.activeMonths,
    required this.targetRegion,
    required this.surgeMultiplierDisplay,
    required this.expectedOccupancyPct,
    required this.aiStrategy,
    required this.impactOnYield,
  });

  String getSeasonName(String lang) => seasonName[lang] ?? seasonName['ar'] ?? '';
  String getActiveMonths(String lang) => activeMonths[lang] ?? activeMonths['ar'] ?? '';
  String getTargetRegion(String lang) => targetRegion[lang] ?? targetRegion['ar'] ?? '';
  String getAiStrategy(String lang) => aiStrategy[lang] ?? aiStrategy['ar'] ?? '';
  String getImpactOnYield(String lang) => impactOnYield[lang] ?? impactOnYield['ar'] ?? '';
}

