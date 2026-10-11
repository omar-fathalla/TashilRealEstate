import 'package:flutter/material.dart';
import 'tashil_tab_item.dart';

/// Official Material Design 3 (M3) Secondary Tab Bar.
///
/// Implements Google Material Design 3 Secondary Tab specifications:
/// - Used for sub-navigation, category filtering, or in-view segmentation
/// - Full-width 2dp indicator underline
/// - 48dp container height
///
/// Reference: https://m3.material.io/components/tabs/specs
class TashilSecondaryTabBar extends StatelessWidget {
  final List<TashilTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isScrollable;

  const TashilSecondaryTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isScrollable = false,
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
            color: colorScheme.outlineVariant.withAlpha(90),
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
                  return _buildItem(
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
                return _buildItem(
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

  Widget _buildItem(
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
      splashColor: colorScheme.primary.withAlpha(25),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? activeColor : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 17, color: currentColor),
                const SizedBox(width: 6),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: currentColor,
                ),
              ),
              if (item.count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.count!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isFlexible) {
      return Expanded(child: content);
    }
    return content;
  }
}
