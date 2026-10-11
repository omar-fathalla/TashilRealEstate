import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_modal_dialog.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading_indicator.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading_overlay.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';

/// Interactive Material Design 3 Expressive Loading Indicator Showcase Dialog.
class M3LoadingShowcaseDialog extends StatefulWidget {
  const M3LoadingShowcaseDialog({super.key});

  /// Displays the interactive showcase dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3LoadingShowcaseDialog(),
    );
  }

  @override
  State<M3LoadingShowcaseDialog> createState() => _M3LoadingShowcaseDialogState();
}

class _M3LoadingShowcaseDialogState extends State<M3LoadingShowcaseDialog> {
  bool _isSimulatingOverlay = false;

  void _triggerOverlaySimulation() {
    setState(() => _isSimulatingOverlay = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isSimulatingOverlay = false);
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.tr('loadingOverlaySimulatedNotice')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TashilLoadingOverlay(
      isLoading: _isSimulatingOverlay,
      message: loc.tr('loadingAiProcessing'),
      child: TashilModalDialog(
        title: loc.tr('m3LoadingIndicatorTitle'),
        subtitle: loc.tr('m3LoadingExpressiveSubtitle'),
        icon: Icons.hourglass_top_rounded,
        maxWidth: 680,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TashilButton(
              label: loc.tr('confirm'),
              icon: Icons.check_circle_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Standard M3 Sizes (Small 24dp, Medium 48dp, Large 72dp)
              Text(
                loc.tr('m3LoadingIndicatorTitle'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TashilCard.outlined(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Row(
                  children: [
                    // Small (24dp)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 80,
                            child: Center(
                              child: TashilLoadingIndicator(size: 24.0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.tr('loadingSizeSmall'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Medium (48dp)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 80,
                            child: Center(
                              child: TashilLoadingIndicator(size: 48.0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.tr('loadingSizeMedium'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Large (72dp)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 80,
                            child: Center(
                              child: TashilLoadingIndicator(size: 72.0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.tr('loadingSizeLarge'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Floating Container Variant (Pull-to-refresh)
              Text(
                loc.tr('loadingContainerVariant'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TashilCard.outlined(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        TashilLoadingIndicator.medium(hasContainer: true),
                        const SizedBox(height: 10),
                        const Text(
                          'M3 Elevation Level 2',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TashilLoadingIndicator.large(
                          hasContainer: true,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tertiary Color Scheme',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 3: Live Overlay Simulation
              TashilCard.filled(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.blur_on_rounded, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('simulateOverlayAction'),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.tr('loadingAiProcessing'),
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TashilButton(
                      label: loc.tr('simulateOverlayAction'),
                      icon: Icons.play_arrow_rounded,
                      onPressed: _triggerOverlaySimulation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
