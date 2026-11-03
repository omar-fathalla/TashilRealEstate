import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/responsive_layout.dart';
import '../models/vision_maintenance_model.dart';
import '../services/ai_vision_maintenance_service.dart';
import '../../owner_portal/services/property_lifecycle_service.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiVisionMaintenanceDialog extends StatefulWidget {
  final String? initialPhotoUrl;

  const AiVisionMaintenanceDialog({
    super.key,
    this.initialPhotoUrl,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialPhotoUrl,
  }) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AiVisionMaintenanceDialog(
        initialPhotoUrl: initialPhotoUrl,
      ),
    );
  }

  @override
  State<AiVisionMaintenanceDialog> createState() =>
      _AiVisionMaintenanceDialogState();
}

class _AiVisionMaintenanceDialogState extends State<AiVisionMaintenanceDialog> {
  final _service = AiVisionMaintenanceService();

  late String _selectedPhotoUrl;
  String? _selectedSampleId;
  bool _isAnalyzing = false;
  VisionMaintenanceDiagnosisResult? _result;

  @override
  void initState() {
    super.initState();
    final samples = _service.samplePhotos;
    _selectedPhotoUrl = widget.initialPhotoUrl ?? samples.first.photoUrl;
    _selectedSampleId = samples.first.id;
    _runDiagnosis();
  }

  Future<void> _runDiagnosis() async {
    setState(() => _isAnalyzing = true);
    final country = CountryController.countryCode;

    final diag = await _service.diagnosePhoto(
      photoUrl: _selectedPhotoUrl,
      countryCode: country,
      sampleId: _selectedSampleId,
    );

    if (mounted) {
      setState(() {
        _result = diag;
        _isAnalyzing = false;
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
        width: 960,
        height: 760,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // Header
            _buildHeader(theme, loc),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 14),

            // Sample Photos Carousel / Selector
            _buildPhotoPresetsBar(theme, loc, lang),
            const SizedBox(height: 14),

            // Main Body: Photo Preview & Diagnosis Details
            Expanded(
              child: isMobile
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildPhotoPreviewWithLaser(theme),
                          const SizedBox(height: 16),
                          _buildDiagnosisResultPane(theme, loc, lang),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Photo Scan Preview
                        Expanded(
                          flex: 4,
                          child: _buildPhotoPreviewWithLaser(theme),
                        ),
                        const SizedBox(width: 20),

                        // Right: Structured AI Results
                        Expanded(
                          flex: 6,
                          child: _buildDiagnosisResultPane(theme, loc, lang),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations loc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Symbols.troubleshoot_rounded,
            color: theme.colorScheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    loc.tr('visionMaintenanceTitle'),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      AppLocalizations.trStatic('uiCopy050'),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('visionMaintenanceSubtitle'),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        TashilIconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: loc.tr('close'),
          icon: Symbols.close_rounded,
        ),
      ],
    );
  }

  Widget _buildPhotoPresetsBar(ThemeData theme, AppLocalizations loc, String lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _service.samplePhotos.map((sample) {
          final isSelected = _selectedSampleId == sample.id;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: InkWell(
              onTap: () {
                if (_selectedSampleId != sample.id) {
                  setState(() {
                    _selectedSampleId = sample.id;
                    _selectedPhotoUrl = sample.photoUrl;
                  });
                  _runDiagnosis();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ImageUtils.cachedImage(
                        imageUrl: sample.photoUrl,
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sample.getTitle(lang),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
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

  Widget _buildPhotoPreviewWithLaser(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          ImageUtils.cachedImage(
            imageUrl: _selectedPhotoUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.scrim.withValues(alpha: 0.4),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Gemini Vision Scanning...',
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.camera_alt_rounded, size: 12, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Uploaded Defect Photo',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisResultPane(ThemeData theme, AppLocalizations loc, String lang) {
    if (_isAnalyzing || _result == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    final res = _result!;
    final isUrgent = res.urgency == MaintenanceUrgencyLevel.critical;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency & Confidence Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUrgent
                        ? theme.colorScheme.error.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUrgent ? Symbols.warning_rounded : Symbols.info_rounded,
                      size: 14,
                      color: isUrgent ? theme.colorScheme.error : theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUrgent ? loc.tr('urgencyCritical') : loc.tr('urgencyHigh'),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                        color: isUrgent ? theme.colorScheme.error : theme.colorScheme.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.verified_rounded, size: 14, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      '${(res.confidenceScore * 100).toStringAsFixed(1)}% ${loc.tr('diagnosisConfidence')}',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Problem Title
          Text(
            res.getTitle(lang),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),

          // Root Cause Analysis Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Symbols.psychology_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      loc.tr('rootCauseAnalysisTitle'),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  res.getRootCause(lang),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Estimated Repair Cost & Assigned Technician
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('estimatedRepairCost'),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${res.estimatedCostMin.toInt()} - ${res.estimatedCostMax.toInt()} ${res.currencyCode}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('assignedTechnicianLabel'),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        res.getTechnicianType(lang),
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Spare Parts Needed
          Text(
            loc.tr('requiredSparePartsTitle'),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: res.getSpareParts(lang).map((part) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.build_circle_rounded, size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      part,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action Button: Dispatch Certified Tech
          SizedBox(
            width: double.infinity,
            child: TashilButton(
              onPressed: () {
                final country = CountryController.countryCode;
                final userProps = PropertyLifecycleService().propertiesNotifier.value
                    .where((p) => p.countryCode == country)
                    .toList();
                final linkedProp = userProps.firstOrNull;

                _service.createTicketFromDiagnosis(
                  diagnosis: res,
                  countryCode: country,
                  propertyId: linkedProp?.id,
                  propertyTitle: linkedProp?.titles,
                );

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      loc.tr('technicianDispatchedSuccessNotification'),
                      style: TextStyle(color: theme.colorScheme.onPrimary),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Symbols.engineering_rounded,
              label: loc.tr('dispatchTechnicianBtn'),
            ),
          ),
        ],
      ),
    );
  }
}
