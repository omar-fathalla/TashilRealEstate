import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'tashil_alert_dialog.dart';
import 'tashil_modal_dialog.dart';
import 'tashil_selection_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Interactive showcase dialog demonstrating the official Material Design 3 Dialogs Suite:
/// 1. Basic / Alert Dialogs ([TashilAlertDialog])
/// 2. Confirmation Dialogs
/// 3. Option Selection Dialogs ([TashilSelectionDialog])
/// 4. Large Modal Dialogs ([TashilModalDialog])
class M3DialogsShowcaseDialog extends StatefulWidget {
  const M3DialogsShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3DialogsShowcaseDialog(),
    );
  }

  @override
  State<M3DialogsShowcaseDialog> createState() => _M3DialogsShowcaseDialogState();
}

class _M3DialogsShowcaseDialogState extends State<M3DialogsShowcaseDialog> {
  String _selectedCurrency = 'EGP';
  String? _lastDialogResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return TashilModalDialog(
          title: AppLocalizations.trStatic('uiCopy313'),
          subtitle: AppLocalizations.trStatic('uiCopy145'),
          icon: Symbols.window_rounded,
          maxWidth: 720,
          maxHeight: 750,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TashilButton(
                label: loc.tr('closeBtn'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Basic Alert Dialog Demo
                _buildDemoCard(
                  title: AppLocalizations.trStatic('uiCopy009'),
                  description: AppLocalizations.trStatic('uiCopy089'),
                  actionLabel: AppLocalizations.trStatic('uiCopy252'),
                  icon: Symbols.notifications_active_rounded,
                  theme: theme,
                  onPressed: () async {
                    await TashilAlertDialog.show(
                      context: context,
                      iconData: Symbols.info_rounded,
                      title: AppLocalizations.trStatic('uiCopy164'),
                      contentText: AppLocalizations.trStatic('uiCopy180'),
                      actions: [
                        TashilButton(
                          label: AppLocalizations.trStatic('uiCopy196'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                    setState(() => _lastDialogResult = AppLocalizations.trStatic('uiCopy175'));
                  },
                ),
                const SizedBox(height: 16),

                // 2. Confirmation Dialog Demo
                _buildDemoCard(
                  title: AppLocalizations.trStatic('uiCopy017'),
                  description: AppLocalizations.trStatic('uiCopy213'),
                  actionLabel: AppLocalizations.trStatic('uiCopy251'),
                  icon: Symbols.help_outline_rounded,
                  theme: theme,
                  onPressed: () async {
                    final confirmed = await TashilAlertDialog.showConfirmation(
                      context: context,
                      title: AppLocalizations.trStatic('uiCopy324'),
                      message: AppLocalizations.trStatic('uiCopy217'),
                      confirmLabel: AppLocalizations.trStatic('uiCopy321'),
                      cancelLabel: AppLocalizations.trStatic('uiCopy099'),
                      icon: Symbols.delete_outline_rounded,
                      isDestructive: true,
                    );
                    setState(() => _lastDialogResult = confirmed ? 'تم تأكيد الحذف بنجاح' : AppLocalizations.trStatic('uiCopy176'));
                  },
                ),
                const SizedBox(height: 16),

                // 3. Selection / Currency Picker Dialog Demo
                _buildDemoCard(
                  title: AppLocalizations.trStatic('uiCopy024'),
                  description: AppLocalizations.trStatic('uiCopy108'),
                  actionLabel: 'فتح محدد العملة (الحالية: $_selectedCurrency)',
                  icon: Symbols.payments_rounded,
                  theme: theme,
                  onPressed: () async {
                    final res = await TashilSelectionDialog.showCurrencyPicker(
                      context: context,
                      currentCurrency: _selectedCurrency,
                    );
                    if (res != null) {
                      setState(() {
                        _selectedCurrency = res;
                        _lastDialogResult = 'تم اختيار العملة: $res';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Result feedback banner
                if (_lastDialogResult != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Symbols.check_circle_rounded, color: theme.colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _lastDialogResult!,
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String description,
    required String actionLabel,
    required IconData icon,
    required ThemeData theme,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TashilButton.tonal(
            onPressed: onPressed,
            icon: icon,
            label: actionLabel,
          ),
        ],
      ),
    );
  }
}
