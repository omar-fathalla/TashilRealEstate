import 'package:flutter/material.dart';

/// Official Material Design 3 (M3) Filter Chip component for Tashil Real Estate.
///
/// Implements Google Material Design 3 Filter Chip specification:
/// - Container height: 32dp
/// - Corner radius: 8dp (M3 shape.corner.small)
/// - Leading checkmark icon: 18dp when selected
/// - Smooth animated transition between unselected and selected states
/// - Variants: Outlined (standard) and Elevated
/// - Native RTL/LTR directionality support
///
/// Reference: https://m3.material.io/components/chips/overview
class TashilFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final Widget? avatar;
  final bool isElevated;
  final Color? selectedBackgroundColor;
  final Color? selectedForegroundColor;
  final String? tooltip;
  final double height;
  final double borderRadius;

  const TashilFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.avatar,
    this.isElevated = false,
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
  });

  /// M3 Elevated Filter Chip
  const TashilFilterChip.elevated({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.avatar,
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
  }) : isElevated = true;

  @override
  State<TashilFilterChip> createState() => _TashilFilterChipState();
}

class _TashilFilterChipState extends State<TashilFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = widget.onSelected != null;

    final Color bg;
    final Color fg;
    final Color border;
    final double elevation;

    if (widget.selected) {
      bg = widget.selectedBackgroundColor ?? colorScheme.secondaryContainer;
      fg = widget.selectedForegroundColor ?? colorScheme.onSecondaryContainer;
      border = Colors.transparent;
      elevation = widget.isElevated ? (_isHovered ? 2.0 : 1.0) : 0.0;
    } else {
      bg = widget.isElevated
          ? colorScheme.surfaceContainerLow
          : (_isHovered ? colorScheme.onSurface.withValues(alpha: 0.04) : Colors.transparent);
      fg = colorScheme.onSurface;
      border = widget.isElevated ? Colors.transparent : colorScheme.outlineVariant;
      elevation = widget.isElevated ? (_isHovered ? 2.0 : 1.0) : 0.0;
    }

    final effectiveFg = isEnabled ? fg : colorScheme.onSurface.withValues(alpha: 0.38);
    final effectiveBg = isEnabled ? bg : colorScheme.onSurface.withValues(alpha: 0.12);
    final effectiveBorder = isEnabled ? border : colorScheme.outlineVariant.withValues(alpha: 0.5);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      side: border != Colors.transparent
          ? BorderSide(color: effectiveBorder, width: 1.0)
          : BorderSide.none,
    );

    Widget chipContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Material(
        color: effectiveBg,
        shape: shape,
        elevation: elevation,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? () => widget.onSelected!(!widget.selected) : null,
          onHover: (hovered) {
            if (mounted && isEnabled) setState(() => _isHovered = hovered);
          },
          borderRadius: BorderRadius.circular(widget.borderRadius),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Container(
            height: widget.height,
            padding: const EdgeInsetsDirectional.only(start: 8.0, end: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Leading Icon / Checkmark
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: widget.selected
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey('checked'),
                          size: 18.0,
                          color: effectiveFg,
                        )
                      : (widget.avatar ??
                          (widget.icon != null
                              ? Icon(
                                  widget.icon,
                                  key: const ValueKey('icon'),
                                  size: 18.0,
                                  color: effectiveFg,
                                )
                              : const SizedBox.shrink())),
                ),
                if (widget.selected || widget.avatar != null || widget.icon != null)
                  const SizedBox(width: 8),

                // Label Text
                Flexible(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: effectiveFg,
                      fontSize: 13.0,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      chipContent = Tooltip(
        message: widget.tooltip!,
        child: chipContent,
      );
    }

    return chipContent;
  }
}
