import 'package:flutter/material.dart';
import '../motion/tashil_motion.dart';

/// Enumeration of Material Design 3 Card visual variants.
enum TashilCardVariant {
  elevated,
  filled,
  outlined,
}

/// Item model for the 3-dots action menu on TashilCard.
class TashilCardMenuItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const TashilCardMenuItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Official Material Design 3 Card component for Tashil Real Estate.
///
/// Implements the 3 official Google M3 Card specifications:
/// 1. [TashilCardVariant.elevated]: Surface container with gentle tonal shadow elevation.
/// 2. [TashilCardVariant.filled]: Subtle tonal surface fill without borders.
/// 3. [TashilCardVariant.outlined]: Crisp surface container with a 1px outlineVariant border.
class TashilCard extends StatefulWidget {
  final Widget child;
  final TashilCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final Color? color;
  final double? elevation;
  final double? hoverElevation;
  final bool enableHoverAnimation;
  final Clip clipBehavior;
  final List<TashilCardMenuItem>? menuItems;
  final ValueChanged? onMenuItemSelected;
  final bool enabled;
  final bool isDragged;
  final bool? isFocused;
  final bool? isHovered;
  final FocusNode? focusNode;

  const TashilCard({
    super.key,
    required this.child,
    this.variant = TashilCardVariant.outlined,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.color,
    this.elevation,
    this.hoverElevation,
    this.enableHoverAnimation = false,
    this.clipBehavior = Clip.antiAlias,
    this.menuItems,
    this.onMenuItemSelected,
    this.enabled = true,
    this.isDragged = false,
    this.isFocused,
    this.isHovered,
    this.focusNode,
  });

  /// Type 1: M3 Elevated Card
  /// Implements Google Material Design 3 Elevated Card specifications:
  /// - Resting: Level 1 elevation (1dp), surfaceContainerLow
  /// - Hovered: Level 2 elevation (3dp), 8% onSurface state layer
  /// - Focused: Level 1 elevation (1dp), 10% onSurface state layer, 3dp focus outline
  /// - Pressed: Level 1 elevation (1dp), 10% onSurface state layer ripple
  /// - Dragged: Level 4 elevation (8dp), 16% onSurface state layer, lift shadow
  /// - Disabled: Level 0 elevation (0dp), 38% muted content opacity
  const TashilCard.elevated({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.color,
    this.elevation = 1.0,
    this.hoverElevation = 3.0,
    this.enableHoverAnimation = false,
    this.clipBehavior = Clip.antiAlias,
    this.menuItems,
    this.onMenuItemSelected,
    this.enabled = true,
    this.isDragged = false,
    this.isFocused,
    this.isHovered,
    this.focusNode,
  }) : variant = TashilCardVariant.elevated;

  /// Type 2: M3 Filled Card
  const TashilCard.filled({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.color,
    this.hoverElevation = 2.0,
    this.enableHoverAnimation = false,
    this.clipBehavior = Clip.antiAlias,
    this.menuItems,
    this.onMenuItemSelected,
    this.enabled = true,
    this.isDragged = false,
    this.isFocused,
    this.isHovered,
    this.focusNode,
  })  : variant = TashilCardVariant.filled,
        elevation = 0;

  /// Type 3: M3 Outlined Card
  /// Implements Google Material Design 3 Outlined Card interactive states:
  /// - Resting: Level 0 elevation (0dp), 1dp outlineVariant border
  /// - Hovered: Level 1 elevation (1dp), 8% onSurface state layer, subtle lift
  /// - Focused: Level 0 elevation (0dp), 10% onSurface state layer, 3dp secondary focus outline ring
  /// - Pressed: Level 0 elevation (0dp), 10% onSurface ripple
  /// - Dragged: Level 4 elevation (8dp), 16% onSurface state layer, lift shadow
  /// - Disabled: Level 0 elevation (0dp), 38% muted content opacity, muted border
  const TashilCard.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.color,
    this.hoverElevation = 1.0,
    this.enableHoverAnimation = true,
    this.clipBehavior = Clip.antiAlias,
    this.menuItems,
    this.onMenuItemSelected,
    this.enabled = true,
    this.isDragged = false,
    this.isFocused,
    this.isHovered,
    this.focusNode,
  })  : variant = TashilCardVariant.outlined,
        elevation = 0;

  @override
  State<TashilCard> createState() => _TashilCardState();
}

class _TashilCardState extends State<TashilCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Official Google M3 Card Shape: 12dp corner radius
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    final bool isEffectivelyDisabled = !widget.enabled;
    final bool isEffectivelyDragged = widget.enabled && widget.isDragged;
    final bool isHoveredState = widget.isHovered ?? _isHovered;
    final bool isFocusedState = widget.isFocused ?? _isFocused;
    final bool isEffectivelyHovered = widget.enabled && isHoveredState && !_isPressed && !isEffectivelyDragged;
    final bool isEffectivelyFocused = widget.enabled && isFocusedState && !_isPressed && !isEffectivelyDragged;
    final bool isEffectivelyPressed = widget.enabled && _isPressed;

    // Determine state layer color & opacity per Google Material Design 3 Interaction States:
    // Hovered: 8% (0.08), Focused: 10% (0.10), Pressed: 10% (0.10), Dragged: 16% (0.16)
    // When hovering, the state layer is derived directly from the primary seed color of the active theme
    // (e.g. Warm Terracotta brown, Forest Olive green, Ocean Blue, etc.) giving a cohesive, slightly darker tone.
    double stateLayerOpacity = 0.0;
    Color stateLayerColor = colorScheme.onSurface;

    if (isEffectivelyDragged) {
      stateLayerOpacity = 0.16;
      stateLayerColor = colorScheme.onSurface;
    } else if (isEffectivelyPressed) {
      stateLayerOpacity = 0.10;
      stateLayerColor = colorScheme.primary;
    } else if (isEffectivelyFocused) {
      stateLayerOpacity = 0.10;
      stateLayerColor = colorScheme.secondary;
    } else if (isEffectivelyHovered) {
      // Primary-derived hover tone ("اللون الغامق سيكة ده أو غامق شوية من اللون الأساسي")
      stateLayerOpacity = 0.08;
      stateLayerColor = colorScheme.primary;
    }

    Widget content = widget.child;

    // Optional 3-dots action menu overlay on top end
    if (widget.menuItems != null && widget.menuItems!.isNotEmpty) {
      content = Stack(
        children: [
          content,
          PositionedDirectional(
            top: 6,
            end: 6,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: isEffectivelyDisabled ? null : widget.onMenuItemSelected,
              enabled: !isEffectivelyDisabled,
              itemBuilder: (context) => widget.menuItems!.map((item) {
                return PopupMenuItem(
                  value: item.value,
                  child: Row(
                    children: [
                      if (item.icon != null) ...[
                        Icon(item.icon, size: 18, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                      ],
                      Text(item.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    if (widget.padding != null) {
      content = Padding(padding: widget.padding!, child: content);
    }

    // Apply M3 disabled opacity (38% on content) if card is disabled
    if (isEffectivelyDisabled) {
      content = Opacity(
        opacity: 0.38,
        child: content,
      );
    }

    final bool isActionable = widget.onTap != null || widget.enableHoverAnimation;

    // Wrap with M3 State Layer overlay
    if (stateLayerOpacity > 0.0 && (isActionable || widget.isHovered == true || widget.isFocused == true || widget.isDragged)) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: stateLayerColor.withValues(alpha: stateLayerOpacity),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Interactive ink response with state tracking (only when actionable)
    if (isActionable) {
      content = InkWell(
        focusNode: widget.focusNode,
        onTap: isEffectivelyDisabled ? null : widget.onTap,
        onHover: isEffectivelyDisabled ? null : (hover) => setState(() => _isHovered = hover),
        onFocusChange: isEffectivelyDisabled ? null : (focus) => setState(() => _isFocused = focus),
        onHighlightChanged: isEffectivelyDisabled ? null : (pressed) => setState(() => _isPressed = pressed),
        borderRadius: radius,
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        highlightColor: colorScheme.primary.withValues(alpha: 0.06),
        child: content,
      );
    }

    Widget cardWidget;

    switch (widget.variant) {
      case TashilCardVariant.elevated:
        // Google M3 Elevation Levels:
        // Disabled: Level 0 (0dp)
        // Resting: Level 1 (1dp)
        // Hovered: Level 2 (3dp)
        // Focused: Level 1 (1dp)
        // Pressed: Level 1 (1dp)
        // Dragged: Level 4 (8dp)
        double currentElevation;
        double shadowAlpha;

        if (isEffectivelyDisabled) {
          currentElevation = 0.0;
          shadowAlpha = 0.0;
        } else if (isEffectivelyDragged) {
          currentElevation = 8.0; // Level 4
          shadowAlpha = isDark ? 0.45 : 0.22;
        } else if (isEffectivelyHovered) {
          currentElevation = widget.hoverElevation ?? 3.0; // Level 2
          shadowAlpha = isDark ? 0.35 : 0.15;
        } else {
          currentElevation = widget.elevation ?? 1.0; // Level 1
          shadowAlpha = isDark ? 0.25 : 0.08;
        }

        // Focus Ring per M3 specification:
        // 3dp stroke width using colorScheme.secondary (or primary in focus)
        BorderSide borderSide;
        if (isEffectivelyFocused) {
          borderSide = BorderSide(
            color: colorScheme.secondary,
            width: 3.0,
          );
        } else if (isEffectivelyHovered) {
          borderSide = BorderSide(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.45 : 0.35),
            width: 1.0,
          );
        } else if (isEffectivelyDisabled) {
          borderSide = BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
            width: 0.5,
          );
        } else {
          borderSide = BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.35),
            width: 0.5,
          );
        }

        final containerColor = isEffectivelyDisabled
            ? (isDark
                ? colorScheme.surfaceContainerLow.withValues(alpha: 0.4)
                : colorScheme.surface.withValues(alpha: 0.38))
            : (widget.color ?? colorScheme.surfaceContainerLow);

        cardWidget = Card(
          elevation: currentElevation,
          shadowColor: isEffectivelyHovered
              ? colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.18)
              : colorScheme.shadow.withValues(alpha: shadowAlpha),
          color: containerColor,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: borderSide,
          ),
          clipBehavior: widget.clipBehavior,
          margin: widget.margin ?? EdgeInsets.zero,
          child: content,
        );
        break;

      case TashilCardVariant.filled:
        BorderSide borderSide = BorderSide.none;
        if (isEffectivelyFocused) {
          borderSide = BorderSide(
            color: colorScheme.secondary,
            width: 3.0,
          );
        }

        final containerColor = isEffectivelyDisabled
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : (widget.color ?? colorScheme.surfaceContainerHighest.withValues(alpha: 0.55));

        cardWidget = Card.filled(
          color: containerColor,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: borderSide,
          ),
          clipBehavior: widget.clipBehavior,
          margin: widget.margin ?? EdgeInsets.zero,
          child: content,
        );
        break;

      case TashilCardVariant.outlined:
        // Google M3 Outlined Card Elevation Levels:
        // Disabled: Level 0 (0dp)
        // Resting: Level 0 (0dp)
        // Hovered: Level 1 (1dp)
        // Focused: Level 0 (0dp)
        // Pressed: Level 0 (0dp)
        // Dragged: Level 4 (8dp)
        double currentElevation;
        double shadowAlpha;

        if (isEffectivelyDisabled) {
          currentElevation = 0.0;
          shadowAlpha = 0.0;
        } else if (isEffectivelyDragged) {
          currentElevation = 8.0; // Level 4
          shadowAlpha = isDark ? 0.40 : 0.20;
        } else if (isEffectivelyHovered && widget.enableHoverAnimation) {
          currentElevation = widget.hoverElevation ?? 1.0; // Level 1 (1dp) per M3 specs
          shadowAlpha = isDark ? 0.25 : 0.08;
        } else {
          currentElevation = 0.0; // Level 0 resting
          shadowAlpha = 0.0;
        }

        BorderSide borderSide;
        if (isEffectivelyFocused) {
          // Focus Ring per M3 Outlined Card specification:
          // 3dp stroke width using colorScheme.secondary
          borderSide = BorderSide(
            color: colorScheme.secondary,
            width: 3.0,
          );
        } else if (isEffectivelyHovered && widget.enableHoverAnimation) {
          borderSide = BorderSide(
            color: isDark ? colorScheme.primary.withValues(alpha: 0.55) : colorScheme.primary.withValues(alpha: 0.42),
            width: 1.0,
          );
        } else if (isEffectivelyDisabled) {
          borderSide = BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.20),
            width: 1.0,
          );
        } else {
          borderSide = BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          );
        }

        final containerColor = isEffectivelyDisabled
            ? (isDark
                ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.4)
                : colorScheme.surface.withValues(alpha: 0.38))
            : (widget.color ?? (isDark ? colorScheme.surfaceContainerLowest : colorScheme.surface));

        cardWidget = Card(
          elevation: currentElevation,
          shadowColor: (isEffectivelyHovered && widget.enableHoverAnimation)
              ? colorScheme.primary.withValues(alpha: isDark ? 0.30 : 0.15)
              : colorScheme.shadow.withValues(alpha: shadowAlpha),
          color: containerColor,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: borderSide,
          ),
          clipBehavior: widget.clipBehavior,
          margin: widget.margin ?? EdgeInsets.zero,
          child: content,
        );
        break;
    }

    if (widget.width != null || widget.height != null) {
      cardWidget = SizedBox(
        width: widget.width,
        height: widget.height,
        child: cardWidget,
      );
    }

    // Determine cursor
    final MouseCursor cursor;
    if (isEffectivelyDisabled) {
      cursor = SystemMouseCursors.basic;
    } else if (isEffectivelyDragged) {
      cursor = SystemMouseCursors.grabbing;
    } else if (widget.onTap != null) {
      cursor = SystemMouseCursors.click;
    } else {
      cursor = MouseCursor.defer;
    }

    // Subtle Google M3 physical motion:
    // Hover: lift (-3dp) and expressive spring micro-scale (1.010x)
    // Dragged: lift (-6dp) and scale (1.020x)
    double offsetY = 0.0;
    double scale = 1.0;
    if (isEffectivelyDragged) {
      offsetY = -6.0;
      scale = 1.020;
    } else if (widget.enableHoverAnimation && isEffectivelyHovered) {
      offsetY = -3.0;
      scale = 1.010;
    }

    return MouseRegion(
      cursor: cursor,
      child: AnimatedContainer(
        duration: isEffectivelyHovered || isEffectivelyDragged
            ? TashilMotionWebCurves.expressiveFastSpatialDuration
            : TashilMotionDuration.short3,
        curve: isEffectivelyHovered || isEffectivelyDragged
            ? TashilMotionWebCurves.expressiveFastSpatial
            : TashilMotionEasing.standardDecelerate,
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(scale, scale, 1.0)
          ..setTranslationRaw(0.0, offsetY, 0.0),
        child: cardWidget,
      ),
    );
  }
}

/// Official Google Material Design 3 Card Text Hierarchy Component.
///
/// Strictly conforms to the Google M3 Card Text Anatomy:
/// 1. **Headline**: Often communicates the subject of the card, such as the name of
///    a photo album, article, or property title. Uses [TextTheme.titleMedium] / [TextTheme.titleLarge].
/// 2. **Subhead**: Smaller text elements, such as an article byline, author/date,
///    or tagged location. Uses [TextTheme.bodySmall] / [TextTheme.labelMedium].
/// 3. **Supporting text**: Includes body content, such as an article summary, restaurant
///    description, or property overview. Uses [TextTheme.bodySmall] / [TextTheme.bodyMedium].
class TashilCardText extends StatelessWidget {
  /// The primary subject of the card.
  final String? headlineText;

  /// Custom headline widget if custom layout or styling is needed.
  final Widget? headline;

  /// Secondary text element (e.g. tagged location, byline, category).
  final String? subheadText;

  /// Custom subhead widget if needed.
  final Widget? subhead;

  /// Optional leading icon or avatar for the subhead (e.g. location pin, author avatar).
  final Widget? subheadLeading;

  /// Body content describing the card subject.
  final String? supportingText;

  /// Custom supporting text widget if needed.
  final Widget? supportingWidget;

  /// Optional trailing widget on the headline/subhead row (e.g. star rating, badge, favorite button).
  final Widget? trailing;

  /// Maximum lines for the headline. Defaults to 1.
  final int headlineMaxLines;

  /// Maximum lines for supporting text. Defaults to 2.
  final int supportingTextMaxLines;

  /// Whether to render the subhead above the headline (e.g. author byline or tagged location first).
  final bool subheadFirst;

  /// Vertical spacing between text elements. Defaults to 4.0.
  final double spacing;

  /// Optional linked text within or at the end of the supporting text per M3 specifications
  /// ("There can be a link in the supporting text on a card").
  final String? linkedText;

  /// Callback when the linked text is clicked.
  final VoidCallback? onLinkedTextTap;

  /// Optional selection control (e.g. chips, checkbox, slider) embedded in the card.
  final Widget? selectionControl;

  const TashilCardText({
    super.key,
    this.headlineText,
    this.headline,
    this.subheadText,
    this.subhead,
    this.subheadLeading,
    this.supportingText,
    this.supportingWidget,
    this.trailing,
    this.headlineMaxLines = 1,
    this.supportingTextMaxLines = 2,
    this.subheadFirst = false,
    this.spacing = 4.0,
    this.linkedText,
    this.onLinkedTextTap,
    this.selectionControl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Headline Widget
    Widget? headlineWidget = headline;
    if (headlineWidget == null && headlineText != null && headlineText!.isNotEmpty) {
      headlineWidget = Text(
        headlineText!,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          height: 1.3,
        ),
        maxLines: headlineMaxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 2. Subhead Widget
    Widget? subheadWidget = subhead;
    if (subheadWidget == null && subheadText != null && subheadText!.isNotEmpty) {
      final text = Text(
        subheadText!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      if (subheadLeading != null) {
        subheadWidget = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            subheadLeading!,
            const SizedBox(width: 4),
            Expanded(child: text),
          ],
        );
      } else {
        subheadWidget = text;
      }
    }

    // 3. Supporting Text Widget (with Linked Text support per Google M3 specs)
    Widget? suppWidget = supportingWidget;
    if (suppWidget == null && supportingText != null && supportingText!.isNotEmpty) {
      if (linkedText != null && linkedText!.isNotEmpty) {
        if (supportingTextMaxLines == 1) {
          suppWidget = Row(
            children: [
              Expanded(
                child: Text(
                  supportingText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onLinkedTextTap,
                  child: Text(
                    linkedText!,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          suppWidget = RichText(
            maxLines: supportingTextMaxLines,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              children: [
                TextSpan(text: '$supportingText '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onLinkedTextTap,
                      child: Text(
                        linkedText!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        suppWidget = Text(
          supportingText!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
          maxLines: supportingTextMaxLines,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    // Assemble components according to subheadFirst configuration
    final List<Widget> children = [];

    if (subheadFirst) {
      if (subheadWidget != null) {
        if (trailing != null && headlineWidget == null) {
          children.add(
            Row(
              children: [
                Expanded(child: subheadWidget),
                const SizedBox(width: 8),
                trailing!,
              ],
            ),
          );
        } else {
          children.add(subheadWidget);
        }
      }

      if (headlineWidget != null) {
        if (children.isNotEmpty) children.add(SizedBox(height: spacing));
        if (trailing != null) {
          children.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: headlineWidget),
                const SizedBox(width: 8),
                trailing!,
              ],
            ),
          );
        } else {
          children.add(headlineWidget);
        }
      }
    } else {
      if (headlineWidget != null) {
        if (trailing != null) {
          children.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: headlineWidget),
                const SizedBox(width: 8),
                trailing!,
              ],
            ),
          );
        } else {
          children.add(headlineWidget);
        }
      }

      if (subheadWidget != null) {
        if (children.isNotEmpty) children.add(SizedBox(height: spacing));
        children.add(subheadWidget);
      }
    }

    if (suppWidget != null) {
      if (children.isNotEmpty) children.add(SizedBox(height: spacing));
      children.add(suppWidget);
    }

    if (selectionControl != null) {
      if (children.isNotEmpty) children.add(SizedBox(height: spacing));
      children.add(selectionControl!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

