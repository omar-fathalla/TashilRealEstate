import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'tashil_slider.dart';

/// Interactive showcase dialog displaying the Official Google Material Design 3 Sliders Suite.
/// Conforms to:
/// - https://m3.material.io/components/sliders/guidelines
/// - https://m3.material.io/components/sliders/specs
///
/// Demonstrates:
/// 1. Expressive 16dp track height with stadium ends.
/// 2. Signature 6dp Stop Gap between active track, handle, and inactive track.
/// 3. Vertical Bar Handle (4dp width x 44dp height) and Round thumb.
/// 4. Animated Floating Value Indicator Balloon with `Curves.easeOutBack` spring physics.
/// 5. Full RTL and LTR support.
class M3SlidersShowcaseDialog extends StatefulWidget {
  const M3SlidersShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3SlidersShowcaseDialog(),
    );
  }

  @override
  State<M3SlidersShowcaseDialog> createState() => _M3SlidersShowcaseDialogState();
}

class _M3SlidersShowcaseDialogState extends State<M3SlidersShowcaseDialog> {
  double _expressivePrice = 70000.0;
  double _steppedScore = 50.0;
  double _roundValue = 35.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final lang = LocaleController.languageCode;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
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
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.tune_rounded, color: colorScheme.onPrimaryContainer, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('maxRentShort'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Google Material Design 3 Expressive Sliders',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: loc.tr('closeModalBtn'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 16),

                  // Content Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. M3 Expressive Slider (Vertical Bar 3.5x26dp, 16dp track, slim 2dp gap)
                          _buildSectionTitle(
                            context,
                            title: '1. M3 Expressive Unified Slider (Vertical Bar & Slim 2dp Gap)',
                            badge: '16dp Track • 2dp Gap',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.tr('maxRent'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${CurrencyFormatter.formatAmount(_expressivePrice, langCode: lang)} ${loc.tr('currency_eg')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TashilSlider(
                            value: _expressivePrice,
                            min: 5000.0,
                            max: 150000.0,
                            divisions: 29,
                            handleType: TashilSliderHandleType.verticalBar,
                            trackHeight: 16.0,
                            gap: 2.0,
                            showDivisionTicks: false,
                            valueLabelFormatter: (val) =>
                                '${CurrencyFormatter.formatAmount(val, langCode: lang)} ${loc.tr('currency_eg')}',
                            onChanged: (val) => setState(() => _expressivePrice = val),
                          ),

                          const SizedBox(height: 24),
                          const TashilDivider.middleInset(),
                          const SizedBox(height: 24),

                          // 2. Discrete Stepped Slider
                          _buildSectionTitle(
                            context,
                            title: '2. Discrete Stepped Slider (10 Divisions with Tick Dots)',
                            badge: 'Stepped • Snapping',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quality Score',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${_steppedScore.round()} / 100',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TashilSlider(
                            value: _steppedScore,
                            min: 0.0,
                            max: 100.0,
                            divisions: 10,
                            handleType: TashilSliderHandleType.verticalBar,
                            trackHeight: 16.0,
                            gap: 2.0,
                            showDivisionTicks: true,
                            valueLabelFormatter: (val) => '${val.round()}%',
                            onChanged: (val) => setState(() => _steppedScore = val),
                          ),

                          const SizedBox(height: 24),
                          const TashilDivider.middleInset(),
                          const SizedBox(height: 24),

                          // 3. Round Thumb Handle Variant
                          _buildSectionTitle(
                            context,
                            title: '3. Round Thumb Handle Variant (20dp Circle)',
                            badge: 'Classic Round Thumb',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Radius Coverage',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${_roundValue.round()} km',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TashilSlider(
                            value: _roundValue,
                            min: 1.0,
                            max: 50.0,
                            divisions: 49,
                            handleType: TashilSliderHandleType.round,
                            trackHeight: 16.0,
                            gap: 6.0,
                            valueLabelFormatter: (val) => '${val.round()} km',
                            onChanged: (val) => setState(() => _roundValue = val),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 12),

                  // Actions
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TashilButton(
                      label: loc.tr('closeModalBtn'),
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                      height: 40,
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

  Widget _buildSectionTitle(BuildContext context, {required String title, required String badge}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
