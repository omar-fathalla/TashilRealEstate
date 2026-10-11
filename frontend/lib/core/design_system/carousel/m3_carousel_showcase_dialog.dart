import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/carousel/tashil_carousels.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';

/// Official Material Design 3 Carousel Showcase Dialog.
///
/// Demonstrates the two primary Google M3 Carousel variants:
/// 1. Hero Carousel (Single focal item, end-peek, magnetic snapping)
/// 2. Multi-Browse Carousel (Dynamic breakpoint-adapted layout with parallax)
class M3CarouselShowcaseDialog extends StatelessWidget {
  const M3CarouselShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const M3CarouselShowcaseDialog(),
    );
  }

  static const List<Map<String, String>> _sampleUnits = [
    {
      'title': 'غرفة نوم رئيسية فاخرة',
      'titleEn': 'Master Bedroom Suite',
      'image': 'https://images.unsplash.com/photo-1540518614846-7ede433c4ef7?w=1000&auto=format&fit=crop',
    },
    {
      'title': 'صالة معيشة بإطلالة بحرية',
      'titleEn': 'Panoramic Sea-View Living Room',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1000&auto=format&fit=crop',
    },
    {
      'title': 'مطبخ أمريكي متكامل الأجهزة',
      'titleEn': 'Designer American Kitchen',
      'image': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=1000&auto=format&fit=crop',
    },
    {
      'title': 'تراس خارجي مشمس وحديقة',
      'titleEn': 'Sunny Terrace & Private Garden',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1000&auto=format&fit=crop',
    },
    {
      'title': 'حمام رخامي عصري جاكوزي',
      'titleEn': 'Modern Marble Jacuzzi Bath',
      'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=1000&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';

    final heroImages = _sampleUnits.map((e) => e['image']!).toList();

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 780),
        child: Column(
          children: [
            // 1. Header Bar
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.view_carousel_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('m3CarouselShowcaseTitle'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.tr('m3CarouselShowcaseSubtitle'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TashilIconButton.standard(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. Scrollable Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Interaction guidance banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_outlined, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.tr('m3CarouselSwipeHint'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ----------------------------------------------------
                  // Section 1: Hero Carousel (Single Focal Item + End Peek)
                  // ----------------------------------------------------
                  _buildSectionHeader(
                    context,
                    title: loc.tr('m3CarouselHeroTitle'),
                    subtitle: loc.tr('m3CarouselHeroSubtitle'),
                    icon: Icons.fullscreen_rounded,
                  ),
                  const SizedBox(height: 14),

                  TashilCard.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TashilCarousel.hero(
                            imageUrls: heroImages,
                            height: 280,
                            borderRadius: BorderRadius.circular(20),
                            showIndicator: true,
                            showArrows: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ----------------------------------------------------
                  // Section 2: Multi-Browse Carousel (Multi-Item Dynamic Weights)
                  // ----------------------------------------------------
                  _buildSectionHeader(
                    context,
                    title: loc.tr('m3CarouselMultiBrowseTitle'),
                    subtitle: loc.tr('m3CarouselMultiBrowseSubtitle'),
                    icon: Icons.view_column_rounded,
                  ),
                  const SizedBox(height: 14),

                  TashilCard.filled(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TashilCarousel.multiBrowse(
                            imageUrls: heroImages,
                            height: 220,
                            flexWeights: const [4, 3, 2, 1],
                            borderRadius: BorderRadius.circular(24),
                            showArrows: true,
                            children: _sampleUnits.map((item) {
                              final label = isArabic ? item['title']! : item['titleEn']!;
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    item['image']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: colorScheme.surfaceContainerHigh,
                                      child: const Icon(Icons.broken_image, size: 30),
                                    ),
                                  ),
                                  // Gradient scrim for text legibility
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: 70,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  PositionedDirectional(
                                    bottom: 12,
                                    start: 12,
                                    end: 12,
                                    child: Text(
                                      label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black87,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TashilButton(
                    label: loc.tr('confirm'),
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
