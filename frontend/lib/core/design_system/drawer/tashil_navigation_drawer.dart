import 'package:flutter/material.dart';

export 'tashil_drawer_destination.dart';
export 'tashil_drawer_section_header.dart';
export 'tashil_drawer_profile_tile.dart';
export 'm3_drawer_showcase_dialog.dart';

/// Official Material Design 3 (M3) Navigation Drawer Design System for Tashil Real Estate.
///
/// Conforms strictly to Google Material Design 3 specifications:
/// - https://m3.material.io/components/navigation-drawer/overview
/// - https://m3.material.io/components/navigation-drawer/specs
/// - https://m3.material.io/components/navigation-drawer/guidelines
///
/// Types:
/// 1. Standard Drawer ([TashilNavigationDrawer.standard]):
///    Persistent or collapsible side panel for desktop & tablet (≥840dp).
///    Supports smooth 250ms cubic easing between expanded (280-360dp) and rail mode (76dp).
/// 2. Modal Drawer ([TashilNavigationDrawer.modal]):
///    Sliding overlay for mobile screens (<600dp) with Level 1 elevation and
///    a 28dp corner radius on the trailing edge meeting the content.
class TashilNavigationDrawer extends StatelessWidget {
  final bool isModal;
  final bool isCollapsed;
  final Widget? header;
  final List<Widget> destinations;
  final Widget? footer;
  final double? expandedWidth;
  final double collapsedWidth;
  final Color? backgroundColor;
  final Duration animationDuration;
  final Curve animationCurve;
  final EdgeInsetsDirectional padding;

  const TashilNavigationDrawer.standard({
    super.key,
    this.isCollapsed = false,
    this.header,
    required this.destinations,
    this.footer,
    this.expandedWidth = 270.0,
    this.collapsedWidth = 76.0,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOutCubic,
    this.padding = const EdgeInsetsDirectional.symmetric(vertical: 12.0),
  }) : isModal = false;

  const TashilNavigationDrawer.modal({
    super.key,
    this.header,
    required this.destinations,
    this.footer,
    this.expandedWidth = 330.0,
    this.backgroundColor,
    this.padding = const EdgeInsetsDirectional.symmetric(vertical: 16.0),
  })  : isModal = true,
        isCollapsed = false,
        collapsedWidth = 76.0,
        animationDuration = const Duration(milliseconds: 250),
        animationCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBg = backgroundColor ??
        (isModal
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest);

    final currentWidth = isCollapsed ? collapsedWidth : (expandedWidth ?? 270.0);

    // Modal drawer geometry: 28dp radius on trailing edge (meeting the page body)
    final modalBorderRadius = isModal
        ? const BorderRadiusDirectional.horizontal(
            end: Radius.circular(28.0),
          ).resolve(Directionality.of(context))
        : null;

    final drawerContent = SafeArea(
      child: Column(
        crossAxisAlignment:
            isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          // 1. Header Slot
          if (header != null) header!,

          // 2. Scrollable Destinations Area
          Expanded(
            child: ListView(
              padding: padding,
              physics: const ClampingScrollPhysics(),
              children: destinations,
            ),
          ),

          // 3. Footer Slot (e.g. Profile Card)
          if (footer != null) ...[
            footer!,
            const SizedBox(height: 8.0),
          ],
        ],
      ),
    );

    if (isModal) {
      return Drawer(
        width: currentWidth,
        backgroundColor: effectiveBg,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: modalBorderRadius ?? BorderRadius.zero,
        ),
        child: drawerContent,
      );
    }

    return AnimatedContainer(
      duration: animationDuration,
      curve: animationCurve,
      width: currentWidth,
      color: effectiveBg,
      child: drawerContent,
    );
  }
}
