import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_builder_wizard_dialog.dart';
import 'package:tashil_real_estate/features/image_moderation/widgets/ai_image_moderator_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/monthly_payment_schedule_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/publish_listing_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/marketplace_visitor_preview_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/property_share_dialog.dart';
import 'package:tashil_real_estate/features/public_marketplace/repositories/property_repository.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/carousel/tashil_carousels.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/lists/tashil_lists.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';

enum PropertyQuickAction {
  onboard,
  valuation,
  lease,
}

/// Style definition for Property Type Chips (Apartment, Villa, Chalet, Duplex, Studio)
/// with high contrast and light/dark mode derivations.
class _PropertyTypeBadgeStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String label;
  final IconData icon;

  const _PropertyTypeBadgeStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.label,
    required this.icon,
  });
}

/// Helper function to derive high-contrast, single-hue color palettes, labels, and M3 icons per property type.
_PropertyTypeBadgeStyle _getPropertyTypeBadgeStyle(
  String propertyTypeCode,
  String unitNumber,
  AppLocalizations loc,
  bool isDark,
) {
  final lowerType = propertyTypeCode.trim().toLowerCase();
  final lowerUnit = unitNumber.trim().toLowerCase();

  final isApartment = lowerType.contains('apart') ||
      lowerType.contains('شقة') ||
      lowerUnit.contains('شقة');
  final isVilla = lowerType.contains('villa') ||
      lowerType.contains('فيلا') ||
      lowerUnit.contains('فيلا');
  final isStudio = lowerType.contains('studio') ||
      lowerType.contains('ستوديو') ||
      lowerUnit.contains('ستوديو');
  final isOffice = lowerType.contains('office') ||
      lowerType.contains('مكتب') ||
      lowerType.contains('اداري') ||
      lowerType.contains('إداري');
  final isChalet = lowerType.contains('chale') ||
      lowerType.contains('شاليه') ||
      lowerUnit.contains('شاليه');
  final isDuplex = lowerType.contains('dup') ||
      lowerType.contains('دوبلكس') ||
      lowerType.contains('pent') ||
      lowerType.contains('بنتهاوس') ||
      lowerType.contains('town') ||
      lowerUnit.contains('دوبلكس');

  if (isApartment) {
    return _PropertyTypeBadgeStyle(
      backgroundColor: isDark
          ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
          : const Color(0xFFEFF6FF),
      borderColor: isDark
          ? const Color(0xFF3B82F6).withValues(alpha: 0.70)
          : const Color(0xFFBFDBFE),
      textColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
      label: loc.tr('propTypeApartment'),
      icon: Icons.apartment_rounded,
    );
  }

  if (isVilla) {
    return _PropertyTypeBadgeStyle(
      backgroundColor: isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.35)
          : const Color(0xFFECFDF5),
      borderColor: isDark
          ? const Color(0xFF10B981).withValues(alpha: 0.70)
          : const Color(0xFFA7F3D0),
      textColor: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
      label: loc.tr('propTypeVilla'),
      icon: Icons.villa_rounded,
    );
  }

  if (isStudio) {
    return _PropertyTypeBadgeStyle(
      backgroundColor: isDark
          ? const Color(0xFF4C1D95).withValues(alpha: 0.35)
          : const Color(0xFFF5F3FF),
      borderColor: isDark
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.70)
          : const Color(0xFFDDD6FE),
      textColor: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
      label: loc.tr('propTypeStudio'),
      icon: Icons.single_bed_rounded,
    );
  }

  if (isOffice) {
    return _PropertyTypeBadgeStyle(
      backgroundColor: isDark
          ? const Color(0xFF134E4A).withValues(alpha: 0.35)
          : const Color(0xFFF0FDFA),
      borderColor: isDark
          ? const Color(0xFF14B8A6).withValues(alpha: 0.70)
          : const Color(0xFF99F6E4),
      textColor: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
      label: loc.tr('propTypeOffice'),
      icon: Icons.business_center_rounded,
    );
  }

  if (isChalet) {
    return _PropertyTypeBadgeStyle(
      backgroundColor: isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.35)
          : const Color(0xFFFFFBEB),
      borderColor: isDark
          ? const Color(0xFFF59E0B).withValues(alpha: 0.70)
          : const Color(0xFFFDE68A),
      textColor: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
      label: loc.tr('propTypeChalet'),
      icon: Icons.beach_access_rounded,
    );
  }

  if (isDuplex) {
    return _PropertyTypeBadgeStyle(
      backgroundColor: isDark
          ? const Color(0xFF312E81).withValues(alpha: 0.35)
          : const Color(0xFFEEF2FF),
      borderColor: isDark
          ? const Color(0xFF6366F1).withValues(alpha: 0.70)
          : const Color(0xFFC7D2FE),
      textColor: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
      label: loc.tr('propTypeDuplex'),
      icon: Icons.holiday_village_rounded,
    );
  }

  // Default / Apartment fallback
  return _PropertyTypeBadgeStyle(
    backgroundColor: isDark
        ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
        : const Color(0xFFEFF6FF),
    borderColor: isDark
        ? const Color(0xFF3B82F6).withValues(alpha: 0.70)
        : const Color(0xFFBFDBFE),
    textColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
    label: loc.tr('propTypeApartment'),
    icon: Icons.apartment_rounded,
  );
}

/// Official M3 Property Type Chip with semantic icon and high-contrast styling
Widget _buildPropertyTypeChip({
  required ManagedPropertyModel prop,
  required AppLocalizations loc,
  required bool isDark,
  bool showUnitNumber = false,
  bool isFloatingBadge = false,
}) {
  final style = _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark);
  final hasUnit = showUnitNumber && prop.unitNumber.trim().isNotEmpty;

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isFloatingBadge ? 9 : 8,
      vertical: isFloatingBadge ? 4.5 : 3,
    ),
    decoration: BoxDecoration(
      color: style.backgroundColor,
      borderRadius: BorderRadius.circular(isFloatingBadge ? 8 : 7),
      border: Border.all(
        color: style.borderColor,
        width: 1.0,
      ),
      boxShadow: isFloatingBadge
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          style.icon,
          size: isFloatingBadge ? 13.5 : 12.5,
          color: style.textColor,
        ),
        const SizedBox(width: 4.5),
        Text(
          hasUnit ? '${style.label} (${prop.unitNumber.trim()})' : style.label,
          style: TextStyle(
            color: style.textColor,
            fontSize: isFloatingBadge ? 11 : 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.1,
          ),
        ),
      ],
    ),
  );
}

/// Official M3 Stylized Location Badge with tinted squircle container and solid pin
Widget _buildLocationBadge(ColorScheme colorScheme, bool isDark, {bool isSmall = false}) {
  final size = isSmall ? 18.0 : 20.0;
  final iconSize = isSmall ? 11.0 : 12.0;

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.08),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.18),
        width: 0.8,
      ),
    ),
    alignment: Alignment.center,
    child: Icon(
      Icons.location_on_rounded,
      size: iconSize,
      color: colorScheme.primary,
    ),
  );
}

/// Style definition for Property Rental Status Badges (Occupied, Published, Hidden Draft)
/// with high-contrast, single-hue derivations.
class _PropertyStatusBadgeStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final String label;
  final IconData icon;

  const _PropertyStatusBadgeStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.label,
    required this.icon,
  });
}

/// Helper function to derive high-contrast, single-hue rental status badge styles.
_PropertyStatusBadgeStyle _getPropertyStatusBadgeStyle(
  ManagedPropertyModel prop,
  AppLocalizations loc,
  bool isDark,
) {
  if (prop.isOccupied) {
    return _PropertyStatusBadgeStyle(
      backgroundColor: isDark ? const Color(0xFF172B4D) : const Color(0xFFE8F0FE),
      borderColor: isDark ? const Color(0xFF4285F4).withValues(alpha: 0.70) : const Color(0xFF8AB4F8),
      foregroundColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF174EA6),
      label: '${loc.tr('statusOccupied')} (${prop.tenantName ?? ""})',
      icon: Icons.vpn_key_rounded,
    );
  }

  if (prop.isPublished) {
    return _PropertyStatusBadgeStyle(
      backgroundColor: isDark ? const Color(0xFF0D3322) : const Color(0xFFE6F4EA),
      borderColor: isDark ? const Color(0xFF34A853).withValues(alpha: 0.70) : const Color(0xFF81C995),
      foregroundColor: isDark ? const Color(0xFF81C995) : const Color(0xFF137333),
      label: loc.tr('statusPublishedOnMarketplace'),
      icon: Icons.storefront_rounded,
    );
  }

  // Hidden draft
  return _PropertyStatusBadgeStyle(
    backgroundColor: isDark ? const Color(0xFF282A2D) : const Color(0xFFF1F3F4),
    borderColor: isDark ? const Color(0xFF5F6368) : const Color(0xFFBDC1C6),
    foregroundColor: isDark ? const Color(0xFFE8EAED) : const Color(0xFF3C4043),
    label: loc.tr('statusHiddenDraft'),
    icon: Icons.visibility_off_rounded,
  );
}

/// Official Material Design 3 (M3) Owner Properties View for Tashil Real Estate.
///
/// Fully adheres to:
/// - Official Google Material Design 3 Guidelines (M3 Expressive Button Groups, Tonal Surfaces, Motion, Dividers)
/// - Strict Google Material Icons only standard (no third-party glyphs or emojis in buttons)
/// - Single seed color scheme derivation with M3HoverColorScheme (Terracotta, Olive, Royal Blue, Navy, Teal)
/// - Responsive layout for Desktop, Tablet, and Mobile
/// - Smooth M3 animated transitions between Table View and Cards View
/// - Trilingual parity (Arabic RTL, English LTR, Hindi LTR) with zero language mixing.
class OwnerPropertiesView extends StatefulWidget {
  const OwnerPropertiesView({super.key});

  @override
  State<OwnerPropertiesView> createState() => _OwnerPropertiesViewState();
}

class _OwnerPropertiesViewState extends State<OwnerPropertiesView> {
  PropertyQuickAction _selectedAction = PropertyQuickAction.onboard;
  bool _isTableView = true;

  void _handleQuickAction(PropertyQuickAction action) {
    setState(() {
      _selectedAction = action;
    });

    switch (action) {
      case PropertyQuickAction.onboard:
        context.push('/fast-onboarding');
        break;
      case PropertyQuickAction.valuation:
        SmartValuationDialog.show(context);
        break;
      case PropertyQuickAction.lease:
        LeaseBuilderWizardDialog.show(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final isMobileOrTablet = isMobile || isTablet;
    final isUAE = CountryController.isUAE;
    final targetCountry = isUAE ? 'AE' : 'EG';
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    return ValueListenableBuilder<List<ManagedPropertyModel>>(
      valueListenable: PropertyLifecycleService().propertiesNotifier,
      builder: (context, allProperties, _) {
        final properties = allProperties
            .where((p) => p.countryCode == targetCountry)
            .toList();

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Title & Metrics Block
                  _buildHeaderBlock(
                    context,
                    loc: loc,
                    theme: theme,
                    colorScheme: colorScheme,
                    propertiesCount: properties.length,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 18),

                  // 2. Action Tools & View Switcher (Official M3 Connected Button Groups)
                  if (isMobileOrTablet) ...[
                    _buildMobileControlBar(context, loc: loc, colorScheme: colorScheme),
                  ] else ...[
                    _buildDesktopControlBar(context, loc: loc, colorScheme: colorScheme),
                  ],
                  const SizedBox(height: 20),

                  // 3. Properties Showcase with Smooth M3 Animated Transitions
                  AnimatedSwitcher(
                    duration: TashilMotionDuration.medium2,
                    switchInCurve: TashilMotionEasing.emphasizedDecelerate,
                    switchOutCurve: TashilMotionEasing.emphasizedAccelerate,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.03),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<bool>(_isTableView),
                      child: _isTableView
                          ? _buildPropertiesTableView(
                              context,
                              loc: loc,
                              lang: lang,
                              currency: currency,
                              properties: properties,
                              isMobile: isMobile,
                              colorScheme: colorScheme,
                            )
                          : _buildPropertiesGridView(
                              context,
                              loc: loc,
                              lang: lang,
                              currency: currency,
                              properties: properties,
                              isMobile: isMobile,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 1. Header Title Block with Localized Count Pill
  Widget _buildHeaderBlock(
    BuildContext context, {
    required AppLocalizations loc,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int propertiesCount,
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('myProperties'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.tr('ownerPropertiesSubtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$propertiesCount ${loc.tr('totalProperties')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 2. Desktop Control Bar: Quick Actions (Start) + View Switcher (End)
  Widget _buildDesktopControlBar(
    BuildContext context, {
    required AppLocalizations loc,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Start: Primary Hero Action (رفع العقار) + Secondary Tools Connected Group + Image Moderator Icon Button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🚀 Hero Primary Action Button: رفع العقار
            TashilButton(
              height: 40.0,
              onPressed: () => context.push('/fast-onboarding'),
              icon: Icons.rocket_launch_rounded,
              label: loc.tr('fastPropertyOnboardingShort'),
            ),
            const SizedBox(width: 12),
            TashilConnectedButtonGroup<PropertyQuickAction>(
              height: 40.0,
              isTonal: true,
              selectedValue: _selectedAction,
              onSelectionChanged: (action) => _handleQuickAction(action),
              segments: [
                TashilConnectedButtonSegment<PropertyQuickAction>(
                  value: PropertyQuickAction.valuation,
                  label: loc.tr('aiValuationShort'),
                  icon: Icons.auto_awesome_rounded,
                ),
                TashilConnectedButtonSegment<PropertyQuickAction>(
                  value: PropertyQuickAction.lease,
                  label: loc.tr('createNewLeaseShort'),
                  icon: Icons.description_outlined,
                ),
              ],
            ),
            const SizedBox(width: 8),
            TashilIconButton.tonal(
              onPressed: () => AiImageModeratorDialog.show(context),
              icon: Icons.shield_outlined,
              size: 40,
              iconSize: 20,
              tooltip: loc.tr('aiImageModeratorTitle'),
            ),
          ],
        ),

        // End: View Mode Switcher (Cards vs Table)
        TashilConnectedButtonGroup<bool>(
          height: 40.0,
          selectedValue: _isTableView,
          onSelectionChanged: (val) {
            if (_isTableView != val) {
              setState(() {
                _isTableView = val;
              });
            }
          },
          segments: [
            TashilConnectedButtonSegment<bool>(
              value: false,
              label: loc.tr('cardsView'),
              icon: Icons.grid_view_rounded,
            ),
            TashilConnectedButtonSegment<bool>(
              value: true,
              label: loc.tr('tableView'),
              icon: Icons.table_rows_rounded,
            ),
          ],
        ),
      ],
    );
  }

  /// Mobile/Tablet Control Bar: Hero Primary CTA + Horizontally Scrollable Tools + Full-Width View Toggle
  Widget _buildMobileControlBar(
    BuildContext context, {
    required AppLocalizations loc,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Primary Action Button for Mobile: رفع العقار
        TashilButton(
          height: 44.0,
          onPressed: () => context.push('/fast-onboarding'),
          icon: Icons.rocket_launch_rounded,
          label: loc.tr('fastPropertyOnboardingShort'),
        ),
        const SizedBox(height: 12),

        // 2. Secondary Tools
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TashilConnectedButtonGroup<PropertyQuickAction>(
                height: 38.0,
                isTonal: true,
                selectedValue: _selectedAction,
                onSelectionChanged: (action) => _handleQuickAction(action),
                segments: [
                  TashilConnectedButtonSegment<PropertyQuickAction>(
                    value: PropertyQuickAction.valuation,
                    label: loc.tr('aiValuationShort'),
                    icon: Icons.auto_awesome_rounded,
                  ),
                  TashilConnectedButtonSegment<PropertyQuickAction>(
                    value: PropertyQuickAction.lease,
                    label: loc.tr('createNewLeaseShort'),
                    icon: Icons.description_outlined,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                onPressed: () => AiImageModeratorDialog.show(context),
                icon: Icons.shield_outlined,
                size: 38,
                iconSize: 18,
                tooltip: loc.tr('aiImageModeratorTitle'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TashilConnectedButtonGroup<bool>(
          height: 38.0,
          isFullWidth: true,
          selectedValue: _isTableView,
          onSelectionChanged: (val) {
            setState(() => _isTableView = val);
          },
          segments: [
            TashilConnectedButtonSegment<bool>(
              value: false,
              label: loc.tr('cardsView'),
              icon: Icons.grid_view_rounded,
            ),
            TashilConnectedButtonSegment<bool>(
              value: true,
              label: loc.tr('tableView'),
              icon: Icons.table_rows_rounded,
            ),
          ],
        ),
      ],
    );
  }

  /// Properties Grid (Cards View)
  Widget _buildPropertiesGridView(
    BuildContext context, {
    required AppLocalizations loc,
    required String lang,
    required String currency,
    required List<ManagedPropertyModel> properties,
    required bool isMobile,
  }) {
    if (properties.isEmpty) {
      return _buildEmptyState(context, loc: loc);
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = isMobile || screenWidth < 900;
    final crossAxisCount = isNarrow ? 1 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isNarrow ? 1.35 : 1.55,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final p = properties[index];
        final title = p.getTitle(lang);
        final location = p.getLocation(lang);

        return TashilStaggeredEntrance(
          index: index,
          child: _buildCompactPropertyCard(
            context,
            loc: loc,
            lang: lang,
            currency: currency,
            prop: p,
            title: title,
            location: location,
          ),
        );
      },
    );
  }

  /// Compact Property Card
  Widget _buildCompactPropertyCard(
    BuildContext context, {
    required AppLocalizations loc,
    required String lang,
    required String currency,
    required ManagedPropertyModel prop,
    required String title,
    required String location,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final statusStyle = _getPropertyStatusBadgeStyle(prop, loc, isDark);

    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header with Badges & M3 Carousel
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                TashilCarousel.hero(
                  imageUrls: prop.imageUrls.isNotEmpty ? prop.imageUrls : [prop.image],
                  height: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  showIndicator: true,
                  showArrows: true,
                ),
                // Status Badge & 3-Dots Share Button
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusStyle.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusStyle.borderColor,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusStyle.icon, color: statusStyle.foregroundColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              statusStyle.label,
                              style: TextStyle(
                                color: statusStyle.foregroundColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => PropertyShareDialog.show(context, prop),
                            child: Tooltip(
                              message: loc.tr('shareAndOptions'),
                              child: Icon(
                                Icons.more_vert_rounded,
                                size: 17,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Property Type & Unit Number Badge
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: _buildPropertyTypeChip(
                    prop: prop,
                    loc: loc,
                    isDark: isDark,
                    showUnitNumber: true,
                    isFloatingBadge: true,
                  ),
                ),
              ],
            ),
          ),

          // Pinned Action Divider
          TashilDivider.cardAction(),

          // Content & Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Title (Start) & Price (End)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${CurrencyFormatter.formatAmount(prop.pricePerMonth, langCode: lang)} $currency',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '/ ${loc.tr('perMonth')}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 2: Location & Revenue (Start) + Action Icons Group (End)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _buildLocationBadge(colorScheme, isDark, isSmall: true),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  prop.buildingName.trim().isNotEmpty
                                      ? '$location • ${prop.buildingName.trim()}'
                                      : location,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (prop.isOccupied) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 12,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${loc.tr('collectedTotal')}: ${CurrencyFormatter.formatAmount(prop.totalCollectedRevenue, langCode: lang)} $currency',
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCardActionGroup(
                      context,
                      prop: prop,
                      loc: loc,
                      colorScheme: colorScheme,
                      isMobileOrTablet: ResponsiveLayout.isMobile(context) || ResponsiveLayout.isTablet(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Responsive Action Button Group for Property Cards
  Widget _buildCardActionGroup(
    BuildContext context, {
    required ManagedPropertyModel prop,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required bool isMobileOrTablet,
  }) {
    final showLabel = !isMobileOrTablet && MediaQuery.sizeOf(context).width >= 1500;

    return Container(
      height: 33,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Segment 1 (Primary Action)
          _buildActionSegment(
            icon: prop.isOccupied ? Icons.calendar_month_rounded : Icons.vpn_key_rounded,
            label: showLabel ? (prop.isOccupied ? loc.tr('paymentScheduleShort') : loc.tr('markAsRentedBtn')) : null,
            tooltip: prop.isOccupied ? loc.tr('paymentScheduleShort') : loc.tr('markAsRentedBtn'),
            isPrimary: true,
            colorScheme: colorScheme,
            onTap: () {
              if (prop.isOccupied) {
                MonthlyPaymentScheduleDialog.show(context, prop);
              } else {
                PublishListingDialog.show(context, prop, initialRentMode: true);
              }
            },
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          // Segment 2 (Secondary Action)
          _buildActionSegment(
            icon: prop.isOccupied ? Icons.tune_rounded : Icons.edit_outlined,
            label: showLabel ? (prop.isOccupied ? loc.tr('manageListingShort') : loc.tr('editListingShort')) : null,
            tooltip: prop.isOccupied ? loc.tr('manageListingShort') : loc.tr('editListingShort'),
            isPrimary: false,
            colorScheme: colorScheme,
            onTap: () {
              if (prop.isOccupied) {
                PublishListingDialog.show(context, prop);
              } else {
                context.push(
                  '/fast-onboarding',
                  extra: {
                    'initialDraft': prop.toDraft(),
                    'existingPropertyId': prop.id,
                  },
                );
              }
            },
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          // Segment 3 (Tertiary Action)
          _buildActionSegment(
            icon: prop.isOccupied ? Icons.edit_outlined : Icons.visibility_outlined,
            label: showLabel ? (prop.isOccupied ? loc.tr('editListingShort') : loc.tr('previewVisitorShort')) : null,
            tooltip: prop.isOccupied ? loc.tr('editListingShort') : loc.tr('previewVisitorShort'),
            isPrimary: false,
            colorScheme: colorScheme,
            onTap: () {
              if (prop.isOccupied) {
                context.push(
                  '/fast-onboarding',
                  extra: {
                    'initialDraft': prop.toDraft(),
                    'existingPropertyId': prop.id,
                  },
                );
              } else {
                final repoProp = PropertyRepository().getPropertyById(prop.id) ?? prop.toPropertyItem();
                MarketplaceVisitorPreviewDialog.show(context, repoProp);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionSegment({
    required IconData icon,
    String? label,
    required String tooltip,
    required bool isPrimary,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    final bg = isPrimary
        ? colorScheme.primaryContainer.withValues(alpha: 0.65)
        : Colors.transparent;
    final fg = isPrimary
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        hoverColor: colorScheme.primaryHoverStateLayer,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label != null ? 10 : 8,
              vertical: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: fg),
                if (label != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact Table View (M3 Reorderable Table)
  Widget _buildPropertiesTableView(
    BuildContext context, {
    required AppLocalizations loc,
    required String lang,
    required String currency,
    required List<ManagedPropertyModel> properties,
    required bool isMobile,
    required ColorScheme colorScheme,
  }) {
    if (properties.isEmpty) {
      return _buildEmptyState(context, loc: loc);
    }

    final isUAE = CountryController.isUAE;
    final targetCountry = isUAE ? 'AE' : 'EG';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. M3 Surface Reorder Drag & Drop Hint Banner
        _buildReorderHintBanner(context, loc: loc, colorScheme: colorScheme, isMobile: isMobile),

        // 2. M3 Outlined Table Container
        TashilCard.outlined(
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table Column Header (Desktop only)
              if (!isMobile)
                _buildTableHeader(context, loc: loc, colorScheme: colorScheme),

              // Reorderable Data Rows
              TashilReorderableList<ManagedPropertyModel>(
                items: properties,
                buildDefaultDragHandles: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                showDividers: false,
                onReorder: (oldIndex, newIndex) {
                  PropertyLifecycleService().reorderProperties(oldIndex, newIndex, targetCountry);
                  TashilSnackBar.showSuccess(
                    context: context,
                    message: loc.tr('reorderSuccessHint'),
                  );
                },
                itemBuilder: (context, index, prop) {
                  final title = prop.getTitle(lang);
                  final location = prop.getLocation(lang);
                  final isLast = index == properties.length - 1;
                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  final statusStyle = _getPropertyStatusBadgeStyle(prop, loc, isDark);
                  final typeStyle = _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark);

                  if (isMobile) {
                    return _buildMobileTableRow(
                      context,
                      key: ValueKey('prop-mobile-${prop.id}'),
                      index: index,
                      prop: prop,
                      title: title,
                      location: location,
                      statusBg: statusStyle.backgroundColor,
                      statusFg: statusStyle.foregroundColor,
                      statusBorder: statusStyle.borderColor,
                      statusLabel: statusStyle.label,
                      statusIcon: statusStyle.icon,
                      typeStyle: typeStyle,
                      currency: currency,
                      lang: lang,
                      loc: loc,
                      colorScheme: colorScheme,
                      isLast: isLast,
                    );
                  }

                  // Desktop Row with M3 Connected Action Button Group
                  return _buildDesktopTableRow(
                    context,
                    key: ValueKey('prop-desktop-${prop.id}'),
                    index: index,
                    prop: prop,
                    title: title,
                    location: location,
                    statusBg: statusStyle.backgroundColor,
                    statusFg: statusStyle.foregroundColor,
                    statusBorder: statusStyle.borderColor,
                    statusLabel: statusStyle.label,
                    statusIcon: statusStyle.icon,
                    typeStyle: typeStyle,
                    currency: currency,
                    lang: lang,
                    loc: loc,
                    colorScheme: colorScheme,
                    isLast: isLast,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// M3 Table Column Header (Desktop)
  Widget _buildTableHeader(
    BuildContext context, {
    required AppLocalizations loc,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 44), // drag handle width (36) + spacing (8)
              Expanded(
                flex: 5,
                child: Text(
                  loc.tr('tableHeaderProperty'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 180,
                child: Text(
                  loc.tr('tableHeaderStatus'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 130,
                child: Text(
                  loc.tr('tableHeaderPrice'),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 166,
                child: Text(
                  loc.tr('tableHeaderActions'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        TashilDivider.fullWidth(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  /// Desktop Table Row with M3 Connected Action Button Group
  Widget _buildDesktopTableRow(
    BuildContext context, {
    Key? key,
    required int index,
    required ManagedPropertyModel prop,
    required String title,
    required String location,
    required Color statusBg,
    required Color statusFg,
    Color? statusBorder,
    required String statusLabel,
    required IconData statusIcon,
    _PropertyTypeBadgeStyle? typeStyle,
    required String currency,
    required String lang,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: key,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: () {
          if (prop.isOccupied) {
            MonthlyPaymentScheduleDialog.show(context, prop);
          } else {
            PublishListingDialog.show(context, prop);
          }
        },
        hoverColor: colorScheme.primaryHoverStateLayer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. Drag Handle
              TashilReorderHandle(
                index: index,
                tooltip: loc.tr('reorderListTooltip'),
              ),
              const SizedBox(width: 8),

              // 2. Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  prop.image,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54,
                    height: 54,
                    color: colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.apartment_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // 3. Property Info (Title, Property Type Chip, Location)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (prop.unitNumber.trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (typeStyle ?? _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark)).backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (typeStyle ?? _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark)).borderColor,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              prop.unitNumber.trim(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (typeStyle ?? _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark)).textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildPropertyTypeChip(prop: prop, loc: loc, isDark: isDark),
                        const SizedBox(width: 10),
                        _buildLocationBadge(colorScheme, isDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            prop.buildingName.trim().isNotEmpty
                                ? '$location • ${prop.buildingName.trim()}'
                                : location,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // 4. Status Badge
              SizedBox(
                width: 180,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusBorder ?? colorScheme.outlineVariant.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusFg, size: 12),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusFg,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // 5. Monthly Price
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${CurrencyFormatter.formatAmount(prop.pricePerMonth, langCode: lang)} $currency',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '/ ${loc.tr('perMonth')}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // 6. Connected Action Button Group
              SizedBox(
                width: 170,
                child: Center(
                  child: _buildTableRowActionGroup(
                    context,
                    prop: prop,
                    loc: loc,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  /// Official M3 Connected Action Button Group for Table Rows
  Widget _buildTableRowActionGroup(
    BuildContext context, {
    required ManagedPropertyModel prop,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
  }) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Primary Action Segment (Colored/Tonal container)
          _buildActionSegmentItem(
            icon: prop.isOccupied ? Icons.calendar_month_rounded : Icons.vpn_key_rounded,
            tooltip: prop.isOccupied ? loc.tr('paymentScheduleShort') : loc.tr('markAsRentedBtn'),
            backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.65),
            foregroundColor: colorScheme.onPrimaryContainer,
            onTap: () {
              if (prop.isOccupied) {
                MonthlyPaymentScheduleDialog.show(context, prop);
              } else {
                PublishListingDialog.show(context, prop, initialRentMode: true);
              }
            },
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          // 2. Secondary Action Segment (Tune if occupied, View if unoccupied)
          _buildActionSegmentItem(
            icon: prop.isOccupied ? Icons.tune_rounded : Icons.visibility_outlined,
            tooltip: prop.isOccupied ? loc.tr('manageListingShort') : loc.tr('previewVisitorShort'),
            foregroundColor: colorScheme.onSurface,
            onTap: () {
              if (prop.isOccupied) {
                PublishListingDialog.show(context, prop);
              } else {
                final repoProp = PropertyRepository().getPropertyById(prop.id) ?? prop.toPropertyItem();
                MarketplaceVisitorPreviewDialog.show(context, repoProp);
              }
            },
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          // 3. Edit Action Segment
          _buildActionSegmentItem(
            icon: Icons.edit_outlined,
            tooltip: loc.tr('editListingShort'),
            foregroundColor: colorScheme.onSurface,
            onTap: () => context.push(
              '/fast-onboarding',
              extra: {
                'initialDraft': prop.toDraft(),
                'existingPropertyId': prop.id,
              },
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          // 4. Share & Options Segment
          _buildActionSegmentItem(
            icon: Icons.share_rounded,
            tooltip: loc.tr('shareAndOptions'),
            foregroundColor: colorScheme.onSurface,
            onTap: () => PropertyShareDialog.show(context, prop),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSegmentItem({
    required IconData icon,
    required String tooltip,
    Color? backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.black.withValues(alpha: 0.08),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 36,
            height: 34,
            child: Center(
              child: Icon(
                icon,
                size: 17,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile Table Row with Drag Handle & Compact Action Bar
  Widget _buildMobileTableRow(
    BuildContext context, {
    Key? key,
    required int index,
    required ManagedPropertyModel prop,
    required String title,
    required String location,
    required Color statusBg,
    required Color statusFg,
    Color? statusBorder,
    required String statusLabel,
    required IconData statusIcon,
    _PropertyTypeBadgeStyle? typeStyle,
    required String currency,
    required String lang,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: key,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. Drag Handle
              TashilReorderHandle(
                index: index,
                tooltip: loc.tr('reorderListTooltip'),
              ),
              const SizedBox(width: 4),

              // 2. Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  prop.image,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54,
                    height: 54,
                    color: colorScheme.surfaceContainerHigh,
                    child: Icon(Icons.apartment_rounded, color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (prop.unitNumber.trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (typeStyle ?? _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark)).backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (typeStyle ?? _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark)).borderColor,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              prop.unitNumber.trim(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: (typeStyle ?? _getPropertyTypeBadgeStyle(prop.propertyTypeCode, prop.unitNumber, loc, isDark)).textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildPropertyTypeChip(prop: prop, loc: loc, isDark: isDark),
                        const SizedBox(width: 8),
                        _buildLocationBadge(colorScheme, isDark, isSmall: true),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            prop.buildingName.trim().isNotEmpty
                                ? '$location • ${prop.buildingName.trim()}'
                                : location,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.formatAmount(prop.pricePerMonth, langCode: lang)} $currency / ${loc.tr('perMonth')}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mobile Actions Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusBorder ?? colorScheme.outlineVariant.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusFg, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusFg, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildTableRowActionGroup(
                context,
                prop: prop,
                loc: loc,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// M3 Surface Reorder Drag & Drop Hint Banner
  Widget _buildReorderHintBanner(
    BuildContext context, {
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required bool isMobile,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            size: isMobile ? 18 : 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.tr('reorderableListHint'),
              style: TextStyle(
                fontSize: isMobile ? 12 : 12.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty State Widget
  Widget _buildEmptyState(BuildContext context, {required AppLocalizations loc}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.apartment_rounded,
                size: 48,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.tr('noPropertiesFound'),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
