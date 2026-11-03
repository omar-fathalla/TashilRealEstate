import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_modal_dialog.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'tashil_divider.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Interactive showcase dialog demonstrating Google Material Design 3 (M3) Divider guidelines:
/// https://m3.material.io/components/divider/guidelines
///
/// Features demonstrated:
/// 1. DO: Full-width divider separating interactive and non-interactive areas of a container (Card).
/// 2. DO: Inset divider in lists aligning with text after avatars/icons.
/// 3. CAUTION: Warning on visual clutter when too many full-width dividers are used.
/// 4. Vertical Divider separating horizontal toolbar items and metrics.
/// 5. Labelled Divider ("أو" / "OR" / Section divider) with RTL/LTR awareness.
class M3DividersShowcaseDialog extends StatefulWidget {
  const M3DividersShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3DividersShowcaseDialog(),
    );
  }

  @override
  State<M3DividersShowcaseDialog> createState() => _M3DividersShowcaseDialogState();
}

class _M3DividersShowcaseDialogState extends State<M3DividersShowcaseDialog> {
  bool _showClutteredDividerComparison = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar';

        return TashilModalDialog(
          title: isArabic ? AppLocalizations.trStatic('uiCopy311') : 'M3 Dividers Design Suite',
          subtitle: isArabic
              ? AppLocalizations.trStatic('uiCopy147')
              : 'Google Material Design 3 official divider specifications with Do and Caution guidelines',
          icon: Symbols.linear_scale_rounded,
          maxWidth: 800,
          maxHeight: 760,
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
                // 1. M3 "DO" Rule: Full-width Divider in Cards
                _buildSectionHeader(
                  title: isArabic
                      ? AppLocalizations.trStatic('uiCopy008')
                      : '1. (Do): Full-width divider separating content and interactive card actions',
                  badgeColor: const Color(0xFF16A34A),
                  badgeText: 'DO',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? AppLocalizations.trStatic('uiCopy110')
                      : 'Use full-width divider lines to separate interactive and non-interactive areas of a container such as a card.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TashilCard.outlined(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Non-interactive content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? AppLocalizations.trStatic('uiCopy256') : 'Luxury Villa in Fifth Settlement',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic
                                  ? AppLocalizations.trStatic('uiCopy171')
                                  : 'Premium finish with private garden and pool, prime location near amenities.',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),

                      // M3 Full-width Action Divider (DO)
                      const TashilDivider.cardAction(),

                      // Interactive Actions Area
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Row(
                          children: [
                            TashilButton(
                              label: isArabic ? AppLocalizations.trStatic('uiCopy259') : 'Read more',
                              variant: TashilButtonVariant.filled,
                              onPressed: () {},
                            ),
                            const Spacer(),
                            TashilIconButton(
                              icon: Symbols.bookmark_border_rounded,
                              tooltip: isArabic ? AppLocalizations.trStatic('uiCopy197') : 'Bookmark',
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            TashilIconButton(
                              icon: Symbols.share_rounded,
                              tooltip: isArabic ? AppLocalizations.trStatic('uiCopy291') : 'Share',
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. M3 "DO" Rule: Inset List Divider
                _buildSectionHeader(
                  title: isArabic
                      ? AppLocalizations.trStatic('uiCopy016')
                      : '2. (Do): Inset Dividers for Lists',
                  badgeColor: const Color(0xFF16A34A),
                  badgeText: 'DO',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? AppLocalizations.trStatic('uiCopy109')
                      : 'Use inset dividers to group list items aligning with the text after leading avatars/icons.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TashilCard.filled(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildListItem(
                        icon: Symbols.apartment_rounded,
                        title: isArabic ? AppLocalizations.trStatic('uiCopy161') : 'Al Yasmin Tower - Unit 402',
                        subtitle: isArabic ? AppLocalizations.trStatic('uiCopy245') : 'Active Lease • 22,000 EGP',
                        theme: theme,
                      ),
                      const TashilDivider.listTextInset(),
                      _buildListItem(
                        icon: Symbols.storefront_rounded,
                        title: isArabic ? AppLocalizations.trStatic('uiCopy303') : 'Commercial Office - New Cairo',
                        subtitle: isArabic ? AppLocalizations.trStatic('uiCopy261') : 'Under Review • 45,000 EGP',
                        theme: theme,
                      ),
                      const TashilDivider.listTextInset(),
                      _buildListItem(
                        icon: Symbols.cottage_rounded,
                        title: isArabic ? AppLocalizations.trStatic('uiCopy255') : 'Palm Hills Villa - Katameya',
                        subtitle: isArabic ? AppLocalizations.trStatic('uiCopy277') : 'Maintenance Scheduled',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. M3 "CAUTION" Rule: Spare Full-Width Dividers
                _buildSectionHeader(
                  title: isArabic
                      ? AppLocalizations.trStatic('uiCopy023')
                      : '3. (Caution): Use full-width dividers sparingly to prevent clutter',
                  badgeColor: const Color(0xFFD97706),
                  badgeText: 'CAUTION',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? AppLocalizations.trStatic('uiCopy118')
                      : 'Use full-width dividers sparingly. Too many divider lines will make an interface look cluttered.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isArabic ? AppLocalizations.trStatic('uiCopy296') : 'Toggle visual comparison:',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    TashilButton(
                      label: _showClutteredDividerComparison
                          ? (isArabic ? AppLocalizations.trStatic('uiCopy243') : 'Show Clean Design')
                          : (isArabic ? AppLocalizations.trStatic('uiCopy244') : 'Show Cluttered Design'),
                      variant: TashilButtonVariant.tonal,
                      icon: Symbols.compare_arrows_rounded,
                      onPressed: () {
                        setState(() {
                          _showClutteredDividerComparison = !_showClutteredDividerComparison;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TashilCard.outlined(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildCompactRow(AppLocalizations.trStatic('uiCopy102'), '22,000 ج.م', theme),
                      if (_showClutteredDividerComparison)
                        const TashilDivider.fullWidth(height: 12)
                      else
                        const SizedBox(height: 8),
                      _buildCompactRow('رسوم الصيانة الدورية', AppLocalizations.trStatic('uiCopy003'), theme),
                      if (_showClutteredDividerComparison)
                        const TashilDivider.fullWidth(height: 12)
                      else
                        const SizedBox(height: 8),
                      _buildCompactRow(AppLocalizations.trStatic('uiCopy114'), '850 ج.م', theme),
                      const SizedBox(height: 8),
                      const TashilDivider.fullWidth(height: 1),
                      const SizedBox(height: 8),
                      _buildCompactRow('الإجمالي المستحق', AppLocalizations.trStatic('uiCopy018'), theme, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Vertical Dividers
                _buildSectionHeader(
                  title: isArabic
                      ? AppLocalizations.trStatic('uiCopy027')
                      : '4. Vertical Dividers for Toolbars and Metric Tiles',
                  badgeColor: colorScheme.primary,
                  badgeText: AppLocalizations.trStatic('uiCopy064'),
                  theme: theme,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricStat('142', isArabic ? AppLocalizations.trStatic('uiCopy091') : 'Total Units', theme),
                        const TashilVerticalDivider.inset(width: 24, inset: 4),
                        _buildMetricStat('94.2%', isArabic ? AppLocalizations.trStatic('uiCopy318') : 'Occupancy', theme),
                        const TashilVerticalDivider.inset(width: 24, inset: 4),
                        _buildMetricStat('0', isArabic ? 'متأخرات معلقة' : 'Overdue', theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Labelled Divider
                _buildSectionHeader(
                  title: isArabic
                      ? AppLocalizations.trStatic('uiCopy029')
                      : '5. Labelled Dividers (Section titles & "OR" separators)',
                  badgeColor: colorScheme.secondary,
                  badgeText: 'LABELLED',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                TashilDivider.withLabel(
                  label: isArabic ? AppLocalizations.trStatic('uiCopy088') : 'OR CONTINUE WITH',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Color badgeColor,
    required String badgeText,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badgeText,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Symbols.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildCompactRow(String label, String value, ThemeData theme, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricStat(String value, String label, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
