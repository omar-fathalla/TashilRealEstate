import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/checkboxes/tashil_checkboxes.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/core/design_system/text_fields/tashil_text_fields.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';
import 'package:tashil_real_estate/core/services/location/gps_service.dart';
import 'package:tashil_real_estate/core/services/location/location_geocoding_service.dart';
import 'package:tashil_real_estate/core/utils/advertising_permit.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/services/storage/property_draft_cache_service.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/fast_onboarding/services/gemini_onboarding_service.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/property_media_gallery_uploader.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/voice_property_input_modal.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/repositories/property_repository.dart';
import 'package:material_symbols_icons/symbols.dart';

class FastOnboardingScreen extends StatefulWidget {
  final FastPropertyDraft? initialDraft;
  final String? existingPropertyId;

  const FastOnboardingScreen({
    super.key,
    this.initialDraft,
    this.existingPropertyId,
  });

  @override
  State<FastOnboardingScreen> createState() => _FastOnboardingScreenState();
}

class _FastOnboardingScreenState extends State<FastOnboardingScreen> {
  bool get isEditing => widget.existingPropertyId != null;
  final _formKey = GlobalKey<FormState>();
  final _service = GeminiOnboardingService();
  final _locationService = LocationGeocodingService();

  late FastPropertyDraft _draft;

  // Section 1 Controllers
  late TextEditingController _cityCtrl;
  late TextEditingController _permitCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _buildingNameCtrl;
  late TextEditingController _unitNumberCtrl;

  // Section 2 Controllers
  late TextEditingController _rentCtrl;
  late TextEditingController _depositCtrl;

  // Section 3 Controllers
  late TextEditingController _areaCtrl;
  late TextEditingController _bedroomsCtrl;
  late TextEditingController _bathroomsCtrl;
  late TextEditingController _floorCtrl;

  // Section 5 Controllers
  late TextEditingController _titleArCtrl;
  late TextEditingController _titleEnCtrl;
  late TextEditingController _descArCtrl;
  late TextEditingController _descEnCtrl;
  late TextEditingController _videoTourCtrl;
  late TextEditingController _addressSearchCtrl;

  bool _isGeneratingDesc = false;
  bool _isSubmitting = false;
  bool _isLocatingGps = false;
  bool _isSearchingAddress = false;
  bool _hasRestoredDraft = false;

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
    _permitCtrl = TextEditingController(text: _draft.advertisingPermitNumber);
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
    _addressSearchCtrl = TextEditingController(
      text: (_draft.streetAddress != null && _draft.streetAddress!.trim().isNotEmpty)
          ? _draft.streetAddress!.trim()
          : (_draft.district.isNotEmpty || _draft.city.isNotEmpty ? '${_draft.district} ${_draft.city}'.trim() : ''),
    );

    if (widget.initialDraft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyDraft(widget.initialDraft!);
        }
      });
    } else {
      // Check for cached draft
      final cached = PropertyDraftCacheService().getDraft();
      if (cached != null) {
        _draft = cached;
        _hasRestoredDraft = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _applyDraft(cached);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _permitCtrl.dispose();
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

  Future<void> _clearDraftAndReset() async {
    await PropertyDraftCacheService().clearDraft();
    setState(() {
      _hasRestoredDraft = false;
      final isUAE = CountryController.isUAE;
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
      _cityCtrl.clear();
      _districtCtrl.clear();
      _permitCtrl.clear();
      _buildingNameCtrl.clear();
      _unitNumberCtrl.clear();
      _rentCtrl.clear();
      _depositCtrl.clear();
      _areaCtrl.clear();
      _bedroomsCtrl.clear();
      _bathroomsCtrl.clear();
      _floorCtrl.clear();
      _titleArCtrl.clear();
      _titleEnCtrl.clear();
      _descArCtrl.clear();
      _descEnCtrl.clear();
      _videoTourCtrl.clear();
      _addressSearchCtrl.clear();
    });
    if (mounted) {
      TashilSnackBar.showInfo(
        context: context,
        message: AppLocalizations.of(context).tr('clearDraftAction'),
      );
    }
  }

  void _applyDraft(FastPropertyDraft draft) {
    setState(() {
      _draft = draft;
      _cityCtrl.text = draft.city;
      _permitCtrl.text = draft.advertisingPermitNumber;
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
      _descArCtrl.text = draft.descriptionAr;
      _descEnCtrl.text = draft.descriptionEn;
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
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.primary,
            content: Text('${loc.tr('gpsLocatedSuccess')}: ${resolved.city} - ${resolved.district}'),
          ),
        );
      } else if (mounted) {
        setState(() => _isLocatingGps = false);
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.error,
            content: Text(loc.tr('gpsLocateFailed')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocatingGps = false);
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.error,
            content: Text(loc.tr('gpsLocateFailed')),
          ),
        );
      }
    }
  }

  Future<void> _handleSearchAddress(AppLocalizations loc) async {
    final query = _addressSearchCtrl.text.trim();
    if (query.isEmpty) return;

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
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.primary,
            content: Text('${loc.tr('gpsLocatedSuccess')}: ${resolved.city} - ${resolved.district}'),
          ),
        );
      } else if (mounted) {
        setState(() => _isSearchingAddress = false);
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.error,
            content: Text(loc.tr('gpsLocateFailed')),
          ),
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
      final query = _addressSearchCtrl.text.trim().isNotEmpty
          ? _addressSearchCtrl.text.trim()
          : '${_draft.district} ${_draft.city}'.trim();
      if (query.isNotEmpty) {
        GpsService().openUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
      } else {
        final isUAE = CountryController.isUAE;
        final defaultQuery = isUAE ? 'Dubai, United Arab Emirates' : 'Cairo, Egypt';
        GpsService().openUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(defaultQuery)}');
      }
    }
  }

  String? _permitError(AppLocalizations loc, String? value) {
    final cityCode = deriveCityCode(
      city: _cityCtrl.text,
      district: _districtCtrl.text,
      countryCode: _draft.countryCode,
    );
    final key = AdvertisingPermit.errorKey(value: value ?? '', cityCode: cityCode);
    return key == null ? null : loc.tr(key);
  }

  void _syncControllersToDraft() {
    _draft.city = _cityCtrl.text.trim();
    _draft.district = _districtCtrl.text.trim();
    _draft.advertisingPermitNumber = _permitCtrl.text.trim();
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
      final copy = await _service.generateMarketingCopy(
        draft: _draft,
      );
      if (mounted) {
        setState(() {
          if (copy.titleAr.isNotEmpty) {
            _titleArCtrl.text = copy.titleAr;
            _draft.titleAr = copy.titleAr;
          }
          if (copy.titleEn.isNotEmpty) {
            _titleEnCtrl.text = copy.titleEn;
            _draft.titleEn = copy.titleEn;
          }
          _draft.titleHi = copy.titleHi;

          if (copy.descriptionAr.isNotEmpty) {
            _descArCtrl.text = copy.descriptionAr;
            _draft.descriptionAr = copy.descriptionAr;
          }
          if (copy.descriptionEn.isNotEmpty) {
            _descEnCtrl.text = copy.descriptionEn;
            _draft.descriptionEn = copy.descriptionEn;
          }
          _draft.descriptionHi = copy.descriptionHi;

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
      TashilSnackBar.showError(
        context: context,
        message: loc.tr('minThreePhotosErrorMsg'),
      );
      return;
    }

    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // User is a guest / visitor!
      // Save full draft into local cache so it survives navigation, registration, and refresh
      await PropertyDraftCacheService().saveDraft(_draft);

      if (!mounted) return;
      TashilAlertDialog.show(
        context: context,
        iconData: Symbols.lock_outline_rounded,
        title: loc.tr('authRequiredToSavePropertyTitle'),
        contentText: loc.tr('authRequiredToSavePropertyDesc'),
        actions: [
          TashilButton.text(
            onPressed: () {
              Navigator.of(context).pop();
              TashilSnackBar.showSuccess(
                context: context,
                message: loc.tr('draftSavedLocallyNotice'),
              );
            },
            label: loc.tr('keepAsDraftAction'),
          ),
          TashilButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login?redirect=/fast-onboarding');
            },
            icon: Symbols.login_rounded,
            label: loc.tr('loginToPublishAction'),
          ),
        ],
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final propId = isEditing ? widget.existingPropertyId! : 'prop-${DateTime.now().millisecondsSinceEpoch}';
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
        advertisingPermitNumber: _draft.advertisingPermitNumber,
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
        advertisingPermitNumber: _draft.advertisingPermitNumber,
        pricePerMonth: _draft.monthlyRent,
        bedrooms: _draft.bedrooms,
        bathrooms: _draft.bathrooms,
        areaSqM: _draft.areaSqm.toDouble(),
        imageUrls: List<String>.from(_draft.photoUrls),
        amenitiesMap: {
          'ar': [
            if (_draft.furnishingStatus == FurnishingStatus.fullyFurnished) 'مفروش بالكامل',
            if (_draft.furnishingStatus == FurnishingStatus.semiFurnished) 'نصف مفروش',
            if (_draft.hasCentralAc) AppLocalizations.trStatic('uiCopy174'),
            if (_draft.hasParking) AppLocalizations.trStatic('uiCopy316'),
            if (_draft.hasSecurity) AppLocalizations.trStatic('uiCopy195'),
            if (_draft.hasBalconyView) AppLocalizations.trStatic('uiCopy221'),
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
          'ar': 'تسهيل عقار',
          'en': 'Tashil Aqar',
          'hi': 'ताशिल अकार',
        },
        agencyPhone: CountryController.isUAE ? '+971 50 000 0000' : '+20 100 123 4567',
        rating: 5.0,
      );

      // 3. Persist to Owner's dedicated Firestore tree & Public Marketplace
      final ownerId = currentUser.uid;
      final savedSuccessfully = await FirestoreService().saveOwnerProperty(
        ownerId: ownerId,
        property: managedProp,
      );

      if (!savedSuccessfully) {
        throw Exception('Failed to persist property to cloud Firestore.');
      }

      // 4. Update in-memory state only upon verified cloud success
      if (isEditing) {
        await PropertyLifecycleService().updateProperty(managedProp);
        PropertyRepository().updateProperty(propertyItem);
      } else {
        await PropertyLifecycleService().addProperty(managedProp);
        PropertyRepository().addProperty(propertyItem);
      }

      // 5. Clear draft from cache
      await PropertyDraftCacheService().clearDraft();
      if (mounted) {
        setState(() => _hasRestoredDraft = false);
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      TashilAlertDialog.show(
        context: context,
        iconData: Symbols.verified_rounded,
        title: isEditing
            ? loc.tr('listingUpdatedSuccessSnackbar')
            : loc.tr('propertyPublishedSuccessNotice'),
        contentText: loc.tr('propertyPublishedSuccessDesc'),
        actions: [
          TashilButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/owner');
              }
            },
            icon: Symbols.dashboard_rounded,
            label: loc.tr('exploreUnits'),
          ),
        ],
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        TashilSnackBar.showError(
          context: context,
          message: 'Error publishing listing: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, countryCode, _) {
            final loc = AppLocalizations.of(context);

            return PopScope(
              canPop: !_isSubmitting,
              child: Scaffold(
              backgroundColor: theme.colorScheme.surface,
              resizeToAvoidBottomInset: true,
              appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/fast-onboarding'),
              bottomNavigationBar: isMobile
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          height: 50,
                          child: TashilButton.filled(
                            onPressed: _isSubmitting ? null : () => _handleSubmit(loc),
                            icon: isEditing ? Symbols.save_rounded : Symbols.publish_rounded,
                            label: _isSubmitting
                                ? loc.tr('savingListing')
                                : (isEditing ? loc.tr('saveChangesAction') : loc.tr('publishPropertyDirectBtn')),
                          ),
                        ),
                      ),
                    )
                  : null,
              body: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  isMobile ? 14 : 24,
                  isMobile ? 14 : 24,
                  isMobile ? 14 : 24,
                  (isMobile ? 120 : 24) + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // -1. EDIT MODE HEADER BANNER
                          if (isEditing) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Symbols.edit_note_rounded, color: theme.colorScheme.primary, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      loc.tr('editListingTitle'),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: TashilMotionDuration.medium2, curve: TashilMotionEasing.emphasizedDecelerate)
                                .slideY(begin: 0.04, end: 0, duration: TashilMotionDuration.medium2, curve: TashilMotionEasing.emphasizedDecelerate),
                          ],

                          // 0. RESTORED DRAFT NOTICE BANNER
                          if (_hasRestoredDraft) ...[
                            _buildRestoredDraftBanner(loc, theme)
                                .animate()
                                .fadeIn(duration: TashilMotionDuration.medium2, curve: TashilMotionEasing.emphasizedDecelerate)
                                .slideY(begin: 0.04, end: 0, duration: TashilMotionDuration.medium2, curve: TashilMotionEasing.emphasizedDecelerate),
                            const SizedBox(height: 16),
                          ],

                          // 1. HERO AI VOICE ACTION BANNER (M3 Filled Card + M3 High-Emphasis Filled Button)
                          _buildVoiceAutofillBanner(loc, isMobile, theme),
                          const SizedBox(height: 20),

                          // 2. SECTION 1: THE LOCATION (M3 Outlined Card + M3 Outlined Text Fields + M3 Assist Chips)
                          _buildSection1Location(loc, isMobile, theme),
                          const SizedBox(height: 20),

                          // 3. SECTION 2: FINANCIAL TRANSPARENCY (M3 Outlined Card + M3 Connected Group + M3 Checkboxes)
                          _buildSection2Financials(loc, isMobile, theme),
                          const SizedBox(height: 20),

                          // 4. SECTION 3: TECHNICAL SPECS (M3 Filter Chips + M3 Outlined Text Fields + M3 Connected Group)
                          _buildSection3TechnicalSpecs(loc, isMobile, theme),
                          const SizedBox(height: 20),

                          // 5. SECTION 4: AMENITIES (M3 Connected Group + M3 Checkboxes Suite)
                          _buildSection4Amenities(loc, isMobile, theme),
                          const SizedBox(height: 20),

                          // 6. SECTION 5: MEDIA & DESCRIPTION (M3 Suggestion Chips + M3 Tonal Button + M3 Outlined Fields)
                          _buildSection5MediaAndDescription(loc, isMobile, theme),
                          const SizedBox(height: 28),

                          // SUBMIT BUTTON (on Tablet / Desktop when not in bottom bar)
                          if (!isMobile)
                            SizedBox(
                              height: 52,
                              child: TashilButton.filled(
                                onPressed: _isSubmitting ? null : () => _handleSubmit(loc),
                                icon: isEditing ? Symbols.save_rounded : Symbols.publish_rounded,
                                label: _isSubmitting
                                    ? loc.tr('savingListing')
                                    : (isEditing ? loc.tr('saveChangesAction') : loc.tr('publishPropertyDirectBtn')),
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            );
          },
        );
      },
    );
  }

  // --- RESTORED DRAFT BANNER ---
  Widget _buildRestoredDraftBanner(AppLocalizations loc, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.save_as_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.tr('draftRestoredNotice'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TashilButton.text(
            onPressed: _clearDraftAndReset,
            icon: Symbols.delete_sweep_rounded,
            label: loc.tr('clearDraftAction'),
          ),
          const SizedBox(width: 4),
          TashilIconButton.close(
            size: 32,
            iconSize: 18,
            onPressed: () => setState(() => _hasRestoredDraft = false),
          ),
        ],
      ),
    );
  }

  // --- 1. HERO VOICE AUTOFILL BANNER (M3 Filled Card + M3 Filled Button) ---
  Widget _buildVoiceAutofillBanner(AppLocalizations loc, bool isMobile, ThemeData theme) {
    return TashilCard.filled(
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Symbols.mic_rounded, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          loc.tr('voiceAutofillHeroTitle'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Symbols.auto_awesome_rounded, size: 12, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Gemini AI',
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.tr('voiceAutofillHeroDesc'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TashilButton.filled(
              onPressed: _handleVoiceAutofill,
              icon: Symbols.record_voice_over_rounded,
              label: loc.tr('startVoiceDictationBtn'),
            ),
          ),
        ],
      ),
    );
  }

  // --- M3 OUTLINED SECTION CONTAINER HELPER ---
  Widget _buildSectionCard({
    required int sectionIndex,
    required String title,
    required IconData icon,
    required Widget child,
    required bool isMobile,
    required ThemeData theme,
  }) {
    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: theme.colorScheme.onSecondaryContainer, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '$sectionIndex',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TashilDivider.cardAction(),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // --- 1. THE LOCATION (M3 Outlined Fields + M3 Assist Chips) ---
  Widget _buildSection1Location(AppLocalizations loc, bool isMobile, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 1,
      title: loc.tr('section1LocationTitle'),
      icon: Symbols.location_on_rounded,
      isMobile: isMobile,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS & Map Quick Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TashilButton.outlined(
                  label: _isLocatingGps ? loc.tr('locatingGpsProgress') : loc.tr('useCurrentLocationGpsBtn'),
                  icon: Symbols.my_location_rounded,
                  height: 48,
                  width: double.infinity,
                  onPressed: _isLocatingGps ? null : () => _handleFetchGpsLocation(loc),
                ),
                const SizedBox(height: 8),
                TashilButton.outlined(
                  label: loc.tr('viewOnGoogleMapsBtn'),
                  icon: Symbols.map_rounded,
                  height: 48,
                  width: double.infinity,
                  onPressed: _handleOpenInGoogleMaps,
                ),
                const SizedBox(height: 10),
                TashilTextField.outlined(
                  controller: _addressSearchCtrl,
                  labelText: loc.tr('searchAddressPlaceholderCompact'),
                  prefixIcon: Symbols.search_rounded,
                  style: theme.textTheme.bodyMedium,
                  suffixIcon: _isSearchingAddress ? null : Symbols.arrow_forward_rounded,
                  suffix: _isSearchingAddress
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: TashilLoadingIndicator.small(),
                          ),
                        )
                      : null,
                  onSuffixIconTap: () => _handleSearchAddress(loc),
                  onSubmitted: (_) => _handleSearchAddress(loc),
                ),
                if (_draft.latitude != 0.0 && _draft.longitude != 0.0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Symbols.check_circle_rounded, color: theme.colorScheme.primary, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_draft.latitude.toStringAsFixed(4)}, ${_draft.longitude.toStringAsFixed(4)} (${_draft.city} - ${_draft.district})',
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // City & District (Responsive Row on Tablet/Desktop, Column on Mobile)
          if (isMobile) ...[
            TashilTextField.outlined(
              controller: _cityCtrl,
              labelText: '${loc.tr('cityLabel')} *',
              hintText: loc.tr('cityHint'),
              prefixIcon: Symbols.location_city_rounded,
              validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
              onChanged: (v) => _draft.city = v,
            ),
            const SizedBox(height: 14),
            TashilTextField.outlined(
              controller: _districtCtrl,
              labelText: '${loc.tr('districtLabel')} *',
              hintText: loc.tr('districtHint'),
              prefixIcon: Symbols.map_rounded,
              validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
              onChanged: (v) => _draft.district = v,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _cityCtrl,
                    labelText: '${loc.tr('cityLabel')} *',
                    hintText: loc.tr('cityHint'),
                    prefixIcon: Symbols.location_city_rounded,
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.city = v,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _districtCtrl,
                    labelText: '${loc.tr('districtLabel')} *',
                    hintText: loc.tr('districtHint'),
                    prefixIcon: Symbols.map_rounded,
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.district = v,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TashilTextField.outlined(
            controller: _permitCtrl,
            labelText: loc.tr('adPermitNumberLabel'),
            hintText: loc.tr('adPermitNumberHint'),
            prefixIcon: Symbols.qr_code_2_rounded,
            keyboardType: TextInputType.number,
            validator: (value) => _permitError(loc, value),
            onChanged: (value) => _draft.advertisingPermitNumber = value.trim(),
          ),
          const SizedBox(height: 16),

          // Building / Compound & Unit Number (Responsive)
          if (isMobile) ...[
            TashilTextField.outlined(
              controller: _buildingNameCtrl,
              labelText: loc.tr('buildingCompoundLabel'),
              hintText: loc.tr('buildingCompoundHint'),
              prefixIcon: Symbols.domain_rounded,
              onChanged: (v) => _draft.buildingName = v,
            ),
            const SizedBox(height: 14),
            TashilTextField.outlined(
              controller: _unitNumberCtrl,
              labelText: loc.tr('unitNumberFieldLabel'),
              hintText: loc.tr('unitNumberFieldHint'),
              prefixIcon: Symbols.meeting_room_rounded,
              onChanged: (v) => _draft.unitNumber = v,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _buildingNameCtrl,
                    labelText: loc.tr('buildingCompoundLabel'),
                    hintText: loc.tr('buildingCompoundHint'),
                    prefixIcon: Symbols.domain_rounded,
                    onChanged: (v) => _draft.buildingName = v,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _unitNumberCtrl,
                    labelText: loc.tr('unitNumberFieldLabel'),
                    hintText: loc.tr('unitNumberFieldHint'),
                    prefixIcon: Symbols.meeting_room_rounded,
                    onChanged: (v) => _draft.unitNumber = v,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. FINANCIAL TRANSPARENCY (M3 Outlined Field + M3 Connected Group + M3 Checkboxes) ---
  Widget _buildSection2Financials(AppLocalizations loc, bool isMobile, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 2,
      title: loc.tr('section2FinancialsTitle'),
      icon: Symbols.account_balance_wallet_rounded,
      isMobile: isMobile,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Rent Price & Currency
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TashilTextField.outlined(
                  controller: _rentCtrl,
                  labelText: '${loc.tr('rentPriceFieldLabel')} *',
                  prefixIcon: Symbols.payments_rounded,
                  keyboardType: TextInputType.number,
                  validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                  onChanged: (v) => _draft.monthlyRent = double.tryParse(v) ?? _draft.monthlyRent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TashilDropdownMenu<String>(
                  value: _draft.currency,
                  height: 56.0,
                  prefixIcon: Symbols.currency_exchange_rounded,
                  items: const [
                    TashilDropdownMenuItem(value: 'EGP', label: 'EGP'),
                    TashilDropdownMenuItem(value: 'AED', label: 'AED'),
                    TashilDropdownMenuItem(value: 'USD', label: 'USD'),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _draft.currency = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Row 2: Payment Frequency (Connected Button Group with Animated Flex)
          Text(
            loc.tr('paymentFrequencyLabel'),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TashilConnectedButtonGroup<PaymentFrequency>(
            isFullWidth: true,
            isAnimatedFlex: true,
            height: 44,
            selectedValue: _draft.paymentFrequency,
            onSelectionChanged: (freq) => setState(() => _draft.paymentFrequency = freq),
            segments: [
              TashilConnectedButtonSegment(
                value: PaymentFrequency.monthly,
                label: loc.tr('freq_monthly_short'),
                selectedLabel: loc.tr('freq_monthly_full'),
                icon: Symbols.calendar_month_rounded,
              ),
              TashilConnectedButtonSegment(
                value: PaymentFrequency.quarterly,
                label: loc.tr('freq_quarterly_short'),
                selectedLabel: loc.tr('freq_quarterly_full'),
                icon: Symbols.date_range_rounded,
              ),
              TashilConnectedButtonSegment(
                value: PaymentFrequency.annual,
                label: loc.tr('freq_annual_short'),
                selectedLabel: loc.tr('freq_annual_full'),
                icon: Symbols.event_available_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Security Deposit
          TashilTextField.outlined(
            controller: _depositCtrl,
            labelText: loc.tr('securityDepositLabel'),
            hintText: loc.tr('securityDepositHint'),
            prefixIcon: Symbols.shield_rounded,
            keyboardType: TextInputType.number,
            onChanged: (v) => _draft.securityDeposit = double.tryParse(v),
          ),
          const SizedBox(height: 16),

          // Financial Switch Options (M3 Boolean Toggles with Compact Typography)
          if (isMobile) ...[
            TashilSwitchListTile(
              title: Text(
                loc.tr('billsIncludedOption'),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface),
              ),
              secondary: Icon(Symbols.receipt_long_rounded, color: theme.colorScheme.primary, size: 20),
              value: _draft.isBillsIncluded,
              onChanged: (v) => setState(() => _draft.isBillsIncluded = v),
            ),
            const SizedBox(height: 8),
            TashilSwitchListTile(
              title: Text(
                loc.tr('isNegotiableOption'),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface),
              ),
              secondary: Icon(Symbols.handshake_rounded, color: theme.colorScheme.secondary, size: 20),
              value: _draft.isNegotiable,
              onChanged: (v) => setState(() => _draft.isNegotiable = v),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TashilSwitchListTile(
                    title: Text(
                      loc.tr('billsIncludedOption'),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface),
                    ),
                    secondary: Icon(Symbols.receipt_long_rounded, color: theme.colorScheme.primary, size: 20),
                    value: _draft.isBillsIncluded,
                    onChanged: (v) => setState(() => _draft.isBillsIncluded = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TashilSwitchListTile(
                    title: Text(
                      loc.tr('isNegotiableOption'),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface),
                    ),
                    secondary: Icon(Symbols.handshake_rounded, color: theme.colorScheme.secondary, size: 20),
                    value: _draft.isNegotiable,
                    onChanged: (v) => setState(() => _draft.isNegotiable = v),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. TECHNICAL SPECS (M3 Filter Chips + M3 Outlined Fields + M3 Connected Group) ---
  Widget _buildSection3TechnicalSpecs(AppLocalizations loc, bool isMobile, ThemeData theme) {
    final safePropertyType = ['apartment', 'villa', 'studio', 'office', 'chalet']
            .contains(_draft.propertyType.toLowerCase())
        ? _draft.propertyType.toLowerCase()
        : 'apartment';

    final propertyTypes = [
      {'key': 'apartment', 'label': loc.tr('propTypeApartment'), 'icon': Symbols.apartment_rounded},
      {'key': 'villa', 'label': loc.tr('propTypeVilla'), 'icon': Symbols.villa_rounded},
      {'key': 'studio', 'label': loc.tr('propTypeStudio'), 'icon': Symbols.single_bed_rounded},
      {'key': 'office', 'label': loc.tr('propTypeOffice'), 'icon': Symbols.business_center_rounded},
      {'key': 'chalet', 'label': loc.tr('propTypeChalet'), 'icon': Symbols.beach_access_rounded},
    ];

    return _buildSectionCard(
      sectionIndex: 3,
      title: loc.tr('section3TechnicalSpecsTitle'),
      icon: Symbols.tune_rounded,
      isMobile: isMobile,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Type Filter Chips
          Text(
            '${loc.tr('propertyTypeLabel')} *',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: propertyTypes.map((pt) {
              final isSelected = safePropertyType == pt['key'];
              return TashilFilterChip(
                label: pt['label'] as String,
                icon: pt['icon'] as IconData,
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _draft.propertyType = pt['key'] as String);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Area & Floor
          if (isMobile) ...[
            TashilTextField.outlined(
              controller: _areaCtrl,
              labelText: '${loc.tr('areaSqmFieldLabel')} (م²) *',
              prefixIcon: Symbols.square_foot_rounded,
              keyboardType: TextInputType.number,
              validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
              onChanged: (v) => _draft.areaSqm = int.tryParse(v) ?? _draft.areaSqm,
            ),
            const SizedBox(height: 14),
            TashilTextField.outlined(
              controller: _floorCtrl,
              labelText: loc.tr('floorNumberLabel'),
              hintText: loc.tr('floorNumberHint'),
              prefixIcon: Symbols.layers_rounded,
              keyboardType: TextInputType.number,
              onChanged: (v) => _draft.floor = int.tryParse(v),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _areaCtrl,
                    labelText: '${loc.tr('areaSqmFieldLabel')} (م²) *',
                    prefixIcon: Symbols.square_foot_rounded,
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.areaSqm = int.tryParse(v) ?? _draft.areaSqm,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _floorCtrl,
                    labelText: loc.tr('floorNumberLabel'),
                    hintText: loc.tr('floorNumberHint'),
                    prefixIcon: Symbols.layers_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _draft.floor = int.tryParse(v),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Bedrooms & Bathrooms
          if (isMobile) ...[
            TashilTextField.outlined(
              controller: _bedroomsCtrl,
              labelText: '${loc.tr('bedroomsLabel')} *',
              prefixIcon: Symbols.bed_rounded,
              keyboardType: TextInputType.number,
              validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
              onChanged: (v) => _draft.bedrooms = int.tryParse(v) ?? _draft.bedrooms,
            ),
            const SizedBox(height: 14),
            TashilTextField.outlined(
              controller: _bathroomsCtrl,
              labelText: '${loc.tr('bathroomsLabel')} *',
              prefixIcon: Symbols.bathtub_rounded,
              keyboardType: TextInputType.number,
              validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
              onChanged: (v) => _draft.bathrooms = int.tryParse(v) ?? _draft.bathrooms,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _bedroomsCtrl,
                    labelText: '${loc.tr('bedroomsLabel')} *',
                    prefixIcon: Symbols.bed_rounded,
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.bedrooms = int.tryParse(v) ?? _draft.bedrooms,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TashilTextField.outlined(
                    controller: _bathroomsCtrl,
                    labelText: '${loc.tr('bathroomsLabel')} *',
                    prefixIcon: Symbols.bathtub_rounded,
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.bathrooms = int.tryParse(v) ?? _draft.bathrooms,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

          // Building Age (Connected Button Group)
          Text(
            loc.tr('buildingAgeLabel'),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TashilConnectedButtonGroup<BuildingAge>(
            isFullWidth: true,
            height: 42,
            selectedValue: _draft.buildingAge ?? BuildingAge.brandNew,
            onSelectionChanged: (age) => setState(() => _draft.buildingAge = age),
            segments: [
              TashilConnectedButtonSegment(
                value: BuildingAge.brandNew,
                label: loc.tr('ageBrandNew'),
                icon: Symbols.fiber_new_rounded,
              ),
              TashilConnectedButtonSegment(
                value: BuildingAge.oneToFive,
                label: loc.tr('ageOneToFive'),
                icon: Symbols.history_rounded,
              ),
              TashilConnectedButtonSegment(
                value: BuildingAge.older,
                label: loc.tr('ageOlder'),
                icon: Symbols.domain_verification_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. AMENITIES (M3 Connected Group + M3 Checkboxes Suite) ---
  Widget _buildSection4Amenities(AppLocalizations loc, bool isMobile, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 4,
      title: loc.tr('section4AmenitiesTitle'),
      icon: Symbols.auto_awesome_rounded,
      isMobile: isMobile,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Furnishing Status
          Text(
            '${loc.tr('furnishingStatusLabel')} *',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TashilConnectedButtonGroup<FurnishingStatus>(
            isFullWidth: true,
            height: 44,
            selectedValue: _draft.furnishingStatus,
            onSelectionChanged: (status) => setState(() => _draft.furnishingStatus = status),
            segments: [
              TashilConnectedButtonSegment(
                value: FurnishingStatus.fullyFurnished,
                label: loc.tr('fullyFurnishedOption'),
                icon: Symbols.chair_rounded,
              ),
              TashilConnectedButtonSegment(
                value: FurnishingStatus.semiFurnished,
                label: loc.tr('semiFurnishedOption'),
                icon: Symbols.weekend_rounded,
              ),
              TashilConnectedButtonSegment(
                value: FurnishingStatus.unfurnished,
                label: loc.tr('unfurnishedOption'),
                icon: Symbols.meeting_room_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // M3 Checkboxes for Amenities
          Text(
            loc.tr('optionalAmenitiesTitle'),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          if (isMobile) ...[
            TashilCheckboxListTile(
              title: Text(loc.tr('parkingAmenity')),
              secondary: Icon(Symbols.local_parking_rounded, color: theme.colorScheme.primary, size: 22),
              value: _draft.hasParking,
              onChanged: (v) => setState(() => _draft.hasParking = v ?? false),
            ),
            const SizedBox(height: 8),
            TashilCheckboxListTile(
              title: Text(loc.tr('centralAcAmenity')),
              secondary: Icon(Symbols.ac_unit_rounded, color: theme.colorScheme.primary, size: 22),
              value: _draft.hasCentralAc,
              onChanged: (v) => setState(() => _draft.hasCentralAc = v ?? false),
            ),
            const SizedBox(height: 8),
            TashilCheckboxListTile(
              title: Text(loc.tr('poolGymAmenity')),
              secondary: Icon(Symbols.pool_rounded, color: theme.colorScheme.primary, size: 22),
              value: _draft.hasPoolGym,
              onChanged: (v) => setState(() => _draft.hasPoolGym = v ?? false),
            ),
            const SizedBox(height: 8),
            TashilCheckboxListTile(
              title: Text(loc.tr('securityAmenity')),
              secondary: Icon(Symbols.security_rounded, color: theme.colorScheme.primary, size: 22),
              value: _draft.hasSecurity,
              onChanged: (v) => setState(() => _draft.hasSecurity = v ?? false),
            ),
            const SizedBox(height: 8),
            TashilCheckboxListTile(
              title: Text(loc.tr('balconyViewAmenity')),
              secondary: Icon(Symbols.balcony_rounded, color: theme.colorScheme.primary, size: 22),
              value: _draft.hasBalconyView,
              onChanged: (v) => setState(() => _draft.hasBalconyView = v ?? false),
            ),
            const SizedBox(height: 8),
            TashilCheckboxListTile(
              title: Text(loc.tr('petFriendlyAmenity')),
              secondary: Icon(Symbols.pets_rounded, color: theme.colorScheme.primary, size: 22),
              value: _draft.isPetFriendly,
              onChanged: (v) => setState(() => _draft.isPetFriendly = v ?? false),
            ),
            const SizedBox(height: 8),
            TashilCheckboxListTile(
              title: Text(loc.tr('hasMaidsRoomOption')),
              secondary: Icon(Symbols.person_outline_rounded, color: theme.colorScheme.primary, size: 22),
              value: _draft.hasMaidsRoom,
              onChanged: (v) => setState(() => _draft.hasMaidsRoom = v ?? false),
            ),
          ] else ...[
            // Responsive 2-column grid for Checkboxes
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TashilCheckboxListTile(
                        title: Text(loc.tr('parkingAmenity')),
                        secondary: Icon(Symbols.local_parking_rounded, color: theme.colorScheme.primary, size: 22),
                        value: _draft.hasParking,
                        onChanged: (v) => setState(() => _draft.hasParking = v ?? false),
                      ),
                      const SizedBox(height: 8),
                      TashilCheckboxListTile(
                        title: Text(loc.tr('poolGymAmenity')),
                        secondary: Icon(Symbols.pool_rounded, color: theme.colorScheme.primary, size: 22),
                        value: _draft.hasPoolGym,
                        onChanged: (v) => setState(() => _draft.hasPoolGym = v ?? false),
                      ),
                      const SizedBox(height: 8),
                      TashilCheckboxListTile(
                        title: Text(loc.tr('balconyViewAmenity')),
                        secondary: Icon(Symbols.balcony_rounded, color: theme.colorScheme.primary, size: 22),
                        value: _draft.hasBalconyView,
                        onChanged: (v) => setState(() => _draft.hasBalconyView = v ?? false),
                      ),
                      const SizedBox(height: 8),
                      TashilCheckboxListTile(
                        title: Text(loc.tr('hasMaidsRoomOption')),
                        secondary: Icon(Symbols.person_outline_rounded, color: theme.colorScheme.primary, size: 22),
                        value: _draft.hasMaidsRoom,
                        onChanged: (v) => setState(() => _draft.hasMaidsRoom = v ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      TashilCheckboxListTile(
                        title: Text(loc.tr('centralAcAmenity')),
                        secondary: Icon(Symbols.ac_unit_rounded, color: theme.colorScheme.primary, size: 22),
                        value: _draft.hasCentralAc,
                        onChanged: (v) => setState(() => _draft.hasCentralAc = v ?? false),
                      ),
                      const SizedBox(height: 8),
                      TashilCheckboxListTile(
                        title: Text(loc.tr('securityAmenity')),
                        secondary: Icon(Symbols.security_rounded, color: theme.colorScheme.primary, size: 22),
                        value: _draft.hasSecurity,
                        onChanged: (v) => setState(() => _draft.hasSecurity = v ?? false),
                      ),
                      const SizedBox(height: 8),
                      TashilCheckboxListTile(
                        title: Text(loc.tr('petFriendlyAmenity')),
                        secondary: Icon(Symbols.pets_rounded, color: theme.colorScheme.primary, size: 22),
                        value: _draft.isPetFriendly,
                        onChanged: (v) => setState(() => _draft.isPetFriendly = v ?? false),
                      ),
                      const SizedBox(height: 56),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 5. MEDIA & DESCRIPTION (M3 Suggestion Chips + M3 Tonal Button + M3 Outlined Fields) ---
  Widget _buildSection5MediaAndDescription(AppLocalizations loc, bool isMobile, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 5,
      title: loc.tr('section5MediaTitle'),
      icon: Symbols.photo_library_rounded,
      isMobile: isMobile,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimum 3 Images Gallery
          PropertyMediaGalleryUploader(
            photoUrls: _draft.photoUrls,
            onPhotosChanged: (urls) => setState(() => _draft.photoUrls = urls),
          ),
          const SizedBox(height: 18),

          // AI Title & Description Generation Button (Gemini 3.8 Flash)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TashilButton.tonal(
              onPressed: _isGeneratingDesc ? null : _triggerAiCopywriting,
              icon: Symbols.auto_awesome_rounded,
              label: _isGeneratingDesc
                  ? loc.tr('savingListing')
                  : loc.tr('generateTitleAndDescAiBtn'),
              fontSize: 13,
              height: 40,
            ),
          ),
          const SizedBox(height: 14),

          // Listing Title (Positioned directly above description)
          TashilTextField.outlined(
            controller: _titleArCtrl,
            labelText: '${loc.tr('propertyTitleField')} *',
            hintText: loc.tr('propertyTitleHint'),
            prefixIcon: Symbols.title_rounded,
            validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
            onChanged: (v) => _draft.titleAr = v,
          ),
          const SizedBox(height: 16),

          // Detailed Marketing Description
          TashilTextField.outlined(
            controller: _descArCtrl,
            labelText: '${loc.tr('detailedDescriptionLabel')} *',
            hintText: loc.tr('detailedDescriptionHint'),
            maxLines: 4,
            validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
            onChanged: (v) => _draft.descriptionAr = v,
          ),
          const SizedBox(height: 20),

          // Video Tour
          TashilTextField.outlined(
            controller: _videoTourCtrl,
            labelText: loc.tr('videoTourUrlLabel'),
            hintText: loc.tr('videoTourUrlHint'),
            prefixIcon: Symbols.videocam_rounded,
            onChanged: (v) => _draft.videoTourUrl = v,
          ),
        ],
      ),
    );
  }
}
