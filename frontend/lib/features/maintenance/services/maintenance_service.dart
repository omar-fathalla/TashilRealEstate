import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/maintenance_ticket.dart';

abstract class MaintenanceBackend {
  String? get currentUserId;
  Future<String> currentAgencyId();
  Stream<List<MaintenanceTicket>> watch(String field, String value);
  Future<ActiveLeaseRef?> activeLeaseFor(String tenantUid);
  Future<void> create(Map<String, dynamic> data);
  Future<void> update(String id, Map<String, dynamic> data);
}

class FirebaseMaintenanceBackend implements MaintenanceBackend {
  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<String> currentAgencyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final claim = ((await user.getIdTokenResult()).claims ?? const {})['agency_id'];
    return claim is String ? claim : '';
  }

  @override
  Stream<List<MaintenanceTicket>> watch(String field, String value) {
    return FirebaseFirestore.instance
        .collection('Maintenance')
        .where(field, isEqualTo: value)
        .snapshots()
        .map((s) => s.docs.map((d) => MaintenanceTicket.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<ActiveLeaseRef?> activeLeaseFor(String tenantUid) async {
    final snap = await FirebaseFirestore.instance.collection('Leases').where('tenant_id', isEqualTo: tenantUid).get();
    for (final doc in snap.docs) {
      if (doc.data()['status'] == 'active') return ActiveLeaseRef.fromMap(doc.id, doc.data());
    }
    return null;
  }

  @override
  Future<void> create(Map<String, dynamic> data) {
    return FirebaseFirestore.instance.collection('Maintenance').add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) {
    return FirebaseFirestore.instance.collection('Maintenance').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}

/// Thrown when a tenant has no active lease to attach a request to.
class NoActiveLeaseException implements Exception {
  const NoActiveLeaseException();
  @override
  String toString() => 'NoActiveLeaseException';
}

/// Maintenance requests (TAQ-111) on the `Maintenance` collection. The server rules require an active
/// lease and copy-check the parties, so the tenant, owner and agency here come from that lease.
class MaintenanceService {
  MaintenanceService({MaintenanceBackend? backend}) : backend = backend ?? FirebaseMaintenanceBackend();

  static MaintenanceService instance = MaintenanceService();

  final MaintenanceBackend backend;

  Stream<List<MaintenanceTicket>> streamMine() {
    final uid = backend.currentUserId;
    if (uid == null) return Stream.value(const []);
    return backend.watch('tenant_id', uid);
  }

  /// Requests addressed to the signed-in owner, or to the signed-in agency admin's agency.
  Stream<List<MaintenanceTicket>> streamForManager({required bool agency}) async* {
    if (agency) {
      final id = await backend.currentAgencyId();
      if (id.isEmpty) {
        yield const [];
        return;
      }
      yield* backend.watch('agency_id', id);
      return;
    }
    final uid = backend.currentUserId;
    if (uid == null) {
      yield const [];
      return;
    }
    yield* backend.watch('owner_id', uid);
  }

  Future<ActiveLeaseRef?> activeLease() async {
    final uid = backend.currentUserId;
    return uid == null ? null : backend.activeLeaseFor(uid);
  }

  /// Creates a request on the tenant's active lease. Throws [NoActiveLeaseException] when there is none.
  Future<void> create({
    required String title,
    String description = '',
    String category = 'other',
    List<String> photos = const [],
  }) async {
    final uid = backend.currentUserId;
    final lease = await activeLease();
    if (uid == null || lease == null) throw const NoActiveLeaseException();
    await backend.create({
      'lease_id': lease.id,
      'tenant_id': uid,
      'owner_id': lease.ownerId,
      'agency_id': lease.agencyId,
      if (lease.propertyId.isNotEmpty) 'property_id': lease.propertyId,
      if (lease.propertyTitle.isNotEmpty) 'property_title': lease.propertyTitle,
      if (lease.tenantName.isNotEmpty) 'tenant_name': lease.tenantName,
      'title': title.trim(),
      'description': description.trim(),
      'category': maintenanceCategories.contains(category) ? category : 'other',
      'photos': photos.take(3).toList(),
      'status': 'pending',
    });
  }

  Future<void> setStatus(String id, String status, {String? note}) {
    return backend.update(id, {
      'status': status,
      if (note != null) 'resolution_note': note,
    });
  }
}
