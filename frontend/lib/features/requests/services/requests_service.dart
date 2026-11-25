import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/request_models.dart';

/// Where the request flows read and write. The default talks to Firebase; tests pass a fake.
abstract class RequestsBackend {
  String? get currentUserId;
  bool get isSignedIn;

  /// The agency id from the signed-in user's claims, or '' when there is none.
  Future<String> currentAgencyId();

  Stream<List<ViewingRequestItem>> watchViewings(RequestScope scope);
  Stream<List<RentalApplicationItem>> watchApplications(RequestScope scope);
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> data);

  /// The status of a lease ('' while it cannot be read), to decide which lease action to offer.
  Stream<String> watchLeaseStatus(String leaseId);

  /// Moves a draft lease to `pending_tenant_approval`. The rules allow only the lease's owner or
  /// managing agency, and only from `draft`.
  Future<void> sendLeaseOffer(String leaseId);
}

class FirebaseRequestsBackend implements RequestsBackend {
  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  bool get isSignedIn {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  @override
  Future<String> currentAgencyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    final agency = claims['agency_id'];
    return agency is String ? agency : '';
  }

  @override
  Stream<List<ViewingRequestItem>> watchViewings(RequestScope scope) {
    return FirebaseFirestore.instance
        .collection('ViewingRequests')
        .where(scope.field, isEqualTo: scope.value)
        .snapshots()
        .map((s) => s.docs.map((d) => ViewingRequestItem.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<RentalApplicationItem>> watchApplications(RequestScope scope) {
    return FirebaseFirestore.instance
        .collection('RentalApplications')
        .where(scope.field, isEqualTo: scope.value)
        .snapshots()
        .map((s) => s.docs.map((d) => RentalApplicationItem.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<String> watchLeaseStatus(String leaseId) {
    return FirebaseFirestore.instance
        .collection('Leases')
        .doc(leaseId)
        .snapshots()
        .map((s) => (s.data()?['status'] as String?) ?? '');
  }

  @override
  Future<void> sendLeaseOffer(String leaseId) {
    return FirebaseFirestore.instance.collection('Leases').doc(leaseId).update({
      'status': 'pending_tenant_approval',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> data) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(function);
    final response = await callable.call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(response.data);
  }
}

/// Viewing requests and rental applications (TAQ-112). Every write goes through a Cloud Function.
class RequestsService {
  RequestsService({RequestsBackend? backend}) : backend = backend ?? FirebaseRequestsBackend();

  static RequestsService instance = RequestsService();

  final RequestsBackend backend;

  bool get isSignedIn => backend.isSignedIn;

  Future<void> requestViewing({
    required String listingId,
    required String name,
    required String phone,
    String? message,
    String? preferredDate,
  }) async {
    await backend.call('requestViewing', {
      'listingId': listingId,
      'name': name,
      'phone': phone,
      if (message != null && message.isNotEmpty) 'message': message,
      if (preferredDate != null && preferredDate.isNotEmpty) 'preferredDate': preferredDate,
    });
  }

  Future<void> applyForRental({
    required String listingId,
    required String name,
    required String phone,
    String? message,
    String? moveInDate,
    int? occupants,
  }) async {
    await backend.call('applyForRental', {
      'listingId': listingId,
      'name': name,
      'phone': phone,
      if (message != null && message.isNotEmpty) 'message': message,
      if (moveInDate != null && moveInDate.isNotEmpty) 'moveInDate': moveInDate,
      if (occupants != null) 'occupants': occupants,
    });
  }

  Future<void> respondToViewing(String requestId, {required bool confirm, String? note}) async {
    await backend.call('respondToViewingRequest', {
      'requestId': requestId,
      'decision': confirm ? 'confirmed' : 'declined',
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> decideApplication(String applicationId, {required bool approve, String? note}) async {
    await backend.call('decideRentalApplication', {
      'applicationId': applicationId,
      'decision': approve ? 'approved' : 'rejected',
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// Creates the draft lease for an approved application and returns its id.
  Future<String> createLeaseDraft({
    required String applicationId,
    required String startDate,
    required String endDate,
    double? monthlyRent,
  }) async {
    final result = await backend.call('createLeaseFromApplication', {
      'applicationId': applicationId,
      'startDate': startDate,
      'endDate': endDate,
      if (monthlyRent != null) 'monthlyRent': monthlyRent,
    });
    return (result['leaseId'] as String?) ?? '';
  }

  Stream<String> watchLeaseStatus(String leaseId) => backend.watchLeaseStatus(leaseId);

  Future<void> sendLeaseOffer(String leaseId) => backend.sendLeaseOffer(leaseId);

  /// The scope for the signed-in owner or agency admin, or null when nobody is signed in.
  Future<RequestScope?> inboxScope({required bool agency}) async {
    if (agency) {
      final id = await backend.currentAgencyId();
      return id.isEmpty ? null : RequestScope.agency(id);
    }
    final uid = backend.currentUserId;
    return uid == null ? null : RequestScope.owner(uid);
  }

  Stream<List<ViewingRequestItem>> watchViewings(RequestScope scope) => backend.watchViewings(scope);
  Stream<List<RentalApplicationItem>> watchApplications(RequestScope scope) => backend.watchApplications(scope);

  /// The signed-in user's own viewing requests and applications (empty streams when signed out).
  Stream<List<ViewingRequestItem>> watchMyViewings() {
    final uid = backend.currentUserId;
    if (uid == null) return Stream.value(const []);
    return backend.watchViewings(RequestScope.mine(uid));
  }

  Stream<List<RentalApplicationItem>> watchMyApplications() {
    final uid = backend.currentUserId;
    if (uid == null) return Stream.value(const []);
    return backend.watchApplications(RequestScope.mine(uid, forApplications: true));
  }
}

/// A WhatsApp chat link for a phone number given as digits with an optional leading +.
Uri whatsAppUri(String phone, {String? message}) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final hasText = message != null && message.isNotEmpty;
  return Uri.https('wa.me', '/$digits', hasText ? {'text': message} : null);
}
