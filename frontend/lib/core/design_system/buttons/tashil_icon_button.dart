import 'package:flutter/material.dart';

/// Enumeration of M3 Icon Button variants.
enum TashilIconButtonVariant {
  standard,
  filled,
  tonal,
  outlined,
  close,
}

/// Type 3: Official Material Design 3 Icon Button component.
///
/// Implements standard, filled, tonal, outlined, and shaded close circular icon buttons.
class TashilIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final TashilIconButtonVariant variant;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;

  const TashilIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = TashilIconButtonVariant.tonal,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.color,
    this.backgroundColor,
  });

  const TashilIconButton.standard({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.color,
  })  : variant = TashilIconButtonVariant.standard,
        backgroundColor = null;

  /// Type 3.5: Official Material Design 3 Shaded Close Button.
  ///
  /// Conforms to the Tashil close button rule:
  /// - Resting state: Soft shaded circular container fill (surfaceContainerHighest)
  /// - Hover state: Visibly darkened layer for clear interactive feedback
  /// - Pressed state: Emphasized dark ripple
  const TashilIconButton.close({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.size = 38.0,
    this.iconSize = 18.0,
    this.color,
    this.backgroundColor,
  })  : icon = Icons.close_rounded,
        variant = TashilIconButtonVariant.close;

  const TashilIconButton.filled({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.color,
    this.backgroundColor,
  }) : variant = TashilIconButtonVariant.filled;

  const TashilIconButton.tonal({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.color,
    this.backgroundColor,
  }) : variant = TashilIconButtonVariant.tonal;

  const TashilIconButton.outlined({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.color,
    this.backgroundColor,
  }) : variant = TashilIconButtonVariant.outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isCloseIcon = icon == Icons.close_rounded ||
        icon == Icons.close ||
        icon == Icons.clear_rounded ||
        icon == Icons.clear;

    // Apply the M3 Shaded Close Button standard to any close variant or close icon
    if (variant == TashilIconButtonVariant.close ||
        (variant == TashilIconButtonVariant.standard && isCloseIcon)) {
      final defaultBg = isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerHighest;
      final effectiveBg = backgroundColor ?? defaultBg;
      final effectiveFg = color ?? colorScheme.onSurface;

      final hoverBg = isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.14), effectiveBg)
          : Color.alphaBlend(Colors.black.withValues(alpha: 0.12), effectiveBg);

      final pressedBg = isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.22), effectiveBg)
          : Color.alphaBlend(Colors.black.withValues(alpha: 0.20), effectiveBg);

      return IconButton(
        icon: Icon(icon, size: iconSize),
        onPressed: onPressed,
        tooltip: tooltip ?? MaterialLocalizations.of(context).closeButtonTooltip,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return pressedBg;
            }
            if (states.contains(WidgetState.hovered)) {
              return hoverBg;
            }
            return effectiveBg;
          }),
          foregroundColor: WidgetStatePropertyAll(effectiveFg),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(CircleBorder()),
          minimumSize: WidgetStatePropertyAll(Size(size, size)),
          fixedSize: WidgetStatePropertyAll(Size(size, size)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        ),
      );
    }

    Widget button;

    switch (variant) {
      case TashilIconButtonVariant.close:
      case TashilIconButtonVariant.standard:
        button = IconButton(
          icon: Icon(icon, size: iconSize),
          onPressed: onPressed,
          tooltip: tooltip,
          color: color ?? colorScheme.onSurfaceVariant,
          hoverColor: colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: colorScheme.primary.withValues(alpha: 0.12),
          constraints: BoxConstraints.tightFor(width: size, height: size),
          padding: EdgeInsets.zero,
        );
        break;

      case TashilIconButtonVariant.filled:
        button = IconButton.filled(
          icon: Icon(icon, size: iconSize),
          onPressed: onPressed,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.primary,
            foregroundColor: color ?? colorScheme.onPrimary,
            hoverColor: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.10),
            highlightColor: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.18),
            minimumSize: Size(size, size),
            fixedSize: Size(size, size),
            padding: EdgeInsets.zero,
          ),
        );
        break;

      case TashilIconButtonVariant.tonal:
        button = IconButton.filledTonal(
          icon: Icon(icon, size: iconSize),
          onPressed: onPressed,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.secondaryContainer,
            foregroundColor: color ?? colorScheme.onSecondaryContainer,
            hoverColor: colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: colorScheme.primary.withValues(alpha: 0.12),
            minimumSize: Size(size, size),
            fixedSize: Size(size, size),
            padding: EdgeInsets.zero,
          ),
        );
        break;

      case TashilIconButtonVariant.outlined:
        button = IconButton.outlined(
          icon: Icon(icon, size: iconSize),
          onPressed: onPressed,
          tooltip: tooltip,
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(color ?? colorScheme.onSurfaceVariant),
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
              return BorderSide(color: colorScheme.outlineVariant);
            }),
            minimumSize: WidgetStatePropertyAll(Size(size, size)),
            fixedSize: WidgetStatePropertyAll(Size(size, size)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          ),
        );
        break;
    }

    return button;
  }
}
