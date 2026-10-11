import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/menus/tashil_menus.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/responsive_layout.dart';
import '../models/document_ocr_result_model.dart';
import '../services/ai_document_ocr_service.dart';

class AiDocumentOcrModal extends StatefulWidget {
  final DocumentOcrType initialDocType;
  final String countryCode;
  final String targetParty; // 'lessor', 'tenant', 'property', 'contract'

  const AiDocumentOcrModal({
    super.key,
    this.initialDocType = DocumentOcrType.egyptianNationalId,
    required this.countryCode,
    this.targetParty = 'lessor',
  });

  static Future<DocumentOcrResultModel?> show(
    BuildContext context, {
    DocumentOcrType docType = DocumentOcrType.egyptianNationalId,
    required String countryCode,
    String targetParty = 'lessor',
  }) {
    return TashilTransitions.showM3Dialog<DocumentOcrResultModel>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AiDocumentOcrModal(
        initialDocType: docType,
        countryCode: countryCode,
        targetParty: targetParty,
      ),
    );
  }

  @override
  State<AiDocumentOcrModal> createState() => _AiDocumentOcrModalState();
}

class _AiDocumentOcrModalState extends State<AiDocumentOcrModal> with SingleTickerProviderStateMixin {
  final _service = AiDocumentOcrService();
  
  bool get _isProfileMode => widget.targetParty == 'profile' || widget.targetParty == 'lessor';

  late String _selectedTemplateId;
  String? _customImageUrl;
  String? _activeImageSource;
  bool _isProcessing = false;
  DocumentOcrResultModel? _extractedResult;
  late AnimationController _scanAnimCtrl;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();

    _scanAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanAnimCtrl, curve: Curves.easeInOut),
    );

    // Pick appropriate default sample based on targetParty & countryCode
    if (_isProfileMode) {
      _selectedTemplateId = widget.countryCode == 'AE' ? 'uae_emirates_id_lessor' : 'eg_national_id_lessor';
    } else if (widget.targetParty == 'tenant') {
      _selectedTemplateId = widget.countryCode == 'AE' ? 'uae_emirates_id_tenant' : 'eg_national_id_tenant';
    } else if (widget.targetParty == 'property') {
      _selectedTemplateId = widget.countryCode == 'AE' ? 'title_deed_dubai' : 'title_deed_egypt';
    } else {
      _selectedTemplateId = widget.countryCode == 'AE' ? 'uae_emirates_id_lessor' : 'eg_national_id_lessor';
    }

    _runOcrScan(_selectedTemplateId);
  }

  @override
  void dispose() {
    _scanAnimCtrl.dispose();
    super.dispose();
  }

  int _rotationQuarterTurns = 0;

  void _rotateLeft() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns - 1) % 4;
      if (_rotationQuarterTurns < 0) _rotationQuarterTurns += 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _resetRotation() {
    setState(() {
      _rotationQuarterTurns = 0;
    });
  }

  void _showZoomViewerDialog(BuildContext context, String imageUrl, int quarterTurns) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Container(
                width: 920,
                height: 720,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(40),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: quarterTurns,
                        child: _buildPreviewImage(imageUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 16,
                end: 16,
                child: TashilIconButton.close(
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              PositionedDirectional(
                bottom: 16,
                start: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        loc.tr('zoomCard'),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runOcrScan(String templateId, {String? customImageUrl, Uint8List? rawBytes}) async {
    setState(() {
      _selectedTemplateId = templateId;
      _isProcessing = true;
      _extractedResult = null;
      _rotationQuarterTurns = 0;
    });

    final template = AiDocumentOcrService.sampleTemplates.firstWhere(
      (t) => t['id'] == templateId,
      orElse: () => AiDocumentOcrService.sampleTemplates.first,
    );

    final imageUrl = customImageUrl ?? _customImageUrl ?? (template['imageUrl'] as String);

    final result = await _service.processDocumentOcr(
      docType: template['docType'] as DocumentOcrType,
      countryCode: template['countryCode'] as String,
      sampleId: templateId,
      customImageUrl: imageUrl,
      rawBytes: rawBytes,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _extractedResult = result;
      });
    }
  }

  Future<void> _handlePickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final mime = picked.mimeType ?? 'image/jpeg';
        final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
        setState(() {
          _customImageUrl = dataUri;
          _activeImageSource = source == ImageSource.camera ? 'camera' : 'upload';
          _rotationQuarterTurns = 0;
        });
        await _runOcrScan(_selectedTemplateId, customImageUrl: dataUri, rawBytes: bytes);
      }
    } catch (e) {
      if (mounted) {
        TashilSnackBar.showWarning(
          context: context,
          message: e.toString(),
        );
      }
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 920,
          maxHeight: 820,
        ),
        child: Column(
          children: [
            // Top Modal Header
            _buildHeader(loc),
            const TashilDivider.fullWidth(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document Templates Selector Bar or Profile Dropdown Menu
                    if (_isProfileMode) ...[
                      Text(
                        loc.tr('identityDocumentType'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProfileDropdown(loc),
                      const SizedBox(height: 16),
                    ] else ...[
                      Text(
                        loc.tr('selectDocToScan'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTemplateSelector(lang),
                      const SizedBox(height: 20),
                    ],

                    // Main Scanning & Results Area
                    if (isMobile) ...[
                      _buildScanPreviewArea(loc),
                      const SizedBox(height: 20),
                      _buildResultsArea(loc),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildScanPreviewArea(loc)),
                          const SizedBox(width: 20),
                          Expanded(flex: 6, child: _buildResultsArea(loc)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const TashilDivider.cardAction(),
            // Bottom Action Footer
            _buildBottomFooter(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.document_scanner_rounded, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('aiDocumentOcrTitle'),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.tr('aiDocumentOcrSubtitle'),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TashilIconButton.close(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(String lang) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AiDocumentOcrService.sampleTemplates.map((t) {
          final isSelected = t['id'] == _selectedTemplateId;
          final title = lang == 'ar'
              ? t['titleAr']
              : (lang == 'hi' ? t['titleHi'] : t['titleEn']);

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: InkWell(
              onTap: _isProcessing ? null : () => _runOcrScan(t['id'] as String),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t['badge'] as String,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title as String,
                      style: TextStyle(
                        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
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

  Widget _buildProfileDropdown(AppLocalizations loc) {
    final selectedId = (_selectedTemplateId == 'uae_emirates_id_lessor')
        ? 'uae_emirates_id_lessor'
        : 'eg_national_id_lessor';

    return TashilDropdownMenu<String>(
      value: selectedId,
      prefixIcon: Icons.badge_outlined,
      height: 48,
      items: [
        TashilDropdownMenuItem<String>(
          value: 'eg_national_id_lessor',
          label: loc.tr('egyptianNationalIdShort'),
          icon: Icons.badge_outlined,
        ),
        TashilDropdownMenuItem<String>(
          value: 'uae_emirates_id_lessor',
          label: loc.tr('uaeEmiratesIdShort'),
          icon: Icons.badge_outlined,
        ),
      ],
      onChanged: _isProcessing
          ? null
          : (val) {
              if (val != null && val != _selectedTemplateId) {
                setState(() {
                  _customImageUrl = null;
                  _activeImageSource = null;
                });
                _runOcrScan(val);
              }
            },
    );
  }

  Widget _buildImageSourceButtonGroup(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: TashilConnectedButtonGroup<String>(
              height: 44,
              isFullWidth: true,
              selectedValue: _activeImageSource,
              onSelectionChanged: (val) {
                if (val == 'camera') {
                  _handlePickImage(ImageSource.camera);
                } else if (val == 'upload') {
                  _handlePickImage(ImageSource.gallery);
                }
              },
              segments: [
                TashilConnectedButtonSegment<String>(
                  value: 'camera',
                  label: loc.tr('takePhoto'),
                  icon: Icons.photo_camera_rounded,
                ),
                TashilConnectedButtonSegment<String>(
                  value: 'upload',
                  label: loc.tr('uploadPhoto'),
                  icon: Icons.upload_file_rounded,
                ),
              ],
            ),
          ),
          if (_customImageUrl != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TashilButton.tonal(
                height: 36,
                icon: Icons.refresh_rounded,
                label: loc.tr('resetToSampleDoc'),
                onPressed: _isProcessing
                    ? null
                    : () {
                        setState(() {
                          _customImageUrl = null;
                          _activeImageSource = null;
                          _rotationQuarterTurns = 0;
                        });
                        _runOcrScan(_selectedTemplateId);
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewToolbar(AppLocalizations loc, String currentImageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TashilIconButton.tonal(
                icon: Icons.rotate_left_rounded,
                tooltip: loc.tr('rotateLeft'),
                size: 36,
                iconSize: 18,
                onPressed: _rotateLeft,
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Icons.rotate_right_rounded,
                tooltip: loc.tr('rotateRight'),
                size: 36,
                iconSize: 18,
                onPressed: _rotateRight,
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Icons.zoom_in_rounded,
                tooltip: loc.tr('zoomCard'),
                size: 36,
                iconSize: 18,
                onPressed: () => _showZoomViewerDialog(context, currentImageUrl, _rotationQuarterTurns),
              ),
            ],
          ),
          if (_rotationQuarterTurns != 0)
            TashilButton.text(
              height: 32,
              icon: Icons.replay_rounded,
              label: '${_rotationQuarterTurns * 90}°',
              onPressed: _resetRotation,
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(String imageUrl, {BoxFit fit = BoxFit.contain}) {
    if (imageUrl.startsWith('data:')) {
      try {
        final base64Part = imageUrl.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: fit,
        );
      } catch (_) {}
    }
    return ImageUtils.cachedImage(
      imageUrl: imageUrl,
      fit: fit,
    );
  }

  Widget _buildScanPreviewArea(AppLocalizations loc) {
    final theme = Theme.of(context);
    final template = AiDocumentOcrService.sampleTemplates.firstWhere(
      (t) => t['id'] == _selectedTemplateId,
      orElse: () => AiDocumentOcrService.sampleTemplates.first,
    );

    final currentImageUrl = _customImageUrl ?? (template['imageUrl'] as String);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upload & Live Camera Capture Buttons Group
        _buildImageSourceButtonGroup(loc),

        // Controls Toolbar: Rotate Left, Rotate Right, Interactive Zoom
        _buildPreviewToolbar(loc, currentImageUrl),

        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image with Laser Scanning Line
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 11,
                      child: Container(
                        color: Colors.black87,
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: _rotationQuarterTurns,
                          child: _buildPreviewImage(currentImageUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                if (_isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                if (_isProcessing)
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 220 * _scanAnimation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, theme.colorScheme.primary, Colors.transparent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Document AI Vision',
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Security Status Badge Bar
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  _isProcessing
                      ? Icons.sync_rounded
                      : (_extractedResult?.securityStatus == 'UNREADABLE_IMAGE'
                          ? Icons.warning_amber_rounded
                          : Icons.verified_user_rounded),
                  color: _isProcessing
                      ? theme.colorScheme.primary
                      : (_extractedResult?.securityStatus == 'UNREADABLE_IMAGE'
                          ? theme.colorScheme.error
                          : theme.colorScheme.secondary),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isProcessing
                        ? 'جاري فحص العلامات المائية والهولوجرام...'
                        : (_extractedResult?.securityStatus == 'UNREADABLE_IMAGE'
                            ? loc.tr('unclearImageTitle')
                            : 'معتمد ومطابق للمعايير الأمنية (100% Tamper-Free)'),
                    style: TextStyle(
                      color: _isProcessing
                          ? theme.colorScheme.onSurfaceVariant
                          : (_extractedResult?.securityStatus == 'UNREADABLE_IMAGE'
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
      ],
    );
  }

  Widget _buildResultsArea(AppLocalizations loc) {
    final theme = Theme.of(context);
    if (_isProcessing) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.tr('extractingDocumentData'),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final res = _extractedResult;
    if (res == null) return const SizedBox();

    final isUnreadable = res.securityStatus == 'UNREADABLE_IMAGE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUnreadable) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('unclearImageTitle'),
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.tr('unclearImageDesc'),
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Security Banner with Confidence Score
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('securityAuditPassed'),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${loc.tr('confidenceAccuracy')}: ${(res.confidenceScore * 100).toStringAsFixed(1)}% | Document AI High-Fidelity',
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Extracted Fields List
        Text(
          loc.tr('extractedDataReview'),
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),

        _buildFieldRow('الاسم الكامل (عربي)', res.fullNameAr, Icons.person_outline_rounded),
        _buildFieldRow('الاسم الكامل (إنجليزي)', res.fullNameEn, Icons.badge_outlined),
        _buildFieldRow('رقم الهوية / الرقم القومي', res.idNumber, Icons.credit_card_rounded, isHighlight: true),
        _buildFieldRow('تاريخ الميلاد', res.dateOfBirth, Icons.calendar_today_outlined),
        _buildFieldRow('تاريخ الانتهاء', res.expiryDate, Icons.event_available_outlined),
        _buildFieldRow('العنوان والحي', res.address, Icons.home_outlined),
        _buildFieldRow('المحافظة / الإمارة', res.governorateOrEmirate, Icons.location_city_outlined),

        if (res.titleDeedNumber != null) ...[
          const TashilDivider.middleInset(height: 20),
          _buildFieldRow('رقم صك الملكية', res.titleDeedNumber!, Icons.description_outlined, isHighlight: true),
          if (res.buildingName != null) _buildFieldRow('اسم المبنى', res.buildingName!, Icons.apartment_rounded),
          if (res.unitNumber != null) _buildFieldRow('رقم الوحدة', res.unitNumber!, Icons.meeting_room_outlined),
          if (res.areaSqm != null) _buildFieldRow('المساحة', '${res.areaSqm!.toInt()} متر مربع', Icons.square_foot_rounded),
          if (res.makaniNumber != null) _buildFieldRow('رقم مكاني', res.makaniNumber!, Icons.tag_rounded),
        ],

        if (res.annualRent != null) ...[
          const TashilDivider.middleInset(height: 20),
          _buildFieldRow('القيمة الإيجارية السنوية', '${res.annualRent!.toInt()} ${res.countryCode == 'AE' ? 'درهم' : 'جنيه'}', Icons.attach_money_rounded, isHighlight: true),
          if (res.chequesCount != null) _buildFieldRow('عدد الدفعات والشيكات', '${res.chequesCount} دفعات', Icons.payments_outlined),
        ],
      ],
    );
  }

  Widget _buildFieldRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlight
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              '$label:',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomFooter(AppLocalizations loc) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TashilButton.text(
            onPressed: () => Navigator.of(context).pop(),
            label: loc.tr('cancel'),
          ),
          TashilButton(
            onPressed: _extractedResult == null || _isProcessing || _extractedResult!.securityStatus == 'UNREADABLE_IMAGE'
                ? null
                : () {
                    Navigator.of(context).pop(_extractedResult);
                  },
            icon: _isProfileMode ? Icons.task_alt_rounded : Icons.flash_on_rounded,
            label: _isProfileMode ? loc.tr('applyExtractedData') : loc.tr('autoFillIntoLease'),
          ),
        ],
      ),
    );
  }
}
