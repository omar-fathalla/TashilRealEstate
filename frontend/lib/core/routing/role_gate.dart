import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading_indicator.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';

/// Second layer behind the router redirect: renders [child] only when the
/// session's trusted role is allowed on [route] by [RouteAccess].
class RoleGate extends StatelessWidget {
  final String route;
  final Widget child;
  final RoleSession? session;

  const RoleGate({super.key, required this.route, required this.child, this.session});

  @override
  Widget build(BuildContext context) {
    final roleSession = session ?? RoleSession.instance;
    return ListenableBuilder(
      listenable: roleSession,
      builder: (context, _) {
        if (!RouteAccess.isProtected(route)) return child;
        switch (roleSession.status) {
          case RoleSessionStatus.loading:
            return const RoleCheckingView();
          case RoleSessionStatus.signedOut:
            return AccessDeniedView(homeRoute: RouteAccess.homeFor(''));
          case RoleSessionStatus.signedIn:
            return RouteAccess.canAccess(route, roleSession.role)
                ? child
                : AccessDeniedView(homeRoute: RouteAccess.homeFor(roleSession.role));
        }
      },
    );
  }
}

/// Shown while the user's role (ID-token claims) is being resolved.
class RoleCheckingView extends StatelessWidget {
  const RoleCheckingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TashilLoadingIndicator.large(semanticLabel: loc.tr('checkingAccess')),
                const SizedBox(height: 24),
                Text(
                  loc.tr('checkingAccess'),
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AccessDeniedView extends StatelessWidget {
  final String homeRoute;

  const AccessDeniedView({super.key, required this.homeRoute});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      loc.tr('accessDeniedTitle'),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.tr('accessDeniedMessage'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TashilButton.filled(
                      icon: Icons.home_rounded,
                      label: loc.tr('goToMyHome'),
                      onPressed: () => context.go(homeRoute),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
