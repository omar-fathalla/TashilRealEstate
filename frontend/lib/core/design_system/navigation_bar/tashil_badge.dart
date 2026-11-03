import 'package:flutter/material.dart';

/// Official Material Design 3 (M3) Badge Component for Tashil Real Estate.
///
/// Conforms strictly to Google Material Design 3 specifications:
/// - https://m3.material.io/components/badges/overview
/// - https://m3.material.io/components/badges/specs
///
/// Types:
/// 1. **Small Badge (Dot)**:
///    A 6dp circular status dot anchored at the upper trailing edge of an icon.
/// 2. **Large Badge (Label / Count)**:
///    A 16dp tall pill shape containing up to 4 characters (e.g. "AI", "99+", "جديد").
class TashilBadge extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool hasDot;
  final Color? backgroundColor;
  final Color? textColor;
  final double offsetTop;
  final double offsetEnd;

  const TashilBadge({
    super.key,
    required this.child,
    this.label,
    this.hasDot = false,
    this.backgroundColor,
    this.textColor,
    this.offsetTop = -2.0,
    this.offsetEnd = -4.0,
  });

  /// Factory for a small dot badge (notification indicator).
  const TashilBadge.dot({
    super.key,
    required this.child,
    this.backgroundColor,
    this.offsetTop = -1.0,
    this.offsetEnd = -2.0,
  })  : label = null,
        hasDot = true,
        textColor = null;

  /// Factory for a large label/count badge (e.g. AI or numbers).
  const TashilBadge.label({
    super.key,
    required this.child,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.offsetTop = -4.0,
    this.offsetEnd = -8.0,
  }) : hasDot = false;

  @override
  Widget build(BuildContext context) {
    if (!hasDot && (label == null || label!.isEmpty)) {
      return child;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBg = backgroundColor ?? colorScheme.error;
    final effectiveTextColor = textColor ?? colorScheme.onError;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        PositionedDirectional(
          top: offsetTop,
          end: offsetEnd,
          child: hasDot
              // Small M3 Dot Badge (6dp circular)
              ? Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: effectiveBg,
                    shape: BoxShape.circle,
                  ),
                )
              // Large M3 Label Badge (16dp stadium capsule)
              : Container(
                  height: 16.0,
                  constraints: const BoxConstraints(minWidth: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: effectiveBg,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label!,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: effectiveTextColor,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      letterSpacing: -0.2),
                  ),
                ),
        ),
      ],
    );
  }
}
