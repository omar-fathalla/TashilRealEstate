import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/carousel/tashil_carousels.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/drawer/tashil_navigation_drawer.dart';
import 'package:tashil_real_estate/core/design_system/navigation_rail/tashil_navigation_rail.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/lists/m3_lists_showcase_dialog.dart';
import 'package:tashil_real_estate/core/design_system/loading/m3_loading_showcase_dialog.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/features/architecture_hub/widgets/google_ai_architecture_hub_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';
import 'package:tashil_real_estate/features/image_moderation/widgets/ai_image_moderator_dialog.dart';
import 'package:tashil_real_estate/features/ai_engine_hub/views/ai_engine_hub_view.dart';

class SuperAdminDashboard extends StatefulWidget {
  final int initialIndex;
  const SuperAdminDashboard({super.key, this.initialIndex = 0});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  late int _selectedIndex;
  bool _isSidebarCollapsed = false;
  String _selectedCountryFilter = 'ALL';
  late List<Map<String, dynamic>> _agencies;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initSampleAgencies();
  }

  void _initSampleAgencies() {
    _agencies = [
      {
        'name': 'إعمار مصر للإدارة العقارية',
        'country': 'EG',
        'license': 'EG-REG-9824',
        'authority': 'الهيئة العامة للرقابة المالية والسجل التجاري',
        'units': 420,
        'brokers': 28,
        'plan': 'Enterprise',
        'initials': 'EM',
        'email': 'compliance@emaarmisr.com',
        'phone': '+20 2 2461 8000',
        'accreditationDate': '2023-01-15',
        'renewalDate': '2027-01-14',
        'isVerified': true,
        'isSuspended': false,
        'permissions': {
          'verifiedBadge': true,
          'directContracts': true,
          'escrowAccess': true,
          'multiBranch': true,
          'apiAccess': true,
        },
      },
      {
        'name': 'الدار العقارية دبي',
        'country': 'AE',
        'license': 'AE-RERA-5510',
        'authority': 'مؤسسة التنظيم العقاري (RERA) - دائرة الأراضي والأملاك',
        'units': 380,
        'brokers': 24,
        'plan': 'Enterprise',
        'initials': 'AD',
        'email': 'licensing@aldar.ae',
        'phone': '+971 4 366 1688',
        'accreditationDate': '2022-06-20',
        'renewalDate': '2026-06-19',
        'isVerified': true,
        'isSuspended': false,
        'permissions': {
          'verifiedBadge': true,
          'directContracts': true,
          'escrowAccess': true,
          'multiBranch': true,
          'apiAccess': true,
        },
      },
      {
        'name': 'بالم هيلز للوساطة والتسويق',
        'country': 'EG',
        'license': 'EG-REG-4412',
        'authority': 'الهيئة العامة للاستثمار والمناطق الحرة',
        'units': 290,
        'brokers': 18,
        'plan': 'Professional',
        'initials': 'PH',
        'email': 'agency@palmhills.com',
        'phone': '+20 2 3535 1200',
        'accreditationDate': '2023-09-10',
        'renewalDate': '2026-09-09',
        'isVerified': true,
        'isSuspended': false,
        'permissions': {
          'verifiedBadge': true,
          'directContracts': true,
          'escrowAccess': false,
          'multiBranch': true,
          'apiAccess': false,
        },
      },
      {
        'name': 'داماك العقارية أبوظبي',
        'country': 'AE',
        'license': 'AE-RERA-8890',
        'authority': 'دائرة البلديات والنقل - أبوظبي',
        'units': 330,
        'brokers': 22,
        'plan': 'Enterprise',
        'initials': 'DM',
        'email': 'brokerage@damac.ae',
        'phone': '+971 2 611 7777',
        'accreditationDate': '2022-11-05',
        'renewalDate': '2026-11-04',
        'isVerified': true,
        'isSuspended': false,
        'permissions': {
          'verifiedBadge': true,
          'directContracts': true,
          'escrowAccess': true,
          'multiBranch': true,
          'apiAccess': true,
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, countryCode, _) {
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
    final views = _getViews(loc, false, colorScheme);

    return TashilScaffoldCanvas(
      header: _buildDesktopTopHeader(context, loc, colorScheme),
      navigationRail: _buildNavigationRail(context, loc, colorScheme),
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          child: views[_selectedIndex],
        ),
      ),
    );
  }

  List<Widget> _getViews(AppLocalizations loc, bool isMobile, ColorScheme colorScheme) => [
    const FinancialKpiDashboardView(role: FinancialPortalRole.superAdmin),
    _buildAgenciesAndTenantsView(loc, isMobile, colorScheme),
    _buildEscrowAndAuditView(loc, isMobile, colorScheme),
    _buildDesignSystemHubView(loc, isMobile, colorScheme),
    const RentCollectionView(),
    const InvestorDashboardView(),
    const AiEngineHubView(),
  ];

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
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: colorScheme.onPrimaryContainer,
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
                    loc.tr('superAdminWorkspaceTitle'),
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

          // End: Quick Action Buttons (AI Models Hub, Google AI Hub, Settings, Browse As Guest, Logout)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TashilIconButton.tonal(
                    icon: Icons.smart_toy_rounded,
                    size: 38,
                    iconSize: 20,
                    tooltip: loc.tr('aiEngineModelsBtn'),
                    onPressed: () => setState(() => _selectedIndex = 6),
                  ),
                  const SizedBox(width: 8),
                  TashilButton.tonal(
                    icon: Icons.hub_rounded,
                    label: loc.tr('googleAiHubBtn'),
                    onPressed: () => GoogleAiArchitectureHubDialog.show(context),
                  ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Icons.shield_outlined,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('aiImageModeratorTitle'),
                onPressed: () => AiImageModeratorDialog.show(context),
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
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Icons.logout_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('logout'),
                onPressed: () async {
                  await FirebaseAuthService().signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
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
      expandedWidth: 280.0,
      onToggleExpanded: () {
        setState(() {
          _isSidebarCollapsed = !_isSidebarCollapsed;
        });
      },
      menuTooltip: isExpanded ? loc.tr('collapseMenu') : loc.tr('expandMenu'),
      destinations: [
        TashilRailDestination(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics_rounded,
          label: loc.tr('kpiCompact'),
          isSelected: _selectedIndex == 0,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        TashilRailDestination(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business_rounded,
          label: loc.tr('agenciesCompact'),
          badgeCount: '48',
          isSelected: _selectedIndex == 1,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        TashilRailDestination(
          icon: Icons.verified_user_outlined,
          selectedIcon: Icons.verified_user_rounded,
          label: loc.tr('escrowCompact'),
          isSelected: _selectedIndex == 2,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        TashilRailDestination(
          icon: Icons.palette_outlined,
          selectedIcon: Icons.palette_rounded,
          label: loc.tr('standardsCompact'),
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
          icon: Icons.show_chart_outlined,
          selectedIcon: Icons.show_chart_rounded,
          label: loc.tr('investorDashboardTitle'),
          isSelected: _selectedIndex == 5,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 5),
        ),
        TashilRailDestination(
          icon: Icons.smart_toy_outlined,
          selectedIcon: Icons.smart_toy_rounded,
          label: loc.tr('aiEngineHubNavTitle'),
          badgeCount: '6',
          isSelected: _selectedIndex == 6,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 6),
        ),
        TashilRailDestination(
          icon: Icons.hub_outlined,
          selectedIcon: Icons.hub_rounded,
          label: loc.tr('googleAiHubBtn'),
          isSelected: false,
          isExpanded: isExpanded,
          trailing: isExpanded
              ? Icon(
                  Icons.chevron_right_rounded,
                  size: 18.0,
                  color: colorScheme.outlineVariant,
                )
              : null,
          onTap: () => GoogleAiArchitectureHubDialog.show(context),
        ),
        TashilRailDestination(
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield_rounded,
          label: loc.tr('aiImageModeratorTitle'),
          isSelected: false,
          isExpanded: isExpanded,
          trailing: isExpanded
              ? Icon(
                  Icons.chevron_right_rounded,
                  size: 18.0,
                  color: colorScheme.outlineVariant,
                )
              : null,
          onTap: () => AiImageModeratorDialog.show(context),
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
                  initials: 'SA',
                  displayName: loc.tr('superAdminProfile'),
                  roleSubtitle: loc.tr('roleSuperAdmin'),
                  isCollapsed: false,
                  onTap: () => _showSuperAdminProfileDialog(context, loc, colorScheme),
                ),
              ],
            )
          : Tooltip(
              message: loc.tr('superAdminProfile'),
              preferBelow: false,
              verticalOffset: 24.0,
              child: InkWell(
                onTap: () => _showSuperAdminProfileDialog(context, loc, colorScheme),
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      'SA',
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

  /// Interactive Super Admin Profile Menu Dialog
  void _showSuperAdminProfileDialog(
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
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          'SA',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
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
                                    loc.tr('superAdminProfile'),
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
                              loc.tr('roleSuperAdmin'),
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

                  // System Summary Chips
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
                          label: loc.tr('activeAgenciesWord'),
                          value: '48',
                          colorScheme: colorScheme,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: colorScheme.outlineVariant.withAlpha(100),
                        ),
                        _buildProfileStat(
                          label: loc.tr('verifiedUnitsWord'),
                          value: '1,420',
                          colorScheme: colorScheme,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: colorScheme.outlineVariant.withAlpha(100),
                        ),
                        _buildProfileStat(
                          label: loc.tr('escrowCompact'),
                          value: '100%',
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  const TashilDivider.middleInset(),
                  const SizedBox(height: 4),

                  // Action 1: System Settings
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(Icons.tune_rounded, size: 20, color: colorScheme.primary),
                    title: Text(
                      loc.tr('settings'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: colorScheme.outlineVariant),
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      AppSettingsDialog.show(context);
                    },
                  ),

                  // Action 2: Audit Logs
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(Icons.verified_user_rounded, size: 20, color: colorScheme.secondary),
                    title: Text(
                      loc.tr('escrowAndAuditLogsTab'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: colorScheme.outlineVariant),
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      setState(() => _selectedIndex = 2);
                    },
                  ),

                  const TashilDivider.middleInset(),
                  const SizedBox(height: 8),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: TashilButton(
                      label: loc.tr('logout'),
                      icon: Icons.logout_rounded,
                      variant: TashilButtonVariant.outlined,
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop();
                        await FirebaseAuthService().signOut();
                        if (context.mounted) context.go('/login');
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
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Mobile Layout: Scaffold with Top AppBar + End Drawer + Bottom NavigationBar
  Widget _buildMobileLayout(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final views = _getViews(loc, true, colorScheme);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.admin_panel_settings_rounded, color: colorScheme.onPrimaryContainer, size: 18),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('appName'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              loc.tr('superAdminWorkspaceTitle'),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TashilIconButton.tonal(
            icon: Icons.tune_rounded,
            size: 38,
            iconSize: 20,
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
      body: views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 4 ? _selectedIndex : 0,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics_rounded),
            label: loc.tr('kpiCompact'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.business_outlined),
            selectedIcon: const Icon(Icons.business_rounded),
            label: loc.tr('agenciesCompact'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.verified_user_outlined),
            selectedIcon: const Icon(Icons.verified_user_rounded),
            label: loc.tr('escrowCompact'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.palette_outlined),
            selectedIcon: const Icon(Icons.palette_rounded),
            label: loc.tr('m3Compact'),
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
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.admin_panel_settings_rounded, color: colorScheme.onPrimaryContainer, size: 20),
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
                    loc.tr('superAdminWorkspaceTitle'),
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
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics_rounded,
          label: loc.tr('kpiCompact'),
          isSelected: _selectedIndex == 0,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 0);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business_rounded,
          label: loc.tr('agenciesCompact'),
          badgeCount: '48',
          isSelected: _selectedIndex == 1,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 1);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.verified_user_outlined,
          selectedIcon: Icons.verified_user_rounded,
          label: loc.tr('escrowCompact'),
          isSelected: _selectedIndex == 2,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 2);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.palette_outlined,
          selectedIcon: Icons.palette_rounded,
          label: loc.tr('standardsCompact'),
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
          icon: Icons.show_chart_outlined,
          selectedIcon: Icons.show_chart_rounded,
          label: loc.tr('investorDashboardTitle'),
          isSelected: _selectedIndex == 5,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 5);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.smart_toy_outlined,
          selectedIcon: Icons.smart_toy_rounded,
          label: loc.tr('aiEngineHubNavTitle'),
          badgeCount: '6',
          isSelected: _selectedIndex == 6,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 6);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.hub_outlined,
          selectedIcon: Icons.hub_rounded,
          label: loc.tr('googleAiHubBtn'),
          isSelected: false,
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 18.0,
            color: colorScheme.outlineVariant,
          ),
          onTap: () {
            Navigator.pop(context);
            GoogleAiArchitectureHubDialog.show(context);
          },
        ),
        TashilDrawerDestination(
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield_rounded,
          label: loc.tr('aiImageModeratorTitle'),
          isSelected: false,
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 18.0,
            color: colorScheme.outlineVariant,
          ),
          onTap: () {
            Navigator.pop(context);
            AiImageModeratorDialog.show(context);
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
            initials: 'SA',
            displayName: loc.tr('superAdminProfile'),
            roleSubtitle: loc.tr('roleSuperAdmin'),
            onTap: () {
              Navigator.pop(context);
              _showSuperAdminProfileDialog(context, loc, colorScheme);
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 1: إدارة الوكالات والمشتركين (Agencies & Subscribers Management)
  // =========================================================================
  Widget _buildAgenciesAndTenantsView(AppLocalizations loc, bool isMobile, ColorScheme colorScheme) {
    final filteredAgencies = _selectedCountryFilter == 'ALL'
        ? _agencies
        : _agencies.where((a) => a['country'] == _selectedCountryFilter).toList();

    final activeCount = 48 + (_agencies.length - 4);
    final totalUnits = 1420 + (_agencies.fold<int>(0, (s, a) => s + (a['units'] as int)) - 1420);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('agenciesAndTenantsTab'),
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeCount ${loc.tr('activeAgenciesWord')} | $totalUnits ${loc.tr('verifiedUnitsWord')}',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TashilButton(
                label: loc.tr('addNewAgency'),
                icon: Icons.add_business_rounded,
                onPressed: () => _showAddAgencyDialog(context, loc, colorScheme),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 4 Stat KPI Cards (Unified M3 Elevated Metric Cards)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isNarrow ? 2 : 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isNarrow ? 1.45 : 1.7,
                children: [
                  _buildAgencyMetricCard(
                    title: '$activeCount',
                    subtitle: loc.tr('activeAgenciesWord'),
                    badgeText: '+12%',
                    badgeColor: Colors.green,
                    icon: Icons.business_rounded,
                    colorScheme: colorScheme,
                  ),
                  _buildAgencyMetricCard(
                    title: '1,420',
                    subtitle: loc.tr('verifiedUnitsWord'),
                    badgeText: '98.5%',
                    badgeColor: colorScheme.primary,
                    icon: Icons.apartment_rounded,
                    colorScheme: colorScheme,
                  ),
                  _buildAgencyMetricCard(
                    title: '142',
                    subtitle: loc.tr('activeBrokersWord'),
                    badgeText: '100%',
                    badgeColor: colorScheme.secondary,
                    icon: Icons.badge_rounded,
                    colorScheme: colorScheme,
                  ),
                  _buildAgencyMetricCard(
                    title: '99.4%',
                    subtitle: loc.tr('complianceRate'),
                    badgeText: 'ISO 27001',
                    badgeColor: Colors.teal,
                    icon: Icons.verified_user_rounded,
                    colorScheme: colorScheme,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Country Filter (Official M3 Expressive Connected Button Group - Clean Minimalist Text)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TashilConnectedButtonGroup<String>(
              selectedValue: _selectedCountryFilter,
              onSelectionChanged: (val) => setState(() => _selectedCountryFilter = val),
              segments: [
                TashilConnectedButtonSegment<String>(
                  value: 'ALL',
                  label: loc.tr('allAgencies'),
                  icon: Icons.domain_rounded,
                ),
                TashilConnectedButtonSegment<String>(
                  value: 'EG',
                  label: loc.tr('country_eg'),
                ),
                TashilConnectedButtonSegment<String>(
                  value: 'AE',
                  label: loc.tr('country_ae'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Agencies Directory Grid (Official M3 Outlined Directory Cards with Hover Animation)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAgencies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isNarrow ? 1 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isNarrow ? 1.45 : 1.95,
                ),
                itemBuilder: (context, index) {
                  final agency = filteredAgencies[index];
                  final isEg = agency['country'] == 'EG';

                  return TashilCard.outlined(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    enableHoverAnimation: true,
                    hoverElevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Header: Avatar, Identity & Plan Badge
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  agency['initials'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                    fontSize: 14,
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
                                            agency['name'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(isEg ? '🇪🇬' : '🇦🇪', style: const TextStyle(fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified_rounded,
                                          size: 14,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          agency['license'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  agency['plan'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Middle: Balanced Metric Ribbon (Fixing the blank void)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildAgencyStatColumn(
                                    label: loc.tr('verifiedUnitsWord'),
                                    value: '${agency['units']}',
                                    icon: Icons.apartment_rounded,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 22,
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildAgencyStatColumn(
                                    label: loc.tr('activeBrokersWord'),
                                    value: '${agency['brokers']}',
                                    icon: Icons.badge_rounded,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // M3 Action Divider (Directly Separating Content from Actions)
                          const TashilDivider.cardAction(),
                          const SizedBox(height: 6),

                          // Footer: Verification Status & Standardized Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: agency['isSuspended'] == true ? Colors.orange : Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        agency['isSuspended'] == true
                                            ? loc.tr('suspendAgencyAccount')
                                            : loc.tr('verifiedAgency'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: agency['isSuspended'] == true
                                              ? colorScheme.error
                                              : colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TashilButton.tonal(
                                    label: loc.tr('viewAgencyDetails'),
                                    icon: Icons.visibility_rounded,
                                    onPressed: () => _showAgencyRegistryDialog(context, agency, loc, colorScheme),
                                  ),
                                  const SizedBox(width: 6),
                                  TashilIconButton.standard(
                                    icon: Icons.shield_rounded,
                                    tooltip: loc.tr('managePermissions'),
                                    onPressed: () => _showAgencyPermissionsDialog(context, agency, loc, colorScheme),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Interactive Agency Management Dialogs & Operations
  // =========================================================================

  /// Open M3 Modal Form for creating and registering a new agency
  void _showAddAgencyDialog(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final licenseController = TextEditingController();
    final brokersController = TextEditingController(text: '12');
    final unitsController = TextEditingController(text: '85');
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    String selectedCountry = 'EG';
    String selectedPlan = 'Enterprise';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return TashilModalDialog(
            maxWidth: 680,
            title: loc.tr('addNewAgency'),
            subtitle: loc.tr('registerNewAgencySubtitle'),
            icon: Icons.add_business_rounded,
            onClose: () => Navigator.of(ctx).pop(),
            footer: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TashilButton.outlined(
                  label: loc.tr('cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                TashilButton(
                  label: loc.tr('submitRegisterAgency'),
                  icon: Icons.check_circle_rounded,
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final name = nameController.text.trim();
                      final words = name.split(' ').where((w) => w.isNotEmpty).toList();
                      String initials = 'AG';
                      if (words.length >= 2) {
                        initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
                      } else if (words.isNotEmpty && words[0].length >= 2) {
                        initials = words[0].substring(0, 2).toUpperCase();
                      }

                      final newAgency = {
                        'name': name,
                        'country': selectedCountry,
                        'license': licenseController.text.trim().isNotEmpty
                            ? licenseController.text.trim()
                            : (selectedCountry == 'EG' ? 'EG-REG-6520' : 'AE-RERA-7140'),
                        'authority': selectedCountry == 'EG'
                            ? 'الهيئة العامة للرقابة المالية والسجل التجاري'
                            : 'مؤسسة التنظيم العقاري (RERA) - دائرة الأراضي والأملاك',
                        'units': int.tryParse(unitsController.text.trim()) ?? 85,
                        'brokers': int.tryParse(brokersController.text.trim()) ?? 12,
                        'plan': selectedPlan,
                        'initials': initials,
                        'email': emailController.text.trim().isNotEmpty
                            ? emailController.text.trim()
                            : 'admin@${name.toLowerCase().replaceAll(' ', '')}.com',
                        'phone': phoneController.text.trim().isNotEmpty
                            ? phoneController.text.trim()
                            : (selectedCountry == 'EG' ? '+20 10 0000 1234' : '+971 50 000 1234'),
                        'accreditationDate': DateTime.now().toString().split(' ').first,
                        'renewalDate': DateTime.now().add(const Duration(days: 365)).toString().split(' ').first,
                        'isVerified': true,
                        'isSuspended': false,
                        'permissions': {
                          'verifiedBadge': true,
                          'directContracts': true,
                          'escrowAccess': true,
                          'multiBranch': true,
                          'apiAccess': selectedPlan == 'Enterprise',
                        },
                      };

                      setState(() {
                        _agencies.insert(0, newAgency);
                      });

                      Navigator.of(ctx).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.tr('agencyAddedSuccess')),
                          backgroundColor: Colors.green.shade800,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Country Selector
                    Text(
                      loc.tr('countryFilter'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TashilConnectedButtonGroup<String>(
                      selectedValue: selectedCountry,
                      onSelectionChanged: (val) => setDialogState(() => selectedCountry = val),
                      segments: [
                        TashilConnectedButtonSegment<String>(
                          value: 'EG',
                          label: loc.tr('country_eg'),
                        ),
                        TashilConnectedButtonSegment<String>(
                          value: 'AE',
                          label: loc.tr('country_ae'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Agency Name Field
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: loc.tr('agencyNameLabel'),
                        hintText: loc.tr('agencyNameHint'),
                        prefixIcon: const Icon(Icons.apartment_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('requiredField') : null,
                    ),
                    const SizedBox(height: 14),

                    // Commercial License No.
                    TextFormField(
                      controller: licenseController,
                      decoration: InputDecoration(
                        labelText: loc.tr('commercialLicenseLabel'),
                        hintText: loc.tr('commercialLicenseHint'),
                        prefixIcon: const Icon(Icons.verified_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('requiredField') : null,
                    ),
                    const SizedBox(height: 16),

                    // Plan Selector
                    Text(
                      loc.tr('subscriptionPlanLabel'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TashilConnectedButtonGroup<String>(
                      selectedValue: selectedPlan,
                      onSelectionChanged: (val) => setDialogState(() => selectedPlan = val),
                      segments: [
                        TashilConnectedButtonSegment<String>(
                          value: 'Enterprise',
                          label: loc.tr('planEnterprise'),
                          icon: Icons.star_rounded,
                        ),
                        TashilConnectedButtonSegment<String>(
                          value: 'Professional',
                          label: loc.tr('planProfessional'),
                        ),
                        TashilConnectedButtonSegment<String>(
                          value: 'Starter',
                          label: loc.tr('planStarter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Brokers and Units count row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: brokersController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.tr('initialBrokersCount'),
                              prefixIcon: const Icon(Icons.badge_rounded),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: unitsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.tr('initialUnitsCount'),
                              prefixIcon: const Icon(Icons.domain_rounded),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Email and Phone row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: loc.tr('agencyEmailLabel'),
                              hintText: 'admin@agency.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: loc.tr('agencyPhoneLabel'),
                              hintText: selectedCountry == 'EG' ? '+20 10...' : '+971 50...',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Open M3 Modal Dialog showing official agency credentials and compliance record
  void _showAgencyRegistryDialog(BuildContext context, Map<String, dynamic> agency, AppLocalizations loc, ColorScheme colorScheme) {
    final isEg = agency['country'] == 'EG';
    final isSuspended = agency['isSuspended'] == true;

    showDialog(
      context: context,
      builder: (ctx) => TashilModalDialog(
        maxWidth: 640,
        title: agency['name'] as String,
        subtitle: '${loc.tr('licenseNumber')}: ${agency['license']}',
        icon: Icons.verified_user_rounded,
        onClose: () => Navigator.of(ctx).pop(),
        footer: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TashilButton.outlined(
              label: loc.tr('exportOfficialAuditStatementBtn'),
              icon: Icons.download_rounded,
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.tr('auditStatementExportSuccess')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            TashilButton(
              label: loc.tr('close'),
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status & Plan Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSuspended
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSuspended ? colorScheme.error : colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSuspended ? colorScheme.error : colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        agency['initials'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                isSuspended ? loc.tr('suspendAgencyAccount') : loc.tr('verifiedAgency'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSuspended ? colorScheme.error : colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  agency['plan'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isEg ? 'جمهورية مصر العربية' : 'دولة الإمارات العربية المتحدة',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Registry Credentials Card
              TashilCard.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildRegistryRow(
                        icon: Icons.account_balance_rounded,
                        label: loc.tr('regulatoryAuthority'),
                        value: agency['authority'] as String? ?? (isEg ? 'هيئة الرقابة المالية والسجل التجاري' : 'مؤسسة التنظيم العقاري (RERA)'),
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 16),
                      _buildRegistryRow(
                        icon: Icons.verified_rounded,
                        label: loc.tr('auditComplianceLevel'),
                        value: 'ISO 27001 / AML Tier 1',
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 16),
                      _buildRegistryRow(
                        icon: Icons.calendar_today_rounded,
                        label: loc.tr('accreditationDate'),
                        value: agency['accreditationDate'] as String? ?? '2023-01-15',
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 16),
                      _buildRegistryRow(
                        icon: Icons.update_rounded,
                        label: loc.tr('annualRenewalDate'),
                        value: agency['renewalDate'] as String? ?? '2027-01-14',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Operational Volume Metrics
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('verifiedUnitsWord'),
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${agency['units']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('activeBrokersWord'),
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${agency['brokers']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('complianceRate'),
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '100%',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact Information
              TashilCard.filled(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            agency['email'] as String? ?? 'info@agency.com',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            agency['phone'] as String? ?? '+20 2 0000 0000',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open M3 Modal Dialog for Agency Governance & Permissions
  void _showAgencyPermissionsDialog(BuildContext context, Map<String, dynamic> agency, AppLocalizations loc, ColorScheme colorScheme) {
    final permissions = Map<String, bool>.from(agency['permissions'] as Map? ?? {
      'verifiedBadge': true,
      'directContracts': true,
      'escrowAccess': true,
      'multiBranch': true,
      'apiAccess': true,
    });
    bool isSuspended = agency['isSuspended'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return TashilModalDialog(
            maxWidth: 640,
            title: loc.tr('agencyPermissionsTitle'),
            subtitle: '${loc.tr('agencyGovernanceSubtitle')}: ${agency['name']}',
            icon: Icons.shield_rounded,
            onClose: () => Navigator.of(ctx).pop(),
            footer: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TashilButton.outlined(
                  label: loc.tr('cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                TashilButton(
                  label: loc.tr('savePermissions'),
                  icon: Icons.save_rounded,
                  onPressed: () {
                    setState(() {
                      agency['permissions'] = permissions;
                      agency['isSuspended'] = isSuspended;
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('permissionsUpdatedSuccess')),
                        backgroundColor: Colors.green.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Suspension Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSuspended
                          ? colorScheme.errorContainer.withValues(alpha: 0.6)
                          : colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSuspended ? colorScheme.error : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSuspended ? Icons.block_rounded : Icons.check_circle_rounded,
                          color: isSuspended ? colorScheme.error : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSuspended ? loc.tr('agencySuspendedWarning') : loc.tr('verifiedAgency'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSuspended ? colorScheme.error : colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                isSuspended
                                    ? 'الحساب معلق مؤقتاً ولا يمكن للوسطاء إبرام عقود'
                                    : 'الحساب نشط ومعتمد ويمتلك كامل الصلاحيات المصرحة',
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        TashilSwitch(
                          value: !isSuspended,
                          onChanged: (val) {
                            setDialogState(() {
                              isSuspended = !val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    loc.tr('managePermissions'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildPermissionSwitchTile(
                    title: loc.tr('permVerifiedBadge'),
                    subtitle: 'إظهار شارة الثقة والاعتماد أمام العملاء في السوق العام',
                    icon: Icons.verified_rounded,
                    value: permissions['verifiedBadge'] ?? true,
                    onChanged: (val) => setDialogState(() => permissions['verifiedBadge'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permDirectContracts'),
                    subtitle: 'تمكين الوكالة من إصدار وتوقيع عقود الإيجار والبيع رقمياً',
                    icon: Icons.description_rounded,
                    value: permissions['directContracts'] ?? true,
                    onChanged: (val) => setDialogState(() => permissions['directContracts'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permEscrowAccess'),
                    subtitle: 'الربط مع حساب الضمان البنكي لتسوية العمولات والدفعات',
                    icon: Icons.shield_rounded,
                    value: permissions['escrowAccess'] ?? false,
                    onChanged: (val) => setDialogState(() => permissions['escrowAccess'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permMultiBranch'),
                    subtitle: 'السماح للوكالة بإدارة فروع ووسطاء في عدة مدن ومحافظات',
                    icon: Icons.corporate_fare_rounded,
                    value: permissions['multiBranch'] ?? true,
                    onChanged: (val) => setDialogState(() => permissions['multiBranch'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permApiAccess'),
                    subtitle: 'منح مفاتيح الربط البرمجي لدمج أنظمة الوكالة السحابية',
                    icon: Icons.api_rounded,
                    value: permissions['apiAccess'] ?? false,
                    onChanged: (val) => setDialogState(() => permissions['apiAccess'] = val),
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegistryRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TashilSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Metric Column inside Agency Directory Card
  Widget _buildAgencyStatColumn({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Official M3 Elevated Metric Card for Platform Stats
  Widget _buildAgencyMetricCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return TashilCard.elevated(
      elevation: 1.0,
      hoverElevation: 4.0,
      enableHoverAnimation: true,
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW 2: حساب الضامن وسجل التدقيق (Escrow & Audit Logs)
  // =========================================================================
  Widget _buildEscrowAndAuditView(AppLocalizations loc, bool isMobile, ColorScheme colorScheme) {
    final currentCountry = CountryController.currentCountry.value;
    final currency = currentCountry == 'AE' ? 'AED' : 'EGP';
    final langCode = loc.locale.languageCode;

    final formattedVaultBalance = CurrencyFormatter.formatPriceWithCurrency(
      amount: currentCountry == 'AE' ? 14200000 : 58450000,
      currencyCode: currency,
      langCode: langCode,
    );

    final auditLogs = [
      {
        'action': 'إيداع دفعة إيجار في حساب الضمان',
        'actor': 'نظام الدفع الإلكتروني (CBE)',
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 45000, currencyCode: currency, langCode: langCode),
        'time': 'منذ 12 دقيقة',
        'status': 'مؤمن ومشفر',
        'signature': 'SHA256:7f8a9b...',
      },
      {
        'action': 'صرف مستحقات المالك بعد مصادقة العقد',
        'actor': 'إدارة المنصة المركزية',
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 120000, currencyCode: currency, langCode: langCode),
        'time': 'منذ 45 دقيقة',
        'status': 'تم التحويل',
        'signature': 'SHA256:3c2e1f...',
      },
      {
        'action': 'تدقيق وتسوية إلكترونية آلية يومية',
        'actor': 'مراقب التدقيق الذكي',
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 58450000, currencyCode: currency, langCode: langCode),
        'time': 'منذ ساعتين',
        'status': 'مطابقة 100%',
        'signature': 'SHA256:0d9e8c...',
      },
      {
        'action': 'تأمين الوديعة التأمينية لوحدة سكنية',
        'actor': 'محفظة المستأجر الذكية',
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 15000, currencyCode: currency, langCode: langCode),
        'time': 'منذ 3 ساعات',
        'status': 'محتجز بالضمان',
        'signature': 'SHA256:4a5b6c...',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('escrowAndAuditLogsTab'),
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('certifiedEscrowSecuritySubtitle'),
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TashilButton(
                label: loc.tr('exportOfficialAuditStatementBtn'),
                icon: Icons.file_download_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.tr('auditStatementExportSuccess')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. 3 Escrow Hero Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isNarrow ? 1 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isNarrow ? 2.3 : 1.8,
                children: [
                  TashilCard.elevated(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.account_balance_rounded, size: 20, color: colorScheme.onPrimaryContainer),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CBE / CBUAE',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedVaultBalance,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                loc.tr('escrowVaultBalance'),
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  TashilCard.filled(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.security_rounded, size: 20, color: colorScheme.onSecondaryContainer),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '100% Secured',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '1,280',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                loc.tr('totalProtectedTransactions'),
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  TashilCard.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.vpn_key_rounded, size: 20, color: colorScheme.onTertiaryContainer),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SHA-256',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ISO/IEC 27001',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                loc.tr('complianceRate'),
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // 3. Audit Trail Table / List
          Text(
            loc.tr('auditLogTrail'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auditLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = auditLogs[index];
              return TashilCard.outlined(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.verified_user_rounded, size: 18, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log['action'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log['actor']} | ${log['signature']}',
                              style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            log['amount'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log['status'] as String,
                                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log['time'] as String,
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 3: معايير تصميم ماتيريال 3 (Material Design 3 Standards Hub)
  // =========================================================================
  Widget _buildDesignSystemHubView(AppLocalizations loc, bool isMobile, ColorScheme colorScheme) {
    final showcases = [
      {
        'title': 'M3 Buttons Suite',
        'desc': '10 Official M3 Button Types (Filled, Tonal, Outlined, FABs, Speed Dial)',
        'icon': Icons.touch_app_rounded,
        'action': () => M3ButtonsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Cards Suite',
        'desc': '3 Official M3 Card Types (Elevated, Filled, Outlined containers)',
        'icon': Icons.dashboard_customize_rounded,
        'action': () => M3CardsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Carousel Suite',
        'desc': 'Hero, Multi-Browse & Uncontained Carousels with mouse swipe',
        'icon': Icons.view_carousel_rounded,
        'action': () => M3CarouselShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Chips Suite',
        'desc': 'Assist, Filter, Input & Suggestion Chips with animated checkmarks',
        'icon': Icons.label_outline_rounded,
        'action': () => M3ChipsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Dialogs Suite',
        'desc': 'Alert, Modal & Selection Dialogs with 28dp radius and Level 3 elevation',
        'icon': Icons.ad_units_rounded,
        'action': () => M3DialogsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Dividers Suite',
        'desc': 'Full-width, cardAction, text-inset, and middle-inset dividers',
        'icon': Icons.horizontal_rule_rounded,
        'action': () => M3DividersShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Lists Suite',
        'desc': '1, 2, 3 line tiles and Reorderable Lists with floating Level 3 proxy',
        'icon': Icons.format_list_bulleted_rounded,
        'action': () => M3ListsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Loading Indicators',
        'desc': 'Organic 4-petal morphing clover with harmonic breathing pulse',
        'icon': Icons.refresh_rounded,
        'action': () => M3LoadingShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Navigation Drawer',
        'desc': 'Standard & Modal Drawers with 28dp pill destinations and badge counters',
        'icon': Icons.menu_open_rounded,
        'action': () => M3DrawerShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Navigation Rail',
        'desc': '80dp compact rail with 260dp smooth cubic animated drawer expansion',
        'icon': Icons.view_sidebar_rounded,
        'action': () => M3RailShowcaseDialog.show(context),
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.palette_rounded, color: colorScheme.onPrimary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('m3DesignSystemTab'),
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('m3ShowcaseSubtitle'),
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: showcases.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isNarrow ? 1 : (constraints.maxWidth < 1200 ? 2 : 3),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isNarrow ? 2.4 : 1.7,
                ),
                itemBuilder: (context, index) {
                  final item = showcases[index];
                  return TashilCard.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(item['icon'] as IconData, color: colorScheme.primary, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item['desc'] as String,
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TashilButton(
                              label: loc.tr('m3BtnShowcaseBtn'),
                              icon: Icons.launch_rounded,
                              onPressed: item['action'] as VoidCallback,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
