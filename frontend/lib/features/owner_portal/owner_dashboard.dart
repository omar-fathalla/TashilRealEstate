import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'views/owner_overview_view.dart';
import 'views/owner_properties_view.dart';
import 'views/owner_financials_view.dart';
import 'views/owner_maintenance_view.dart';
import 'views/owner_trash_view.dart';
import 'services/property_lifecycle_service.dart';
import 'models/managed_property_model.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';
import 'package:tashil_real_estate/features/lease_builder/services/legal_clauses_service.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/drawer/tashil_navigation_drawer.dart';
import 'package:tashil_real_estate/core/design_system/navigation_rail/tashil_navigation_rail.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';
import 'package:flutter/services.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/features/owner_portal/dialogs/edit_profile_dialog.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  /// Displays the M3 profile details bottom sheet
  static void showProfileDetailsModal(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    _OwnerDashboardState.showProfileDetailsModal(context, loc, colorScheme);
  }

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    UserProfileService().loadProfile();
  }

  void _selectView(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  final List<Widget> _views = const [
    OwnerOverviewView(),
    OwnerPropertiesView(),
    RentCollectionView(),
    LeasesManagementView(),
    OwnerFinancialsView(),
    InvestorDashboardView(),
    OwnerMaintenanceView(),
    OwnerTrashView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, currentCountry, _) {
            final loc = AppLocalizations.of(context);

            return ResponsiveLayout(
              mobileBody: _buildMobileLayout(context, loc),
              desktopBody: _buildDesktopLayout(context, loc),
              tabletBody: _buildMobileLayout(context, loc),
            );
          },
        );
      },
    );
  }

  /// Desktop Layout: Material Design 3 Nested Canvas + Navigation Rail (80dp) / Expanded (260dp)
  Widget _buildDesktopLayout(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TashilScaffoldCanvas(
      header: _buildDesktopTopHeader(context, loc, colorScheme),
      navigationRail: _buildNavigationRail(context, loc, colorScheme),
      body: ValueListenableBuilder<TashilPageTransitionType>(
        valueListenable: MotionPreferenceController.currentTransition,
        builder: (context, transitionType, _) {
          final isRtl = Directionality.of(context) == TextDirection.rtl;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: TashilPageTransitionSwitcher(
                transitionType: transitionType,
                isForward: _selectedIndex >= _previousIndex,
                isRtl: isRtl,
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: _views[_selectedIndex],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Full-Width Persistent Top Header
  Widget _buildDesktopTopHeader(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: colorScheme.surfaceContainerLowest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Start: Brand Identity (Logo & Title) — Independent & Clean
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.apartment_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.tr('appName'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    loc.tr('ownerPortal'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // End: User Quick Controls (Settings & Browse As Guest)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Motion & Transitions Mode Selector Pill
              ValueListenableBuilder<TashilPageTransitionType>(
                valueListenable: MotionPreferenceController.currentTransition,
                builder: (context, activeMotion, _) {
                  return TashilIconButton.tonal(
                    icon: Icons.animation_rounded,
                    size: 38,
                    iconSize: 20,
                    tooltip: loc.tr('m3MotionPreferenceTitle'),
                    onPressed: () => _showMotionSelectorMenu(context, loc, colorScheme),
                  );
                },
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Icons.tune_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('settings'),
                onPressed: () => AppSettingsDialog.show(context),
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Icons.travel_explore_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('browseAsVisitor'),
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Official Material Design 3 Navigation Rail & Expanded Drawer
  Widget _buildNavigationRail(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final isExpanded = !_isSidebarCollapsed;

    return ValueListenableBuilder<List<RentInvoiceModel>>(
      valueListenable: RentCollectionService().invoicesNotifier,
      builder: (context, _, __) {
        return ValueListenableBuilder<List<LeaseContractModel>>(
          valueListenable: LegalClausesService().contractsNotifier,
          builder: (context, _, __) {
            return ValueListenableBuilder<List<ManagedPropertyModel>>(
              valueListenable: PropertyLifecycleService().propertiesNotifier,
              builder: (context, props, _) {
                final targetCountry = CountryController.isUAE ? 'AE' : 'EG';
                final countryProps = props.where((p) => p.countryCode == targetCountry).toList();
                final propertiesCount = countryProps.length;
                final myPropertiesBadge = propertiesCount > 0 ? propertiesCount.toString() : null;

                // Dynamic real contracts count
                final activeContracts = LegalClausesService().getActiveContractsForCountry(targetCountry);
                final contractsCount = activeContracts.length;
                final contractsBadge = contractsCount > 0 ? contractsCount.toString() : null;

                // Dynamic real collections count
                final invoices = RentCollectionService().getInvoicesForCountry(targetCountry);
                final dueInvoicesCount = invoices.where((i) => i.status != 'paid').length;
                final collectionBadge = dueInvoicesCount > 0 ? dueInvoicesCount.toString() : (invoices.isNotEmpty ? invoices.length.toString() : null);

                // Dynamic trash count (invoices + contracts)
                final deletedInvoicesCount = RentCollectionService().getDeletedInvoicesForCountry(targetCountry).length;
                final deletedContractsCount = LegalClausesService().getDeletedContractsForCountry(targetCountry).length;
                final totalTrashCount = deletedInvoicesCount + deletedContractsCount;
                final trashBadge = totalTrashCount > 0 ? totalTrashCount.toString() : null;

                // Maintenance count: 0 for real accounts
                final hasRealProps = countryProps.any((p) => !PropertyLifecycleService.isMockPropertyId(p.id));
                final maintenanceBadge = hasRealProps ? null : '1';

                final currentUser = UserAvatarUtils.safeCurrentUser;
                final profile = UserProfileService().profileNotifier.value;
                final displayName = profile.hasFullName
                    ? profile.fullName
                    : UserAvatarUtils.getDisplayName(currentUser, loc.tr('ownerProfile'));
                final roleSubtitle = loc.tr('ownerRoleTitle');
                final initials = UserAvatarUtils.getInitials(displayName, 'AF');

                return TashilNavigationRail(
                  isExpanded: isExpanded,
                  railWidth: 80.0,
                  expandedWidth: 260.0,
                  onToggleExpanded: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  menuTooltip: isExpanded ? loc.tr('collapseMenu') : loc.tr('expandMenu'),
                  destinations: [
                    TashilRailDestination(
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard_rounded,
                      label: loc.tr('portfolioOverview'),
                      isSelected: _selectedIndex == 0,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(0),
                    ),
                    TashilRailDestination(
                      icon: Icons.apartment_outlined,
                      selectedIcon: Icons.apartment_rounded,
                      label: loc.tr('myProperties'),
                      badgeCount: myPropertiesBadge,
                      isSelected: _selectedIndex == 1,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(1),
                    ),
                    TashilRailDestination(
                      icon: Icons.payments_outlined,
                      selectedIcon: Icons.payments_rounded,
                      label: loc.tr('navCollection'),
                      badgeCount: collectionBadge,
                      isSelected: _selectedIndex == 2,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(2),
                    ),
                    TashilRailDestination(
                      icon: Icons.description_outlined,
                      selectedIcon: Icons.description_rounded,
                      label: loc.tr('navContracts'),
                      badgeCount: contractsBadge,
                      isSelected: _selectedIndex == 3,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(3),
                    ),
                    TashilRailDestination(
                      icon: Icons.account_balance_wallet_outlined,
                      selectedIcon: Icons.account_balance_wallet_rounded,
                      label: loc.tr('financialsAndPayouts'),
                      isSelected: _selectedIndex == 4,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(4),
                    ),
                    TashilRailDestination(
                      icon: Icons.show_chart_outlined,
                      selectedIcon: Icons.show_chart_rounded,
                      label: loc.tr('navAnalytics'),
                      isSelected: _selectedIndex == 5,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(5),
                    ),
                    TashilRailDestination(
                      icon: Icons.build_outlined,
                      selectedIcon: Icons.build_rounded,
                      label: loc.tr('maintenanceTickets'),
                      badgeCount: maintenanceBadge,
                      isSelected: _selectedIndex == 6,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(6),
                    ),
                    TashilRailDestination(
                      icon: Icons.delete_outline_rounded,
                      selectedIcon: Icons.delete_rounded,
                      label: loc.tr('trashAndDeleted'),
                      badgeCount: trashBadge,
                      isSelected: _selectedIndex == 7,
                      isExpanded: isExpanded,
                      onTap: () => _selectView(7),
                    ),
                    TashilRailDestination(
                      icon: Icons.tune_outlined,
                      selectedIcon: Icons.tune_rounded,
                      label: loc.tr('settings'),
                      isSelected: false,
                      isExpanded: isExpanded,
                      trailing: isExpanded
                          ? Icon(
                              Icons.chevron_right_rounded,
                              size: 18.0,
                              color: colorScheme.outlineVariant,
                            )
                          : null,
                      onTap: () => AppSettingsDialog.show(context),
                    ),
                  ],
      footer: isExpanded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TashilDivider.middleInset(height: 16.0),
                TashilDrawerProfileTile(
                  initials: initials,
                  displayName: displayName,
                  roleSubtitle: roleSubtitle,
                  photoUrl: profile.photoUrl,
                  isCollapsed: false,
                  onTap: () => _showOwnerProfileDialog(context, loc, colorScheme),
                ),
              ],
            )
          : Tooltip(
              message: displayName,
              preferBelow: false,
              verticalOffset: 24.0,
              child: InkWell(
                onTap: () => _showOwnerProfileDialog(context, loc, colorScheme),
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: UserAvatarUtils.buildAvatar(
                    context: context,
                    photoUrl: profile.photoUrl,
                    displayName: displayName,
                    fallbackInitials: initials,
                    radius: 18.0,
                  ),
                ),
              ),
            ),
        );
              },
            );
          },
        );
      },
    );
  }

  /// Ahmed Fouad Profile Menu Dialog (Dashboard, Profile, Settings, Security, Logout)
  void _showOwnerProfileDialog(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final currentUser = UserAvatarUtils.safeCurrentUser;
    final profile = UserProfileService().profileNotifier.value;
    final displayName = profile.hasFullName
        ? profile.fullName
        : UserAvatarUtils.getDisplayName(currentUser, loc.tr('ownerProfile'));
    final initials = UserAvatarUtils.getInitials(displayName, 'AF');
    final roleSubtitle = loc.tr('ownerRoleTitle');

    // Portfolio Summary Chips dynamically computed from active managed properties
    final allProperties = PropertyLifecycleService().propertiesNotifier.value;
    final targetCountry = CountryController.isUAE ? 'AE' : 'EG';
    final properties = allProperties.where((p) => p.countryCode == targetCountry).toList();
    final totalUnits = properties.isNotEmpty ? properties.length.toString() : (currentUser != null ? '0' : '5');
    final occupiedUnits = properties.isNotEmpty ? properties.where((p) => p.isOccupied).length.toString() : (currentUser != null ? '0' : '4');
    final vacantUnits = properties.isNotEmpty ? properties.where((p) => !p.isOccupied).length.toString() : (currentUser != null ? '0' : '1');

    TashilTransitions.showM3Dialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Identity Header
                  Row(
                    children: [
                      UserAvatarUtils.buildAvatar(
                        context: context,
                        photoUrl: profile.photoUrl,
                        displayName: displayName,
                        fallbackInitials: initials,
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.5,
                                      color: colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                            Text(
                              roleSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TashilIconButton.close(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Portfolio Summary Chips
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileStat(
                          label: loc.tr('totalUnits'),
                          value: totalUnits,
                          colorScheme: colorScheme,
                        ),
                        Container(width: 1, height: 20, color: colorScheme.outlineVariant),
                        _buildProfileStat(
                          label: loc.tr('occupiedUnits'),
                          value: occupiedUnits,
                          colorScheme: colorScheme,
                        ),
                        Container(width: 1, height: 20, color: colorScheme.outlineVariant),
                        _buildProfileStat(
                          label: loc.tr('vacantUnits'),
                          value: vacantUnits,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 8),

                  // 1. Dashboard Action
                  _buildProfileMenuItem(
                    icon: Icons.dashboard_outlined,
                    title: loc.tr('dashboard'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      _selectView(0);
                    },
                  ),
                  // 2. Profile Details Action
                  _buildProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: loc.tr('ownerProfileMenu'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      showProfileDetailsModal(context, loc, colorScheme);
                    },
                  ),
                  // 3. Settings Action
                  _buildProfileMenuItem(
                    icon: Icons.tune_rounded,
                    title: loc.tr('settings'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      AppSettingsDialog.show(context);
                    },
                  ),
                  // 4. Security Action
                  _buildProfileMenuItem(
                    icon: Icons.security_rounded,
                    title: loc.tr('accountSecurity'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.tr('verifiedOwner')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 6),

                  // 5. Logout Action
                  _buildProfileMenuItem(
                    icon: Icons.logout_rounded,
                    title: loc.tr('logout'),
                    colorScheme: colorScheme,
                    isDestructive: true,
                    onTap: () async {
                      Navigator.of(dialogCtx).pop();
                      await FirebaseAuthService().signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat({
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final itemColor = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 19, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDestructive
                  ? colorScheme.error.withAlpha(120)
                  : colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// Profile Details Sheet
  static void showProfileDetailsModal(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ValueListenableBuilder<UserProfileData>(
          valueListenable: UserProfileService().profileNotifier,
          builder: (context, profile, _) {
            final currentUser = UserAvatarUtils.safeCurrentUser;
            final displayName = profile.hasFullName
                ? profile.fullName
                : UserAvatarUtils.getDisplayName(currentUser, loc.tr('ownerProfile'));
            final initials = UserAvatarUtils.getInitials(displayName, 'AF');
            final roleSubtitle = loc.tr('ownerRoleTitle');
            final email = profile.email.isNotEmpty
                ? profile.email
                : (currentUser?.email ?? 'user@tashil.com');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Header with Title, Edit Button, and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('ownerProfileMenu'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TashilIconButton.tonal(
                            icon: Icons.edit_outlined,
                            tooltip: loc.tr('editProfileTitle'),
                            size: 38,
                            iconSize: 18,
                            onPressed: () {
                              EditProfileDialog.show(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          TashilIconButton.close(
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Identity Card (Right-aligned in Arabic RTL)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatarUtils.buildAvatar(
                      context: context,
                      photoUrl: profile.photoUrl,
                      displayName: displayName,
                      fallbackInitials: initials,
                      radius: 24,
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(roleSubtitle),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            loc.tr('verifiedOwner'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Completeness Progress Indicator (M3 Enhancement)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: profile.completeness == 1.0
                          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: profile.completeness == 1.0
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              loc.tr('profileCompleteness'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${profile.completenessPercent}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: profile.completeness,
                            minHeight: 6,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                        if (profile.completeness < 1.0) ...[
                          const SizedBox(height: 6),
                          Text(
                            loc.tr('completeProfileHint'),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const TashilDivider.middleInset(),
                  const SizedBox(height: 10),

                  // 5. Contact Details Section
                  // STRICT USER INSTRUCTION (Audio 1):
                  // Left-aligned (ناحية الشمال) and formatted Left-to-Right (LTR)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.email_outlined,
                            text: email,
                            colorScheme: colorScheme,
                            onCopy: () => _copyToClipboard(context, email, loc.tr('emailCopied')),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.phone_outlined,
                            text: profile.hasPhone
                                ? profile.phone
                                : loc.tr('addPhoneNumberPrompt'),
                            isPlaceholder: !profile.hasPhone,
                            colorScheme: colorScheme,
                            onTap: profile.hasPhone
                                ? null
                                : () => EditProfileDialog.show(context),
                            onCopy: profile.hasPhone
                                ? () => _copyToClipboard(context, profile.phone, loc.tr('phoneCopied'))
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
    bool isPlaceholder = false,
    VoidCallback? onTap,
    VoidCallback? onCopy,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ?? onCopy,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPlaceholder ? colorScheme.tertiary : colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: isPlaceholder ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isPlaceholder ? FontWeight.w600 : FontWeight.w500,
                  decoration: isPlaceholder ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ] else if (isPlaceholder) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void _copyToClipboard(BuildContext context, String text, String message) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    TashilSnackBar.showSuccess(
      context: context,
      message: message,
    );
  }

  /// Mobile Layout
  Widget _buildMobileLayout(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.apartment_rounded, color: colorScheme.onPrimary, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                loc.tr('appName'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<TashilPageTransitionType>(
            valueListenable: MotionPreferenceController.currentTransition,
            builder: (context, activeMotion, _) {
              return TashilIconButton.tonal(
                icon: Icons.animation_rounded,
                size: 38,
                iconSize: 18,
                tooltip: loc.tr('m3MotionPreferenceTitle'),
                onPressed: () => _showMotionSelectorMenu(context, loc, colorScheme),
              );
            },
          ),
          const SizedBox(width: 4),
          TashilIconButton.tonal(
            icon: Icons.tune_rounded,
            size: 38,
            iconSize: 18,
            tooltip: loc.tr('settings'),
            onPressed: () => AppSettingsDialog.show(context),
          ),
          const SizedBox(width: 4),
          Builder(
            builder: (ctx) => TashilIconButton.tonal(
              icon: Icons.menu_rounded,
              size: 38,
              iconSize: 20,
              tooltip: loc.tr('menu'),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: _buildMobileDrawer(context, loc, colorScheme),
      body: ValueListenableBuilder<TashilPageTransitionType>(
        valueListenable: MotionPreferenceController.currentTransition,
        builder: (context, transitionType, _) {
          final isRtl = Directionality.of(context) == TextDirection.rtl;

          return TashilPageTransitionSwitcher(
            transitionType: transitionType,
            isForward: _selectedIndex >= _previousIndex,
            isRtl: isRtl,
            child: KeyedSubtree(
              key: ValueKey<int>(_selectedIndex),
              child: _views[_selectedIndex],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 6 ? _selectedIndex : 0,
        onDestinationSelected: _selectView,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: loc.tr('navOverview'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.apartment_outlined),
            selectedIcon: const Icon(Icons.apartment_rounded),
            label: loc.tr('navProperties'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments_rounded),
            label: loc.tr('navCollection'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description_rounded),
            label: loc.tr('navContracts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: loc.tr('navFinancials'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.build_outlined),
            selectedIcon: const Icon(Icons.build_rounded),
            label: loc.tr('navMaintenance'),
          ),
        ],
      ),
    );
  }

  /// Official Material Design 3 Mobile Modal Drawer
  Widget _buildMobileDrawer(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return ValueListenableBuilder<List<RentInvoiceModel>>(
      valueListenable: RentCollectionService().invoicesNotifier,
      builder: (context, _, __) {
        return ValueListenableBuilder<List<LeaseContractModel>>(
          valueListenable: LegalClausesService().contractsNotifier,
          builder: (context, _, __) {
            return ValueListenableBuilder<List<ManagedPropertyModel>>(
              valueListenable: PropertyLifecycleService().propertiesNotifier,
              builder: (context, props, _) {
                final targetCountry = CountryController.isUAE ? 'AE' : 'EG';
                final countryProps = props.where((p) => p.countryCode == targetCountry).toList();
                final propertiesCount = countryProps.length;
                final myPropertiesBadge = propertiesCount > 0 ? propertiesCount.toString() : null;

                // Dynamic real contracts count
                final activeContracts = LegalClausesService().getActiveContractsForCountry(targetCountry);
                final contractsCount = activeContracts.length;
                final contractsBadge = contractsCount > 0 ? contractsCount.toString() : null;

                // Dynamic real collections count
                final invoices = RentCollectionService().getInvoicesForCountry(targetCountry);
                final dueInvoicesCount = invoices.where((i) => i.status != 'paid').length;
                final collectionBadge = dueInvoicesCount > 0 ? dueInvoicesCount.toString() : (invoices.isNotEmpty ? invoices.length.toString() : null);

                // Dynamic trash count
                final deletedInvoicesCount = RentCollectionService().getDeletedInvoicesForCountry(targetCountry).length;
                final deletedContractsCount = LegalClausesService().getDeletedContractsForCountry(targetCountry).length;
                final totalTrashCount = deletedInvoicesCount + deletedContractsCount;
                final trashBadge = totalTrashCount > 0 ? totalTrashCount.toString() : null;

                // Maintenance count: 0 for real accounts
                final hasRealProps = countryProps.any((p) => !PropertyLifecycleService.isMockPropertyId(p.id));
                final maintenanceBadge = hasRealProps ? null : '1';

                final currentUser = UserAvatarUtils.safeCurrentUser;
                final displayName = UserAvatarUtils.getDisplayName(currentUser, loc.tr('ownerProfile'));
                final roleSubtitle = loc.tr('ownerRoleTitle');
                final initials = UserAvatarUtils.getInitials(displayName, 'AF');

                return TashilNavigationDrawer.modal(
      expandedWidth: 320.0,
      backgroundColor: colorScheme.surfaceContainerLowest,
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.apartment_rounded, color: colorScheme.onPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('appName'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    loc.tr('ownerPortal'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TashilIconButton.close(
              size: 36,
              iconSize: 18,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      destinations: [
        TashilDrawerDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          label: loc.tr('portfolioOverview'),
          isSelected: _selectedIndex == 0,
          onTap: () {
            Navigator.pop(context);
            _selectView(0);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment_rounded,
          label: loc.tr('myProperties'),
          badgeCount: myPropertiesBadge,
          isSelected: _selectedIndex == 1,
          onTap: () {
            Navigator.pop(context);
            _selectView(1);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
          label: loc.tr('navCollection'),
          badgeCount: collectionBadge,
          isSelected: _selectedIndex == 2,
          onTap: () {
            Navigator.pop(context);
            _selectView(2);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_rounded,
          label: loc.tr('navContracts'),
          badgeCount: contractsBadge,
          isSelected: _selectedIndex == 3,
          onTap: () {
            Navigator.pop(context);
            _selectView(3);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
          label: loc.tr('financialsAndPayouts'),
          isSelected: _selectedIndex == 4,
          onTap: () {
            Navigator.pop(context);
            _selectView(4);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.show_chart_outlined,
          selectedIcon: Icons.show_chart_rounded,
          label: loc.tr('navAnalytics'),
          isSelected: _selectedIndex == 5,
          onTap: () {
            Navigator.pop(context);
            _selectView(5);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.build_outlined,
          selectedIcon: Icons.build_rounded,
          label: loc.tr('maintenanceTickets'),
          badgeCount: maintenanceBadge,
          isSelected: _selectedIndex == 6,
          onTap: () {
            Navigator.pop(context);
            _selectView(6);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.delete_outline_rounded,
          selectedIcon: Icons.delete_rounded,
          label: loc.tr('trashAndDeleted'),
          badgeCount: trashBadge,
          isSelected: _selectedIndex == 7,
          onTap: () {
            Navigator.pop(context);
            _selectView(7);
          },
        ),
        TashilDrawerSectionHeader(
          title: loc.tr('settings'),
        ),
        TashilDrawerDestination(
          icon: Icons.tune_outlined,
          selectedIcon: Icons.tune_rounded,
          label: loc.tr('settings'),
          isSelected: false,
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 18.0,
            color: colorScheme.outlineVariant,
          ),
          onTap: () {
            Navigator.pop(context);
            AppSettingsDialog.show(context);
          },
        ),
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TashilDivider.middleInset(height: 16.0),
          TashilDrawerProfileTile(
            initials: initials,
            displayName: displayName,
            roleSubtitle: roleSubtitle,
            onTap: () {
              Navigator.pop(context);
              _showOwnerProfileDialog(context, loc, colorScheme);
            },
          ),
        ],
      ),
    );
              },
            );
          },
        );
      },
    );
}

  /// Interactive M3 Motion & Transition Style Dialog
  void _showMotionSelectorMenu(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    TashilTransitions.showM3Dialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.animation_rounded,
                                size: 20,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('m3MotionPreferenceTitle'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    loc.tr('m3MotionSubtitle'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: colorScheme.onSurfaceVariant,
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
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<TashilPageTransitionType>(
                    valueListenable: MotionPreferenceController.currentTransition,
                    builder: (context, activeType, _) {
                      return Column(
                        children: [
                          _buildMotionOptionTile(
                            context: context,
                            title: loc.tr('m3MotionFadeThrough'),
                            subtitle: loc.tr('m3MotionFadeThroughTooltip'),
                            icon: Icons.auto_awesome_motion_rounded,
                            isSelected: activeType == TashilPageTransitionType.fadeThrough,
                            colorScheme: colorScheme,
                            onTap: () {
                              MotionPreferenceController.setTransition(TashilPageTransitionType.fadeThrough);
                              Navigator.of(dialogCtx).pop();
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMotionOptionTile(
                            context: context,
                            title: loc.tr('m3MotionSharedAxisX'),
                            subtitle: loc.tr('m3MotionSharedAxisXTooltip'),
                            icon: Icons.swap_horiz_rounded,
                            isSelected: activeType == TashilPageTransitionType.sharedAxisX,
                            colorScheme: colorScheme,
                            onTap: () {
                              MotionPreferenceController.setTransition(TashilPageTransitionType.sharedAxisX);
                              Navigator.of(dialogCtx).pop();
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMotionOptionTile(
                            context: context,
                            title: loc.tr('m3MotionSharedAxisZ'),
                            subtitle: loc.tr('m3MotionSharedAxisZTooltip'),
                            icon: Icons.zoom_in_map_rounded,
                            isSelected: activeType == TashilPageTransitionType.sharedAxisZ,
                            colorScheme: colorScheme,
                            onTap: () {
                              MotionPreferenceController.setTransition(TashilPageTransitionType.sharedAxisZ);
                              Navigator.of(dialogCtx).pop();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TashilButton.tonal(
                      icon: Icons.movie_filter_outlined,
                      label: loc.tr('m3MotionSuiteButton'),
                      height: 40,
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        M3MotionShowcaseDialog.show(context);
                      },
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

  Widget _buildMotionOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.secondaryContainer.withAlpha(160) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withAlpha(120)
                : colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
