import 'package:flutter/material.dart';
import '../design_system/loading/tashil_loading_indicator.dart';

class ImageUtils {
  static String resolveUrl(String url) {
    if (url.startsWith('assets/')) return url;
    if (url.contains('images.unsplash.com')) {
      if (url.contains('1502672260266')) return 'assets/images/properties/prop_eg_6_1.jpg';
      if (url.contains('1540518614846')) return 'assets/images/properties/prop_eg_6_2.jpg';
      if (url.contains('1556911220')) return 'assets/images/properties/prop_eg_6_3.jpg';
      if (url.contains('1545324418')) return 'assets/images/properties/prop_eg_5_1.jpg';
      if (url.contains('1584622650111')) return 'assets/images/properties/prop_eg_5_2.jpg';
      if (url.contains('1613977257363')) return 'assets/images/properties/prop_eg_2_1.jpg';
      if (url.contains('1600596542815')) return 'assets/images/properties/prop_eg_2_2.jpg';
      if (url.contains('1512917774080')) return 'assets/images/properties/prop_eg_2_3.jpg';
      if (url.contains('1580587771525')) return 'assets/images/properties/prop_eg_3_1.jpg';
      if (url.contains('1600585154340')) return 'assets/images/properties/prop_eg_4_1.jpg';
      if (url.contains('1613490493576')) return 'assets/images/properties/prop_eg_1_2.jpg';
      final index = (url.hashCode.abs() % 6) + 1;
      return 'assets/images/properties/prop_eg_${index}_1.jpg';
    }
    return url;
  }

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
    final resolvedUrl = resolveUrl(imageUrl);
    final isAsset = resolvedUrl.startsWith('assets/') || !resolvedUrl.startsWith('http');
    final Widget imageWidget = isAsset
        ? Image.asset(
            resolvedUrl.startsWith('assets/') ? resolvedUrl : 'assets/images/properties/$resolvedUrl',
            width: width,
            height: height,
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(context, width, height),
          )
        : Image.network(
            resolvedUrl,
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
              final fallbackAsset = 'assets/images/properties/prop_eg_${(resolvedUrl.hashCode.abs() % 6) + 1}_1.jpg';
              return Image.asset(
                fallbackAsset,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (c, e, s) => _buildErrorPlaceholder(context, width, height),
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

  static Widget _buildErrorPlaceholder(BuildContext context, double? width, double? height) {
    final theme = Theme.of(context);
    final isCompact = (height != null && height < 60) || (width != null && width < 60);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Center(
        child: isCompact
            ? Icon(Icons.apartment_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apartment_rounded, size: 32, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                ],
              ),
      ),
    );
  }
}
