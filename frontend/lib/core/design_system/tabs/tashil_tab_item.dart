import 'package:flutter/material.dart';

/// Item model for Material Design 3 TabBar components.
class TashilTabItem {
  final String label;
  final IconData? icon;
  final Widget? badge;
  final String? count;

  const TashilTabItem({
    required this.label,
    this.icon,
    this.badge,
    this.count,
  });
}
