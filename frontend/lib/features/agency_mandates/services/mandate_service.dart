import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/features/agency_mandates/models/mandate_models.dart';

/// Reads and callables behind mandates and agency applications (TAQ-149). Tests pass a fake.
abstract class MandateBackend {
  String? get currentUserId;
  Stream<List<PropertyMandate>> watchOwnerMandates(String ownerId);
  Stream<List<PropertyMandate>> watchAgencyMandates(String agencyId);
  Stream<AgencyApplicationItem?> watchApplication(String uid);
  Stream<List<AgencyApplicationItem>> watchPendingApplications();
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data);
}

class FirebaseMandateBackend implements MandateBackend {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Stream<List<PropertyMandate>> _mandates(String field, String value) => _db
      .collection('PropertyMandates')
      .where(field, isEqualTo: value)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map((d) => PropertyMandate.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<PropertyMandate>> watchOwnerMandates(String ownerId) => _mandates('owner_id', ownerId);

  @override
  Stream<List<PropertyMandate>> watchAgencyMandates(String agencyId) => _mandates('agency_id', agencyId);

  @override
  Stream<AgencyApplicationItem?> watchApplication(String uid) => _db
      .collection('AgencyApplications')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AgencyApplicationItem.fromMap(d.id, d.data() ?? const {}) : null);

  @override
  Stream<List<AgencyApplicationItem>> watchPendingApplications() => _db
      .collection('AgencyApplications')
      .where('status', isEqualTo: 'pending')
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => AgencyApplicationItem.fromMap(d.id, d.data())).toList());

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    final response = await FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(name).call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(response.data);
  }
}

class MandateService {
  MandateService({MandateBackend? backend}) : backend = backend ?? FirebaseMandateBackend();

  static MandateService instance = MandateService();

  final MandateBackend backend;

  /// A stream that never throws while building: a read that cannot start shows as an error event.
  static Stream<T> safe<T>(Stream<T> Function() open) {
    try {
      return open();
    } catch (e) {
      return Stream<T>.error(e);
    }
  }

  Future<void> invite(String propertyId) => backend.call('inviteMandate', {'propertyId': propertyId.trim()});
  Future<void> respond(String propertyId, {required bool accept}) =>
      backend.call('respondToMandate', {'propertyId': propertyId, 'accept': accept});
  Future<void> revoke(String propertyId) => backend.call('revokeMandate', {'propertyId': propertyId});

  Future<void> applyForAgency({
    required String name,
    required String countryCode,
    required String phone,
    String city = '',
    String orn = '',
    String licenceNumber = '',
  }) =>
      backend.call('applyForAgency', {
        'name': name.trim(),
        'countryCode': countryCode,
        'phone': phone.trim(),
        'city': city.trim(),
        'orn': orn.trim(),
        'licenceNumber': licenceNumber.trim(),
      });

  Future<void> review(String uid, {required bool approve, String note = ''}) =>
      backend.call('reviewAgencyApplication', {'uid': uid, 'approve': approve, if (note.trim().isNotEmpty) 'note': note.trim()});
}

/// The dictionary key that explains a refused mandate or application call, from `details.reason`.
String mandateErrorKey(String reason) {
  switch (reason) {
    case 'property_not_registered':
    case 'property_not_found':
      return 'mdPropertyNotFound';
    case 'owner_not_eligible':
    case 'mandate_own_property':
      return 'mdOwnerNotEligible';
    case 'mandate_already_active':
    case 'mandate_active_other':
      return 'mdAlreadyManaged';
    case 'mandate_pending_other':
      return 'mdPendingOther';
    case 'mandate_lease_live':
      return 'mdLeaseLive';
    case 'mandate_not_open':
      return 'mdNotOpen';
    case 'agency_not_found':
      return 'mdAgencyMissing';
    case 'application_pending':
      return 'aaPending';
    case 'application_approved':
      return 'aaApproved';
    case 'applicant_has_open_leases':
      return 'aaBlockedLeases';
    case 'applicant_has_mandates':
      return 'aaBlockedMandates';
    case 'name_required':
    case 'name_invalid':
    case 'name_contact':
      return 'aaNameInvalid';
    case 'phone_required':
    case 'phone_invalid':
      return 'aaPhoneInvalid';
    case 'orn_invalid':
      return 'aaOrnInvalid';
    default:
      return 'mdFailed';
  }
}
