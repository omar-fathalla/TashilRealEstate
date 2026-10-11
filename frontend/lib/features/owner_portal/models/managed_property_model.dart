import '../../public_marketplace/models/property_item.dart';
import '../../fast_onboarding/models/property_onboarding_model.dart';

enum InstallmentPaymentStatus {
  paidOnline,
  paidCash,
  paidBankWire,
  due,
  overdue,
  upcoming,
}

class MonthlyInstallment {
  final String monthKey; // e.g., '2026-01', '2026-02'
  final String monthNumber; // '01', '02', etc.
  final Map<String, String> monthNames; // {'ar': 'يناير 2026', 'en': 'January 2026', 'hi': 'जनवरी 2026'}
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final InstallmentPaymentStatus status;
  final String? paymentMethod; // 'google_pay', 'apple_pay', 'cash', 'bank_wire', 'instapay'
  final String? transactionRef;
  final String? receiptNumber;
  final String? notes;

  final bool isDeleted;
  final DateTime? deletedAt;

  const MonthlyInstallment({
    required this.monthKey,
    required this.monthNumber,
    required this.monthNames,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    this.status = InstallmentPaymentStatus.upcoming,
    this.paymentMethod,
    this.transactionRef,
    this.receiptNumber,
    this.notes,
    this.isDeleted = false,
    this.deletedAt,
  });

  bool get isPaid =>
      status == InstallmentPaymentStatus.paidOnline ||
      status == InstallmentPaymentStatus.paidCash ||
      status == InstallmentPaymentStatus.paidBankWire;

  String getMonthName(String lang) => monthNames[lang] ?? monthNames['ar'] ?? monthKey;

  MonthlyInstallment copyWith({
    String? monthKey,
    String? monthNumber,
    Map<String, String>? monthNames,
    double? amount,
    DateTime? dueDate,
    DateTime? paidAt,
    InstallmentPaymentStatus? status,
    String? paymentMethod,
    String? transactionRef,
    String? receiptNumber,
    String? notes,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return MonthlyInstallment(
      monthKey: monthKey ?? this.monthKey,
      monthNumber: monthNumber ?? this.monthNumber,
      monthNames: monthNames ?? this.monthNames,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionRef: transactionRef ?? this.transactionRef,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthKey': monthKey,
      'monthNumber': monthNumber,
      'monthNames': monthNames,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'receiptNumber': receiptNumber,
      'notes': notes,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory MonthlyInstallment.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val != null) {
        try {
          return (val as dynamic).toDate();
        } catch (_) {}
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate();
      } catch (_) {}
      return null;
    }

    InstallmentPaymentStatus parseStatus(String? name) {
      if (name == null) return InstallmentPaymentStatus.upcoming;
      for (final s in InstallmentPaymentStatus.values) {
        if (s.name == name) return s;
      }
      return InstallmentPaymentStatus.upcoming;
    }

    final rawNames = map['monthNames'] ?? map['month_names'];
    final names = <String, String>{};
    if (rawNames is Map) {
      rawNames.forEach((k, v) {
        names[k.toString()] = v.toString();
      });
    }

    return MonthlyInstallment(
      monthKey: (map['monthKey'] ?? map['month_key'] ?? '').toString(),
      monthNumber: (map['monthNumber'] ?? map['month_number'] ?? '01').toString(),
      monthNames: names,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      dueDate: parseDate(map['dueDate'] ?? map['due_date']),
      paidAt: parseNullableDate(map['paidAt'] ?? map['paid_at']),
      status: parseStatus((map['status'] ?? '').toString()),
      paymentMethod: map['paymentMethod']?.toString() ?? map['payment_method']?.toString(),
      transactionRef: map['transactionRef']?.toString() ?? map['transaction_ref']?.toString(),
      receiptNumber: map['receiptNumber']?.toString() ?? map['receipt_number']?.toString(),
      notes: map['notes']?.toString(),
      isDeleted: map['isDeleted'] == true || map['is_deleted'] == true,
      deletedAt: parseNullableDate(map['deletedAt'] ?? map['deleted_at']),
    );
  }
}

enum PropertyRentalStatus {
  available, // شاغرة ومتاحة للإيجار
  rented,    // مؤجرة حالياً بعقد نشط
  maintenance, // تحت الصيانة
}

class ManagedPropertyModel {
  final String id;
  final String countryCode; // 'EG' or 'AE'
  final String currencyCode; // 'EGP' or 'AED'
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final Map<String, String> locations;
  final String cityCode;
  final String propertyTypeCode; // apartment, villa, duplex, chalet
  final String unitNumber;
  final String buildingName;
  final double pricePerMonth;
  final int bedrooms;
  final int bathrooms;
  final double areaSqM;
  final String image;
  final List<String> imageUrls;
  final bool isPublished; // هل الوحدة معروضة حالياً للجمهور في السوق العام؟
  final PropertyRentalStatus rentalStatus;
  final String? tenantName;
  final String? tenantPhone;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final List<MonthlyInstallment> installments;
  final List<MonthlyInstallment> archivedInstallments;

  const ManagedPropertyModel({
    required this.id,
    required this.countryCode,
    required this.currencyCode,
    required this.titles,
    required this.descriptions,
    required this.locations,
    required this.cityCode,
    required this.propertyTypeCode,
    required this.unitNumber,
    required this.buildingName,
    required this.pricePerMonth,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqM,
    required this.image,
    required this.imageUrls,
    this.isPublished = true,
    this.rentalStatus = PropertyRentalStatus.rented,
    this.tenantName,
    this.tenantPhone,
    this.leaseStartDate,
    this.leaseEndDate,
    this.installments = const [],
    this.archivedInstallments = const [],
  });

  String getTitle(String lang) => titles[lang] ?? titles['ar'] ?? '';
  String getDescription(String lang) => descriptions[lang] ?? descriptions['ar'] ?? '';
  String getLocation(String lang) => locations[lang] ?? locations['ar'] ?? '';

  bool get isOccupied => rentalStatus == PropertyRentalStatus.rented;
  bool get isAvailable => rentalStatus == PropertyRentalStatus.available;

  double get totalCollectedRevenue => (installments + archivedInstallments)
      .where((inst) => inst.isPaid)
      .fold(0.0, (sum, inst) => sum + inst.amount);

  double get totalPendingDue => installments
      .where((inst) => inst.status == InstallmentPaymentStatus.due || inst.status == InstallmentPaymentStatus.overdue)
      .fold(0.0, (sum, inst) => sum + inst.amount);

  int get paidMonthsCount => (installments + archivedInstallments).where((inst) => inst.isPaid).length;

  ManagedPropertyModel copyWith({
    String? id,
    String? countryCode,
    String? currencyCode,
    Map<String, String>? titles,
    Map<String, String>? descriptions,
    Map<String, String>? locations,
    String? cityCode,
    String? propertyTypeCode,
    String? unitNumber,
    String? buildingName,
    double? pricePerMonth,
    int? bedrooms,
    int? bathrooms,
    double? areaSqM,
    String? image,
    List<String>? imageUrls,
    bool? isPublished,
    PropertyRentalStatus? rentalStatus,
    bool clearTenant = false,
    String? tenantName,
    String? tenantPhone,
    DateTime? leaseStartDate,
    DateTime? leaseEndDate,
    List<MonthlyInstallment>? installments,
    List<MonthlyInstallment>? archivedInstallments,
  }) {
    return ManagedPropertyModel(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      titles: titles ?? this.titles,
      descriptions: descriptions ?? this.descriptions,
      locations: locations ?? this.locations,
      cityCode: cityCode ?? this.cityCode,
      propertyTypeCode: propertyTypeCode ?? this.propertyTypeCode,
      unitNumber: unitNumber ?? this.unitNumber,
      buildingName: buildingName ?? this.buildingName,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      areaSqM: areaSqM ?? this.areaSqM,
      image: image ?? this.image,
      imageUrls: imageUrls ?? this.imageUrls,
      isPublished: isPublished ?? this.isPublished,
      rentalStatus: rentalStatus ?? this.rentalStatus,
      tenantName: clearTenant ? null : (tenantName ?? this.tenantName),
      tenantPhone: clearTenant ? null : (tenantPhone ?? this.tenantPhone),
      leaseStartDate: clearTenant ? null : (leaseStartDate ?? this.leaseStartDate),
      leaseEndDate: clearTenant ? null : (leaseEndDate ?? this.leaseEndDate),
      installments: installments ?? this.installments,
      archivedInstallments: archivedInstallments ?? this.archivedInstallments,
    );
  }

  /// Converts this managed property to a visitor-facing PropertyItem for marketplace display
  PropertyItem toPropertyItem() {
    final images = imageUrls.isNotEmpty ? imageUrls : [image];
    return PropertyItem(
      id: id,
      countryCode: countryCode,
      currencyCode: currencyCode,
      titles: titles,
      descriptions: descriptions,
      propertyTypeCode: propertyTypeCode,
      locations: locations,
      cityCode: cityCode,
      pricePerMonth: pricePerMonth,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      areaSqM: areaSqM,
      imageUrls: images,
      amenitiesMap: const {
        'ar': ['مفروش بالكامل', 'تكييف مركزي', 'موقف سيارات خاص', 'أمن وحراسة 24/7'],
        'en': ['Fully Furnished', 'Central A/C', 'Private Parking', '24/7 Security'],
        'hi': ['पूरी तरह सुसज्जित', 'केंद्रीय एसी', 'निजी पार्किंग', '24/7 सुरक्षा'],
      },
      isFurnished: true,
      isFeatured: true,
      agencyNames: const {
        'ar': 'شركة تسهيل لإدارة الأملاك',
        'en': 'Tashil Property Management',
        'hi': 'तशिल संपत्ति प्रबंधन',
      },
      agencyPhone: '+20 100 123 4567',
      rating: 5.0,
    );
  }

  /// Converts this managed property to FastPropertyDraft for editing in the onboarding dialog
  FastPropertyDraft toDraft() {
    final locAr = getLocation('ar');
    String city = '';
    String district = '';
    if (locAr.contains('،')) {
      final parts = locAr.split('،');
      district = parts[0].trim();
      city = parts.length > 1 ? parts[1].trim() : '';
    } else if (locAr.contains(',')) {
      final parts = locAr.split(',');
      district = parts[0].trim();
      city = parts.length > 1 ? parts[1].trim() : '';
    } else {
      district = locAr.trim();
      city = '';
    }

    final images = imageUrls.isNotEmpty ? List<String>.from(imageUrls) : [image];

    return FastPropertyDraft(
      countryCode: countryCode,
      currency: currencyCode,
      city: city,
      district: district,
      buildingName: buildingName,
      unitNumber: unitNumber,
      monthlyRent: pricePerMonth,
      securityDeposit: pricePerMonth * 2,
      areaSqm: areaSqM.toInt(),
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      propertyType: propertyTypeCode,
      titleAr: getTitle('ar'),
      titleEn: getTitle('en'),
      titleHi: getTitle('hi'),
      descriptionAr: getDescription('ar'),
      descriptionEn: getDescription('en'),
      descriptionHi: getDescription('hi'),
      photoUrls: images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'titles': titles,
      'descriptions': descriptions,
      'locations': locations,
      'cityCode': cityCode,
      'propertyTypeCode': propertyTypeCode,
      'unitNumber': unitNumber,
      'buildingName': buildingName,
      'pricePerMonth': pricePerMonth,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqM': areaSqM,
      'image': image,
      'imageUrls': imageUrls,
      'isPublished': isPublished,
      'rentalStatus': rentalStatus.name,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'leaseStartDate': leaseStartDate?.toIso8601String(),
      'leaseEndDate': leaseEndDate?.toIso8601String(),
      'installments': installments.map((i) => i.toMap()).toList(),
      'archivedInstallments': archivedInstallments.map((i) => i.toMap()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory ManagedPropertyModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate();
      } catch (_) {}
      return null;
    }

    Map<String, String> parseStringMap(dynamic val, [String fallback = '']) {
      final res = <String, String>{};
      if (val is Map) {
        val.forEach((k, v) {
          res[k.toString()] = v.toString();
        });
      }
      if (res.isEmpty && fallback.isNotEmpty) {
        res['ar'] = fallback;
        res['en'] = fallback;
        res['hi'] = fallback;
      }
      return res;
    }

    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    PropertyRentalStatus parseRentalStatus(String? name) {
      if (name == null) return PropertyRentalStatus.available;
      for (final s in PropertyRentalStatus.values) {
        if (s.name == name) return s;
      }
      return PropertyRentalStatus.available;
    }

    final rawInstallments = map['installments'];
    final instList = <MonthlyInstallment>[];
    if (rawInstallments is List) {
      for (final item in rawInstallments) {
        if (item is Map<String, dynamic>) {
          instList.add(MonthlyInstallment.fromMap(item));
        } else if (item is Map) {
          instList.add(MonthlyInstallment.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawArchived = map['archivedInstallments'];
    final archivedList = <MonthlyInstallment>[];
    if (rawArchived is List) {
      for (final item in rawArchived) {
        if (item is Map<String, dynamic>) {
          archivedList.add(MonthlyInstallment.fromMap(item));
        } else if (item is Map) {
          archivedList.add(MonthlyInstallment.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final id = docId ?? map['id']?.toString() ?? 'prop-${DateTime.now().millisecondsSinceEpoch}';
    final fallbackTitle = map['title_ar']?.toString() ?? map['title']?.toString() ?? '';
    final fallbackDesc = map['description_ar']?.toString() ?? map['description']?.toString() ?? '';
    final fallbackLoc = map['location']?.toString() ?? (map['district'] != null ? '${map['district']}، ${map['city']}' : '');

    final titles = parseStringMap(map['titles'], fallbackTitle);
    final descriptions = parseStringMap(map['descriptions'], fallbackDesc);
    final locations = parseStringMap(map['locations'], fallbackLoc);

    final imageUrls = parseStringList(map['imageUrls'] ?? map['photo_urls'] ?? map['images']);
    final singleImage = map['image']?.toString() ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
    if (imageUrls.isEmpty && singleImage.isNotEmpty) {
      imageUrls.add(singleImage);
    }

    return ManagedPropertyModel(
      id: id,
      countryCode: map['countryCode']?.toString() ?? map['country_code']?.toString() ?? 'EG',
      currencyCode: map['currencyCode']?.toString() ?? map['currency_code']?.toString() ?? 'EGP',
      titles: titles,
      descriptions: descriptions,
      locations: locations,
      cityCode: map['cityCode']?.toString() ?? map['city_code']?.toString() ?? 'new_cairo',
      propertyTypeCode: map['propertyTypeCode']?.toString() ?? map['property_type']?.toString() ?? 'apartment',
      unitNumber: map['unitNumber']?.toString() ?? map['unit_number']?.toString() ?? '',
      buildingName: map['buildingName']?.toString() ?? map['building_name']?.toString() ?? '',
      pricePerMonth: (map['pricePerMonth'] is num)
          ? (map['pricePerMonth'] as num).toDouble()
          : (map['monthly_rent'] is num)
              ? (map['monthly_rent'] as num).toDouble()
              : 0.0,
      bedrooms: (map['bedrooms'] is num) ? (map['bedrooms'] as num).toInt() : 1,
      bathrooms: (map['bathrooms'] is num) ? (map['bathrooms'] as num).toInt() : 1,
      areaSqM: (map['areaSqM'] is num)
          ? (map['areaSqM'] as num).toDouble()
          : (map['area_sqm'] is num)
              ? (map['area_sqm'] as num).toDouble()
              : 100.0,
      image: singleImage,
      imageUrls: imageUrls,
      isPublished: map['isPublished'] == true || map['is_published'] == true,
      rentalStatus: parseRentalStatus(map['rentalStatus']?.toString() ?? map['rental_status']?.toString()),
      tenantName: map['tenantName']?.toString() ?? map['tenant_name']?.toString(),
      tenantPhone: map['tenantPhone']?.toString() ?? map['tenant_phone']?.toString(),
      leaseStartDate: parseNullableDate(map['leaseStartDate'] ?? map['lease_start_date']),
      leaseEndDate: parseNullableDate(map['leaseEndDate'] ?? map['lease_end_date']),
      installments: instList,
      archivedInstallments: archivedList,
    );
  }
}
