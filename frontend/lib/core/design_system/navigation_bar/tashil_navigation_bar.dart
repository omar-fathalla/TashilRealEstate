import 'package:flutter/material.dart';

export 'tashil_navigation_destination.dart';
export 'tashil_badge.dart';
export 'm3_navigation_bar_showcase_dialog.dart';

/// Official Material Design 3 (M3) Navigation Bar Container for Tashil Real Estate.
///
/// Implements Google Material Design 3 Navigation Bar specifications:
/// - Container Height: 80.0dp.
/// - Elevation: Level 0 (no drop shadow as specified in M3 vs M2 differences).
/// - Layout: 3 to 5 destinations distributed horizontally across the screen width.
/// - Active indicator: 64x32dp pill in [ColorScheme.secondaryContainer].
/// - Surface color: [ColorScheme.surfaceContainerLowest] or [ColorScheme.surfaceContainer].
///
/// References:
/// - https://m3.material.io/components/navigation-bar/overview
/// - https://m3.material.io/components/navigation-bar/specs
class TashilNavigationBar extends StatelessWidget {
  final List<Widget> destinations;
  final double height;
  final Color? backgroundColor;
  final bool hasTopBorder;
  final Color? borderColor;

  const TashilNavigationBar({
    super.key,
    required this.destinations,
    this.height = 80.0,
    this.backgroundColor,
    this.hasTopBorder = true,
    this.borderColor,
  }) : assert(destinations.length >= 2 && destinations.length <= 5,
            'M3 Navigation Bar requires 2 to 5 destinations.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBg = backgroundColor ?? colorScheme.surfaceContainerLowest;
    final effectiveBorderColor =
        borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      height: height + MediaQuery.paddingOf(context).bottom,
      decoration: BoxDecoration(
        color: effectiveBg,
        border: hasTopBorder
            ? Border(
                top: BorderSide(
                  color: effectiveBorderColor,
                  width: 1.0,
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: destinations.map((dest) {
              return Expanded(
                child: Center(child: dest),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
