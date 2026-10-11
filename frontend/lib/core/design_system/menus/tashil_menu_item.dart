import 'package:flutter/material.dart';

/// Data model representing an item in the Material Design 3 Dropdown Menu.
class TashilDropdownMenuItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? supportingText;
  final bool isDivider;

  const TashilDropdownMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.supportingText,
    this.isDivider = false,
  });

  /// Factory for creating an inline group divider in the menu
  const TashilDropdownMenuItem.divider({
    required this.value,
  })  : label = '',
        icon = null,
        supportingText = null,
        isDivider = true;
}

/// Official Material Design 3 Menu Item Component.
/// Adheres to https://m3.material.io/components/menus/specs
/// Features 48dp standard height, 12dp directional insets,
/// rounded selected pill container highlight, and trailing checkmark.
class TashilMenuItemWidget<T> extends StatefulWidget {
  final TashilDropdownMenuItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const TashilMenuItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TashilMenuItemWidget<T>> createState() => _TashilMenuItemWidgetState<T>();
}

class _TashilMenuItemWidgetState<T> extends State<TashilMenuItemWidget<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.item.isDivider) {
      return Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      );
    }

    final isSelected = widget.isSelected;

    // Background color: Selected pill container or hover state layer
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = colorScheme.secondaryContainer.withValues(alpha: 0.85);
    } else if (_isHovered) {
      backgroundColor = colorScheme.onSurface.withValues(alpha: 0.08);
    } else {
      backgroundColor = Colors.transparent;
    }

    final foregroundColor = isSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;

    final iconColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final hasSupportingText = widget.item.supportingText != null && widget.item.supportingText!.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: hasSupportingText ? 52 : 44,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsetsDirectional.only(start: 12, end: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Leading Semantic Icon (Optional)
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
              ],

              // Label & optional Supporting Text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: foregroundColor,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSupportingText) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.item.supportingText!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onSecondaryContainer.withValues(alpha: 0.8)
                              : colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing Checkmark for selected state (as in official M3 specs)
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
