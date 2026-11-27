import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/portfolio_models.dart';

/// Where the owner and agency portals read their leases, payments, receipts and maintenance, and
/// where they create leases. The default talks to Firebase; tests pass a fake.
abstract class PortfolioBackend {
  String? get currentUserId;

  /// The agency id from an AgencyAdmin's claims, or '' for everyone else.
  Future<String> currentAgencyId();

  /// True when the signed-in user's claims say SuperAdmin (TAQ-162).
  Future<bool> currentIsSuperAdmin();

  Stream<List<PortfolioLease>> watchLeases(PortfolioScope scope);
  Stream<List<PortfolioTransaction>> watchTransactions(PortfolioScope scope);
  Stream<List<PortfolioInvoice>> watchInvoices(PortfolioScope scope);
  Stream<List<PortfolioMaintenance>> watchMaintenance(PortfolioScope scope);

  /// Calls the createLease function. Throws its error on refusal.
  Future<Map<String, dynamic>> createLease(Map<String, dynamic> data);

  /// Moves a lease between draft and offered (the rules allow only the owner or managing agency).
  Future<void> setLeaseStatus(String leaseId, String status);

  /// Deletes a draft lease (the rules refuse every other status).
  Future<void> deleteDraftLease(String leaseId);
}

class FirebasePortfolioBackend implements PortfolioBackend {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> currentAgencyId() async {
    if (currentUserId == null) return '';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    final agency = claims['agency_id'];
    return claims['role'] == 'AgencyAdmin' && agency is String ? agency : '';
  }

  @override
  Future<bool> currentIsSuperAdmin() async {
    if (currentUserId == null) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    return claims['role'] == 'SuperAdmin';
  }

  /// The platform scope reads at most this many docs per collection (TAQ-162).
  static const int platformLimit = 1000;

  Stream<List<T>> _scoped<T>(String collection, PortfolioScope scope, T Function(String, Map<String, dynamic>) parse) {
    final Query<Map<String, dynamic>> query = scope.isPlatform
        ? _db.collection(collection).limit(platformLimit)
        : _db.collection(collection).where(scope.field, isEqualTo: scope.value);
    return query
        .snapshots()
        .map((s) => s.docs.map((d) => parse(d.id, d.data())).toList());
  }

  @override
  Stream<List<PortfolioLease>> watchLeases(PortfolioScope scope) => _scoped('Leases', scope, PortfolioLease.fromMap);

  @override
  Stream<List<PortfolioTransaction>> watchTransactions(PortfolioScope scope) =>
      _scoped('Transactions', scope, PortfolioTransaction.fromMap);

  @override
  Stream<List<PortfolioInvoice>> watchInvoices(PortfolioScope scope) => _scoped('Invoices', scope, PortfolioInvoice.fromMap);

  @override
  Stream<List<PortfolioMaintenance>> watchMaintenance(PortfolioScope scope) =>
      _scoped('Maintenance', scope, PortfolioMaintenance.fromMap);

  @override
  Future<Map<String, dynamic>> createLease(Map<String, dynamic> data) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('createLease');
    final response = await callable.call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> setLeaseStatus(String leaseId, String status) {
    return _db.collection('Leases').doc(leaseId).update({'status': status, 'updated_at': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> deleteDraftLease(String leaseId) => _db.collection('Leases').doc(leaseId).delete();
}

/// The dictionary key that explains why createLease refused, from its `details.reason`.
String leaseCreateErrorKey(String reason) {
  switch (reason) {
    case 'property_already_leased':
      return 'ldPropertyAlreadyLeased';
    case 'tenant_not_found':
      return 'ldTenantNotFound';
    case 'property_not_managed':
    case 'property_agency_managed':
    case 'property_not_found':
    case 'property_not_registered':
    case 'property_id_conflict':
    case 'owner_not_landlord':
      return 'ldPropertyNotManaged';
    case 'rent_precision':
      return 'rqRentPrecision';
    case 'late_fee_invalid':
      return 'ldLateFeeInvalid';
    case 'iban_invalid':
      return 'ldIbanInvalid';
    case 'property_country_missing':
      return 'ldPropertyCountryMissing';
    default:
      return 'ldCreateFailed';
  }
}

/// The signed-in manager's real portfolio data (TAQ-143, TAQ-144, TAQ-145). Nothing here marks a
/// lease active or a payment paid: those happen only on the server.
class PortfolioDataService {
  PortfolioDataService({PortfolioBackend? backend}) : backend = backend ?? FirebasePortfolioBackend();

  static PortfolioDataService instance = PortfolioDataService();

  final PortfolioBackend backend;

  bool get isSignedIn => backend.currentUserId != null;

  /// The records to read: an agency admin's agency by its claim, otherwise the owner's by their
  /// uid. With [agencyOnly] a missing agency claim gives null (nothing to show, never "all").
  /// Null too when signed out.
  ///
  /// With [platform] (the SuperAdmin dashboard, TAQ-162) a SuperAdmin gets the platform scope and
  /// anyone else null.
  Future<PortfolioScope?> scopeFor({bool agencyOnly = false, bool platform = false}) async {
    final uid = backend.currentUserId;
    if (uid == null) return null;
    if (platform) return await backend.currentIsSuperAdmin() ? const PortfolioScope.platform() : null;
    final id = await backend.currentAgencyId();
    if (id.isNotEmpty) return PortfolioScope.agency(id);
    return agencyOnly ? null : PortfolioScope.owner(uid);
  }

  /// Leases, newest change first.
  Stream<List<PortfolioLease>> watchLeases(PortfolioScope scope) => backend.watchLeases(scope).map((items) {
        final list = [...items];
        list.sort((a, b) => (b.lastChange ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.lastChange ?? DateTime.fromMillisecondsSinceEpoch(0)));
        return list;
      });

  Stream<List<PortfolioTransaction>> watchTransactions(PortfolioScope scope) => backend.watchTransactions(scope);
  Stream<List<PortfolioInvoice>> watchInvoices(PortfolioScope scope) => backend.watchInvoices(scope);
  Stream<List<PortfolioMaintenance>> watchMaintenance(PortfolioScope scope) => backend.watchMaintenance(scope);

  /// Creates the lease on the server and returns its id. [sendOffer] puts it straight in front of
  /// the tenant. Throws the callable's error on refusal; there is no local fallback.
  Future<String> createLease({
    required String ownerId,
    required String propertyId,
    required String tenantId,
    required String startDate,
    required String endDate,
    required double monthlyRent,
    required bool sendOffer,
    double? lateFeeAmount,
    int? lateFeeGraceDays,
    String? payoutBankName,
    String? payoutIban,
  }) async {
    final result = await backend.createLease({
      'ownerId': ownerId,
      'propertyId': propertyId,
      'tenantId': tenantId,
      'startDate': startDate,
      'endDate': endDate,
      'monthlyRent': monthlyRent,
      'sendOffer': sendOffer,
      // Optional terms (TAQ-164); absent ones are left out so the server keeps its defaults.
      if (lateFeeAmount != null) 'lateFeeAmount': lateFeeAmount,
      if (lateFeeGraceDays != null) 'lateFeeGraceDays': lateFeeGraceDays,
      if (payoutBankName != null && payoutBankName.isNotEmpty) 'payoutBankName': payoutBankName,
      if (payoutIban != null && payoutIban.isNotEmpty) 'payoutIban': payoutIban,
    });
    final id = result['leaseId'];
    if (id is! String || id.isEmpty) throw StateError('createLease returned no lease id');
    return id;
  }

  Future<void> sendOffer(String leaseId) => backend.setLeaseStatus(leaseId, 'pending_tenant_approval');
  Future<void> withdrawOffer(String leaseId) => backend.setLeaseStatus(leaseId, 'draft');
  Future<void> deleteDraft(String leaseId) => backend.deleteDraftLease(leaseId);
}
