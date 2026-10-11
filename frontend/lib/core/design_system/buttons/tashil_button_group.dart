import 'package:flutter/material.dart';

/// Item model for connected button groups.
class TashilConnectedButtonSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Widget? leading;
  final String? badge;
  final bool enabled;
  final Color? activeColor;
  final Color? activeForegroundColor;
  final Color? unselectedColor;
  final Color? unselectedForegroundColor;
  final BorderRadius? borderRadius;

  const TashilConnectedButtonSegment({
    required this.value,
    required this.label,
    this.icon,
    this.leading,
    this.badge,
    this.enabled = true,
    this.activeColor,
    this.activeForegroundColor,
    this.unselectedColor,
    this.unselectedForegroundColor,
    this.borderRadius,
  });
}

/// Type 6: Official Material Design 3 Standard Button Group component.
///
/// Lays out multiple standalone buttons (such as icon buttons, standard buttons,
/// or toggle buttons) in a consistent M3 row/wrap with unified spacing and alignment.
class TashilStandardButtonGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool wrap;
  final WrapAlignment wrapAlignment;

  const TashilStandardButtonGroup({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrap = false,
    this.wrapAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        alignment: wrapAlignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          children[i],
        ],
      ],
    );
  }
}

/// Type 7: Official Material Design 3 Expressive Connected Button Group component.
///
/// Replaces deprecated baseline SegmentedButtons according to M3 Expressive guidelines:
/// https://m3.material.io/components/button-groups/guidelines
///
/// Implements a continuous outer stadium capsule (surfaceContainerHigh) housing
/// concentric floating pill segments. The active segment elevates with subtle shadow,
/// primary/secondaryContainer contrast, and 220ms easeInOutCubic animation.
class TashilConnectedButtonGroup<T> extends StatelessWidget {
  final List<TashilConnectedButtonSegment<T>> segments;
  final T? selectedValue;
  final ValueChanged<T> onSelectionChanged;
  final double height;
  final BorderRadius? borderRadius;
  final bool isTonal;
  final Color? activeColor;
  final Color? activeForegroundColor;
  final bool isFullWidth;
  final bool showCheckmark;

  const TashilConnectedButtonGroup({
    super.key,
    required this.segments,
    this.selectedValue,
    required this.onSelectionChanged,
    this.height = 42.0,
    this.borderRadius,
    this.isTonal = false,
    this.activeColor,
    this.activeForegroundColor,
    this.isFullWidth = false,
    this.showCheckmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outerRadius = borderRadius ?? BorderRadius.circular(height / 2);

    final groupContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: 5.0),
          if (isFullWidth)
            Expanded(
              child: _ConnectedGroupSegmentItem<T>(
                segment: segments[i],
                isSelected: segments[i].value == selectedValue,
                onTap: () => onSelectionChanged(segments[i].value),
                height: height - 7.0,
                isTonal: isTonal,
                activeColor: activeColor,
                activeForegroundColor: activeForegroundColor,
                showCheckmark: showCheckmark,
                isFullWidth: true,
              ),
            )
          else
            _ConnectedGroupSegmentItem<T>(
              segment: segments[i],
              isSelected: segments[i].value == selectedValue,
              onTap: () => onSelectionChanged(segments[i].value),
              height: height - 7.0,
              isTonal: isTonal,
              activeColor: activeColor,
              activeForegroundColor: activeForegroundColor,
              showCheckmark: showCheckmark,
              isFullWidth: false,
            ),
        ],
      ],
    );

    return Container(
      height: height,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: isTonal
            ? colorScheme.surfaceContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: outerRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: isFullWidth
          ? groupContent
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: groupContent,
            ),
    );
  }
}

class _ConnectedGroupSegmentItem<T> extends StatefulWidget {
  final TashilConnectedButtonSegment<T> segment;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;
  final bool isTonal;
  final Color? activeColor;
  final Color? activeForegroundColor;
  final bool showCheckmark;
  final bool isFullWidth;

  const _ConnectedGroupSegmentItem({
    super.key,
    required this.segment,
    required this.isSelected,
    required this.onTap,
    required this.height,
    required this.isTonal,
    this.activeColor,
    this.activeForegroundColor,
    this.showCheckmark = false,
    this.isFullWidth = false,
  });

  @override
  State<_ConnectedGroupSegmentItem<T>> createState() => _ConnectedGroupSegmentItemState<T>();
}

class _ConnectedGroupSegmentItemState<T> extends State<_ConnectedGroupSegmentItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = widget.isSelected;
    final enabled = widget.segment.enabled;

    // Per Material Design 3 Button Groups specs: All segment pills morph into full stadium capsules
    // (height / 2) ensuring geometric symmetry between start, middle, and end pills.
    final innerRadius = widget.segment.borderRadius ??
        BorderRadius.circular(widget.height / 2);

    final segmentActiveColor = widget.segment.activeColor ?? widget.activeColor;
    final segmentActiveFg = widget.segment.activeForegroundColor ?? widget.activeForegroundColor;

    final Color selectedBg = segmentActiveColor ??
        (widget.isTonal ? colorScheme.secondaryContainer : colorScheme.primary);
    final Color selectedFg = segmentActiveFg ??
        (widget.isTonal ? colorScheme.onSecondaryContainer : colorScheme.onPrimary);

    final Color unselectedFg = enabled
        ? (widget.segment.unselectedForegroundColor ?? colorScheme.onSurfaceVariant)
        : colorScheme.onSurface.withValues(alpha: 0.38);

    // Primary-derived or segment-derived hover tone for unselected segment
    final Color hoverBaseColor = segmentActiveColor ?? colorScheme.primary;

    // Resting state: noticeable light shading ("تظليل خفيف") with subtle outline so every unselected button is clearly visible as an independent button
    final Color restingUnselectedBg = widget.segment.unselectedColor ??
        (widget.isTonal
            ? colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.60 : 0.70)
            : colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.70 : 0.85));

    // Hover state: visibly darker/richer shade ("الهافر أغمق") derived from the primary/active color
    final Color hoveredUnselectedBg = widget.segment.unselectedColor != null
        ? Color.alphaBlend(
            hoverBaseColor.withValues(alpha: isDark ? 0.28 : 0.18),
            widget.segment.unselectedColor!,
          )
        : Color.alphaBlend(
            hoverBaseColor.withValues(alpha: isDark ? 0.26 : 0.16),
            colorScheme.surfaceContainerHighest,
          );

    final Color unselectedBg = _isHovered && enabled ? hoveredUnselectedBg : restingUnselectedBg;

    // For active/selected segment on hover:
    // Generate slightly darker tone derived directly from the active color ("اللون الغامق سيكة ده أو غامق شوية من اللون الأساسي")
    final Color hoveredSelectedBg = isDark
        ? (Color.lerp(selectedBg, Colors.white, 0.12) ?? selectedBg)
        : (Color.lerp(selectedBg, Colors.black, 0.10) ?? selectedBg);

    final Color currentBg = isSelected
        ? (_isHovered && enabled ? hoveredSelectedBg : selectedBg)
        : unselectedBg;
    final Color currentFg = isSelected ? selectedFg : unselectedFg;

    final Border? currentBorder = isSelected
        ? null
        : Border.all(
            color: (_isHovered && enabled)
                ? hoverBaseColor.withValues(alpha: isDark ? 0.55 : 0.45)
                : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
            width: 1.0,
          );

    final List<BoxShadow> currentShadow = isSelected
        ? [
            BoxShadow(
              color: (_isHovered && enabled)
                  ? (segmentActiveColor ?? colorScheme.primary).withValues(alpha: isDark ? 0.35 : 0.22)
                  : (segmentActiveColor ?? colorScheme.primary).withValues(alpha: isDark ? 0.25 : 0.14),
              blurRadius: (_isHovered && enabled) ? 6.0 : 3.5,
              offset: const Offset(0, 1.5),
            ),
          ]
        : [
            BoxShadow(
              color: (_isHovered && enabled)
                  ? hoverBaseColor.withValues(alpha: isDark ? 0.22 : 0.10)
                  : colorScheme.shadow.withValues(alpha: isDark ? 0.12 : 0.05),
              blurRadius: (_isHovered && enabled) ? 4.5 : 2.5,
              offset: const Offset(0, 1.0),
            ),
          ];

    // Per M3 Button Groups specs: When selected and showCheckmark is true,
    // the checkmark appears and replaces the icon to maintain the Single-Icon rule.
    Widget? leadingWidget;
    if (isSelected && widget.showCheckmark) {
      leadingWidget = Icon(
        Icons.check_rounded,
        key: const ValueKey('m3_check_icon'),
        size: 16.0,
        color: currentFg,
      );
    } else if (widget.segment.leading != null) {
      leadingWidget = widget.segment.leading;
    } else if (widget.segment.icon != null) {
      leadingWidget = Icon(
        widget.segment.icon,
        key: ValueKey(widget.segment.icon),
        size: 16.0,
        color: currentFg,
      );
    }

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (mounted && enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted && enabled) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        height: widget.height,
        decoration: BoxDecoration(
          color: currentBg,
          borderRadius: innerRadius,
          border: currentBorder,
          boxShadow: currentShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onTap : null,
            borderRadius: innerRadius,
            splashColor: currentFg.withValues(alpha: 0.12),
            highlightColor: currentFg.withValues(alpha: 0.08),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isFullWidth ? 4.0 : 14.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingWidget != null) ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: leadingWidget,
                    ),
                    const SizedBox(width: 4.0),
                  ],
                  Flexible(
                    child: Text(
                      widget.segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: currentFg,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.2,
                        fontSize: widget.height <= 38.0 ? 11.5 : 12.0,
                      ),
                    ),
                  ),
                  if (widget.segment.badge != null) ...[
                    const SizedBox(width: 5.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? currentFg.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        widget.segment.badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: currentFg,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item model for connected icon button groups.
class TashilConnectedIconItem {
  final IconData? icon;
  final Widget? customWidget;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? activeColor;
  final Color? activeForegroundColor;
  final Color? iconColor;
  final double iconSize;
  final bool enabled;
  final BorderRadius? borderRadius;

  const TashilConnectedIconItem({
    this.icon,
    this.customWidget,
    this.tooltip,
    this.onTap,
    this.isSelected = false,
    this.activeColor,
    this.activeForegroundColor,
    this.iconColor,
    this.iconSize = 20.0,
    this.enabled = true,
    this.borderRadius,
  });
}

/// Official Material Design 3 Connected Icon Button Group component.
///
/// Houses a cohesive set of icon actions inside a continuous stadium capsule
/// (surfaceContainerHigh) according to official M3 Button Groups guidelines:
/// https://m3.material.io/components/button-groups/guidelines
class TashilConnectedIconButtonGroup extends StatelessWidget {
  final List<TashilConnectedIconItem> items;
  final double height;
  final BorderRadius? borderRadius;
  final bool isTonal;
  final Color? backgroundColor;
  final Color? borderColor;
  final double itemSpacing;

  const TashilConnectedIconButtonGroup({
    super.key,
    required this.items,
    this.height = 42.0,
    this.borderRadius,
    this.isTonal = false,
    this.backgroundColor,
    this.borderColor,
    this.itemSpacing = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outerRadius = borderRadius ?? BorderRadius.circular(height / 2);

    return Container(
      height: height,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isTonal
                ? colorScheme.surfaceContainer
                : colorScheme.surfaceContainerHigh),
        borderRadius: outerRadius,
        border: Border.all(
          color: borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: itemSpacing),
            _ConnectedIconSegmentItem(
              item: items[i],
              size: height - 7.0,
              isTonal: isTonal,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectedIconSegmentItem extends StatefulWidget {
  final TashilConnectedIconItem item;
  final double size;
  final bool isTonal;

  const _ConnectedIconSegmentItem({
    required this.item,
    required this.size,
    required this.isTonal,
  });

  @override
  State<_ConnectedIconSegmentItem> createState() => _ConnectedIconSegmentItemState();
}

class _ConnectedIconSegmentItemState extends State<_ConnectedIconSegmentItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;
    final isSelected = item.isSelected;
    final enabled = item.enabled;

    final innerRadius = item.borderRadius ?? BorderRadius.circular(widget.size / 2);

    final segmentActiveColor = item.activeColor;
    final segmentActiveFg = item.activeForegroundColor;

    final Color selectedBg = segmentActiveColor ??
        (widget.isTonal ? colorScheme.secondaryContainer : colorScheme.primary);
    final Color selectedFg = segmentActiveFg ??
        (widget.isTonal ? colorScheme.onSecondaryContainer : colorScheme.onPrimary);

    final Color unselectedFg = enabled
        ? (item.iconColor ?? colorScheme.onSurfaceVariant)
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final Color hoverBaseColor = segmentActiveColor ?? colorScheme.primary;
    final Color unselectedBg = _isHovered && enabled
        ? hoverBaseColor.withValues(alpha: isDark ? 0.16 : 0.10)
        : Colors.transparent;

    final Color hoveredSelectedBg = isDark
        ? (Color.lerp(selectedBg, Colors.white, 0.12) ?? selectedBg)
        : (Color.lerp(selectedBg, Colors.black, 0.10) ?? selectedBg);

    final Color currentBg = isSelected
        ? (_isHovered && enabled ? hoveredSelectedBg : selectedBg)
        : unselectedBg;
    final Color currentFg = isSelected ? selectedFg : unselectedFg;

    final List<BoxShadow>? currentShadow = isSelected
        ? [
            BoxShadow(
              color: (_isHovered && enabled)
                  ? (segmentActiveColor ?? colorScheme.primary).withValues(alpha: isDark ? 0.35 : 0.22)
                  : colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: (_isHovered && enabled) ? 6.0 : 4.0,
              offset: const Offset(0, 1.5),
            ),
          ]
        : null;

    Widget content;
    if (item.customWidget != null) {
      content = item.customWidget!;
    } else {
      content = Icon(
        item.icon,
        size: item.iconSize,
        color: currentFg,
      );
    }

    Widget interactiveContent;
    if (item.customWidget != null && item.onTap == null) {
      interactiveContent = Center(child: item.customWidget);
    } else {
      interactiveContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? item.onTap : null,
          borderRadius: innerRadius,
          splashColor: currentFg.withValues(alpha: 0.12),
          highlightColor: currentFg.withValues(alpha: 0.08),
          child: Center(child: content),
        ),
      );
    }

    Widget segmentWidget = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (mounted && enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted && enabled) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: currentBg,
          borderRadius: innerRadius,
          boxShadow: currentShadow,
        ),
        child: interactiveContent,
      ),
    );

    if (item.tooltip != null && item.tooltip!.isNotEmpty) {
      return Tooltip(
        message: item.tooltip!,
        child: segmentWidget,
      );
    }

    return segmentWidget;
  }
}

