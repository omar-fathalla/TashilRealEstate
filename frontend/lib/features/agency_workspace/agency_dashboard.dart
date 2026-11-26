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
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'services/agency_identity.dart';
import 'widgets/agency_profile_dialog.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/fast_property_onboarding_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_stats.dart';
import 'views/overview_view.dart';
import 'views/properties_view.dart';
import 'views/crm_view.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/features/requests/views/requests_inbox_view.dart';
import 'package:tashil_real_estate/features/maintenance/views/maintenance_views.dart';

class AgencyDashboard extends StatefulWidget {
  /// Where the signed-in account and its agency come from; tests pass a fake.
  final AgencyIdentitySource? identitySource;

  /// The portfolio data source. Tests pass one backed by fakes; the app uses the Firebase one.
  final PortfolioController? portfolio;

  const AgencyDashboard({super.key, this.identitySource, this.portfolio});

  @override
  State<AgencyDashboard> createState() => _AgencyDashboardState();
}

class _AgencyDashboardState extends State<AgencyDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final ValueNotifier<AgencyIdentity> _identity = ValueNotifier(AgencyIdentity.empty);
  late final AgencyIdentitySource _identitySource = widget.identitySource ?? FirebaseAgencyIdentitySource();

  late final PortfolioController _portfolio;
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _identitySource.load().then((identity) {
      if (mounted) _identity.value = identity;
    }).catchError((Object _) {});
    _portfolio = widget.portfolio ?? PortfolioController();
    _portfolio.start();
    _views = [
      OverviewView(
        controller: _portfolio,
        onNavigate: (tab) => setState(() => _selectedIndex = tab),
        onAddProperty: () => FastPropertyOnboardingDialog.show(context),
      ),
      const PropertiesView(),
      const CrmView(),
      LeasesManagementView(controller: _portfolio),
      RentCollectionView(portfolio: _portfolio),
      FinancialKpiDashboardView(role: FinancialPortalRole.agency, portfolio: _portfolio),
      const InvestorDashboardView(),
      const RequestsInboxView(agency: true),
      const MaintenanceManagerView(agency: true),
    ];
  }

  @override
  void dispose() {
    _identity.dispose();
    if (widget.portfolio == null) _portfolio.dispose();
    super.dispose();
  }

  PortfolioStats _stats() {
    final real = PropertyLifecycleService().propertiesNotifier.value.where((p) => !PropertyLifecycleService.isMockPropertyId(p.id)).toList();
    return PortfolioStats.compute(_portfolio.snapshot, real, countryCode: CountryController.countryCode, now: DateTime.now());
  }

  static String? _badge(int n) => n > 0 ? '$n' : null;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, country, _) {
            final loc = AppLocalizations.of(context);

            return ListenableBuilder(
              listenable: Listenable.merge([_portfolio, PropertyLifecycleService().propertiesNotifier]),
              builder: (context, _) => ResponsiveLayout(
                mobileBody: _buildMobileLayout(context, loc),
                desktopBody: _buildDesktopLayout(context, loc),
                tabletBody: _buildMobileLayout(context, loc),
              ),
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
          badgeCount: _badge(_stats().properties),
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
          badgeCount: _badge(_stats().activeLeases),
          isSelected: _selectedIndex == 3,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 3),
        ),
        TashilRailDestination(
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
          label: loc.tr('rentCollectionTitle'),
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
          icon: Icons.inbox_outlined,
          selectedIcon: Icons.inbox_rounded,
          label: loc.tr('rqInboxTitle'),
          isSelected: _selectedIndex == 7,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 7),
        ),
        TashilRailDestination(
          icon: Icons.build_outlined,
          selectedIcon: Icons.build_rounded,
          label: loc.tr('maintenanceTickets'),
          isSelected: _selectedIndex == 8,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 8),
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
                _identityTile(
                  loc: loc,
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
                    child: ValueListenableBuilder<AgencyIdentity>(
                      valueListenable: _identity,
                      builder: (context, identity, _) => Text(
                        _initialsOf(identity, loc),
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
            ),
    );
  }

  String _initialsOf(AgencyIdentity identity, AppLocalizations loc) =>
      identity.initials.isEmpty ? loc.tr('roleAgency').characters.first : identity.initials;

  /// The profile tile of the drawer: the signed-in person and their agency, never placeholders.
  Widget _identityTile({required AppLocalizations loc, required VoidCallback onTap}) {
    return ValueListenableBuilder<AgencyIdentity>(
      valueListenable: _identity,
      builder: (context, identity, _) {
        final agencyName = identity.agencyNameFor(Localizations.localeOf(context).languageCode);
        return TashilDrawerProfileTile(
          initials: _initialsOf(identity, loc),
          displayName: identity.personName.isEmpty ? loc.tr('agencyWorkspace') : identity.personName,
          roleSubtitle: agencyName.isEmpty ? loc.tr('roleAgency') : agencyName,
          isCollapsed: false,
          onTap: onTap,
        );
      },
    );
  }

  /// The agency account menu, built from the signed-in account and its agency (TAQ-153).
  void _showAgencyProfileDialog(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    final identity = _identity.value;
    showDialog(
      context: context,
      builder: (dialogCtx) => AgencyProfileDialog(
        identity: identity,
        onDashboard: () {
          Navigator.of(dialogCtx).pop();
          setState(() => _selectedIndex = 0);
        },
        onSettings: () {
          Navigator.of(dialogCtx).pop();
          AppSettingsDialog.show(context);
        },
        onBrowse: () {
          Navigator.of(dialogCtx).pop();
          context.go('/');
        },
        onSecurity: () async {
          Navigator.of(dialogCtx).pop();
          final sent = await showAgencyPasswordResetDialog(
            context,
            email: identity.email,
            send: _identitySource.sendPasswordReset,
          );
          if (sent && context.mounted) {
            TashilSnackBar.showSuccess(context: context, message: loc.tr('securityResetSent'));
          }
        },
        onLogout: () async {
          Navigator.of(dialogCtx).pop();
          await FirebaseAuthService().signOut();
          if (context.mounted) context.go('/login');
        },
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
          badgeCount: _badge(_stats().properties),
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
          badgeCount: _badge(_stats().activeLeases),
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
        TashilDrawerDestination(
          icon: Icons.inbox_outlined,
          selectedIcon: Icons.inbox_rounded,
          label: loc.tr('rqInboxTitle'),
          isSelected: _selectedIndex == 7,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 7);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.build_outlined,
          selectedIcon: Icons.build_rounded,
          label: loc.tr('maintenanceTickets'),
          isSelected: _selectedIndex == 8,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 8);
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
        child: _identityTile(
          loc: loc,
          onTap: () {
            Navigator.pop(context);
            _showAgencyProfileDialog(context, loc, colorScheme);
          },
        ),
      ),
    );
  }
}
