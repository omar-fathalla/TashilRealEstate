import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/image_moderation/models/image_moderation_model.dart';
import 'package:tashil_real_estate/features/image_moderation/services/ai_image_moderation_service.dart';

class AiImageModeratorDialog extends StatefulWidget {
  const AiImageModeratorDialog({super.key});

  static void show(BuildContext context) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AiImageModeratorDialog(),
    );
  }

  @override
  State<AiImageModeratorDialog> createState() => _AiImageModeratorDialogState();
}

class _AiImageModeratorDialogState extends State<AiImageModeratorDialog> {
  String _selectedFilter = 'all'; // 'all', 'approved', 'rejected'
  ImageModerationItem? _selectedItem;
  bool _isUploading = false;

  final _service = AiImageModerationService();

  Future<void> _simulateUpload(String type) async {
    setState(() => _isUploading = true);

    String name = 'property_photo.jpg';
    String url = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80';

    if (type == 'living_room') {
      name = 'luxury_living_room.jpg';
      url = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80';
    } else if (type == 'bedroom') {
      name = 'master_bedroom.jpg';
      url = 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=800&q=80';
    } else if (type == 'kitchen') {
      name = 'modern_kitchen.jpg';
      url = 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800&q=80';
    } else if (type == 'person') {
      name = 'person_selfie_in_room.jpg';
      url = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&q=80';
    } else if (type == 'car') {
      name = 'sports_car_automobile.jpg';
      url = 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80';
    } else if (type == 'blur') {
      name = 'dark_blurry_photo.jpg';
      url = 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=800&q=80';
    }

    final item = await _service.moderateImage(fileName: name, imageUrl: url);

    if (mounted) {
      setState(() {
        _isUploading = false;
        _selectedItem = item;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 20 : 28)),
      backgroundColor: theme.colorScheme.surface,
      elevation: 3.0,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.25),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: ValueListenableBuilder<List<ImageModerationItem>>(
          valueListenable: _service.moderatedItemsNotifier,
          builder: (context, allItems, _) {
            final approvedCount = allItems.where((i) => i.isApproved).length;
            final rejectedCount = allItems.where((i) => i.isRejected).length;

            final filteredItems = allItems.where((i) {
              if (_selectedFilter == 'approved') return i.isApproved;
              if (_selectedFilter == 'rejected') return i.isRejected;
              return true;
            }).toList();

            return Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('aiImageModeratorTitle'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    loc.tr('aiImageModeratorSubtitle'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      TashilIconButton.close(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // KPI Metric Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricItem(loc.tr('totalScannedPhotos'), '${allItems.length}', theme.colorScheme.onSurface, theme),
                        _buildMetricItem(loc.tr('approvedPhotosCount'), '$approvedCount', theme.colorScheme.primary, theme),
                        _buildMetricItem(loc.tr('rejectedPhotosCount'), '$rejectedCount', theme.colorScheme.error, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Test Buttons Bar
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        loc.tr('simulateMediaUpload'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      _buildQuickUploadBtn('living_room', loc.tr('sampleLivingRoom'), Icons.chair_rounded, theme.colorScheme.primary),
                      _buildQuickUploadBtn('bedroom', loc.tr('sampleBedroom'), Icons.bed_rounded, theme.colorScheme.primary),
                      _buildQuickUploadBtn('kitchen', loc.tr('sampleKitchen'), Icons.kitchen_rounded, theme.colorScheme.primary),
                      _buildQuickUploadBtn('person', loc.tr('samplePersonSelfie'), Icons.person_off_rounded, theme.colorScheme.error),
                      _buildQuickUploadBtn('car', loc.tr('sampleCarObject'), Icons.directions_car_rounded, theme.colorScheme.error),
                      _buildQuickUploadBtn('blur', loc.tr('sampleBlurry'), Icons.blur_on_rounded, theme.colorScheme.error),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Filter Tabs
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TashilConnectedButtonGroup<String>(
                      selectedValue: _selectedFilter,
                      onSelectionChanged: (val) {
                        setState(() {
                          _selectedFilter = val;
                        });
                      },
                      segments: [
                        TashilConnectedButtonSegment<String>(
                          value: 'all',
                          label: '${loc.tr('all')} (${allItems.length})',
                        ),
                        TashilConnectedButtonSegment<String>(
                          value: 'approved',
                          label: '${loc.tr('approved')} ($approvedCount)',
                        ),
                        TashilConnectedButtonSegment<String>(
                          value: 'rejected',
                          label: '${loc.tr('rejected')} ($rejectedCount)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Main Content: Grid & Inspector Details
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_search_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(height: 12),
                                Text(
                                  loc.tr('noModeratedPhotosFound'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : isMobile
                            ? SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: 130,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: filteredItems.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                                        itemBuilder: (context, index) {
                                          final item = filteredItems[index];
                                          return SizedBox(
                                            width: 130,
                                            child: _buildImageCard(item, loc, theme),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInspectionDetailsPanel(
                                      _selectedItem ?? (filteredItems.isNotEmpty ? filteredItems.first : null),
                                      loc,
                                      theme,
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left side: Images Grid
                                  Expanded(
                                    flex: 3,
                                    child: GridView.builder(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1.1,
                                      ),
                                      itemCount: filteredItems.length,
                                      itemBuilder: (context, index) {
                                        final item = filteredItems[index];
                                        return _buildImageCard(item, loc, theme);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Right side: Policy Inspector Panel
                                  Expanded(
                                    flex: 2,
                                    child: _buildInspectionDetailsPanel(
                                      _selectedItem ?? (filteredItems.isNotEmpty ? filteredItems.first : null),
                                      loc,
                                      theme,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickUploadBtn(String type, String label, IconData icon, Color color) {
    return TashilButton.outlined(
      onPressed: _isUploading ? null : () => _simulateUpload(type),
      icon: icon,
      label: label,
    );
  }



  Widget _buildImageCard(ImageModerationItem item, AppLocalizations loc, ThemeData theme) {
    final isSelected = _selectedItem?.id == item.id;
    final isApproved = item.isApproved;
    final isAnalyzing = item.isAnalyzing;

    Color badgeBg = isApproved ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer;
    Color badgeText = isApproved ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer;
    String statusText = isApproved ? loc.tr('statusApproved') : loc.tr('statusRejected');

    if (isAnalyzing) {
      badgeBg = theme.colorScheme.tertiaryContainer;
      badgeText = theme.colorScheme.onTertiaryContainer;
      statusText = loc.tr('statusAnalyzing');
    }

    return InkWell(
      onTap: () => setState(() => _selectedItem = item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (item.isRejected ? theme.colorScheme.error : theme.colorScheme.outlineVariant),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 8)]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview with Status Badge
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imagePathOrUrl != null)
                    Image.network(
                      item.imagePathOrUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_rounded, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image, size: 36, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  // Status Badge on top-start
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeText.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isApproved ? Icons.verified_rounded : Icons.cancel_rounded,
                            color: badgeText,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(color: badgeText, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Footer Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.tr(item.categoryKey),
                    style: TextStyle(
                      fontSize: 10,
                      color: isApproved ? theme.colorScheme.primary : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionDetailsPanel(ImageModerationItem? item, AppLocalizations loc, ThemeData theme) {
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Text(
            loc.tr('selectImageToInspect'),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
      );
    }

    final isApproved = item.isApproved;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApproved ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    loc.tr('aiDiagnosticsTitle'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isApproved ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isApproved ? loc.tr('statusApproved') : loc.tr('statusRejected'),
                    style: TextStyle(
                      color: isApproved ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Rejection Banner (If Rejected)
            if (item.isRejected) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          loc.tr('rejectionReasonLabel'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onErrorContainer, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRejectionMessage(item, loc),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onErrorContainer, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Compliance Checklist
            Text(
              loc.tr('policyChecklistLabel'),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildChecklistTile(
              loc.tr('ruleRealEstateContent'),
              item.isRealEstateRelated,
              theme,
            ),
            _buildChecklistTile(
              loc.tr('ruleNoPersonsOrFaces'),
              !item.containsPersonsOrFaces,
              theme,
            ),
            _buildChecklistTile(
              loc.tr('ruleFamilySafeContent'),
              item.isAppropriateContent,
              theme,
            ),
            _buildChecklistTile(
              loc.tr('ruleHighClarityQuality'),
              item.isHighQuality,
              theme,
            ),
            const Divider(height: 18),

            // Category & Scores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.tr('detectedCategoryLabel'), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  loc.tr(item.categoryKey),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.tr('relevanceScoreLabel'), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  '${(item.relevanceScore * 100).toInt()}%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.secondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.tr('qualityScoreLabel'), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  '${(item.qualityScore * 100).toInt()}%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.primary),
                ),
              ],
            ),

            if (item.detectedFeatures.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                loc.tr('detectedFeaturesLabel'),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: item.detectedFeatures.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(f, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistTile(String title, bool isPassed, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isPassed ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPassed ? FontWeight.w500 : FontWeight.bold,
                color: isPassed ? theme.colorScheme.onSurface : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRejectionMessage(ImageModerationItem item, AppLocalizations loc) {
    if (item.rejectionReasonKey != null) {
      return loc.tr(item.rejectionReasonKey!);
    }
    if (item.containsPersonsOrFaces) {
      return loc.tr('rejectedContainsPersons');
    }
    if (!item.isRealEstateRelated) {
      return loc.tr('rejectedNonRealEstate');
    }
    if (!item.isAppropriateContent) {
      return loc.tr('rejectedInappropriateContent');
    }
    if (!item.isHighQuality) {
      return loc.tr('rejectedLowQuality');
    }
    return loc.tr('rejectedDefaultExplanation');
  }
}
