import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

/// Official Material Design 3 (M3) Basic & Alert Dialog for Tashil Real Estate.
///
/// Implements Google Material Design 3 Dialog specifications:
/// - Container corner radius: 28dp (shape.corner.extra_large)
/// - Container elevation: Level 3 (3dp tonal shadow)
/// - Container color: colorScheme.surfaceContainerHigh
/// - Optional top icon: 24dp (secondary or primary)
/// - Headline typography: headlineSmall (24sp)
/// - Supporting text typography: bodyMedium (14sp, onSurfaceVariant)
/// - Actions padding: 24dp horizontal & bottom, 8dp gap between buttons
/// - Responsive RTL/LTR directional layout
///
/// Reference: https://m3.material.io/components/dialogs/overview
class TashilAlertDialog extends StatelessWidget {
  final Widget? icon;
  final IconData? iconData;
  final String? title;
  final Widget? titleWidget;
  final String? contentText;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsets? insetPadding;
  final double borderRadius;
  final double elevation;
  final Color? backgroundColor;
  final bool isDismissible;

  const TashilAlertDialog({
    super.key,
    this.icon,
    this.iconData,
    this.title,
    this.titleWidget,
    this.contentText,
    this.content,
    this.actions,
    this.insetPadding,
    this.borderRadius = 28.0,
    this.elevation = 3.0,
    this.backgroundColor,
    this.isDismissible = true,
  });

  /// Static helper to display the M3 Alert Dialog
  static Future<T?> show<T>({
    required BuildContext context,
    IconData? iconData,
    Widget? icon,
    String? title,
    Widget? titleWidget,
    String? contentText,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return TashilTransitions.showM3Dialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => TashilAlertDialog(
        iconData: iconData,
        icon: icon,
        title: title,
        titleWidget: titleWidget,
        contentText: contentText,
        content: content,
        actions: actions,
        isDismissible: barrierDismissible,
      ),
    );
  }

  /// Convenience factory for a standard M3 Confirmation dialog (Cancel / Confirm)
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    IconData? icon = Icons.help_outline_rounded,
    bool isDestructive = false,
  }) async {
    final result = await show<bool>(
      context: context,
      iconData: icon,
      title: title,
      contentText: message,
      actions: [
        TashilButton.text(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TashilButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          customColor: isDestructive ? Theme.of(context).colorScheme.error : null,
          variant: isDestructive ? TashilButtonVariant.filled : TashilButtonVariant.tonal,
        ),
      ],
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final resolvedBg = backgroundColor ?? colorScheme.surfaceContainerHigh;

    Widget? resolvedIcon;
    if (icon != null) {
      resolvedIcon = icon;
    } else if (iconData != null) {
      resolvedIcon = Icon(
        iconData,
        size: 24.0,
        color: colorScheme.secondary,
      );
    }

    Widget? resolvedTitle;
    if (titleWidget != null) {
      resolvedTitle = titleWidget;
    } else if (title != null) {
      resolvedTitle = Text(
        title!,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        textAlign: resolvedIcon != null ? TextAlign.center : TextAlign.start,
      );
    }

    Widget? resolvedContent;
    if (content != null) {
      resolvedContent = content;
    } else if (contentText != null) {
      resolvedContent = Text(
        contentText!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
        textAlign: resolvedIcon != null ? TextAlign.center : TextAlign.start,
      );
    }

    return Dialog(
      backgroundColor: resolvedBg,
      elevation: elevation,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 24.0,
            end: 24.0,
            top: 24.0,
            bottom: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: resolvedIcon != null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              // 1. Optional M3 Top Icon
              if (resolvedIcon != null) ...[
                resolvedIcon,
                const SizedBox(height: 16.0),
              ],

              // 2. M3 Headline
              if (resolvedTitle != null) ...[
                resolvedTitle,
                const SizedBox(height: 16.0),
              ],

              // 3. Supporting Content / Body
              if (resolvedContent != null) ...[
                Flexible(
                  child: SingleChildScrollView(
                    child: resolvedContent,
                  ),
                ),
                const SizedBox(height: 24.0),
              ],

              // 4. Action Buttons (End-aligned, 8dp spacing)
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!.map((action) {
                    final index = actions!.indexOf(action);
                    return Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: index > 0 ? 8.0 : 0.0,
                      ),
                      child: action,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
