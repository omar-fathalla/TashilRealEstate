import 'package:flutter/material.dart';

/// Official Material Design 3 (M3) Input Chip component for Tashil Real Estate.
///
/// Implements Google Material Design 3 Input Chip specification:
/// - Container height: 32dp
/// - Corner radius: 8dp (M3 shape.corner.small)
/// - Optional leading icon or avatar: 18dp
/// - Trailing remove/delete icon button: 18dp (Icons.close_rounded)
/// - Represents discrete user entries, filters, or selected tags
/// - Native RTL/LTR directionality support
///
/// Reference: https://m3.material.io/components/chips/overview
class TashilInputChip extends StatefulWidget {
  final String label;
  final VoidCallback? onDeleted;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? avatar;
  final bool isSelected;
  final String? deleteTooltip;
  final double height;
  final double borderRadius;

  const TashilInputChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.onPressed,
    this.icon,
    this.avatar,
    this.isSelected = false,
    this.deleteTooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
  });

  @override
  State<TashilInputChip> createState() => _TashilInputChipState();
}

class _TashilInputChipState extends State<TashilInputChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bg = widget.isSelected
        ? colorScheme.secondaryContainer
        : (_isHovered ? colorScheme.onSurface.withValues(alpha: 0.04) : Colors.transparent);
    final Color fg = widget.isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface;
    final Color border = widget.isSelected ? Colors.transparent : colorScheme.outlineVariant;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      side: border != Colors.transparent ? BorderSide(color: border, width: 1.0) : BorderSide.none,
    );

    final hasLeading = widget.avatar != null || widget.icon != null;

    return Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onPressed,
        onHover: (hovered) {
          if (mounted) setState(() => _isHovered = hovered);
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
        child: Container(
          height: widget.height,
          padding: EdgeInsetsDirectional.only(
            start: hasLeading ? 8.0 : 12.0,
            end: widget.onDeleted != null ? 4.0 : 12.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading Avatar / Icon
              if (widget.avatar != null) ...[
                widget.avatar!,
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 18.0, color: fg),
                const SizedBox(width: 8),
              ],

              // Label Text
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontSize: 13.0,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Trailing Delete Action Button
              if (widget.onDeleted != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: widget.deleteTooltip ?? 'حذف',
                  child: InkResponse(
                    onTap: widget.onDeleted,
                    radius: 12,
                    hoverColor: colorScheme.error.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.0,
                        color: fg.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
