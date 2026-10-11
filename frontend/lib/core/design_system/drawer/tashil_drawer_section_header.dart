import 'package:flutter/material.dart';

/// Official Material Design 3 (M3) Drawer Section Header.
///
/// Implements Google Material Design 3 Drawer Section Header:
/// - Typography: `titleSmall` (M3 token).
/// - Alignment: Directional start alignment (RTL/LTR).
/// - Padding: 16dp start/end padding, height ~48dp.
/// - When collapsed, hides gracefully or displays a subtle divider.
///
/// Reference: https://m3.material.io/components/navigation-drawer/specs
class TashilDrawerSectionHeader extends StatelessWidget {
  final String title;
  final bool isCollapsed;
  final Widget? trailing;

  const TashilDrawerSectionHeader({
    super.key,
    required this.title,
    this.isCollapsed = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return const SizedBox(height: 8.0);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 28.0,
        end: 16.0,
        top: 14.0,
        bottom: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
