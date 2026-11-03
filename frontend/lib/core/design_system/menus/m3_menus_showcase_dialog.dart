import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'tashil_dropdown_menu.dart';
import 'tashil_menu_item.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Interactive showcase dialog displaying the Official Google Material Design 3 Dropdown Menus:
/// Conforms to https://m3.material.io/components/menus/guidelines and specs
/// Demonstrating:
/// 1. Top-to-Bottom Unfolding Motion with 250ms easing.
/// 2. 180° Rotating Dropdown Caret.
/// 3. Highlighted Selected Item Pill with checkmark.
/// 4. 48dp Item Height & Level 2 Elevation.
class M3MenusShowcaseDialog extends StatefulWidget {
  const M3MenusShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3MenusShowcaseDialog(),
    );
  }

  @override
  State<M3MenusShowcaseDialog> createState() => _M3MenusShowcaseDialogState();
}

class _M3MenusShowcaseDialogState extends State<M3MenusShowcaseDialog> {
  String _selectedCity = 'new_cairo';
  String _selectedType = 'apartment';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Symbols.arrow_drop_down_circle_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Google Material Design 3 Menus',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'https://m3.material.io/components/menus/specs',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          ),
                        ],
                      ),
                      ),
                      IconButton(
                        icon: const Icon(Symbols.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 16),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Specs Pill Banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Symbols.speed_rounded, color: colorScheme.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '250ms Top-to-Bottom Unfolding Motion • 180° Rotating Caret • 48dp Item Touch Target • Selected Pill Highlight with Checkmark',
                                    style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Demo 1: City Dropdown
                          Text(
                            loc.tr('city'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TashilDropdownMenu<String>(
                            value: _selectedCity,
                            labelText: loc.tr('city'),
                            prefixIcon: Symbols.location_city_rounded,
                            items: [
                              TashilDropdownMenuItem(
                                value: 'all',
                                label: loc.tr('city_all'),
                                icon: Symbols.domain_rounded,
                                supportingText: 'ALL',
                              ),
                              const TashilDropdownMenuItem.divider(value: 'div_1'),
                              TashilDropdownMenuItem(
                                value: 'new_cairo',
                                label: loc.tr('city_new_cairo'),
                                icon: Symbols.location_city_rounded,
                                supportingText: 'EG',
                              ),
                              TashilDropdownMenuItem(
                                value: 'sheikh_zayed',
                                label: loc.tr('city_sheikh_zayed'),
                                icon: Symbols.holiday_village_rounded,
                                supportingText: 'EG',
                              ),
                              TashilDropdownMenuItem(
                                value: 'alexandria',
                                label: loc.tr('city_alexandria'),
                                icon: Symbols.beach_access_rounded,
                                supportingText: 'EG',
                              ),
                              TashilDropdownMenuItem(
                                value: 'north_coast',
                                label: loc.tr('city_north_coast'),
                                icon: Symbols.waves_rounded,
                                supportingText: 'EG',
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCity = val);
                            },
                          ),
                          const SizedBox(height: 20),

                          // Demo 2: Property Type Dropdown
                          Text(
                            loc.tr('propertyType'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TashilDropdownMenu<String>(
                            value: _selectedType,
                            labelText: loc.tr('propertyType'),
                            prefixIcon: Symbols.home_work_rounded,
                            items: [
                              TashilDropdownMenuItem(
                                value: 'all',
                                label: loc.tr('type_all'),
                                icon: Symbols.home_work_rounded,
                              ),
                              const TashilDropdownMenuItem.divider(value: 'div_2'),
                              TashilDropdownMenuItem(
                                value: 'apartment',
                                label: loc.tr('type_apartment'),
                                icon: Symbols.apartment_rounded,
                              ),
                              TashilDropdownMenuItem(
                                value: 'villa',
                                label: loc.tr('type_villa'),
                                icon: Symbols.villa_rounded,
                              ),
                              TashilDropdownMenuItem(
                                value: 'studio',
                                label: loc.tr('type_studio'),
                                icon: Symbols.single_bed_rounded,
                              ),
                              TashilDropdownMenuItem(
                                value: 'duplex',
                                label: loc.tr('type_duplex'),
                                icon: Symbols.layers_rounded,
                              ),
                              TashilDropdownMenuItem(
                                value: 'chalet',
                                label: loc.tr('type_chalet'),
                                icon: Symbols.beach_access_rounded,
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Selection Feedback Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Symbols.check_circle_rounded, color: colorScheme.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${loc.tr('city')}: $_selectedCity  |  ${loc.tr('propertyType')}: $_selectedType',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
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

                  // Actions
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TashilButton(
                      label: loc.tr('closeModalBtn'),
                      icon: Symbols.check_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                      height: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
