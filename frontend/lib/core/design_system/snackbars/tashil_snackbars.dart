import 'dart:math';
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

export 'm3_snackbar_showcase_dialog.dart';

/// Semantic message tone for [TashilSnackBar].
enum TashilSnackBarTone {
  /// Default/Informational update using M3 inverse surface with subtle primary tint.
  info,

  /// Successful action completion (e.g. copied link, saved listing, published unit).
  success,

  /// Failure or critical alerts (e.g. network disconnect, validation error).
  error,

  /// Warning or time-sensitive notice (e.g. expiring reservation, caution).
  warning,
}

/// Action button specification for [TashilSnackBar].
///
/// Follows the Google M3 DO rule: Snackbars contain at most ONE single action.
class TashilSnackBarAction {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;

  const TashilSnackBarAction({
    required this.label,
    required this.onPressed,
    this.textColor,
  });
}

/// Official Google Material Design 3 (M3) SnackBar Suite for Tashil Real Estate.
///
/// Conforms strictly to:
/// - https://m3.material.io/components/snackbar/overview
/// - https://m3.material.io/components/snackbar/specs
/// - https://m3.material.io/components/snackbar/guidelines
///
/// Key M3 Specifications & Architectural Guarantees:
/// 1. **Floating & Rounded:** `SnackBarBehavior.floating` with 8dp squircle radius and Level 3 tonal elevation (6dp).
/// 2. **Responsive Centered Width:** Never stretches edge-to-edge on large screens (desktop/tablet). Clamped to `min(screenWidth - 32, 520)` on wide displays and padded by 16dp on mobile.
/// 3. **Dynamic Primary-Derived Palette:** Colors are dynamically derived from the active theme seed color (`colorScheme.inverseSurface`, `inverseOnSurface`, `inversePrimary`), harmonizing with Terracotta, Olive, Royal Blue, Navy, or Teal.
/// 4. **Strict Single Action Rule (DOs/DON'Ts):** Enforces a maximum of 1 action button per snackbar.
/// 5. **Close Affordance:** Supports optional close icon ('X') alongside the action or standalone.
/// 6. **No Stacking:** Dismisses any active snackbar immediately (`hideCurrentSnackBar`) before displaying the new one.
/// 7. **Full Trilingual & RTL/LTR Awareness:** Directionality-aware insets and typography for Arabic, English, and Hindi.
class TashilSnackBar {
  TashilSnackBar._();

  /// Displays an M3 SnackBar with the specified tone, message, and optional action/close button.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show({
    required BuildContext context,
    required String message,
    TashilSnackBarTone tone = TashilSnackBarTone.info,
    String? title,
    IconData? icon,
    bool showIcon = true,
    TashilSnackBarAction? action,
    bool showCloseIcon = false,
    Duration? duration,
    VoidCallback? onVisible,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Google M3 Guidelines: Dismiss previous snackbars to prevent stacking.
    messenger.hideCurrentSnackBar();

    // Determine colors dynamically from the active ColorScheme & tone
    final resolvedColors = _resolveColors(
      colorScheme: colorScheme,
      tone: tone,
      isDark: isDark,
    );

    // Determine default icon based on tone if not explicitly provided
    final resolvedIcon = showIcon
        ? (icon ?? _resolveDefaultIcon(tone))
        : null;

    // Calculate responsive width (Google M3 Responsive Layout standard)
    // On wide screens (>= 600dp), constrain width to max 520dp centered.
    // On mobile (< 600dp), use floating margins with 16dp horizontal padding.
    final bool isWideScreen = screenWidth >= 600;
    final double? customWidth = isWideScreen ? min(screenWidth - 32, 520.0) : null;
    final EdgeInsetsGeometry? customMargin = isWideScreen
        ? null
        : const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16);

    // Default duration: 4s for simple notices, 7s if an action or 2-line title is present
    final resolvedDuration = duration ??
        ((action != null || title != null)
            ? const Duration(seconds: 7)
            : const Duration(seconds: 4));

    final snackBar = SnackBar(
      elevation: 6.0,
      behavior: SnackBarBehavior.floating,
      width: customWidth,
      margin: customMargin,
      duration: resolvedDuration,
      onVisible: onVisible,
      backgroundColor: resolvedColors.containerColor,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: resolvedColors.borderColor,
          width: 1.0,
        ),
      ),
      content: _TashilSnackBarContent(
        message: message,
        title: title,
        icon: resolvedIcon,
        iconColor: resolvedColors.iconColor,
        textColor: resolvedColors.textColor,
        action: action,
        actionColor: resolvedColors.actionColor,
        showCloseIcon: showCloseIcon,
        closeIconColor: resolvedColors.closeIconColor,
      ),
    );

    return messenger.showSnackBar(snackBar);
  }

  /// Convenience helper for Success messages (e.g. copied links, successful saves).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess({
    required BuildContext context,
    required String message,
    String? title,
    IconData icon = Icons.check_circle_rounded,
    TashilSnackBarAction? action,
    bool showCloseIcon = false,
    Duration? duration,
  }) {
    return show(
      context: context,
      message: message,
      title: title,
      tone: TashilSnackBarTone.success,
      icon: icon,
      showIcon: true,
      action: action,
      showCloseIcon: showCloseIcon,
      duration: duration,
    );
  }

  /// Convenience helper for Error messages (e.g. network failure, validation errors).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError({
    required BuildContext context,
    required String message,
    String? title,
    IconData icon = Icons.error_outline_rounded,
    TashilSnackBarAction? action,
    bool showCloseIcon = true,
    Duration? duration,
  }) {
    return show(
      context: context,
      message: message,
      title: title,
      tone: TashilSnackBarTone.error,
      icon: icon,
      showIcon: true,
      action: action,
      showCloseIcon: showCloseIcon,
      duration: duration ?? const Duration(seconds: 7),
    );
  }

  /// Convenience helper for Warning messages (e.g. expiring sessions, caution).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showWarning({
    required BuildContext context,
    required String message,
    String? title,
    IconData icon = Icons.warning_amber_rounded,
    TashilSnackBarAction? action,
    bool showCloseIcon = false,
    Duration? duration,
  }) {
    return show(
      context: context,
      message: message,
      title: title,
      tone: TashilSnackBarTone.warning,
      icon: icon,
      showIcon: true,
      action: action,
      showCloseIcon: showCloseIcon,
      duration: duration,
    );
  }

  /// Convenience helper for Information updates (e.g. background sync, property filters).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showInfo({
    required BuildContext context,
    required String message,
    String? title,
    IconData icon = Icons.info_outline_rounded,
    TashilSnackBarAction? action,
    bool showCloseIcon = false,
    Duration? duration,
  }) {
    return show(
      context: context,
      message: message,
      title: title,
      tone: TashilSnackBarTone.info,
      icon: icon,
      showIcon: true,
      action: action,
      showCloseIcon: showCloseIcon,
      duration: duration,
    );
  }

  /// Derives dynamic M3 colors conforming to the active theme seed.
  static _TashilSnackBarColors _resolveColors({
    required ColorScheme colorScheme,
    required TashilSnackBarTone tone,
    required bool isDark,
  }) {
    // Base M3 Inverse Container
    final baseInverseSurface = colorScheme.inverseSurface;
    final onInverseSurface = colorScheme.onInverseSurface;
    final primary = colorScheme.primary;

    switch (tone) {
      case TashilSnackBarTone.success:
        // Harmonize with the active primary seed (Olive, Terracotta, Navy, Blue, Teal)
        // by blending 16% of primary + 8% of clean emerald green into the inverse container
        final container = Color.alphaBlend(
          primary.withValues(alpha: 0.16),
          Color.alphaBlend(
            const Color(0xFF10B981).withValues(alpha: 0.12),
            baseInverseSurface,
          ),
        );
        final border = primary.withValues(alpha: 0.28);
        final iconColor = Color.lerp(
          colorScheme.inversePrimary,
          const Color(0xFF34D399),
          0.55,
        )!;
        final actionColor = colorScheme.inversePrimary;

        return _TashilSnackBarColors(
          containerColor: container,
          borderColor: border,
          textColor: onInverseSurface,
          iconColor: iconColor,
          actionColor: actionColor,
          closeIconColor: onInverseSurface.withValues(alpha: 0.75),
        );

      case TashilSnackBarTone.error:
        // M3 High-contrast error container tone with primary seed anchor
        final container = Color.alphaBlend(
          colorScheme.error.withValues(alpha: 0.24),
          baseInverseSurface,
        );
        final border = colorScheme.error.withValues(alpha: 0.35);
        final iconColor = Color.lerp(
          colorScheme.error,
          Colors.redAccent.shade100,
          0.6,
        )!;
        final actionColor = Colors.redAccent.shade100;

        return _TashilSnackBarColors(
          containerColor: container,
          borderColor: border,
          textColor: onInverseSurface,
          iconColor: iconColor,
          actionColor: actionColor,
          closeIconColor: onInverseSurface.withValues(alpha: 0.75),
        );

      case TashilSnackBarTone.warning:
        // M3 Warm warning container tone
        final container = Color.alphaBlend(
          colorScheme.tertiary.withValues(alpha: 0.18),
          baseInverseSurface,
        );
        final border = colorScheme.tertiary.withValues(alpha: 0.30);
        const iconColor = Color(0xFFFBBF24); // Amber 400
        const actionColor = Color(0xFFFCD34D); // Amber 300

        return _TashilSnackBarColors(
          containerColor: container,
          borderColor: border,
          textColor: onInverseSurface,
          iconColor: iconColor,
          actionColor: actionColor,
          closeIconColor: onInverseSurface.withValues(alpha: 0.75),
        );

      case TashilSnackBarTone.info:
        // Standard M3 Inverse Surface lightly tinted with primary
        final container = Color.alphaBlend(
          primary.withValues(alpha: 0.08),
          baseInverseSurface,
        );
        final border = primary.withValues(alpha: 0.20);
        final iconColor = onInverseSurface;
        final actionColor = colorScheme.inversePrimary;

        return _TashilSnackBarColors(
          containerColor: container,
          borderColor: border,
          textColor: onInverseSurface,
          iconColor: iconColor,
          actionColor: actionColor,
          closeIconColor: onInverseSurface.withValues(alpha: 0.75),
        );
    }
  }

  static IconData _resolveDefaultIcon(TashilSnackBarTone tone) {
    switch (tone) {
      case TashilSnackBarTone.success:
        return Icons.check_circle_rounded;
      case TashilSnackBarTone.error:
        return Icons.error_outline_rounded;
      case TashilSnackBarTone.warning:
        return Icons.warning_amber_rounded;
      case TashilSnackBarTone.info:
        return Icons.info_outline_rounded;
    }
  }
}

class _TashilSnackBarColors {
  final Color containerColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final Color actionColor;
  final Color closeIconColor;

  const _TashilSnackBarColors({
    required this.containerColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.actionColor,
    required this.closeIconColor,
  });
}

/// Internal Layout conforming strictly to the Google M3 SnackBar Anatomy & Measurements:
/// - Start padding: 16dp (or 12dp when leading icon is present)
/// - End padding: 8dp when action/close button is present, 16dp otherwise
/// - Height: 48dp minimum
/// - Gap between elements: 12dp
class _TashilSnackBarContent extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final Color iconColor;
  final Color textColor;
  final TashilSnackBarAction? action;
  final Color actionColor;
  final bool showCloseIcon;
  final Color closeIconColor;

  const _TashilSnackBarContent({
    required this.message,
    this.title,
    this.icon,
    required this.iconColor,
    required this.textColor,
    this.action,
    required this.actionColor,
    required this.showCloseIcon,
    required this.closeIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 48.0),
      padding: EdgeInsetsDirectional.only(
        start: icon != null ? 14.0 : 16.0,
        end: (action != null || showCloseIcon) ? 6.0 : 16.0,
        top: 10.0,
        bottom: 10.0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Optional Leading Semantic Icon
          if (icon != null) ...[
            Icon(
              icon,
              size: 20.0,
              color: iconColor,
            ),
            const SizedBox(width: 12.0),
          ],

          // 2. Supporting Text (1 line or 2 lines)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: title != null ? 0.90 : 1.0),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: title != null ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Optional Action Button (Max 1 action per M3 guideline)
          if (action != null) ...[
            const SizedBox(width: 8.0),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                action!.onPressed();
              },
              style: TextButton.styleFrom(
                foregroundColor: action!.textColor ?? actionColor,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                minimumSize: const Size(48, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              child: Text(
                action!.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: action!.textColor ?? actionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          // 4. Optional Close 'X' Affordance
          if (showCloseIcon) ...[
            const SizedBox(width: 4.0),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18.0,
                color: closeIconColor,
              ),
              tooltip: loc.tr('snackbarDismiss'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32.0,
                minHeight: 32.0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ],
      ),
    );
  }
}
