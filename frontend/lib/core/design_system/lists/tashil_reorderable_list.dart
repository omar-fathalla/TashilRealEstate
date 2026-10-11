import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_divider.dart';

/// Reorderable List item builder signature with index and typed data.
typedef TashilReorderableItemBuilder<T> = Widget Function(
  BuildContext context,
  int index,
  T item,
);

/// Dedicated Material Design 3 Drag Handle for Reorderable Lists.
///
/// Enables instant mouse drag on Web / Desktop without long-press delay,
/// and smooth touch dragging on mobile devices.
class TashilReorderHandle extends StatelessWidget {
  /// The index of the item this handle is attached to.
  final int index;

  /// Custom icon for the handle. Defaults to [Icons.drag_indicator_rounded].
  final IconData icon;

  /// Optional tooltip string explaining the drag action.
  final String? tooltip;

  /// Size of the handle container. Defaults to 36dp.
  final double size;

  /// Size of the icon. Defaults to 20dp.
  final double iconSize;

  /// Whether dragging is enabled.
  final bool enabled;

  const TashilReorderHandle({
    super.key,
    required this.index,
    this.icon = Icons.drag_indicator_rounded,
    this.tooltip,
    this.size = 36.0,
    this.iconSize = 20.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final handleWidget = MouseRegion(
      cursor: enabled ? SystemMouseCursors.grab : SystemMouseCursors.basic,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: enabled
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
              : colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );

    final wrappedHandle = tooltip != null
        ? Tooltip(message: tooltip!, child: handleWidget)
        : handleWidget;

    if (!enabled) return wrappedHandle;

    // ReorderableDragStartListener allows immediate mouse drag on desktop
    // and touch drag on mobile!
    return ReorderableDragStartListener(
      index: index,
      child: wrappedHandle,
    );
  }
}

/// Official Material Design 3 Reorderable List Container for Tashil Real Estate.
///
/// Fully adheres to:
/// - https://m3.material.io/components/lists/guidelines
/// - https://m3.material.io/components/lists/specs
///
/// Highlights:
/// 1. Instant Desktop Mouse Drag & Mobile Touch Hold support.
/// 2. Official M3 Elevation Level 3 floating proxy decorator with squircle corners.
/// 3. Inset or full-width M3 divider integration.
/// 4. Automatic RTL / LTR directionality awareness.
class TashilReorderableList<T> extends StatelessWidget {
  /// The list of items to display.
  final List<T> items;

  /// Builder for each list item. Each child MUST have a unique [Key] provided by the builder.
  final TashilReorderableItemBuilder<T> itemBuilder;

  /// Callback when an item is moved from [oldIndex] to [newIndex].
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Whether to show subtle M3 dividers between items. Defaults to true.
  final bool showDividers;

  /// Indent for inset dividers (e.g. 72dp aligning with text after thumbnails).
  final double dividerStartIndent;

  /// Whether to shrink-wrap the list when embedded in another scrollable container.
  final bool shrinkWrap;

  /// Custom scroll physics.
  final ScrollPhysics? physics;

  /// Container padding around the list.
  final EdgeInsets? padding;

  /// Widget displayed when [items] is empty.
  final Widget? emptyWidget;

  /// Optional header widget placed above all items.
  final Widget? header;

  /// Optional footer widget placed below all items.
  final Widget? footer;

  /// Whether to build Flutter's default drag handle on items. Defaults to false.
  final bool buildDefaultDragHandles;

  const TashilReorderableList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.buildDefaultDragHandles = false,
    this.showDividers = true,
    this.dividerStartIndent = 0.0,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.emptyWidget,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      itemCount: items.length,
      buildDefaultDragHandles: buildDefaultDragHandles,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? EdgeInsets.zero,
      header: header,
      footer: footer,
      onReorderItem: onReorder,
      // Official M3 Floating Card Proxy Decorator
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final elevation = 2.0 + (animValue * 6.0); // Lift to M3 Level 3

            return Transform.scale(
              scale: 1.0 + (animValue * 0.015), // Micro tactile scale
              child: Material(
                elevation: elevation,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.35),
                color: colorScheme.surfaceContainerHigh,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3 * animValue),
                    width: 1.5,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final itemWidget = itemBuilder(context, index, item);

        final isLast = index == items.length - 1;

        if (!showDividers || isLast) {
          return itemWidget;
        }

        // Interleaved with M3 Inset or Full-width Divider with guaranteed unique wrapper key
        final itemKey = itemWidget.key ?? ValueKey<int>(index);
        return KeyedSubtree(
          key: ValueKey<String>('tashil_reorder_item_wrap_${itemKey.hashCode}_$index'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              itemWidget,
              TashilDivider.inset(
                startIndent: dividerStartIndent,
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        );
      },
    );
  }
}
