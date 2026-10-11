import 'package:flutter/material.dart';

/// Item model for TashilSplitButton dropdown options.
class TashilSplitButtonItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool enabled;

  const TashilSplitButtonItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });
}

/// Variant styles for TashilSplitButton conforming to M3 Expressive.
enum TashilSplitButtonStyle {
  filled,
  tonal,
  elevated,
  outlined,
}

/// Type 5: Official Material Design 3 Expressive Split Button component.
///
/// Conforms to official Google M3 Expressive guidelines (May 2024 update):
/// https://m3.material.io/components/split-button/overview
///
/// - Dual segment geometry: Leading common action button + Trailing menu icon button.
/// - Asymmetrical stadium ends on outer edges and 6dp squircle on inner edges.
/// - Smooth 250ms cubic animated chevron rotation (0 to 180°).
/// - 4 Color Styles: Filled, Tonal, Elevated, Outlined.
/// - 100% Directionality Awareness (RTL for Arabic, LTR for English/Hindi).
class TashilSplitButton<T> extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final List<TashilSplitButtonItem<T>> items;
  final ValueChanged<T>? onItemSelected;
  final T? selectedValue;
  final double height;
  final TashilSplitButtonStyle style;
  final Color? customColor;
  final String? tooltip;

  const TashilSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    required this.items,
    this.onItemSelected,
    this.selectedValue,
    this.height = 44.0,
    this.style = TashilSplitButtonStyle.filled,
    this.customColor,
    this.tooltip,
  });

  const TashilSplitButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    required this.items,
    this.onItemSelected,
    this.selectedValue,
    this.height = 44.0,
    this.customColor,
    this.tooltip,
  })  : style = TashilSplitButtonStyle.tonal;

  const TashilSplitButton.elevated({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    required this.items,
    this.onItemSelected,
    this.selectedValue,
    this.height = 44.0,
    this.customColor,
    this.tooltip,
  })  : style = TashilSplitButtonStyle.elevated;

  const TashilSplitButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    required this.items,
    this.onItemSelected,
    this.selectedValue,
    this.height = 44.0,
    this.customColor,
    this.tooltip,
  })  : style = TashilSplitButtonStyle.outlined;

  @override
  State<TashilSplitButton<T>> createState() => _TashilSplitButtonState<T>();
}

class _TashilSplitButtonState<T> extends State<TashilSplitButton<T>> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final outerRadius = widget.height / 2;
    const innerRadius = 6.0;

    // Color tokens based on M3 Expressive style
    Color bg;
    Color fg;
    Color? borderColor;
    List<BoxShadow>? shadows;

    switch (widget.style) {
      case TashilSplitButtonStyle.filled:
        bg = widget.customColor ?? colorScheme.primary;
        fg = colorScheme.onPrimary;
        borderColor = null;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case TashilSplitButtonStyle.tonal:
        bg = widget.customColor ?? colorScheme.secondaryContainer;
        fg = colorScheme.onSecondaryContainer;
        borderColor = null;
        shadows = null;
        break;
      case TashilSplitButtonStyle.elevated:
        bg = widget.customColor ?? colorScheme.surfaceContainerHigh;
        fg = colorScheme.primary;
        borderColor = colorScheme.outlineVariant.withValues(alpha: 0.2);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
        break;
      case TashilSplitButtonStyle.outlined:
        bg = Colors.transparent;
        fg = widget.customColor ?? colorScheme.primary;
        borderColor = colorScheme.outlineVariant;
        shadows = null;
        break;
    }

    // Directional border radius for Primary Action Button
    final primaryBorderRadius = BorderRadiusDirectional.only(
      topStart: Radius.circular(outerRadius),
      bottomStart: Radius.circular(outerRadius),
      topEnd: const Radius.circular(innerRadius),
      bottomEnd: const Radius.circular(innerRadius),
    ).resolve(Directionality.of(context));

    // Directional border radius for Trailing Menu Icon Button
    final menuBorderRadius = _isMenuOpen
        ? BorderRadius.circular(outerRadius)
        : BorderRadiusDirectional.only(
            topStart: const Radius.circular(innerRadius),
            bottomStart: const Radius.circular(innerRadius),
            topEnd: Radius.circular(outerRadius),
            bottomEnd: Radius.circular(outerRadius),
          ).resolve(Directionality.of(context));

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Primary Action Button
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: primaryBorderRadius,
              border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: primaryBorderRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: fg,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Animated Separation Gap (expands to 8dp on open per M3 Expressive spec)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: _isMenuOpen ? 8.0 : 2.5,
          ),

          // 3. Trailing Menu Icon Button with Animated Rotating Chevron & Circle Morphing
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: widget.height,
            height: widget.height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: menuBorderRadius,
              border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: Theme(
                data: theme.copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    color: colorScheme.surfaceContainerHigh,
                    elevation: 6,
                    surfaceTintColor: Colors.transparent,
                  ),
                ),
                child: PopupMenuButton<T>(
                  tooltip: widget.tooltip ?? 'خيارات البحث / Search options',
                  enabled: widget.items.isNotEmpty,
                  borderRadius: _isMenuOpen ? BorderRadius.circular(outerRadius) : menuBorderRadius,
                  offset: const Offset(0, 48),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
                  onOpened: () => setState(() => _isMenuOpen = true),
                  onCanceled: () => setState(() => _isMenuOpen = false),
                  onSelected: (val) {
                    setState(() => _isMenuOpen = false);
                    widget.onItemSelected?.call(val);
                  },
                  icon: AnimatedRotation(
                    turns: _isMenuOpen ? 0.5 : 0.0, // Smooth 180° rotation
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: fg,
                    ),
                  ),
                  itemBuilder: (context) {
                    return widget.items.map((item) {
                      final isSelected = widget.selectedValue != null && widget.selectedValue == item.value;
                      return PopupMenuItem<T>(
                        value: item.value,
                        enabled: item.enabled,
                        height: item.subtitle != null ? 56 : 46,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: Row(
                            children: [
                              if (item.icon != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 16,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                      ),
                                    ),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

