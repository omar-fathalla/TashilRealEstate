import 'package:flutter/material.dart';

/// Material Design 3 Divider Variants based on the official guidelines:
/// https://m3.material.io/components/divider/guidelines
enum TashilDividerVariant {
  /// Full-width divider spanning 100% of container width.
  /// Used to separate distinct functional areas (e.g. headers, sections).
  fullWidth,

  /// Inset divider with a leading indent (e.g. 16dp or 72dp) aligning with
  /// content/text after an icon or avatar in lists. Directionality-aware.
  inset,

  /// Middle inset divider with equal start and end insets (e.g. 16dp on both sides).
  middleInset,

  /// M3 "Do" Guideline separator: full-width divider explicitly separating
  /// interactive areas (buttons/actions) from non-interactive content areas in cards/sheets.
  cardAction,
}

/// Official Material Design 3 Divider Component for Tashil Real Estate.
///
/// Implements Google M3 guidelines:
/// - 1dp standard thickness.
/// - [ColorScheme.outlineVariant] subtle container contrast.
/// - RTL / LTR directionality awareness for insets.
/// - DO: Separates interactive areas from non-interactive content in cards and dialogs.
/// - CAUTION: Used sparingly to avoid visual clutter in dense lists.
class TashilDivider extends StatelessWidget {
  /// The total height allocated to this divider. Defaults to 1.0dp for minimal footprint.
  final double height;

  /// The thickness of the divider line. Defaults to 1.0dp per M3 specs.
  final double thickness;

  /// Indent at the leading edge (in RTL, this is the right edge; in LTR, the left edge).
  final double startIndent;

  /// Indent at the trailing edge (in RTL, this is the left edge; in LTR, the right edge).
  final double endIndent;

  /// Color of the divider line. Defaults to [ColorScheme.outlineVariant].
  final Color? color;

  /// The structural variant of this divider.
  final TashilDividerVariant variant;

  const TashilDivider({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.startIndent = 0.0,
    this.endIndent = 0.0,
    this.color,
    this.variant = TashilDividerVariant.fullWidth,
  });

  /// Type 1: Full-width Divider
  ///
  /// Spans the entire width of its container or screen (0 indent).
  const TashilDivider.fullWidth({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.color,
  })  : variant = TashilDividerVariant.fullWidth,
        startIndent = 0.0,
        endIndent = 0.0;

  /// Type 2: Inset Divider
  ///
  /// Indented at the start (default 16dp, or 72dp for list items after avatars).
  /// Automatically places the indent on the correct side in RTL (Arabic) and LTR.
  const TashilDivider.inset({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.startIndent = 16.0,
    this.endIndent = 0.0,
    this.color,
  }) : variant = TashilDividerVariant.inset;

  /// Inset Divider aligned specifically with list item text after a leading avatar/icon (72dp).
  const TashilDivider.listTextInset({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.startIndent = 72.0,
    this.endIndent = 0.0,
    this.color,
  }) : variant = TashilDividerVariant.inset;

  /// Type 3: Middle Inset Divider
  ///
  /// Indented symmetrically at both start and end (default 16dp).
  const TashilDivider.middleInset({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    double inset = 16.0,
    this.color,
  })  : variant = TashilDividerVariant.middleInset,
        startIndent = inset,
        endIndent = inset;

  /// Type 4: M3 "Do" Card Action Divider
  ///
  /// Full-width divider explicitly separating interactive actions (buttons, chips)
  /// from non-interactive content (media, body text) within cards and dialogs.
  const TashilDivider.cardAction({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.color,
  })  : variant = TashilDividerVariant.cardAction,
        startIndent = 0.0,
        endIndent = 0.0;

  /// Type 5: Labelled Divider (e.g. "أو" / "OR" or Section Subheader)
  ///
  /// Factory helper that returns a [TashilLabelledDivider].
  static Widget withLabel({
    Key? key,
    required String label,
    TextStyle? textStyle,
    Color? color,
    double thickness = 1.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    Widget? leadingIcon,
  }) {
    return TashilLabelledDivider(
      key: key,
      label: label,
      textStyle: textStyle,
      color: color,
      thickness: thickness,
      padding: padding,
      leadingIcon: leadingIcon,
    );
  }

  /// Factory helper for a Vertical Divider.
  static Widget vertical({
    Key? key,
    double width = 1.0,
    double thickness = 1.0,
    double topIndent = 0.0,
    double bottomIndent = 0.0,
    Color? color,
  }) {
    return TashilVerticalDivider(
      key: key,
      width: width,
      thickness: thickness,
      topIndent: topIndent,
      bottomIndent: bottomIndent,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.outlineVariant;

    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: thickness,
          margin: EdgeInsetsDirectional.only(
            start: startIndent,
            end: endIndent,
          ),
          decoration: BoxDecoration(
            color: effectiveColor,
          ),
        ),
      ),
    );
  }
}

/// Official Material Design 3 Vertical Divider Component.
///
/// A thin 1dp vertical line that separates horizontally adjacent elements
/// (e.g. split buttons, toolbars, side-by-side metric tiles).
class TashilVerticalDivider extends StatelessWidget {
  /// The total width allocated to this vertical divider. Defaults to 1.0dp.
  final double width;

  /// The thickness of the vertical line. Defaults to 1.0dp per M3 specs.
  final double thickness;

  /// Indent at the top edge. Defaults to 0.0.
  final double topIndent;

  /// Indent at the bottom edge. Defaults to 0.0.
  final double bottomIndent;

  /// Color of the divider line. Defaults to [ColorScheme.outlineVariant].
  final Color? color;

  const TashilVerticalDivider({
    super.key,
    this.width = 1.0,
    this.thickness = 1.0,
    this.topIndent = 0.0,
    this.bottomIndent = 0.0,
    this.color,
  });

  /// Inset vertical divider with subtle top and bottom padding (e.g. 6dp).
  const TashilVerticalDivider.inset({
    super.key,
    this.width = 1.0,
    this.thickness = 1.0,
    double inset = 6.0,
    this.color,
  })  : topIndent = inset,
        bottomIndent = inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.outlineVariant;

    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          width: thickness,
          margin: EdgeInsets.only(
            top: topIndent,
            bottom: bottomIndent,
          ),
          decoration: BoxDecoration(
            color: effectiveColor,
          ),
        ),
      ),
    );
  }
}

/// Material Design 3 Labelled Divider Component.
///
/// Renders a centered or leading label (e.g. "أو" / "OR" or Section title)
/// flanked by thin 1dp M3 divider lines. Directionality and typography aware.
class TashilLabelledDivider extends StatelessWidget {
  final String label;
  final TextStyle? textStyle;
  final Color? color;
  final double thickness;
  final EdgeInsetsGeometry padding;
  final Widget? leadingIcon;

  const TashilLabelledDivider({
    super.key,
    required this.label,
    this.textStyle,
    this.color,
    this.thickness = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.outlineVariant;

    final effectiveTextStyle = textStyle ??
        theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: thickness,
              color: effectiveColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: effectiveTextStyle,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: thickness,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
