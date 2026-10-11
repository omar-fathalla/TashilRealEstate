import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_modal_dialog.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'tashil_progress_types.dart';
import 'tashil_linear_progress.dart';
import 'tashil_circular_progress.dart';

/// Interactive showcase dialog displaying the Official Google Material Design 3 Expressive Progress Indicators Suite.
/// Conforms to:
/// - https://m3.material.io/components/progress-indicators/overview
/// - https://m3.material.io/components/progress-indicators/specs
class M3ProgressShowcaseDialog extends StatefulWidget {
  const M3ProgressShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3ProgressShowcaseDialog(),
    );
  }

  @override
  State<M3ProgressShowcaseDialog> createState() => _M3ProgressShowcaseDialogState();
}

class _M3ProgressShowcaseDialogState extends State<M3ProgressShowcaseDialog> {
  double _determinateValue = 0.65;
  TashilProgressShape _selectedShape = TashilProgressShape.wavy;

  // Simulation state
  bool _isDownloading = false;
  double _simulatedDownloadProgress = 0.0;
  Timer? _downloadTimer;

  bool _isUploading = false;
  double _simulatedUploadProgress = 0.0;
  Timer? _uploadTimer;

  @override
  void dispose() {
    _downloadTimer?.cancel();
    _uploadTimer?.cancel();
    super.dispose();
  }

  void _startDownloadSimulation(AppLocalizations loc) {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _simulatedDownloadProgress = 0.0;
    });

    _downloadTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _simulatedDownloadProgress += 0.05;
        if (_simulatedDownloadProgress >= 1.0) {
          _simulatedDownloadProgress = 1.0;
          _isDownloading = false;
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.tr('downloadCompleted')),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });
  }

  void _startUploadSimulation(AppLocalizations loc) {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _simulatedUploadProgress = 0.0;
    });

    _uploadTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _simulatedUploadProgress += 0.04;
        if (_simulatedUploadProgress >= 1.0) {
          _simulatedUploadProgress = 1.0;
          _isUploading = false;
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.tr('uploadCompleted')),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return TashilModalDialog(
          title: loc.tr('m3ProgressIndicatorTitle'),
          subtitle: loc.tr('m3ProgressExpressiveSubtitle'),
          icon: Icons.linear_scale_rounded,
          maxWidth: 720,
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
                // 1. Determinate Interactive Playground Card
                TashilCard.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.tr('determinateMode'),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(_determinateValue * 100).round()}%',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Shape selector using TashilConnectedButtonGroup
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TashilConnectedButtonGroup<TashilProgressShape>(
                            selectedValue: _selectedShape,
                            onSelectionChanged: (shape) {
                              setState(() => _selectedShape = shape);
                            },
                            height: 38.0,
                            segments: [
                              TashilConnectedButtonSegment(
                                value: TashilProgressShape.wavy,
                                label: loc.tr('wavyShape'),
                                icon: Icons.waves_rounded,
                              ),
                              TashilConnectedButtonSegment(
                                value: TashilProgressShape.flat,
                                label: loc.tr('flatShape'),
                                icon: Icons.horizontal_rule_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Linear Determinate Track
                        Text(
                          loc.tr('linearProgressTitle'),
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        TashilLinearProgressIndicator(
                          value: _determinateValue,
                          shape: _selectedShape,
                          showStopIndicator: true,
                        ),
                        const SizedBox(height: 24),

                        // Circular Determinate Track
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr('circularProgressTitle'),
                                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    TashilCircularProgressIndicator(
                                      value: _determinateValue,
                                      shape: _selectedShape,
                                      sizeToken: TashilCircularProgressSize.standard,
                                    ),
                                    const SizedBox(width: 16),
                                    TashilCircularProgressIndicator(
                                      value: _determinateValue,
                                      shape: _selectedShape,
                                      sizeToken: TashilCircularProgressSize.large,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Scrub slider
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('progressPercentage'),
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                  Slider(
                                    value: _determinateValue,
                                    onChanged: (v) => setState(() => _determinateValue = v),
                                    min: 0.0,
                                    max: 1.0,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Indeterminate Fluid Motion Card
                TashilCard.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.all_inclusive_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              loc.tr('indeterminateMode'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Wavy Indeterminate Linear Bar
                        Text(
                          loc.tr('wavyShape'),
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        const TashilLinearProgressIndicator(
                          value: null,
                          shape: TashilProgressShape.wavy,
                        ),
                        const SizedBox(height: 16),

                        // Flat Indeterminate Linear Bar
                        Text(
                          loc.tr('flatShape'),
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        const TashilLinearProgressIndicator(
                          value: null,
                          shape: TashilProgressShape.flat,
                        ),
                        const SizedBox(height: 20),

                        // Indeterminate Circulars (Flat & Wavy)
                        Row(
                          children: [
                            const TashilCircularProgressIndicator(
                              value: null,
                              shape: TashilProgressShape.wavy,
                              sizeToken: TashilCircularProgressSize.standard,
                            ),
                            const SizedBox(width: 24),
                            const TashilCircularProgressIndicator(
                              value: null,
                              shape: TashilProgressShape.flat,
                              sizeToken: TashilCircularProgressSize.standard,
                            ),
                            const SizedBox(width: 24),
                            const TashilCircularProgressIndicator(
                              value: null,
                              shape: TashilProgressShape.wavy,
                              sizeToken: TashilCircularProgressSize.small,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Real-world Simulation Card (Downloads & Uploads)
                TashilCard.elevated(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_sync_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              loc.tr('simulateFileDownload'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isDownloading || _simulatedDownloadProgress > 0.0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.tr('simulateFileDownload'),
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${(_simulatedDownloadProgress * 100).round()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TashilLinearProgressIndicator(
                            value: _simulatedDownloadProgress,
                            shape: TashilProgressShape.wavy,
                          ),
                          const SizedBox(height: 16),
                        ],

                        TashilDivider.cardAction(),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            TashilButton.outlined(
                              label: loc.tr('simulateProgressMediaUpload'),
                              icon: Icons.upload_file_rounded,
                              onPressed: _isUploading ? null : () => _startUploadSimulation(loc),
                            ),
                            TashilButton(
                              label: loc.tr('simulateFileDownload'),
                              icon: Icons.download_rounded,
                              onPressed: _isDownloading ? null : () => _startDownloadSimulation(loc),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
