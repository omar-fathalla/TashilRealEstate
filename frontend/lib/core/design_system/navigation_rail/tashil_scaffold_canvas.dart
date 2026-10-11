import 'package:flutter/material.dart';

/// Official Material Design 3 (M3) Nested Canvas Scaffold.
///
/// Implements Google Material Design 3 nested canvas architecture (as in Google Clock, Gmail, Keep):
/// - Unified Canvas Frame: Top Header and Navigation Rail share the identical background color
///   (`colorScheme.surfaceContainerLowest` or `surface`) with zero dividing line between them.
/// - Nested Body Container: The main content body sits in a distinct container with:
///   * A richer/slightly darker surface color (`colorScheme.surfaceContainerLow` / `surfaceContainer`).
///   * A prominent M3 corner curve on the top-start corner (`28dp` radius) meeting the rail & header.
///   * In RTL (Arabic), the top-right corner curves smoothly into the workspace.
///   * In LTR (English/Hindi), the top-left corner curves smoothly into the workspace.
class TashilScaffoldCanvas extends StatelessWidget {
  final Widget header;
  final Widget navigationRail;
  final Widget body;
  final Color? canvasBackgroundColor;
  final Color? bodyBackgroundColor;
  final double cornerRadius;

  const TashilScaffoldCanvas({
    super.key,
    required this.header,
    required this.navigationRail,
    required this.body,
    this.canvasBackgroundColor,
    this.bodyBackgroundColor,
    this.cornerRadius = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 1. Unified outer frame color (behind Header & Rail)
    final effectiveCanvasBg = canvasBackgroundColor ??
        (isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest);

    // 2. Nested body workspace color (slightly darker/richer contrast as seen in Image 3)
    final effectiveBodyBg = bodyBackgroundColor ??
        (isDark
            ? colorScheme.surfaceContainerLow
            : Color.alphaBlend(
                colorScheme.primary.withAlpha(10),
                colorScheme.surfaceContainerLow,
              ));

    final curveRadius = Radius.circular(cornerRadius);

    return Scaffold(
      backgroundColor: effectiveCanvasBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Persistent Top Header (Seamlessly colored with the canvas background)
          Container(
            color: effectiveCanvasBg,
            child: header,
          ),

          // 2. Main Row: Navigation Rail + Nested Curved Body
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Navigation Rail / Expanded Drawer
                Container(
                  color: effectiveCanvasBg,
                  height: double.infinity,
                  child: navigationRail,
                ),

                // Nested Body Workspace with 28dp Corner Curve
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: effectiveBodyBg,
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: curveRadius,
                      ),
                      border: BorderDirectional(
                        top: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(60),
                          width: 1.0,
                        ),
                        start: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(60),
                          width: 1.0,
                        ),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
