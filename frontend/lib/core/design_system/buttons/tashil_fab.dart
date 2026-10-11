import 'package:flutter/material.dart';

/// Size variants for M3 Floating Action Button.
enum TashilFabSize {
  small,
  regular,
  large,
}

/// Type 8: Official Material Design 3 Floating Action Button (FAB) component.
///
/// Features M3 squircle container shape with gentle tonal elevation.
class TashilFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final TashilFabSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final double elevation;

  const TashilFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = TashilFabSize.regular,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.elevation = 2.0,
  });

  const TashilFloatingActionButton.small({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.elevation = 2.0,
  }) : size = TashilFabSize.small;

  const TashilFloatingActionButton.large({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.elevation = 2.0,
  }) : size = TashilFabSize.large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = backgroundColor ?? colorScheme.primaryContainer;
    final fg = foregroundColor ?? colorScheme.onPrimaryContainer;

    switch (size) {
      case TashilFabSize.small:
        return FloatingActionButton.small(
          onPressed: onPressed,
          tooltip: tooltip,
          elevation: elevation,
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20),
        );

      case TashilFabSize.regular:
        return FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          elevation: elevation,
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 24),
        );

      case TashilFabSize.large:
        return FloatingActionButton.large(
          onPressed: onPressed,
          tooltip: tooltip,
          elevation: elevation,
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Icon(icon, size: 32),
        );
    }
  }
}

/// Type 9: Official Material Design 3 Extended FAB component.
///
/// Combines an icon with a prominent descriptive text label in an M3 squircle container.
class TashilExtendedFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final double elevation;
  final bool isExtended;

  const TashilExtendedFloatingActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.elevation = 2.0,
    this.isExtended = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = backgroundColor ?? colorScheme.primaryContainer;
    final fg = foregroundColor ?? colorScheme.onPrimaryContainer;

    return FloatingActionButton.extended(
      onPressed: onPressed,
      tooltip: tooltip,
      elevation: elevation,
      backgroundColor: bg,
      foregroundColor: fg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
      isExtended: isExtended,
    );
  }
}
