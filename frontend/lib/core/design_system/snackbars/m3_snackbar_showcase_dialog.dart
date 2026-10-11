import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../theme/theme_palette_controller.dart';
import '../buttons/tashil_buttons.dart';
import '../dialogs/tashil_dialogs.dart';
import '../dividers/tashil_dividers.dart';
import 'tashil_snackbars.dart';

/// Interactive showcase dialog allowing visual inspection and live testing of the
/// Google Material Design 3 (M3) SnackBar Suite across all 4 tones, actions,
/// close affordances, and the 5 active seed color palettes.
class M3SnackbarShowcaseDialog extends StatelessWidget {
  const M3SnackbarShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => const M3SnackbarShowcaseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return TashilModalDialog(
      title: loc.tr('m3SnackbarShowcase'),
      subtitle: loc.tr('m3SnackbarSubtitle'),
      icon: Icons.notifications_active_outlined,
      maxWidth: 680,
      footer: TashilButton(
        label: loc.tr('close'),
        icon: Icons.check_rounded,
        variant: TashilButtonVariant.filled,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Live Interactive Trigger Buttons (Tones & Configurations)
            Text(
              loc.tr('interactiveStates'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Tone 1: Success (Copied Link / Listing Saved)
            _buildShowcaseRow(
              context: context,
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF10B981),
              title: loc.tr('snackbarSuccessDemo'),
              description: loc.tr('snackbarRuleDynamicPalette'),
              actionLabel: loc.tr('snackbarUndo'),
              onTrigger: () {
                TashilSnackBar.showSuccess(
                  context: context,
                  message: loc.tr('linkCopiedSuccess'),
                  action: TashilSnackBarAction(
                    label: loc.tr('snackbarUndo'),
                    onPressed: () {},
                  ),
                  showCloseIcon: true,
                );
              },
            ),
            const SizedBox(height: 10),

            // Tone 2: Error (Connection failure with Retry & Close)
            _buildShowcaseRow(
              context: context,
              icon: Icons.error_outline_rounded,
              iconColor: colorScheme.error,
              title: loc.tr('snackbarErrorDemo'),
              description: loc.tr('snackbarRuleMaxOneAction'),
              actionLabel: loc.tr('snackbarRetry'),
              onTrigger: () {
                TashilSnackBar.showError(
                  context: context,
                  title: loc.tr('errorTitle'),
                  message: loc.tr('snackbarErrorDemo'),
                  action: TashilSnackBarAction(
                    label: loc.tr('snackbarRetry'),
                    onPressed: () {},
                  ),
                  showCloseIcon: true,
                );
              },
            ),
            const SizedBox(height: 10),

            // Tone 3: Warning (Expiring session)
            _buildShowcaseRow(
              context: context,
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: loc.tr('snackbarWarningDemo'),
              description: loc.tr('snackbarRuleNoStacking'),
              actionLabel: loc.tr('snackbarView'),
              onTrigger: () {
                TashilSnackBar.showWarning(
                  context: context,
                  message: loc.tr('snackbarWarningDemo'),
                  action: TashilSnackBarAction(
                    label: loc.tr('snackbarView'),
                    onPressed: () {},
                  ),
                  showCloseIcon: false,
                );
              },
            ),
            const SizedBox(height: 10),

            // Tone 4: Info (Property data updated)
            _buildShowcaseRow(
              context: context,
              icon: Icons.info_outline_rounded,
              iconColor: colorScheme.primary,
              title: loc.tr('snackbarInfoDemo'),
              description: loc.tr('snackbarRuleResponsiveWidth'),
              actionLabel: null,
              onTrigger: () {
                TashilSnackBar.showInfo(
                  context: context,
                  title: loc.tr('refreshDataBtn'),
                  message: loc.tr('snackbarInfoDemo'),
                  showCloseIcon: true,
                );
              },
            ),

            const SizedBox(height: 20),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 16),

            // 2. Active Seed Palette Testing Section
            Text(
              loc.tr('m3SystemTokens'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.tr('snackbarRuleDynamicPalette'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // 5 Theme Palettes Switcher
            ValueListenableBuilder<M3ThemePalette>(
              valueListenable: ThemePaletteController.instance.currentPalette,
              builder: (context, activePalette, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: M3ThemePalette.values.map((palette) {
                    final isSelected = palette == activePalette;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: CircleAvatar(
                        backgroundColor: palette.color,
                        radius: 8,
                      ),
                      label: Text(
                        palette.getLocalizedName(loc.locale.languageCode),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                        ),
                      ),
                      selectedColor: colorScheme.primaryContainer,
                      onSelected: (selected) {
                        if (selected) {
                          ThemePaletteController.instance.setPalette(palette);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 16),

            // 3. Official Google M3 Specifications & Guidelines Rules
            Text(
              loc.tr('snackbarSpecsHeading'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecRule(
              context: context,
              number: '1',
              ruleText: loc.tr('snackbarRuleMaxOneAction'),
              isDo: true,
            ),
            const SizedBox(height: 8),
            _buildSpecRule(
              context: context,
              number: '2',
              ruleText: loc.tr('snackbarRuleResponsiveWidth'),
              isDo: true,
            ),
            const SizedBox(height: 8),
            _buildSpecRule(
              context: context,
              number: '3',
              ruleText: loc.tr('snackbarRuleNoStacking'),
              isDo: true,
            ),
            const SizedBox(height: 8),
            _buildSpecRule(
              context: context,
              number: '4',
              ruleText: loc.tr('snackbarRuleDynamicPalette'),
              isDo: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String? actionLabel,
    required VoidCallback onTrigger,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TashilButton(
            label: loc.tr('preview'),
            icon: Icons.play_arrow_rounded,
            variant: TashilButtonVariant.tonal,
            onPressed: onTrigger,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRule({
    required BuildContext context,
    required String number,
    required String ruleText,
    required bool isDo,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDo
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : colorScheme.error.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDo ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: isDo ? const Color(0xFF10B981) : colorScheme.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            ruleText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
