import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/loading/tashil_loading.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/design_system/switches/tashil_switches.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_utils.dart';
import '../models/dynamic_pricing_model.dart';
import '../services/dynamic_pricing_optimizer_service.dart';

/// Independent full-page tab view for the Interactive Yield Forecast Curve
/// and Predictive Yield Optimizer according to Google M3 Design System standards.
class DynamicYieldCurveTabView extends StatefulWidget {
  final String? countryCode;

  const DynamicYieldCurveTabView({
    super.key,
    this.countryCode,
  });

  @override
  State<DynamicYieldCurveTabView> createState() => _DynamicYieldCurveTabViewState();
}

class _DynamicYieldCurveTabViewState extends State<DynamicYieldCurveTabView> {
  final _service = DynamicPricingOptimizerService();
  bool _isLoading = true;
  PortfolioYieldOptimizationSummary? _summary;
  int _selectedAssetIndex = 0;
  final Set<String> _appliedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final activeCountry = widget.countryCode ?? CountryController.countryCode;
    final data = await _service.generateOptimizationSummary(
      countryCode: activeCountry,
    );
    if (mounted) {
      setState(() {
        _summary = data;
        _selectedAssetIndex = 0;
        for (final r in data.assetRecommendations) {
          if (r.isApplied) {
            _appliedIds.add(r.asset.id);
          }
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final activeCountry = widget.countryCode ?? CountryController.countryCode;
    final isAE = activeCountry == 'AE';
    final currency = isAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    if (_isLoading || _summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TashilLoadingIndicator(size: 48.0),
              const SizedBox(height: 16),
              Text(
                loc.tr('runningPredictivePricingAlgorithm'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = _selectedAssetIndex < _summary!.assetRecommendations.length
        ? _selectedAssetIndex
        : 0;
    final currentAssetItem = _summary!.assetRecommendations[safeIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 860;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header
            _buildTopHeader(loc, isAE, colorScheme),
            const SizedBox(height: 16),

            if (isDesktop) ...[
              // Desktop / Tablet Landscape: Two-column Side-by-Side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Units Selector List
                  SizedBox(
                    width: 320,
                    child: _buildAssetsList(theme, colorScheme, loc, lang, currency),
                  ),
                  const SizedBox(width: 20),

                  // Right Column: Complete Interactive Curve & AI Detail Pane
                  Expanded(
                    child: _buildAssetDetailPane(
                      currentAssetItem,
                      currency,
                      lang,
                      loc,
                      isAE,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Mobile / Compact View: Horizontal Asset Selector then Stacked Detail Pane
              _buildMobileHorizontalSelector(theme, colorScheme, loc, lang, currency),
              const SizedBox(height: 16),
              _buildAssetDetailPane(
                currentAssetItem,
                currency,
                lang,
                loc,
                isAE,
                colorScheme,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTopHeader(AppLocalizations loc, bool isAE, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.show_chart_rounded, color: colorScheme.onPrimary, size: 22),
          ),
          const SizedBox(width: 14),
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
                      loc.tr('openFullYieldDialogBtn'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Vertex AI + Gemini Pro',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text(
                        isAE ? '🇦🇪 ${loc.tr('country_ae')}' : '🇪🇬 ${loc.tr('country_eg')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  loc.tr('dynamicYieldOptimizerSubtitle'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsList(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
    String lang,
    String currency,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.apartment_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.tr('managedUnitsList'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_summary!.assetRecommendations.length}',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colorScheme.outlineVariant, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _summary!.assetRecommendations.length,
            separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant, height: 1),
            itemBuilder: (context, index) {
              final item = _summary!.assetRecommendations[index];
              final isSelected = index == _selectedAssetIndex;
              final isApplied = item.isApplied || _appliedIds.contains(item.asset.id);

              return InkWell(
                onTap: () => setState(() => _selectedAssetIndex = index),
                child: Container(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                          children: [
                            Text(
                              item.asset.name[lang] ?? item.asset.name['ar'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.asset.location[lang] ?? item.asset.location['ar'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                Text(
                                  '${CurrencyFormatter.formatAmount(item.recommendedDynamicRent, langCode: lang)} $currency',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isApplied)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 10, color: colorScheme.primary),
                                        const SizedBox(width: 3),
                                        Text(
                                          loc.tr('priceApplied'),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHorizontalSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
    String lang,
    String currency,
  ) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _summary!.assetRecommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _summary!.assetRecommendations[index];
          final isSelected = index == _selectedAssetIndex;

          return InkWell(
            onTap: () => setState(() => _selectedAssetIndex = index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ImageUtils.cachedImage(
                      imageUrl: item.asset.imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.asset.name[lang] ?? item.asset.name['ar'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${CurrencyFormatter.formatAmount(item.recommendedDynamicRent, langCode: lang)} $currency',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetDetailPane(
    AssetDynamicPricingItem item,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isAE,
    ColorScheme colorScheme,
  ) {
    final isApplied = item.isApplied || _appliedIds.contains(item.asset.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 Quick Metrics Banner
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: loc.tr('recommendedDynamicRent'),
                  value: '${CurrencyFormatter.formatAmount(item.recommendedDynamicRent, langCode: lang)} $currency',
                  sub: isApplied
                      ? '${loc.tr('originalBaseRent')}: ${CurrencyFormatter.formatAmount(item.originalBaseRent, langCode: lang)} $currency'
                      : '${loc.tr('currentRent')}: ${CurrencyFormatter.formatAmount(item.currentBaseRent, langCode: lang)} $currency',
                  icon: Icons.trending_up_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: loc.tr('projectedNetAnnualGain'),
                  value: '+${CurrencyFormatter.formatAmount(item.projectedAnnualNetGain, langCode: lang)} $currency',
                  sub: '+${item.projectedYieldIncreasePct.toStringAsFixed(1)}% ${loc.tr('yieldRoiBonus')}',
                  icon: Icons.auto_graph_rounded,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: loc.tr('vacancyReductionDays'),
                  value: '${item.projectedVacancyReductionDays} ${loc.tr('daysSaved')}',
                  sub: loc.tr('vacancyProtectionDesc'),
                  icon: Icons.shield_rounded,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Strategy Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: colorScheme.onPrimary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('aiYieldStrategyRationale'),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isApplied
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: colorScheme.onTertiaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  '${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}% ${loc.tr('multiplierBadge')} • ${loc.tr('priceApplied')}',
                                  style: TextStyle(
                                    color: colorScheme.onTertiaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}% ${loc.tr('multiplierBadge')}',
                              style: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.getStrategy(lang),
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.getDemandDrivers(lang).map((d) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: colorScheme.onPrimary, size: 11),
                          const SizedBox(width: 4),
                          Text(d, style: TextStyle(color: colorScheme.onPrimary, fontSize: 10)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 12-Month Forecast Curve Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.tr('twelveMonthForecastCurve'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '12 Months Yield Curve',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _build12MonthForecastBars(item.monthlyForecastCurve, currency, lang, loc, colorScheme),
          const SizedBox(height: 18),
          const TashilDivider.cardAction(),
          const SizedBox(height: 14),

          // Action Controls Footer
          Row(
            children: [
              // Auto-Pilot Switch
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        loc.tr('autoPilotYieldMode'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TashilSwitch(
                      value: item.isAutoPilotEnabled,
                      onChanged: (_) {
                        setState(() {
                          _service.toggleAutoPilot(item.asset.id);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TashilButton(
                onPressed: isApplied ? null : () => _applyPrice(item),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _build12MonthForecastBars(
    List<MonthlyPriceForecast> forecasts,
    String currency,
    String lang,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    if (forecasts.isEmpty) return const SizedBox.shrink();

    double maxVal = 0;
    for (final f in forecasts) {
      if (f.recommendedPrice > maxVal) maxVal = f.recommendedPrice;
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: forecasts.map((f) {
          final heightFactor = (f.recommendedPrice / maxVal).clamp(0.2, 1.0);
          final isHighSeason = f.seasonType == PricingSeasonType.tourismPeak ||
              f.seasonType == PricingSeasonType.academicSurge ||
              f.seasonType == PricingSeasonType.summerCoast;

          final barColor = isHighSeason
              ? colorScheme.primary
              : colorScheme.secondary;

          return Expanded(
            child: Tooltip(
              message:
                  '${f.getMonthName(lang)}: ${CurrencyFormatter.formatAmount(f.recommendedPrice, langCode: lang)} $currency (${f.occupancyRatePct.toInt()}% ${loc.tr('occupancy')})',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${f.occupancyRatePct.toInt()}%',
                    style: TextStyle(
                      fontSize: 8,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 80 * heightFactor,
                    width: 14,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.getMonthName(lang),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
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
    );
  }
}
