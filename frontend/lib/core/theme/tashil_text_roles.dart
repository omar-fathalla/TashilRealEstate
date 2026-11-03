import 'package:flutter/material.dart';

/// Maps a legacy fixed size onto the Material 3 text role that owns that size.
extension TashilTextRoles on TextTheme {
  TextStyle roleFor(double size) {
    if (size <= 11) return labelSmall ?? const TextStyle(fontSize: 11);
    if (size <= 12.5) return labelMedium ?? const TextStyle(fontSize: 12);
    if (size <= 14.5) return bodyMedium ?? const TextStyle(fontSize: 14);
    if (size <= 16.5) return titleMedium ?? const TextStyle(fontSize: 16);
    if (size <= 22) return titleLarge ?? const TextStyle(fontSize: 22);
    if (size <= 28) return headlineSmall ?? const TextStyle(fontSize: 24);
    if (size <= 32) return headlineMedium ?? const TextStyle(fontSize: 28);
    return headlineLarge ?? const TextStyle(fontSize: 32);
  }
}

/// Builds a text style from a Material 3 role, keeping color and weight.
TextStyle tashilText(
  TextTheme theme,
  double legacySize, {
  Color? color,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
  FontStyle? fontStyle,
  String? fontFamily,
  List<Shadow>? shadows,
  TextOverflow? overflow,
}) {
  return theme.roleFor(legacySize).copyWith(
        color: color,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
        fontStyle: fontStyle,
        fontFamily: fontFamily,
        shadows: shadows,
        overflow: overflow,
      );
}
