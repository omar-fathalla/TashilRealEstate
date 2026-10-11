import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/utils/image_utils.dart';

/// Custom ScrollBehavior that allows smooth dragging with mouse, touch, and stylus.
///
/// Note: PointerDeviceKind.trackpad is intentionally excluded from dragDevices because
/// trackpads are handled natively via PointerPanZoom events; including it causes
/// Flutter's DragGestureRecognizer to assert "!identical(kind, PointerDeviceKind.trackpad)".
class TashilCarouselScrollBehavior extends MaterialScrollBehavior {
  const TashilCarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
}

/// Official Material Design 3 (M3) Carousel component for Tashil Real Estate.
///
/// Implements Google Material Design 3 Carousel specifications:
/// 1. [TashilCarousel.hero]: Single focal item scrolling through one large photo at a time
///    with gentle snapping, end-peek, photo counter, and mouse/touch drag support.
/// 2. [TashilCarousel.multiBrowse]: Multi-item carousel that dynamically adapts item sizes
///    based on breakpoints (large, medium, small, peek).
/// 3. [TashilCarousel.uncontained]: Smooth horizontal carousel of uniform items.
class TashilCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final List<Widget>? children;
  final double height;
  final double? itemExtent;
  final List<int>? flexWeights;
  final BorderRadius? borderRadius;
  final bool showIndicator;
  final bool showArrows;
  final bool itemSnapping;
  final VoidCallback? onTap;
  final ValueChanged<int>? onIndexChanged;
  final Widget Function(BuildContext, String, int)? imageBuilder;

  /// Type 1: Hero Carousel (Single large item at a time with end peek & snap)
  const TashilCarousel.hero({
    super.key,
    required this.imageUrls,
    this.children,
    this.height = 220.0,
    this.itemExtent,
    this.borderRadius,
    this.showIndicator = true,
    this.showArrows = true,
    this.itemSnapping = true,
    this.onTap,
    this.onIndexChanged,
    this.imageBuilder,
  })  : flexWeights = null;

  /// Type 2: Multi-Browse Carousel (Multiple items adapting dynamically with weights)
  const TashilCarousel.multiBrowse({
    super.key,
    required this.imageUrls,
    this.children,
    this.height = 200.0,
    this.flexWeights = const [3, 3, 2, 1],
    this.borderRadius,
    this.showIndicator = false,
    this.showArrows = true,
    this.itemSnapping = true,
    this.onTap,
    this.onIndexChanged,
    this.imageBuilder,
  })  : itemExtent = null;

  /// Type 3: Uncontained Carousel
  const TashilCarousel.uncontained({
    super.key,
    required this.imageUrls,
    this.children,
    this.height = 180.0,
    required double this.itemExtent,
    this.borderRadius,
    this.showIndicator = false,
    this.showArrows = true,
    this.itemSnapping = false,
    this.onTap,
    this.onIndexChanged,
    this.imageBuilder,
  })  : flexWeights = null;

  @override
  State<TashilCarousel> createState() => _TashilCarouselState();
}

class _TashilCarouselState extends State<TashilCarousel> {
  late CarouselController _controller;
  int _currentIndex = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = CarouselController();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.hasClients) return;
    final total = _itemCount;
    if (total <= 1) return;

    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.position.pixels.clamp(0.0, maxScroll);
    final ratio = maxScroll > 0 ? (currentScroll / maxScroll) : 0.0;
    final newIndex = (ratio * (total - 1)).round().clamp(0, total - 1);

    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
      widget.onIndexChanged?.call(newIndex);
    }
  }

  int get _itemCount {
    if (widget.children != null && widget.children!.isNotEmpty) {
      return widget.children!.length;
    }
    return widget.imageUrls.length;
  }

  void _next() {
    if (_controller.hasClients) {
      final max = _controller.position.maxScrollExtent;
      final target = (_controller.offset + 280).clamp(0.0, max);
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previous() {
    if (_controller.hasClients) {
      final max = _controller.position.maxScrollExtent;
      final target = (_controller.offset - 280).clamp(0.0, max);
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final count = _itemCount;

    if (count == 0) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: radius,
        ),
        child: Center(
          child: Icon(Icons.photo_outlined, size: 40, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Build children widgets
    final items = List<Widget>.generate(count, (index) {
      Widget childWidget;
      if (widget.children != null && index < widget.children!.length) {
        childWidget = widget.children![index];
      } else if (widget.imageBuilder != null) {
        childWidget = widget.imageBuilder!(context, widget.imageUrls[index], index);
      } else {
        childWidget = ImageUtils.cachedImage(
          imageUrl: widget.imageUrls[index],
          fit: BoxFit.cover,
        );
      }

      final clipped = ClipRRect(
        borderRadius: radius,
        child: childWidget,
      );

      if (widget.onTap != null) {
        return InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          child: clipped,
        );
      }
      return clipped;
    });

    Widget carousel;

    // Use CarouselView.weighted if flexWeights provided, otherwise CarouselView
    if (widget.flexWeights != null && widget.flexWeights!.isNotEmpty) {
      carousel = CarouselView.weighted(
        controller: _controller,
        flexWeights: widget.flexWeights!,
        itemSnapping: widget.itemSnapping,
        shape: RoundedRectangleBorder(borderRadius: radius),
        children: items,
      );
    } else {
      carousel = LayoutBuilder(
        builder: (context, constraints) {
          // If itemExtent not specified, hero mode takes 90% of width to create standard M3 end-peek
          final calculatedExtent = widget.itemExtent ?? (constraints.maxWidth * 0.92);

          return CarouselView(
            controller: _controller,
            itemExtent: calculatedExtent,
            shrinkExtent: 40,
            itemSnapping: widget.itemSnapping,
            shape: RoundedRectangleBorder(borderRadius: radius),
            children: items,
          );
        },
      );
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        height: widget.height != double.infinity ? widget.height : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Core Material 3 Carousel with Drag Support
            ScrollConfiguration(
              behavior: const TashilCarouselScrollBehavior(),
              child: carousel,
            ),

            // 2. Navigation Arrow: Previous (Start side)
            if (widget.showArrows && count > 1 && (_isHovered || _currentIndex > 0))
              PositionedDirectional(
                top: 0,
                bottom: 0,
                start: 8,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered || _currentIndex > 0 ? 1.0 : 0.0,
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _previous,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                            color: theme.colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Navigation Arrow: Next (End side)
            if (widget.showArrows && count > 1 && (_isHovered || _currentIndex < count - 1))
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 8,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered || _currentIndex < count - 1 ? 1.0 : 0.0,
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _next,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 4. Photo Count Badge & Dots Indicator (Bottom Start)
            if (widget.showIndicator && count > 1)
              PositionedDirectional(
                bottom: 10,
                start: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, color: theme.colorScheme.onSurface, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentIndex + 1} / $count',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
