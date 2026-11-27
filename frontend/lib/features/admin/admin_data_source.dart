import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// One public listing as the platform Admin sees it.
class AdminListing {
  const AdminListing({
    required this.id,
    required this.title,
    required this.location,
    required this.pricePerMonth,
    required this.currencyCode,
    required this.isPublished,
    required this.verified,
    required this.hidden,
    required this.status,
  });

  final String id;
  final String title;
  final String location;
  final num pricePerMonth;
  final String currencyCode;
  final bool isPublished;
  final bool verified;
  final bool hidden;
  final String status;

  /// A hidden listing can be put back online only while it is still vacant, which is what
  /// firestore.rules allow an Admin to do.
  bool get canRestore => hidden && status == 'vacant';

  factory AdminListing.fromMap(String id, Map<String, dynamic> data, String langCode) {
    String localized(Object? value) {
      if (value is Map) {
        for (final key in [langCode, 'en', 'ar', 'hi']) {
          final text = value[key];
          if (text is String && text.trim().isNotEmpty) return text.trim();
        }
      }
      return '';
    }

    return AdminListing(
      id: id,
      title: localized(data['titles']).isNotEmpty ? localized(data['titles']) : id,
      location: localized(data['locations']),
      pricePerMonth: data['pricePerMonth'] is num ? data['pricePerMonth'] as num : 0,
      currencyCode: data['currencyCode'] == 'AED' ? 'AED' : 'EGP',
      isPublished: data['is_published'] == true,
      verified: data['verified'] == true,
      hidden: data['moderation_hidden'] == true,
      status: data['status'] is String ? data['status'] as String : '',
    );
  }
}

/// A user as returned by the `listUsersForAdmin` callable: no IBAN, national ID or phone.
///
/// [role] is the profile document's role and [claimRole] the role in the user's custom claim, which
/// is what the rules and the app actually trust. They differ for staff roles, which only exist as
/// claims, so the dashboard shows both when they differ.
class AdminUserRow {
  const AdminUserRow({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.claimRole = '',
  });

  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String claimRole;

  /// The role the platform acts on: the claim when there is one, otherwise the profile role.
  String get effectiveRole => claimRole.isNotEmpty ? claimRole : role;

  bool get rolesDiffer => claimRole.isNotEmpty && role.isNotEmpty && claimRole != role;

  factory AdminUserRow.fromMap(Map<dynamic, dynamic> data) => AdminUserRow(
        uid: '${data['uid'] ?? ''}',
        email: '${data['email'] ?? ''}',
        fullName: '${data['full_name'] ?? ''}',
        role: '${data['role'] ?? ''}',
        claimRole: '${data['claim_role'] ?? ''}',
      );
}

/// One page of the user directory. [nextPageToken] is null on the last page.
class AdminUserPage {
  const AdminUserPage({required this.users, this.nextPageToken});

  final List<AdminUserRow> users;
  final String? nextPageToken;
}

class AdminAgencyRow {
  const AdminAgencyRow({
    required this.id,
    required this.name,
    required this.verified,
    required this.city,
    this.orn = '',
    this.rera = '',
    this.licenceStatus = 'unverified',
  });

  final String id;
  final String name;
  final bool verified;
  final String city;

  /// The broker office (ORN) and broker (RERA) numbers the agency entered. Platform staff check
  /// them by hand (TAQ-154).
  final String orn;
  final String rera;

  /// `unverified`, `pending`, `verified` or `rejected`. Only a SuperAdmin can set verified or rejected.
  final String licenceStatus;

  static const licenceStatuses = ['unverified', 'pending', 'verified', 'rejected'];
}

/// What the Admin dashboard reads and writes. Every write here is one firestore.rules allow
/// an Admin to make; anything else would be rejected by the server.
abstract class AdminDataSource {
  Stream<List<AdminListing>> watchListings(String langCode);
  Future<void> setVerified(String listingId, bool verified);

  /// Hides [listing]: writes PropertyModeration and the public doc in one batch, recording whether
  /// the listing was live so a later restore cannot publish anything that was not.
  Future<void> hide(AdminListing listing);

  /// Lifts the hold. The listing goes back online only if the server finds it was live before the
  /// hide and its owner's private listing is still published, valid and allowed to publish.
  Future<void> restore(AdminListing listing);

  Future<AdminUserPage> loadUsers({String? startAfter});
  Stream<List<AdminAgencyRow>> watchAgencies(String langCode);

  /// Whether the signed-in account may verify agency licences. firestore.rules allow it only to a
  /// SuperAdmin; an Admin sees the status read-only.
  Future<bool> canVerifyAgencies();

  /// Records the manual licence check: [status] `verified` also turns the public badge on, and any
  /// other status turns it off.
  Future<void> setAgencyLicence(String agencyId, String status);
}

class FirebaseAdminDataSource implements AdminDataSource {
  FirebaseAdminDataSource({FirebaseFirestore? firestore, FirebaseFunctions? functions, String? Function()? currentUid})
      : _firestore = firestore,
        _functions = functions,
        _currentUid = currentUid;

  FirebaseFirestore? _firestore;
  FirebaseFunctions? _functions;
  final String? Function()? _currentUid;

  String get _uid {
    final uid = _currentUid != null ? _currentUid!() : FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) throw StateError('Not signed in');
    return uid;
  }

  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;
  FirebaseFunctions get _fn => _functions ??= FirebaseFunctions.instanceFor(region: 'us-central1');

  DocumentReference<Map<String, dynamic>> _listing(String id) => _db.collection('Properties').doc(id);

  @override
  Stream<List<AdminListing>> watchListings(String langCode) {
    return _db.collection('Properties').limit(200).snapshots().map(
          (snap) => snap.docs.map((d) => AdminListing.fromMap(d.id, d.data(), langCode)).toList(),
        );
  }

  @override
  Future<void> setVerified(String listingId, bool verified) {
    return _listing(listingId).update({'verified': verified, 'updated_at': FieldValue.serverTimestamp()});
  }

  DocumentReference<Map<String, dynamic>> _moderation(String id) => _db.collection('PropertyModeration').doc(id);

  @override
  Future<void> hide(AdminListing listing) {
    final batch = _db.batch();
    batch.set(_moderation(listing.id), {
      'hidden': true,
      'pre_hide_published': listing.isPublished,
      'updated_by': _uid,
      'updated_at': FieldValue.serverTimestamp(),
    });
    batch.update(_listing(listing.id), {
      'is_published': false,
      'moderation_hidden': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  @override
  Future<void> restore(AdminListing listing) async {
    final stored = await _moderation(listing.id).get();
    final preHidePublished = stored.data()?['pre_hide_published'] == true;
    final batch = _db.batch();
    batch.set(_moderation(listing.id), {
      'hidden': false,
      'pre_hide_published': preHidePublished,
      'updated_by': _uid,
      'updated_at': FieldValue.serverTimestamp(),
    });
    // The rules never let a client set is_published to true. Lifting the flag is enough: the server
    // re-reads the owner's private listing and republishes it only if it is still valid.
    batch.update(_listing(listing.id), {
      'moderation_hidden': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  @override
  Future<AdminUserPage> loadUsers({String? startAfter}) async {
    final result = await _fn.httpsCallable('listUsersForAdmin').call<Map<dynamic, dynamic>>({
      'limit': 100,
      if (startAfter != null && startAfter.isNotEmpty) 'startAfter': startAfter,
    });
    final users = result.data['users'];
    final next = result.data['nextPageToken'];
    return AdminUserPage(
      users: users is List ? users.whereType<Map>().map(AdminUserRow.fromMap).toList() : const [],
      nextPageToken: next is String && next.isNotEmpty ? next : null,
    );
  }

  @override
  Stream<List<AdminAgencyRow>> watchAgencies(String langCode) {
    return _db.collection('Agencies').limit(200).snapshots().map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            final names = data['names'];
            var name = data['name'] is String ? data['name'] as String : '';
            if (names is Map && names[langCode] is String && (names[langCode] as String).isNotEmpty) {
              name = names[langCode] as String;
            }
            final status = data['licence_status'];
            return AdminAgencyRow(
              id: d.id,
              name: name.isEmpty ? d.id : name,
              verified: data['verified_badge'] == true,
              city: data['city'] is String ? data['city'] as String : '',
              orn: data['orn'] is String ? data['orn'] as String : '',
              rera: data['rera'] is String ? data['rera'] as String : '',
              licenceStatus: AdminAgencyRow.licenceStatuses.contains(status) ? status as String : 'unverified',
            );
          }).toList(),
        );
  }

  @override
  Future<bool> canVerifyAgencies() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    return claims['role'] == 'SuperAdmin';
  }

  @override
  Future<void> setAgencyLicence(String agencyId, String status) {
    return _db.collection('Agencies').doc(agencyId).update({
      'licence_status': status,
      'verified_badge': status == 'verified',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
