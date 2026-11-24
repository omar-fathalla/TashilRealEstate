import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/auth/role_session.dart';
import 'package:tashil_real_estate/core/routing/role_gate.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';
import 'package:tashil_real_estate/features/public_marketplace/public_marketplace_screen.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_dashboard.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_dashboard.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';
import 'package:tashil_real_estate/features/tenant_portal/tenant_dashboard.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_screen.dart';
import 'package:tashil_real_estate/features/lease_builder/lease_builder_screen.dart';
import 'package:tashil_real_estate/features/rent_collection/rent_collection_screen.dart';
import 'package:tashil_real_estate/features/image_moderation/image_moderation_screen.dart';
import 'package:tashil_real_estate/features/investor_dashboard/investor_dashboard_screen.dart';
import 'package:tashil_real_estate/features/market_index/market_index_screen.dart';
import 'package:tashil_real_estate/features/fast_onboarding/fast_onboarding_screen.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/financial_kpi_screen.dart';
import 'package:tashil_real_estate/features/rent_collection/tenant_checkout_screen.dart';
import 'package:tashil_real_estate/features/owner_portal/payment_schedule_screen.dart';

/// Decides where a navigation to [uri] should go, using [RouteAccess]:
/// - protected routes wait on `/auth-check` while the role is still loading,
/// - signed-out users go to `/login?redirect=<route>`,
/// - signed-in users without an allowed role go to their own home.
/// Returns null to allow the navigation.
String? guardRedirect(Uri uri, RoleSessionStatus status, String role) {
  final path = uri.path.isEmpty ? '/' : uri.path;

  if (path == RouteAccess.authCheck) {
    if (status == RoleSessionStatus.loading) return null;
    final from = Uri.tryParse(uri.queryParameters['from'] ?? '');
    final safe = from != null &&
        !from.hasScheme &&
        !from.hasAuthority &&
        from.path.startsWith('/') &&
        from.path != RouteAccess.authCheck;
    final target = safe ? from : Uri(path: '/');
    return guardRedirect(target, status, role) ?? target.toString();
  }

  if (!RouteAccess.isProtected(path)) return null;
  switch (status) {
    case RoleSessionStatus.loading:
      return Uri(path: RouteAccess.authCheck, queryParameters: {'from': uri.toString()}).toString();
    case RoleSessionStatus.signedOut:
      return Uri(path: RouteAccess.login, queryParameters: {'redirect': uri.toString()}).toString();
    case RoleSessionStatus.signedIn:
      return RouteAccess.canAccess(path, role) ? null : RouteAccess.homeFor(role);
  }
}

GoRouter buildAppRouter({
  required RoleSession session,
  String initialLocation = '/',
  /// Replaces a route's screen in tests; return null to keep the real one.
  @visibleForTesting Widget? Function(String route)? screenOverride,
}) {
  GoRoute route(String path, Widget Function(GoRouterState state) screen) {
    return GoRoute(
      path: path,
      builder: (context, state) {
        final page = screenOverride?.call(path) ?? screen(state);
        return RouteAccess.isProtected(path) ? RoleGate(route: path, session: session, child: page) : page;
      },
    );
  }

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (context, state) => guardRedirect(state.uri, session.status, session.role),
    routes: [
      route('/', (_) => const PublicMarketplaceScreen()),
      route('/valuation', (_) => const SmartValuationScreen()),
      route('/lease-builder', (_) => const LeaseBuilderScreen()),
      route('/rent-collection', (_) => const RentCollectionScreen()),
      route('/checkout', (state) => TenantCheckoutScreen(invoiceId: state.uri.queryParameters['invoice'])),
      route('/payment-schedule', (state) => PaymentScheduleScreen(propertyId: state.uri.queryParameters['property'])),
      route('/image-moderation', (_) => const ImageModerationScreen()),
      route('/investor-dashboard', (_) => const InvestorDashboardScreen()),
      route('/market-index', (_) => const MarketIndexScreen()),
      route('/fast-onboarding', (state) {
        final extra = state.extra as Map<String, dynamic>?;
        return FastOnboardingScreen(
          initialDraft: extra?['initialDraft'] as FastPropertyDraft?,
          existingPropertyId: extra?['existingPropertyId'] as String?,
        );
      }),
      route('/financial-dashboard', (_) => const FinancialKpiScreen()),
      route(RouteAccess.login, (_) => const LoginScreen()),
      route(RouteAccess.authCheck, (_) => const RoleCheckingView()),
      route('/super-admin', (_) => const SuperAdminDashboard()),
      route('/agency', (_) => const AgencyDashboard()),
      route('/owner', (_) => const OwnerDashboard()),
      route('/tenant', (_) => const TenantDashboard()),
    ],
  );
}

final GoRouter appRouter = buildAppRouter(session: RoleSession.instance);
