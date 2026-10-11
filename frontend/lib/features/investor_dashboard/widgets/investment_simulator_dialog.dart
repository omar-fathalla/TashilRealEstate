import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/sliders/tashil_sliders.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/investor_dashboard/services/investor_analytics_service.dart';

/// Official Material Design 3 (M3) Investment Simulator Dialog for Tashil Real Estate.
/// Conforms to:
/// - Google M3 Dialog Specifications (28dp squircle radius, Level 3 elevation).
/// - Official M3 Sliders Suite ([TashilSlider] with 16dp track, vertical bar handle, and stop gap).
/// - Official M3 Cards Suite ([TashilCard.outlined] with 1dp outline boundary).
/// - The M3 Shaded Close Button Standard ([TashilIconButton.close]).
/// - Zero Language Mixing & Trilingual Parity (AR, EN, HI).
/// - Dynamic Primary-Derived Seed Palette.
class InvestmentSimulatorDialog extends StatefulWidget {
  const InvestmentSimulatorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const InvestmentSimulatorDialog(),
    );
  }

  @override
  State<InvestmentSimulatorDialog> createState() => _InvestmentSimulatorDialogState();
}

class _InvestmentSimulatorDialogState extends State<InvestmentSimulatorDialog> {
  final _service = InvestorAnalyticsService();

  late TextEditingController _priceController;
  late TextEditingController _rentController;
  late TextEditingController _nameController;
  late TextEditingController _maintenanceController;
  late TextEditingController _serviceFeeController;

  double _downPaymentPercent = 30.0;
  double _annualMaintenance = 15000.0;
  double _annualServiceFee = 18000.0;
  double _annualGrowthRate = 8.5;

  late InvestmentSimulationResult _currentResult;

  @override
  void initState() {
    super.initState();
    final isUAE = CountryController.isUAE;
    final initialPrice = isUAE ? 2500000.0 : 4000000.0;
    final initialRent = isUAE ? 18000.0 : 32000.0;

    _priceController = TextEditingController(text: initialPrice.toStringAsFixed(0));
    _rentController = TextEditingController(text: initialRent.toStringAsFixed(0));
    _nameController = TextEditingController(
      text: isUAE ? 'شقة استثمارية - دبي داون تاون' : 'شقة استثمارية - التجمع الخامس',
    );

    _annualMaintenance = isUAE ? 8000.0 : 15000.0;
    _annualServiceFee = isUAE ? 20000.0 : 18000.0;

    _maintenanceController = TextEditingController(text: _annualMaintenance.toInt().toString());
    _serviceFeeController = TextEditingController(text: _annualServiceFee.toInt().toString());

    _recalculate();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _rentController.dispose();
    _nameController.dispose();
    _maintenanceController.dispose();
    _serviceFeeController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final price = double.tryParse(_priceController.text) ?? (CountryController.isUAE ? 2500000 : 4000000);
    final rent = double.tryParse(_rentController.text) ?? (CountryController.isUAE ? 18000 : 32000);
    final maintenance = double.tryParse(_maintenanceController.text) ?? (CountryController.isUAE ? 8000 : 15000);
    final serviceFee = double.tryParse(_serviceFeeController.text) ?? (CountryController.isUAE ? 20000 : 18000);

    setState(() {
      _annualMaintenance = maintenance;
      _annualServiceFee = serviceFee;
      _currentResult = _service.simulateInvestment(
        purchasePrice: price,
        downPaymentPercentage: _downPaymentPercent,
        expectedMonthlyRent: rent,
        annualMaintenanceEstimate: maintenance,
        annualServiceFeeEstimate: serviceFee,
        annualAppreciationRate: _annualGrowthRate,
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = CountryController.isUAE;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, currentLocale, _) {
        final loc = AppLocalizations.of(context);
        final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
        final lang = currentLocale.languageCode;

        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          elevation: 3.0,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.25),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 32,
            vertical: isMobile ? 16 : 28,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960, maxHeight: 840),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. M3 Header with Icon Badge & Shaded Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calculate_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('investmentSimulatorTitle'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 17,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.tr('investmentSimulatorSubtitle'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 14),
                  TashilDivider.fullWidth(),
                  const SizedBox(height: 14),

                  // 2. Scrollable Body
                  Expanded(
                    child: isMobile
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildInputSection(theme, loc, currency, lang),
                                const SizedBox(height: 20),
                                _buildResultsSection(theme, loc, currency, lang),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Inputs side
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  child: _buildInputSection(theme, loc, currency, lang),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Results side
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  child: _buildResultsSection(theme, loc, currency, lang),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // 3. Pinned Action Footer
                  const SizedBox(height: 12),
                  TashilDivider.cardAction(),
                  const SizedBox(height: 14),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TashilButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      icon: Icons.check_rounded,
                      label: loc.tr('close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(ThemeData theme, AppLocalizations loc, String currency, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              loc.tr('unitParameters'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Property Name
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: loc.tr('propertyName'),
            prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Purchase Price
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          onChanged: (_) => _recalculate(),
          decoration: InputDecoration(
            labelText: '${loc.tr('purchasePrice')} ($currency)',
            prefixIcon: const Icon(Icons.monetization_on_rounded, size: 20),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Down Payment Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${loc.tr('downPaymentPercentage')}: ${_downPaymentPercent.toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${CurrencyFormatter.formatAmount(_currentResult.downPayment, langCode: lang)} $currency',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TashilSlider(
          value: _downPaymentPercent,
          min: 10,
          max: 100,
          divisions: 18,
          handleType: TashilSliderHandleType.verticalBar,
          valueLabelFormatter: (val) => '${val.toInt()}%',
          activeTrackColor: theme.colorScheme.primary,
          onChanged: (val) {
            setState(() => _downPaymentPercent = val);
            _recalculate();
          },
        ),
        const SizedBox(height: 10),

        // Expected Monthly Rent
        TextField(
          controller: _rentController,
          keyboardType: TextInputType.number,
          onChanged: (_) => _recalculate(),
          decoration: InputDecoration(
            labelText: '${loc.tr('expectedMonthlyRent')} ($currency)',
            prefixIcon: const Icon(Icons.payments_rounded, size: 20),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Annual Expenses
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _maintenanceController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _recalculate(),
                decoration: InputDecoration(
                  labelText: '${loc.tr('annualMaintenance')} ($currency)',
                  prefixIcon: const Icon(Icons.handyman_rounded, size: 18),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _serviceFeeController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _recalculate(),
                decoration: InputDecoration(
                  labelText: '${loc.tr('annualServiceFees')} ($currency)',
                  prefixIcon: const Icon(Icons.room_service_rounded, size: 18),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Annual Capital Growth %
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${loc.tr('annualAppreciationForecast')}: ${_annualGrowthRate.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TashilSlider(
          value: _annualGrowthRate,
          min: 0,
          max: 20,
          divisions: 40,
          handleType: TashilSliderHandleType.verticalBar,
          valueLabelFormatter: (val) => '${val.toStringAsFixed(1)}%',
          activeTrackColor: theme.colorScheme.secondary,
          onChanged: (val) {
            setState(() => _annualGrowthRate = val);
            _recalculate();
          },
        ),
      ],
    );
  }

  Widget _buildResultsSection(ThemeData theme, AppLocalizations loc, String currency, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
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
                  loc.tr('simulationResultsTitle'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      size: 14,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${loc.tr('capRate')}: ${_currentResult.capRatePercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Main Output Cards with TashilCard.outlined
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    loc.tr('netOperatingIncomeNoi'),
                    '${CurrencyFormatter.formatAmount(_currentResult.netOperatingIncome, langCode: lang)} $currency',
                    theme.colorScheme.primary,
                    Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    loc.tr('cashOnCashReturn'),
                    '${_currentResult.cashOnCashReturnPercentage.toStringAsFixed(2)}%',
                    theme.colorScheme.secondary,
                    Icons.percent_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    loc.tr('paybackPeriod'),
                    '${_currentResult.paybackPeriodYears.toStringAsFixed(1)} ${loc.tr('years')}',
                    theme.colorScheme.tertiary,
                    Icons.timelapse_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    theme,
                    loc.tr('fiveYearProjectedValue'),
                    '${CurrencyFormatter.formatAmount(_currentResult.fiveYearProjectedValue, langCode: lang)} $currency',
                    theme.colorScheme.primary,
                    Icons.auto_graph_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5-Year Cumulative Profit Breakdown Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  Color.lerp(theme.colorScheme.primary, Colors.black, 0.18) ?? theme.colorScheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('fiveYearCumulativeReturn'),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '+ ${CurrencyFormatter.formatAmount(_currentResult.totalEstimated5YearProfit, langCode: lang)} $currency',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.tr('fiveYearSimulationNote'),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(ThemeData theme, String label, String value, Color color, IconData icon) {
    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
