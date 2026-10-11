import 'package:flutter/material.dart';

/// Type 4: Official Material Design 3 Toggle Icon Button component.
///
/// Toggles between an unselected state (outlined/standard) and
/// a selected state (filled/tonal container) with smooth animation.
class TashilToggleIconButton extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool> onSelectedChanged;
  final IconData icon;
  final IconData? selectedIcon;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? selectedBackgroundColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;

  const TashilToggleIconButton({
    super.key,
    required this.isSelected,
    required this.onSelectedChanged,
    required this.icon,
    this.selectedIcon,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.selectedBackgroundColor,
    this.selectedIconColor,
    this.unselectedIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeIcon = isSelected ? (selectedIcon ?? icon) : icon;

    return IconButton(
      isSelected: isSelected,
      icon: Icon(activeIcon, size: iconSize),
      selectedIcon: Icon(selectedIcon ?? icon, size: iconSize),
      onPressed: () => onSelectedChanged(!isSelected),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: isSelected
            ? (selectedIconColor ?? colorScheme.onPrimary)
            : (unselectedIconColor ?? colorScheme.onSurfaceVariant),
        backgroundColor: isSelected
            ? (selectedBackgroundColor ?? colorScheme.primary)
            : Colors.transparent,
        minimumSize: Size(size, size),
        fixedSize: Size(size, size),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
