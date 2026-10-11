import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_modal_dialog.dart';
import 'package:tashil_real_estate/core/design_system/lists/tashil_list_tile.dart';
import 'package:tashil_real_estate/core/design_system/lists/tashil_reorderable_list.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';

/// Interactive Material Design 3 Lists & Reordering Showcase Dialog.
class M3ListsShowcaseDialog extends StatefulWidget {
  const M3ListsShowcaseDialog({super.key});

  /// Displays the interactive showcase dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3ListsShowcaseDialog(),
    );
  }

  @override
  State<M3ListsShowcaseDialog> createState() => _M3ListsShowcaseDialogState();
}

class _M3ListsShowcaseDialogState extends State<M3ListsShowcaseDialog> {
  // Sample reorderable list items
  late List<_SampleListItem> _demoItems;
  bool _switchVal = true;

  @override
  void initState() {
    super.initState();
    _resetDemoItems();
  }

  void _resetDemoItems() {
    _demoItems = [
      _SampleListItem(
        id: '1',
        unit: '402',
        titleAr: 'شقة فاخرة بالتجمع الخامس - النرجس',
        titleEn: 'Luxury Apartment in 5th Settlement - El Narges',
        titleHi: '5वें सेटलमेंट में लक्जरी अपार्टमेंट',
        price: '23,000 ج.م',
        icon: Icons.apartment_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _SampleListItem(
        id: '2',
        unit: '12',
        titleAr: 'فيلا مستقلة بحمام سباحة - بيفرلي هيلز',
        titleEn: 'Standalone Villa with Pool - Beverly Hills',
        titleHi: 'स्विमिंग पूल के साथ विला - बेवर्ली हिल्स',
        price: '35,000 ج.م',
        icon: Icons.villa_rounded,
        color: const Color(0xFF10B981),
      ),
      _SampleListItem(
        id: '3',
        unit: '701',
        titleAr: 'شقة مطلة على النيل - جاردن سيتي',
        titleEn: 'Nile View Apartment - Garden City',
        titleHi: 'नाइल व्यू अपार्टमेंट - गार्डन सिटी',
        price: '21,000 ج.م',
        icon: Icons.water_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _SampleListItem(
        id: '4',
        unit: '104',
        titleAr: 'شاليه بحري صف أول - أمواج',
        titleEn: 'Seafront Chalet - Amwaj',
        titleHi: 'समुद्र तट शैले - अमवाज',
        price: '25,000 ج.م',
        icon: Icons.beach_access_rounded,
        color: const Color(0xFFF59E0B),
      ),
    ];
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _demoItems.removeAt(oldIndex);
      _demoItems.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = LocaleController.languageCode;

    return TashilModalDialog(
      title: loc.tr('m3ListsSuiteTitle'),
      subtitle: loc.tr('reorderablePropertiesTitle'),
      icon: Icons.format_list_bulleted_rounded,
      maxWidth: 680,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TashilButton(
            label: loc.tr('confirm'),
            icon: Icons.check_circle_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Section 1: Standard M3 Height Specifications (1-line, 2-line, 3-line)
          Text(
            loc.tr('m3ListsShowcase'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          TashilCard.outlined(
            borderRadius: BorderRadius.circular(16),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // 1-Line Item (56dp standard)
                TashilListTile.oneLine(
                  leading: const Icon(Icons.notifications_active_outlined),
                  leadingType: TashilListTileLeadingType.icon,
                  headline: Text(loc.tr('oneLineListItem')),
                  trailing: Switch(
                    value: _switchVal,
                    onChanged: (v) => setState(() => _switchVal = v),
                  ),
                ),
                const Divider(height: 1, indent: 72),

                // 2-Line Item (72dp standard)
                TashilListTile.twoLine(
                  leading: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.analytics_rounded, color: colorScheme.onPrimaryContainer),
                  ),
                  leadingType: TashilListTileLeadingType.avatar,
                  headline: Text(loc.tr('twoLineListItem')),
                  supportingText: Text(loc.tr('investorDashboardSubtitle')),
                  trailing: TashilFilterChip(
                    label: 'M3 72dp',
                    selected: true,
                    onSelected: (_) {},
                  ),
                ),
                const Divider(height: 1, indent: 72),

                // 3-Line Item (88dp standard)
                TashilListTile.threeLine(
                  leading: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.home_work_rounded, color: colorScheme.onSecondaryContainer),
                  ),
                  leadingType: TashilListTileLeadingType.thumbnail,
                  overline: const Text('PROPTECH M3 COMPONENT'),
                  headline: Text(loc.tr('threeLineListItem')),
                  supportingText: Text(loc.tr('heroSubtitle')),
                  trailing: Text(
                    '88dp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Interactive Drag & Drop Reorderable List
          Row(
            children: [
              Icon(Icons.drag_indicator_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.tr('reorderableListHint'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TashilIconButton.tonal(
                icon: Icons.refresh_rounded,
                size: 32,
                iconSize: 18,
                tooltip: loc.tr('resetFilters'),
                onPressed: () => setState(_resetDemoItems),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TashilCard.outlined(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TashilReorderableList<_SampleListItem>(
              items: _demoItems,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              dividerStartIndent: 64,
              onReorder: _onReorder,
              itemBuilder: (context, index, item) {
                return TashilListTile(
                  key: ValueKey('demo-item-${item.id}'),
                  lines: TashilListTileLines.twoLine,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TashilReorderHandle(
                        index: index,
                        tooltip: loc.tr('dragHandleTooltip'),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                    ],
                  ),
                  headline: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${item.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.getTitle(lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                  supportingText: Text(
                    item.price,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  trailing: TashilIconButton.outlined(
                    icon: Icons.touch_app_rounded,
                    size: 32,
                    iconSize: 16,
                    onPressed: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SampleListItem {
  final String id;
  final String unit;
  final String titleAr;
  final String titleEn;
  final String titleHi;
  final String price;
  final IconData icon;
  final Color color;

  _SampleListItem({
    required this.id,
    required this.unit,
    required this.titleAr,
    required this.titleEn,
    required this.titleHi,
    required this.price,
    required this.icon,
    required this.color,
  });

  String getTitle(String lang) {
    if (lang == 'ar') return titleAr;
    if (lang == 'hi') return titleHi;
    return titleEn;
  }
}
