import 'package:flutter/material.dart';

/// Official Google Material Design 3 (M3) Window Size Classes.
///
/// Categorizes viewports according to Google's official canonical breakpoints:
/// - [compact]: < 600dp (Smartphones portrait, foldables folded)
/// - [medium]: 600 - 839dp (Small tablets, foldables unfolded, landscape phones)
/// - [expanded]: 840 - 1199dp (Laptops, large tablets landscape)
/// - [large]: 1200 - 1599dp (Desktop monitors)
/// - [extraLarge]: >= 1600dp (Ultra-wide displays, 4K monitors)
///
/// Reference: https://m3.material.io/foundations/layout/applying-layout/window-size-classes
enum M3WindowSizeClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge,
}

/// Official M3 Canonical Adaptive Navigation Types.
enum M3NavigationType {
  /// Modal Navigation Drawer triggered via AppBar or Bottom Navigation Bar (< 600dp)
  modalDrawerOrBottomBar,

  /// Slim Navigation Rail (72dp - 80dp) for tablet viewports (600 - 839dp)
  rail,

  /// Persistent Navigation Sidebar / Drawer (230 - 275dp) for laptops (840 - 1199dp)
  persistentSidebar,

  /// Permanent Navigation Drawer for desktop displays (1200 - 1599dp)
  permanentDrawer,

  /// Permanent Navigation Drawer with Max-Width Content Containment (>= 1600dp)
  permanentDrawerWithContainment,
}

/// Official Material Design 3 Layout Metrics and Grid Tokens.
class M3LayoutMetrics {
  final double width;
  final double height;
  final M3WindowSizeClass windowSizeClass;
  final int columns;
  final double margin;
  final double gutter;
  final M3NavigationType navigationType;

  const M3LayoutMetrics({
    required this.width,
    required this.height,
    required this.windowSizeClass,
    required this.columns,
    required this.margin,
    required this.gutter,
    required this.navigationType,
  });

  bool get isCompact => windowSizeClass == M3WindowSizeClass.compact;
  bool get isMedium => windowSizeClass == M3WindowSizeClass.medium;
  bool get isExpanded => windowSizeClass == M3WindowSizeClass.expanded;
  bool get isLarge => windowSizeClass == M3WindowSizeClass.large;
  bool get isExtraLarge => windowSizeClass == M3WindowSizeClass.extraLarge;

  /// Convenience aliases conforming to Tashil 3-tier Adaptive Navigation
  bool get isMobile => isCompact;
  bool get isTablet => isMedium;
  bool get isDesktop => isExpanded || isLarge || isExtraLarge;

  @override
  String toString() =>
      'M3LayoutMetrics(width: ${width.toStringAsFixed(1)}, class: ${windowSizeClass.name}, cols: $columns, margin: $margin, gutter: $gutter)';
}

/// Authoritative Material Design 3 Layout Engine.
abstract class M3Layout {
  static const double compactMaxWidth = 599.99;
  static const double mediumMinWidth = 600.0;
  static const double mediumMaxWidth = 839.99;
  static const double expandedMinWidth = 840.0;
  static const double expandedMaxWidth = 1199.99;
  static const double largeMinWidth = 1200.0;
  static const double largeMaxWidth = 1599.99;
  static const double extraLargeMinWidth = 1600.0;

  /// Resolves the official [M3WindowSizeClass] for a given width.
  static M3WindowSizeClass windowSizeClassFromWidth(double width) {
    if (width < mediumMinWidth) return M3WindowSizeClass.compact;
    if (width < expandedMinWidth) return M3WindowSizeClass.medium;
    if (width < largeMinWidth) return M3WindowSizeClass.expanded;
    if (width < extraLargeMinWidth) return M3WindowSizeClass.large;
    return M3WindowSizeClass.extraLarge;
  }

  /// Calculates the complete [M3LayoutMetrics] from viewport dimensions.
  static M3LayoutMetrics fromWidth(double width, [double height = 0.0]) {
    final sizeClass = windowSizeClassFromWidth(width);

    switch (sizeClass) {
      case M3WindowSizeClass.compact:
        return M3LayoutMetrics(
          width: width,
          height: height,
          windowSizeClass: sizeClass,
          columns: 4,
          margin: 16.0,
          gutter: 16.0,
          navigationType: M3NavigationType.modalDrawerOrBottomBar,
        );
      case M3WindowSizeClass.medium:
        return M3LayoutMetrics(
          width: width,
          height: height,
          windowSizeClass: sizeClass,
          columns: 8,
          margin: 24.0,
          gutter: 24.0,
          navigationType: M3NavigationType.rail,
        );
      case M3WindowSizeClass.expanded:
        return M3LayoutMetrics(
          width: width,
          height: height,
          windowSizeClass: sizeClass,
          columns: 12,
          margin: 24.0,
          gutter: 24.0,
          navigationType: M3NavigationType.persistentSidebar,
        );
      case M3WindowSizeClass.large:
        return M3LayoutMetrics(
          width: width,
          height: height,
          windowSizeClass: sizeClass,
          columns: 12,
          margin: 32.0,
          gutter: 24.0,
          navigationType: M3NavigationType.permanentDrawer,
        );
      case M3WindowSizeClass.extraLarge:
        return M3LayoutMetrics(
          width: width,
          height: height,
          windowSizeClass: sizeClass,
          columns: 12,
          margin: 64.0,
          gutter: 24.0,
          navigationType: M3NavigationType.permanentDrawerWithContainment,
        );
    }
  }

  /// Extracts [M3LayoutMetrics] from the current ambient [BuildContext].
  static M3LayoutMetrics of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return fromWidth(size.width, size.height);
  }

  /// Extracts [M3LayoutMetrics] from incoming [BoxConstraints].
  static M3LayoutMetrics fromConstraints(BoxConstraints constraints) {
    return fromWidth(
      constraints.maxWidth,
      constraints.hasBoundedHeight ? constraints.maxHeight : 0.0,
    );
  }

  // --- Static Quick Boolean Checks ---
  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < mediumMinWidth;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mediumMinWidth && w < expandedMinWidth;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= expandedMinWidth;

  static bool isCompact(BuildContext context) => of(context).isCompact;
  static bool isMedium(BuildContext context) => of(context).isMedium;
  static bool isExpanded(BuildContext context) => of(context).isExpanded;
  static bool isLarge(BuildContext context) => of(context).isLarge;
  static bool isExtraLarge(BuildContext context) => of(context).isExtraLarge;
}

/// Responsive builder delivering [M3LayoutMetrics] directly into the build tree.
class M3ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, M3LayoutMetrics layout) builder;

  const M3ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = M3Layout.fromConstraints(constraints);
        return builder(context, layout);
      },
    );
  }
}

/// Adaptive layout component displaying specific widgets per M3 Window Size Class.
class M3AdaptiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;
  final Widget? large;
  final Widget? extraLarge;

  const M3AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
    this.extraLarge,
  });

  @override
  Widget build(BuildContext context) {
    return M3ResponsiveBuilder(
      builder: (context, layout) {
        switch (layout.windowSizeClass) {
          case M3WindowSizeClass.compact:
            return compact;
          case M3WindowSizeClass.medium:
            return medium ?? compact;
          case M3WindowSizeClass.expanded:
            return expanded ?? medium ?? compact;
          case M3WindowSizeClass.large:
            return large ?? expanded ?? medium ?? compact;
          case M3WindowSizeClass.extraLarge:
            return extraLarge ?? large ?? expanded ?? medium ?? compact;
        }
      },
    );
  }
}
