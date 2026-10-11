import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';
import 'package:tashil_real_estate/core/services/location/gps_service.dart';
import 'package:tashil_real_estate/core/services/location/location_geocoding_service.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/fast_onboarding/services/gemini_onboarding_service.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/property_media_gallery_uploader.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/voice_property_input_modal.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/repositories/property_repository.dart';
import 'package:tashil_real_estate/features/image_moderation/widgets/ai_image_moderator_dialog.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';

class FastPropertyOnboardingDialog extends StatefulWidget {
  final FastPropertyDraft? initialDraft;
  final String? existingPropertyId;

  const FastPropertyOnboardingDialog({
    super.key,
    this.initialDraft,
    this.existingPropertyId,
  });

  static Future<void> show(
    BuildContext context, {
    FastPropertyDraft? initialDraft,
    String? existingPropertyId,
  }) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => FastPropertyOnboardingDialog(
        initialDraft: initialDraft,
        existingPropertyId: existingPropertyId,
      ),
    );
  }

  @override
  State<FastPropertyOnboardingDialog> createState() => _FastPropertyOnboardingDialogState();
}

class _FastPropertyOnboardingDialogState extends State<FastPropertyOnboardingDialog> {
  bool get isEditing => widget.existingPropertyId != null;
  final _formKey = GlobalKey<FormState>();
  final _service = GeminiOnboardingService();
  final _locationService = LocationGeocodingService();

  late FastPropertyDraft _draft;

  late TextEditingController _cityCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _buildingNameCtrl;
  late TextEditingController _unitNumberCtrl;

  late TextEditingController _rentCtrl;
  late TextEditingController _depositCtrl;

  late TextEditingController _areaCtrl;
  late TextEditingController _bedroomsCtrl;
  late TextEditingController _bathroomsCtrl;
  late TextEditingController _floorCtrl;

  late TextEditingController _titleArCtrl;
  late TextEditingController _titleEnCtrl;
  late TextEditingController _descArCtrl;
  late TextEditingController _descEnCtrl;
  late TextEditingController _videoTourCtrl;
  late TextEditingController _addressSearchCtrl;

  final PropertyMarketingTone _selectedTone = PropertyMarketingTone.luxuryExecutive;
  bool _isGeneratingDesc = false;
  bool _isSubmitting = false;
  bool _isLocatingGps = false;
  bool _isSearchingAddress = false;
  String _selectedFooterAction = 'submit';

  @override
  void initState() {
    super.initState();
    final isUAE = CountryController.isUAE;
    if (widget.initialDraft != null) {
      _draft = widget.initialDraft!;
    } else {
      _draft = FastPropertyDraft(
        countryCode: isUAE ? 'AE' : 'EG',
        currency: isUAE ? 'AED' : 'EGP',
        city: '',
        district: '',
        buildingName: '',
        unitNumber: '',
        monthlyRent: 0,
        securityDeposit: null,
        areaSqm: 0,
        bedrooms: 0,
        bathrooms: 0,
        floor: null,
        furnishingStatus: FurnishingStatus.fullyFurnished,
        hasParking: false,
        hasCentralAc: false,
        hasPoolGym: false,
        hasSecurity: false,
        hasBalconyView: false,
        isPetFriendly: false,
        titleAr: '',
        titleEn: '',
        descriptionAr: '',
        descriptionEn: '',
        descriptionHi: '',
        videoTourUrl: '',
        latitude: 0.0,
        longitude: 0.0,
        photoUrls: [],
      );
    }

    _cityCtrl = TextEditingController(text: _draft.city);
    _districtCtrl = TextEditingController(text: _draft.district);
    _buildingNameCtrl = TextEditingController(text: _draft.buildingName ?? '');
    _unitNumberCtrl = TextEditingController(text: _draft.unitNumber ?? '');

    _rentCtrl = TextEditingController(
      text: _draft.monthlyRent > 0 ? _draft.monthlyRent.toInt().toString() : '',
    );
    _depositCtrl = TextEditingController(
      text: (_draft.securityDeposit != null && _draft.securityDeposit! > 0)
          ? _draft.securityDeposit!.toInt().toString()
          : '',
    );

    _areaCtrl = TextEditingController(
      text: _draft.areaSqm > 0 ? _draft.areaSqm.toString() : '',
    );
    _bedroomsCtrl = TextEditingController(
      text: _draft.bedrooms > 0 ? _draft.bedrooms.toString() : '',
    );
    _bathroomsCtrl = TextEditingController(
      text: _draft.bathrooms > 0 ? _draft.bathrooms.toString() : '',
    );
    _floorCtrl = TextEditingController(
      text: (_draft.floor != null && _draft.floor! > 0) ? _draft.floor!.toString() : '',
    );

    _titleArCtrl = TextEditingController(text: _draft.titleAr);
    _titleEnCtrl = TextEditingController(text: _draft.titleEn);
    _descArCtrl = TextEditingController(text: _draft.descriptionAr);
    _descEnCtrl = TextEditingController(text: _draft.descriptionEn);
    _videoTourCtrl = TextEditingController(text: _draft.videoTourUrl ?? '');
    _addressSearchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _buildingNameCtrl.dispose();
    _unitNumberCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _areaCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _floorCtrl.dispose();
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _descArCtrl.dispose();
    _descEnCtrl.dispose();
    _videoTourCtrl.dispose();
    _addressSearchCtrl.dispose();
    super.dispose();
  }

  void _applyDraft(FastPropertyDraft draft) {
    setState(() {
      _draft = draft;
      _cityCtrl.text = draft.city;
      _districtCtrl.text = draft.district;
      _buildingNameCtrl.text = draft.buildingName ?? '';
      _unitNumberCtrl.text = draft.unitNumber ?? '';

      // Auto-populate street address into map search field
      if (draft.streetAddress != null && draft.streetAddress!.trim().isNotEmpty) {
        _addressSearchCtrl.text = draft.streetAddress!.trim();
      } else if (draft.district.isNotEmpty || draft.city.isNotEmpty) {
        _addressSearchCtrl.text = '${draft.district} ${draft.city}'.trim();
      }

      _rentCtrl.text = draft.monthlyRent > 0 ? draft.monthlyRent.toInt().toString() : '';
      _depositCtrl.text = (draft.securityDeposit != null && draft.securityDeposit! > 0)
          ? draft.securityDeposit!.toInt().toString()
          : '';

      _areaCtrl.text = draft.areaSqm > 0 ? draft.areaSqm.toString() : '';
      _bedroomsCtrl.text = draft.bedrooms > 0 ? draft.bedrooms.toString() : '';
      _bathroomsCtrl.text = draft.bathrooms > 0 ? draft.bathrooms.toString() : '';
      _floorCtrl.text = (draft.floor != null && draft.floor! > 0) ? draft.floor!.toString() : '';

      _titleArCtrl.text = draft.titleAr;
      _titleEnCtrl.text = draft.titleEn;
      _videoTourCtrl.text = draft.videoTourUrl ?? '';
    });

    final loc = AppLocalizations.of(context);
    if (_addressSearchCtrl.text.trim().isNotEmpty) {
      _handleSearchAddress(loc);
    }

    if (draft.city.isNotEmpty || draft.areaSqm > 0 || draft.monthlyRent > 0) {
      _triggerAiCopywriting();
    }
  }

  Future<void> _handleFetchGpsLocation(AppLocalizations loc) async {
    setState(() => _isLocatingGps = true);
    try {
      final resolved = await _locationService.fetchCurrentGpsLocation(preferredCountry: _draft.countryCode);
      if (resolved != null && mounted) {
        setState(() {
          _draft.latitude = resolved.latitude;
          _draft.longitude = resolved.longitude;
          _draft.city = resolved.city;
          _draft.district = resolved.district;
          _cityCtrl.text = resolved.city;
          _districtCtrl.text = resolved.district;
          _isLocatingGps = false;
        });
        TashilSnackBar.showSuccess(
          context: context,
          message: '${loc.tr('gpsLocatedSuccess')}: ${resolved.city} - ${resolved.district}',
        );
      } else if (mounted) {
        setState(() => _isLocatingGps = false);
        TashilSnackBar.showError(
          context: context,
          message: loc.tr('gpsLocateFailed'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocatingGps = false);
        TashilSnackBar.showError(
          context: context,
          message: loc.tr('gpsLocateFailed'),
        );
      }
    }
  }

  Future<void> _handleSearchAddress(AppLocalizations loc) async {
    final query = _addressSearchCtrl.text.trim();
    if (query.isEmpty) return;

    final isUrl = query.contains('maps') || query.contains('goo.gl');

    setState(() => _isSearchingAddress = true);
    try {
      final resolved = await _locationService.searchLocation(query, countryCode: _draft.countryCode);
      if (resolved != null && mounted) {
        setState(() {
          _draft.latitude = resolved.latitude;
          _draft.longitude = resolved.longitude;
          _draft.city = resolved.city;
          _draft.district = resolved.district;
          _cityCtrl.text = resolved.city;
          _districtCtrl.text = resolved.district;
          _isSearchingAddress = false;
        });
        TashilSnackBar.showSuccess(
          context: context,
          message: isUrl
              ? loc.tr('googleMapsLinkResolvedSuccess')
              : '${loc.tr('gpsLocatedSuccess')}: ${resolved.city} - ${resolved.district}',
        );
      } else if (mounted) {
        setState(() => _isSearchingAddress = false);
        TashilSnackBar.showError(
          context: context,
          message: loc.tr('gpsLocateFailed'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  void _handleOpenInGoogleMaps() {
    if (_draft.latitude != 0.0 && _draft.longitude != 0.0) {
      _locationService.openInGoogleMaps(_draft.latitude, _draft.longitude);
    } else {
      final query = '${_draft.district} ${_draft.city}'.trim();
      if (query.isNotEmpty) {
        GpsService().openUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
      }
    }
  }

  void _syncControllersToDraft() {
    _draft.city = _cityCtrl.text.trim();
    _draft.district = _districtCtrl.text.trim();
    _draft.buildingName = _buildingNameCtrl.text.trim();
    _draft.unitNumber = _unitNumberCtrl.text.trim();
    _draft.monthlyRent = double.tryParse(_rentCtrl.text.trim()) ?? _draft.monthlyRent;
    _draft.securityDeposit = double.tryParse(_depositCtrl.text.trim());
    _draft.areaSqm = int.tryParse(_areaCtrl.text.trim()) ?? _draft.areaSqm;
    _draft.bedrooms = int.tryParse(_bedroomsCtrl.text.trim()) ?? _draft.bedrooms;
    _draft.bathrooms = int.tryParse(_bathroomsCtrl.text.trim()) ?? _draft.bathrooms;
    _draft.floor = int.tryParse(_floorCtrl.text.trim());
    _draft.titleAr = _titleArCtrl.text.trim();
    _draft.titleEn = _titleEnCtrl.text.trim();
    _draft.videoTourUrl = _videoTourCtrl.text.trim();
  }

  Future<void> _triggerAiCopywriting() async {
    _syncControllersToDraft();
    setState(() => _isGeneratingDesc = true);
    try {
      final descriptions = await _service.generateMarketingDescriptions(
        draft: _draft,
        tone: _selectedTone,
      );
      if (mounted) {
        setState(() {
          _descArCtrl.text = descriptions['ar'] ?? _draft.descriptionAr;
          _descEnCtrl.text = descriptions['en'] ?? _draft.descriptionEn;
          _draft.descriptionAr = _descArCtrl.text;
          _draft.descriptionEn = _descEnCtrl.text;
          _draft.descriptionHi = descriptions['hi'] ?? '';
          _isGeneratingDesc = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGeneratingDesc = false);
    }
  }

  Future<void> _handleVoiceAutofill() async {
    final result = await VoicePropertyInputModal.show(context);
    if (result != null) {
      _applyDraft(result);
      if (mounted) {
        final loc = AppLocalizations.of(context);
        TashilSnackBar.showSuccess(
          context: context,
          message: loc.tr('voiceAutofillSuccessNotice'),
        );
      }
    }
  }

  Future<void> _handleSubmit(AppLocalizations loc) async {
    _syncControllersToDraft();
    if (!_formKey.currentState!.validate()) {
      TashilSnackBar.showError(
        context: context,
        message: loc.tr('mandatoryFieldsErrorMsg'),
      );
      return;
    }

    if (_draft.photoUrls.length < 3) {
      TashilSnackBar.showWarning(
        context: context,
        message: loc.tr('minThreePhotosErrorMsg'),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final propId = widget.existingPropertyId ?? 'prop-${DateTime.now().millisecondsSinceEpoch}';
      final cityCode = deriveCityCode(
        city: _draft.city,
        district: _draft.district,
        countryCode: _draft.countryCode,
      );

      final titleAr = _draft.titleAr.trim().isNotEmpty
          ? _draft.titleAr.trim()
          : '${loc.tr('propTypeApartment')} ${_draft.district} ${_draft.city}';
      final descAr = _draft.descriptionAr.trim().isNotEmpty
          ? _draft.descriptionAr.trim()
          : 'وحدة عقارية مميزة للإيجار في ${_draft.district}، ${_draft.city} بمساحة ${_draft.areaSqm}م² وتضم ${_draft.bedrooms} غرف نوم و${_draft.bathrooms} حمامات.';
      final locationAr = '${_draft.district}، ${_draft.city}';

      // 1. Add to Owner's Managed Properties (شاشة عقاراتي)
      final managedProp = ManagedPropertyModel(
        id: propId,
        countryCode: _draft.countryCode,
        currencyCode: _draft.currency,
        titles: {
          'ar': titleAr,
          'en': _draft.titleEn.isNotEmpty ? _draft.titleEn : titleAr,
          'hi': _draft.titleHi.isNotEmpty ? _draft.titleHi : titleAr,
        },
        descriptions: {
          'ar': descAr,
          'en': _draft.descriptionEn.isNotEmpty ? _draft.descriptionEn : descAr,
          'hi': _draft.descriptionHi.isNotEmpty ? _draft.descriptionHi : descAr,
        },
        locations: {
          'ar': locationAr,
          'en': locationAr,
          'hi': locationAr,
        },
        cityCode: cityCode,
        propertyTypeCode: _draft.propertyType,
        unitNumber: _draft.unitNumber ?? '',
        buildingName: _draft.buildingName ?? '',
        pricePerMonth: _draft.monthlyRent,
        bedrooms: _draft.bedrooms,
        bathrooms: _draft.bathrooms,
        areaSqM: _draft.areaSqm.toDouble(),
        image: _draft.photoUrls.isNotEmpty ? _draft.photoUrls.first : '',
        imageUrls: List<String>.from(_draft.photoUrls),
        isPublished: true,
        rentalStatus: PropertyRentalStatus.available,
        installments: const [],
      );
      if (isEditing) {
        await PropertyLifecycleService().updateProperty(managedProp);
      } else {
        await PropertyLifecycleService().addProperty(managedProp);
      }

      // 2. Add to Public Marketplace (السوق العقاري العام)
      final propertyItem = PropertyItem(
        id: propId,
        countryCode: _draft.countryCode,
        currencyCode: _draft.currency,
        titles: {
          'ar': titleAr,
          'en': _draft.titleEn.isNotEmpty ? _draft.titleEn : titleAr,
          'hi': _draft.titleHi.isNotEmpty ? _draft.titleHi : titleAr,
        },
        descriptions: {
          'ar': descAr,
          'en': _draft.descriptionEn.isNotEmpty ? _draft.descriptionEn : descAr,
          'hi': _draft.descriptionHi.isNotEmpty ? _draft.descriptionHi : descAr,
        },
        propertyTypeCode: _draft.propertyType,
        locations: {
          'ar': locationAr,
          'en': locationAr,
          'hi': locationAr,
        },
        cityCode: cityCode,
        pricePerMonth: _draft.monthlyRent,
        bedrooms: _draft.bedrooms,
        bathrooms: _draft.bathrooms,
        areaSqM: _draft.areaSqm.toDouble(),
        imageUrls: List<String>.from(_draft.photoUrls),
        amenitiesMap: {
          'ar': [
            if (_draft.furnishingStatus == FurnishingStatus.fullyFurnished) 'مفروش بالكامل',
            if (_draft.furnishingStatus == FurnishingStatus.semiFurnished) 'نصف مفروش',
            if (_draft.hasCentralAc) 'تكييف مركزي',
            if (_draft.hasParking) 'موقف سيارات خاص',
            if (_draft.hasSecurity) 'حراسة وأمن 24/7',
            if (_draft.hasBalconyView) 'شرفة / إطلالة مميزة',
            if (_draft.hasPoolGym) 'مسبح ونادٍ رياضي',
            if (_draft.isPetFriendly) 'السماح بالحيوانات الأليفة',
          ],
          'en': [
            if (_draft.furnishingStatus == FurnishingStatus.fullyFurnished) 'Fully Furnished',
            if (_draft.furnishingStatus == FurnishingStatus.semiFurnished) 'Semi Furnished',
            if (_draft.hasCentralAc) 'Central A/C',
            if (_draft.hasParking) 'Private Parking',
            if (_draft.hasSecurity) '24/7 Security',
            if (_draft.hasBalconyView) 'Balcony View',
            if (_draft.hasPoolGym) 'Pool & Gym',
            if (_draft.isPetFriendly) 'Pet Friendly',
          ],
          'hi': [
            if (_draft.furnishingStatus == FurnishingStatus.fullyFurnished) 'पूरी तरह सुसज्जित',
            if (_draft.furnishingStatus == FurnishingStatus.semiFurnished) 'अर्ध-सुसज्जित',
            if (_draft.hasCentralAc) 'केंद्रीय एसी',
            if (_draft.hasParking) 'निजी पार्किंग',
            if (_draft.hasSecurity) '24/7 सुरक्षा',
            if (_draft.hasBalconyView) 'बालकनी दृश्य',
            if (_draft.hasPoolGym) 'पूल और जिम',
            if (_draft.isPetFriendly) 'पालतू जानवरों के अनुकूल',
          ],
        },
        isFurnished: _draft.furnishingStatus != FurnishingStatus.unfurnished,
        isFeatured: true,
        agencyNames: {
          'ar': 'شركة تسهيل لإدارة الأملاك',
          'en': 'Tashil Property Management',
          'hi': 'तशिल संपत्ति प्रबंधन',
        },
        agencyPhone: '+20 100 123 4567',
        rating: 5.0,
      );
      if (isEditing) {
        PropertyRepository().updateProperty(propertyItem);
      } else {
        PropertyRepository().addProperty(propertyItem);
      }

      // 3. Persist to Owner's dedicated Firestore tree & Public Marketplace
      final ownerId = PropertyLifecycleService().currentOwnerId;
      final savedOk = await FirestoreService().saveOwnerProperty(
        ownerId: ownerId,
        property: managedProp,
      );

      if (!savedOk) {
        throw Exception('Failed to persist property to cloud Firestore.');
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();

      TashilSnackBar.showSuccess(
        context: context,
        message: isEditing
            ? loc.tr('listingUpdatedSuccessSnackbar')
            : loc.tr('propertyPublishedSuccessSnackbar'),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        TashilSnackBar.showError(
          context: context,
          message: 'Error saving property: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final isMobile = ResponsiveLayout.isMobile(context);
        final theme = Theme.of(context);

        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          elevation: 3.0,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 20 : 28)),
          clipBehavior: Clip.antiAlias,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 36,
            vertical: isMobile ? 16 : 28,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 850),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? loc.tr('editListingTitle') : loc.tr('addPropertyFiveSectionsTitle'),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      loc.tr('fiveSectionsSubtitle'),
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
                        const SizedBox(width: 8),
                        TashilIconButton.close(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                const SizedBox(height: 12),
                const TashilDivider.fullWidth(),
                const SizedBox(height: 12),

                // Scrollable 5-Sections Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🎙️ Hero Voice Action Button
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.85)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.mic_rounded, color: theme.colorScheme.onPrimary, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loc.tr('voiceAutofillHeroDesc'),
                                  style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12),
                                ),
                              ),
                              TashilButton.tonal(
                                onPressed: _handleVoiceAutofill,
                                icon: Icons.record_voice_over_rounded,
                                label: loc.tr('startVoiceDictationBtn'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 1
                        _buildSectionHeader('📍 1', loc.tr('section1LocationTitle'), theme),
                        const SizedBox(height: 10),

                        // GPS & Google Maps Toolbar Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Google Maps Search Bar with GPS Option Suffix Action
                              TextFormField(
                                controller: _addressSearchCtrl,
                                style: const TextStyle(fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: loc.tr('searchAddressPlaceholder'),
                                  hintStyle: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: theme.colorScheme.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // GPS Location Option Button
                                      IconButton(
                                        tooltip: loc.tr('useGpsOptionBtn'),
                                        icon: _isLocatingGps
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Icon(Icons.my_location_rounded, size: 18, color: theme.colorScheme.primary),
                                        onPressed: _isLocatingGps ? null : () => _handleFetchGpsLocation(loc),
                                      ),
                                      // Submit Search Button
                                      _isSearchingAddress
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 10),
                                              child: SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          : IconButton(
                                              tooltip: loc.tr('searchAddressBtn'),
                                              icon: Icon(Icons.arrow_forward_rounded, size: 18, color: theme.colorScheme.onSurface),
                                              onPressed: () => _handleSearchAddress(loc),
                                            ),
                                    ],
                                  ),
                                ),
                                onFieldSubmitted: (_) => _handleSearchAddress(loc),
                              ),

                              // Optional Quick GPS Assist Chip
                              Padding(
                                padding: const EdgeInsets.only(top: 6, right: 4, left: 4),
                                child: Row(
                                  children: [
                                    TashilAssistChip.outlined(
                                      onPressed: _isLocatingGps ? null : () => _handleFetchGpsLocation(loc),
                                      icon: Icons.gps_fixed_rounded,
                                      label: loc.tr('useGpsOptionBtn'),
                                      isLoading: _isLocatingGps,
                                      height: 28.0,
                                      borderRadius: 6.0,
                                    ),
                                  ],
                                ),
                              ),

                              // 2. Verified Coordinates Banner with Google Maps Button Right Beside It
                              if (_draft.latitude != 0.0 && _draft.longitude != 0.0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${_draft.city} - ${_draft.district}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onPrimaryContainer,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              '${_draft.latitude.toStringAsFixed(5)}, ${_draft.longitude.toStringAsFixed(5)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TashilAssistChip.outlined(
                                        onPressed: _handleOpenInGoogleMaps,
                                        icon: Icons.map_rounded,
                                        label: loc.tr('viewOnGoogleMapsBtn'),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_draft.city.isNotEmpty || _draft.district.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: theme.colorScheme.onSurfaceVariant, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_draft.city} - ${_draft.district}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TashilAssistChip.outlined(
                                        onPressed: _handleOpenInGoogleMaps,
                                        icon: Icons.map_rounded,
                                        label: loc.tr('viewOnGoogleMapsBtn'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityCtrl,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('cityLabel')} (إجباري 🔴)',
                                  prefixIcon: const Icon(Icons.location_city_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                                onChanged: (v) => _draft.city = v,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _districtCtrl,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('districtLabel')} (إجباري 🔴)',
                                  prefixIcon: const Icon(Icons.map_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                                onChanged: (v) => _draft.district = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _buildingNameCtrl,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('buildingCompoundLabel')} (اختياري 🟢)',
                                  prefixIcon: const Icon(Icons.domain_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (v) => _draft.buildingName = v,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _unitNumberCtrl,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('unitNumberFieldLabel')} (اختياري 🟢)',
                                  prefixIcon: const Icon(Icons.meeting_room_rounded, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (v) => _draft.unitNumber = v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 2
                        _buildSectionHeader('💰 2', loc.tr('section2FinancialsTitle')),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _rentCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('rentPriceFieldLabel')} (إجباري 🔴)',
                                  prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                                onChanged: (v) => _draft.monthlyRent = double.tryParse(v) ?? _draft.monthlyRent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final chosen = await TashilSelectionDialog.showCurrencyPicker(
                                    context: context,
                                    currentCurrency: _draft.currency,
                                  );
                                  if (chosen != null) {
                                    setState(() => _draft.currency = chosen);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'العملة 🔴',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 22),
                                  ),
                                  child: Text(
                                    _draft.currency == 'EGP'
                                        ? '🇪🇬 ج.م'
                                        : _draft.currency == 'AED'
                                            ? '🇦🇪 د.إ'
                                            : '🇺🇸 \$',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(loc.tr('billsIncludedOption'), style: const TextStyle(fontSize: 11)),
                                value: _draft.isBillsIncluded,
                                onChanged: (v) => setState(() => _draft.isBillsIncluded = v ?? false),
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(loc.tr('isNegotiableOption'), style: const TextStyle(fontSize: 11)),
                                value: _draft.isNegotiable,
                                onChanged: (v) => setState(() => _draft.isNegotiable = v ?? false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 3
                        _buildSectionHeader('🏠 3', loc.tr('section3TechnicalSpecsTitle')),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _areaCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('areaSqmFieldLabel')} (إجباري 🔴)',
                                  suffixText: 'م²',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                                onChanged: (v) => _draft.areaSqm = int.tryParse(v) ?? _draft.areaSqm,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _bedroomsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('bedroomsLabel')} 🔴',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                                onChanged: (v) => _draft.bedrooms = int.tryParse(v) ?? _draft.bedrooms,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _bathroomsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: '${loc.tr('bathroomsLabel')} 🔴',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                                onChanged: (v) => _draft.bathrooms = int.tryParse(v) ?? _draft.bathrooms,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 4
                        _buildSectionHeader('✨ 4', loc.tr('section4AmenitiesTitle')),
                        const SizedBox(height: 8),
                        TashilConnectedButtonGroup<FurnishingStatus>(
                          selectedValue: _draft.furnishingStatus,
                          onSelectionChanged: (status) => setState(() => _draft.furnishingStatus = status),
                          segments: [
                            TashilConnectedButtonSegment(
                              value: FurnishingStatus.fullyFurnished,
                              label: loc.tr('fullyFurnishedOption'),
                              icon: Icons.chair_rounded,
                            ),
                            TashilConnectedButtonSegment(
                              value: FurnishingStatus.semiFurnished,
                              label: loc.tr('semiFurnishedOption'),
                              icon: Icons.weekend_outlined,
                            ),
                            TashilConnectedButtonSegment(
                              value: FurnishingStatus.unfurnished,
                              label: loc.tr('unfurnishedOption'),
                              icon: Icons.crop_free_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Amenities M3 Filter Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TashilFilterChip(
                              icon: Icons.ac_unit_rounded,
                              label: loc.tr('centralAcAmenity'),
                              selected: _draft.hasCentralAc,
                              onSelected: (val) => setState(() => _draft.hasCentralAc = val),
                            ),
                            TashilFilterChip(
                              icon: Icons.local_parking_rounded,
                              label: loc.tr('parkingAmenity'),
                              selected: _draft.hasParking,
                              onSelected: (val) => setState(() => _draft.hasParking = val),
                            ),
                            TashilFilterChip(
                              icon: Icons.security_rounded,
                              label: loc.tr('securityAmenity'),
                              selected: _draft.hasSecurity,
                              onSelected: (val) => setState(() => _draft.hasSecurity = val),
                            ),
                            TashilFilterChip(
                              icon: Icons.balcony_rounded,
                              label: loc.tr('balconyViewAmenity'),
                              selected: _draft.hasBalconyView,
                              onSelected: (val) => setState(() => _draft.hasBalconyView = val),
                            ),
                            TashilFilterChip(
                              icon: Icons.pool_rounded,
                              label: loc.tr('poolGymAmenity'),
                              selected: _draft.hasPoolGym,
                              onSelected: (val) => setState(() => _draft.hasPoolGym = val),
                            ),
                            TashilFilterChip(
                              icon: Icons.pets_rounded,
                              label: loc.tr('petFriendlyAmenity'),
                              selected: _draft.isPetFriendly,
                              onSelected: (val) => setState(() => _draft.isPetFriendly = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 5
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildSectionHeader('🖼️ 📝 5', loc.tr('section5MediaTitle'))),
                            const SizedBox(width: 8),
                            TashilAssistChip.elevated(
                              onPressed: () => AiImageModeratorDialog.show(context),
                              icon: Icons.shield_outlined,
                              label: loc.tr('aiImageModeratorTitle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Animated Photo Gallery & Multi-Photo Upload System
                        PropertyMediaGalleryUploader(
                          photoUrls: _draft.photoUrls,
                          onPhotosChanged: (urls) => setState(() => _draft.photoUrls = urls),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _titleArCtrl,
                          decoration: InputDecoration(
                            labelText: '${loc.tr('propertyTitleField')} (إجباري 🔴)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                          onChanged: (v) => _draft.titleAr = v,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${loc.tr('detailedDescriptionLabel')} (إجباري 🔴)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            TashilAssistChip(
                              onPressed: _isGeneratingDesc ? null : _triggerAiCopywriting,
                              isLoading: _isGeneratingDesc,
                              icon: Icons.auto_awesome_rounded,
                              label: loc.tr('generateWithAiBtn'),
                              variant: TashilChipVariant.tonal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descArCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: loc.tr('detailedDescriptionHint'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                          onChanged: (v) => _draft.descriptionAr = v,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const TashilDivider.cardAction(),
                const SizedBox(height: 12),

                // Bottom Action Buttons (M3 Connected Button Group)
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TashilConnectedButtonGroup<String>(
                      selectedValue: _selectedFooterAction,
                      onSelectionChanged: (action) {
                        setState(() => _selectedFooterAction = action);
                        if (action == 'cancel') {
                          Navigator.of(context).pop();
                        } else if (action == 'submit') {
                          if (!_isSubmitting) {
                            _handleSubmit(loc);
                          }
                        }
                      },
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 'cancel',
                          label: loc.tr('cancel'),
                          icon: Icons.close_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'submit',
                          label: isEditing ? loc.tr('saveChangesBtn') : loc.tr('publishPropertyDirectBtn'),
                          icon: isEditing ? Icons.save_rounded : Icons.publish_rounded,
                          enabled: !_isSubmitting,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }

  Widget _buildSectionHeader(String number, String title, [ThemeData? theme]) {
    final t = theme ?? Theme.of(context);
    return Text(
      '$number $title',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: t.colorScheme.onSurface),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
