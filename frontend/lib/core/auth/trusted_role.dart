import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';

/// The role the app may act on. Mirrors currentRole() in firestore.rules and
/// resolveRole() in backend/authz.js: an ID-token custom claim (set only by the
/// setUserRole function) wins, and the Users profile is trusted only for the
/// self-service roles. Server rules remain the real enforcement.
class TrustedRole {
  TrustedRole._();

  static const String superAdmin = 'SuperAdmin';

  /// Platform staff with fewer permissions than [superAdmin]: moderates listings and handles
  /// escalations. Only ever granted as a custom claim by a SuperAdmin.
  static const String admin = 'Admin';
  static const String agencyAdmin = 'AgencyAdmin';

  /// Agency staff (TAQ-169): works the agency's leases, rent rows, requests and maintenance, but
  /// cannot decide applications, create leases or record payments. Granted only as a custom
  /// claim when the user accepts an AgencyAdmin's invite.
  static const String agencyAgent = 'AgencyAgent';
  static const String owner = 'Owner';
  static const String tenant = 'Tenant';

  /// Browses, saves and compares listings and uses the market and AI tools. Self-service at
  /// signup like [owner] and [tenant]; it never grants publishing or lease access.
  static const String investor = 'Investor';

  static const Set<String> selfServiceRoles = {owner, tenant, investor};
  static const Set<String> all = {superAdmin, admin, agencyAdmin, agencyAgent, owner, tenant, investor};

  /// Returns one of [all], or '' when neither source grants a role.
  static String fromSources({Object? claimRole, Object? profileRole}) {
    if (claimRole is String && claimRole.isNotEmpty) {
      return all.contains(claimRole) ? claimRole : '';
    }
    if (profileRole is String && selfServiceRoles.contains(profileRole)) return profileRole;
    return '';
  }

  /// The `role` custom claim from the user's ID token, or null when there is none.
  static Future<String?> claimRole(User user, {bool forceRefresh = false}) async {
    try {
      final token = await user.getIdTokenResult(forceRefresh);
      final role = token.claims?['role'];
      return role is String && role.isNotEmpty ? role : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String> resolve(
    User user, {
    bool forceRefresh = false,
    Future<String?> Function(String uid)? loadProfileRole,
  }) async {
    final claim = await claimRole(user, forceRefresh: forceRefresh);
    if (claim != null) return fromSources(claimRole: claim);
    final profileRole = await (loadProfileRole ?? FirestoreService().getUserRole)(user.uid);
    return fromSources(profileRole: profileRole);
  }
}
