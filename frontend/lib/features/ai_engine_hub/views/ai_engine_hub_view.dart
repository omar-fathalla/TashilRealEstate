import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/cards/tashil_cards.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/responsive_layout.dart';
import '../models/ai_model_definition.dart';
import '../services/ai_engine_config_controller.dart';

/// Full-featured Material Design 3 AI Models & Engine Hub View for Super Admin.
/// Enables switching between the top 3 latest models per AI service, with comprehensive
/// token consumption, latency, and budget expenditure insights.
class AiEngineHubView extends StatefulWidget {
  const AiEngineHubView({super.key});

  @override
  State<AiEngineHubView> createState() => _AiEngineHubViewState();
}

class _AiEngineHubViewState extends State<AiEngineHubView> {
  final AiEngineConfigController _controller = AiEngineConfigController();
  String _activeCategoryFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final lang = LocaleController.languageCode;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final categories = _getFilteredCategories();
        final totalTokens = _controller.calculateEstimatedMonthlyTokens();
        final totalCost = _controller.calculateEstimatedMonthlyCost();
        final savings = _controller.calculateEstimatedSavingsPercentage();

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : (isTablet ? 20 : 28),
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header Banner & Insights
                  _buildHeaderSection(context, loc, colorScheme, isMobile, totalTokens, totalCost, savings),

                  const SizedBox(height: 24),

                  // 2. Filter Category Bar (TashilConnectedButtonGroup)
                  _buildFilterBar(context, loc, colorScheme, isMobile),

                  const SizedBox(height: 20),

                  // 3. Service Cards List (The 6 AI Tasks with Top 3 Switchable Models)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildServiceCard(context, category, loc, colorScheme, isMobile, lang);
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<AiServiceCategory> _getFilteredCategories() {
    final all = _controller.categories;
    switch (_activeCategoryFilter) {
      case 'TEXT':
        return all
            .where((c) =>
                c.serviceType == AiServiceType.propertyIngestion ||
                c.serviceType == AiServiceType.marketingCopywriting)
            .toList();
      case 'VALUATION_SEARCH':
        return all
            .where((c) =>
                c.serviceType == AiServiceType.smartValuation ||
                c.serviceType == AiServiceType.semanticSearch)
            .toList();
      case 'LEGAL_VISION':
        return all
            .where((c) =>
                c.serviceType == AiServiceType.legalAdvisor ||
                c.serviceType == AiServiceType.virtualStaging)
            .toList();
      default:
        return all;
    }
  }

  /// Section 1: Hero KPI Header Card
  Widget _buildHeaderSection(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
    int totalTokens,
    double totalCost,
    int savings,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Reset Action Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.smart_toy_rounded, color: colorScheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          loc.tr('aiEngineHubTitle'),
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Gemini & Imagen Mesh',
                            style: TextStyle(
                              color: colorScheme.onTertiaryContainer,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_done_rounded, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                loc.tr('autoSaveActiveBadge'),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('aiEngineHubSubtitle'),
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                TashilButton.tonal(
                  icon: Icons.restore_rounded,
                  label: loc.tr('resetAiDefaultsBtn'),
                  onPressed: () {
                    _controller.resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('aiSettingsResetSuccess')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),

          if (isMobile) ...[
            const SizedBox(height: 12),
            TashilButton.tonal(
              icon: Icons.restore_rounded,
              label: loc.tr('resetAiDefaultsBtn'),
              onPressed: () {
                _controller.resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.tr('aiSettingsResetSuccess')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 20),
          const TashilDivider.fullWidth(),
          const SizedBox(height: 20),

          // 4 KPI Metric Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricPill(
                context: context,
                icon: Icons.all_inclusive_rounded,
                title: loc.tr('activeAiEnginesCount'),
                value: '6 / 6',
                subtitle: loc.tr('allEnginesOperational'),
                color: colorScheme.primary,
              ),
              _buildMetricPill(
                context: context,
                icon: Icons.token_rounded,
                title: loc.tr('monthlyTokenEstimate'),
                value: '${(totalTokens / 1000).toStringAsFixed(1)}K',
                subtitle: loc.tr('basedOnMonthlyRequests'),
                color: colorScheme.secondary,
              ),
              _buildMetricPill(
                context: context,
                icon: Icons.attach_money_rounded,
                title: loc.tr('estimatedMonthlySpend'),
                value: '\$$totalCost',
                subtitle: loc.tr('monthlyAiBudget'),
                color: colorScheme.tertiary,
              ),
              _buildMetricPill(
                context: context,
                icon: Icons.trending_down_rounded,
                title: loc.tr('tokenSavingsIndex'),
                value: '+$savings%',
                subtitle: loc.tr('savingsComparedToHeavy'),
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 2: Category Connected Button Group Filter
  Widget _buildFilterBar(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return TashilConnectedButtonGroup<String>(
      selectedValue: _activeCategoryFilter,
      onSelectionChanged: (val) => setState(() => _activeCategoryFilter = val),
      segments: [
        TashilConnectedButtonSegment<String>(
          value: 'ALL',
          label: loc.tr('allAiServicesFilter'),
          icon: Icons.apps_rounded,
        ),
        TashilConnectedButtonSegment<String>(
          value: 'TEXT',
          label: loc.tr('textAndIngestionFilter'),
          icon: Icons.edit_note_rounded,
        ),
        TashilConnectedButtonSegment<String>(
          value: 'VALUATION_SEARCH',
          label: loc.tr('valuationAndSearchFilter'),
          icon: Icons.query_stats_rounded,
        ),
        TashilConnectedButtonSegment<String>(
          value: 'LEGAL_VISION',
          label: loc.tr('legalAndVisionFilter'),
          icon: Icons.gavel_rounded,
        ),
      ],
    );
  }

  /// Section 3: The AI Service Card with Top 3 Switchable Models
  Widget _buildServiceCard(
    BuildContext context,
    AiServiceCategory category,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
    String lang,
  ) {
    final activeModel = _controller.getActiveModel(category.serviceType);
    final title = lang == 'ar'
        ? category.titleAr
        : (lang == 'hi' ? category.titleHi : category.titleEn);
    final usedFor = lang == 'ar'
        ? category.usedForAr
        : (lang == 'hi' ? category.usedForHi : category.usedForEn);
    final locationInApp = lang == 'ar'
        ? category.locationInAppAr
        : (lang == 'hi' ? category.locationInAppHi : category.locationInAppEn);

    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Icon, Title, Feature Badge, and Active Model Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 17,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category.featureBadge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        loc.tr('switchBetweenLatest3ModelsNotice'),
                        style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Active Model Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        activeModel.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Exact Use Case & Location in Platform ("بيستخدم في إيه")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 15, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface, height: 1.4),
                            children: [
                              TextSpan(
                                text: '${loc.tr('whatIsItUsedForLabel')}: ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: usedFor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined, size: 15, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant, height: 1.3),
                            children: [
                              TextSpan(
                                text: '${loc.tr('locationInWebsiteLabel')}: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                              TextSpan(text: locationInApp),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. The 3 Models Switcher Cards (Top 3 Latest Models)
            Text(
              loc.tr('selectActiveModelHeadline'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, constraints) {
                final useColumns = constraints.maxWidth < 750;
                final modelCards = category.top3Models.map((model) {
                  final isSelected = model.id == activeModel.id;
                  return _buildModelSelectionPill(
                    context: context,
                    model: model,
                    isSelected: isSelected,
                    onTap: () {
                      if (!isSelected) {
                        _controller.switchModel(category.serviceType, model.id);
                        TashilSnackBar.showSuccess(
                          context: context,
                          message: '${model.name} — ${loc.tr('modelActivatedNotification')}',
                        );
                      }
                    },
                    loc: loc,
                    colorScheme: colorScheme,
                    lang: lang,
                  );
                }).toList();

                if (useColumns) {
                  return Column(
                    children: modelCards
                        .map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c))
                        .toList(),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: modelCards
                      .map((c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: c,
                            ),
                          ))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 14),
            const TashilDivider.cardAction(),
            const SizedBox(height: 12),

            // 4. Token & Expense Transparency Breakdown Footer
            _buildTokenExpenseFooter(context, activeModel, loc, colorScheme),
          ],
        ),
      ),
    );
  }

  /// Model Selection Pill / Card
  Widget _buildModelSelectionPill({
    required BuildContext context,
    required AiModelOption model,
    required bool isSelected,
    required VoidCallback onTap,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required String lang,
  }) {
    final modelDesc = lang == 'ar'
        ? model.descriptionAr
        : (lang == 'hi' ? model.descriptionHi : model.descriptionEn);

    // Color code token level
    final (tokenColor, tokenLabel) = switch (model.tokenLevel) {
      TokenConsumptionLevel.ultraLow => (Colors.teal, loc.tr('tokenLevelUltraLow')),
      TokenConsumptionLevel.balanced => (Colors.amber.shade800, loc.tr('tokenLevelBalanced')),
      TokenConsumptionLevel.high => (colorScheme.error, loc.tr('tokenLevelHigh')),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Radio Status + Name + Generation Tag
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    model.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    model.generationBadge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Token Footprint Badge + Latency Badge
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokenColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tokenColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: tokenColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tokenLabel,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: tokenColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚡ ~${model.averageLatencySeconds}s',
                    style: TextStyle(fontSize: 9.5, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Cost per 1M tokens
            Text(
              '\$${model.inputCostPerMillion} / 1M ${loc.tr('inputTokensLabel')}  •  \$${model.outputCostPerMillion} / 1M ${loc.tr('outputTokensLabel')}',
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              modelDesc,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.8), height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Token and Expense Transparency Footer
  Widget _buildTokenExpenseFooter(
    BuildContext context,
    AiModelOption activeModel,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${loc.tr('averageTokenPerCallLabel')}: ~${activeModel.typicalTokensPerCall} ${loc.tr('tokensUnit')}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
            ],
          ),
          Text(
            '${loc.tr('costPerThousandCallsLabel')}: ~\$${activeModel.costPerThousandCalls.toStringAsFixed(3)}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
