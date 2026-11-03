import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';
import 'package:material_symbols_icons/symbols.dart';

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


  Widget _buildMobileCircularLoginButton(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user != null) {
            final info = _resolveUserInfo(user, loc);
            return PopupMenuButton<String>(
              tooltip: '${info.displayName} (${info.roleTitle})',
              offset: const Offset(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              color: colorScheme.surfaceContainerLowest,
              elevation: 6,
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
                PopupMenuItem<String>(
                  value: 'dashboard',
                  child: Row(
                    children: [
                      Icon(Symbols.dashboard_rounded, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(loc.tr('backToDashboard'), style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Symbols.logout_rounded, size: 18, color: colorScheme.error),
                      const SizedBox(width: 10),
                      Text(loc.tr('logout'), style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600, color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                  border: Border.all(color: colorScheme.outlineVariant, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  info.initials,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          return TashilIconButton.tonal(
            icon: Symbols.lock_person_rounded,
            size: 38,
            iconSize: 19,
            tooltip: loc.tr('portalLogin'),
            onPressed: () => _navigateSafely(context, '/login'),
          );
        },
      );
    } catch (_) {
      return TashilIconButton.tonal(
        icon: Symbols.lock_person_rounded,
        size: 38,
        iconSize: 19,
        tooltip: loc.tr('portalLogin'),
        onPressed: () => _navigateSafely(context, '/login'),
      );
    }
  }

  Widget _buildMobileAppBarContent(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // PHYSICAL LEFT: Brand Icon + English "Tashil Aqar"
            InkWell(
              onTap: () => _navigateSafely(context, '/'),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSubPage) ...[
                    IconButton(
                      icon: Icon(Symbols.arrow_back_rounded, color: colorScheme.onSurface),
                      tooltip: loc.tr('browseAsVisitor'),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const SizedBox(width: 2),
                  ],
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Symbols.apartment_rounded,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tashil Aqar',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3),
                  ),
                ],
              ),
            ),

            // PHYSICAL RIGHT: Circular Login / Account Button Only
            _buildMobileCircularLoginButton(context, loc, colorScheme),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: _buildMobileAppBarContent(context, loc, colorScheme),
      );
    }

    return AppBar(
      backgroundColor: colorScheme.surfaceContainerLowest,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      titleSpacing: 16,
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
                  icon: Icon(Symbols.arrow_back_rounded, color: colorScheme.onSurface),
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
                  Symbols.apartment_rounded,
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
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5),
                    ),
                    Text(
                      loc.tr('appSlogan'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Desktop & Tablet Mode: Official M3 Expressive Connected Button Group
        _buildDesktopConnectedActions(context, loc, colorScheme),
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
            icon: Symbols.auto_awesome_rounded,
            tooltip: loc.tr('aiValuationTitle'),
            onTap: () => SmartValuationDialog.show(context),
          ),

          // 2. Real Estate Market Index Icon Button
          TashilConnectedIconItem(
            icon: Symbols.analytics_rounded,
            tooltip: CountryController.isUAE
                ? loc.tr('dxbMarketIndexTitle')
                : loc.tr('aqarmapIndexTitle'),
            isSelected: isIndexActive,
            onTap: () => _navigateSafely(context, '/market-index'),
          ),

          // 3. Unified App Settings Icon Button (Country, Language, Theme Palette & Font)
          TashilConnectedIconItem(
            icon: Symbols.tune_rounded,
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
              icon: Symbols.lock_person_rounded,
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
        shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
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
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold),
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
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.roleTitle,
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.primary,
                            fontWeight: FontWeight.w600),
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
                Icon(Symbols.dashboard_rounded, color: colorScheme.onSurface, size: 18),
                const SizedBox(width: 10),
                Text(
                  loc.tr('backToDashboard'),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
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
                Icon(Symbols.logout_rounded, color: colorScheme.error, size: 18),
                const SizedBox(width: 10),
                Text(
                  loc.tr('logout'),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,
                    color: colorScheme.error),
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
              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold),
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
