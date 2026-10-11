import 'package:flutter/material.dart';
import '../loading/tashil_loading_indicator.dart';

/// Enumeration of Material Design 3 Button visual variants.
enum TashilButtonVariant {
  filled,
  tonal,
  outlined,
  elevated,
  text,
}

/// Type 1: Official Material Design 3 Button component.
///
/// Implements M3 button specifications with single-icon support,
/// tonal palette integration, and pure RTL/LTR adaptability.
class TashilButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TashilButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? customColor;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const TashilButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = TashilButtonVariant.filled,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.borderRadius,
    this.customColor,
    this.tooltip,
    this.padding,
  });

  const TashilButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.borderRadius,
    this.customColor,
    this.tooltip,
    this.padding,
  }) : variant = TashilButtonVariant.filled;

  const TashilButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.borderRadius,
    this.customColor,
    this.tooltip,
    this.padding,
  }) : variant = TashilButtonVariant.tonal;

  const TashilButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.borderRadius,
    this.customColor,
    this.tooltip,
    this.padding,
  }) : variant = TashilButtonVariant.outlined;

  const TashilButton.elevated({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.borderRadius,
    this.customColor,
    this.tooltip,
    this.padding,
  }) : variant = TashilButtonVariant.elevated;

  const TashilButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.borderRadius,
    this.customColor,
    this.tooltip,
    this.padding,
  }) : variant = TashilButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(20);

    // Official Material Design 3 Container & Foreground Color Roles
    final Color foregroundColor;
    final Color backgroundColor;

    switch (variant) {
      case TashilButtonVariant.filled:
        backgroundColor = customColor ?? colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        break;
      case TashilButtonVariant.tonal:
        final cColor = customColor;
        if (cColor != null) {
          if (cColor == colorScheme.error) {
            backgroundColor = colorScheme.errorContainer;
            foregroundColor = colorScheme.onErrorContainer;
          } else {
            backgroundColor = cColor.withValues(alpha: 0.16);
            foregroundColor = cColor;
          }
        } else {
          backgroundColor = colorScheme.secondaryContainer;
          foregroundColor = colorScheme.onSecondaryContainer;
        }
        break;
      case TashilButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = customColor ?? colorScheme.primary;
        break;
      case TashilButtonVariant.elevated:
        backgroundColor = colorScheme.surface;
        foregroundColor = customColor ?? colorScheme.primary;
        break;
      case TashilButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = customColor ?? colorScheme.primary;
        break;
    }

    // Official M3 Button Padding: 16dp start with icon, 24dp end; 10dp vertical breathing room
    final effectivePadding = padding ??
        (icon != null
            ? const EdgeInsetsDirectional.only(start: 16, end: 20, top: 10, bottom: 10)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 10));

    Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          TashilLoadingIndicator(
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: foregroundColor, // Strict M3 Contrast Enforcer: Never dark-on-dark
            ),
          ),
        ),
      ],
    );

    Widget button;

    switch (variant) {
      case TashilButtonVariant.filled:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            overlayColor: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(borderRadius: radius),
            minimumSize: Size(width ?? 0, height),
            padding: effectivePadding,
            visualDensity: VisualDensity.standard,
          ),
          child: childContent,
        );
        break;

      case TashilButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            overlayColor: colorScheme.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: radius),
            minimumSize: Size(width ?? 0, height),
            padding: effectivePadding,
            visualDensity: VisualDensity.standard,
          ),
          child: childContent,
        );
        break;

      case TashilButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return colorScheme.primary.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.pressed)) {
                return colorScheme.primary.withValues(alpha: 0.12);
              }
              return null;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return BorderSide(color: colorScheme.primary.withValues(alpha: isDark ? 0.55 : 0.45));
              }
              return BorderSide(
                color: customColor?.withValues(alpha: 0.5) ?? colorScheme.outlineVariant,
              );
            }),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radius)),
            minimumSize: WidgetStatePropertyAll(Size(width ?? 0, height)),
            padding: WidgetStatePropertyAll(effectivePadding),
            visualDensity: VisualDensity.standard,
          ),
          child: childContent,
        );
        break;

      case TashilButtonVariant.elevated:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 1,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            overlayColor: colorScheme.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: radius),
            minimumSize: Size(width ?? 0, height),
            padding: effectivePadding,
            visualDensity: VisualDensity.standard,
          ),
          child: childContent,
        );
        break;

      case TashilButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            overlayColor: colorScheme.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: radius),
            minimumSize: Size(width ?? 0, height),
            padding: effectivePadding,
            visualDensity: VisualDensity.standard,
          ),
          child: childContent,
        );
        break;
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
