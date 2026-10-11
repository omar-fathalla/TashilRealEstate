import 'package:flutter/material.dart';

/// Material Design 3 Chip Visual Variants.
enum TashilChipVariant {
  outlined,
  elevated,
  tonal,
  filled,
}

/// Official Material Design 3 (M3) Assist Chip component for Tashil Real Estate.
///
/// Implements Google Material Design 3 Assist Chip specification:
/// - Container height: 32dp
/// - Corner radius: 8dp (M3 shape.corner.small)
/// - Leading icon: 18dp
/// - Typography: M3 labelLarge (14sp, w500)
/// - Padding: start 8dp with icon / 16dp without, end 12dp
/// - Variants: Outlined (1px outlineVariant), Elevated (1dp elevation on surfaceContainerLow), Tonal (primary/secondary container)
/// - Directionality: Native RTL/LTR support using [EdgeInsetsDirectional]
///
/// Reference: https://m3.material.io/components/chips/overview
class TashilAssistChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final TashilChipVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? elevation;
  final double? hoverElevation;
  final bool isSelected;
  final bool isLoading;
  final String? tooltip;
  final double height;
  final double borderRadius;
  final bool enabled;

  const TashilAssistChip({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.onPressed,
    this.variant = TashilChipVariant.outlined,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.elevation,
    this.hoverElevation,
    this.isSelected = false,
    this.isLoading = false,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
    this.enabled = true,
  });

  /// M3 Outlined Assist Chip (Standard crisp outline)
  const TashilAssistChip.outlined({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.isSelected = false,
    this.isLoading = false,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
    this.enabled = true,
  })  : variant = TashilChipVariant.outlined,
        elevation = 0,
        hoverElevation = 1.0;

  /// M3 Elevated Assist Chip (Surface container with gentle 1dp shadow)
  const TashilAssistChip.elevated({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.isSelected = false,
    this.isLoading = false,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
    this.enabled = true,
  })  : variant = TashilChipVariant.elevated,
        elevation = 1.0,
        hoverElevation = 2.0;

  /// M3 Tonal Assist Chip (Container fill with subtle contrast)
  const TashilAssistChip.tonal({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.isSelected = false,
    this.isLoading = false,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
    this.enabled = true,
  })  : variant = TashilChipVariant.tonal,
        elevation = 0,
        hoverElevation = 1.0;

  @override
  State<TashilAssistChip> createState() => _TashilAssistChipState();
}

class _TashilAssistChipState extends State<TashilAssistChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInteractive = widget.onPressed != null && !widget.isLoading;
    final isEnabled = widget.enabled && !widget.isLoading;

    // Resolve Colors according to M3 Token specifications
    final Color bg;
    final Color fg;
    final Color border;
    double currentElevation = 0;

    switch (widget.variant) {
      case TashilChipVariant.elevated:
        bg = widget.backgroundColor ??
            (widget.isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow);
        fg = widget.foregroundColor ??
            (widget.isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface);
        border = widget.borderColor ?? Colors.transparent;
        currentElevation = _isHovered ? (widget.hoverElevation ?? 2.0) : (widget.elevation ?? 1.0);
        break;

      case TashilChipVariant.tonal:
        bg = widget.backgroundColor ??
            (widget.isSelected ? colorScheme.primaryContainer : colorScheme.secondaryContainer.withValues(alpha: 0.7));
        fg = widget.foregroundColor ??
            (widget.isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer);
        border = widget.borderColor ?? Colors.transparent;
        currentElevation = _isHovered ? 1.0 : 0.0;
        break;

      case TashilChipVariant.filled:
        bg = widget.backgroundColor ??
            (widget.isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest);
        fg = widget.foregroundColor ??
            (widget.isSelected ? colorScheme.onPrimary : colorScheme.onSurface);
        border = widget.borderColor ?? Colors.transparent;
        currentElevation = _isHovered ? 1.0 : 0.0;
        break;

      case TashilChipVariant.outlined:
        if (widget.isSelected) {
          bg = widget.backgroundColor ?? colorScheme.primaryContainer;
          fg = widget.foregroundColor ?? colorScheme.onPrimaryContainer;
          border = widget.borderColor ?? colorScheme.primary;
        } else {
          bg = widget.backgroundColor ??
              (_isHovered ? colorScheme.onSurface.withValues(alpha: 0.04) : Colors.transparent);
          fg = widget.foregroundColor ?? colorScheme.onSurface;
          border = widget.borderColor ?? colorScheme.outlineVariant;
        }
        currentElevation = 0;
        break;
    }

    final effectiveFg = isEnabled ? fg : colorScheme.onSurface.withValues(alpha: 0.38);
    final effectiveBg = isEnabled ? bg : colorScheme.onSurface.withValues(alpha: 0.12);
    final effectiveBorder = isEnabled ? border : colorScheme.outlineVariant.withValues(alpha: 0.5);

    final hasLeading = widget.isLoading || widget.leading != null || widget.icon != null;
    final hasTrailing = widget.trailing != null;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      side: border != Colors.transparent
          ? BorderSide(color: effectiveBorder, width: 1.0)
          : BorderSide.none,
    );

    Widget chipContent = Material(
      color: effectiveBg,
      shape: shape,
      elevation: currentElevation,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isInteractive ? widget.onPressed : null,
        onHover: (hovered) {
          if (mounted && isInteractive) setState(() => _isHovered = hovered);
        },
        borderRadius: BorderRadius.circular(widget.borderRadius),
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        child: Container(
          height: widget.height,
          padding: EdgeInsetsDirectional.only(
            start: hasLeading ? 8.0 : 10.0,
            end: hasTrailing ? 8.0 : 10.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading Icon / Loader / Widget
              if (widget.isLoading) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                  ),
                ),
                const SizedBox(width: 6),
              ] else if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 6),
              ] else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16.0,
                  color: effectiveFg,
                ),
                const SizedBox(width: 6),
              ],

              // Label Text (M3 labelLarge typography)
              Flexible(
                child: Text(
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: effectiveFg,
                    fontSize: 12.0,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Trailing Widget
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
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
