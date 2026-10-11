import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';
import 'package:tashil_real_estate/core/services/location/gps_service.dart';
import 'package:tashil_real_estate/core/services/location/location_geocoding_service.dart';
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

  final PropertyMarketingTone _selectedTone = PropertyMarketingTone.luxuryExecutive;
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
        iconData: Icons.lock_outline_rounded,
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
            icon: Icons.login_rounded,
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
        iconData: Icons.verified_rounded,
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
            icon: Icons.dashboard_rounded,
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

            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/fast-onboarding'),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
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
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary, size: 24),
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

                          // 1. HERO AI VOICE ACTION BANNER
                          _buildVoiceAutofillBanner(loc, isMobile, theme),
                          const SizedBox(height: 20),

                          // 2. SECTION 1: THE LOCATION
                          _buildSection1Location(loc, theme),
                          const SizedBox(height: 20),

                          // 3. SECTION 2: FINANCIAL TRANSPARENCY
                          _buildSection2Financials(loc, theme),
                          const SizedBox(height: 20),

                          // 4. SECTION 3: TECHNICAL SPECS
                          _buildSection3TechnicalSpecs(loc, theme),
                          const SizedBox(height: 20),

                          // 5. SECTION 4: AMENITIES
                          _buildSection4Amenities(loc, theme),
                          const SizedBox(height: 20),

                          // 6. SECTION 5: MEDIA & DESCRIPTION
                          _buildSection5MediaAndDescription(loc, isMobile, theme),
                          const SizedBox(height: 28),

                          // SUBMIT BUTTON
                          SizedBox(
                            height: 52,
                            child: TashilButton(
                              onPressed: _isSubmitting ? null : () => _handleSubmit(loc),
                              icon: isEditing ? Icons.save_rounded : Icons.publish_rounded,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.save_as_rounded,
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
            icon: Icons.delete_sweep_outlined,
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

  // --- HERO VOICE AUTOFILL BANNER ---
  Widget _buildVoiceAutofillBanner(AppLocalizations loc, bool isMobile, ThemeData theme) {
    return TashilCard.filled(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.mic_rounded, color: theme.colorScheme.primary, size: 28),
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
                              Icon(Icons.auto_awesome_rounded, size: 12, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Gemini AI',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('voiceAutofillHeroDesc'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
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
            child: TashilButton(
              onPressed: _handleVoiceAutofill,
              icon: Icons.record_voice_over_rounded,
              label: loc.tr('startVoiceDictationBtn'),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION CONTAINER HELPER ---
  Widget _buildSectionCard({
    required int sectionIndex,
    required String title,
    required IconData icon,
    required Widget child,
    required ThemeData theme,
  }) {
    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: theme.colorScheme.onSecondaryContainer, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 14),
          const TashilDivider.cardAction(),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldBadge({
    required bool isMandatory,
    required String label,
    required AppLocalizations loc,
    required ThemeData theme,
  }) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: isMandatory
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.75)
                : theme.colorScheme.secondaryContainer.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isMandatory
                  ? theme.colorScheme.error.withValues(alpha: 0.3)
                  : theme.colorScheme.secondary.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            isMandatory ? loc.tr('fieldRequiredBadge') : loc.tr('fieldOptionalBadge'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isMandatory
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  // --- 1. THE LOCATION ---
  Widget _buildSection1Location(AppLocalizations loc, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 1,
      title: loc.tr('section1LocationTitle'),
      icon: Icons.location_on_rounded,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Map Pin Coordinates
          _buildFieldBadge(isMandatory: true, label: loc.tr('mapPinCoordinatesLabel'), loc: loc, theme: theme),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 460;
                    final gpsBtn = TashilButton.tonal(
                      onPressed: _isLocatingGps ? null : () => _handleFetchGpsLocation(loc),
                      icon: Icons.my_location_rounded,
                      label: _isLocatingGps ? loc.tr('locatingGpsProgress') : loc.tr('useCurrentLocationGpsBtn'),
                    );
                    final mapBtn = TashilButton.outlined(
                      onPressed: _handleOpenInGoogleMaps,
                      icon: Icons.map_rounded,
                      label: loc.tr('viewOnGoogleMapsBtn'),
                    );
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          gpsBtn,
                          const SizedBox(height: 8),
                          mapBtn,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: gpsBtn),
                        const SizedBox(width: 10),
                        mapBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressSearchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: loc.tr('searchAddressPlaceholder'),
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _isSearchingAddress
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            onPressed: () => _handleSearchAddress(loc),
                          ),
                  ),
                  onFieldSubmitted: (_) => _handleSearchAddress(loc),
                ),
                if (_draft.latitude != 0.0 && _draft.longitude != 0.0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_draft.latitude.toStringAsFixed(4)}, ${_draft.longitude.toStringAsFixed(4)} (${_draft.city} - ${_draft.district})',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
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

          // Mandatory City & District
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final cityWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('cityLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cityCtrl,
                    decoration: InputDecoration(
                      hintText: loc.tr('cityHint'),
                      prefixIcon: const Icon(Icons.location_city_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.city = v,
                  ),
                ],
              );

              final districtWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('districtLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _districtCtrl,
                    decoration: InputDecoration(
                      hintText: loc.tr('districtHint'),
                      prefixIcon: const Icon(Icons.map_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.district = v,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    cityWidget,
                    const SizedBox(height: 14),
                    districtWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cityWidget),
                  const SizedBox(width: 12),
                  Expanded(child: districtWidget),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Optional Compound/Tower & Unit Number
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final buildingWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: false, label: loc.tr('buildingCompoundLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _buildingNameCtrl,
                    decoration: InputDecoration(
                      hintText: loc.tr('buildingCompoundHint'),
                      prefixIcon: const Icon(Icons.domain_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => _draft.buildingName = v,
                  ),
                ],
              );

              final unitWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: false, label: loc.tr('unitNumberFieldLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _unitNumberCtrl,
                    decoration: InputDecoration(
                      hintText: loc.tr('unitNumberFieldHint'),
                      prefixIcon: const Icon(Icons.meeting_room_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => _draft.unitNumber = v,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    buildingWidget,
                    const SizedBox(height: 14),
                    unitWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buildingWidget),
                  const SizedBox(width: 12),
                  Expanded(child: unitWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 2. FINANCIAL TRANSPARENCY ---
  Widget _buildSection2Financials(AppLocalizations loc, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 2,
      title: loc.tr('section2FinancialsTitle'),
      icon: Icons.account_balance_wallet_rounded,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Rent Price & Currency (decoupled from Payment Frequency)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              final rentField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('rentPriceFieldLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _rentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.monthlyRent = double.tryParse(v) ?? _draft.monthlyRent,
                  ),
                ],
              );

              final currencyField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('currencyLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _draft.currency,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_exchange_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'EGP', child: Text('ج.م (EGP)')),
                      DropdownMenuItem(value: 'AED', child: Text('د.إ (AED)')),
                      DropdownMenuItem(value: 'USD', child: Text('\$ (USD)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _draft.currency = v);
                    },
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    rentField,
                    const SizedBox(height: 14),
                    currencyField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: rentField),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: currencyField),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Row 2: Payment Frequency (Connected Button Group!)
          _buildFieldBadge(isMandatory: true, label: loc.tr('paymentFrequencyLabel'), loc: loc, theme: theme),
          const SizedBox(height: 8),
          TashilConnectedButtonGroup<PaymentFrequency>(
            isFullWidth: true,
            height: 44,
            selectedValue: _draft.paymentFrequency,
            onSelectionChanged: (freq) => setState(() => _draft.paymentFrequency = freq),
            segments: [
              TashilConnectedButtonSegment(
                value: PaymentFrequency.monthly,
                label: loc.tr('freq_monthly'),
                icon: Icons.calendar_month_rounded,
              ),
              TashilConnectedButtonSegment(
                value: PaymentFrequency.quarterly,
                label: loc.tr('freq_quarterly'),
                icon: Icons.date_range_rounded,
              ),
              TashilConnectedButtonSegment(
                value: PaymentFrequency.annual,
                label: loc.tr('freq_annual'),
                icon: Icons.event_available_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Optional Security Deposit
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldBadge(isMandatory: false, label: loc.tr('securityDepositLabel'), loc: loc, theme: theme),
              const SizedBox(height: 6),
              TextFormField(
                controller: _depositCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: loc.tr('securityDepositHint'),
                  prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => _draft.securityDeposit = double.tryParse(v),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // M3 Switches for Financial Options
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final billsTile = TashilSwitchListTile(
                title: Text(
                  loc.tr('billsIncludedOption'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                secondary: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary, size: 22),
                value: _draft.isBillsIncluded,
                onChanged: (v) => setState(() => _draft.isBillsIncluded = v),
              );
              final negotiableTile = TashilSwitchListTile(
                title: Text(
                  loc.tr('isNegotiableOption'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                secondary: Icon(Icons.handshake_outlined, color: theme.colorScheme.secondary, size: 22),
                value: _draft.isNegotiable,
                onChanged: (v) => setState(() => _draft.isNegotiable = v),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    billsTile,
                    const SizedBox(height: 4),
                    negotiableTile,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: billsTile),
                  const SizedBox(width: 8),
                  Expanded(child: negotiableTile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getPropertyTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'villa':
        return Icons.villa_rounded;
      case 'studio':
        return Icons.single_bed_rounded;
      case 'office':
        return Icons.business_center_rounded;
      case 'chalet':
        return Icons.beach_access_rounded;
      case 'apartment':
      default:
        return Icons.apartment_rounded;
    }
  }

  // --- 3. TECHNICAL SPECS ---
  Widget _buildSection3TechnicalSpecs(AppLocalizations loc, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 3,
      title: loc.tr('section3TechnicalSpecsTitle'),
      icon: Icons.tune_rounded,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Property Type & Area
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final safePropertyType = ['apartment', 'villa', 'studio', 'office', 'chalet']
                      .contains(_draft.propertyType.toLowerCase())
                  ? _draft.propertyType.toLowerCase()
                  : 'apartment';

              final propTypeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('propertyTypeLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TashilDropdownMenu<String>(
                    value: safePropertyType,
                    height: 48.0,
                    prefixIcon: _getPropertyTypeIcon(safePropertyType),
                    items: [
                      TashilDropdownMenuItem<String>(
                        value: 'apartment',
                        label: loc.tr('propTypeApartment'),
                        icon: Icons.apartment_rounded,
                      ),
                      TashilDropdownMenuItem<String>(
                        value: 'villa',
                        label: loc.tr('propTypeVilla'),
                        icon: Icons.villa_rounded,
                      ),
                      TashilDropdownMenuItem<String>(
                        value: 'studio',
                        label: loc.tr('propTypeStudio'),
                        icon: Icons.single_bed_rounded,
                      ),
                      TashilDropdownMenuItem<String>(
                        value: 'office',
                        label: loc.tr('propTypeOffice'),
                        icon: Icons.business_center_rounded,
                      ),
                      TashilDropdownMenuItem<String>(
                        value: 'chalet',
                        label: loc.tr('propTypeChalet'),
                        icon: Icons.beach_access_rounded,
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _draft.propertyType = v;
                        });
                      }
                    },
                  ),
                ],
              );

              final areaField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('areaSqmFieldLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _areaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: 'م²',
                      prefixIcon: const Icon(Icons.square_foot_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.areaSqm = int.tryParse(v) ?? _draft.areaSqm,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    propTypeField,
                    const SizedBox(height: 14),
                    areaField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: propTypeField),
                  const SizedBox(width: 12),
                  Expanded(child: areaField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Mandatory Bedrooms & Bathrooms
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final bedsField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('bedroomsLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bedroomsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.bed_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.bedrooms = int.tryParse(v) ?? _draft.bedrooms,
                  ),
                ],
              );

              final bathsField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: true, label: loc.tr('bathroomsLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bathroomsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.bathtub_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
                    onChanged: (v) => _draft.bathrooms = int.tryParse(v) ?? _draft.bathrooms,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    bedsField,
                    const SizedBox(height: 14),
                    bathsField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: bedsField),
                  const SizedBox(width: 12),
                  Expanded(child: bathsField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Optional Floor & Building Age
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final floorField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: false, label: loc.tr('floorNumberLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _floorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: loc.tr('floorNumberHint'),
                      prefixIcon: const Icon(Icons.layers_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => _draft.floor = int.tryParse(v),
                  ),
                ],
              );

              final ageField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldBadge(isMandatory: false, label: loc.tr('buildingAgeLabel'), loc: loc, theme: theme),
                  const SizedBox(height: 6),
                  TashilConnectedButtonGroup<BuildingAge>(
                    isFullWidth: true,
                    height: 42,
                    selectedValue: _draft.buildingAge ?? BuildingAge.brandNew,
                    onSelectionChanged: (age) => setState(() => _draft.buildingAge = age),
                    segments: [
                      TashilConnectedButtonSegment(
                        value: BuildingAge.brandNew,
                        label: loc.tr('ageBrandNew'),
                        icon: Icons.fiber_new_rounded,
                      ),
                      TashilConnectedButtonSegment(
                        value: BuildingAge.oneToFive,
                        label: loc.tr('ageOneToFive'),
                        icon: Icons.history_rounded,
                      ),
                      TashilConnectedButtonSegment(
                        value: BuildingAge.older,
                        label: loc.tr('ageOlder'),
                        icon: Icons.domain_verification_rounded,
                      ),
                    ],
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    floorField,
                    const SizedBox(height: 14),
                    ageField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: floorField),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: ageField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Maid's Room switch
          TashilSwitchListTile(
            title: Text(loc.tr('hasMaidsRoomOption'), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            secondary: Icon(Icons.person_outline_rounded, color: theme.colorScheme.secondary, size: 22),
            value: _draft.hasMaidsRoom,
            onChanged: (v) => setState(() => _draft.hasMaidsRoom = v),
          ),
        ],
      ),
    );
  }

  // --- 4. AMENITIES ---
  Widget _buildSection4Amenities(AppLocalizations loc, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 4,
      title: loc.tr('section4AmenitiesTitle'),
      icon: Icons.auto_awesome_rounded,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Furnishing Status
          _buildFieldBadge(isMandatory: true, label: loc.tr('furnishingStatusLabel'), loc: loc, theme: theme),
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
                icon: Icons.meeting_room_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Optional Amenities Filter Chips
          _buildFieldBadge(isMandatory: false, label: loc.tr('optionalAmenitiesTitle'), loc: loc, theme: theme),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TashilFilterChip(
                label: loc.tr('parkingAmenity'),
                icon: Icons.local_parking_rounded,
                selected: _draft.hasParking,
                onSelected: (v) => setState(() => _draft.hasParking = v),
              ),
              TashilFilterChip(
                label: loc.tr('centralAcAmenity'),
                icon: Icons.ac_unit_rounded,
                selected: _draft.hasCentralAc,
                onSelected: (v) => setState(() => _draft.hasCentralAc = v),
              ),
              TashilFilterChip(
                label: loc.tr('poolGymAmenity'),
                icon: Icons.pool_rounded,
                selected: _draft.hasPoolGym,
                onSelected: (v) => setState(() => _draft.hasPoolGym = v),
              ),
              TashilFilterChip(
                label: loc.tr('securityAmenity'),
                icon: Icons.security_rounded,
                selected: _draft.hasSecurity,
                onSelected: (v) => setState(() => _draft.hasSecurity = v),
              ),
              TashilFilterChip(
                label: loc.tr('balconyViewAmenity'),
                icon: Icons.balcony_rounded,
                selected: _draft.hasBalconyView,
                onSelected: (v) => setState(() => _draft.hasBalconyView = v),
              ),
              TashilFilterChip(
                label: loc.tr('petFriendlyAmenity'),
                icon: Icons.pets_rounded,
                selected: _draft.isPetFriendly,
                onSelected: (v) => setState(() => _draft.isPetFriendly = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. MEDIA & DESCRIPTION ---
  Widget _buildSection5MediaAndDescription(AppLocalizations loc, bool isMobile, ThemeData theme) {
    return _buildSectionCard(
      sectionIndex: 5,
      title: loc.tr('section5MediaTitle'),
      icon: Icons.photo_library_rounded,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Minimum 3 Images - Animated Gallery System
          PropertyMediaGalleryUploader(
            photoUrls: _draft.photoUrls,
            onPhotosChanged: (urls) => setState(() => _draft.photoUrls = urls),
          ),
          const SizedBox(height: 20),

          // Mandatory Listing Title
          _buildFieldBadge(isMandatory: true, label: loc.tr('propertyTitleField'), loc: loc, theme: theme),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleArCtrl,
            decoration: InputDecoration(
              hintText: loc.tr('propertyTitleHint'),
              prefixIcon: const Icon(Icons.title_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
            onChanged: (v) => _draft.titleAr = v,
          ),
          const SizedBox(height: 18),

          // Mandatory AI-Assisted Detailed Description
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildFieldBadge(isMandatory: true, label: loc.tr('detailedDescriptionLabel'), loc: loc, theme: theme),
              TashilButton.tonal(
                onPressed: _isGeneratingDesc ? null : _triggerAiCopywriting,
                icon: Icons.auto_awesome_rounded,
                label: loc.tr('generateWithAiBtn'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descArCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: loc.tr('detailedDescriptionHint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('fieldRequiredError') : null,
            onChanged: (v) => _draft.descriptionAr = v,
          ),
          const SizedBox(height: 18),

          // Optional Video Tour
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldBadge(isMandatory: false, label: loc.tr('videoTourUrlLabel'), loc: loc, theme: theme),
              const SizedBox(height: 6),
              TextFormField(
                controller: _videoTourCtrl,
                decoration: InputDecoration(
                  hintText: loc.tr('videoTourUrlHint'),
                  prefixIcon: const Icon(Icons.videocam_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => _draft.videoTourUrl = v,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
