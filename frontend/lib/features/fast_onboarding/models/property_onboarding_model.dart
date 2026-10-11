enum PropertyMarketingTone {
  luxuryExecutive,  // فاخر وراقي
  cozyFamily,       // عائلي دافئ ومريح
  highYieldInvestor // استثماري عالي العائد للمغتربين ورجال الأعمال
}

enum FurnishingStatus {
  fullyFurnished, // مفروش بالكامل
  semiFurnished,  // نصف مفروش
  unfurnished,    // غير مفروش
}

enum PaymentFrequency {
  monthly,     // شهري
  quarterly,   // ربع سنوي (4 دفعات)
  semiAnnual,  // نصف سنوي (دفعتان)
  annual,      // سنوي
}

enum BuildingAge {
  brandNew,    // جديد / أول ساكن
  oneToFive,   // من 1 إلى 5 سنوات
  older,       // أكثر من 5 سنوات
}

class FastPropertyDraft {
  // 📍 1. الموقع الجغرافي (The Location)
  // 🔴 الإجباري:
  double latitude;
  double longitude;
  String city;
  String district;
  // 🟢 الاختياري:
  String? streetAddress;
  String? buildingName;
  String? unitNumber;

  // 💰 2. الشفافية المالية (Financial Transparency)
  // 🔴 الإجباري:
  double monthlyRent;
  String currency; // 'EGP', 'AED', 'USD'
  PaymentFrequency paymentFrequency;
  // 🟢 الاختياري:
  double? securityDeposit;
  bool isBillsIncluded;
  bool isNegotiable;

  // 🏠 3. المواصفات الفنية (Technical Specs)
  // 🔴 الإجباري:
  String propertyType; // apartment, villa, studio, office, chalet, penthouse
  int areaSqm;
  int bedrooms; // 0 for studio
  int bathrooms;
  // 🟢 الاختياري:
  int? floor;
  BuildingAge? buildingAge;
  bool hasMaidsRoom;

  // ✨ 4. المرافق والمميزات (Amenities)
  // 🔴 الإجباري:
  FurnishingStatus furnishingStatus;
  // 🟢 الاختياري (Checkboxes):
  bool hasParking;
  bool hasCentralAc;
  bool hasPoolGym;
  bool hasSecurity;
  bool hasBalconyView;
  bool isPetFriendly;

  // 🖼️ 📝 5. الوسائط المرئية والوصف (Media & Description)
  // 🔴 الإجباري:
  List<String> photoUrls; // Min 3 required
  String titleAr;
  String titleEn;
  String titleHi;
  String descriptionAr;
  String descriptionEn;
  String descriptionHi;
  // 🟢 الاختياري:
  String? videoTourUrl;
  DateTime? availableFrom; // If null, "متاح فوراً"

  String countryCode; // 'EG' or 'AE'

  FastPropertyDraft({
    // Section 1: Location
    this.latitude = 30.0131,
    this.longitude = 31.4913,
    this.city = 'القاهرة',
    this.district = 'التجمع الخامس',
    this.streetAddress,
    this.buildingName,
    this.unitNumber,

    // Section 2: Financials
    this.monthlyRent = 25000,
    this.currency = 'EGP',
    this.paymentFrequency = PaymentFrequency.monthly,
    this.securityDeposit = 50000,
    this.isBillsIncluded = false,
    this.isNegotiable = true,

    // Section 3: Technical Specs
    this.propertyType = 'apartment',
    this.areaSqm = 180,
    this.bedrooms = 3,
    this.bathrooms = 2,
    this.floor = 3,
    this.buildingAge = BuildingAge.brandNew,
    this.hasMaidsRoom = false,

    // Section 4: Amenities
    this.furnishingStatus = FurnishingStatus.fullyFurnished,
    this.hasParking = false,
    this.hasCentralAc = false,
    this.hasPoolGym = false,
    this.hasSecurity = false,
    this.hasBalconyView = false,
    this.isPetFriendly = false,

    // Section 5: Media & Description
    List<String>? photoUrls,
    this.titleAr = 'شقة فاخرة 180م بتشطيب ألترا لوكس وإطلالة مميزة',
    this.titleEn = 'Luxury 180m² 3BR Apartment with Prime Views',
    this.titleHi = 'शानदार 180 वर्ग मीटर 3बीएचके अपार्टमेंट दृश्य के साथ',
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.descriptionHi = '',
    this.videoTourUrl,
    this.availableFrom,
    this.countryCode = 'EG',
  }) : photoUrls = photoUrls ?? [];

  Map<String, dynamic> toJson() => {
        // Section 1
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'district': district,
        'streetAddress': streetAddress,
        'buildingName': buildingName,
        'unitNumber': unitNumber,

        // Section 2
        'monthlyRent': monthlyRent,
        'currency': currency,
        'paymentFrequency': paymentFrequency.name,
        'securityDeposit': securityDeposit,
        'isBillsIncluded': isBillsIncluded,
        'isNegotiable': isNegotiable,

        // Section 3
        'propertyType': propertyType,
        'areaSqm': areaSqm,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'floor': floor,
        'buildingAge': buildingAge?.name,
        'hasMaidsRoom': hasMaidsRoom,

        // Section 4
        'furnishingStatus': furnishingStatus.name,
        'hasParking': hasParking,
        'hasCentralAc': hasCentralAc,
        'hasPoolGym': hasPoolGym,
        'hasSecurity': hasSecurity,
        'hasBalconyView': hasBalconyView,
        'isPetFriendly': isPetFriendly,

        // Section 5
        'photoUrls': photoUrls,
        'titleAr': titleAr,
        'titleEn': titleEn,
        'titleHi': titleHi,
        'descriptionAr': descriptionAr,
        'descriptionEn': descriptionEn,
        'descriptionHi': descriptionHi,
        'videoTourUrl': videoTourUrl,
        'availableFrom': availableFrom?.toIso8601String(),
        'countryCode': countryCode,
      };

  factory FastPropertyDraft.fromJson(Map<String, dynamic> json) {
    PaymentFrequency parseFrequency(dynamic val) {
      if (val == null) return PaymentFrequency.monthly;
      final str = val.toString();
      for (final f in PaymentFrequency.values) {
        if (f.name == str) return f;
      }
      return PaymentFrequency.monthly;
    }

    FurnishingStatus parseFurnishing(dynamic val) {
      if (val == null) return FurnishingStatus.fullyFurnished;
      final str = val.toString();
      for (final f in FurnishingStatus.values) {
        if (f.name == str) return f;
      }
      return FurnishingStatus.fullyFurnished;
    }

    BuildingAge? parseBuildingAge(dynamic val) {
      if (val == null) return null;
      final str = val.toString();
      for (final a in BuildingAge.values) {
        if (a.name == str) return a;
      }
      return null;
    }

    List<String> parsePhotos(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return FastPropertyDraft(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 30.0131,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 31.4913,
      city: json['city']?.toString() ?? 'القاهرة',
      district: json['district']?.toString() ?? 'التجمع الخامس',
      streetAddress: json['streetAddress']?.toString(),
      buildingName: json['buildingName']?.toString(),
      unitNumber: json['unitNumber']?.toString(),
      monthlyRent: (json['monthlyRent'] as num?)?.toDouble() ?? 25000,
      currency: json['currency']?.toString() ?? 'EGP',
      paymentFrequency: parseFrequency(json['paymentFrequency']),
      securityDeposit: (json['securityDeposit'] as num?)?.toDouble() ?? 50000,
      isBillsIncluded: json['isBillsIncluded'] == true,
      isNegotiable: json['isNegotiable'] != false,
      propertyType: json['propertyType']?.toString() ?? 'apartment',
      areaSqm: (json['areaSqm'] as num?)?.toInt() ?? 180,
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 3,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 2,
      floor: (json['floor'] as num?)?.toInt() ?? 3,
      buildingAge: parseBuildingAge(json['buildingAge']),
      hasMaidsRoom: json['hasMaidsRoom'] == true,
      furnishingStatus: parseFurnishing(json['furnishingStatus']),
      hasParking: json['hasParking'] == true,
      hasCentralAc: json['hasCentralAc'] == true,
      hasPoolGym: json['hasPoolGym'] == true,
      hasSecurity: json['hasSecurity'] == true,
      hasBalconyView: json['hasBalconyView'] == true,
      isPetFriendly: json['isPetFriendly'] == true,
      photoUrls: parsePhotos(json['photoUrls']),
      titleAr: json['titleAr']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      titleHi: json['titleHi']?.toString() ?? '',
      descriptionAr: json['descriptionAr']?.toString() ?? '',
      descriptionEn: json['descriptionEn']?.toString() ?? '',
      descriptionHi: json['descriptionHi']?.toString() ?? '',
      videoTourUrl: json['videoTourUrl']?.toString(),
      availableFrom: parseDate(json['availableFrom']),
      countryCode: json['countryCode']?.toString() ?? 'EG',
    );
  }
}

String deriveCityCode({
  required String city,
  required String district,
  required String countryCode,
}) {
  final text = '$city $district'.toLowerCase();
  if (countryCode == 'AE' || text.contains('دبي') || text.contains('dubai')) {
    if (text.contains('أبو ظبي') || text.contains('ابو ظبي') || text.contains('abu dhabi')) return 'abu_dhabi';
    if (text.contains('شارقة') || text.contains('sharjah')) return 'sharjah';
    if (text.contains('عجمان') || text.contains('ajman')) return 'ajman';
    if (text.contains('رأس الخيمة') || text.contains('راس الخيمة') || text.contains('ras al khaimah')) return 'ras_al_khaimah';
    return 'dubai';
  }
  // Egypt
  if (text.contains('إسكندرية') || text.contains('اسكندرية') || text.contains('alexandria') || text.contains('العجمي') || text.contains('سموحة')) {
    return 'alexandria';
  }
  if (text.contains('تجمع') || text.contains('قاهرة جديدة') || text.contains('new cairo')) {
    return 'new_cairo';
  }
  if (text.contains('زايد') || text.contains('zayed')) {
    return 'sheikh_zayed';
  }
  if (text.contains('أكتوبر') || text.contains('اكتوبر') || text.contains('october')) {
    return 'october';
  }
  if (text.contains('معادي') || text.contains('maadi')) {
    return 'maadi';
  }
  if (text.contains('ساحل') || text.contains('north coast')) {
    return 'north_coast';
  }
  return 'new_cairo';
}
