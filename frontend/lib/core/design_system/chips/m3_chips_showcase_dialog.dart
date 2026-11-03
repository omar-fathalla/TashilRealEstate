import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import '../dividers/tashil_dividers.dart';
import 'tashil_assist_chip.dart';
import 'tashil_filter_chip.dart';
import 'tashil_input_chip.dart';
import 'tashil_suggestion_chip.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Interactive showcase dialog displaying the 4 official Material Design 3 Chip types:
/// 1. Assist Chips (Type 1 - Outlined, Elevated, Tonal)
/// 2. Filter Chips (Type 2 - Multiselect with checkmarks)
/// 3. Input Chips (Type 3 - Dismissible tags with delete buttons)
/// 4. Suggestion Chips (Type 4 - Dynamic recommendations)
class M3ChipsShowcaseDialog extends StatefulWidget {
  const M3ChipsShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3ChipsShowcaseDialog(),
    );
  }

  @override
  State<M3ChipsShowcaseDialog> createState() => _M3ChipsShowcaseDialogState();
}

class _M3ChipsShowcaseDialogState extends State<M3ChipsShowcaseDialog> {
  // Filter Chip State
  final Set<String> _selectedFilters = {'furnished', 'parking'};

  // Input Chip State
  final List<String> _tags = [AppLocalizations.trStatic('uiCopy123'), AppLocalizations.trStatic('uiCopy020'), 'مكيف بالكامل', 'إطلالة بحرية'];

  // Assist Chip State
  String? _lastAssistTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Symbols.label_important_outline_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.trStatic('uiCopy312'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                AppLocalizations.trStatic('uiCopy146'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TashilIconButton.standard(
                        icon: Symbols.close_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const TashilDivider.fullWidth(),

                  // Showcase Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Assist Chips (Type 1)
                          _buildSectionTitle(
                            title: AppLocalizations.trStatic('uiCopy006'),
                            description:
                                AppLocalizations.trStatic('uiCopy090'),
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TashilAssistChip.outlined(
                                icon: Symbols.weekend_rounded,
                                label: loc.tr('presetLivingRoom'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetLivingRoom')),
                              ),
                              TashilAssistChip.outlined(
                                icon: Symbols.bed_rounded,
                                label: loc.tr('presetMasterBed'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetMasterBed')),
                              ),
                              TashilAssistChip.elevated(
                                icon: Symbols.countertops_rounded,
                                label: loc.tr('presetKitchen'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetKitchen')),
                              ),
                              TashilAssistChip.elevated(
                                icon: Symbols.balcony_rounded,
                                label: loc.tr('presetBalcony'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetBalcony')),
                              ),
                              TashilAssistChip.tonal(
                                icon: Symbols.bathtub_rounded,
                                label: loc.tr('presetBathroom'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetBathroom')),
                              ),
                              TashilAssistChip.outlined(
                                icon: Symbols.apartment_rounded,
                                label: loc.tr('presetFacade'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetFacade')),
                              ),
                            ],
                          ),
                          if (_lastAssistTapped != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'تم النقر على رقاقة المساعدة: $_lastAssistTapped',
                              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // 2. Filter Chips (Type 2)
                          _buildSectionTitle(
                            title: AppLocalizations.trStatic('uiCopy015'),
                            description: AppLocalizations.trStatic('uiCopy105'),
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TashilFilterChip(
                                icon: Symbols.chair_rounded,
                                label: AppLocalizations.trStatic('uiCopy301'),
                                selected: _selectedFilters.contains('furnished'),
                                onSelected: (sel) => setState(() {
                                  if (sel) {
                                    _selectedFilters.add('furnished');
                                  } else {
                                    _selectedFilters.remove('furnished');
                                  }
                                }),
                              ),
                              TashilFilterChip(
                                icon: Symbols.local_parking_rounded,
                                label: AppLocalizations.trStatic('uiCopy315'),
                                selected: _selectedFilters.contains('parking'),
                                onSelected: (sel) => setState(() {
                                  if (sel) {
                                    _selectedFilters.add('parking');
                                  } else {
                                    _selectedFilters.remove('parking');
                                  }
                                }),
                              ),
                              TashilFilterChip.elevated(
                                icon: Symbols.ac_unit_rounded,
                                label: AppLocalizations.trStatic('uiCopy174'),
                                selected: _selectedFilters.contains('ac'),
                                onSelected: (sel) => setState(() {
                                  if (sel) {
                                    _selectedFilters.add('ac');
                                  } else {
                                    _selectedFilters.remove('ac');
                                  }
                                }),
                              ),
                              TashilFilterChip.elevated(
                                icon: Symbols.pool_rounded,
                                label: AppLocalizations.trStatic('uiCopy288'),
                                selected: _selectedFilters.contains('pool'),
                                onSelected: (sel) => setState(() {
                                  if (sel) {
                                    _selectedFilters.add('pool');
                                  } else {
                                    _selectedFilters.remove('pool');
                                  }
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 3. Input Chips (Type 3)
                          _buildSectionTitle(
                            title: AppLocalizations.trStatic('uiCopy022'),
                            description: AppLocalizations.trStatic('uiCopy181'),
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              return TashilInputChip(
                                icon: Symbols.tag_rounded,
                                label: tag,
                                onDeleted: () => setState(() => _tags.remove(tag)),
                              );
                            }).toList(),
                          ),
                          if (_tags.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextButton.icon(
                                onPressed: () => setState(() => _tags.addAll([AppLocalizations.trStatic('uiCopy123'), AppLocalizations.trStatic('uiCopy020'), 'مكيف'])),
                                icon: const Icon(Symbols.refresh_rounded, size: 16),
                                label: Text(AppLocalizations.trStatic('uiCopy096')),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // 4. Suggestion Chips (Type 4)
                          _buildSectionTitle(
                            title: AppLocalizations.trStatic('uiCopy028'),
                            description: AppLocalizations.trStatic('uiCopy116'),
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TashilSuggestionChip(
                                icon: Symbols.auto_awesome_rounded,
                                label: AppLocalizations.trStatic('uiCopy238'),
                                onPressed: () {},
                              ),
                              TashilSuggestionChip.elevated(
                                icon: Symbols.psychology_rounded,
                                label: AppLocalizations.trStatic('uiCopy169'),
                                onPressed: () {},
                              ),
                              TashilSuggestionChip(
                                icon: Symbols.mic_rounded,
                                label: AppLocalizations.trStatic('uiCopy100'),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const TashilDivider.cardAction(),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TashilButton(
                        label: loc.tr('closeBtn'),
                        onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildSectionTitle({
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
