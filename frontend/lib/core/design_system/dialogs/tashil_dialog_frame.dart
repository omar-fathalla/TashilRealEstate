import 'package:flutter/material.dart';

/// Dialog chrome on expanded windows, plain sheet content on a phone.
///
/// Compact routes already present a bottom sheet or a full-screen page.
/// Wrapping that content in [Dialog] adds inset padding and a floating card
/// with an empty gap above it.
class TashilDialogFrame extends StatelessWidget {
  final Widget? child;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final EdgeInsets? insetPadding;
  final Clip clipBehavior;
  final BoxConstraints? constraints;

  const TashilDialogFrame({
    super.key,
    this.child,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.alignment,
    this.insetPadding,
    this.clipBehavior = Clip.none,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    if (compact) {
      final color = backgroundColor ?? Theme.of(context).colorScheme.surface;
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: color,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            height: MediaQuery.sizeOf(context).height,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
    }
    return Dialog(
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
      alignment: alignment,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      constraints: constraints,
      child: child,
    );
  }
}
