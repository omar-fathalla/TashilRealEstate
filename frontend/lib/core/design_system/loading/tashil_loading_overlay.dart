import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading_indicator.dart';

/// Official Material Design 3 Loading Overlay Scrim.
///
/// Wraps any screen or section to provide a non-intrusive, frosted glass
/// loading scrim with an M3 Expressive Morphing indicator and localized message.
class TashilLoadingOverlay extends StatelessWidget {
  /// The underlying child widget to display beneath the loading scrim.
  final Widget child;

  /// Whether the loading overlay is currently active.
  final bool isLoading;

  /// Optional localized message displayed below the loading indicator.
  final String? message;

  /// Indicator size token. Defaults to [TashilLoadingSize.large].
  final TashilLoadingSize indicatorSize;

  /// Indicator primary color. Defaults to [ColorScheme.primary].
  final Color? indicatorColor;

  /// Blur intensity for the frosted glass effect. Defaults to 4.0.
  final double blurSigma;

  const TashilLoadingOverlay({
    super.key,
    this.child = const SizedBox.shrink(),
    this.isLoading = true,
    this.message,
    this.indicatorSize = TashilLoadingSize.large,
    this.indicatorColor,
    this.blurSigma = 4.0,
  });

  /// Imperatively presents a modal loading overlay scrim.
  static Future<T?> show<T>(
    BuildContext context, {
    String? message,
    TashilLoadingSize indicatorSize = TashilLoadingSize.large,
    Color? indicatorColor,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (dialogContext) => PopScope(
        canPop: barrierDismissible,
        child: TashilLoadingOverlay(
          isLoading: true,
          message: message,
          indicatorSize: indicatorSize,
          indicatorColor: indicatorColor,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// Dismisses a currently presented modal loading overlay scrim.
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // 1. Underlying content with touch absorption
        AbsorbPointer(
          absorbing: true,
          child: child,
        ),

        // 2. Frosted Glass Scrim Layer
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
              color: colorScheme.scrim.withValues(alpha: 0.32),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24.0),
              child: Material(
                elevation: 4.0,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TashilLoadingIndicator(
                        size: indicatorSize.dimension,
                        color: indicatorColor ?? colorScheme.primary,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 20.0),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320.0),
                          child: Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  }
}
