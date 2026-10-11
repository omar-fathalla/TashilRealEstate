import 'package:flutter/material.dart';
import '../design_system/loading/tashil_loading_indicator.dart';

class ImageUtils {
  /// Builds a memory-optimized network image with defined cache dimensions
  static Widget cachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    int? cacheWidth = 600,
    int? cacheHeight = 400,
    BorderRadius? borderRadius,
  }) {
    final imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final theme = Theme.of(context);
        return Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          child: Center(
            child: TashilLoadingIndicator.small(
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        final theme = Theme.of(context);
        final isCompact = (height != null && height < 60) || (width != null && width < 60);
        return Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHigh,
          child: Center(
            child: isCompact
                ? Icon(Icons.broken_image_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
