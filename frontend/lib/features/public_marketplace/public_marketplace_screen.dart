import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import '../../core/localization/country_controller.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/public_header_navbar.dart';
import '../semantic_search/models/semantic_search_result_model.dart';
import '../semantic_search/services/ai_semantic_vector_search_service.dart';
import '../semantic_search/widgets/visual_search_modal.dart';
import 'models/property_item.dart';
import 'repositories/property_repository.dart';
import 'widgets/property_card.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/design_system/sliders/tashil_sliders.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/search/tashil_search.dart';
import 'package:tashil_real_estate/core/design_system/progress/tashil_progress.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

class PublicMarketplaceScreen extends StatefulWidget {
  const PublicMarketplaceScreen({super.key});

  @override
  State<PublicMarketplaceScreen> createState() => _PublicMarketplaceScreenState();
}

class _PublicMarketplaceScreenState extends State<PublicMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCityCode = 'all';
  String _selectedTypeCode = 'all';
  double _maxPrice = 80000;
  String _propertyQuickFilter = 'all'; // 'all' | 'featured' | 'furnished'
  bool get _onlyFurnished => _propertyQuickFilter == 'furnished';
  bool get _onlyFeatured => _propertyQuickFilter == 'featured';

  // Semantic & Vector Search State
  String _activeSearchMode = 'location';
  bool _isSemanticSearchActive = false;
  bool _isSemanticLoading = false;
  List<SemanticSearchResultItem> _semanticResults = [];
  final _semanticService = AiSemanticVectorSearchService();

  final List<String> _typeCodes = ['all', 'apartment', 'villa', 'studio', 'duplex', 'chalet'];

  List<String> _getCityCodes(String countryCode) {
    if (countryCode == 'AE') {
      return ['all', 'dubai', 'abu_dhabi', 'sharjah', 'ajman', 'ras_al_khaimah'];
    }
    return ['all', 'new_cairo', 'sheikh_zayed', 'alexandria', 'maadi', 'north_coast', 'october'];
  }

  @override
  void initState() {
    super.initState();
    _maxPrice = CountryController.isUAE ? 40000 : 80000;
    CountryController.currentCountry.addListener(_onCountryChanged);
  }

  void _onCountryChanged() {
    if (mounted) {
      setState(() {
        _selectedCityCode = 'all';
        _maxPrice = CountryController.isUAE ? 40000 : 80000;
        if (_isSemanticSearchActive && _searchController.text.isNotEmpty) {
          _performSemanticSearch(_searchController.text, CountryController.countryCode);
        }
      });
    }
  }

  @override
  void dispose() {
    CountryController.currentCountry.removeListener(_onCountryChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSemanticSearch(String query, String countryCode) async {
    if (query.trim().isEmpty) {
      setState(() {
        _semanticResults = [];
        _isSemanticLoading = false;
      });
      return;
    }

    setState(() {
      _isSemanticSearchActive = true;
      _isSemanticLoading = true;
    });

    final res = await _semanticService.searchByNaturalLanguage(
      query: query,
      countryCode: countryCode,
    );

    if (mounted) {
      setState(() {
        _isSemanticLoading = false;
        _semanticResults = res;
      });
    }
  }

  List<PropertyItem> _getFilteredProperties(String countryCode) {
    if (_isSemanticSearchActive && _semanticResults.isNotEmpty) {
      return _semanticResults.map((r) => r.property).toList();
    }

    final lang = LocaleController.languageCode;
    final result = PropertyRepository().queryProperties(
      countryCode: countryCode,
      langCode: lang,
      searchQuery: _searchController.text,
      cityCode: _selectedCityCode,
      typeCode: _selectedTypeCode,
      maxPrice: _maxPrice,
      onlyFurnished: _onlyFurnished,
      onlyFeatured: _onlyFeatured,
      page: 1,
      pageSize: 50,
    );
    return result.items;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCityCode = 'all';
      _selectedTypeCode = 'all';
      _maxPrice = CountryController.isUAE ? 40000 : 80000;
      _propertyQuickFilter = 'all';
      _activeSearchMode = 'location';
      _isSemanticSearchActive = false;
      _semanticResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ValueListenableBuilder<String>(
      valueListenable: CountryController.currentCountry,
      builder: (context, currentCountry, child) {
        return ValueListenableBuilder<int>(
          valueListenable: PropertyRepository().updatesNotifier,
          builder: (context, _, __) {
            final filteredList = _getFilteredProperties(currentCountry);

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: const PublicHeaderNavbar(isSubPage: false, currentRoute: '/'),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Section with Search Banner
                _buildHeroBanner(context, loc, currentCountry, isMobile),

                // Content Section (Filters & Grid)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : (isDesktop ? 64 : 32),
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Chips Row
                      _buildQuickFilterChips(context, loc),
                      const SizedBox(height: 24),

                      // Results Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${loc.tr('availableUnits')} (${filteredList.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (_selectedCityCode != 'all' || _selectedTypeCode != 'all' || _searchController.text.isNotEmpty || _propertyQuickFilter != 'all')
                            TashilButton.tonal(
                              label: loc.tr('resetFilters'),
                              icon: Icons.refresh_rounded,
                              height: 38,
                              onPressed: _resetFilters,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Properties Grid
                      _buildPropertiesGrid(context, loc, filteredList),
                      const SizedBox(height: 64),

                      // Agency / Landlord Promo Banner
                      _buildOwnerAgencyBanner(context, loc, isMobile),
                    ],
                  ),
                ),

                // Footer
                _buildFooter(context, loc),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, AppLocalizations loc, String currentCountry, bool isMobile) {
    final isUAE = currentCountry == 'AE';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 64,
        vertical: isMobile ? 32 : 64,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.8), Colors.black),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: colorScheme.secondaryContainer, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      loc.tr('verifiedBadge'),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.go('/fast-onboarding'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rocket_launch_rounded, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        loc.tr('listPropertyBtn'),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isUAE ? loc.tr('heroTitle_ae') : loc.tr('heroTitle_eg'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 22 : 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isUAE ? loc.tr('heroSubtitle_ae') : loc.tr('heroSubtitle_eg'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Single Unified Official Google M3 Expressive Split Search Bar
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: TashilSearchBar(
              controller: _searchController,
              hintText: _isSemanticSearchActive
                  ? loc.tr('aiSearchPlaceholder')
                  : loc.tr('searchPlaceholder'),
              isSemanticActive: _isSemanticSearchActive,
              suggestions: _getSearchSuggestions(currentCountry),
              leadingIcon: _activeSearchMode == 'ai'
                  ? Icons.auto_awesome_rounded
                  : (_activeSearchMode == 'visual'
                      ? Icons.photo_camera_outlined
                      : Icons.search_rounded),
              splitMenuItems: [
                TashilSplitButtonItem<String>(
                  value: 'location',
                  label: loc.tr('searchModeLocation'),
                  subtitle: loc.tr('searchModeLocationDesc'),
                  icon: Icons.location_on_outlined,
                ),
                TashilSplitButtonItem<String>(
                  value: 'ai',
                  label: loc.tr('searchModeAi'),
                  subtitle: loc.tr('searchModeAiDesc'),
                  icon: Icons.auto_awesome_rounded,
                ),
                TashilSplitButtonItem<String>(
                  value: 'visual',
                  label: loc.tr('searchModeVisual'),
                  subtitle: loc.tr('searchModeVisualDesc'),
                  icon: Icons.photo_camera_outlined,
                ),
              ],
              selectedSplitMenuValue: _activeSearchMode,
              onSplitMenuItemSelected: (mode) {
                setState(() {
                  _activeSearchMode = mode;
                  if (mode == 'ai') {
                    _isSemanticSearchActive = true;
                    if (_searchController.text.isNotEmpty) {
                      _performSemanticSearch(_searchController.text, currentCountry);
                    }
                  } else if (mode == 'visual') {
                    VisualSearchModal.show(context, countryCode: currentCountry);
                  } else {
                    _isSemanticSearchActive = false;
                    _semanticResults = [];
                  }
                });
              },
              onChanged: (val) {
                if (_isSemanticSearchActive) {
                  _performSemanticSearch(val, currentCountry);
                } else {
                  setState(() {});
                }
              },
              onSubmitted: (val) {
                if (_isSemanticSearchActive) {
                  _performSemanticSearch(val, currentCountry);
                } else {
                  setState(() {});
                }
              },
              onClear: () {
                _searchController.clear();
                if (_isSemanticSearchActive) {
                  setState(() => _semanticResults = []);
                } else {
                  setState(() {});
                }
              },
              onVisualSearch: () {
                setState(() => _activeSearchMode = 'visual');
                VisualSearchModal.show(context, countryCode: currentCountry);
              },
              onSelectSuggestion: (suggestion) {
                _searchController.text = suggestion;
                if (_isSemanticSearchActive) {
                  _performSemanticSearch(suggestion, currentCountry);
                } else {
                  setState(() {});
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. Dedicated Filter Container (City, Type, Price Slider)
          Container(
            constraints: const BoxConstraints(maxWidth: 880),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 18,
              vertical: isMobile ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isMobile
                ? Column(
                    children: [
                      _buildCityDropdown(loc, currentCountry),
                      const SizedBox(height: 12),
                      _buildTypeDropdown(loc),
                      const SizedBox(height: 12),
                      _buildPriceSlider(loc, currentCountry, colorScheme),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 3, child: _buildCityDropdown(loc, currentCountry)),
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: _buildTypeDropdown(loc)),
                      const SizedBox(width: 14),
                      Expanded(flex: 4, child: _buildPriceSliderCompact(loc, currentCountry, colorScheme)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // 3. Hero Action CTAs (List Property & AI Valuation)
          _buildHeroActions(context, loc, colorScheme, isMobile),
        ],
      ),
    );
  }

  List<String> _getSearchSuggestions(String currentCountry) {
    if (currentCountry == 'EG') {
      return const [
        'شقة للبيع في الشيخ زايد',
        'شقق للإيجار في التجمع الخامس',
        'فيلا مستقلة في المعادي',
        'مكتب إداري في العاصمة الإدارية',
        'شاليه بإطلالة بحرية في الساحل الشمالي',
      ];
    } else {
      return const [
        'Apartment for rent in Dubai Marina',
        'Luxury Villa in Palm Jumeirah',
        'Studio in Downtown Dubai',
        'Commercial office in Business Bay',
        'Townhouse in Sharjah Waterfront',
      ];
    }
  }

  Widget _buildHeroActions(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Center(
      child: TashilButton.elevated(
        label: loc.tr('aiValuationBannerPrompt'),
        icon: Icons.auto_awesome_rounded,
        height: 48.0,
        borderRadius: BorderRadius.circular(24),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 18 : 28,
          vertical: 12,
        ),
        onPressed: () => SmartValuationDialog.show(context),
      ),
    );
  }

  IconData _getCityIcon(String code) {
    switch (code) {
      case 'all':
        return Icons.domain_rounded;
      case 'dubai':
      case 'abu_dhabi':
        return Icons.location_city_rounded;
      case 'sharjah':
      case 'ajman':
      case 'ras_al_khaimah':
        return Icons.apartment_rounded;
      case 'new_cairo':
      case 'october':
      case 'maadi':
        return Icons.location_city_rounded;
      case 'sheikh_zayed':
        return Icons.holiday_village_rounded;
      case 'alexandria':
      case 'north_coast':
        return Icons.beach_access_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  Widget _buildCityDropdown(AppLocalizations loc, String currentCountry) {
    final cityCodes = _getCityCodes(currentCountry);

    // If previously selected city does not belong to new country list, reset to 'all'
    if (!cityCodes.contains(_selectedCityCode)) {
      _selectedCityCode = 'all';
    }

    final items = <TashilDropdownMenuItem<String>>[];
    for (int i = 0; i < cityCodes.length; i++) {
      final code = cityCodes[i];
      if (i == 1) {
        items.add(const TashilDropdownMenuItem.divider(value: 'div_city'));
      }
      items.add(
        TashilDropdownMenuItem<String>(
          value: code,
          label: loc.tr('city_$code'),
          icon: _getCityIcon(code),
          supportingText: code == 'all' ? null : currentCountry,
        ),
      );
    }

    return TashilDropdownMenu<String>(
      key: ValueKey('city_m3_dropdown_${currentCountry}_$_selectedCityCode'),
      value: _selectedCityCode,
      labelText: loc.tr('city'),
      prefixIcon: Icons.location_city_rounded,
      items: items,
      onChanged: (val) {
        if (val != null) setState(() => _selectedCityCode = val);
      },
    );
  }

  IconData _getTypeIcon(String code) {
    switch (code) {
      case 'all':
        return Icons.home_work_outlined;
      case 'apartment':
        return Icons.apartment_rounded;
      case 'villa':
        return Icons.villa_outlined;
      case 'studio':
        return Icons.single_bed_outlined;
      case 'duplex':
        return Icons.layers_outlined;
      case 'chalet':
        return Icons.beach_access_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  Widget _buildTypeDropdown(AppLocalizations loc) {
    final items = <TashilDropdownMenuItem<String>>[];
    for (int i = 0; i < _typeCodes.length; i++) {
      final code = _typeCodes[i];
      if (i == 1) {
        items.add(const TashilDropdownMenuItem.divider(value: 'div_type'));
      }
      items.add(
        TashilDropdownMenuItem<String>(
          value: code,
          label: loc.tr('type_$code'),
          icon: _getTypeIcon(code),
        ),
      );
    }

    return TashilDropdownMenu<String>(
      key: ValueKey('type_m3_dropdown_$_selectedTypeCode'),
      value: _selectedTypeCode,
      labelText: loc.tr('propertyType'),
      prefixIcon: Icons.home_work_outlined,
      items: items,
      onChanged: (val) {
        if (val != null) setState(() => _selectedTypeCode = val);
      },
    );
  }

  Widget _buildPriceSlider(AppLocalizations loc, String currentCountry, ColorScheme colorScheme) {
    final isUAE = currentCountry == 'AE';
    final maxLimit = isUAE ? 50000.0 : 150000.0;
    final minLimit = isUAE ? 3000.0 : 5000.0;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(loc.tr('maxRent'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Flexible(
              child: Text(
                '${CurrencyFormatter.formatAmount(_maxPrice, langCode: lang)} $currency / ${loc.tr('perMonth')}',
                style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TashilSlider(
          value: _maxPrice.clamp(minLimit, maxLimit),
          min: minLimit,
          max: maxLimit,
          divisions: isUAE ? 47 : 29,
          handleType: TashilSliderHandleType.verticalBar,
          trackHeight: 16.0,
          gap: 2.0,
          showDivisionTicks: false,
          valueLabelFormatter: (val) =>
              '${CurrencyFormatter.formatAmount(val, langCode: lang)} $currency',
          onChanged: (val) => setState(() => _maxPrice = val),
        ),
      ],
    );
  }

  Widget _buildPriceSliderCompact(AppLocalizations loc, String currentCountry, ColorScheme colorScheme) {
    final isUAE = currentCountry == 'AE';
    final maxLimit = isUAE ? 50000.0 : 150000.0;
    final minLimit = isUAE ? 3000.0 : 5000.0;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    return Container(
      height: 52.0,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.centerStart,
        children: [
          // Floating Notch Label cut into the top border line (exact match to City & Type dropdowns)
          PositionedDirectional(
            top: -10,
            start: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: colorScheme.surface,
              child: Text(
                loc.tr('maxRentShort'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Content Row: Leading Money Icon -> Interactive Slider -> Live Price Tag
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 10, end: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TashilSlider(
                    value: _maxPrice.clamp(minLimit, maxLimit),
                    min: minLimit,
                    max: maxLimit,
                    divisions: isUAE ? 47 : 29,
                    handleType: TashilSliderHandleType.verticalBar,
                    trackHeight: 14.0,
                    gap: 2.0,
                    height: 38.0,
                    showDivisionTicks: false,
                    valueLabelFormatter: (val) =>
                        '${CurrencyFormatter.formatAmount(val, langCode: lang)} $currency',
                    onChanged: (val) => setState(() => _maxPrice = val),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${CurrencyFormatter.formatAmount(_maxPrice, langCode: lang)} $currency',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChips(BuildContext context, AppLocalizations loc) {
    return TashilConnectedButtonGroup<String>(
      selectedValue: _propertyQuickFilter,
      onSelectionChanged: (val) {
        setState(() {
          if (_propertyQuickFilter == val && val != 'all') {
            _propertyQuickFilter = 'all';
          } else {
            _propertyQuickFilter = val;
          }
        });
      },
      height: 42.0,
      segments: [
        TashilConnectedButtonSegment<String>(
          value: 'all',
          label: loc.tr('all'),
          icon: Icons.grid_view_rounded,
        ),
        TashilConnectedButtonSegment<String>(
          value: 'featured',
          label: loc.tr('chipFeatured'),
          icon: Icons.star_rounded,
        ),
        TashilConnectedButtonSegment<String>(
          value: 'furnished',
          label: loc.tr('chipFurnished'),
          icon: Icons.chair_rounded,
        ),
      ],
    );
  }

  Widget _buildPropertiesGrid(BuildContext context, AppLocalizations loc, List<PropertyItem> properties) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isSemanticLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              TashilCircularProgressIndicator.standard(
                shape: TashilProgressShape.wavy,
                color: colorScheme.primary,
                showStopIndicator: true,
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr('semanticSearchingProgress'),
                style: TextStyle(fontSize: 14, color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 200,
                child: TashilLinearProgressIndicator.wavy(
                  showStopIndicator: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (properties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                loc.tr('noResultsTitle'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc.tr('noResultsSub'),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TashilButton.tonal(
                label: loc.tr('resetFilters'),
                icon: Icons.refresh_rounded,
                onPressed: _resetFilters,
              ),
            ],
          ),
        ),
      );
    }

    final filterKey = ValueKey('${_selectedTypeCode}_${_selectedCityCode}_${_propertyQuickFilter}_${_maxPrice}_${_isSemanticSearchActive}_${properties.length}');

    return AnimatedSwitcher(
      duration: TashilMotionDuration.medium2,
      switchInCurve: TashilMotionEasing.emphasizedDecelerate,
      switchOutCurve: TashilMotionEasing.emphasizedAccelerate,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: filterKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 720;
            final isTablet = constraints.maxWidth >= 720 && constraints.maxWidth < 1180;
            final isWideDesktop = constraints.maxWidth >= 1550;
            final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : (isWideDesktop ? 4 : 3));

            final itemWidth = (constraints.maxWidth - 8.0 * (crossAxisCount - 1)) / crossAxisCount;
            // Calibrate childAspectRatio precisely to card geometry:
            // header (44) + 16:10 image + content (166) + divider (1) + actions footer (58) + borders (2) + breathing headroom (15) = ~286.0
            final targetHeight = itemWidth * (10 / 16) + (_isSemanticSearchActive ? 318.0 : 286.0);
            final calculatedAspectRatio = (itemWidth / targetHeight).clamp(0.66, 0.80);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: calculatedAspectRatio,
              ),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final semResult = (_isSemanticSearchActive && _semanticResults.length > index)
                    ? _semanticResults[index]
                    : null;
                return TashilStaggeredEntrance(
                  key: ValueKey('stagger_${properties[index].id}_$index'),
                  index: index,
                  child: PropertyCard(
                    property: properties[index],
                    semanticResult: semResult,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOwnerAgencyBanner(BuildContext context, AppLocalizations loc, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.8), Colors.black),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('promoTitle'),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              loc.tr('promoSubtitle'),
              style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(loc.tr('joinPlatform')),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.8), Colors.black),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('promoTitle'),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.tr('promoSubtitle'),
                  style: TextStyle(color: Colors.grey[300], fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: Text(loc.tr('joinPlatform')),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Center(
        child: Text(
          loc.tr('footerCopyright'),
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ),
    );
  }
}
