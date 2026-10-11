import 'package:flutter/material.dart';

/// The standard line configuration variants for Material Design 3 List items:
/// https://m3.material.io/components/lists/specs
enum TashilListTileLines {
  /// One-line list item: 56dp standard container height (48dp dense).
  oneLine,

  /// Two-line list item: 72dp standard container height (64dp dense).
  twoLine,

  /// Three-line list item: 88dp standard container height.
  threeLine,
}

/// Leading media/icon type for M3 List Item sizing & clipping.
enum TashilListTileLeadingType {
  /// 24dp icon centered in a 40dp box.
  icon,

  /// 40x40dp circular or rounded squircle avatar.
  avatar,

  /// 56x56dp squircle thumbnail image (ideal for real estate properties).
  thumbnail,

  /// 100x56dp or 114x64dp landscape thumbnail for video/floorplans.
  video,

  /// Unconstrained custom leading widget.
  custom,
}

/// Official Material Design 3 List Item Component for Tashil Real Estate.
///
/// Fully adheres to:
/// - https://m3.material.io/components/lists/guidelines
/// - https://m3.material.io/components/lists/specs
///
/// Features:
/// 1. Strict M3 container heights (56dp for 1-line, 72dp for 2-line, 88dp for 3-line).
/// 2. 16dp horizontal insets with Directional RTL/LTR awareness.
/// 3. 16dp spacing between leading, text column, and trailing items.
/// 4. M3 Typography hierarchy (headline, overline, supportingText).
/// 5. Hover, focus, pressed state layers and selected state styling.
class TashilListTile extends StatelessWidget {
  /// Line variant determining the standard M3 height constraints.
  final TashilListTileLines lines;

  /// The primary headline text or widget.
  final Widget headline;

  /// Optional supporting text / subtitle.
  final Widget? supportingText;

  /// Optional second supporting text line or overline text.
  final Widget? overline;

  /// Leading element (icon, avatar, image thumbnail, or drag handle).
  final Widget? leading;

  /// Type of leading widget for optimal M3 aspect ratio and clipping.
  final TashilListTileLeadingType leadingType;

  /// Trailing element (price, badge, status chip, action buttons, switch, checkbox).
  final Widget? trailing;

  /// Whether this list item is currently selected.
  final bool selected;

  /// Whether this list item is interactive and enabled.
  final bool enabled;

  /// Callback when the list item is clicked/tapped.
  final VoidCallback? onTap;

  /// Callback when the list item is long-pressed (ideal for touch reorder / contextual menus).
  final VoidCallback? onLongPress;

  /// Dense mode reduces height (48dp for 1-line, 64dp for 2-line).
  final bool dense;

  /// Custom padding overriding default 16dp horizontal M3 spec.
  final EdgeInsetsDirectional? contentPadding;

  /// Corner radius of this tile container (default 0 for flat lists, 12-16dp for card rows).
  final BorderRadius? borderRadius;

  /// Background color of the tile. If null, transparent or surface container.
  final Color? backgroundColor;

  const TashilListTile({
    super.key,
    this.lines = TashilListTileLines.oneLine,
    required this.headline,
    this.supportingText,
    this.overline,
    this.leading,
    this.leadingType = TashilListTileLeadingType.custom,
    this.trailing,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.contentPadding,
    this.borderRadius,
    this.backgroundColor,
  });

  /// 1-Line M3 List Item (56dp standard height, 48dp dense)
  factory TashilListTile.oneLine({
    Key? key,
    required Widget headline,
    Widget? leading,
    TashilListTileLeadingType leadingType = TashilListTileLeadingType.icon,
    Widget? trailing,
    bool selected = false,
    bool enabled = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool dense = false,
    EdgeInsetsDirectional? contentPadding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return TashilListTile(
      key: key,
      lines: TashilListTileLines.oneLine,
      headline: headline,
      leading: leading,
      leadingType: leadingType,
      trailing: trailing,
      selected: selected,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      dense: dense,
      contentPadding: contentPadding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }

  /// 2-Line M3 List Item (72dp standard height, 64dp dense)
  factory TashilListTile.twoLine({
    Key? key,
    required Widget headline,
    required Widget supportingText,
    Widget? overline,
    Widget? leading,
    TashilListTileLeadingType leadingType = TashilListTileLeadingType.thumbnail,
    Widget? trailing,
    bool selected = false,
    bool enabled = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool dense = false,
    EdgeInsetsDirectional? contentPadding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return TashilListTile(
      key: key,
      lines: TashilListTileLines.twoLine,
      headline: headline,
      supportingText: supportingText,
      overline: overline,
      leading: leading,
      leadingType: leadingType,
      trailing: trailing,
      selected: selected,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      dense: dense,
      contentPadding: contentPadding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }

  /// 3-Line M3 List Item (88dp standard height)
  factory TashilListTile.threeLine({
    Key? key,
    required Widget headline,
    required Widget supportingText,
    Widget? overline,
    Widget? leading,
    TashilListTileLeadingType leadingType = TashilListTileLeadingType.thumbnail,
    Widget? trailing,
    bool selected = false,
    bool enabled = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    EdgeInsetsDirectional? contentPadding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return TashilListTile(
      key: key,
      lines: TashilListTileLines.threeLine,
      headline: headline,
      supportingText: supportingText,
      overline: overline,
      leading: leading,
      leadingType: leadingType,
      trailing: trailing,
      selected: selected,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      dense: false,
      contentPadding: contentPadding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }

  /// Calculates the official M3 minimum height based on specs
  double get minHeight {
    switch (lines) {
      case TashilListTileLines.oneLine:
        return dense ? 48.0 : 56.0;
      case TashilListTileLines.twoLine:
        return dense ? 64.0 : 72.0;
      case TashilListTileLines.threeLine:
        return 88.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on selection & enabled state
    Color effectiveBackground;
    Color headlineColor;
    Color supportingColor;

    if (!enabled) {
      effectiveBackground = Colors.transparent;
      headlineColor = colorScheme.onSurface.withValues(alpha: 0.38);
      supportingColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (selected) {
      effectiveBackground = colorScheme.secondaryContainer.withValues(alpha: 0.8);
      headlineColor = colorScheme.onSecondaryContainer;
      supportingColor = colorScheme.onSecondaryContainer.withValues(alpha: 0.85);
    } else {
      effectiveBackground = backgroundColor ?? Colors.transparent;
      headlineColor = colorScheme.onSurface;
      supportingColor = colorScheme.onSurfaceVariant;
    }

    final verticalPadding = switch (lines) {
      TashilListTileLines.oneLine => dense ? 6.0 : 8.0,
      TashilListTileLines.twoLine => dense ? 8.0 : 12.0,
      TashilListTileLines.threeLine => 12.0,
    };

    final effectivePadding = contentPadding ??
        EdgeInsetsDirectional.only(
          start: 16.0,
          end: 16.0,
          top: verticalPadding,
          bottom: verticalPadding,
        );

    final effectiveBorderRadius = borderRadius ?? BorderRadius.zero;

    return Material(
      color: effectiveBackground,
      borderRadius: effectiveBorderRadius,
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: effectiveBorderRadius,
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: effectivePadding,
          child: Row(
            crossAxisAlignment: lines == TashilListTileLines.threeLine
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              // 1. Leading Element
              if (leading != null) ...[
                _buildLeading(context, colorScheme),
                const SizedBox(width: 16.0), // Official M3 16dp spacing
              ],

              // 2. Center Text Column (Overline, Headline, Supporting Text)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (overline != null) ...[
                      DefaultTextStyle(
                        style: theme.textTheme.labelSmall?.copyWith(
                              color: supportingColor,
                              letterSpacing: 0.5,
                            ) ??
                            TextStyle(color: supportingColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: overline!,
                      ),
                      const SizedBox(height: 2.0),
                    ],
                    DefaultTextStyle(
                      style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: headlineColor,
                          ) ??
                          TextStyle(
                            color: headlineColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: lines == TashilListTileLines.oneLine ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      child: headline,
                    ),
                    if (supportingText != null) ...[
                      const SizedBox(height: 3.0),
                      DefaultTextStyle(
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: supportingColor,
                            ) ??
                            TextStyle(color: supportingColor, fontSize: 14),
                        maxLines: lines == TashilListTileLines.threeLine ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        child: supportingText!,
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Trailing Element
              if (trailing != null) ...[
                const SizedBox(width: 16.0), // Official M3 16dp spacing
                Align(
                  alignment: lines == TashilListTileLines.threeLine
                      ? Alignment.topRight
                      : Alignment.center,
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the leading element formatted to M3 specifications.
  Widget _buildLeading(BuildContext context, ColorScheme colorScheme) {
    switch (leadingType) {
      case TashilListTileLeadingType.icon:
        return SizedBox(
          width: 40.0,
          height: 40.0,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: enabled
                    ? (selected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant)
                    : colorScheme.onSurface.withValues(alpha: 0.38),
                size: 24.0,
              ),
              child: leading!,
            ),
          ),
        );

      case TashilListTileLeadingType.avatar:
        return SizedBox(
          width: 40.0,
          height: 40.0,
          child: leading!,
        );

      case TashilListTileLeadingType.thumbnail:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: SizedBox(
            width: 56.0,
            height: 56.0,
            child: leading!,
          ),
        );

      case TashilListTileLeadingType.video:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: SizedBox(
            width: 100.0,
            height: 56.0,
            child: leading!,
          ),
        );

      case TashilListTileLeadingType.custom:
        return leading!;
    }
  }
}
