import 'package:flutter/material.dart';

/// Colors for large hero and promo bands.
///
/// In a dark [ColorScheme], `primary` is a light accent. Painting it across a
/// hero turns the band pale. Dark bands use [ColorScheme.surfaceContainer] and
/// [ColorScheme.primaryContainer] so they sit with the rest of the dark surfaces.
class TashilBannerColors {
  const TashilBannerColors._();

  static List<Color> gradient(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return [scheme.surfaceContainer, scheme.primaryContainer];
    }
    return [
      scheme.primary,
      Color.alphaBlend(scheme.primary.withValues(alpha: 0.8), scheme.onSurface),
    ];
  }

  static Color foreground(ColorScheme scheme) => scheme.brightness == Brightness.dark
      ? scheme.onPrimaryContainer
      : scheme.onPrimary;

  static Color muted(ColorScheme scheme) => foreground(scheme).withValues(alpha: 0.78);
}
