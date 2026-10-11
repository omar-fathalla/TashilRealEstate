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

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final String location = state.matchedLocation;
    final bool isPublicRoute = location == '/' || location == '/login' || location == '/valuation' || location == '/lease-builder' || location == '/rent-collection' || location == '/image-moderation' || location == '/investor-dashboard' || location == '/market-index' || location == '/fast-onboarding' || location == '/financial-dashboard' || location == '/checkout' || location == '/payment-schedule';

    if (!isLoggedIn && !isPublicRoute) {
      return '/login'; // Redirect unauthenticated users to login
    }
    
    return null;
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
      builder: (context, state) => const LeaseBuilderScreen(),
    ),
    GoRoute(
      path: '/rent-collection',
      builder: (context, state) => const RentCollectionScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const TenantCheckoutScreen(),
    ),
    GoRoute(
      path: '/payment-schedule',
      builder: (context, state) => const PaymentScheduleScreen(),
    ),
    GoRoute(
      path: '/image-moderation',
      builder: (context, state) => const ImageModerationScreen(),
    ),
    GoRoute(
      path: '/investor-dashboard',
      builder: (context, state) => const InvestorDashboardScreen(),
    ),
    GoRoute(
      path: '/market-index',
      builder: (context, state) => const MarketIndexScreen(),
    ),
    GoRoute(
      path: '/fast-onboarding',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return FastOnboardingScreen(
          initialDraft: extra?['initialDraft'] as FastPropertyDraft?,
          existingPropertyId: extra?['existingPropertyId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/financial-dashboard',
      builder: (context, state) => const FinancialKpiScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/super-admin',
      builder: (context, state) => const SuperAdminDashboard(),
    ),
    GoRoute(
      path: '/agency',
      builder: (context, state) => const AgencyDashboard(),
    ),
    GoRoute(
      path: '/owner',
      builder: (context, state) => const OwnerDashboard(),
    ),
    GoRoute(
      path: '/tenant',
      builder: (context, state) => const TenantDashboard(),
    ),
  ],
);
