import 'package:flutter/material.dart';

/// Official Material Design 3 (M3) Dual-Mode Rail Destination Item.
///
/// Implements Google Material Design 3 Navigation Rail specifications:
/// - In Rail Mode (width 80dp):
///   * Active Indicator Pill: 56dp wide x 32dp high with 16dp corner radius.
///   * Leading Icon: 24dp centered inside the active indicator pill.
///   * Label Text: Situated directly below the indicator pill with 4dp gap (`labelMedium`).
///   * Badge: Positioned at top-trailing edge of icon (e.g. numeric "3" or status dot).
///   * State Layers: Enabled, Hovered (8%), Focused (10%), Pressed (10%).
/// - In Expanded Drawer Mode (width 260dp):
///   * Horizontal row pill (56dp height, 28dp radius, 12dp margins).
///   * Icon at start, Label beside icon (`labelLarge`), Badge at end.
///
/// References:
/// - https://m3.material.io/components/navigation-rail/overview
/// - https://m3.material.io/components/navigation-rail/specs
/// - https://m3.material.io/components/navigation-rail/guidelines
class TashilRailDestination extends StatefulWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? compactLabel;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isExpanded;
  final String? badgeCount;
  final bool hasBadgeDot;
  final Widget? trailing;
  final bool isEnabled;

  const TashilRailDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.compactLabel,
    required this.isSelected,
    required this.onTap,
    this.isExpanded = false,
    this.badgeCount,
    this.hasBadgeDot = false,
    this.trailing,
    this.isEnabled = true,
  });

  @override
  State<TashilRailDestination> createState() => _TashilRailDestinationState();
}

class _TashilRailDestinationState extends State<TashilRailDestination> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeContainer = colorScheme.secondaryContainer;
    final activeContent = colorScheme.onSecondaryContainer;
    final inactiveContent = colorScheme.onSurfaceVariant;
    final activeHoverLayer = activeContent.withAlpha((255 * 0.08).round());
    final inactiveHoverLayer = colorScheme.onSurface.withAlpha((255 * 0.08).round());
    final focusLayer = (widget.isSelected ? activeContent : colorScheme.onSurface)
        .withAlpha((255 * 0.10).round());

    final isBold = widget.isSelected || _isHovered;
    final currentIcon = (isBold && widget.selectedIcon != null)
        ? widget.selectedIcon!
        : widget.icon;

    final contentColor = widget.isSelected
        ? activeContent
        : (_isHovered ? colorScheme.onSurface : inactiveContent);

    // Build icon with optional top-end badge
    Widget iconWidget = Icon(
      currentIcon,
      size: 24.0,
      color: contentColor,
    );

    // Build icon with optional top-end badge (Only in collapsed Rail mode; in expanded mode, counter is cleanly displayed at the trailing end of the row)
    if (!widget.isExpanded && (widget.badgeCount != null || widget.hasBadgeDot)) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          iconWidget,
          PositionedDirectional(
            top: -3.0,
            end: -6.0,
            child: widget.hasBadgeDot && widget.badgeCount == null
                ? Container(
                    width: 7.0,
                    height: 7.0,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 16.0, minHeight: 16.0),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.badgeCount ?? '',
                      style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onError,
                        height: 1.1,
                      ),
                    ),
                  ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showExpanded = widget.isExpanded && constraints.maxWidth >= 140.0;

        if (!showExpanded) {
          // -------------------------------------------------------------
          // 1. Navigation Rail Mode (80dp Width, Vertical Icon Over Label)
          // -------------------------------------------------------------
          Color indicatorColor;
          if (widget.isSelected) {
            if (_isHovered) {
              indicatorColor = Color.alphaBlend(activeHoverLayer, activeContainer);
            } else if (_isFocused) {
              indicatorColor = Color.alphaBlend(focusLayer, activeContainer);
            } else {
              indicatorColor = activeContainer;
            }
          } else {
            if (_isHovered) {
              indicatorColor = inactiveHoverLayer;
            } else if (_isFocused) {
              indicatorColor = focusLayer;
            } else {
              indicatorColor = Colors.transparent;
            }
          }

          final pillRadius = BorderRadius.circular(16.0);

          final railItem = Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: InkWell(
              onTap: widget.isEnabled ? widget.onTap : null,
              borderRadius: BorderRadius.circular(20.0),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              splashColor: (widget.isSelected ? activeContent : colorScheme.primary)
                  .withAlpha((255 * 0.12).round()),
              onHover: (h) => setState(() => _isHovered = h),
              onFocusChange: (f) => setState(() => _isFocused = f),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // M3 Active Indicator Pill: 56dp wide x 32dp high
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOutCubic,
                    width: 56.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: pillRadius,
                      border: _isFocused
                          ? Border.all(color: colorScheme.primary.withAlpha(160), width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: iconWidget,
                  ),
                  const SizedBox(height: 4.0),
                  // Label Text Situated Directly Below the Icon
                  SizedBox(
                    width: 76.0,
                    child: Text(
                      widget.compactLabel ?? widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                        fontSize: 12.0,
                        fontWeight: (widget.isSelected || _isHovered) ? FontWeight.bold : FontWeight.w500,
                        color: widget.isSelected ? colorScheme.onSurface : (_isHovered ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return Tooltip(
            message: widget.badgeCount != null
                ? '${widget.label} (${widget.badgeCount})'
                : widget.label,
            preferBelow: false,
            verticalOffset: 24.0,
            child: railItem,
          );
        }

        // -------------------------------------------------------------
        // 2. Expanded Drawer Mode (260dp Width, Horizontal Icon + Label)
        // -------------------------------------------------------------
        Color drawerContainerColor;
        if (widget.isSelected) {
          if (_isHovered) {
            drawerContainerColor = Color.alphaBlend(activeHoverLayer, activeContainer);
          } else if (_isFocused) {
            drawerContainerColor = Color.alphaBlend(focusLayer, activeContainer);
          } else {
            drawerContainerColor = activeContainer;
          }
        } else {
          if (_isHovered) {
            drawerContainerColor = inactiveHoverLayer;
          } else if (_isFocused) {
            drawerContainerColor = focusLayer;
          } else {
            drawerContainerColor = Colors.transparent;
          }
        }

        final drawerPillRadius = BorderRadius.circular(28.0);

        return Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12.0, vertical: 2.0),
            child: InkWell(
              onTap: widget.isEnabled ? widget.onTap : null,
              borderRadius: drawerPillRadius,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              splashColor: (widget.isSelected ? activeContent : colorScheme.primary)
                  .withAlpha((255 * 0.12).round()),
              onHover: (h) => setState(() => _isHovered = h),
              onFocusChange: (f) => setState(() => _isFocused = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOutCubic,
                height: 56.0,
                padding: const EdgeInsetsDirectional.only(start: 16.0, end: 20.0),
                decoration: BoxDecoration(
                  color: drawerContainerColor,
                  borderRadius: drawerPillRadius,
                  border: _isFocused
                      ? Border.all(color: colorScheme.primary.withAlpha(160), width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                          fontSize: 14.0,
                          fontWeight: (widget.isSelected || _isHovered) ? FontWeight.bold : FontWeight.w500,
                          color: contentColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (widget.badgeCount != null) ...[
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? colorScheme.primary.withAlpha(25)
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          widget.badgeCount!,
                          style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: contentColor,
                          ),
                        ),
                      ),
                    ] else if (widget.hasBadgeDot) ...[
                      const SizedBox(width: 8.0),
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ] else if (widget.trailing != null) ...[
                      const SizedBox(width: 8.0),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
