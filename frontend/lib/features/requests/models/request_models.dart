import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String _text(dynamic value) => value is String ? value : '';

/// A visitor's request to view a listing (`ViewingRequests/{id}`, written by the server).
class ViewingRequestItem {
  final String id;
  final String listingId;
  final String ownerId;
  final String agencyId;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String message;
  final String preferredDate;
  final String status;
  final String responseNote;
  final Map<String, String> listingTitles;
  final DateTime? createdAt;

  const ViewingRequestItem({
    required this.id,
    required this.listingId,
    this.ownerId = '',
    this.agencyId = '',
    this.requesterId = '',
    this.requesterName = '',
    this.requesterPhone = '',
    this.message = '',
    this.preferredDate = '',
    this.status = 'pending',
    this.responseNote = '',
    this.listingTitles = const {},
    this.createdAt,
  });

  bool get isPending => status == 'pending';

  String titleFor(String lang) =>
      listingTitles[lang]?.isNotEmpty == true ? listingTitles[lang]! : (listingTitles['en'] ?? listingTitles['ar'] ?? '');

  factory ViewingRequestItem.fromMap(String id, Map<String, dynamic> data) {
    return ViewingRequestItem(
      id: id,
      listingId: _text(data['listing_id']),
      ownerId: _text(data['owner_id']),
      agencyId: _text(data['agency_id']),
      requesterId: _text(data['requester_id']),
      requesterName: _text(data['requester_name']),
      requesterPhone: _text(data['requester_phone']),
      message: _text(data['message']),
      preferredDate: _text(data['preferred_date']),
      status: _text(data['status']).isEmpty ? 'pending' : _text(data['status']),
      responseNote: _text(data['response_note']),
      listingTitles: {
        for (final e in ((data['listing_titles'] as Map?) ?? const {}).entries) e.key.toString(): _text(e.value),
      },
      createdAt: _date(data['created_at']),
    );
  }
}

/// A tenant's application to rent a listing (`RentalApplications/{listingId}_{uid}`).
class RentalApplicationItem {
  final String id;
  final String listingId;
  final String ownerId;
  final String agencyId;
  final String applicantId;
  final String applicantName;
  final String applicantPhone;
  final String message;
  final String moveInDate;
  final int occupants;
  final String status;
  final String responseNote;
  final String leaseId;
  final Map<String, String> listingTitles;
  final DateTime? createdAt;

  const RentalApplicationItem({
    required this.id,
    required this.listingId,
    this.ownerId = '',
    this.agencyId = '',
    this.applicantId = '',
    this.applicantName = '',
    this.applicantPhone = '',
    this.message = '',
    this.moveInDate = '',
    this.occupants = 1,
    this.status = 'pending',
    this.responseNote = '',
    this.leaseId = '',
    this.listingTitles = const {},
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get canCreateLease => status == 'approved' && leaseId.isEmpty;

  String titleFor(String lang) =>
      listingTitles[lang]?.isNotEmpty == true ? listingTitles[lang]! : (listingTitles['en'] ?? listingTitles['ar'] ?? '');

  factory RentalApplicationItem.fromMap(String id, Map<String, dynamic> data) {
    final occupants = data['occupants'];
    return RentalApplicationItem(
      id: id,
      listingId: _text(data['listing_id']),
      ownerId: _text(data['owner_id']),
      agencyId: _text(data['agency_id']),
      applicantId: _text(data['applicant_id']),
      applicantName: _text(data['applicant_name']),
      applicantPhone: _text(data['applicant_phone']),
      message: _text(data['message']),
      moveInDate: _text(data['move_in_date']),
      occupants: occupants is int ? occupants : 1,
      status: _text(data['status']).isEmpty ? 'pending' : _text(data['status']),
      responseNote: _text(data['response_note']),
      leaseId: _text(data['lease_id']),
      listingTitles: {
        for (final e in ((data['listing_titles'] as Map?) ?? const {}).entries) e.key.toString(): _text(e.value),
      },
      createdAt: _date(data['created_at']),
    );
  }
}

/// Which records an inbox shows: the ones addressed to an owner or an agency, or the ones a user sent.
class RequestScope {
  final String field;
  final String value;
  const RequestScope._(this.field, this.value);

  const RequestScope.owner(String uid) : this._('owner_id', uid);
  const RequestScope.agency(String agencyId) : this._('agency_id', agencyId);

  /// The requester's own records. [forApplications] picks `applicant_id` instead of `requester_id`.
  const RequestScope.mine(String uid, {bool forApplications = false})
      : this._(forApplications ? 'applicant_id' : 'requester_id', uid);

  bool get isMine => field == 'requester_id' || field == 'applicant_id';
}

/// The Cloud Function error codes the request flows surface to people.
String requestErrorKey(Object error) {
  final text = error.toString();
  if (text.contains('listing_not_live')) return 'rqListingUnavailable';
  if (text.contains('duplicate_pending') || text.contains('duplicate_application')) return 'rqDuplicate';
  if (text.contains('own_listing')) return 'rqOwnListing';
  if (text.contains('resource-exhausted')) return 'rqTooMany';
  if (text.contains('unauthenticated')) return 'rqSignInRequired';
  if (text.contains('permission-denied')) return 'rqTenantOnly';
  if (text.contains('invalid-argument')) return 'rqInvalidInput';
  return 'rqFailed';
}
