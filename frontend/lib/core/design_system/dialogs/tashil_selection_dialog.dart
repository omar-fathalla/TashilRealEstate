import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

/// Item model for M3 Selection Dialog options.
class TashilSelectionOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final IconData? icon;

  const TashilSelectionOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.icon,
  });
}

/// Official Material Design 3 (M3) Option Selection / Picker Dialog.
///
/// Implements Google Material Design 3 Dialog specifications:
/// - Container corner radius: 28dp (shape.corner.extra_large)
/// - Container elevation: Level 3 (3dp)
/// - Background: colorScheme.surfaceContainerHigh
/// - Smooth interactive radio / checkmark selection
/// - End-aligned M3 cancel button
///
/// Reference: https://m3.material.io/components/dialogs/overview
class TashilSelectionDialog<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<TashilSelectionOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T> onSelected;
  final double borderRadius;
  final double elevation;

  const TashilSelectionDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.options,
    this.selectedValue,
    required this.onSelected,
    this.borderRadius = 28.0,
    this.elevation = 3.0,
  });

  /// Static helper to display the selection dialog and return the chosen value
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    required List<TashilSelectionOption<T>> options,
    T? selectedValue,
  }) {
    return TashilTransitions.showM3Dialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TashilSelectionDialog<T>(
        title: title,
        subtitle: subtitle,
        icon: icon,
        options: options,
        selectedValue: selectedValue,
        onSelected: (val) => Navigator.of(ctx).pop(val),
      ),
    );
  }

  /// Convenience picker for currencies (EGP, AED, USD) with country flags and M3 styling
  static Future<String?> showCurrencyPicker({
    required BuildContext context,
    required String currentCurrency,
    String? title,
  }) {
    return show<String>(
      context: context,
      title: title ?? 'اختيار العملة النقدية',
      icon: Icons.payments_rounded,
      selectedValue: currentCurrency,
      options: const [
        TashilSelectionOption<String>(
          value: 'EGP',
          label: 'ج.م (جنيه مصري)',
          subtitle: 'جمهورية مصر العربية 🇪🇬',
          leading: Text('🇪🇬', style: TextStyle(fontSize: 22)),
        ),
        TashilSelectionOption<String>(
          value: 'AED',
          label: 'د.إ (درهم إماراتي)',
          subtitle: 'الإمارات العربية المتحدة 🇦🇪',
          leading: Text('🇦🇪', style: TextStyle(fontSize: 22)),
        ),
        TashilSelectionOption<String>(
          value: 'USD',
          label: '\$ (دولار أمريكي)',
          subtitle: 'الولايات المتحدة الأمريكية 🇺🇸',
          leading: Text('🇺🇸', style: TextStyle(fontSize: 22)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      elevation: elevation,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colorScheme.outlineVariant),
              const SizedBox(height: 8),

              // Options List
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((opt) {
                      final isSelected = opt.value == selectedValue;

                      return Material(
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => onSelected(opt.value),
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: colorScheme.primary.withValues(alpha: 0.08),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                if (opt.leading != null) ...[
                                  opt.leading!,
                                  const SizedBox(width: 12),
                                ] else if (opt.icon != null) ...[
                                  Icon(
                                    opt.icon,
                                    size: 20,
                                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        opt.label,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (opt.subtitle != null)
                                        Text(
                                          opt.subtitle!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  )
                                else
                                  Icon(
                                    Icons.radio_button_unchecked_rounded,
                                    color: colorScheme.outlineVariant,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TashilButton.text(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
