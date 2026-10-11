import 'package:flutter/material.dart';

export 'tashil_rail_destination.dart';
export 'tashil_scaffold_canvas.dart';
export 'm3_rail_showcase_dialog.dart';

/// Official Material Design 3 (M3) Navigation Rail Container.
///
/// Implements Google Material Design 3 Navigation Rail specifications:
/// - Width: 80.0dp in Rail Mode, 260.0dp in Expanded Drawer Mode.
/// - Top Menu Toggle Button: Centered on the exact vertical track as the destination icons.
/// - Action FAB Slot: Squircle FAB (56x56dp) in Rail Mode, Extended FAB in Expanded Mode.
/// - Animated Transition: 250ms smooth cubic easing ([Curves.easeInOutCubic]).
/// - Footer Slot: Compact avatar in Rail Mode, full profile card in Expanded Mode.
///
/// References:
/// - https://m3.material.io/components/navigation-rail/overview
/// - https://m3.material.io/components/navigation-rail/specs
/// - https://m3.material.io/components/navigation-rail/guidelines
class TashilNavigationRail extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final String menuTooltip;
  final Widget? actionFab;
  final List<Widget> destinations;
  final Widget? footer;
  final double railWidth;
  final double expandedWidth;
  final Color? backgroundColor;
  final Duration animationDuration;
  final Curve animationCurve;

  const TashilNavigationRail({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.menuTooltip,
    this.actionFab,
    required this.destinations,
    this.footer,
    this.railWidth = 80.0,
    this.expandedWidth = 260.0,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentWidth = isExpanded ? expandedWidth : railWidth;

    final effectiveBg = backgroundColor ?? Colors.transparent;

    return AnimatedContainer(
      duration: animationDuration,
      curve: animationCurve,
      width: currentWidth,
      height: double.infinity,
      color: effectiveBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
              isExpanded ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8.0),

            // 1. Top Menu Toggle Button: Perfectly Aligned With Destination Icons!
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16.0,
                top: 4.0,
                bottom: 4.0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  tooltip: menuTooltip,
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                    size: 24.0,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    fixedSize: const Size(48.0, 48.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Optional Quick Action FAB
            if (actionFab != null) ...[
              const SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 16.0 : 12.0,
                ),
                child: actionFab!,
              ),
              const SizedBox(height: 12.0),
            ] else ...[
              const SizedBox(height: 6.0),
            ],

            // 3. Scrollable Destinations Column
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  vertical: isExpanded ? 6.0 : 4.0,
                ),
                physics: const ClampingScrollPhysics(),
                children: destinations,
              ),
            ),

            // 4. Footer Slot (User Profile Card / Avatar)
            if (footer != null) ...[
              footer!,
              const SizedBox(height: 10.0),
            ],
          ],
        ),
      ),
    );
  }
}
