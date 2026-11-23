import 'package:flutter/material.dart';

import '../buttons/tashil_button.dart';

/// Material Design 3 empty state: a tonal icon badge, a headline, a short explanation and
/// up to two actions. Actions use 48dp touch targets and the layout is direction-agnostic,
/// so it reads correctly in RTL and LTR.
class TashilEmptyState extends StatelessWidget {
  const TashilEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: colorScheme.secondaryContainer, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (primaryActionLabel != null) ...[
                const SizedBox(height: 24),
                TashilButton.filled(
                  label: primaryActionLabel!,
                  icon: primaryActionIcon,
                  height: 48,
                  onPressed: onPrimaryAction,
                ),
              ],
              if (secondaryActionLabel != null) ...[
                const SizedBox(height: 8),
                TashilButton.text(
                  label: secondaryActionLabel!,
                  height: 48,
                  onPressed: onSecondaryAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
