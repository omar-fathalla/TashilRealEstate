import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/services/session_guard.dart';

import '../models/tenant_models.dart';

/// Where the tenant portal reads and writes. The default talks to Firebase; tests pass a fake.
abstract class TenantBackend {
  String? get currentUserId;
  Stream<List<TenantLease>> watchLeases(String uid);
  Stream<List<TenantTransaction>> watchTransactions(String uid);
  Stream<List<TenantInvoice>> watchInvoices(String uid);
  Stream<List<TenantNotification>> watchNotifications(String uid);

  /// Answers a pending lease offer through the respondToLeaseOffer function, which activates the
  /// lease only if no other live lease holds the property. Throws the callable's error on refusal.
  Future<void> decideLease(String leaseId, {required bool approve});

  Future<void> markNotificationRead(String uid, String notificationId);
}

class FirebaseTenantBackend implements TenantBackend {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<T>> _byTenant<T>(String collection, String uid, T Function(String, Map<String, dynamic>) parse) {
    return _db
        .collection(collection)
        .where('tenant_id', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => parse(d.id, d.data())).toList());
  }

  @override
  Stream<List<TenantLease>> watchLeases(String uid) => _byTenant('Leases', uid, TenantLease.fromMap);

  @override
  Stream<List<TenantTransaction>> watchTransactions(String uid) => _byTenant('Transactions', uid, TenantTransaction.fromMap);

  @override
  Stream<List<TenantInvoice>> watchInvoices(String uid) => _byTenant('Invoices', uid, TenantInvoice.fromMap);

  @override
  Stream<List<TenantNotification>> watchNotifications(String uid) {
    return _db
        .collection('Users')
        .doc(uid)
        .collection('notifications')
        .snapshots()
        .map((s) => s.docs.map((d) => TenantNotification.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> decideLease(String leaseId, {required bool approve}) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('respondToLeaseOffer');
    await SessionGuard.instance.run(() => callable.call<Map<String, dynamic>>({'leaseId': leaseId, 'decision': approve ? 'approve' : 'reject'}));
  }

  @override
  Future<void> markNotificationRead(String uid, String notificationId) {
    return _db.collection('Users').doc(uid).collection('notifications').doc(notificationId).update({'read': true});
  }
}

/// The dictionary key that explains why respondToLeaseOffer refused, from its `details.reason`.
String decisionErrorKey(String reason) {
  switch (reason) {
    case 'property_already_leased':
      return 'tnPropertyAlreadyLeased';
    case 'offer_expired':
      return 'tnOfferExpired';
    case 'not_pending':
      return 'tnOfferNotPending';
    case 'try_again':
      return 'tnDecisionTryAgain';
    case 'property_not_available':
      return 'tnPropertyNotAvailable';
    case 'property_not_found':
    case 'property_not_registered':
    case 'property_id_conflict':
    case 'property_not_managed':
    case 'property_agency_managed':
    case 'owner_not_landlord':
    case 'lease_missing_property':
    case 'lease_missing_owner':
      return 'tnOfferPropertyInvalid';
    case 'rent_invalid':
    case 'rent_missing':
    case 'lease_dates_invalid':
      return 'tnOfferTermsInvalid';
    default:
      return 'tnDecisionFailed';
  }
}

/// The signed-in tenant's real data: leases, payments, receipts and notifications (TAQ-110).
/// Nothing here marks a payment paid; payments are created and settled only by the server.
class TenantLeaseService {
  TenantLeaseService({TenantBackend? backend}) : backend = backend ?? FirebaseTenantBackend();

  static TenantLeaseService instance = TenantLeaseService();

  final TenantBackend backend;

  Stream<List<T>> _signedIn<T>(Stream<List<T>> Function(String uid) open) {
    final uid = backend.currentUserId;
    if (uid == null) return Stream.value(const []);
    return open(uid);
  }

  /// The tenant's leases without drafts, newest start first.
  Stream<List<TenantLease>> watchLeases() => _signedIn(backend.watchLeases).map((items) {
        final visible = items.where((l) => l.visibleToTenant).toList();
        visible.sort((a, b) => b.startDate.compareTo(a.startDate));
        return visible;
      });

  Stream<List<TenantTransaction>> watchTransactions() => _signedIn(backend.watchTransactions).map((items) {
        final list = [...items];
        list.sort((a, b) => b.period.compareTo(a.period));
        return list;
      });

  Stream<List<TenantInvoice>> watchInvoices() => _signedIn(backend.watchInvoices);

  /// Newest first. Items still waiting for the server timestamp sort to the top.
  Stream<List<TenantNotification>> watchNotifications() => _signedIn(backend.watchNotifications).map((items) {
        final list = [...items];
        final now = DateTime.now();
        list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        return list;
      });

  Future<void> decideLease(String leaseId, {required bool approve}) => backend.decideLease(leaseId, approve: approve);

  Future<void> markRead(String notificationId) async {
    final uid = backend.currentUserId;
    if (uid == null) return;
    await backend.markNotificationRead(uid, notificationId);
  }

  Future<void> markAllRead(Iterable<TenantNotification> items) async {
    for (final item in items.where((n) => !n.read)) {
      await markRead(item.id);
    }
  }
}

/// The month (`YYYY-MM`) the tenant should pay next on an active lease, or null when the lease has
/// no payable month left. It is the current month (or the start month, if the lease starts later),
/// moving forward past months already paid.
String? nextDuePeriod(TenantLease lease, Iterable<TenantTransaction> transactions, DateTime now) {
  if (!lease.isActive) return null;
  String format(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  final paid = {for (final t in transactions) if (t.leaseId == lease.id && t.isPaid) t.period};
  var period = format(DateTime(now.year, now.month));
  if (lease.startDate.length >= 7 && period.compareTo(lease.startDate.substring(0, 7)) < 0) {
    period = lease.startDate.substring(0, 7);
  }
  var year = int.parse(period.substring(0, 4));
  var month = int.parse(period.substring(5, 7));
  while (paid.contains(period)) {
    month += 1;
    if (month > 12) {
      month = 1;
      year += 1;
    }
    period = format(DateTime(year, month));
  }
  if (lease.endDate.length >= 7 && period.compareTo(lease.endDate.substring(0, 7)) > 0) return null;
  return period;
}
