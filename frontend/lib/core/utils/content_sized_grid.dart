import 'package:flutter/material.dart';

/// Grid that sizes each tile to its child instead of a fixed aspect ratio.
class ContentSizedGrid extends StatelessWidget {
  final double maxWidth;
  final int columns;
  final double spacing;
  final List<Widget> children;

  const ContentSizedGrid({
    super.key,
    required this.maxWidth,
    required this.columns,
    required this.spacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cols = columns < 1 ? 1 : columns;
    final tileWidth = cols == 1
        ? maxWidth
        : (maxWidth - spacing * (cols - 1)) / cols;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final child in children)
          SizedBox(width: tileWidth, child: child),
      ],
    );
  }
}
