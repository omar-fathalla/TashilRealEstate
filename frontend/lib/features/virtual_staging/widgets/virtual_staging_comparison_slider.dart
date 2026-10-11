import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/image_utils.dart';

class VirtualStagingComparisonSlider extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final double height;

  const VirtualStagingComparisonSlider({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.height = 420,
  });

  @override
  State<VirtualStagingComparisonSlider> createState() =>
      _VirtualStagingComparisonSliderState();
}

class _VirtualStagingComparisonSliderState
    extends State<VirtualStagingComparisonSlider> {
  double _sliderPosition = 0.5; // 0.0 (full before) to 1.0 (full after)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final splitX = totalWidth * _sliderPosition;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.height,
            width: totalWidth,
            child: Stack(
              children: [
                // Layer 1: After Image (Virtually Staged - Full Width Underneath)
                Positioned.fill(
                  child: ImageUtils.cachedImage(
                    imageUrl: widget.afterImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),

                // Layer 2: Before Image (Empty / Vacant - Clipped from left to splitX)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: splitX.clamp(0.0, totalWidth),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxWidth: totalWidth,
                      maxHeight: widget.height,
                      child: ImageUtils.cachedImage(
                        imageUrl: widget.beforeImageUrl,
                        width: totalWidth,
                        height: widget.height,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Layer 3: Vertical Divider Line
                Positioned(
                  left: splitX - 1.5,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: theme.colorScheme.surface,
                  ),
                ),

                // Layer 4: Dragger Handle in the center of the divider
                Positioned(
                  left: splitX - 20,
                  top: (widget.height / 2) - 20,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        final newPos = (details.globalPosition.dx) / totalWidth;
                        _sliderPosition = newPos.clamp(0.05, 0.95);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // Layer 5: Label Badge Top-Left (Before / Empty)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 12, color: theme.colorScheme.onSurface),
                        const SizedBox(width: 5),
                        Text(
                          loc.tr('beforeStagingEmpty'),
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

                // Layer 6: Label Badge Top-Right (After / Staged)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 5),
                        Text(
                          loc.tr('afterStagingAi'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Gesture detector over entire area for smooth click-to-move
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localOffset = box.globalToLocal(details.globalPosition);
                      setState(() {
                        _sliderPosition = (localOffset.dx / totalWidth).clamp(0.05, 0.95);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
