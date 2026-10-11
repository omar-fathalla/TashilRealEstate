import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import '../dividers/tashil_dividers.dart';
import 'tashil_assist_chip.dart';
import 'tashil_filter_chip.dart';
import 'tashil_input_chip.dart';
import 'tashil_suggestion_chip.dart';

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
  final List<String> _tags = ['التجمع الخامس', '3 غرف', 'مكيف بالكامل', 'إطلالة بحرية'];

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
                              Icons.label_important_outline_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'منظومة رقائق المواد M3 (Chips Suite)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'المواصفات القياسية الرسمية لماتريال ديزاين 3 مع نقاء لغوي تام',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TashilIconButton.standard(
                        icon: Icons.close_rounded,
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
                            title: '1. رقائق المساعدة (Assist Chips) — النوع الأول القياسي',
                            description:
                                'إجراءات سريعة وذكية مع أيقونة دلالية متوافقة مع السياق (ارتفاع 32dp وزوايا 8dp)',
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TashilAssistChip.outlined(
                                icon: Icons.weekend_outlined,
                                label: loc.tr('presetLivingRoom'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetLivingRoom')),
                              ),
                              TashilAssistChip.outlined(
                                icon: Icons.bed_outlined,
                                label: loc.tr('presetMasterBed'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetMasterBed')),
                              ),
                              TashilAssistChip.elevated(
                                icon: Icons.countertops_outlined,
                                label: loc.tr('presetKitchen'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetKitchen')),
                              ),
                              TashilAssistChip.elevated(
                                icon: Icons.balcony_outlined,
                                label: loc.tr('presetBalcony'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetBalcony')),
                              ),
                              TashilAssistChip.tonal(
                                icon: Icons.bathtub_outlined,
                                label: loc.tr('presetBathroom'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetBathroom')),
                              ),
                              TashilAssistChip.outlined(
                                icon: Icons.apartment_outlined,
                                label: loc.tr('presetFacade'),
                                onPressed: () => setState(() => _lastAssistTapped = loc.tr('presetFacade')),
                              ),
                            ],
                          ),
                          if (_lastAssistTapped != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'تم النقر على رقاقة المساعدة: $_lastAssistTapped',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // 2. Filter Chips (Type 2)
                          _buildSectionTitle(
                            title: '2. رقائق التصفية والاختيار (Filter Chips)',
                            description: 'اختيار المعايير والمرافق مع انتقال حركي سلس لأيقونة التأكيد (Checkmark)',
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TashilFilterChip(
                                icon: Icons.chair_outlined,
                                label: 'مفروش بالكامل',
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
                                icon: Icons.local_parking_outlined,
                                label: 'موقف سيارات',
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
                                icon: Icons.ac_unit_outlined,
                                label: 'تكييف مركزي',
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
                                icon: Icons.pool_outlined,
                                label: 'مسبح ونادٍ',
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
                            title: '3. رقائق الإدخال والوسوم (Input Chips)',
                            description: 'تمثيل المدخلات والكلمات المفتاحية مع زر حذف مدمج للتفريغ السريع',
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              return TashilInputChip(
                                icon: Icons.tag_rounded,
                                label: tag,
                                onDeleted: () => setState(() => _tags.remove(tag)),
                              );
                            }).toList(),
                          ),
                          if (_tags.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextButton.icon(
                                onPressed: () => setState(() => _tags.addAll(['التجمع الخامس', '3 غرف', 'مكيف'])),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('إعادة تعيين الوسوم'),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // 4. Suggestion Chips (Type 4)
                          _buildSectionTitle(
                            title: '4. رقائق الاقتراحات الذكية (Suggestion Chips)',
                            description: 'اقتراحات محادثة الذكاء الاصطناعي وصياغة الإعلانات الفورية',
                            theme: theme,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TashilSuggestionChip(
                                icon: Icons.auto_awesome_rounded,
                                label: 'صياغة تسويقية تنفيذية فاخرة',
                                onPressed: () {},
                              ),
                              TashilSuggestionChip.elevated(
                                icon: Icons.psychology_rounded,
                                label: 'تدقيق الصور بالذكاء الاصطناعي',
                                onPressed: () {},
                              ),
                              TashilSuggestionChip(
                                icon: Icons.mic_rounded,
                                label: 'إملاء صوتي فوري للوصف',
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
