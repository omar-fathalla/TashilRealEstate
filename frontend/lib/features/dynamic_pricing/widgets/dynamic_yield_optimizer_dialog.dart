import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/loading/tashil_loading.dart';
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

class DynamicYieldOptimizerDialog extends StatefulWidget {
  final String countryCode;

  const DynamicYieldOptimizerDialog({
    super.key,
    required this.countryCode,
  });

  static Future<void> show(BuildContext context, {String? countryCode}) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DynamicYieldOptimizerDialog(
        countryCode: countryCode ?? CountryController.countryCode,
      ),
    );
  }

  @override
  State<DynamicYieldOptimizerDialog> createState() =>
      _DynamicYieldOptimizerDialogState();
}

class _DynamicYieldOptimizerDialogState
    extends State<DynamicYieldOptimizerDialog> {
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
    final data = await _service.generateOptimizationSummary(
      countryCode: widget.countryCode,
    );
    if (mounted) {
      setState(() {
        _summary = data;
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
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isAE = widget.countryCode == 'AE';
    final currency = isAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      elevation: 6,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 20 : 28)),
      child: Container(
        width: 1050,
        height: 720,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: _isLoading || _summary == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TashilLoadingIndicator(size: 48.0),
                    const SizedBox(height: 16),
                    Text(
                      loc.tr('runningPredictivePricingAlgorithm'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Header
                  _buildHeader(loc, isAE),
                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 16),

                  // Content Area
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Assets Selector List)
                        Container(
                          width: isMobile ? 180 : 320,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.apartment_rounded, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        loc.tr('managedUnitsList'),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_summary!.assetRecommendations.length}',
                                        style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(color: theme.colorScheme.outlineVariant, height: 1),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _summary!.assetRecommendations.length,
                                  separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant, height: 1),
                                  itemBuilder: (context, index) {
                                    final item = _summary!.assetRecommendations[index];
                                    final isSelected = index == _selectedAssetIndex;
                                    return InkWell(
                                      onTap: () => setState(() => _selectedAssetIndex = index),
                                      child: Container(
                                        color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                                        padding: const EdgeInsets.all(10),
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
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.asset.name[lang] ?? item.asset.name['ar'] ?? '',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.asset.location[lang] ?? item.asset.location['ar'] ?? '',
                                                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    spacing: 4,
                                                    runSpacing: 2,
                                                    children: [
                                                      Text(
                                                        '${CurrencyFormatter.formatAmount(item.recommendedDynamicRent, langCode: lang)} $currency',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: theme.colorScheme.primary,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (item.isApplied || _appliedIds.contains(item.asset.id))
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primaryContainer,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.check_circle_rounded, size: 10, color: theme.colorScheme.primary),
                                                              const SizedBox(width: 3),
                                                              Text(
                                                                loc.tr('priceApplied'),
                                                                style: TextStyle(
                                                                  fontSize: 9,
                                                                  color: theme.colorScheme.onPrimaryContainer,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      else
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primaryContainer,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            '+${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}%',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              color: theme.colorScheme.onPrimaryContainer,
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Right Column (Dynamic Strategy & Forecast Chart for Selected Asset)
                        Expanded(
                          child: _buildAssetDetailPane(
                            _summary!.assetRecommendations[_selectedAssetIndex],
                            currency,
                            lang,
                            loc,
                            isAE,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc, bool isAE) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.bolt_rounded, color: theme.colorScheme.onPrimary, size: 22),
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
                    loc.tr('dynamicYieldOptimizerTitle'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Vertex AI + Gemini',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      isAE ? '🇦🇪 ${loc.tr('country_ae')}' : '🇪🇬 ${loc.tr('country_eg')}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('dynamicYieldOptimizerSubtitle'),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        TashilIconButton.close(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildAssetDetailPane(
    AssetDynamicPricingItem item,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isAE,
  ) {
    final theme = Theme.of(context);
    final isApplied = item.isApplied || _appliedIds.contains(item.asset.id);

    return SingleChildScrollView(
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
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: loc.tr('projectedNetAnnualGain'),
                  value: '+${CurrencyFormatter.formatAmount(item.projectedAnnualNetGain, langCode: lang)} $currency',
                  sub: '+${item.projectedYieldIncreasePct.toStringAsFixed(1)}% ${loc.tr('yieldRoiBonus')}',
                  icon: Icons.auto_graph_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: loc.tr('vacancyReductionDays'),
                  value: '${item.projectedVacancyReductionDays} ${loc.tr('daysSaved')}',
                  sub: loc.tr('vacancyProtectionDesc'),
                  icon: Icons.shield_rounded,
                  color: theme.colorScheme.tertiary,
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
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: theme.colorScheme.onPrimary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('aiYieldStrategyRationale'),
                        style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isApplied
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: theme.colorScheme.onTertiaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  '${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}% ${loc.tr('multiplierBadge')} • ${loc.tr('priceApplied')}',
                                  style: TextStyle(color: theme.colorScheme.onTertiaryContainer, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Text(
                              '${((item.dynamicMultiplier - 1.0) * 100).toStringAsFixed(0)}% ${loc.tr('multiplierBadge')}',
                              style: TextStyle(color: theme.colorScheme.onTertiaryContainer, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.getStrategy(lang),
                  style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.9), fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.getDemandDrivers(lang).map((d) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: theme.colorScheme.onPrimary, size: 11),
                          const SizedBox(width: 4),
                          Text(d, style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10)),
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
          Text(
            loc.tr('twelveMonthForecastCurve'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          _build12MonthForecastBars(item.monthlyForecastCurve, currency, lang, loc),
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
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
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
  ) {
    if (forecasts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    double maxVal = 0;
    for (final f in forecasts) {
      if (f.recommendedPrice > maxVal) maxVal = f.recommendedPrice;
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: forecasts.map((f) {
          final heightFactor = (f.recommendedPrice / maxVal).clamp(0.2, 1.0);
          final isHighSeason = f.seasonType == PricingSeasonType.tourismPeak ||
              f.seasonType == PricingSeasonType.academicSurge ||
              f.seasonType == PricingSeasonType.summerCoast;

          final barColor = isHighSeason
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary;

          return Expanded(
            child: Tooltip(
              message: '${f.getMonthName(lang)}: ${CurrencyFormatter.formatAmount(f.recommendedPrice, langCode: lang)} $currency (${f.occupancyRatePct.toInt()}% ${loc.tr('occupancy')})',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${f.occupancyRatePct.toInt()}%',
                    style: TextStyle(fontSize: 8, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
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
