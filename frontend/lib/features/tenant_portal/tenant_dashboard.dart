import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/language_switcher.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/design_system/navigation_rail/tashil_navigation_rail.dart';
import 'package:tashil_real_estate/core/layout/m3_content_boundary.dart';
import 'package:tashil_real_estate/core/layout/m3_spacing.dart';
import 'views/tenant_home_view.dart';
import 'views/tenant_payments_view.dart';
import 'views/tenant_support_view.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Widget> _views = const [
    TenantHomeView(),
    TenantPaymentsView(),
    TenantSupportView(),
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
            final colorScheme = Theme.of(context).colorScheme;

            return ResponsiveLayout(
              mobileBody: _buildMobileLayout(context, loc, colorScheme),
              tabletBody: _buildDesktopLayout(context, loc, colorScheme, isTablet: true),
              desktopBody: _buildDesktopLayout(context, loc, colorScheme, isTablet: false),
            );
          },
        );
      },
    );
  }

  /// Mobile Layout: Standard M3 Top AppBar + Bottom Navigation Bar
  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_pin_rounded, color: colorScheme.onPrimary, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              loc.tr('tenant'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
            ),
          ],
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.travel_explore),
          tooltip: loc.tr('browseAsVisitor'),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: loc.tr('settings'),
            onPressed: () => AppSettingsDialog.show(context),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.onSurfaceVariant),
            tooltip: loc.tr('logout'),
            onPressed: () async {
              await FirebaseAuthService().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: loc.tr('navOverview'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.payment_outlined),
            selectedIcon: const Icon(Icons.payment),
            label: loc.tr('navFinancials'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.handyman_outlined),
            selectedIcon: const Icon(Icons.handyman),
            label: loc.tr('navMaintenance'),
          ),
        ],
      ),
    );
  }

  /// Desktop/Tablet Layout: Official M3 Stage 2 Adaptive Navigation with TashilScaffoldCanvas and TashilNavigationRail
  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme, {
    required bool isTablet,
  }) {
    final bool isExpanded = !isTablet && !_isSidebarCollapsed;

    return TashilScaffoldCanvas(
      header: _buildDesktopTopHeader(context, loc, colorScheme, isTablet: isTablet),
      navigationRail: TashilNavigationRail(
        isExpanded: isExpanded,
        onToggleExpanded: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
        menuTooltip: isExpanded ? loc.tr('collapseMenu') : loc.tr('expandMenu'),
        destinations: [
          TashilRailDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: loc.tr('navOverview'),
            isSelected: _selectedIndex == 0,
            isExpanded: isExpanded,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          TashilRailDestination(
            icon: Icons.payment_outlined,
            selectedIcon: Icons.payment_rounded,
            label: loc.tr('navFinancials'),
            isSelected: _selectedIndex == 1,
            isExpanded: isExpanded,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          TashilRailDestination(
            icon: Icons.handyman_outlined,
            selectedIcon: Icons.handyman_rounded,
            label: loc.tr('navMaintenance'),
            isSelected: _selectedIndex == 2,
            isExpanded: isExpanded,
            onTap: () => setState(() => _selectedIndex = 2),
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
      ),
      body: M3ContentBoundary(
        maxWidth: M3ContentBoundary.standardMaxWidth,
        padding: M3Spacing.pSm,
        child: _views[_selectedIndex],
      ),
    );
  }

  /// Full-Width Persistent Top Header (64dp) for Desktop & Tablet
  Widget _buildDesktopTopHeader(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme, {
    required bool isTablet,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: colorScheme.surfaceContainerLowest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Start: Brand Identity (Logo & Tenant Indicator)
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
                  Icons.person_pin_rounded,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    loc.tr('tenant'),
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

          // End: Quick Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.travel_explore),
                tooltip: loc.tr('browseAsVisitor'),
                onPressed: () => context.go('/'),
              ),
              if (!isTablet) ...[
                const SizedBox(width: 8),
                const LanguageSwitcher(isCompact: true, showLabel: false),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: loc.tr('settings'),
                onPressed: () => AppSettingsDialog.show(context),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.logout, color: colorScheme.error),
                tooltip: loc.tr('logout'),
                onPressed: () async {
                  await FirebaseAuthService().signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
