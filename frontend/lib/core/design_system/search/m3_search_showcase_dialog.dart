import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'tashil_search_bar.dart';

/// Interactive showcase dialog displaying the Official Google Material Design 3 (M3) Search Suite.
/// Conforms to:
/// - https://m3.material.io/components/search/overview
/// - https://m3.material.io/components/search/guidelines
/// - https://m3.material.io/components/search/accessibility
/// - https://m3.material.io/components/search/specs
///
/// Demonstrates:
/// 1. 56dp stadium container with 28dp full rounded radius.
/// 2. Interactive state layers, hover elevation, and scale spring physics.
/// 3. Search View unfolding overlay suggestions with cubic easing.
/// 4. Harmonized multi-modal search (Text query, AI Semantic search, Visual camera search).
/// 5. Full RTL/LTR directionality awareness and pure trilingual parity.
class M3SearchShowcaseDialog extends StatefulWidget {
  const M3SearchShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const M3SearchShowcaseDialog(),
    );
  }

  @override
  State<M3SearchShowcaseDialog> createState() => _M3SearchShowcaseDialogState();
}

class _M3SearchShowcaseDialogState extends State<M3SearchShowcaseDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSemanticActive = false;
  String _lastSubmittedQuery = '';
  String _searchFeedback = '';

  final List<String> _demoSuggestions = [
    'شقة للبيع في الشيخ زايد',
    'Apartment for rent in Dubai Marina',
    'فيلا بإطلالة بحرية',
    'Modern duplex with private pool',
    'Penthouse in New Cairo',
    'مكتب تجاري في العاصمة الإدارية',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_rounded,
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
                                  ? 'منظومة البحث الذكي M3 Search'
                                  : (lang == 'hi'
                                      ? 'M3 स्मार्ट खोज प्रणाली'
                                      : 'M3 Smart Search System'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              lang == 'ar'
                                  ? 'معايير جوجل الرسمية للبحث وشريط البحث المتقدم'
                                  : (lang == 'hi'
                                      ? 'Google Material Design 3 आधिकारिक खोज मानक'
                                      : 'Official Google M3 Search Bar & Search View Specifications'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 20),

                  // Interactive Playground Area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section 1: Live Search Bar Demo
                          Text(
                            lang == 'ar'
                                ? '1. شريط البحث التفاعلي (Live M3 Search Bar)'
                                : (lang == 'hi'
                                    ? '1. इंटरैक्टिव M3 सर्च बार'
                                    : '1. Live Interactive M3 Search Bar'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang == 'ar'
                                ? 'جرب الكتابة لرؤية قائمة المقترحات الذكية، أو فعّل البحث الدلالي بالذكاء الاصطناعي أو البحث بالصور:'
                                : (lang == 'hi'
                                    ? 'सुझाव देखने के लिए टाइप करें, या AI सिमेंटिक सर्च और विज़ुअल सर्च आज़माएँ:'
                                    : 'Try typing to view suggestions view, toggle AI Semantic Search, or trigger Visual Search:'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Standalone Search Bar Container
                          TashilSearchBar(
                            controller: _searchController,
                            hintText: _isSemanticActive
                                ? loc.tr('aiSearchPlaceholder')
                                : loc.tr('searchPlaceholder'),
                            isSemanticActive: _isSemanticActive,
                            suggestions: _demoSuggestions,
                            onChanged: (val) {
                              setState(() {
                                _searchFeedback = val.isEmpty
                                    ? ''
                                    : '${loc.tr('search')}: $val';
                              });
                            },
                            onSubmitted: (query) {
                              setState(() {
                                _lastSubmittedQuery = query;
                                _searchFeedback = '${loc.tr('results')}: $query';
                              });
                            },
                            onClear: () {
                              setState(() {
                                _searchFeedback = '';
                                _lastSubmittedQuery = '';
                              });
                            },
                            onToggleSemantic: () {
                              setState(() {
                                _isSemanticActive = !_isSemanticActive;
                                _searchFeedback = _isSemanticActive
                                    ? loc.tr('semanticSearchEnabled')
                                    : loc.tr('semanticSearchDisabled');
                              });
                            },
                            onVisualSearch: () {
                              setState(() {
                                _searchFeedback = loc.tr('visualSearchTooltip');
                              });
                            },
                            onSelectSuggestion: (sugg) {
                              setState(() {
                                _lastSubmittedQuery = sugg;
                                _searchFeedback = '${loc.tr('selected')}: $sugg';
                              });
                            },
                          ),

                          if (_searchFeedback.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _searchFeedback,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (_lastSubmittedQuery.isNotEmpty)
                                    Text(
                                      '✓',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),
                          const TashilDivider.middleInset(),
                          const SizedBox(height: 20),

                          // Section 2: Technical M3 Search Specifications
                          Text(
                            lang == 'ar'
                                ? '2. المواصفات الهندسية الرسمية (M3 Search Specs)'
                                : (lang == 'hi'
                                    ? '2. तकनीकी M3 विनिर्देश'
                                    : '2. Official Technical M3 Specifications'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildSpecCard(
                                context,
                                icon: Icons.straighten_rounded,
                                title: lang == 'ar' ? 'الارتفاع والأبعاد' : 'Dimensions',
                                spec: '56dp Height • 28dp Stadium Radius',
                                description: lang == 'ar'
                                    ? 'ارتفاع قياسي 56dp مع زوايا دائرية بالكامل 28dp تعزز سهولة اللمس والتفاعل.'
                                    : 'Standard 56dp container height with 28dp full stadium pill corners.',
                              ),
                              _buildSpecCard(
                                context,
                                icon: Icons.animation_rounded,
                                title: lang == 'ar' ? 'الحركة والانتقال' : 'Motion & Physics',
                                spec: '240ms cubic easing • Level 1-2 Elevation',
                                description: lang == 'ar'
                                    ? 'انتقال ناعم مع زيادة طفيفة في التكبير (1.008x) وظل الارتفاع عند التركيز.'
                                    : 'Smooth scale (1.008x) and elevation transition upon focus and hover.',
                              ),
                              _buildSpecCard(
                                context,
                                icon: Icons.auto_awesome_rounded,
                                title: lang == 'ar' ? 'تعدد الوسائط والذكاء' : 'Multi-Modal Search',
                                spec: 'Text • AI Semantic • Visual Photo',
                                description: lang == 'ar'
                                    ? 'تناغم فوري بين البحث النصي التقليدي، والبحث الدلالي بالمتجهات، والبحث بالصور.'
                                    : 'Seamless tri-modal search combining text query, AI vector search, and visual search.',
                              ),
                              _buildSpecCard(
                                context,
                                icon: Icons.format_list_bulleted_rounded,
                                title: lang == 'ar' ? 'قائمة المقترحات المتدفقة' : 'Search View Overlay',
                                spec: 'Uncontained Overlay • 16dp Radius',
                                description: lang == 'ar'
                                    ? 'قائمة مقترحات تنبثق بنعومة من أسفل شريط البحث دون تشويه أو إزاحة باقي عناصر الصفحة.'
                                    : 'Elevated suggestions menu unfolding smoothly below search bar without displacing page elements.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const TashilDivider.fullWidth(),
                  const SizedBox(height: 14),

                  // Actions Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TashilButton(
                        label: loc.tr('close'),
                        variant: TashilButtonVariant.filled,
                        icon: Icons.check_rounded,
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

  Widget _buildSpecCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String spec,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              spec,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
