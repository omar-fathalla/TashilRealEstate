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
import 'package:tashil_real_estate/core/design_system/firebase_hub/firebase_enterprise_hub_dialog.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialog_frame.dart';

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
        'name': AppLocalizations.trStatic('uiCopy097'),
        'country': 'EG',
        'license': 'EG-REG-9824',
        'authority': AppLocalizations.trStatic('uiCopy151'),
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
        'name': AppLocalizations.trStatic('uiCopy128'),
        'country': 'AE',
        'license': 'AE-RERA-5510',
        'authority': AppLocalizations.trStatic('uiCopy273'),
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
        'name': AppLocalizations.trStatic('uiCopy156'),
        'country': 'EG',
        'license': 'EG-REG-4412',
        'authority': AppLocalizations.trStatic('uiCopy150'),
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
        'name': AppLocalizations.trStatic('uiCopy202'),
        'country': 'AE',
        'license': 'AE-RERA-8890',
        'authority': AppLocalizations.trStatic('uiCopy201'),
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
                  Symbols.admin_panel_settings_rounded,
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
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3),
                  ),
                  Text(
                    loc.tr('superAdminWorkspaceTitle'),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.primary,
                      fontWeight: FontWeight.w600),
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
                  _buildEmailVerificationBadge(context, loc, colorScheme),
                  const SizedBox(width: 8),
                  TashilIconButton.tonal(
                    icon: Symbols.smart_toy_rounded,
                    size: 38,
                    iconSize: 20,
                    tooltip: loc.tr('aiEngineModelsBtn'),
                    onPressed: () => setState(() => _selectedIndex = 6),
                  ),
                  const SizedBox(width: 8),
                  TashilButton.tonal(
                    icon: Symbols.hub_rounded,
                    label: loc.tr('googleAiHubBtn'),
                    onPressed: () => GoogleAiArchitectureHubDialog.show(context),
                  ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Symbols.shield_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('aiImageModeratorTitle'),
                onPressed: () => AiImageModeratorDialog.show(context),
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Symbols.tune_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('settings'),
                onPressed: () => AppSettingsDialog.show(context),
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Symbols.travel_explore_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('browseAsVisitor'),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              TashilIconButton.tonal(
                icon: Symbols.logout_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('logout'),
                onPressed: () async {
                  await FirebaseAuthService().signOut();
                  if (context.mounted) context.go('/admin/login');
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
          icon: Symbols.analytics_rounded,
          selectedIcon: Symbols.analytics_rounded,
          label: loc.tr('kpiCompact'),
          isSelected: _selectedIndex == 0,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        TashilRailDestination(
          icon: Symbols.business_rounded,
          selectedIcon: Symbols.business_rounded,
          label: loc.tr('agenciesCompact'),
          badgeCount: '48',
          isSelected: _selectedIndex == 1,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        TashilRailDestination(
          icon: Symbols.verified_user_rounded,
          selectedIcon: Symbols.verified_user_rounded,
          label: loc.tr('escrowCompact'),
          isSelected: _selectedIndex == 2,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        TashilRailDestination(
          icon: Symbols.payments_rounded,
          selectedIcon: Symbols.payments_rounded,
          label: loc.tr('rentCollectionTitle'),
          badgeCount: '3',
          isSelected: _selectedIndex == 4,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 4),
        ),
        TashilRailDestination(
          icon: Symbols.show_chart_rounded,
          selectedIcon: Symbols.show_chart_rounded,
          label: loc.tr('investorDashboardTitle'),
          isSelected: _selectedIndex == 5,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 5),
        ),
        TashilRailDestination(
          icon: Symbols.smart_toy_rounded,
          selectedIcon: Symbols.smart_toy_rounded,
          label: loc.tr('aiEngineHubNavTitle'),
          badgeCount: '6',
          isSelected: _selectedIndex == 6,
          isExpanded: isExpanded,
          onTap: () => setState(() => _selectedIndex = 6),
        ),
        TashilRailDestination(
          icon: Symbols.hub_rounded,
          selectedIcon: Symbols.hub_rounded,
          label: loc.tr('googleAiHubBtn'),
          isSelected: false,
          isExpanded: isExpanded,
          trailing: isExpanded
              ? Icon(
                  Symbols.chevron_right_rounded,
                  size: 18.0,
                  color: colorScheme.outlineVariant,
                )
              : null,
          onTap: () => GoogleAiArchitectureHubDialog.show(context),
        ),
        TashilRailDestination(
          icon: Symbols.shield_rounded,
          selectedIcon: Symbols.shield_rounded,
          label: loc.tr('aiImageModeratorTitle'),
          isSelected: false,
          isExpanded: isExpanded,
          trailing: isExpanded
              ? Icon(
                  Symbols.chevron_right_rounded,
                  size: 18.0,
                  color: colorScheme.outlineVariant,
                )
              : null,
          onTap: () => AiImageModeratorDialog.show(context),
        ),
        TashilRailDestination(
          icon: Symbols.tune_rounded,
          selectedIcon: Symbols.tune_rounded,
          label: loc.tr('settings'),
          isSelected: false,
          isExpanded: isExpanded,
          trailing: isExpanded
              ? Icon(
                  Symbols.chevron_right_rounded,
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
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer),
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
        return TashilDialogFrame(
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
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold),
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
                                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Symbols.verified_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                            Text(
                              loc.tr('roleSuperAdmin'),
                              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      TashilIconButton.standard(
                        icon: Symbols.close_rounded,
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
                    leading: Icon(Symbols.tune_rounded, size: 20, color: colorScheme.primary),
                    title: Text(
                      loc.tr('settings'),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: Icon(Symbols.chevron_right_rounded, size: 18, color: colorScheme.outlineVariant),
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      AppSettingsDialog.show(context);
                    },
                  ),

                  // Action 2: Audit Logs
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(Symbols.verified_user_rounded, size: 20, color: colorScheme.secondary),
                    title: Text(
                      loc.tr('escrowAndAuditLogsTab'),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: Icon(Symbols.chevron_right_rounded, size: 18, color: colorScheme.outlineVariant),
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
                      icon: Symbols.logout_rounded,
                      variant: TashilButtonVariant.outlined,
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop();
                        await FirebaseAuthService().signOut();
                        if (context.mounted) context.go('/admin/login');
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
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
            color: colorScheme.primary),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmailVerificationBadge(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    final isVerified = FirebaseAuthService().isCurrentUserEmailVerified;
    final badgeColor = isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final icon = isVerified ? Symbols.verified_user_rounded : Symbols.mark_email_unread_rounded;
    final label = isVerified ? loc.tr('emailVerifiedBadge') : loc.tr('emailPendingVerificationBadge');

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showEmailVerificationDialog(context, loc, isVerified),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600,
                color: badgeColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEmailVerificationDialog(
    BuildContext context,
    AppLocalizations loc,
    bool isVerified,
  ) async {
    final auth = FirebaseAuthService();
    if (isVerified) {
      await TashilAlertDialog.show(
        context: context,
        iconData: Symbols.verified_user_rounded,
        title: loc.tr('verifyEmailTitle'),
        contentText: loc.tr('emailVerifiedSuccess'),
        actions: [
          TashilButton.filled(
            label: loc.tr('close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    } else {
      bool isActionLoading = false;
      await showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return TashilAlertDialog(
              iconData: Symbols.mark_email_unread_rounded,
              title: loc.tr('verifyEmailTitle'),
              contentText: loc.tr('verifyEmailNotice'),
              actions: [
                TashilButton.text(
                  label: loc.tr('cancel'),
                  onPressed: isActionLoading ? null : () => Navigator.pop(dialogCtx),
                ),
                TashilButton.tonal(
                  label: loc.tr('resendVerificationBtn'),
                  icon: Symbols.send_rounded,
                  isLoading: isActionLoading,
                  onPressed: isActionLoading
                      ? null
                      : () async {
                          setDialogState(() => isActionLoading = true);
                          try {
                            await auth.sendEmailVerification();
                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);
                            TashilSnackBar.showSuccess(
                              context: context,
                              message: loc.tr('verifyEmailNotice'),
                            );
                          } catch (e) {
                            setDialogState(() => isActionLoading = false);
                            TashilSnackBar.showError(
                              context: context,
                              message: e.toString(),
                            );
                          }
                        },
                ),
                TashilButton.filled(
                  label: loc.tr('checkVerificationStatus'),
                  icon: Symbols.sync_rounded,
                  isLoading: isActionLoading,
                  onPressed: isActionLoading
                      ? null
                      : () async {
                          setDialogState(() => isActionLoading = true);
                          await auth.reloadCurrentUser();
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);
                          setState(() {});
                          if (auth.isCurrentUserEmailVerified) {
                            TashilSnackBar.showSuccess(
                              context: context,
                              message: loc.tr('emailVerifiedSuccess'),
                            );
                          } else {
                            TashilSnackBar.showWarning(
                              context: context,
                              message: loc.tr('emailNotYetVerified'),
                            );
                          }
                        },
                ),
              ],
            );
          },
        ),
      );
    }
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
            child: Icon(Symbols.admin_panel_settings_rounded, color: colorScheme.onPrimaryContainer, size: 18),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('appName'),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                color: colorScheme.onSurface),
            ),
            Text(
              loc.tr('superAdminWorkspaceTitle'),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.primary,
                fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          _buildEmailVerificationBadge(context, loc, colorScheme),
          const SizedBox(width: 4),
          TashilIconButton.tonal(
            icon: Symbols.tune_rounded,
            size: 38,
            iconSize: 20,
            tooltip: loc.tr('settings'),
            onPressed: () => AppSettingsDialog.show(context),
          ),
          if (!ResponsiveLayout.isMobile(context)) ...[
          const SizedBox(width: 4),
          Builder(
            builder: (ctx) => TashilIconButton.tonal(
              icon: Symbols.menu_rounded,
              size: 38,
              iconSize: 20,
              tooltip: loc.tr('menu'),
              onPressed: () => showModalBottomSheet<void>(
                context: ctx,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                builder: (sheetContext) => SizedBox(
                  height: MediaQuery.sizeOf(sheetContext).height * 0.8,
                  child: _buildMobileDrawer(sheetContext, loc, colorScheme),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ],
        ],
      ),
      endDrawer: null,
      body: views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (_selectedIndex) {
          0 => 0,
          1 => 1,
          2 => 2,
          _ => 3,
        },
        onDestinationSelected: (index) {
          if (index == 3) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (sheetContext) => SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.8,
                child: _buildMobileDrawer(sheetContext, loc, colorScheme),
              ),
            );
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.analytics_rounded),
            selectedIcon: const Icon(Symbols.analytics_rounded),
            label: loc.tr('kpiCompact'),
          ),
          NavigationDestination(
            icon: const Icon(Symbols.business_rounded),
            selectedIcon: const Icon(Symbols.business_rounded),
            label: loc.tr('agenciesCompact'),
          ),
          NavigationDestination(
            icon: const Icon(Symbols.verified_user_rounded),
            selectedIcon: const Icon(Symbols.verified_user_rounded),
            label: loc.tr('escrowCompact'),
          ),
          NavigationDestination(
            icon: const Icon(Symbols.menu_rounded),
            selectedIcon: const Icon(Symbols.menu_rounded),
            label: loc.tr('navMore'),
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
              child: Icon(Symbols.admin_panel_settings_rounded, color: colorScheme.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('appName'),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                  ),
                  Text(
                    loc.tr('superAdminWorkspaceTitle'),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.primary,
                      fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TashilIconButton.standard(
              icon: Symbols.close_rounded,
              size: 36,
              iconSize: 20,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      destinations: [
        TashilDrawerDestination(
          icon: Symbols.analytics_rounded,
          selectedIcon: Symbols.analytics_rounded,
          label: loc.tr('kpiCompact'),
          isSelected: _selectedIndex == 0,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 0);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.business_rounded,
          selectedIcon: Symbols.business_rounded,
          label: loc.tr('agenciesCompact'),
          badgeCount: '48',
          isSelected: _selectedIndex == 1,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 1);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.verified_user_rounded,
          selectedIcon: Symbols.verified_user_rounded,
          label: loc.tr('escrowCompact'),
          isSelected: _selectedIndex == 2,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 2);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.palette_rounded,
          selectedIcon: Symbols.palette_rounded,
          label: loc.tr('standardsCompact'),
          isSelected: _selectedIndex == 3,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 3);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.payments_rounded,
          selectedIcon: Symbols.payments_rounded,
          label: loc.tr('rentCollectionTitle'),
          badgeCount: '3',
          isSelected: _selectedIndex == 4,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 4);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.show_chart_rounded,
          selectedIcon: Symbols.show_chart_rounded,
          label: loc.tr('investorDashboardTitle'),
          isSelected: _selectedIndex == 5,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 5);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.smart_toy_rounded,
          selectedIcon: Symbols.smart_toy_rounded,
          label: loc.tr('aiEngineHubNavTitle'),
          badgeCount: '6',
          isSelected: _selectedIndex == 6,
          onTap: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 6);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.hub_rounded,
          selectedIcon: Symbols.hub_rounded,
          label: loc.tr('googleAiHubBtn'),
          isSelected: false,
          trailing: Icon(
            Symbols.chevron_right_rounded,
            size: 18.0,
            color: colorScheme.outlineVariant,
          ),
          onTap: () {
            Navigator.pop(context);
            GoogleAiArchitectureHubDialog.show(context);
          },
        ),
        TashilDrawerDestination(
          icon: Symbols.shield_rounded,
          selectedIcon: Symbols.shield_rounded,
          label: loc.tr('aiImageModeratorTitle'),
          isSelected: false,
          trailing: Icon(
            Symbols.chevron_right_rounded,
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
          icon: Symbols.tune_rounded,
          selectedIcon: Symbols.tune_rounded,
          label: loc.tr('settings'),
          isSelected: false,
          trailing: Icon(
            Symbols.chevron_right_rounded,
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
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeCount ${loc.tr('activeAgenciesWord')} | $totalUnits ${loc.tr('verifiedUnitsWord')}',
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TashilButton(
                label: loc.tr('addNewAgency'),
                icon: Symbols.add_business_rounded,
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
                    badgeColor: colorScheme.primary,
                    icon: Symbols.business_rounded,
                    colorScheme: colorScheme,
                  ),
                  _buildAgencyMetricCard(
                    title: '1,420',
                    subtitle: loc.tr('verifiedUnitsWord'),
                    badgeText: '98.5%',
                    badgeColor: colorScheme.primary,
                    icon: Symbols.apartment_rounded,
                    colorScheme: colorScheme,
                  ),
                  _buildAgencyMetricCard(
                    title: '142',
                    subtitle: loc.tr('activeBrokersWord'),
                    badgeText: '100%',
                    badgeColor: colorScheme.secondary,
                    icon: Symbols.badge_rounded,
                    colorScheme: colorScheme,
                  ),
                  _buildAgencyMetricCard(
                    title: '99.4%',
                    subtitle: loc.tr('complianceRate'),
                    badgeText: loc.tr('complianceUnderReview'),
                    badgeColor: colorScheme.tertiary,
                    icon: Symbols.verified_user_rounded,
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
                  icon: Symbols.domain_rounded,
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
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer),
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
                                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(isEg ? '🇪🇬' : '🇦🇪', style: Theme.of(context).textTheme.bodyMedium!),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Symbols.verified_rounded,
                                          size: 14,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          agency['license'] as String,
                                          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500),
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
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer),
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
                                    icon: Symbols.apartment_rounded,
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
                                    icon: Symbols.badge_rounded,
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
                                        color: agency['isSuspended'] == true ? colorScheme.tertiary : colorScheme.primary,
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
                                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: agency['isSuspended'] == true
                                              ? colorScheme.error
                                              : colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500),
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
                                    icon: Symbols.visibility_rounded,
                                    onPressed: () => _showAgencyRegistryDialog(context, agency, loc, colorScheme),
                                  ),
                                  const SizedBox(width: 6),
                                  TashilIconButton.standard(
                                    icon: Symbols.shield_rounded,
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
    final tradeLicenseController = TextEditingController();
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
            icon: Symbols.add_business_rounded,
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
                  icon: Symbols.check_circle_rounded,
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
                        if (selectedCountry == 'AE' && tradeLicenseController.text.trim().isNotEmpty)
                          'tradeLicense': tradeLicenseController.text.trim(),
                        'authority': selectedCountry == 'EG'
                            ? AppLocalizations.trStatic('uiCopy151')
                            : AppLocalizations.trStatic('uiCopy273'),
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
                          backgroundColor: colorScheme.primary,
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
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
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
                        prefixIcon: const Icon(Symbols.apartment_rounded),
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

                    TextFormField(
                      controller: licenseController,
                      decoration: InputDecoration(
                        labelText: selectedCountry == 'AE'
                            ? loc.tr('officeRegistrationNumberLabel')
                            : loc.tr('commercialLicenseLabel'),
                        hintText: loc.tr('commercialLicenseHint'),
                        prefixIcon: const Icon(Symbols.verified_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('requiredField') : null,
                    ),
                    if (selectedCountry == 'AE') ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: tradeLicenseController,
                        decoration: InputDecoration(
                          labelText: loc.tr('commercialLicenseLabel'),
                          hintText: loc.tr('commercialLicenseHint'),
                          prefixIcon: const Icon(Symbols.badge_rounded),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Plan Selector
                    Text(
                      loc.tr('subscriptionPlanLabel'),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    TashilConnectedButtonGroup<String>(
                      selectedValue: selectedPlan,
                      onSelectionChanged: (val) => setDialogState(() => selectedPlan = val),
                      segments: [
                        TashilConnectedButtonSegment<String>(
                          value: 'Enterprise',
                          label: loc.tr('planEnterprise'),
                          icon: Symbols.star_rounded,
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
                              prefixIcon: const Icon(Symbols.badge_rounded),
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
                              prefixIcon: const Icon(Symbols.domain_rounded),
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
                              hintText: AppLocalizations.trStatic('uiCopy085'),
                              prefixIcon: const Icon(Symbols.email_rounded),
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
                              prefixIcon: const Icon(Symbols.phone_rounded),
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
        subtitle: isEg
            ? '${loc.tr('commercialLicenseLabel')}: ${agency['license']}'
            : '${loc.tr('officeRegistrationNumberLabel')}: ${agency['license']}',
        icon: Symbols.verified_user_rounded,
        onClose: () => Navigator.of(ctx).pop(),
        footer: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TashilButton.outlined(
              label: loc.tr('exportOfficialAuditStatementBtn'),
              icon: Symbols.download_rounded,
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
              icon: Symbols.check_rounded,
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
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
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
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                                  color: isSuspended ? colorScheme.error : colorScheme.primary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  agency['plan'] as String,
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isEg ? 'جمهورية مصر العربية' : AppLocalizations.trStatic('uiCopy209'),
                            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
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
                        icon: Symbols.account_balance_rounded,
                        label: loc.tr('regulatoryAuthority'),
                        value: agency['authority'] as String? ?? (isEg ? AppLocalizations.trStatic('uiCopy325') : 'مؤسسة التنظيم العقاري (RERA)'),
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 16),
                      _buildRegistryRow(
                        icon: Symbols.verified_rounded,
                        label: loc.tr('auditComplianceLevel'),
                        value: loc.tr('complianceUnderReview'),
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 16),
                      _buildRegistryRow(
                        icon: Symbols.calendar_today_rounded,
                        label: loc.tr('accreditationDate'),
                        value: agency['accreditationDate'] as String? ?? '2023-01-15',
                        colorScheme: colorScheme,
                      ),
                      const Divider(height: 16),
                      _buildRegistryRow(
                        icon: Symbols.update_rounded,
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
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${agency['units']}',
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
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
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${agency['brokers']}',
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
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
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '100%',
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
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
                          Icon(Symbols.email_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            agency['email'] as String? ?? 'info@agency.com',
                            style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.phone_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            agency['phone'] as String? ?? '+20 2 0000 0000',
                            style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
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
            icon: Symbols.shield_rounded,
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
                  icon: Symbols.save_rounded,
                  onPressed: () {
                    setState(() {
                      agency['permissions'] = permissions;
                      agency['isSuspended'] = isSuspended;
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('permissionsUpdatedSuccess')),
                        backgroundColor: colorScheme.primary,
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
                          isSuspended ? Symbols.block_rounded : Symbols.check_circle_rounded,
                          color: isSuspended ? colorScheme.error : colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSuspended ? loc.tr('agencySuspendedWarning') : loc.tr('verifiedAgency'),
                                style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                                  color: isSuspended ? colorScheme.error : colorScheme.onSurface),
                              ),
                              Text(
                                isSuspended
                                    ? AppLocalizations.trStatic('uiCopy125')
                                    : AppLocalizations.trStatic('uiCopy126'),
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
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
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),

                  _buildPermissionSwitchTile(
                    title: loc.tr('permVerifiedBadge'),
                    subtitle: AppLocalizations.trStatic('uiCopy095'),
                    icon: Symbols.verified_rounded,
                    value: permissions['verifiedBadge'] ?? true,
                    onChanged: (val) => setDialogState(() => permissions['verifiedBadge'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permDirectContracts'),
                    subtitle: AppLocalizations.trStatic('uiCopy182'),
                    icon: Symbols.description_rounded,
                    value: permissions['directContracts'] ?? true,
                    onChanged: (val) => setDialogState(() => permissions['directContracts'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permEscrowAccess'),
                    subtitle: AppLocalizations.trStatic('uiCopy129'),
                    icon: Symbols.shield_rounded,
                    value: permissions['escrowAccess'] ?? false,
                    onChanged: (val) => setDialogState(() => permissions['escrowAccess'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permMultiBranch'),
                    subtitle: AppLocalizations.trStatic('uiCopy133'),
                    icon: Symbols.corporate_fare_rounded,
                    value: permissions['multiBranch'] ?? true,
                    onChanged: (val) => setDialogState(() => permissions['multiBranch'] = val),
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 12),
                  _buildPermissionSwitchTile(
                    title: loc.tr('permApiAccess'),
                    subtitle: AppLocalizations.trStatic('uiCopy305'),
                    icon: Symbols.api_rounded,
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
          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
              color: colorScheme.onSurface),
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
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
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
                style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500),
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
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                      color: badgeColor,
                      letterSpacing: 0.2),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant),
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
        'action': AppLocalizations.trStatic('uiCopy103'),
        'actor': AppLocalizations.trStatic('uiCopy320'),
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 45000, currencyCode: currency, langCode: langCode),
        'time': AppLocalizations.trStatic('uiCopy306'),
        'status': AppLocalizations.trStatic('uiCopy274'),
        'signature': 'SHA256:7f8a9b...',
      },
      {
        'action': AppLocalizations.trStatic('uiCopy237'),
        'actor': AppLocalizations.trStatic('uiCopy092'),
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 120000, currencyCode: currency, langCode: langCode),
        'time': AppLocalizations.trStatic('uiCopy308'),
        'status': AppLocalizations.trStatic('uiCopy178'),
        'signature': 'SHA256:3c2e1f...',
      },
      {
        'action': AppLocalizations.trStatic('uiCopy170'),
        'actor': AppLocalizations.trStatic('uiCopy284'),
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 58450000, currencyCode: currency, langCode: langCode),
        'time': AppLocalizations.trStatic('uiCopy309'),
        'status': AppLocalizations.trStatic('uiCopy294'),
        'signature': 'SHA256:0d9e8c...',
      },
      {
        'action': AppLocalizations.trStatic('uiCopy165'),
        'actor': AppLocalizations.trStatic('uiCopy279'),
        'amount': CurrencyFormatter.formatPriceWithCurrency(amount: 15000, currencyCode: currency, langCode: langCode),
        'time': AppLocalizations.trStatic('uiCopy307'),
        'status': AppLocalizations.trStatic('uiCopy278'),
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
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('certifiedEscrowSecuritySubtitle'),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TashilButton(
                label: loc.tr('exportOfficialAuditStatementBtn'),
                icon: Symbols.file_download_rounded,
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
                                child: Icon(Symbols.account_balance_rounded, size: 20, color: colorScheme.onPrimaryContainer),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'CBE / CBUAE',
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedVaultBalance,
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                loc.tr('escrowVaultBalance'),
                                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
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
                                child: Icon(Symbols.security_rounded, size: 20, color: colorScheme.onSecondaryContainer),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '100% Secured',
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1,280',
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                loc.tr('totalProtectedTransactions'),
                                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
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
                                child: Icon(Symbols.vpn_key_rounded, size: 20, color: colorScheme.onTertiaryContainer),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SHA-256',
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ISO/IEC 27001',
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                loc.tr('complianceRate'),
                                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
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
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
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
                        child: Icon(Symbols.verified_user_rounded, size: 18, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log['action'] as String,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log['actor']} | ${log['signature']}',
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            log['amount'] as String,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log['status'] as String,
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log['time'] as String,
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
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
        'icon': Symbols.touch_app_rounded,
        'action': () => M3ButtonsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Cards Suite',
        'desc': '3 Official M3 Card Types (Elevated, Filled, Outlined containers)',
        'icon': Symbols.dashboard_customize_rounded,
        'action': () => M3CardsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Carousel Suite',
        'desc': 'Hero, Multi-Browse & Uncontained Carousels with mouse swipe',
        'icon': Symbols.view_carousel_rounded,
        'action': () => M3CarouselShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Chips Suite',
        'desc': 'Assist, Filter, Input & Suggestion Chips with animated checkmarks',
        'icon': Symbols.label_outline_rounded,
        'action': () => M3ChipsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Dialogs Suite',
        'desc': 'Alert, Modal & Selection Dialogs with 28dp radius and Level 3 elevation',
        'icon': Symbols.ad_units_rounded,
        'action': () => M3DialogsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Dividers Suite',
        'desc': 'Full-width, cardAction, text-inset, and middle-inset dividers',
        'icon': Symbols.horizontal_rule_rounded,
        'action': () => M3DividersShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Lists Suite',
        'desc': '1, 2, 3 line tiles and Reorderable Lists with floating Level 3 proxy',
        'icon': Symbols.format_list_bulleted_rounded,
        'action': () => M3ListsShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Loading Indicators',
        'desc': 'Organic 4-petal morphing clover with harmonic breathing pulse',
        'icon': Symbols.refresh_rounded,
        'action': () => M3LoadingShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Navigation Drawer',
        'desc': 'Standard & Modal Drawers with 28dp pill destinations and badge counters',
        'icon': Symbols.menu_open_rounded,
        'action': () => M3DrawerShowcaseDialog.show(context),
      },
      {
        'title': 'M3 Navigation Rail',
        'desc': '80dp compact rail with 260dp smooth cubic animated drawer expansion',
        'icon': Symbols.view_sidebar_rounded,
        'action': () => M3RailShowcaseDialog.show(context),
      },
      {
        'title': 'Firebase Enterprise Hub',
        'desc': 'App Check, Cloud Messaging, Remote Config, Performance, and Invoicing Live Hub',
        'icon': Symbols.cloud_done_rounded,
        'action': () => FirebaseEnterpriseHubDialog.show(context),
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
                child: Icon(Symbols.palette_rounded, color: colorScheme.onPrimary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('m3DesignSystemTab'),
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('m3ShowcaseSubtitle'),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
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
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item['desc'] as String,
                            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: TashilButton(
                              label: loc.tr('m3BtnShowcaseBtn'),
                              icon: Symbols.launch_rounded,
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
