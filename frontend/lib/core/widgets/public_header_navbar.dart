import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';
import 'package:tashil_real_estate/core/design_system/firebase_hub/firebase_enterprise_hub_dialog.dart';

class PublicHeaderNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSubPage;
  final String? currentRoute;

  const PublicHeaderNavbar({
    super.key,
    this.isSubPage = false,
    this.currentRoute,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  void _navigateSafely(BuildContext context, String targetRoute) {
    if (currentRoute == targetRoute) return;
    context.go(targetRoute);
  }


  String _getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'hi':
        return 'हिन्दी';
      default:
        return 'English';
    }
  }

  String _getSettingsTooltip(AppLocalizations loc) {
    final countryName = CountryController.isUAE ? loc.tr('country_ae') : loc.tr('country_eg');
    final langName = _getLanguageName(loc.locale.languageCode);
    return '${loc.tr('settings')} ($countryName • $langName)';
  }

  void _showMobileMenu(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.tr('appName'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TashilIconButton.close(
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const TashilDivider.fullWidth(),

                // Unified App Settings Tile (Country, Language, Theme & Fonts)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(
                    loc.tr('settings'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '${CountryController.isUAE ? loc.tr('country_ae') : loc.tr('country_eg')} • ${_getLanguageName(loc.locale.languageCode)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.pop(modalContext);
                    AppSettingsDialog.show(context);
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.cloud_done_rounded,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    loc.tr('firebaseHubTitle'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    loc.tr('firebaseHubSubtitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.pop(modalContext);
                    FirebaseEnterpriseHubDialog.show(context);
                  },
                ),
                const TashilDivider.fullWidth(),

                // Navigation List Tiles (Explore Units removed as requested)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.rocket_launch_rounded, color: colorScheme.primary),
                  title: Text(loc.tr('fastPropertyOnboardingTitle'), style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _navigateSafely(context, '/fast-onboarding');
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                  title: Text(loc.tr('aiValuationTitle'), style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.pop(modalContext);
                    SmartValuationDialog.show(context);
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.analytics_rounded, color: colorScheme.tertiary),
                  title: Text(
                    CountryController.isUAE ? loc.tr('dxbMarketIndexTitle') : loc.tr('aqarmapIndexTitle'),
                    style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _navigateSafely(context, '/market-index');
                  },
                ),


                const SizedBox(height: 16),

                // Full-width Smart Account / Login CTA
                _buildMobileAuthSection(context, loc, colorScheme, modalContext),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileAuthSection(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    BuildContext modalContext,
  ) {
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (ctx, snapshot) {
          final user = snapshot.data;
          if (user != null) {
            final info = _resolveUserInfo(user, loc);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        radius: 18,
                        child: Text(
                          info.initials,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              info.roleTitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TashilButton(
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(modalContext);
                    _navigateSafely(context, info.dashboardRoute);
                  },
                  icon: Icons.dashboard_rounded,
                  label: loc.tr('backToDashboard'),
                  height: 44,
                ),
                const SizedBox(height: 8),
                TashilButton.outlined(
                  width: double.infinity,
                  onPressed: () async {
                    Navigator.pop(modalContext);
                    await FirebaseAuthService().signOut();
                    if (context.mounted) {
                      _navigateSafely(context, '/');
                    }
                  },
                  icon: Icons.logout_rounded,
                  label: loc.tr('logout'),
                  customColor: colorScheme.error,
                  height: 44,
                ),
              ],
            );
          }

          return _buildMobileLoginButton(context, loc, modalContext);
        },
      );
    } catch (_) {
      return _buildMobileLoginButton(context, loc, modalContext);
    }
  }

  Widget _buildMobileLoginButton(
    BuildContext context,
    AppLocalizations loc,
    BuildContext modalContext,
  ) {
    return TashilButton(
      width: double.infinity,
      onPressed: () {
        Navigator.pop(modalContext);
        _navigateSafely(context, '/login');
      },
      icon: Icons.lock_person_outlined,
      label: loc.tr('portalLogin'),
      height: 44,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);

    return AppBar(
      backgroundColor: colorScheme.surfaceContainerLowest,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleSpacing: isMobile ? 8 : 16,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: InkWell(
        onTap: () => _navigateSafely(context, '/'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back Button on Subpages
              if (isSubPage) ...[
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
                  tooltip: loc.tr('browseAsVisitor'),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],

              // Tashil Brand Icon
              Container(
                padding: const EdgeInsets.all(7),
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

              // Brand Title & Slogan
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.tr('appName'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 15 : 18,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (!isMobile)
                      Text(
                        loc.tr('appSlogan'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isMobile) ...[
          // Mobile Mode: Settings Icon Button + Menu Hamburger
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TashilIconButton.tonal(
              icon: Icons.tune_rounded,
              size: 38,
              iconSize: 18,
              tooltip: _getSettingsTooltip(loc),
              onPressed: () => AppSettingsDialog.show(context),
            ),
          ),
          IconButton.filledTonal(
            icon: Icon(Icons.menu_rounded, color: colorScheme.onSurface),
            tooltip: loc.tr('smartServicesMenu'),
            onPressed: () => _showMobileMenu(context, loc),
          ),
          const SizedBox(width: 8),
        ] else ...[
          // Desktop & Tablet Mode: Official M3 Expressive Connected Button Group
          _buildDesktopConnectedActions(context, loc, colorScheme),
        ],
      ],
    );
  }

  Widget _buildDesktopConnectedActions(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          return _buildConnectedButtonGroup(context, loc, colorScheme, snapshot.data);
        },
      );
    } catch (_) {
      return _buildConnectedButtonGroup(context, loc, colorScheme, null);
    }
  }

  Widget _buildConnectedButtonGroup(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    User? user,
  ) {
    final isIndexActive = currentRoute == '/market-index';

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16),
      child: TashilConnectedIconButtonGroup(
        height: 42.0,
        items: [
          // 1. AI Smart Valuation Icon Button
          TashilConnectedIconItem(
            icon: Icons.auto_awesome_rounded,
            tooltip: loc.tr('aiValuationTitle'),
            onTap: () => SmartValuationDialog.show(context),
          ),

          // 2. Real Estate Market Index Icon Button
          TashilConnectedIconItem(
            icon: Icons.analytics_rounded,
            tooltip: CountryController.isUAE
                ? loc.tr('dxbMarketIndexTitle')
                : loc.tr('aqarmapIndexTitle'),
            isSelected: isIndexActive,
            onTap: () => _navigateSafely(context, '/market-index'),
          ),

          // 3. Unified App Settings Icon Button (Country, Language, Theme Palette & Font)
          TashilConnectedIconItem(
            icon: Icons.tune_rounded,
            tooltip: _getSettingsTooltip(loc),
            onTap: () => AppSettingsDialog.show(context),
          ),

          // 4. Portal Login / User Profile CTA
          if (user != null)
            TashilConnectedIconItem(
              customWidget: _buildUserDropdown(context, loc, user),
            )
          else
            TashilConnectedIconItem(
              icon: Icons.lock_person_outlined,
              tooltip: loc.tr('portalLogin'),
              isSelected: true,
              activeColor: colorScheme.primary,
              activeForegroundColor: colorScheme.onPrimary,
              onTap: () => _navigateSafely(context, '/login'),
            ),
        ],
      ),
    );
  }

  Widget _buildUserDropdown(
    BuildContext context,
    AppLocalizations loc,
    User user,
  ) {
    final info = _resolveUserInfo(user, loc);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<String>(
        tooltip: '${info.displayName} (${info.roleTitle})',
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surfaceContainerLowest,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        onSelected: (action) async {
          if (action == 'dashboard') {
            _navigateSafely(context, info.dashboardRoute);
          } else if (action == 'logout') {
            await FirebaseAuthService().signOut();
            if (context.mounted) {
              _navigateSafely(context, '/');
            }
          }
        },
        itemBuilder: (menuContext) => [
          // 1. Header Profile summary
          PopupMenuItem<String>(
            enabled: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    radius: 18,
                    child: Text(
                      info.initials,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          info.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.roleTitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuDivider(height: 1),

          // 2. Return to Dashboard
          PopupMenuItem<String>(
            value: 'dashboard',
            child: Row(
              children: [
                Icon(Icons.dashboard_rounded, color: colorScheme.onSurface, size: 18),
                const SizedBox(width: 10),
                Text(
                  loc.tr('backToDashboard'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuDivider(height: 1),

          // 3. Logout
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: colorScheme.error, size: 18),
                const SizedBox(width: 10),
                Text(
                  loc.tr('logout'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              info.initials,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
  }

  static _UserRoleInfo _resolveUserInfo(User user, AppLocalizations loc) {
    final email = (user.email ?? '').toLowerCase();

    if (email.contains('admin')) {
      final name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!
          : 'Super Admin';
      return _UserRoleInfo(
        displayName: name,
        roleTitle: loc.tr('roleSuperAdmin'),
        initials: UserAvatarUtils.getInitials(name, 'SA'),
        dashboardRoute: '/super-admin',
      );
    } else if (email.contains('agency') || email.contains('broker')) {
      final name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!
          : loc.tr('roleAgency');
      return _UserRoleInfo(
        displayName: name,
        roleTitle: loc.tr('roleAgency'),
        initials: UserAvatarUtils.getInitials(name, 'AG'),
        dashboardRoute: '/agency',
      );
    } else if (email.contains('tenant')) {
      final name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!
          : loc.tr('roleTenant');
      return _UserRoleInfo(
        displayName: name,
        roleTitle: loc.tr('roleTenant'),
        initials: UserAvatarUtils.getInitials(name, 'TN'),
        dashboardRoute: '/tenant',
      );
    } else {
      final name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!
          : loc.tr('ownerProfile');
      return _UserRoleInfo(
        displayName: name,
        roleTitle: loc.tr('ownerRoleTitle'),
        initials: UserAvatarUtils.getInitials(name, 'AF'),
        dashboardRoute: '/owner',
      );
    }
  }
}

class _UserRoleInfo {
  final String displayName;
  final String roleTitle;
  final String initials;
  final String dashboardRoute;

  const _UserRoleInfo({
    required this.displayName,
    required this.roleTitle,
    required this.initials,
    required this.dashboardRoute,
  });
}
