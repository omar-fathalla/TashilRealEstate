/// An owner's mandate to an agency for one property (TAQ-149), as the server keeps it in
/// `PropertyMandates/{propertyId}`. Written only by the mandate callables.
class PropertyMandate {
  final String propertyId;
  final String ownerId;
  final String agencyId;
  final String agencyName;
  final String propertyTitle;
  final String countryCode;
  final double pricePerMonth;
  final String status; // invited, active, declined, revoked
  final DateTime? expiresAt;

  const PropertyMandate({
    required this.propertyId,
    this.ownerId = '',
    this.agencyId = '',
    this.agencyName = '',
    this.propertyTitle = '',
    this.countryCode = 'AE',
    this.pricePerMonth = 0,
    this.status = 'invited',
    this.expiresAt,
  });

  bool get isActive => status == 'active';

  /// An invite the owner can still answer.
  bool isOpenInvite(DateTime now) => status == 'invited' && expiresAt != null && expiresAt!.isAfter(now);

  /// Something to show: an open invite or an active mandate.
  bool isCurrent(DateTime now) => isActive || isOpenInvite(now);

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return (v as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  factory PropertyMandate.fromMap(String id, Map<String, dynamic> m) => PropertyMandate(
        propertyId: id,
        ownerId: m['owner_id']?.toString() ?? '',
        agencyId: m['agency_id']?.toString() ?? '',
        agencyName: m['agency_name']?.toString() ?? '',
        propertyTitle: m['property_title']?.toString() ?? '',
        countryCode: m['country_code'] == 'EG' ? 'EG' : 'AE',
        pricePerMonth: m['price_per_month'] is num ? (m['price_per_month'] as num).toDouble() : 0,
        status: m['status']?.toString() ?? '',
        expiresAt: _date(m['expires_at']),
      );
}

/// A request to become an agency (TAQ-149), `AgencyApplications/{uid}`.
class AgencyApplicationItem {
  final String uid;
  final String name;
  final String countryCode;
  final String city;
  final String orn;
  final String licenceNumber;
  final String phone;
  final String status; // pending, approved, rejected
  final String reviewNote;
  final String agencyId;

  const AgencyApplicationItem({
    required this.uid,
    this.name = '',
    this.countryCode = 'AE',
    this.city = '',
    this.orn = '',
    this.licenceNumber = '',
    this.phone = '',
    this.status = 'pending',
    this.reviewNote = '',
    this.agencyId = '',
  });

  factory AgencyApplicationItem.fromMap(String id, Map<String, dynamic> m) => AgencyApplicationItem(
        uid: id,
        name: m['name']?.toString() ?? '',
        countryCode: m['country_code'] == 'EG' ? 'EG' : 'AE',
        city: m['city']?.toString() ?? '',
        orn: m['orn']?.toString() ?? '',
        licenceNumber: m['licence_number']?.toString() ?? '',
        phone: m['phone']?.toString() ?? '',
        status: m['status']?.toString() ?? '',
        reviewNote: m['review_note']?.toString() ?? '',
        agencyId: m['agency_id']?.toString() ?? '',
      );
}
