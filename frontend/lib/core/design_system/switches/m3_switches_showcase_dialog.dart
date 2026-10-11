import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../localization/locale_controller.dart';
import '../buttons/tashil_buttons.dart';
import '../dividers/tashil_dividers.dart';
import 'tashil_switch.dart';

/// Interactive showcase dialog displaying the Official Google Material Design 3 Switches Suite.
///
/// Conforms to:
/// - https://m3.material.io/components/switch/specs
/// - https://m3.material.io/components/switch/guidelines
class M3SwitchesShowcaseDialog extends StatefulWidget {
  const M3SwitchesShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3SwitchesShowcaseDialog(),
    );
  }

  @override
  State<M3SwitchesShowcaseDialog> createState() => _M3SwitchesShowcaseDialogState();
}

class _M3SwitchesShowcaseDialogState extends State<M3SwitchesShowcaseDialog> {
  // State variables for various switch configurations
  bool _wifiSelected = true;
  bool _bluetoothSelected = false;
  bool _customIconSelected = true;
  bool _notificationsTile = true;
  bool _autoDebitTile = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final lang = LocaleController.languageCode;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.toggle_on_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang == 'ar'
                                        ? 'مفاتيح التبديل الرسمية (M3 Switch)'
                                        : (lang == 'hi' ? 'आधिकारिक एम3 स्विच (M3 Switch)' : 'Google M3 Switch Suite'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '52x32dp Track • 16/24/28dp Handle • Dynamic Morphing',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: loc.tr('closeModalBtn'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 16),

                  // Content Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Android Settings Style (With and Without Icon)
                          _buildSectionTitle(
                            context,
                            title: lang == 'ar'
                                ? '1. التبديل القياسي مع علامة الصح التعبيرية (M3 Default)'
                                : '1. Standard M3 Switch with Animated Checkmark',
                            badge: 'Wi-Fi & Bluetooth Demo',
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.wifi_rounded, size: 20, color: colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Wi-Fi',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: colorScheme.onSurface),
                                        ),
                                      ],
                                    ),
                                    TashilSwitch(
                                      value: _wifiSelected,
                                      showIcon: true,
                                      onChanged: (val) => setState(() => _wifiSelected = val),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const TashilDivider.inset(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.bluetooth_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Bluetooth',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: colorScheme.onSurface),
                                        ),
                                      ],
                                    ),
                                    TashilSwitch(
                                      value: _bluetoothSelected,
                                      showIcon: false,
                                      onChanged: (val) => setState(() => _bluetoothSelected = val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. Dual Icons Configuration (Checkmark & Cross)
                          _buildSectionTitle(
                            context,
                            title: lang == 'ar'
                                ? '2. التبديل مع أيقونتين مزدوجتين (تفعيل / إلغاء)'
                                : '2. Dual Icons Configuration (Selected & Unselected)',
                            badge: 'Dual Icon Morph',
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang == 'ar' ? 'التفاوض الآلي الفوري' : 'Automated Negotiation Auto-Pilot',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface),
                                ),
                                TashilSwitch(
                                  value: _customIconSelected,
                                  showIcon: true,
                                  selectedIcon: Icons.check_rounded,
                                  unselectedIcon: Icons.close_rounded,
                                  onChanged: (val) => setState(() => _customIconSelected = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. Disabled States
                          _buildSectionTitle(
                            context,
                            title: lang == 'ar' ? '3. الحالات المعطلة (Disabled States)' : '3. Disabled States',
                            badge: 'M3 Inactive Tokens',
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      lang == 'ar' ? 'معطل (مفعل)' : 'Disabled (ON)',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(width: 8),
                                    const TashilSwitch(
                                      value: true,
                                      enabled: false,
                                      onChanged: null,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      lang == 'ar' ? 'معطل (مغلق)' : 'Disabled (OFF)',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(width: 8),
                                    const TashilSwitch(
                                      value: false,
                                      enabled: false,
                                      onChanged: null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. Interactive List Tile Suite (TashilSwitchListTile)
                          _buildSectionTitle(
                            context,
                            title: lang == 'ar' ? '4. قائمة التبديل التفاعلية (TashilSwitchListTile)' : '4. M3 Switch List Tile Suite',
                            badge: 'Full Row Tap Area',
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                TashilSwitchListTile(
                                  title: Text(loc.tr('allowUpfrontDiscountSwitch')),
                                  subtitle: Text(loc.tr('allowUpfrontDiscountDesc')),
                                  secondary: Icon(Icons.discount_rounded, color: colorScheme.primary),
                                  value: _notificationsTile,
                                  onChanged: (val) => setState(() => _notificationsTile = val),
                                ),
                                const TashilDivider.fullWidth(),
                                TashilSwitchListTile(
                                  title: Text(loc.tr('autoCloseDealsTitle')),
                                  subtitle: Text(loc.tr('autoCloseDealsDesc')),
                                  secondary: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                                  value: _autoDebitTile,
                                  onChanged: (val) => setState(() => _autoDebitTile = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 12),

                  // Footer: Close action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TashilButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icons.check_circle_outline_rounded,
                        label: loc.tr('confirmActionBtn'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required String badge,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
