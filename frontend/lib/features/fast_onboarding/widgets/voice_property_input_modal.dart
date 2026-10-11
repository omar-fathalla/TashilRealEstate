import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/services/speech_recognition/speech_recognition_service.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/fast_onboarding/services/gemini_onboarding_service.dart';

enum VoiceInputStep {
  listening,
  ready,
  parsing,
}

class MandatoryFieldStatus {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final bool isComplete;
  final String? detectedValue;
  final List<String> sampleChips;
  final bool isMandatory;
  final String missingWarningText;

  const MandatoryFieldStatus({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.isComplete,
    this.detectedValue,
    required this.sampleChips,
    this.isMandatory = true,
    this.missingWarningText = '',
  });
}

class VoicePropertyInputModal extends StatefulWidget {
  const VoicePropertyInputModal({super.key});

  static Future<FastPropertyDraft?> show(BuildContext context) {
    return TashilTransitions.showM3Dialog<FastPropertyDraft>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const VoicePropertyInputModal(),
    );
  }

  @override
  State<VoicePropertyInputModal> createState() => _VoicePropertyInputModalState();
}

class _VoicePropertyInputModalState extends State<VoicePropertyInputModal> {
  final _service = GeminiOnboardingService();
  final _speechService = SpeechRecognitionService();
  final _transcriptionController = TextEditingController();

  VoiceInputStep _step = VoiceInputStep.ready;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  String? _errorMessage;
  int _mobileSelectedTab = 0; // 0 = recording, 1 = guide
  bool _showMissingWarning = false;
  String _baseTranscript = '';

  @override
  void initState() {
    super.initState();
    _transcriptionController.text = '';
    _transcriptionController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupSpeechCallbacks();
        _startListening();
      }
    });
  }

  void _onTextChanged() {
    if (!mounted) return;
    final text = _transcriptionController.text.trim();
    if (_showMissingWarning && text.isNotEmpty) {
      final countryCode = CountryController.isUAE ? 'AE' : 'EG';
      final draft = _service.parseVoiceHeuristically(text, countryCode);
      final isLocationOk = draft.city.isNotEmpty && draft.district.isNotEmpty;
      final isRentOk = draft.monthlyRent > 0;
      final isAreaOk = draft.areaSqm > 0;
      final isBedsOk = draft.bedrooms > 0 || draft.propertyType == 'studio';
      final isBathsOk = draft.bathrooms > 0;
      if (isLocationOk && isRentOk && isAreaOk && isBedsOk && isBathsOk) {
        _showMissingWarning = false;
      }
    }
    setState(() {});
  }

  void _setupSpeechCallbacks() {
    _speechService.setCallbacks(
      onResult: (transcript) {
        if (!mounted) return;
        setState(() {
          if (_baseTranscript.isNotEmpty) {
            _transcriptionController.text = '$_baseTranscript، $transcript';
          } else {
            _transcriptionController.text = transcript;
          }
          _errorMessage = null;
        });
      },
      onError: (error) {
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        setState(() {
          if (error == 'not-allowed' || error == 'permission_denied') {
            _errorMessage = loc.tr('speechMicPermissionDenied');
          } else if (error == 'not_supported') {
            _errorMessage = loc.tr('speechRecognitionNotSupported');
          } else if (error != 'no-speech') {
            _errorMessage = error;
          }
        });
      },
      onEnd: (finalTranscript) {
        if (!mounted) return;
        if (_step == VoiceInputStep.listening) {
          _stopListening();
        }
      },
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _speechService.stopListening();
    _transcriptionController.removeListener(_onTextChanged);
    _transcriptionController.dispose();
    super.dispose();
  }

  void _startListening({bool appendMode = false}) {
    _recordingTimer?.cancel();

    setState(() {
      _step = VoiceInputStep.listening;
      _recordingSeconds = 0;
      _errorMessage = null;
      _baseTranscript = appendMode ? _transcriptionController.text.trim() : '';
    });

    final loc = AppLocalizations.of(context);
    final countryCode = CountryController.isUAE ? 'AE' : 'EG';
    final started = _speechService.startListening(
      languageCode: loc.locale.languageCode,
      countryCode: countryCode,
    );

    if (!started && !_speechService.isSupported) {
      setState(() {
        _errorMessage = loc.tr('speechRecognitionNotSupported');
      });
    }

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _recordingSeconds++);
    });
  }

  void _stopListening() {
    _recordingTimer?.cancel();
    final captured = _speechService.stopListening();

    setState(() {
      _step = VoiceInputStep.ready;
      if (captured.trim().isNotEmpty && _transcriptionController.text.trim().isEmpty) {
        _transcriptionController.text = captured;
      }
    });
  }

  void _appendSampleKeyword(String keyword) {
    final current = _transcriptionController.text.trim();
    if (current.isEmpty) {
      _transcriptionController.text = keyword;
    } else {
      _transcriptionController.text = '$current، $keyword';
    }
    setState(() {
      _step = VoiceInputStep.ready;
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatPropertyType(String type) {
    switch (type.toLowerCase()) {
      case 'villa':
        return 'فيلا';
      case 'studio':
        return 'استوديو';
      case 'chalet':
        return 'شاليه';
      case 'penthouse':
        return 'بنتهاوس';
      case 'office':
        return 'مكتب';
      default:
        return 'شقة سكنية';
    }
  }

  String _formatFurnishing(FurnishingStatus status) {
    switch (status) {
      case FurnishingStatus.fullyFurnished:
        return 'مفروش بالكامل';
      case FurnishingStatus.semiFurnished:
        return 'نصف مفروش';
      case FurnishingStatus.unfurnished:
        return 'غير مفروش';
    }
  }

  String _formatAmenitiesSummary(FastPropertyDraft draft) {
    final list = <String>[];
    if (draft.hasParking) list.add('موقف');
    if (draft.hasCentralAc) list.add('تكييف');
    if (draft.hasPoolGym) list.add('مسبح/جيم');
    if (draft.hasSecurity) list.add('أمن');
    if (draft.hasBalconyView) list.add('شرفة');
    if (draft.isPetFriendly) list.add('حيوانات');
    return list.isNotEmpty ? list.join('، ') : 'بدون مرافق إضافية';
  }

  List<MandatoryFieldStatus> _buildFieldStatuses(String text, String countryCode) {
    final isUAE = countryCode == 'AE';
    final draft = _service.parseVoiceHeuristically(text, countryCode);

    final isLocationOk = draft.city.isNotEmpty && draft.district.isNotEmpty;
    final isRentOk = draft.monthlyRent > 0;
    final isAreaOk = draft.areaSqm > 0;
    final isBedsOk = draft.bedrooms > 0 || draft.propertyType == 'studio';
    final isBathsOk = draft.bathrooms > 0;

    return [
      // 1. Mandatory Location
      MandatoryFieldStatus(
        icon: Icons.location_on_rounded,
        titleKey: 'guideFieldLocation',
        descKey: 'guideFieldLocationDesc',
        isComplete: isLocationOk,
        detectedValue: isLocationOk ? '${draft.city} - ${draft.district}' : null,
        missingWarningText: 'الموقع الجغرافي (المدينة والحي)',
        sampleChips: const [],
        isMandatory: true,
      ),
      // 2. Mandatory Rent
      MandatoryFieldStatus(
        icon: Icons.payments_rounded,
        titleKey: 'guideFieldRent',
        descKey: 'guideFieldRentDesc',
        isComplete: isRentOk,
        detectedValue: isRentOk ? '${draft.monthlyRent.toInt()} ${isUAE ? "AED" : "ج.م"}' : null,
        missingWarningText: 'قيمة الإيجار الشهري المطلوب',
        sampleChips: const [],
        isMandatory: true,
      ),
      // 3. Mandatory Area & Type
      MandatoryFieldStatus(
        icon: Icons.square_foot_rounded,
        titleKey: 'guideFieldAreaOnly',
        descKey: 'guideFieldAreaOnlyDesc',
        isComplete: isAreaOk,
        detectedValue: isAreaOk ? '${draft.areaSqm} م² (${_formatPropertyType(draft.propertyType)})' : null,
        missingWarningText: 'المساحة بالمتر المربع ونوع العقار',
        sampleChips: const [],
        isMandatory: true,
      ),
      // 4. Mandatory Bedrooms
      MandatoryFieldStatus(
        icon: Icons.bed_rounded,
        titleKey: 'guideFieldBedrooms',
        descKey: 'guideFieldBedroomsDesc',
        isComplete: isBedsOk,
        detectedValue: isBedsOk
            ? (draft.propertyType == 'studio' ? 'استوديو (0 غرف)' : '${draft.bedrooms} غرف نوم')
            : null,
        missingWarningText: 'عدد غرف النوم',
        sampleChips: const ['غرفة واحدة', 'غرفتين نوم', '3 غرف نوم', '4 غرف نوم'],
        isMandatory: true,
      ),
      // 5. Mandatory Bathrooms
      MandatoryFieldStatus(
        icon: Icons.bathtub_rounded,
        titleKey: 'guideFieldBathrooms',
        descKey: 'guideFieldBathroomsDesc',
        isComplete: isBathsOk,
        detectedValue: isBathsOk ? '${draft.bathrooms} حمام' : null,
        missingWarningText: 'عدد الحمامات',
        sampleChips: const ['1 حمام', '2 حمام', '3 حمامات'],
        isMandatory: true,
      ),
      // 6. Mandatory Furnishing
      MandatoryFieldStatus(
        icon: Icons.chair_rounded,
        titleKey: 'guideFieldFurnishing',
        descKey: 'guideFieldFurnishingDesc',
        isComplete: true,
        detectedValue: _formatFurnishing(draft.furnishingStatus),
        missingWarningText: 'حالة الفرش والتأثيث',
        sampleChips: const ['غير مفروش', 'مفروش بالكامل', 'نصف مفروش'],
        isMandatory: true,
      ),

      // 7. Optional Building / Street / Unit
      MandatoryFieldStatus(
        icon: Icons.signpost_rounded,
        titleKey: 'guideFieldBuildingAddress',
        descKey: 'guideFieldBuildingAddressDesc',
        isComplete: (draft.buildingName != null && draft.buildingName!.isNotEmpty) ||
            (draft.streetAddress != null && draft.streetAddress!.isNotEmpty) ||
            (draft.unitNumber != null && draft.unitNumber!.isNotEmpty),
        detectedValue: [
          if (draft.unitNumber != null && draft.unitNumber!.isNotEmpty) 'وحدة ${draft.unitNumber}',
          if (draft.buildingName != null && draft.buildingName!.isNotEmpty) draft.buildingName,
          if (draft.streetAddress != null && draft.streetAddress!.isNotEmpty) draft.streetAddress,
        ].join(' - '),
        sampleChips: const [],
        isMandatory: false,
      ),
      // 8. Optional Floor & Finishing
      MandatoryFieldStatus(
        icon: Icons.layers_rounded,
        titleKey: 'guideFieldFloorFinishing',
        descKey: 'guideFieldFloorFinishingDesc',
        isComplete: draft.floor != null,
        detectedValue: draft.floor != null ? 'الدور ${draft.floor}' : null,
        sampleChips: const [],
        isMandatory: false,
      ),
      // 9. Optional Security Deposit
      MandatoryFieldStatus(
        icon: Icons.security_rounded,
        titleKey: 'guideFieldRentAndDeposit',
        descKey: 'guideFieldRentAndDepositDesc',
        isComplete: draft.securityDeposit != null && draft.securityDeposit! > 0,
        detectedValue: draft.securityDeposit != null ? '${draft.securityDeposit!.toInt()} ${isUAE ? "AED" : "ج.م"}' : null,
        sampleChips: const [],
        isMandatory: false,
      ),
      // 10. Optional Amenities
      MandatoryFieldStatus(
        icon: Icons.pool_rounded,
        titleKey: 'guideFieldAmenities',
        descKey: 'guideFieldAmenitiesDesc',
        isComplete: draft.hasParking || draft.hasCentralAc || draft.hasPoolGym || draft.hasSecurity || draft.hasBalconyView || draft.isPetFriendly,
        detectedValue: _formatAmenitiesSummary(draft),
        sampleChips: const [],
        isMandatory: false,
      ),
    ];
  }

  Future<void> _processVoice({bool bypassValidation = false}) async {
    final text = _transcriptionController.text.trim();
    if (text.isEmpty || _step == VoiceInputStep.parsing) return;

    final countryCode = CountryController.isUAE ? 'AE' : 'EG';
    final heuristicDraft = _service.parseVoiceHeuristically(text, countryCode);

    if (!bypassValidation) {
      final isLocationOk = heuristicDraft.city.isNotEmpty && heuristicDraft.district.isNotEmpty;
      final isRentOk = heuristicDraft.monthlyRent > 0;
      final isAreaOk = heuristicDraft.areaSqm > 0;
      final isBedsOk = heuristicDraft.bedrooms > 0 || heuristicDraft.propertyType == 'studio';
      final isBathsOk = heuristicDraft.bathrooms > 0;

      final isAllMandatoryOk = isLocationOk && isRentOk && isAreaOk && isBedsOk && isBathsOk;

      if (!isAllMandatoryOk) {
        setState(() {
          _showMissingWarning = true;
        });
        return;
      }
    }

    _recordingTimer?.cancel();
    _speechService.stopListening();

    setState(() => _step = VoiceInputStep.parsing);

    final draft = await _service.parseVoiceTranscriptionToDraft(
      voiceTranscription: text,
      countryCode: countryCode,
    );

    if (mounted) {
      setState(() => _step = VoiceInputStep.ready);
      Navigator.of(context).pop(draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 960 : 660,
          maxHeight: 780,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with shaded close button
              _buildHeader(loc, theme),
              const Divider(height: 20),

              // Mobile Segmented Switch (if compact)
              if (!isWide) ...[
                _buildMobileSegmentedSwitch(loc, theme),
                const SizedBox(height: 12),
              ],

              // Content Area
              Expanded(
                child: isWide
                    ? _buildWideDualPane(loc)
                    : (_mobileSelectedTab == 0 ? _buildRecordingPane(loc) : _buildGuidancePane(loc)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.mic_rounded, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('voicePropertyOnboardingTitle'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loc.tr('speakOrTypePropertySpecsDesc'),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Shaded M3 Close Button as per rule
        TashilIconButton.close(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: loc.tr('close'),
        ),
      ],
    );
  }

  Widget _buildMobileSegmentedSwitch(AppLocalizations loc, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _mobileSelectedTab = 0),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _mobileSelectedTab == 0 ? theme.colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _mobileSelectedTab == 0
                      ? [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.08), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      size: 15,
                      color: _mobileSelectedTab == 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.tr('tabVoiceRecord'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _mobileSelectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _mobileSelectedTab == 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _mobileSelectedTab = 1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _mobileSelectedTab == 1 ? theme.colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _mobileSelectedTab == 1
                      ? [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.08), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 15,
                      color: _mobileSelectedTab == 1 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.tr('tabRequiredFieldsGuide'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _mobileSelectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _mobileSelectedTab == 1 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideDualPane(AppLocalizations loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left (Recording & Transcription)
        Expanded(
          flex: 11,
          child: _buildRecordingPane(loc),
        ),
        const SizedBox(width: 18),
        const VerticalDivider(width: 1),
        const SizedBox(width: 18),
        // Right (Required Fields Interactive Guide)
        Expanded(
          flex: 11,
          child: _buildGuidancePane(loc),
        ),
      ],
    );
  }

  Widget _buildRecordingPane(AppLocalizations loc) {
    final theme = Theme.of(context);
    final text = _transcriptionController.text.trim();
    final wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    final countryCode = CountryController.isUAE ? 'AE' : 'EG';
    final allStatuses = _buildFieldStatuses(text, countryCode);
    final missingMandatory = allStatuses.where((s) => s.isMandatory && !s.isComplete).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Interactive Audio Recording Card
          _buildInteractiveAudioCard(loc),
          const SizedBox(height: 14),

          // Error Message Banner if any
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Spoken Text Input Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  loc.tr('spokenVoiceTranscription'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_step == VoiceInputStep.listening)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          loc.tr('speechListeningLive'),
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else if (wordCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$wordCount كلمة',
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // TextField for Spoken Input
          TextField(
            controller: _transcriptionController,
            maxLines: 5,
            readOnly: _step == VoiceInputStep.parsing,
            style: const TextStyle(fontSize: 13, height: 1.45),
            decoration: InputDecoration(
              hintText: _step == VoiceInputStep.listening
                  ? loc.tr('speakNowPlaceholder')
                  : loc.tr('voiceInputPlaceholder'),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // No Speech Detected Banner
          if (_step == VoiceInputStep.ready && text.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded, size: 16, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.tr('speechNoWordsDetected'),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Missing Mandatory Warning Card (if user clicked Parse before completing all fields)
          if (_showMissingWarning && missingMandatory.isNotEmpty) ...[
            _buildMissingFieldsWarningCard(loc, theme, missingMandatory),
            const SizedBox(height: 14),
          ],

          // Sample Prompts / Quick Fill Chips
          _buildQuickSamplePrompts(loc),
          const SizedBox(height: 16),

          // Parse & Fill Button
          TashilButton(
            onPressed: (_step == VoiceInputStep.parsing || text.isEmpty) ? null : () => _processVoice(bypassValidation: false),
            icon: _step == VoiceInputStep.parsing ? null : Icons.auto_awesome_rounded,
            label: _step == VoiceInputStep.parsing
                ? loc.tr('geminiParsingSpeech')
                : loc.tr('parseAndAutofillWithAi'),
            isLoading: _step == VoiceInputStep.parsing,
            variant: TashilButtonVariant.filled,
          ),
        ],
      ),
    );
  }

  Widget _buildMissingFieldsWarningCard(
    AppLocalizations loc,
    ThemeData theme,
    List<MandatoryFieldStatus> missingList,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.tr('missingMandatoryWarning'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            loc.tr('missingMandatoryDesc'),
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          // List of missing mandatory fields formatted cleanly to avoid flex overflow
          ...missingList.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.missingWarningText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (m.sampleChips.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: m.sampleChips.take(2).map((chip) {
                        return TashilAssistChip.outlined(
                          label: chip,
                          icon: Icons.add_rounded,
                          height: 24.0,
                          borderRadius: 6.0,
                          onPressed: () => _appendSampleKeyword(chip),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          // Action Buttons: Speak Missing Data vs Continue Anyway
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TashilButton(
                  onPressed: () => _startListening(appendMode: true),
                  icon: Icons.mic_rounded,
                  label: loc.tr('speakMissingFieldsBtn'),
                  variant: TashilButtonVariant.filled,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TashilButton.outlined(
                  onPressed: () => _processVoice(bypassValidation: true),
                  label: loc.tr('continueManualFillBtn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveAudioCard(AppLocalizations loc) {
    final theme = Theme.of(context);
    if (_step == VoiceInputStep.listening) {
      // 1. Listening State (Active Mic)
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _stopListening,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.graphic_eq_rounded, color: theme.colorScheme.onError, size: 30),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.tr('listeningToVoiceInput'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, size: 8, color: theme.colorScheme.onError),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(_recordingSeconds),
                            style: TextStyle(
                              color: theme.colorScheme.onError,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop_rounded, size: 14, color: theme.colorScheme.error),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              loc.tr('tapToStopRecordingAndReview'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Ready / Review State
    final hasText = _transcriptionController.text.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startListening(appendMode: false),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasText
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasText ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasText ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (hasText ? theme.colorScheme.primary : theme.shadowColor).withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    hasText ? Icons.check_circle_rounded : Icons.mic_rounded,
                    color: hasText ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasText ? loc.tr('recordingCompletedReviewText') : loc.tr('tapMicToSpeak'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: hasText ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                hasText ? loc.tr('reviewTextInstructions') : loc.tr('speakOrTypePropertySpecsDesc'),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TashilButton.outlined(
                onPressed: () => _startListening(appendMode: false),
                icon: Icons.refresh_rounded,
                label: loc.tr('recordAgainBtn'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSamplePrompts(AppLocalizations loc) {
    final isUAE = CountryController.isUAE;
    final sampleAudioPromptsEG = [
      'شقة 90 متر في بحري، الإسكندرية، 2 غرفة و1 حمام، غير مفروشة، إيجار 5000 جنيه',
      'شقة 180 متر بالتجمع الخامس، 3 غرف نوم و2 حمام، مفروشة، إيجار 24 ألف جنيه',
      'دوبلكس 250 متر في الشيخ زايد، 4 غرف، حديقة خاصة، نصف مفروش، 35 ألف جنيه',
    ];

    final sampleAudioPromptsAE = [
      '2BR luxury apartment in Dubai Marina, 140 sqm, fully furnished, 12,000 AED/month',
      '1BR modern apartment in Downtown Burj Khalifa view, high floor, 14,500 AED/month',
      'Studio in JVC, furnished with pool and gym, 6,500 AED/month',
    ];

    final prompts = isUAE ? sampleAudioPromptsAE : sampleAudioPromptsEG;

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = prompts[index];
          return TashilSuggestionChip(
            label: p,
            icon: Icons.mic_none_rounded,
            variant: TashilChipVariant.outlined,
            onPressed: () {
              setState(() {
                _transcriptionController.text = p;
                _step = VoiceInputStep.ready;
                _showMissingWarning = false;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildGuidancePane(AppLocalizations loc) {
    final theme = Theme.of(context);
    final text = _transcriptionController.text.trim();
    final countryCode = CountryController.isUAE ? 'AE' : 'EG';
    final allStatuses = _buildFieldStatuses(text, countryCode);

    final mandatoryItems = allStatuses.where((s) => s.isMandatory).toList();
    final optionalItems = allStatuses.where((s) => !s.isMandatory).toList();

    // The 5 core mandatory criteria: Location, Rent, Area, Beds, Baths
    final coreMandatoryChecks = mandatoryItems.take(5).toList();
    final completedCount = coreMandatoryChecks.where((s) => s.isComplete).length;
    final isAllComplete = completedCount == coreMandatoryChecks.length;
    final progress = completedCount / coreMandatoryChecks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Description
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment_outlined, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.tr('requiredFieldsGuideTitle'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          loc.tr('requiredFieldsGuideDesc'),
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),

        // Progress Capsule Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isAllComplete
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isAllComplete ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isAllComplete ? Icons.verified_rounded : Icons.pie_chart_outline_rounded,
                          size: 15,
                          color: isAllComplete ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isAllComplete
                                ? loc.tr('allMandatoryFieldsComplete')
                                : loc.tr('mandatoryProgressBadge').replaceAll('{count}', '$completedCount').replaceAll('{total}', '${coreMandatoryChecks.length}'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAllComplete ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAllComplete ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAllComplete ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Scrollable List of Fields
        Expanded(
          child: ListView(
            children: [
              // Mandatory Header
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: theme.colorScheme.error, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.tr('mandatoryFieldsSectionTitle'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...mandatoryItems.map((item) => _buildStatusCard(item, loc, theme)),

              const SizedBox(height: 12),
              // Optional Header
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: theme.colorScheme.outline, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.tr('optionalFieldsSectionTitle'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...optionalItems.map((item) => _buildStatusCard(item, loc, theme)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(MandatoryFieldStatus item, AppLocalizations loc, ThemeData theme) {
    final isDone = item.isComplete;
    final isMissingMandatory = item.isMandatory && !isDone;

    final borderColor = isMissingMandatory
        ? theme.colorScheme.error.withValues(alpha: 0.45)
        : (isDone ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant);

    final bgColor = isMissingMandatory
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.12)
        : (isDone
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                size: 16,
                color: isDone ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        loc.tr(item.titleKey),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDone ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isMandatory) ...[
                      const SizedBox(width: 4),
                      Text(
                        '🔴',
                        style: const TextStyle(fontSize: 8),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Dynamic Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDone
                      ? theme.colorScheme.primaryContainer
                      : (item.isMandatory ? theme.colorScheme.errorContainer.withValues(alpha: 0.4) : theme.colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : (item.isMandatory ? Icons.error_outline_rounded : Icons.radio_button_unchecked_rounded),
                      size: 11,
                      color: isDone
                          ? theme.colorScheme.onPrimaryContainer
                          : (item.isMandatory ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isDone
                          ? (item.detectedValue != null
                              ? loc.tr('detectedFieldBadge').replaceAll('{value}', item.detectedValue!)
                              : loc.tr('detectedInSpeechBadge'))
                          : (item.isMandatory ? loc.tr('missingFieldBadge') : loc.tr('notMentionedYetBadge')),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? theme.colorScheme.onPrimaryContainer
                            : (item.isMandatory ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            loc.tr(item.descKey),
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
          ),
          if (item.sampleChips.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.sampleChips.map((chip) {
                return TashilAssistChip.outlined(
                  label: chip,
                  icon: Icons.add_rounded,
                  height: 26.0,
                  borderRadius: 6.0,
                  onPressed: () => _appendSampleKeyword(chip),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
