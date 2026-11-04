import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import 'package:tashil_real_estate/features/smart_valuation/widgets/district_location_picker_dialog.dart';
import '../../core/localization/country_controller.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/public_header_navbar.dart';
import '../semantic_search/models/semantic_search_result_model.dart';
import '../semantic_search/services/ai_semantic_vector_search_service.dart';
import '../semantic_search/widgets/visual_search_modal.dart';
import 'package:tashil_real_estate/core/config/screenshot_hooks.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/widgets/font_picker_dialog.dart';
import 'package:tashil_real_estate/core/theme/tashil_banner_colors.dart';
import 'models/property_item.dart';
import 'repositories/property_repository.dart';
import 'widgets/property_card.dart';
import 'widgets/property_details_dialog.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/design_system/sliders/tashil_sliders.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/search/tashil_search.dart';
import 'package:tashil_real_estate/core/design_system/progress/tashil_progress.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import '../../core/design_system/navigation_bar/tashil_navigation_bar.dart';
import 'package:material_symbols_icons/symbols.dart';

class PublicMarketplaceScreen extends StatefulWidget {
  const PublicMarketplaceScreen({super.key});

  @override
  State<PublicMarketplaceScreen> createState() => _PublicMarketplaceScreenState();
}

class _PublicMarketplaceScreenState extends State<PublicMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _openedHookedListing = false;
  final ScrollController _resultsScroll = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();
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
    final hookedQuery = ScreenshotHooks.searchQuery;
    if (hookedQuery != null) {
      _searchController.text = hookedQuery;
    }
    _maxPrice = CountryController.isUAE ? 40000 : 80000;
    CountryController.currentCountry.addListener(_onCountryChanged);
    if (ScreenshotHooks.details != null) {
      PropertyRepository().updatesNotifier.addListener(_maybeOpenHookedListing);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenHookedListing());
    }
    if (hookedQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSearchResults());
    }
    final sheet = ScreenshotHooks.sheet;
    if (sheet == 'valuation' || sheet == 'district' || sheet == 'settings' || sheet == 'font') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (sheet) {
          case 'valuation':
            SmartValuationDialog.show(context);
          case 'district':
            DistrictLocationPickerDialog.show(
              context,
              countryCode: CountryController.countryCode,
            );
          case 'settings':
            AppSettingsDialog.show(context);
          case 'font':
            FontPickerDialog.show(context);
        }
      });
    }
  }

  void _revealSearchResults() {
    if (!mounted || _searchController.text.trim().isEmpty) return;
    if (MediaQuery.sizeOf(context).width >= 600) return;
    final target = _resultsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      alignment: 0.02,
    );
  }

  void _maybeOpenHookedListing() {
    if (!mounted || _openedHookedListing) return;
    final which = ScreenshotHooks.details;
    if (which == null) return;
    final props = PropertyRepository().getPropertiesByCountry('AE');
    PropertyItem? item;
    if (which == 'permit') {
      for (final property in props) {
        if (!property.isSample &&
            property.cityCode == 'dubai' &&
            property.advertisingPermitNumber.trim().isNotEmpty) {
          item = property;
          break;
        }
      }
    } else if (which == 'sample') {
      for (final property in props) {
        if (property.isSample && property.cityCode == 'dubai') {
          item = property;
          break;
        }
      }
    }
    if (item == null) return;
    _openedHookedListing = true;
    PropertyDetailsDialog.show(context, item);
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
    PropertyRepository().updatesNotifier.removeListener(_maybeOpenHookedListing);
    _resultsScroll.dispose();
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
          builder: (context, _, _) {
            final filteredList = _getFilteredProperties(currentCountry);

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: const PublicHeaderNavbar(isSubPage: false, currentRoute: '/'),
              bottomNavigationBar: isMobile ? _buildMobileBottomBar(context, loc, colorScheme) : null,
              body: RefreshIndicator.adaptive(
                onRefresh: () async {
                  PropertyRepository().updatesNotifier.value++;
                },
                child: SingleChildScrollView(
                controller: _resultsScroll,
                physics: const AlwaysScrollableScrollPhysics(),
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
                        key: _resultsKey,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${loc.tr('availableUnits')} (${filteredList.length})',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_selectedCityCode != 'all' || _selectedTypeCode != 'all' || _searchController.text.isNotEmpty || _propertyQuickFilter != 'all')
                            TashilButton.tonal(
                              label: loc.tr('resetFilters'),
                              icon: Symbols.refresh_rounded,
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
                if (isMobile) const SizedBox(height: 24),
              ],
            ),
          ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildMobileBottomBar(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final isUAE = CountryController.isUAE;

    return TashilNavigationBar(
      destinations: [
        TashilNavigationDestination(
          icon: Symbols.explore_rounded,
          selectedIcon: Symbols.explore_rounded,
          label: loc.tr('navExplore'),
          isSelected: true,
          tooltip: loc.tr('navExplore'),
          onTap: () => context.go('/'),
        ),

        // 2. AI Smart Valuation
        TashilNavigationDestination(
          icon: Symbols.auto_awesome_rounded,
          selectedIcon: Symbols.auto_awesome_rounded,
          label: loc.tr('navValuation'),
          badgeLabel: loc.tr('navBadgeAi'),
          badgeColor: colorScheme.primary,
          isSelected: false,
          tooltip: loc.tr('aiValuationTitle'),
          onTap: () => context.go('/valuation'),
        ),

        // 3. Market Index (Aqarmap / DXB Index)
        TashilNavigationDestination(
          icon: Symbols.analytics_rounded,
          selectedIcon: Symbols.analytics_rounded,
          label: isUAE ? loc.tr('navMarketIndexAe') : loc.tr('navMarketIndex'),
          hasBadgeDot: true,
          isSelected: false,
          tooltip: isUAE ? loc.tr('dxbMarketIndexTitle') : loc.tr('aqarmapIndexTitle'),
          onTap: () => context.go('/market-index'),
        ),

        // 4. Settings
        TashilNavigationDestination(
          icon: Symbols.account_circle_rounded,
          selectedIcon: Symbols.account_circle_rounded,
          label: loc.tr('signIn'),
          isSelected: false,
          tooltip: loc.tr('portalLogin'),
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context, AppLocalizations loc, String currentCountry, bool isMobile) {
    final isUAE = currentCountry == 'AE';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onBanner = TashilBannerColors.foreground(colorScheme);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 64,
        vertical: isMobile ? 16 : 64,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: TashilBannerColors.gradient(colorScheme),
          begin: AlignmentDirectional.topEnd,
          end: AlignmentDirectional.bottomStart,
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
                  color: onBanner.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: onBanner.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.verified_rounded, color: onBanner, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      loc.tr('verifiedBadge'),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(color: onBanner, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.go('/fast-onboarding'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: onBanner.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: onBanner.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.rocket_launch_rounded, color: onBanner, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        loc.tr('listPropertyBtn'),
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: onBanner, fontWeight: FontWeight.bold),
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
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold,
              color: onBanner,
              height: 1.2),
          ),
          if (!isMobile) ...[
            const SizedBox(height: 12),
            Text(
              isUAE ? loc.tr('heroSubtitle_ae') : loc.tr('heroSubtitle_eg'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: TashilBannerColors.muted(colorScheme),
                height: 1.5),
            ),
          ],
          const SizedBox(height: 16),

          // Single Unified Official Google M3 Expressive Split Search Bar
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: TashilSearchBar(
              controller: _searchController,
              hintText: _isSemanticSearchActive
                  ? loc.tr('aiSearchPlaceholder')
                  : loc.tr('searchPlaceholder'),
              isSemanticActive: _isSemanticSearchActive,
              suggestions: _getSearchSuggestions(loc, currentCountry),
              leadingIcon: _activeSearchMode == 'ai'
                  ? Symbols.auto_awesome_rounded
                  : (_activeSearchMode == 'visual'
                      ? Symbols.photo_camera_rounded
                      : Symbols.search_rounded),
              splitMenuItems: isMobile ? null : [
                TashilSplitButtonItem<String>(
                  value: 'location',
                  label: loc.tr('searchModeLocation'),
                  subtitle: loc.tr('searchModeLocationDesc'),
                  icon: Symbols.location_on_rounded,
                ),
                TashilSplitButtonItem<String>(
                  value: 'ai',
                  label: loc.tr('searchModeAi'),
                  subtitle: loc.tr('searchModeAiDesc'),
                  icon: Symbols.auto_awesome_rounded,
                ),
                TashilSplitButtonItem<String>(
                  value: 'visual',
                  label: loc.tr('searchModeVisual'),
                  subtitle: loc.tr('searchModeVisualDesc'),
                  icon: Symbols.photo_camera_rounded,
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
                  _revealSearchResults();
                }
              },
              onSubmitted: (val) {
                if (_isSemanticSearchActive) {
                  _performSemanticSearch(val, currentCountry);
                } else {
                  setState(() {});
                  _revealSearchResults();
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

          // 2. Filters: a sheet on a phone, an inline bar on a wider window.
          if (isMobile)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (sheetContext) => Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      16,
                      0,
                      16,
                      24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCityDropdown(loc, currentCountry),
                        const SizedBox(height: 12),
                        _buildTypeDropdown(loc),
                        const SizedBox(height: 12),
                        _buildPriceSlider(loc, currentCountry, colorScheme),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Symbols.tune_rounded),
              label: Text(loc.tr('filtersLabel')),
            )
          else
          Container(
            constraints: const BoxConstraints(maxWidth: 1120),
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
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
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

  List<String> _getSearchSuggestions(AppLocalizations loc, String currentCountry) {
    if (currentCountry == 'AE') {
      return [
        loc.tr('searchSuggestMarina'),
        loc.tr('searchSuggestPalm'),
        loc.tr('searchSuggestDowntown'),
        loc.tr('searchSuggestBusinessBay'),
        loc.tr('searchSuggestSharjah'),
      ];
    }
    return [
      loc.tr('searchSuggestEg1'),
      loc.tr('searchSuggestEg2'),
      loc.tr('searchSuggestEg3'),
      loc.tr('searchSuggestEg4'),
      loc.tr('searchSuggestEg5'),
    ];
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
        icon: Symbols.auto_awesome_rounded,
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
        return Symbols.domain_rounded;
      case 'dubai':
      case 'abu_dhabi':
        return Symbols.location_city_rounded;
      case 'sharjah':
      case 'ajman':
      case 'ras_al_khaimah':
        return Symbols.apartment_rounded;
      case 'new_cairo':
      case 'october':
      case 'maadi':
        return Symbols.location_city_rounded;
      case 'sheikh_zayed':
        return Symbols.holiday_village_rounded;
      case 'alexandria':
      case 'north_coast':
        return Symbols.beach_access_rounded;
      default:
        return Symbols.location_on_rounded;
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
      prefixIcon: Symbols.location_city_rounded,
      items: items,
      onChanged: (val) {
        if (val != null) setState(() => _selectedCityCode = val);
      },
    );
  }

  IconData _getTypeIcon(String code) {
    switch (code) {
      case 'all':
        return Symbols.home_work_rounded;
      case 'apartment':
        return Symbols.apartment_rounded;
      case 'villa':
        return Symbols.villa_rounded;
      case 'studio':
        return Symbols.single_bed_rounded;
      case 'duplex':
        return Symbols.layers_rounded;
      case 'chalet':
        return Symbols.beach_access_rounded;
      default:
        return Symbols.home_rounded;
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
      prefixIcon: Symbols.home_work_rounded,
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
                Icon(Symbols.payments_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(loc.tr('maxRent'), style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Flexible(
              child: Text(
                '${CurrencyFormatter.formatAmount(_maxPrice, langCode: lang)} $currency / ${loc.tr('perMonth')}',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
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
                style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant),
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
                  Symbols.payments_rounded,
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
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                    color: colorScheme.primary),
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
          icon: Symbols.grid_view_rounded,
        ),
        TashilConnectedButtonSegment<String>(
          value: 'featured',
          label: loc.tr('chipFeatured'),
          icon: Symbols.star_rounded,
        ),
        TashilConnectedButtonSegment<String>(
          value: 'furnished',
          label: loc.tr('chipFurnished'),
          icon: Symbols.chair_rounded,
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
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
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
              Icon(Symbols.search_off_rounded, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                loc.tr('noResultsTitle'),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc.tr('noResultsSub'),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TashilButton.tonal(
                label: loc.tr('resetFilters'),
                icon: Symbols.refresh_rounded,
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

    final onBanner = TashilBannerColors.foreground(colorScheme);
    if (isMobile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: TashilBannerColors.gradient(colorScheme),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('promoTitle'),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: onBanner, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              loc.tr('promoSubtitle'),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: TashilBannerColors.muted(colorScheme), height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Symbols.rocket_launch_rounded, size: 18),
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
          colors: TashilBannerColors.gradient(colorScheme),
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
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(color: onBanner, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.tr('promoSubtitle'),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(color: TashilBannerColors.muted(colorScheme), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Symbols.rocket_launch_rounded, size: 18),
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
          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
