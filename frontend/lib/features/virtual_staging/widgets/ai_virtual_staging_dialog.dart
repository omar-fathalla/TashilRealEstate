import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../public_marketplace/models/property_item.dart';
import '../models/virtual_staging_model.dart';
import '../services/ai_virtual_staging_service.dart';
import 'virtual_staging_comparison_slider.dart';

class AiVirtualStagingDialog extends StatefulWidget {
  final PropertyItem? property;
  final String? initialImageUrl;

  const AiVirtualStagingDialog({
    super.key,
    this.property,
    this.initialImageUrl,
  });

  static Future<void> show(
    BuildContext context, {
    PropertyItem? property,
    String? initialImageUrl,
  }) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AiVirtualStagingDialog(
        property: property,
        initialImageUrl: initialImageUrl,
      ),
    );
  }

  @override
  State<AiVirtualStagingDialog> createState() => _AiVirtualStagingDialogState();
}

class _AiVirtualStagingDialogState extends State<AiVirtualStagingDialog> {
  final _service = AiVirtualStagingService();

  StagingRoomType _selectedRoomType = StagingRoomType.livingRoom;
  VirtualStagingStyle _selectedStyle = VirtualStagingStyle.modernLuxury;
  bool _isGenerating = false;
  VirtualStagingPair? _currentPair;
  int _variationIndex = 0;
  int _regenerationAttemptsLeft = 3;
  static const int maxRegenerations = 3;
  String _selectedAction = 'save';

  @override
  void initState() {
    super.initState();
    _generateStage();
  }

  Future<void> _generateStage({bool isRegeneration = false}) async {
    if (isRegeneration) {
      if (_regenerationAttemptsLeft <= 0) {
        if (mounted) {
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.tr('stagingQuotaExhaustedSnack')),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      setState(() {
        _regenerationAttemptsLeft--;
        _variationIndex++;
      });
    }

    setState(() => _isGenerating = true);
    final baseImg = widget.initialImageUrl ??
        (widget.property != null && widget.property!.imageUrls.isNotEmpty
            ? widget.property!.imageUrls.first
            : null) ??
        'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=1200&q=80';

    final pair = await _service.generateVirtualStage(
      baseImageUrl: baseImg,
      roomType: _selectedRoomType,
      style: _selectedStyle,
      variation: _variationIndex,
    );

    if (mounted) {
      setState(() {
        _currentPair = pair;
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1080,
        height: 740,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // Header
            _buildHeader(loc),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 14),

            // Room Type Selector Tabs
            _buildRoomTypeSelector(loc),
            const SizedBox(height: 14),

            // Main Body: Comparison Slider & Style Options
            Expanded(
              child: isMobile
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSliderArea(loc),
                          const SizedBox(height: 16),
                          _buildRightControlPane(loc, lang),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Interactive Comparison Slider
                        Expanded(
                          flex: 6,
                          child: _buildSliderArea(loc),
                        ),
                        const SizedBox(width: 20),

                        // Right: Style Selection & Furniture Items
                        Expanded(
                          flex: 4,
                          child: _buildRightControlPane(loc, lang),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.chair_rounded, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    loc.tr('virtualStagingDialogTitle'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Google Imagen 3',
                      style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('virtualStagingDialogSubtitle'),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        TashilIconButton.standard(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icons.close_rounded,
        ),
      ],
    );
  }

  Widget _buildRoomTypeSelector(AppLocalizations loc) {
    final theme = Theme.of(context);
    final types = [
      (StagingRoomType.livingRoom, loc.tr('roomLivingRoom'), Icons.weekend_rounded),
      (StagingRoomType.masterBedroom, loc.tr('roomMasterBedroom'), Icons.bed_rounded),
      (StagingRoomType.diningRoom, loc.tr('roomDiningRoom'), Icons.table_restaurant_rounded),
      (StagingRoomType.homeOffice, loc.tr('roomHomeOffice'), Icons.desk_rounded),
      (StagingRoomType.balconyTerrace, loc.tr('roomBalconyTerrace'), Icons.balcony_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((item) {
          final isSelected = _selectedRoomType == item.$1;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () {
                if (_selectedRoomType != item.$1) {
                  setState(() {
                    _selectedRoomType = item.$1;
                    _variationIndex = 0;
                  });
                  _generateStage();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$3,
                      size: 16,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSliderArea(AppLocalizations loc) {
    final theme = Theme.of(context);
    if (_isGenerating || _currentPair == null) {
      return Container(
        height: 440,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr('generatingVirtualStageProgress'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                loc.tr('imagen3InferencePreserveBounds'),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VirtualStagingComparisonSlider(
          beforeImageUrl: _currentPair!.originalEmptyImageUrl,
          afterImageUrl: _currentPair!.stagedImageUrl,
          height: 430,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                loc.tr('sliderDragHint'),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightControlPane(AppLocalizations loc, String lang) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr('selectStagingStyle'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 10),

          // Style Cards
          ..._service.availableStyles.map((stylePreset) {
            final isSelected = _selectedStyle == stylePreset.style;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: InkWell(
                onTap: () {
                  if (_selectedStyle != stylePreset.style) {
                    setState(() {
                      _selectedStyle = stylePreset.style;
                      _variationIndex = 0;
                    });
                    _generateStage();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Text(stylePreset.iconEmoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stylePreset.getName(lang),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stylePreset.getDescription(lang),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isSelected ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),

          // Staged Furniture Elements Tags
          if (_currentPair != null) ...[
            Text(
              loc.tr('stagedFurnitureElements'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _currentPair!.getFurnitureElements(lang).map((elem) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 12, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        elem,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Actions: Connected Button Group (M3 Specification)
          TashilConnectedButtonGroup<String>(
            height: 44.0,
            isFullWidth: true,
            selectedValue: _selectedAction,
            onSelectionChanged: (action) {
              setState(() => _selectedAction = action);
              if (action == 'regenerate') {
                _generateStage(isRegeneration: true);
              } else if (action == 'save') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      loc.tr('virtualStagingSavedNotification'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: theme.colorScheme.inverseSurface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            segments: [
              TashilConnectedButtonSegment<String>(
                value: 'regenerate',
                label: _regenerationAttemptsLeft > 0
                    ? '${loc.tr('regenerateStagingBtn')} ($_regenerationAttemptsLeft/$maxRegenerations)'
                    : loc.tr('stagingQuotaExhausted'),
                icon: Icons.refresh_rounded,
                enabled: _regenerationAttemptsLeft > 0 && !_isGenerating,
              ),
              TashilConnectedButtonSegment<String>(
                value: 'save',
                label: loc.tr('saveStagedPhotoBtn'),
                icon: Icons.share_rounded,
                enabled: !_isGenerating && _currentPair != null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
