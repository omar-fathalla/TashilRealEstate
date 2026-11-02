import 'package:flutter/material.dart';

/// Official Material Design 3 Max-Width Content Boundary & Visual Breathing Container.
///
/// Prevents dashboard content, data tables, and forms from infinitely stretching
/// on ultra-wide desktop and 4K displays. Centers the content while providing
/// balanced, symmetrical visual breathing margins.
///
/// Thresholds:
/// - [standardMaxWidth]: 1360.0dp (Recommended canonical width for dashboards & views)
/// - [dataTableMaxWidth]: 1440.0dp (Expanded width for dense financial tables & grids)
///
/// Reference: https://m3.material.io/foundations/layout/applying-layout/canonical-layouts
class M3ContentBoundary extends StatelessWidget {
  static const double standardMaxWidth = 1360.0;
  static const double dataTableMaxWidth = 1440.0;

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  const M3ContentBoundary({
    super.key,
    required this.child,
    this.maxWidth = standardMaxWidth,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  /// Factory constructor optimized for dense data tables and analytical dashboards (1440dp).
  const M3ContentBoundary.table({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.padding,
  }) : maxWidth = dataTableMaxWidth;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    return Align(
      alignment: alignment,
      child: content,
    );
  }
}
