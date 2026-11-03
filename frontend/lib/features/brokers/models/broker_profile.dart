class BrokerProfile {
  final String id;
  final String agencyId;
  final Map<String, String> names;
  final Map<String, String> agencyNames;
  final String photoUrl;
  final String brokerRegistrationNumber;
  final String officeRegistrationNumber;
  final List<String> languages;
  final String phone;
  final String whatsApp;

  const BrokerProfile({
    required this.id,
    required this.agencyId,
    required this.names,
    required this.agencyNames,
    this.photoUrl = '',
    required this.brokerRegistrationNumber,
    required this.officeRegistrationNumber,
    required this.languages,
    required this.phone,
    required this.whatsApp,
  });

  String name(String lang) => names[lang] ?? names['en'] ?? names['ar'] ?? '';
  String agencyName(String lang) => agencyNames[lang] ?? agencyNames['en'] ?? agencyNames['ar'] ?? '';

  Map<String, dynamic> toMap() => {
        'id': id,
        'agencyId': agencyId,
        'names': names,
        'agencyNames': agencyNames,
        'photoUrl': photoUrl,
        'brokerRegistrationNumber': brokerRegistrationNumber,
        'officeRegistrationNumber': officeRegistrationNumber,
        'languages': languages,
        'phone': phone,
        'whatsApp': whatsApp,
      };

  factory BrokerProfile.fromMap(Map<String, dynamic> map, {String? docId}) {
    Map<String, String> strings(dynamic raw) {
      final out = <String, String>{};
      if (raw is Map) {
        raw.forEach((key, value) => out[key.toString()] = value.toString());
      }
      return out;
    }

    List<String> list(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    return BrokerProfile(
      id: docId ?? map['id']?.toString() ?? '',
      agencyId: map['agencyId']?.toString() ?? map['agency_id']?.toString() ?? '',
      names: strings(map['names']),
      agencyNames: strings(map['agencyNames'] ?? map['agency_names']),
      photoUrl: map['photoUrl']?.toString() ?? map['photo_url']?.toString() ?? '',
      brokerRegistrationNumber: map['brokerRegistrationNumber']?.toString() ?? map['broker_registration_number']?.toString() ?? '',
      officeRegistrationNumber: map['officeRegistrationNumber']?.toString() ?? map['office_registration_number']?.toString() ?? '',
      languages: list(map['languages']),
      phone: map['phone']?.toString() ?? '',
      whatsApp: map['whatsApp']?.toString() ?? map['whatsapp']?.toString() ?? '',
    );
  }

  static const BrokerProfile marinaDemo = BrokerProfile(
    id: 'broker-demo-marina',
    agencyId: 'agency-demo-marina',
    names: {
      'ar': 'ليلى المنصوري',
      'en': 'Layla Al Mansoori',
      'hi': 'लैला अल मंसूरी',
    },
    agencyNames: {
      'ar': 'مارينا للوساطة العقارية',
      'en': 'Marina Realty',
      'hi': 'मरीना रियल्टी',
    },
    brokerRegistrationNumber: 'BR-48291',
    officeRegistrationNumber: 'ORN-1044',
    languages: ['العربية', 'English', 'हिन्दी'],
    phone: '+971501112233',
    whatsApp: '+971501112233',
  );
}
