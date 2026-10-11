import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/market_index/models/market_index_model.dart';
import 'package:tashil_real_estate/features/market_index/services/ai_market_index_service.dart';
import 'package:tashil_real_estate/features/market_index/widgets/ai_market_analyst_chat_dialog.dart';
import 'package:tashil_real_estate/features/market_index/widgets/market_historical_chart.dart';

class MarketIndexView extends StatefulWidget {
  const MarketIndexView({super.key});

  @override
  State<MarketIndexView> createState() => _MarketIndexViewState();
}

class _MarketIndexViewState extends State<MarketIndexView> {
  // 'auto' uses cards on mobile and table on desktop; user can explicitly override
  String _districtsViewMode = 'auto';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: CountryController.currentCountry,
      builder: (context, countryCode, _) {
        final service = AiMarketIndexService();
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isMobile = ResponsiveLayout.isMobile(context);
        final isUAE = countryCode == 'AE';
        final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
        final lang = LocaleController.languageCode;

        return ValueListenableBuilder<MarketIndexSummary>(
          valueListenable: service.currentSummaryNotifier as ValueNotifier<MarketIndexSummary>,
          builder: (context, summary, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.analytics_rounded, color: colorScheme.onPrimary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              isUAE ? loc.tr('dxbMarketIndexTitle') : loc.tr('aqarmapIndexTitle'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                                fontSize: isMobile ? 16 : 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TashilButton(
                        onPressed: () => AiMarketAnalystChatDialog.show(context),
                        icon: Icons.psychology_alt_rounded,
                        label: loc.tr('askAiMarketAnalyst'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1. Live Market Pulse & Breaking Signals Ticker (09:00 AM Daily Grounding)
                  _buildLiveMarketPulseTicker(context, summary, lang, loc, isMobile, colorScheme),
                  const SizedBox(height: 24),

                  // Hero Index Banner Card
                  _buildIndexHeroBanner(summary, currency, lang, loc, isMobile, colorScheme),
                  const SizedBox(height: 24),

                  // Gemini AI Executive Insights Box
                  _buildAiExecutiveSummaryBox(context, summary, lang, loc, isMobile, colorScheme),
                  const SizedBox(height: 24),

                  // Owner & Tenant Actionable Recommendations
                  _buildOwnerTenantAdviceRow(summary, lang, loc, isMobile, colorScheme),
                  const SizedBox(height: 24),

                  // Key Market Drivers
                  _buildKeyDriversSection(summary, lang, loc, isMobile, colorScheme),
                  const SizedBox(height: 24),

                  // Top Districts Leasing Velocity & Yield (Responsive Table & Cards)
                  _buildDistrictsSection(summary, currency, lang, loc, isMobile, colorScheme),
                  const SizedBox(height: 24),

                  // Historical Demand Trajectory & Test Simulation Chart
                  MarketHistoricalChart(
                    initialPoints: summary.historicalTrend,
                    countryCode: summary.countryCode,
                    lang: lang,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 24),

                  // Verified Sources & Grounding Notice Banner
                  _buildVerifiedSourcesFooter(summary, loc, isMobile, colorScheme),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIndexHeroBanner(
    MarketIndexSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.7), Colors.black),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      summary.indexName,
                      style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${summary.indexChangeMoM}% ${lang == 'ar' ? 'شهرياً' : lang == 'hi' ? 'मासिक' : 'MoM'}',
                      style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              Text(
                '${loc.tr('lastUpdated')}: ${summary.lastUpdatedTimestamp}',
                style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.7), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Index Points
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${summary.indexPoints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loc.tr('points'),
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Metric Badges in Responsive Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              if (w >= 780) {
                // Wide Desktop: 4 items in a row
                return Row(
                  children: [
                    Expanded(child: _buildHeroMetricTile(loc.tr('demandMomentum'), loc.tr('highDemandSurge'), Icons.local_fire_department_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHeroMetricTile(loc.tr('marketCondition'), loc.tr('sellersMarketState'), Icons.storefront_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHeroMetricTile(loc.tr('averageLeasingSpeed'), '${summary.averageDaysOnMarket.toStringAsFixed(1)} ${loc.tr('days')}', Icons.speed_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHeroMetricTile(loc.tr('annualRentalInflation'), '+${summary.averageRentalGrowthYoY}% ${lang == 'ar' ? 'سنوياً' : lang == 'hi' ? 'वार्षिक' : 'YoY'}', Icons.trending_up_rounded)),
                  ],
                );
              } else if (w >= 480) {
                // Tablet / Large Phone: 2x2 grid
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildHeroMetricTile(loc.tr('demandMomentum'), loc.tr('highDemandSurge'), Icons.local_fire_department_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildHeroMetricTile(loc.tr('marketCondition'), loc.tr('sellersMarketState'), Icons.storefront_rounded)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildHeroMetricTile(loc.tr('averageLeasingSpeed'), '${summary.averageDaysOnMarket.toStringAsFixed(1)} ${loc.tr('days')}', Icons.speed_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildHeroMetricTile(loc.tr('annualRentalInflation'), '+${summary.averageRentalGrowthYoY}% ${lang == 'ar' ? 'سنوياً' : lang == 'hi' ? 'वार्षिक' : 'YoY'}', Icons.trending_up_rounded)),
                      ],
                    ),
                  ],
                );
              } else {
                // Compact Phone: Vertical Stack
                return Column(
                  children: [
                    _buildHeroMetricTile(loc.tr('demandMomentum'), loc.tr('highDemandSurge'), Icons.local_fire_department_rounded),
                    const SizedBox(height: 8),
                    _buildHeroMetricTile(loc.tr('marketCondition'), loc.tr('sellersMarketState'), Icons.storefront_rounded),
                    const SizedBox(height: 8),
                    _buildHeroMetricTile(loc.tr('averageLeasingSpeed'), '${summary.averageDaysOnMarket.toStringAsFixed(1)} ${loc.tr('days')}', Icons.speed_rounded),
                    const SizedBox(height: 8),
                    _buildHeroMetricTile(loc.tr('annualRentalInflation'), '+${summary.averageRentalGrowthYoY}% ${lang == 'ar' ? 'سنوياً' : lang == 'hi' ? 'वार्षिक' : 'YoY'}', Icons.trending_up_rounded),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiExecutiveSummaryBox(
    BuildContext context,
    MarketIndexSummary summary,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    final aiText = AiTranslationService.getLocalizedText(summary.aiExecutiveSummary, lang);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: colorScheme.secondary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      loc.tr('geminiAiMarketDiagnosis'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              TashilButton.tonal(
                onPressed: () => AiMarketAnalystChatDialog.show(context),
                icon: Icons.forum_outlined,
                label: loc.tr('askAiAnalyst'),
                height: 36,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aiText,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerTenantAdviceRow(
    MarketIndexSummary summary,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    final ownerAdvice = AiTranslationService.getLocalizedText(summary.ownerAdvice, lang);
    final tenantAdvice = AiTranslationService.getLocalizedText(summary.tenantAdvice, lang);

    final ownerCard = _buildAdviceCard(
      title: loc.tr('recommendationForOwners'),
      content: ownerAdvice,
      icon: Icons.key_rounded,
      headerColor: colorScheme.primary,
      bgColor: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant,
      colorScheme: colorScheme,
    );

    final tenantCard = _buildAdviceCard(
      title: loc.tr('recommendationForTenants'),
      content: tenantAdvice,
      icon: Icons.person_pin_circle_rounded,
      headerColor: colorScheme.secondary,
      bgColor: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant,
      colorScheme: colorScheme,
    );

    if (isMobile) {
      return Column(
        children: [
          ownerCard,
          const SizedBox(height: 12),
          tenantCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: ownerCard),
        const SizedBox(width: 14),
        Expanded(child: tenantCard),
      ],
    );
  }

  Widget _buildAdviceCard({
    required String title,
    required String content,
    required IconData icon,
    required Color headerColor,
    required Color bgColor,
    required Color borderColor,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: headerColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: headerColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyDriversSection(
    MarketIndexSummary summary,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr('marketMomentumDrivers'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summary.keyDrivers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final driver = summary.keyDrivers[index];
            final title = AiTranslationService.getLocalizedText(driver.title, lang);
            final desc = AiTranslationService.getLocalizedText(driver.impactDescription, lang);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.insights_rounded, color: colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              title,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                driver.metricBadge,
                                style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Top Districts Section with View Switcher (Table vs Cards)
  Widget _buildDistrictsSection(
    MarketIndexSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    // Resolve active presentation mode
    final isCards = _districtsViewMode == 'cards' || (_districtsViewMode == 'auto' && isMobile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Responsive Wrap to prevent overflow
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('districtDemandRanking'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 15,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.tr('updatedDailyFromLiveBookings'),
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),

            // View Mode Toggle (Table vs Cards)
            TashilConnectedButtonGroup<String>(
              height: 34,
              selectedValue: isCards ? 'cards' : 'table',
              onSelectionChanged: (val) {
                setState(() => _districtsViewMode = val);
              },
              segments: [
                TashilConnectedButtonSegment(
                  value: 'table',
                  icon: Icons.table_rows_rounded,
                  label: loc.tr('tableView'),
                ),
                TashilConnectedButtonSegment(
                  value: 'cards',
                  icon: Icons.grid_view_rounded,
                  label: loc.tr('cardsView'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Display either Responsive M3 Cards or Full-width Responsive Table
        isCards
            ? _buildDistrictCards(summary, currency, lang, loc, isMobile, colorScheme)
            : _buildResponsiveTable(summary, currency, lang, loc, isMobile, colorScheme),
      ],
    );
  }

  // Full-width Responsive Table for Desktop and Tablet
  Widget _buildResponsiveTable(
    MarketIndexSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Wrap in horizontal scroll with minimum width if window is narrower than 720px
          final needsScroll = constraints.maxWidth < 720;

          final tableContent = Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2), // District Name & City
              1: FlexColumnWidth(1.2), // Demand Score
              2: FlexColumnWidth(1.5), // Avg Rent/Sqm
              3: FlexColumnWidth(1.1), // Annual Yield
              4: FlexColumnWidth(1.3), // Leasing Velocity
              5: FlexColumnWidth(1.2), // Price Trend MoM
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                ),
                children: [
                  _buildTableHeaderCell(loc.tr('districtName'), colorScheme),
                  _buildTableHeaderCell(loc.tr('demandScore'), colorScheme),
                  _buildTableHeaderCell('${loc.tr('avgRentPerSqm')} ($currency)', colorScheme),
                  _buildTableHeaderCell(loc.tr('annualYield'), colorScheme),
                  _buildTableHeaderCell(loc.tr('leasingVelocity'), colorScheme),
                  _buildTableHeaderCell(loc.tr('priceTrend'), colorScheme),
                ],
              ),

              // Data Rows
              ...summary.topDistricts.map((d) {
                final name = AiTranslationService.getLocalizedText(d.name, lang);
                final city = AiTranslationService.getLocalizedText(d.city, lang);

                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  children: [
                    // District Name & City
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            city,
                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),

                    // Demand Score Badge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${d.demandIndexScore}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('/100', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),

                    // Average Rent per Sqm
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Text(
                        '${CurrencyFormatter.formatAmount(d.averageRentPerSqm, langCode: lang)} $currency/م²',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ),

                    // Annual Yield
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Text(
                        '${d.annualRentalYield.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Leasing Velocity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timelapse_rounded, size: 14, color: colorScheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${d.demandVelocityDays} ${loc.tr('days')}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),

                    // Price Trend Pill
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${d.priceGrowthRateMoM}% MoM',
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          );

          if (needsScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: tableContent,
              ),
            );
          }

          return tableContent;
        },
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  // Mobile-Optimized Modern District Cards
  Widget _buildDistrictCards(
    MarketIndexSummary summary,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;

        if (crossAxisCount == 1) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.topDistricts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildDistrictSingleCard(
                summary.topDistricts[index],
                currency,
                lang,
                loc,
                colorScheme,
              );
            },
          );
        }

        // 2-Column Grid on Tablet
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: summary.topDistricts.map((d) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return SizedBox(
              width: cardWidth,
              child: _buildDistrictSingleCard(d, currency, lang, loc, colorScheme),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDistrictSingleCard(
    DistrictMarketData d,
    String currency,
    String lang,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final name = AiTranslationService.getLocalizedText(d.name, lang);
    final city = AiTranslationService.getLocalizedText(d.city, lang);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Location Info + Demand Score Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            city,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${d.demandIndexScore}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.primary),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),

          // 2x2 Grid of Key District Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.payments_outlined,
                  label: loc.tr('avgRentPerSqm'),
                  value: '${CurrencyFormatter.formatAmount(d.averageRentPerSqm, langCode: lang)} $currency/م²',
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.trending_up_rounded,
                  label: loc.tr('annualYield'),
                  value: '${d.annualRentalYield.toStringAsFixed(1)}%',
                  valueColor: colorScheme.primary,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.timelapse_rounded,
                  label: loc.tr('leasingVelocity'),
                  value: '${d.demandVelocityDays} ${loc.tr('days')}',
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.price_change_outlined,
                  label: loc.tr('priceTrend'),
                  value: '+${d.priceGrowthRateMoM}% MoM',
                  isPill: true,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isPill = false,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          isPill
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }

  /// Live Market Pulse & Breaking News Ticker (09:00 AM Daily Ingestion)
  Widget _buildLiveMarketPulseTicker(
    BuildContext context,
    MarketIndexSummary summary,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loc.tr('dailyUpdateAtNine'),
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                TashilButton.tonal(
                  onPressed: () async {
                    await AiMarketIndexService().refreshDailyMarketData(countryCode: summary.countryCode);
                    if (context.mounted) {
                      TashilSnackBar.showSuccess(
                        context: context,
                        message: loc.tr('refreshingMarketData'),
                      );
                    }
                  },
                  icon: Icons.refresh_rounded,
                  label: loc.tr('instantRefreshNow'),
                  height: 30,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              loc.tr('liveMarketPulseTitle'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: colorScheme.onSurface,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loc.tr('dailyUpdateAtNine'),
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          loc.tr('liveMarketPulseTitle'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TashilButton.tonal(
                  onPressed: () async {
                    await AiMarketIndexService().refreshDailyMarketData(countryCode: summary.countryCode);
                    if (context.mounted) {
                      TashilSnackBar.showSuccess(
                        context: context,
                        message: loc.tr('refreshingMarketData'),
                      );
                    }
                  },
                  icon: Icons.refresh_rounded,
                  label: loc.tr('instantRefreshNow'),
                  height: 32,
                ),
              ],
            ),
          ],
          if (summary.dailySignals.isNotEmpty) ...[
            const SizedBox(height: 14),
            if (isMobile)
              Column(
                children: summary.dailySignals.map((sig) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildSignalCard(sig, lang, colorScheme),
                  );
                }).toList(),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summary.dailySignals.map((sig) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: _buildSignalCard(sig, lang, colorScheme),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignalCard(DailyMarketSignal signal, String lang, ColorScheme colorScheme) {
    final headline = AiTranslationService.getLocalizedText(signal.headline, lang);
    final timeStr = AiTranslationService.getLocalizedText(signal.timeAgo, lang);

    IconData catIcon;
    switch (signal.category) {
      case 'demand':
        catIcon = Icons.trending_up_rounded;
        break;
      case 'economy':
        catIcon = Icons.account_balance_rounded;
        break;
      case 'velocity':
        catIcon = Icons.speed_rounded;
        break;
      case 'investment':
        catIcon = Icons.monetization_on_outlined;
        break;
      default:
        catIcon = Icons.newspaper_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(catIcon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  signal.sourceName,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Official Verified Sources & Google Search Grounding Notice Banner
  Widget _buildVerifiedSourcesFooter(
    MarketIndexSummary summary,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.verified_user_rounded, color: colorScheme.onPrimaryContainer, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.tr('verifiedSourcesLabel'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${loc.tr('officialBaselineSource')} • ${loc.tr('googleGroundingNotice')}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: summary.verifiedSources.map((src) {
                  return Container(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.travel_explore_rounded, size: 13, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            src,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

