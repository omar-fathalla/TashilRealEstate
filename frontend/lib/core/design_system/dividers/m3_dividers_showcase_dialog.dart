import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_modal_dialog.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'tashil_divider.dart';

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
          title: isArabic ? 'منظومة الفواصل M3 (Dividers Suite)' : 'M3 Dividers Design Suite',
          subtitle: isArabic
              ? 'المواصفات القياسية لفواصل ماتيريال ديزاين 3 مع إرشادات (Do) و (Caution)'
              : 'Google Material Design 3 official divider specifications with Do and Caution guidelines',
          icon: Icons.linear_scale_rounded,
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
                      ? '1. قاعدة (Do): فاصل يفصل بين المحتوى والإجراءات التفاعلية في البطاقة'
                      : '1. (Do): Full-width divider separating content and interactive card actions',
                  badgeColor: const Color(0xFF16A34A),
                  badgeText: 'DO',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'استخدم فاصلاً بعرض الحاوية بالكامل (Full-width) للفصل بين النصوص الوصفية غير التفاعلية ومنطقة الأزرار التفاعلية.'
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
                              isArabic ? 'فيلا راقية بالتجمع الخامس' : 'Luxury Villa in Fifth Settlement',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic
                                  ? 'تشطيب فاخر مع حديقة خاصة وحمام سباحة، موقع استراتيجي بالقرب من الخدمات.'
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
                              label: isArabic ? 'قراءة المزيد' : 'Read more',
                              variant: TashilButtonVariant.filled,
                              onPressed: () {},
                            ),
                            const Spacer(),
                            TashilIconButton(
                              icon: Icons.bookmark_border_rounded,
                              tooltip: isArabic ? 'حفظ' : 'Bookmark',
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            TashilIconButton(
                              icon: Icons.share_outlined,
                              tooltip: isArabic ? 'مشاركة' : 'Share',
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
                      ? '2. قاعدة (Do): الفواصل الداخلية للقوائم (Inset Dividers)'
                      : '2. (Do): Inset Dividers for Lists',
                  badgeColor: const Color(0xFF16A34A),
                  badgeText: 'DO',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'استخدم الفواصل الداخلية التي تبدأ مع بداية النص لتجنب قطع الأيقونات أو الصور الرمزية في القوائم، مع دعم كامل للاتجاهين (RTL / LTR).'
                      : 'Use inset dividers to group list items aligning with the text after leading avatars/icons.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TashilCard.filled(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildListItem(
                        icon: Icons.apartment_rounded,
                        title: isArabic ? 'برج الياسمين - وحدة 402' : 'Al Yasmin Tower - Unit 402',
                        subtitle: isArabic ? 'عقد إيجار نشط • 22,000 ج.م' : 'Active Lease • 22,000 EGP',
                        theme: theme,
                      ),
                      const TashilDivider.listTextInset(),
                      _buildListItem(
                        icon: Icons.storefront_rounded,
                        title: isArabic ? 'مكتب إداري - التجمع الخامس' : 'Commercial Office - New Cairo',
                        subtitle: isArabic ? 'قيد المراجعة • 45,000 ج.م' : 'Under Review • 45,000 EGP',
                        theme: theme,
                      ),
                      const TashilDivider.listTextInset(),
                      _buildListItem(
                        icon: Icons.cottage_rounded,
                        title: isArabic ? 'فيلا بالم هيلز - القطامية' : 'Palm Hills Villa - Katameya',
                        subtitle: isArabic ? 'مجدول للصيانة • زيارة فنية' : 'Maintenance Scheduled',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. M3 "CAUTION" Rule: Spare Full-Width Dividers
                _buildSectionHeader(
                  title: isArabic
                      ? '3. قاعدة (Caution): تجنب الإفراط في الفواصل حتى لا يزدحم التصميم'
                      : '3. (Caution): Use full-width dividers sparingly to prevent clutter',
                  badgeColor: const Color(0xFFD97706),
                  badgeText: 'CAUTION',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'الإفراط في وضع خطوط فواصل عريضة بين كل سطر يجعل الشاشة مزدحمة ومشوشة بصرياً. المسافات البيضاء وظلال الحاويات كافية في كثير من الأحيان.'
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
                      isArabic ? 'معاينة المقارنة بين التصميمين:' : 'Toggle visual comparison:',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    TashilButton(
                      label: _showClutteredDividerComparison
                          ? (isArabic ? 'عرض التصميم المريح النظيف' : 'Show Clean Design')
                          : (isArabic ? 'عرض التصميم المزدحم الخاطئ' : 'Show Cluttered Design'),
                      variant: TashilButtonVariant.tonal,
                      icon: Icons.compare_arrows_rounded,
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
                      _buildCompactRow('إيجار شهر سبتمبر', '22,000 ج.م', theme),
                      if (_showClutteredDividerComparison)
                        const TashilDivider.fullWidth(height: 12)
                      else
                        const SizedBox(height: 8),
                      _buildCompactRow('رسوم الصيانة الدورية', '1,500 ج.م', theme),
                      if (_showClutteredDividerComparison)
                        const TashilDivider.fullWidth(height: 12)
                      else
                        const SizedBox(height: 8),
                      _buildCompactRow('استهلاك المياه والكهرباء', '850 ج.م', theme),
                      const SizedBox(height: 8),
                      const TashilDivider.fullWidth(height: 1),
                      const SizedBox(height: 8),
                      _buildCompactRow('الإجمالي المستحق', '24,350 ج.م', theme, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Vertical Dividers
                _buildSectionHeader(
                  title: isArabic
                      ? '4. الفواصل الرأسية (Vertical Dividers) للأشرطة والمقاييس'
                      : '4. Vertical Dividers for Toolbars and Metric Tiles',
                  badgeColor: colorScheme.primary,
                  badgeText: 'M3 SPECS',
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
                        _buildMetricStat('142', isArabic ? 'إجمالي العقارات' : 'Total Units', theme),
                        const TashilVerticalDivider.inset(width: 24, inset: 4),
                        _buildMetricStat('94.2%', isArabic ? 'نسبة الإشغال' : 'Occupancy', theme),
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
                      ? '5. الفواصل المعنونة (Labelled Dividers) للفصل النصي و "أو"'
                      : '5. Labelled Dividers (Section titles & "OR" separators)',
                  badgeColor: colorScheme.secondary,
                  badgeText: 'LABELLED',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                TashilDivider.withLabel(
                  label: isArabic ? 'أو المتابعة عبر' : 'OR CONTINUE WITH',
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
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
          Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
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
