import 'package:flutter/material.dart';

/// Official Material Design 3 (M3) Drawer Destination Item.
///
/// Implements Google Material Design 3 Navigation Drawer specifications:
/// - Container Shape: Full Stadium Pill (28dp corner radius).
/// - Container Height: 56.0dp.
/// - Container Margins: 12dp horizontal start & end margins.
/// - Leading Icon: 24dp (selected vs unselected icon).
/// - Typography: M3 `labelLarge` (FontWeight.w700 for active, FontWeight.w500 for inactive).
/// - State Layers:
///   * Enabled: Inactive transparent, Active `secondaryContainer` fill with `onSecondaryContainer`.
///   * Hovered: 8% overlay state layer on pointer hover.
///   * Focused: 10% focus state layer with clear accessibility indicator.
///   * Pressed: 10% pressed state layer and fluid splash ripple.
/// - Collapsed Rail Mode: Centers icon, preserves 56dp height and pill shape, shows tooltip.
///
/// References:
/// - https://m3.material.io/components/navigation-drawer/specs
/// - https://m3.material.io/components/navigation-drawer/guidelines
class TashilDrawerDestination extends StatefulWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;
  final String? badgeCount;
  final String? supportingText;
  final Widget? trailing;
  final bool isEnabled;

  const TashilDrawerDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCollapsed = false,
    this.badgeCount,
    this.supportingText,
    this.trailing,
    this.isEnabled = true,
  });

  @override
  State<TashilDrawerDestination> createState() => _TashilDrawerDestinationState();
}

class _TashilDrawerDestinationState extends State<TashilDrawerDestination> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // M3 Color Tokens
    final activeContainer = colorScheme.secondaryContainer;
    final activeContent = colorScheme.onSecondaryContainer;
    final inactiveContent = colorScheme.onSurfaceVariant;
    final inactiveHoverLayer = colorScheme.onSurface.withAlpha((255 * 0.08).round());
    final activeHoverLayer = activeContent.withAlpha((255 * 0.08).round());
    final focusLayer = (widget.isSelected ? activeContent : colorScheme.onSurface)
        .withAlpha((255 * 0.10).round());

    final isBold = widget.isSelected || _isHovered;
    final currentIcon = (isBold && widget.selectedIcon != null)
        ? widget.selectedIcon!
        : widget.icon;

    final contentColor = widget.isSelected
        ? activeContent
        : (_isHovered ? colorScheme.onSurface : inactiveContent);

    // Container decoration according to active selection + hover/focus state
    Color containerColor;
    if (widget.isSelected) {
      if (_isHovered) {
        containerColor = Color.alphaBlend(activeHoverLayer, activeContainer);
      } else if (_isFocused) {
        containerColor = Color.alphaBlend(focusLayer, activeContainer);
      } else {
        containerColor = activeContainer;
      }
    } else {
      if (_isHovered) {
        containerColor = inactiveHoverLayer;
      } else if (_isFocused) {
        containerColor = focusLayer;
      } else {
        containerColor = Colors.transparent;
      }
    }

    final pillBorderRadius = BorderRadius.circular(28.0);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOutCubic,
      height: 56.0,
      margin: EdgeInsetsDirectional.symmetric(
        horizontal: widget.isCollapsed ? 8.0 : 12.0,
        vertical: 2.0,
      ),
      padding: EdgeInsetsDirectional.only(
        start: widget.isCollapsed ? 0.0 : 16.0,
        end: widget.isCollapsed ? 0.0 : 24.0,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: pillBorderRadius,
        border: _isFocused
            ? Border.all(color: colorScheme.primary.withAlpha(160), width: 1.5)
            : null,
      ),
      child: widget.isCollapsed
          ? Center(
              child: Icon(
                currentIcon,
                size: 24.0,
                color: contentColor,
              ),
            )
          : Row(
              children: [
                // 1. Leading Icon (24dp)
                Icon(
                  currentIcon,
                  size: 24.0,
                  color: contentColor,
                ),
                const SizedBox(width: 12.0),

                // 2. Label & Optional Supporting Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
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
                      if (widget.supportingText != null) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          widget.supportingText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                            fontSize: 11.0,
                            color: widget.isSelected
                                ? activeContent.withAlpha(200)
                                : colorScheme.onSurfaceVariant.withAlpha(180),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 3. Trailing Badge / Counter or Custom Trailing
                if (widget.badgeCount != null) ...[
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
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
                ] else if (widget.trailing != null) ...[
                  const SizedBox(width: 8.0),
                  widget.trailing!,
                ],
              ],
            ),
    );

    // Interactive ink response (Hover, Focus, Pressed)
    Widget interactive = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isEnabled ? widget.onTap : null,
        borderRadius: pillBorderRadius,
        hoverColor: Colors.transparent, // Handled in container decoration
        focusColor: Colors.transparent, // Handled in container decoration
        splashColor: (widget.isSelected ? activeContent : colorScheme.primary)
            .withAlpha((255 * 0.12).round()),
        highlightColor: (widget.isSelected ? activeContent : colorScheme.onSurface)
            .withAlpha((255 * 0.08).round()),
        onHover: (hovered) {
          if (hovered != _isHovered) {
            setState(() => _isHovered = hovered);
          }
        },
        onFocusChange: (focused) {
          if (focused != _isFocused) {
            setState(() => _isFocused = focused);
          }
        },
        child: content,
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: widget.badgeCount != null
            ? '${widget.label} (${widget.badgeCount})'
            : widget.label,
        preferBelow: false,
        verticalOffset: 24,
        child: interactive,
      );
    }

    return interactive;
  }
}
