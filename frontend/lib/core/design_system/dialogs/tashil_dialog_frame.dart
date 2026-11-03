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
    final compact = MediaQuery.sizeOf(context).width < 600;
    if (compact) {
      final color = backgroundColor ?? Theme.of(context).colorScheme.surface;
      return Material(
        color: color,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
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
