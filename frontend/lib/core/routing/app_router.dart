import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/features/auth/login_screen.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_dashboard.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_dashboard.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';
import 'package:tashil_real_estate/features/tenant_portal/tenant_dashboard.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isLoggingIn = state.matchedLocation == '/';

    if (!isLoggedIn && !isLoggingIn) {
      return '/'; // Redirect unauthenticated users to login
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
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
