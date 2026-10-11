import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/country_switcher.dart';
import 'package:tashil_real_estate/core/localization/language_switcher.dart';
import 'package:tashil_real_estate/core/widgets/theme_palette_switcher.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/drawer/tashil_navigation_drawer.dart';
import 'package:tashil_real_estate/core/design_system/navigation_rail/tashil_navigation_rail.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'views/overview_view.dart';
import 'views/properties_view.dart';
import 'views/crm_view.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';

class AgencyDashboard extends StatefulWidget {
  const AgencyDashboard({super.key});

  @override
  State<AgencyDashboard> createState() => _AgencyDashboardState();
}

class _AgencyDashboardState extends State<AgencyDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Widget> _views = [
    const OverviewView(),
    const PropertiesView(),
    const CrmView(),
    const LeasesManagementView(),
    const RentCollectionView(),
    const FinancialKpiDashboardView(role: FinancialPortalRole.agency),
    const InvestorDashboardView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, country, _) {
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
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          child: _views[_selectedIndex],
        ),
      ),
    );
  }

  /// Full-Width Persistent Top Header (64dp)
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
          // Start: Brand Identity (Logo & Title)
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
                  Icons.domain_rounded,
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
                    loc.tr('agencyWorkspace'),
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

          // End: User Quick Controls (Theme, Country, Language, Settings, Browse As Guest)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThemePaletteSwitcher(isCompact: true),
              const SizedBox(width: 6),
              const CountrySwitcher(isCompact: true, showLabel: false),
              const SizedBox(width: 6),
              const LanguageSwitcher(isCompact: true),
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
          label: loc.tr('dashboard'),
          isSelected: _selectedIndex == 0,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        TashilRailDestination(
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment_rounded,
          label: loc.tr('properties'),
          badgeCount: '120',
          isSelected: _selectedIndex == 1,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        TashilRailDestination(
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
          label: loc.tr('crm'),
          isSelected: _selectedIndex == 2,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        TashilRailDestination(
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_rounded,
          label: loc.tr('leases'),
          badgeCount: '85',
          isSelected: _selectedIndex == 3,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 3),
        ),
        TashilRailDestination(
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
          label: loc.tr('rentCollectionTitle'),
          badgeCount: '3',
          isSelected: _selectedIndex == 4,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 4),
        ),
        TashilRailDestination(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics_rounded,
          label: loc.tr('financials'),
          isSelected: _selectedIndex == 5,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 5),
        ),
        TashilRailDestination(
          icon: Icons.show_chart_outlined,
          selectedIcon: Icons.show_chart_rounded,
          label: loc.tr('investorDashboardTitle'),
          isSelected: _selectedIndex == 6,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 6),
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
                  initials: 'AG',
                  displayName: loc.tr('agencyWorkspace'),
                  roleSubtitle: loc.tr('roleAgency'),
                  isCollapsed: false,
                  onTap: () => _showAgencyProfileDialog(context, loc, colorScheme),
                ),
              ],
            )
          : Tooltip(
              message: loc.tr('agencyWorkspace'),
              preferBelow: false,
              verticalOffset: 24.0,
              child: InkWell(
                onTap: () => _showAgencyProfileDialog(context, loc, colorScheme),
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      'AG',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  /// Interactive Agency Profile Menu Dialog
  void _showAgencyProfileDialog(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          'AG',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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
                                    loc.tr('agencyWorkspace'),
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
                              loc.tr('roleAgency'),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TashilIconButton.standard(
                        icon: Icons.close_rounded,
                        size: 34,
                        iconSize: 18,
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Agency Portfolio Summary Chips
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
                          label: loc.tr('properties'),
                          value: '120',
                          colorScheme: colorScheme,
                        ),
                        Container(width: 1, height: 20, color: colorScheme.outlineVariant),
                        _buildProfileStat(
                          label: loc.tr('leases'),
                          value: '85',
                          colorScheme: colorScheme,
                        ),
                        Container(width: 1, height: 20, color: colorScheme.outlineVariant),
                        _buildProfileStat(
                          label: loc.tr('crm'),
                          value: '15',
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 8),

                  // Menu Actions
                  _buildProfileMenuItem(
                    icon: Icons.dashboard_outlined,
                    title: loc.tr('dashboard'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      setState(() => _selectedIndex = 0);
                    },
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.tune_rounded,
                    title: loc.tr('settings'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      AppSettingsDialog.show(context);
                    },
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.travel_explore_rounded,
                    title: loc.tr('browseAsVisitor'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      context.go('/');
                    },
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.security_rounded,
                    title: loc.tr('accountSecurity'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.tr('roleAgency')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 6),
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
              child: Icon(Icons.domain_rounded, color: colorScheme.onPrimary, size: 18),
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
      body: _views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: loc.tr('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.apartment_outlined),
            selectedIcon: const Icon(Icons.apartment_rounded),
            label: loc.tr('properties'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people_rounded),
            label: loc.tr('crm'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description_rounded),
            label: loc.tr('leases'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics_rounded),
            label: loc.tr('financials'),
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
              child: Icon(Icons.domain_rounded, color: colorScheme.onPrimary, size: 20),
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
                    loc.tr('agencyWorkspace'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TashilIconButton.standard(
              icon: Icons.close_rounded,
              size: 36,
              iconSize: 20,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      destinations: [
        TashilDrawerDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          label: loc.tr('dashboard'),
          isSelected: _selectedIndex == 0,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 0);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment_rounded,
          label: loc.tr('properties'),
          badgeCount: '120',
          isSelected: _selectedIndex == 1,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 1);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
          label: loc.tr('crm'),
          isSelected: _selectedIndex == 2,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 2);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_rounded,
          label: loc.tr('leases'),
          badgeCount: '85',
          isSelected: _selectedIndex == 3,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 3);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
          label: loc.tr('rentCollectionTitle'),
          badgeCount: '3',
          isSelected: _selectedIndex == 4,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 4);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics_rounded,
          label: loc.tr('financials'),
          isSelected: _selectedIndex == 5,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 5);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.show_chart_outlined,
          selectedIcon: Icons.show_chart_rounded,
          label: loc.tr('investorDashboardTitle'),
          isSelected: _selectedIndex == 6,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 6);
          },
        ),
        const TashilDivider.middleInset(height: 16.0),
        TashilDrawerDestination(
          icon: Icons.tune_outlined,
          selectedIcon: Icons.tune_rounded,
          label: loc.tr('settings'),
          isSelected: false,
          onTap: () {
            Navigator.pop(context);
            AppSettingsDialog.show(context);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.travel_explore_outlined,
          selectedIcon: Icons.travel_explore_rounded,
          label: loc.tr('browseAsVisitor'),
          isSelected: false,
          onTap: () {
            Navigator.pop(context);
            context.go('/');
          },
        ),
        TashilDrawerDestination(
          icon: Icons.logout_outlined,
          selectedIcon: Icons.logout_rounded,
          label: loc.tr('logout'),
          isSelected: false,
          onTap: () async {
            Navigator.pop(context);
            await FirebaseAuthService().signOut();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TashilDrawerProfileTile(
          initials: 'AG',
          displayName: loc.tr('agencyWorkspace'),
          roleSubtitle: loc.tr('roleAgency'),
          isCollapsed: false,
          onTap: () {
            Navigator.pop(context);
            _showAgencyProfileDialog(context, loc, colorScheme);
          },
        ),
      ),
    );
  }
}
