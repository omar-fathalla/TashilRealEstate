import 'package:flutter/material.dart';
import 'tashil_motion.dart';

/// Official Google Material Design 3 (M3) Filtered Card List Motion Component.
///
/// Implements fluid, expressive transitions when filtering cards across categories:
/// 1. Staggered Cascading Entrance for incoming items (35ms index delay, 280ms duration).
/// 2. Smooth Height Resizing via [AnimatedSize] to eliminate solid/abrupt layout jumps.
/// 3. Cross-fade & subtle spatial slide (Y-axis 18dp) adhering to [TashilMotionEasing.emphasizedDecelerate].
/// 4. Graceful empty state transitions.
class TashilCardFilterMotion<T> extends StatelessWidget {
  final List<T> items;
  final String filterKey;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyState;
  final double spacing;
  final Duration switchDuration;
  final Duration itemDuration;
  final Duration staggerDelay;
  final double slideOffset;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  const TashilCardFilterMotion({
    super.key,
    required this.items,
    required this.filterKey,
    required this.itemBuilder,
    this.emptyState,
    this.spacing = 16.0,
    this.switchDuration = TashilMotionDuration.medium2,
    this.itemDuration = const Duration(milliseconds: 280),
    this.staggerDelay = const Duration(milliseconds: 35),
    this.slideOffset = 18.0,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: TashilMotionDuration.medium2,
      curve: TashilMotionEasing.emphasized,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: switchDuration,
        switchInCurve: TashilMotionEasing.emphasizedDecelerate,
        switchOutCurve: TashilMotionEasing.emphasizedAccelerate,
        transitionBuilder: (child, animation) {
          final isIncoming = animation.status != AnimationStatus.reverse;
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: isIncoming
                ? TashilMotionEasing.emphasizedDecelerate
                : TashilMotionEasing.emphasizedAccelerate,
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
        child: items.isEmpty
            ? KeyedSubtree(
                key: ValueKey('empty_filter_$filterKey'),
                child: emptyState ?? const SizedBox.shrink(),
              )
            : KeyedSubtree(
                key: ValueKey('filter_cards_${filterKey}_${items.length}'),
                child: ListView.separated(
                  key: ValueKey('list_view_$filterKey'),
                  shrinkWrap: shrinkWrap,
                  physics: physics,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: spacing),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return TashilStaggeredEntrance(
                      key: ValueKey('stagger_${filterKey}_${item.hashCode}_$index'),
                      index: index,
                      delayStep: staggerDelay,
                      duration: itemDuration,
                      slideOffset: slideOffset,
                      child: itemBuilder(context, item, index),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
