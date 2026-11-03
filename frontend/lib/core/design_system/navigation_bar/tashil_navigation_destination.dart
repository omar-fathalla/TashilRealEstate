import 'package:flutter/material.dart';
import 'tashil_badge.dart';

/// Official Material Design 3 (M3) Navigation Destination Item.
///
/// Implements Google Material Design 3 specifications:
/// - Active Indicator Pill: 64dp wide x 32dp high with 16dp corner radius.
/// - Container color: [ColorScheme.secondaryContainer].
/// - Icon color: [ColorScheme.onSecondaryContainer] when active, [ColorScheme.onSurfaceVariant] when inactive.
/// - Label: 12dp ([TextTheme.labelMedium]) directly below indicator with 4dp gap.
/// - Interactive state layers: Hovered (8%), Focused (10%), Pressed (10%).
/// - Badge: Anchored at upper-trailing edge of icon bounding box.
///
/// References:
/// - https://m3.material.io/components/navigation-bar/overview
/// - https://m3.material.io/components/navigation-bar/specs
class TashilNavigationDestination extends StatefulWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeLabel;
  final bool hasBadgeDot;
  final Color? badgeColor;
  final String? tooltip;
  final bool isEnabled;

  const TashilNavigationDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeLabel,
    this.hasBadgeDot = false,
    this.badgeColor,
    this.tooltip,
    this.isEnabled = true,
  });

  @override
  State<TashilNavigationDestination> createState() =>
      _TashilNavigationDestinationState();
}

class _TashilNavigationDestinationState
    extends State<TashilNavigationDestination> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeContainer = colorScheme.secondaryContainer;
    final activeIconColor = colorScheme.onSecondaryContainer;
    final inactiveIconColor = colorScheme.onSurfaceVariant;
    final activeTextColor = colorScheme.onSurface;
    final inactiveTextColor = colorScheme.onSurfaceVariant;

    final currentIcon = (widget.isSelected && widget.selectedIcon != null)
        ? widget.selectedIcon!
        : widget.icon;

    final iconColor = widget.isSelected
        ? activeIconColor
        : (_isHovered ? colorScheme.onSurface : inactiveIconColor);

    // Build icon with optional badge
    Widget iconWidget = Icon(
      currentIcon,
      size: 24.0,
      color: iconColor,
    );

    if (widget.badgeLabel != null || widget.hasBadgeDot) {
      iconWidget = TashilBadge(
        label: widget.badgeLabel,
        hasDot: widget.hasBadgeDot && widget.badgeLabel == null,
        backgroundColor: widget.badgeColor ?? colorScheme.primary,
        textColor: colorScheme.onPrimary,
        child: iconWidget,
      );
    }

    final destinationWidget = FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowHoverHighlight: (val) => setState(() => _isHovered = val),
      onShowFocusHighlight: (val) => setState(() => _isFocused = val),
      mouseCursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Semantics(
        selected: widget.isSelected,
        button: true,
        label: widget.label,
        child: InkWell(
          onTap: widget.isEnabled ? widget.onTap : null,
          splashColor: activeContainer.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. M3 Active Indicator Pill (64 x 32 dp)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                width: 64.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? activeContainer
                      : (_isHovered
                          ? colorScheme.onSurface.withValues(alpha: 0.08)
                          : (_isFocused
                              ? colorScheme.onSurface.withValues(alpha: 0.12)
                              : Colors.transparent)),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),

              const SizedBox(height: 4.0),

              // 2. Label Text (M3 labelMedium, 12dp)
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  color: widget.isSelected ? activeTextColor : inactiveTextColor),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        child: destinationWidget,
      );
    }

    return destinationWidget;
  }
}
