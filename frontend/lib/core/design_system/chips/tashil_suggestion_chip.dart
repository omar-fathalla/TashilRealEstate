import 'package:flutter/material.dart';
import 'tashil_assist_chip.dart';

/// Official Material Design 3 (M3) Suggestion Chip component for Tashil Real Estate.
///
/// Implements Google Material Design 3 Suggestion Chip specification:
/// - Container height: 32dp
/// - Corner radius: 8dp (M3 shape.corner.small)
/// - Provides dynamic recommendations, autocomplete suggestions, or AI quick-prompts
/// - Outlined and Elevated variants
/// - Native RTL/LTR directionality support
///
/// Reference: https://m3.material.io/components/chips/overview
class TashilSuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final TashilChipVariant variant;
  final bool isElevated;
  final String? tooltip;
  final double height;
  final double borderRadius;

  const TashilSuggestionChip({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.variant = TashilChipVariant.outlined,
    this.isElevated = false,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
  });

  const TashilSuggestionChip.elevated({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.tooltip,
    this.height = 32.0,
    this.borderRadius = 8.0,
  })  : variant = TashilChipVariant.elevated,
        isElevated = true;

  @override
  Widget build(BuildContext context) {
    return TashilAssistChip(
      label: label,
      onPressed: onPressed,
      icon: icon,
      leading: leading,
      variant: isElevated ? TashilChipVariant.elevated : variant,
      tooltip: tooltip,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
