import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'tashil_navigation_rail.dart';

/// Interactive Showcase Dialog for Google Material Design 3 Navigation Rail & Nested Canvas.
class M3RailShowcaseDialog extends StatefulWidget {
  const M3RailShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const M3RailShowcaseDialog(),
    );
  }

  @override
  State<M3RailShowcaseDialog> createState() => _M3RailShowcaseDialogState();
}

class _M3RailShowcaseDialogState extends State<M3RailShowcaseDialog> {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final canvasBg = isDark
        ? colorScheme.surface
        : colorScheme.surfaceContainerLowest;

    final bodyBg = isDark
        ? colorScheme.surfaceContainerLow
        : Color.alphaBlend(colorScheme.primary.withAlpha(10), colorScheme.surfaceContainerLow);

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Icon(
                      Icons.view_sidebar_rounded,
                      color: colorScheme.onSecondaryContainer,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('m3RailShowcase'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          loc.tr('m3RailSubtitle'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TashilButton.tonal(
                    icon: _isExpanded ? Icons.close_fullscreen_rounded : Icons.open_in_full_rounded,
                    label: _isExpanded ? loc.tr('railMode') : loc.tr('expandedMode'),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                  const SizedBox(width: 8.0),
                  TashilIconButton.standard(
                    icon: Icons.close_rounded,
                    size: 38.0,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const TashilDivider.fullWidth(),
              const SizedBox(height: 16.0),

              // 2. Interactive Nested Canvas Preview Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: canvasBg,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Simulated Canvas Header
                      Container(
                        height: 56.0,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        color: canvasBg,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Icon(Icons.apartment_rounded, color: colorScheme.onPrimary, size: 18.0),
                                ),
                                const SizedBox(width: 10.0),
                                Text(
                                  loc.tr('appName'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                loc.tr('nestedCanvas'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Canvas Body: Rail + Nested Rounded Workspace
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Navigation Rail (Unified canvas background)
                            TashilNavigationRail(
                              isExpanded: _isExpanded,
                              onToggleExpanded: () => setState(() => _isExpanded = !_isExpanded),
                              menuTooltip: loc.tr('menu'),
                              actionFab: _isExpanded
                                  ? TashilButton(
                                      icon: Icons.add_rounded,
                                      label: 'إضافة وحدة',
                                      onPressed: () {},
                                    )
                                  : FloatingActionButton.small(
                                      elevation: 0,
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                                      onPressed: () {},
                                      child: const Icon(Icons.add_rounded, size: 22.0),
                                    ),
                              destinations: [
                                TashilRailDestination(
                                  icon: Icons.dashboard_outlined,
                                  selectedIcon: Icons.dashboard_rounded,
                                  label: loc.tr('portfolioOverview'),
                                  isSelected: _selectedIndex == 0,
                                  isExpanded: _isExpanded,
                                  onTap: () => setState(() => _selectedIndex = 0),
                                ),
                                TashilRailDestination(
                                  icon: Icons.apartment_outlined,
                                  selectedIcon: Icons.apartment_rounded,
                                  label: loc.tr('myProperties'),
                                  badgeCount: '5',
                                  isSelected: _selectedIndex == 1,
                                  isExpanded: _isExpanded,
                                  onTap: () => setState(() => _selectedIndex = 1),
                                ),
                                TashilRailDestination(
                                  icon: Icons.account_balance_wallet_outlined,
                                  selectedIcon: Icons.account_balance_wallet_rounded,
                                  label: loc.tr('financialsAndPayouts'),
                                  isSelected: _selectedIndex == 2,
                                  isExpanded: _isExpanded,
                                  onTap: () => setState(() => _selectedIndex = 2),
                                ),
                                TashilRailDestination(
                                  icon: Icons.build_outlined,
                                  selectedIcon: Icons.build_rounded,
                                  label: loc.tr('maintenanceTickets'),
                                  badgeCount: '1',
                                  isSelected: _selectedIndex == 3,
                                  isExpanded: _isExpanded,
                                  onTap: () => setState(() => _selectedIndex = 3),
                                ),
                                TashilRailDestination(
                                  icon: Icons.tune_rounded,
                                  label: loc.tr('settings'),
                                  isSelected: _selectedIndex == 4,
                                  isExpanded: _isExpanded,
                                  onTap: () => setState(() => _selectedIndex = 4),
                                ),
                              ],
                              footer: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: CircleAvatar(
                                  radius: 18.0,
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Text(
                                    'AF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 2. Nested Workspace Body with 28dp Top-Start Corner Curve!
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bodyBg,
                                  borderRadius: const BorderRadiusDirectional.only(
                                    topStart: Radius.circular(28.0),
                                  ),
                                  border: BorderDirectional(
                                    top: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
                                    start: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
                                  ),
                                ),
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.rounded_corner_rounded, size: 24.0, color: colorScheme.primary),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          loc.tr('nestedCanvasDesc'),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12.0),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(color: colorScheme.outlineVariant),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline_rounded, size: 20.0, color: colorScheme.primary),
                                          const SizedBox(width: 10.0),
                                          Expanded(
                                            child: Text(
                                              loc.tr('railActiveIndicatorDesc'),
                                              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20.0),
                                    Text(
                                      'المواصفات الهندسية المحققة:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: colorScheme.onSurface),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text('• عرض الشريط القياسي في وضع الـ Rail هو 80.0dp بدقة.', style: TextStyle(fontSize: 12.0, color: colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 4.0),
                                    Text('• مؤشر الكبسولة النشطة للأيقونة بمقاس 56×32dp مع استدارة 16dp.', style: TextStyle(fontSize: 12.0, color: colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 4.0),
                                    Text('• تموضع اسم الوجهة مباشرة تحت الأيقونة بنمط labelMedium.', style: TextStyle(fontSize: 12.0, color: colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 4.0),
                                    Text('• محاذاة زر المنيو العلوي في نفس المحور الرأسي للأيقونات.', style: TextStyle(fontSize: 12.0, color: colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 4.0),
                                    Text('• تكامل لوني موحد بين الهيدر والـ Rail مع انحناءة زاوية البودي 28dp.', style: TextStyle(fontSize: 12.0, color: colorScheme.onSurfaceVariant)),
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}
