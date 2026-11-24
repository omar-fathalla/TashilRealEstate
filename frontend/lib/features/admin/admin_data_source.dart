import 'package:cloud_firestore/cloud_firestore.dart';
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
class AdminUserRow {
  const AdminUserRow({required this.uid, required this.email, required this.fullName, required this.role});

  final String uid;
  final String email;
  final String fullName;
  final String role;

  factory AdminUserRow.fromMap(Map<dynamic, dynamic> data) => AdminUserRow(
        uid: '${data['uid'] ?? ''}',
        email: '${data['email'] ?? ''}',
        fullName: '${data['full_name'] ?? ''}',
        role: '${data['role'] ?? ''}',
      );
}

class AdminAgencyRow {
  const AdminAgencyRow({required this.id, required this.name, required this.verified, required this.city});

  final String id;
  final String name;
  final bool verified;
  final String city;
}

/// What the Admin dashboard reads and writes. Every write here is one firestore.rules allow
/// an Admin to make; anything else would be rejected by the server.
abstract class AdminDataSource {
  Stream<List<AdminListing>> watchListings(String langCode);
  Future<void> setVerified(String listingId, bool verified);
  Future<void> hide(String listingId);
  Future<void> restore(String listingId);
  Future<List<AdminUserRow>> loadUsers();
  Stream<List<AdminAgencyRow>> watchAgencies(String langCode);
}

class FirebaseAdminDataSource implements AdminDataSource {
  FirebaseAdminDataSource({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore,
        _functions = functions;

  FirebaseFirestore? _firestore;
  FirebaseFunctions? _functions;

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

  @override
  Future<void> hide(String listingId) {
    return _listing(listingId).update({
      'is_published': false,
      'moderation_hidden': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> restore(String listingId) {
    return _listing(listingId).update({
      'is_published': true,
      'moderation_hidden': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<AdminUserRow>> loadUsers() async {
    final result = await _fn.httpsCallable('listUsersForAdmin').call<Map<dynamic, dynamic>>({'limit': 100});
    final users = result.data['users'];
    if (users is! List) return const [];
    return users.whereType<Map>().map(AdminUserRow.fromMap).toList();
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
            return AdminAgencyRow(
              id: d.id,
              name: name.isEmpty ? d.id : name,
              verified: data['verified_badge'] == true,
              city: data['city'] is String ? data['city'] as String : '',
            );
          }).toList(),
        );
  }
}
