import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:tashil_real_estate/features/super_admin/super_admin_login_screen.dart';
import 'package:tashil_real_estate/features/auth/views/email_action_handler_screen.dart';
import 'package:tashil_real_estate/core/routing/not_found_screen.dart';
import 'package:tashil_real_estate/core/routing/role_gate.dart';
import 'package:tashil_real_estate/core/routing/route_access.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';

bool _isLoggedIn() {
  try {
    return FirebaseAuth.instance.currentUser != null;
  } catch (_) {
    return false;
  }
}

String? _signedInRole() {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final profile = UserProfileService().profileNotifier.value;
    if (!UserProfileService().roleConfirmed.value || profile.uid != user.uid) {
      return null;
    }
    return profile.role;
  } catch (_) {
    return null;
  }
}

bool _roleKnown() {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final profile = UserProfileService().profileNotifier.value;
    return UserProfileService().roleConfirmed.value && profile.uid == user.uid;
  } catch (_) {
    return false;
  }
}

GoRouter createAppRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  errorBuilder: (context, state) => const NotFoundScreen(),
  redirect: (context, state) {
    final location = state.matchedLocation;
    return RouteAccess.redirect(
      isLoggedIn: _isLoggedIn(),
      role: _signedInRole(),
      roleKnown: _roleKnown(),
      location: location,
    );
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PublicMarketplaceScreen(),
    ),
    GoRoute(
      path: '/valuation',
      builder: (context, state) => const SmartValuationScreen(),
    ),
    GoRoute(
      path: '/lease-builder',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Owner', 'AgencyAdmin', 'SuperAdmin'},
        child: LeaseBuilderScreen(),
      ),
    ),
    GoRoute(
      path: '/rent-collection',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Owner', 'AgencyAdmin', 'SuperAdmin'},
        child: RentCollectionScreen(),
      ),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Tenant', 'Owner', 'AgencyAdmin', 'SuperAdmin'},
        child: TenantCheckoutScreen(),
      ),
    ),
    GoRoute(
      path: '/payment-schedule',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Owner', 'AgencyAdmin', 'SuperAdmin'},
        child: PaymentScheduleScreen(),
      ),
    ),
    GoRoute(
      path: '/image-moderation',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Owner', 'AgencyAdmin', 'SuperAdmin'},
        child: ImageModerationScreen(),
      ),
    ),
    GoRoute(
      path: '/investor-dashboard',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Owner', 'AgencyAdmin', 'SuperAdmin', 'Investor'},
        child: InvestorDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/market-index',
      builder: (context, state) => const MarketIndexScreen(),
    ),
    GoRoute(
      path: '/fast-onboarding',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RoleGate(
          allowedRoles: const {'Owner', 'AgencyAdmin', 'SuperAdmin'},
          child: FastOnboardingScreen(
            initialDraft: extra?['initialDraft'] as FastPropertyDraft?,
            existingPropertyId: extra?['existingPropertyId'] as String?,
          ),
        );
      },
    ),
    GoRoute(
      path: '/financial-dashboard',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Owner', 'AgencyAdmin', 'SuperAdmin'},
        child: FinancialKpiScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'SuperAdmin'},
        child: SuperAdminDashboard(),
      ),
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const SuperAdminLoginScreen(),
    ),
    GoRoute(
      path: '/super-admin',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'SuperAdmin'},
        child: SuperAdminDashboard(),
      ),
    ),
    GoRoute(
      path: '/agency',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'AgencyAdmin', 'SuperAdmin'},
        child: AgencyDashboard(),
      ),
    ),
    GoRoute(
      path: '/owner',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Owner', 'SuperAdmin'},
        child: OwnerDashboard(),
      ),
    ),
    GoRoute(
      path: '/tenant',
      builder: (context, state) => const RoleGate(
        allowedRoles: {'Tenant', 'SuperAdmin'},
        child: TenantDashboard(),
      ),
    ),
    GoRoute(
      path: '/auth/action',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'verifyEmail';
        final oobCode = state.uri.queryParameters['oobCode'] ?? '';
        final apiKey = state.uri.queryParameters['apiKey'];
        return EmailActionHandlerScreen(
          mode: mode,
          oobCode: oobCode,
          apiKey: apiKey,
        );
      },
    ),
    GoRoute(
      path: '/auth/verify',
      redirect: (context, state) {
        final oobCode = state.uri.queryParameters['oobCode'] ?? '';
        return '/auth/action?mode=verifyEmail&oobCode=$oobCode';
      },
    ),
  ],
);

final GoRouter appRouter = createAppRouter(initialLocation: '/');
final GoRouter superAdminAppRouter = createAppRouter(initialLocation: '/admin');

