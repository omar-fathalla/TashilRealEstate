import 'package:flutter/material.dart';
import 'tashil_tab_item.dart';

/// Official Material Design 3 (M3) Primary Tab Bar.
///
/// Implements Google Material Design 3 Tabs specifications:
/// - Container height: 48dp (inline icon + text) or 64dp (stacked icon)
/// - Active indicator: 3dp pill with rounded corners (primary color)
/// - Full-width bottom divider: 1dp outline-variant
/// - Active label/icon: primary color, bold typography
/// - Inactive label/icon: onSurfaceVariant color, medium typography
/// - Fixed (equal-width distribution) or scrollable
///
/// Reference: https://m3.material.io/components/tabs/specs
class TashilPrimaryTabBar extends StatelessWidget {
  final List<TashilTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;
  final bool stackedIcon;
  final double height;

  const TashilPrimaryTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isScrollable = false,
    this.stackedIcon = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(120),
            width: 1.0,
          ),
        ),
      ),
      child: isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tabs.length, (index) {
                  return _buildTabItem(
                    context,
                    item: tabs[index],
                    isSelected: selectedIndex == index,
                    colorScheme: colorScheme,
                    onTap: () => onTabSelected(index),
                    isFlexible: false,
                  );
                }),
              ),
            )
          : Row(
              children: List.generate(tabs.length, (index) {
                return _buildTabItem(
                  context,
                  item: tabs[index],
                  isSelected: selectedIndex == index,
                  colorScheme: colorScheme,
                  onTap: () => onTabSelected(index),
                  isFlexible: true,
                );
              }),
            ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required TashilTabItem item,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    required bool isFlexible,
  }) {
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;
    final currentColor = isSelected ? activeColor : inactiveColor;

    final content = InkWell(
      onTap: onTap,
      splashColor: colorScheme.primary.withAlpha(30),
      highlightColor: colorScheme.primary.withAlpha(15),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center content: icon + label + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 19,
                    color: currentColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: currentColor,
                    letterSpacing: -0.2,
                  ),
                ),
                if (item.count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.count!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (item.badge != null) ...[
                  const SizedBox(width: 6),
                  item.badge!,
                ],
              ],
            ),

            // M3 Active Indicator: 3dp pill at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isSelected ? 1.0 : 0.0,
                child: Center(
                  child: Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isFlexible) {
      return Expanded(child: content);
    }
    return content;
  }
}
