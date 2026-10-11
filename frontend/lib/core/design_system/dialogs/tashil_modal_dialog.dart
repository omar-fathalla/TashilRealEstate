import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';


/// Official Material Design 3 (M3) Large / Full-Screen Modal Dialog for Tashil Real Estate.
///
/// Implements Google Material Design 3 Large Dialog specifications:
/// - Container corner radius: 28dp on tablet/desktop (shape.corner.extra_large), adaptive on mobile
/// - Container elevation: Level 3 (3dp tonal shadow)
/// - Container color: colorScheme.surfaceContainerHigh or surface
/// - Structured M3 header: leading icon container, headline title, supporting subtitle, close icon button
/// - Scrollable body with custom constraints
/// - Pinned action footer with M3 buttons
/// - Responsive RTL/LTR directionality support
///
/// Reference: https://m3.material.io/components/dialogs/overview
class TashilModalDialog extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? headerLeading;
  final Widget? footer;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback? onClose;
  final double borderRadius;
  final double elevation;
  final Color? backgroundColor;

  const TashilModalDialog({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.icon,
    this.headerLeading,
    this.footer,
    this.maxWidth = 840.0,
    this.maxHeight = 880.0,
    this.onClose,
    this.borderRadius = 28.0,
    this.elevation = 3.0,
    this.backgroundColor,
  });

  /// Static helper to display the M3 Modal Dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? headerLeading,
    Widget? footer,
    double maxWidth = 840.0,
    double maxHeight = 880.0,
    bool barrierDismissible = true,
  }) {
    return TashilTransitions.showM3Dialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => TashilModalDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        headerLeading: headerLeading,
        footer: footer,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        onClose: () => Navigator.of(ctx).pop(),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);

    final resolvedBg = backgroundColor ?? colorScheme.surface;
    final effectiveRadius = isMobile ? 20.0 : borderRadius;

    return Dialog(
      backgroundColor: resolvedBg,
      elevation: elevation,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveRadius),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 36.0,
        vertical: isMobile ? 16.0 : 28.0,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. M3 Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (headerLeading != null) ...[
                          headerLeading!,
                          const SizedBox(width: 12.0),
                        ] else if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              icon,
                              color: colorScheme.onPrimaryContainer,
                              size: 22.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
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
                                  fontSize: 16.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 2.0),
                                Text(
                                  subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12.0,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TashilIconButton.close(
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(height: 20.0, color: colorScheme.outlineVariant),

              // 2. Scrollable Body Content
              Expanded(
                child: child,
              ),

              // 3. Optional Pinned Action Footer
              if (footer != null) ...[
                const SizedBox(height: 16.0),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
