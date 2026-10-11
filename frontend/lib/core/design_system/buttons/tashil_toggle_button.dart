import 'package:flutter/material.dart';

/// Type 2: Official Material Design 3 Toggle Button component.
///
/// A stateful or controlled binary toggle button that transitions between
/// an unselected and selected state with M3 elevation and surface tinting.
class TashilToggleButton extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool> onSelectedChanged;
  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool showCheckmark;

  const TashilToggleButton({
    super.key,
    required this.isSelected,
    required this.onSelectedChanged,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.height = 40.0,
    this.width,
    this.borderRadius,
    this.showCheckmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(20);

    final activeIcon = isSelected
        ? (selectedIcon ?? (showCheckmark ? Icons.check : icon))
        : icon;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: height,
      width: width,
      child: Material(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: () => onSelectedChanged(!isSelected),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (activeIcon != null) ...[
                  Icon(
                    activeIcon,
                    size: 18,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
