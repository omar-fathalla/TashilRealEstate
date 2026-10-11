import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/location/gps_service.dart';
import 'package:tashil_real_estate/core/services/location/location_geocoding_service.dart';

/// Item representing a verified district, neighborhood, or compound.
class DistrictItem {
  final String id;
  final String nameAr;
  final String nameEn;
  final String nameHi;
  final String cityAr;
  final String cityEn;
  final String cityHi;
  final String category; // 'new_cairo', 'zayed_october', 'central_cairo', 'coastal', 'dubai_prime', 'dubai_suburbs', 'abu_dhabi'
  final double latitude;
  final double longitude;
  final IconData icon;

  const DistrictItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameHi,
    required this.cityAr,
    required this.cityEn,
    required this.cityHi,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.icon = Icons.apartment_rounded,
  });

  String getLocalizedName(String lang) {
    if (lang == 'en') return nameEn;
    if (lang == 'hi') return nameHi;
    return nameAr;
  }

  String getLocalizedCity(String lang) {
    if (lang == 'en') return cityEn;
    if (lang == 'hi') return cityHi;
    return cityAr;
  }
}

/// Official M3 Modal Dialog for interactive district & Google Maps location picking.
class DistrictLocationPickerDialog extends StatefulWidget {
  final String countryCode;
  final String? currentDistrict;

  const DistrictLocationPickerDialog({
    super.key,
    required this.countryCode,
    this.currentDistrict,
  });

  static Future<String?> show(
    BuildContext context, {
    required String countryCode,
    String? currentDistrict,
  }) {
    return TashilTransitions.showM3Dialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: DistrictLocationPickerDialog(
            countryCode: countryCode,
            currentDistrict: currentDistrict,
          ),
        ),
      ),
    );
  }

  @override
  State<DistrictLocationPickerDialog> createState() => _DistrictLocationPickerDialogState();
}

class _DistrictLocationPickerDialogState extends State<DistrictLocationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mapsUrlController = TextEditingController();
  final LocationGeocodingService _geocodingService = LocationGeocodingService();
  final GpsService _gpsService = GpsService();

  String _selectedCategory = 'all';
  bool _isLocatingGps = false;
  bool _showMapsUrlInput = false;

  late final List<DistrictItem> _allDistricts;

  @override
  void initState() {
    super.initState();
    _allDistricts = _buildVerifiedDistrictsDatabase(widget.countryCode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapsUrlController.dispose();
    super.dispose();
  }

  List<DistrictItem> _buildVerifiedDistrictsDatabase(String country) {
    if (country == 'AE') {
      return const [
        DistrictItem(
          id: 'ae_dubai_marina',
          nameAr: 'دبي مارينا',
          nameEn: 'Dubai Marina',
          nameHi: 'दुबई मरीना',
          cityAr: 'دبي',
          cityEn: 'Dubai',
          cityHi: 'दुबई',
          category: 'dubai_prime',
          latitude: 25.0805,
          longitude: 55.1403,
          icon: Icons.water_rounded,
        ),
        DistrictItem(
          id: 'ae_downtown_dubai',
          nameAr: 'داون تاون دبي (وسط المدينة)',
          nameEn: 'Downtown Dubai',
          nameHi: 'डाउनटाउन दुबई',
          cityAr: 'دبي',
          cityEn: 'Dubai',
          cityHi: 'दुबई',
          category: 'dubai_prime',
          latitude: 25.1972,
          longitude: 55.2744,
          icon: Icons.location_city_rounded,
        ),
        DistrictItem(
          id: 'ae_business_bay',
          nameAr: 'الخليج التجاري (بيزنس باي)',
          nameEn: 'Business Bay',
          nameHi: 'बिजनेस बे',
          cityAr: 'دبي',
          cityEn: 'Dubai',
          cityHi: 'दुबई',
          category: 'dubai_prime',
          latitude: 25.1857,
          longitude: 55.2656,
          icon: Icons.business_rounded,
        ),
        DistrictItem(
          id: 'ae_palm_jumeirah',
          nameAr: 'نخلة جميرا',
          nameEn: 'Palm Jumeirah',
          nameHi: 'पाम जुमेराह',
          cityAr: 'دبي',
          cityEn: 'Dubai',
          cityHi: 'दुबई',
          category: 'dubai_prime',
          latitude: 25.1124,
          longitude: 55.1390,
          icon: Icons.villa_rounded,
        ),
        DistrictItem(
          id: 'ae_jvc',
          nameAr: 'قرية جميرا الدائرية (JVC)',
          nameEn: 'Jumeirah Village Circle (JVC)',
          nameHi: 'जुमेराह विलेज सर्कल (JVC)',
          cityAr: 'دبي',
          cityEn: 'Dubai',
          cityHi: 'दुबई',
          category: 'dubai_suburbs',
          latitude: 25.0601,
          longitude: 55.2078,
          icon: Icons.apartment_rounded,
        ),
        DistrictItem(
          id: 'ae_dubai_hills',
          nameAr: 'دبي هيلز استيت',
          nameEn: 'Dubai Hills Estate',
          nameHi: 'दुबई हिल्स एस्टेट',
          cityAr: 'دبي',
          cityEn: 'Dubai',
          cityHi: 'दुबई',
          category: 'dubai_suburbs',
          latitude: 25.1130,
          longitude: 55.2530,
          icon: Icons.park_rounded,
        ),
        DistrictItem(
          id: 'ae_jlt',
          nameAr: 'أبراج بحيرات جميرا (JLT)',
          nameEn: 'Jumeirah Lakes Towers (JLT)',
          nameHi: 'जुमेराह लेक्स टावर्स (JLT)',
          cityAr: 'دبي',
          cityEn: 'Dubai',
          cityHi: 'दुबई',
          category: 'dubai_prime',
          latitude: 25.0743,
          longitude: 55.1492,
          icon: Icons.domain_rounded,
        ),
        DistrictItem(
          id: 'ae_yas_island',
          nameAr: 'جزيرة ياس',
          nameEn: 'Yas Island',
          nameHi: 'यास द्वीप',
          cityAr: 'أبوظبي',
          cityEn: 'Abu Dhabi',
          cityHi: 'अबू धाबी',
          category: 'abu_dhabi',
          latitude: 24.4988,
          longitude: 54.6062,
          icon: Icons.attractions_rounded,
        ),
        DistrictItem(
          id: 'ae_al_reem',
          nameAr: 'جزيرة الريم',
          nameEn: 'Al Reem Island',
          nameHi: 'अल रीम द्वीप',
          cityAr: 'أبوظبي',
          cityEn: 'Abu Dhabi',
          cityHi: 'अबू धाबी',
          category: 'abu_dhabi',
          latitude: 24.4965,
          longitude: 54.4042,
          icon: Icons.holiday_village_rounded,
        ),
      ];
    }

    // Egypt Database
    return const [
      DistrictItem(
        id: 'eg_5th_settlement',
        nameAr: 'التجمع الخامس (القاهرة الجديدة)',
        nameEn: '5th Settlement (New Cairo)',
        nameHi: '5वां सेटलमेंट (न्यू काहिरा)',
        cityAr: 'القاهرة الجديدة',
        cityEn: 'New Cairo',
        cityHi: 'न्यू काहिरा',
        category: 'new_cairo',
        latitude: 30.0131,
        longitude: 31.4913,
        icon: Icons.location_city_rounded,
      ),
      DistrictItem(
        id: 'eg_el_narges',
        nameAr: 'حي النرجس (التجمع الخامس)',
        nameEn: 'El Narges (5th Settlement)',
        nameHi: 'अल नर्गिस (5वां सेटलमेंट)',
        cityAr: 'القاهرة الجديدة',
        cityEn: 'New Cairo',
        cityHi: 'न्यू काहिरा',
        category: 'new_cairo',
        latitude: 30.0185,
        longitude: 31.4721,
        icon: Icons.apartment_rounded,
      ),
      DistrictItem(
        id: 'eg_beit_el_watan',
        nameAr: 'بيت الوطن (القاهرة الجديدة)',
        nameEn: 'Beit El Watan (New Cairo)',
        nameHi: 'बेत अल वतन (न्यू काहिरा)',
        cityAr: 'القاهرة الجديدة',
        cityEn: 'New Cairo',
        cityHi: 'न्यू काहिरा',
        category: 'new_cairo',
        latitude: 30.0380,
        longitude: 31.5420,
        icon: Icons.villa_rounded,
      ),
      DistrictItem(
        id: 'eg_el_yasmeen',
        nameAr: 'حي الياسمين (التجمع الأول)',
        nameEn: 'El Yasmeen (1st Settlement)',
        nameHi: 'अल यास्मीन (पहला सेटलमेंट)',
        cityAr: 'القاهرة الجديدة',
        cityEn: 'New Cairo',
        cityHi: 'न्यू काहिरा',
        category: 'new_cairo',
        latitude: 30.0450,
        longitude: 31.4750,
        icon: Icons.domain_rounded,
      ),
      DistrictItem(
        id: 'eg_al_rehab',
        nameAr: 'مدينة الرحاب',
        nameEn: 'Al Rehab City',
        nameHi: 'अल रेहाब शहर',
        cityAr: 'القاهرة الجديدة',
        cityEn: 'New Cairo',
        cityHi: 'न्यू काहिरा',
        category: 'new_cairo',
        latitude: 30.0610,
        longitude: 31.4920,
        icon: Icons.park_rounded,
      ),
      DistrictItem(
        id: 'eg_madinaty',
        nameAr: 'مدينتي',
        nameEn: 'Madinaty',
        nameHi: 'मदीनती',
        cityAr: 'القاهرة',
        cityEn: 'Cairo',
        cityHi: 'काहिरा',
        category: 'new_cairo',
        latitude: 30.0910,
        longitude: 31.6430,
        icon: Icons.holiday_village_rounded,
      ),
      DistrictItem(
        id: 'eg_sheikh_zayed',
        nameAr: 'مدينة الشيخ زايد',
        nameEn: 'Sheikh Zayed City',
        nameHi: 'शेख जायद शहर',
        cityAr: 'الجيزة',
        cityEn: 'Giza',
        cityHi: 'गीज़ा',
        category: 'zayed_october',
        latitude: 30.0561,
        longitude: 30.9788,
        icon: Icons.villa_rounded,
      ),
      DistrictItem(
        id: 'eg_beverly_hills',
        nameAr: 'كمبوند بيفرلي هيلز (الشيخ زايد)',
        nameEn: 'Beverly Hills Compound (Sheikh Zayed)',
        nameHi: 'बेवर्ली हिल्स कंपाउंड (शेख जायद)',
        cityAr: 'الجيزة',
        cityEn: 'Giza',
        cityHi: 'गीज़ा',
        category: 'zayed_october',
        latitude: 30.0680,
        longitude: 30.9320,
        icon: Icons.home_work_rounded,
      ),
      DistrictItem(
        id: 'eg_6_october',
        nameAr: 'مدينة 6 أكتوبر (المحور المركزي)',
        nameEn: '6th of October City',
        nameHi: '6 अक्टूबर शहर',
        cityAr: 'الجيزة',
        cityEn: 'Giza',
        cityHi: 'गीज़ा',
        category: 'zayed_october',
        latitude: 29.9723,
        longitude: 30.9426,
        icon: Icons.apartment_rounded,
      ),
      DistrictItem(
        id: 'eg_maadi',
        nameAr: 'المعادي (دجلة وسرايات المعادي)',
        nameEn: 'Maadi (Degla & Sarayat)',
        nameHi: 'मादी (देगला और सरायत)',
        cityAr: 'القاهرة',
        cityEn: 'Cairo',
        cityHi: 'काहिरा',
        category: 'central_cairo',
        latitude: 29.9602,
        longitude: 31.2569,
        icon: Icons.park_rounded,
      ),
      DistrictItem(
        id: 'eg_heliopolis',
        nameAr: 'مصر الجديدة (الكوربة وميدان الحجاز)',
        nameEn: 'Heliopolis (Korba & Hegaz)',
        nameHi: 'हेलियोपोलिस (कोरबा)',
        cityAr: 'القاهرة',
        cityEn: 'Cairo',
        cityHi: 'काहिरा',
        category: 'central_cairo',
        latitude: 30.0890,
        longitude: 31.3280,
        icon: Icons.location_city_rounded,
      ),
      DistrictItem(
        id: 'eg_nasr_city',
        nameAr: 'مدينة نصر (عباس العقاد ومكرم عبيد)',
        nameEn: 'Nasr City (Abbas El Akkad)',
        nameHi: 'नस्र शहर',
        cityAr: 'القاهرة',
        cityEn: 'Cairo',
        cityHi: 'काहिरा',
        category: 'central_cairo',
        latitude: 30.0571,
        longitude: 31.3411,
        icon: Icons.domain_rounded,
      ),
      DistrictItem(
        id: 'eg_zamalek',
        nameAr: 'الزمالك (جزيرة الزمالك)',
        nameEn: 'Zamalek Island',
        nameHi: 'जमालेक द्वीप',
        cityAr: 'القاهرة',
        cityEn: 'Cairo',
        cityHi: 'काहिरा',
        category: 'central_cairo',
        latitude: 30.0609,
        longitude: 31.2197,
        icon: Icons.water_rounded,
      ),
      DistrictItem(
        id: 'eg_dokki',
        nameAr: 'الدقي (شارع مصدق ومحي الدين)',
        nameEn: 'Dokki (Mossadak & Mohy El Din)',
        nameHi: 'दोक्की',
        cityAr: 'الجيزة',
        cityEn: 'Giza',
        cityHi: 'गीज़ा',
        category: 'central_cairo',
        latitude: 30.0382,
        longitude: 31.2119,
        icon: Icons.business_rounded,
      ),
      DistrictItem(
        id: 'eg_smouha',
        nameAr: 'سموحة (الإسكندرية)',
        nameEn: 'Smouha (Alexandria)',
        nameHi: 'स्मोहा (अलेक्जेंड्रिया)',
        cityAr: 'الإسكندرية',
        cityEn: 'Alexandria',
        cityHi: 'अलेक्जेंड्रिया',
        category: 'coastal',
        latitude: 31.2156,
        longitude: 29.9489,
        icon: Icons.apartment_rounded,
      ),
      DistrictItem(
        id: 'eg_agami_kilo21',
        nameAr: 'العجمي - الكيلو 21 (شاطئ الزراعيين)',
        nameEn: 'Agami - Kilo 21 (Agricultural Beach)',
        nameHi: 'अगामी - किलो 21',
        cityAr: 'الإسكندرية',
        cityEn: 'Alexandria',
        cityHi: 'अलेक्जेंड्रिया',
        category: 'coastal',
        latitude: 31.0860,
        longitude: 29.7130,
        icon: Icons.beach_access_rounded,
      ),
    ];
  }

  Future<void> _handleGpsLocate() async {
    setState(() => _isLocatingGps = true);
    final loc = AppLocalizations.of(context);

    try {
      final resolved = await _geocodingService.fetchCurrentGpsLocation(
        preferredCountry: widget.countryCode,
      );

      if (mounted) {
        setState(() => _isLocatingGps = false);
        if (resolved != null) {
          final resultString = resolved.district.isNotEmpty
              ? '${resolved.district}، ${resolved.city}'
              : resolved.city;
          TashilSnackBar.showSuccess(
            context: context,
            message: '${loc.tr('locationDetectedSuccess')}: $resultString',
          );
          Navigator.of(context).pop(resultString);
        } else {
          TashilSnackBar.showWarning(
            context: context,
            message: loc.tr('locationPermissionDenied'),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocatingGps = false);
        TashilSnackBar.showWarning(
          context: context,
          message: loc.tr('locationPermissionDenied'),
        );
      }
    }
  }

  void _handleGoogleMapsSearch() {
    final query = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : (widget.countryCode == 'AE' ? 'Dubai real estate' : 'عقارات القاهرة والتجمع');
    _gpsService.openUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
  }

  Future<void> _handleParseGoogleMapsUrl() async {
    final text = _mapsUrlController.text.trim();
    if (text.isEmpty) return;

    final loc = AppLocalizations.of(context);
    final resolved = _geocodingService.parseGoogleMapsUrl(text);

    if (resolved != null) {
      final address = '${resolved.district}، ${resolved.city}';
      TashilSnackBar.showSuccess(
        context: context,
        message: '${loc.tr('districtSelectedNotice')}: $address',
      );
      Navigator.of(context).pop(address);
    } else {
      // Try search location
      final searched = await _geocodingService.searchLocation(text, countryCode: widget.countryCode);
      if (searched != null && mounted) {
        final address = '${searched.district}، ${searched.city}';
        TashilSnackBar.showSuccess(
          context: context,
          message: '${loc.tr('districtSelectedNotice')}: $address',
        );
        Navigator.of(context).pop(address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final lang = locale.languageCode;

        final query = _searchController.text.trim().toLowerCase();
        final filteredDistricts = _allDistricts.where((district) {
          final matchesCategory = _selectedCategory == 'all' || district.category == _selectedCategory;
          if (!matchesCategory) return false;

          if (query.isEmpty) return true;
          return district.nameAr.toLowerCase().contains(query) ||
              district.nameEn.toLowerCase().contains(query) ||
              district.nameHi.toLowerCase().contains(query) ||
              district.cityAr.toLowerCase().contains(query) ||
              district.cityEn.toLowerCase().contains(query);
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Structured M3 Header
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('pickDistrictOrCompound'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.tr('searchOnGoogleMaps'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TashilIconButton.close(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const TashilDivider.fullWidth(),

              // 2. Search Box + Quick GPS Locate + Google Maps Web
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: loc.tr('searchDistrictsPlaceholder'),
                        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 20),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              TashilIconButton.close(
                                size: 28,
                                iconSize: 15,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                            IconButton(
                              tooltip: loc.tr('openInGoogleMapsAction'),
                              icon: Icon(Icons.travel_explore_rounded, color: colorScheme.secondary, size: 20),
                              onPressed: _handleGoogleMapsSearch,
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),

                    // Fast Action Buttons: GPS Pinpoint & Paste Maps URL
                    Row(
                      children: [
                        Expanded(
                          child: TashilButton.tonal(
                            onPressed: _isLocatingGps ? null : _handleGpsLocate,
                            icon: _isLocatingGps ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
                            label: _isLocatingGps
                                ? loc.tr('locatingCurrentPosition')
                                : loc.tr('useCurrentGpsLocation'),
                            height: 40,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TashilAssistChip.outlined(
                          onPressed: () => setState(() => _showMapsUrlInput = !_showMapsUrlInput),
                          icon: Icons.link_rounded,
                          label: loc.tr('pasteGoogleMapsLink'),
                        ),
                      ],
                    ),

                    if (_showMapsUrlInput) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mapsUrlController,
                              decoration: InputDecoration(
                                hintText: 'maps.google.com/...',
                                isDense: true,
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TashilButton(
                            height: 38,
                            onPressed: _handleParseGoogleMapsUrl,
                            label: loc.tr('doneAction'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Category Filter Segments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildCategoryChips(loc, colorScheme),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const TashilDivider.fullWidth(),

              // 4. District Item List
              Flexible(
                child: filteredDistricts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: colorScheme.outline),
                              const SizedBox(height: 10),
                              Text(
                                loc.tr('searchDistrictsPlaceholder'),
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredDistricts.length,
                        separatorBuilder: (_, __) => const TashilDivider.inset(),
                        itemBuilder: (context, index) {
                          final item = filteredDistricts[index];
                          final localizedName = item.getLocalizedName(lang);
                          final localizedCity = item.getLocalizedCity(lang);
                          final isCurrent = widget.currentDistrict != null &&
                              (widget.currentDistrict!.contains(item.nameAr) ||
                                  widget.currentDistrict!.contains(item.nameEn));

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                color: isCurrent ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              localizedName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '$localizedCity • ${item.latitude.toStringAsFixed(3)}, ${item.longitude.toStringAsFixed(3)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: TashilButton.text(
                              height: 32,
                              onPressed: () => Navigator.of(context).pop(localizedName),
                              label: loc.tr('selectCountry').replaceAll('اختر الدولة', 'اختيار').replaceAll('Select Country', 'Select').replaceAll('देश चुनें', 'चुनें'),
                            ),
                            onTap: () => Navigator.of(context).pop(localizedName),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCategoryChips(AppLocalizations loc, ColorScheme colorScheme) {
    if (widget.countryCode == 'AE') {
      return [
        _buildFilterPill('all', loc.tr('allDistrictsTab')),
        _buildFilterPill('dubai_prime', 'Dubai Prime & Marina'),
        _buildFilterPill('dubai_suburbs', 'Dubai Hills & JVC'),
        _buildFilterPill('abu_dhabi', 'Abu Dhabi Islands'),
      ];
    }

    return [
      _buildFilterPill('all', loc.tr('allDistrictsTab')),
      _buildFilterPill('new_cairo', 'القاهرة الجديدة والتجمع'),
      _buildFilterPill('zayed_october', 'الشيخ زايد و 6 أكتوبر'),
      _buildFilterPill('central_cairo', 'المعادي ومصر الجديدة ووسط البلد'),
      _buildFilterPill('coastal', 'الإسكندرية والساحل الشمالي'),
    ];
  }

  Widget _buildFilterPill(String id, String label) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: TashilFilterChip(
        label: label,
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = id),
      ),
    );
  }
}
