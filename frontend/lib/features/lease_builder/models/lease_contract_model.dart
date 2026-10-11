class ContractParty {
  final String name;
  final String nationalIdOrEmiratesId;
  final String? passportNumber;
  final String nationality;
  final String phone;
  final String email;
  final String address;
  final bool isLessor;

  const ContractParty({
    required this.name,
    required this.nationalIdOrEmiratesId,
    this.passportNumber,
    required this.nationality,
    required this.phone,
    required this.email,
    required this.address,
    required this.isLessor,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'nationalIdOrEmiratesId': nationalIdOrEmiratesId,
    'passportNumber': passportNumber,
    'nationality': nationality,
    'phone': phone,
    'email': email,
    'address': address,
    'isLessor': isLessor,
  };

  factory ContractParty.fromMap(Map<String, dynamic> map) => ContractParty(
    name: map['name'] ?? '',
    nationalIdOrEmiratesId: map['nationalIdOrEmiratesId'] ?? '',
    passportNumber: map['passportNumber'],
    nationality: map['nationality'] ?? '',
    phone: map['phone'] ?? '',
    email: map['email'] ?? '',
    address: map['address'] ?? '',
    isLessor: map['isLessor'] ?? false,
  );
}

class LeasePropertySpec {
  final String propertyTitle;
  final String unitNumber;
  final String buildingName;
  final String district;
  final String city;
  final String countryCode; // 'EG' | 'AE'
  final int areaSqm;
  final String propertyType; // 'apartment', 'villa', 'commercial'
  final String? makaniNumber; // UAE
  final String? dewaPremiseNumber; // UAE
  final String? titleDeedNumber; // UAE / Egypt
  final String? floorNumber;

  const LeasePropertySpec({
    required this.propertyTitle,
    required this.unitNumber,
    required this.buildingName,
    required this.district,
    required this.city,
    required this.countryCode,
    required this.areaSqm,
    required this.propertyType,
    this.makaniNumber,
    this.dewaPremiseNumber,
    this.titleDeedNumber,
    this.floorNumber,
  });

  Map<String, dynamic> toMap() => {
    'propertyTitle': propertyTitle,
    'unitNumber': unitNumber,
    'buildingName': buildingName,
    'district': district,
    'city': city,
    'countryCode': countryCode,
    'areaSqm': areaSqm,
    'propertyType': propertyType,
    'makaniNumber': makaniNumber,
    'dewaPremiseNumber': dewaPremiseNumber,
    'titleDeedNumber': titleDeedNumber,
    'floorNumber': floorNumber,
  };

  factory LeasePropertySpec.fromMap(Map<String, dynamic> map) => LeasePropertySpec(
    propertyTitle: map['propertyTitle'] ?? '',
    unitNumber: map['unitNumber'] ?? '',
    buildingName: map['buildingName'] ?? '',
    district: map['district'] ?? '',
    city: map['city'] ?? '',
    countryCode: map['countryCode'] ?? 'EG',
    areaSqm: map['areaSqm'] ?? 100,
    propertyType: map['propertyType'] ?? 'apartment',
    makaniNumber: map['makaniNumber'],
    dewaPremiseNumber: map['dewaPremiseNumber'],
    titleDeedNumber: map['titleDeedNumber'],
    floorNumber: map['floorNumber'],
  );
}

class ChequeDetail {
  final String chequeNumber;
  final String bankName;
  final DateTime dueDate;
  final double amount;
  final String status; // 'pending', 'cleared', 'bounced'

  const ChequeDetail({
    required this.chequeNumber,
    required this.bankName,
    required this.dueDate,
    required this.amount,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'chequeNumber': chequeNumber,
    'bankName': bankName,
    'dueDate': dueDate.toIso8601String(),
    'amount': amount,
    'status': status,
  };

  factory ChequeDetail.fromMap(Map<String, dynamic> map) => ChequeDetail(
    chequeNumber: map['chequeNumber'] ?? '',
    bankName: map['bankName'] ?? '',
    dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    status: map['status'] ?? 'pending',
  );
}

class FinancialTerms {
  final double totalRentAmount;
  final double monthlyRentEquivalent;
  final String currencyCode; // 'EGP' | 'AED'
  final String paymentFrequency; // 'monthly', 'quarterly', 'semi_annual', 'annual'
  final int numberOfCheques;
  final double securityDeposit;
  final double annualIncreasePercentage;
  final bool isVatApplicable;
  final double vatPercentage;
  final List<ChequeDetail> cheques;

  const FinancialTerms({
    required this.totalRentAmount,
    required this.monthlyRentEquivalent,
    required this.currencyCode,
    required this.paymentFrequency,
    required this.numberOfCheques,
    required this.securityDeposit,
    required this.annualIncreasePercentage,
    this.isVatApplicable = false,
    this.vatPercentage = 5.0,
    this.cheques = const [],
  });

  Map<String, dynamic> toMap() => {
    'totalRentAmount': totalRentAmount,
    'monthlyRentEquivalent': monthlyRentEquivalent,
    'currencyCode': currencyCode,
    'paymentFrequency': paymentFrequency,
    'numberOfCheques': numberOfCheques,
    'securityDeposit': securityDeposit,
    'annualIncreasePercentage': annualIncreasePercentage,
    'isVatApplicable': isVatApplicable,
    'vatPercentage': vatPercentage,
    'cheques': cheques.map((c) => c.toMap()).toList(),
  };

  factory FinancialTerms.fromMap(Map<String, dynamic> map) => FinancialTerms(
    totalRentAmount: (map['totalRentAmount'] as num?)?.toDouble() ?? 0.0,
    monthlyRentEquivalent: (map['monthlyRentEquivalent'] as num?)?.toDouble() ?? 0.0,
    currencyCode: map['currencyCode'] ?? 'EGP',
    paymentFrequency: map['paymentFrequency'] ?? 'monthly',
    numberOfCheques: map['numberOfCheques'] ?? 1,
    securityDeposit: (map['securityDeposit'] as num?)?.toDouble() ?? 0.0,
    annualIncreasePercentage: (map['annualIncreasePercentage'] as num?)?.toDouble() ?? 0.0,
    isVatApplicable: map['isVatApplicable'] ?? false,
    vatPercentage: (map['vatPercentage'] as num?)?.toDouble() ?? 5.0,
    cheques: (map['cheques'] as List<dynamic>?)
            ?.map((c) => ChequeDetail.fromMap(c as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

class LegalClause {
  final String id;
  final String titleAr;
  final String titleEn;
  final String titleHi;
  final String bodyAr;
  final String bodyEn;
  final String bodyHi;
  final bool isMandatory;
  final bool isEnabled;
  final String? lawReference;

  const LegalClause({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleHi,
    required this.bodyAr,
    required this.bodyEn,
    required this.bodyHi,
    required this.isMandatory,
    this.isEnabled = true,
    this.lawReference,
  });

  LegalClause copyWith({bool? isEnabled}) {
    return LegalClause(
      id: id,
      titleAr: titleAr,
      titleEn: titleEn,
      titleHi: titleHi,
      bodyAr: bodyAr,
      bodyEn: bodyEn,
      bodyHi: bodyHi,
      isMandatory: isMandatory,
      isEnabled: isEnabled ?? this.isEnabled,
      lawReference: lawReference,
    );
  }

  String getLocalizedTitle(String langCode) {
    if (langCode == 'en') return titleEn;
    if (langCode == 'hi') return titleHi;
    return titleAr;
  }

  String getLocalizedBody(String langCode) {
    if (langCode == 'en') return bodyEn;
    if (langCode == 'hi') return bodyHi;
    return bodyAr;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'titleAr': titleAr,
    'titleEn': titleEn,
    'titleHi': titleHi,
    'bodyAr': bodyAr,
    'bodyEn': bodyEn,
    'bodyHi': bodyHi,
    'isMandatory': isMandatory,
    'isEnabled': isEnabled,
    'lawReference': lawReference,
  };

  factory LegalClause.fromMap(Map<String, dynamic> map) => LegalClause(
    id: map['id'] ?? '',
    titleAr: map['titleAr'] ?? '',
    titleEn: map['titleEn'] ?? '',
    titleHi: map['titleHi'] ?? '',
    bodyAr: map['bodyAr'] ?? '',
    bodyEn: map['bodyEn'] ?? '',
    bodyHi: map['bodyHi'] ?? '',
    isMandatory: map['isMandatory'] ?? false,
    isEnabled: map['isEnabled'] ?? true,
    lawReference: map['lawReference'],
  );
}

class DigitalSignature {
  final String signerName;
  final String signerRole; // 'lessor' | 'tenant'
  final String nationalIdOrEmiratesId;
  final DateTime signedAt;
  final String ipAddress;
  final String verificationHash;
  final String certificateId;
  final List<List<double>>? signatureStrokePoints;

  const DigitalSignature({
    required this.signerName,
    required this.signerRole,
    required this.nationalIdOrEmiratesId,
    required this.signedAt,
    required this.ipAddress,
    required this.verificationHash,
    required this.certificateId,
    this.signatureStrokePoints,
  });

  Map<String, dynamic> toMap() => {
    'signerName': signerName,
    'signerRole': signerRole,
    'nationalIdOrEmiratesId': nationalIdOrEmiratesId,
    'signedAt': signedAt.toIso8601String(),
    'ipAddress': ipAddress,
    'verificationHash': verificationHash,
    'certificateId': certificateId,
    'signatureStrokePoints': signatureStrokePoints,
  };

  factory DigitalSignature.fromMap(Map<String, dynamic> map) => DigitalSignature(
    signerName: map['signerName'] ?? '',
    signerRole: map['signerRole'] ?? '',
    nationalIdOrEmiratesId: map['nationalIdOrEmiratesId'] ?? '',
    signedAt: DateTime.tryParse(map['signedAt'] ?? '') ?? DateTime.now(),
    ipAddress: map['ipAddress'] ?? '127.0.0.1',
    verificationHash: map['verificationHash'] ?? '',
    certificateId: map['certificateId'] ?? '',
    signatureStrokePoints: (map['signatureStrokePoints'] as List<dynamic>?)
        ?.map((stroke) => (stroke as List<dynamic>).map((p) => (p as num).toDouble()).toList())
        .toList(),
  );
}

class LeaseContractModel {
  final String id;
  final String contractNumber;
  final String countryCode; // 'EG' | 'AE'
  final String status; // 'draft', 'pending_signatures', 'active', 'expired', 'terminated'
  final DateTime startDate;
  final DateTime endDate;
  final ContractParty lessor;
  final ContractParty tenant;
  final LeasePropertySpec property;
  final FinancialTerms financialTerms;
  final List<LegalClause> clauses;
  final DigitalSignature? lessorSignature;
  final DigitalSignature? tenantSignature;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? registeredRegistryId; // e.g. Ejari Number / الشهر العقاري
  final bool isDeleted;
  final DateTime? deletedAt;

  const LeaseContractModel({
    required this.id,
    required this.contractNumber,
    required this.countryCode,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.lessor,
    required this.tenant,
    required this.property,
    required this.financialTerms,
    required this.clauses,
    this.lessorSignature,
    this.tenantSignature,
    required this.createdAt,
    required this.updatedAt,
    this.registeredRegistryId,
    this.isDeleted = false,
    this.deletedAt,
  });

  bool get isFullySigned => lessorSignature != null && tenantSignature != null;

  int get durationInMonths {
    return ((endDate.year - startDate.year) * 12) + (endDate.month - startDate.month);
  }

  LeaseContractModel copyWith({
    String? id,
    String? contractNumber,
    String? countryCode,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    ContractParty? lessor,
    ContractParty? tenant,
    LeasePropertySpec? property,
    FinancialTerms? financialTerms,
    List<LegalClause>? clauses,
    DigitalSignature? lessorSignature,
    DigitalSignature? tenantSignature,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? registeredRegistryId,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return LeaseContractModel(
      id: id ?? this.id,
      contractNumber: contractNumber ?? this.contractNumber,
      countryCode: countryCode ?? this.countryCode,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lessor: lessor ?? this.lessor,
      tenant: tenant ?? this.tenant,
      property: property ?? this.property,
      financialTerms: financialTerms ?? this.financialTerms,
      clauses: clauses ?? this.clauses,
      lessorSignature: lessorSignature ?? this.lessorSignature,
      tenantSignature: tenantSignature ?? this.tenantSignature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      registeredRegistryId: registeredRegistryId ?? this.registeredRegistryId,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'contractNumber': contractNumber,
    'countryCode': countryCode,
    'status': status,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'lessor': lessor.toMap(),
    'tenant': tenant.toMap(),
    'property': property.toMap(),
    'financialTerms': financialTerms.toMap(),
    'clauses': clauses.map((c) => c.toMap()).toList(),
    'lessorSignature': lessorSignature?.toMap(),
    'tenantSignature': tenantSignature?.toMap(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'registeredRegistryId': registeredRegistryId,
    'isDeleted': isDeleted,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory LeaseContractModel.fromMap(Map<String, dynamic> map, String id) => LeaseContractModel(
    id: id,
    contractNumber: map['contractNumber'] ?? '',
    countryCode: map['countryCode'] ?? 'EG',
    status: map['status'] ?? 'draft',
    startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
    endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 365)),
    lessor: ContractParty.fromMap(map['lessor'] ?? {}),
    tenant: ContractParty.fromMap(map['tenant'] ?? {}),
    property: LeasePropertySpec.fromMap(map['property'] ?? {}),
    financialTerms: FinancialTerms.fromMap(map['financialTerms'] ?? {}),
    clauses: (map['clauses'] as List<dynamic>?)
            ?.map((c) => LegalClause.fromMap(c as Map<String, dynamic>))
            .toList() ??
        const [],
    lessorSignature: map['lessorSignature'] != null ? DigitalSignature.fromMap(map['lessorSignature']) : null,
    tenantSignature: map['tenantSignature'] != null ? DigitalSignature.fromMap(map['tenantSignature']) : null,
    createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    registeredRegistryId: map['registeredRegistryId'],
    isDeleted: map['isDeleted'] ?? false,
    deletedAt: map['deletedAt'] != null ? DateTime.tryParse(map['deletedAt']) : null,
  );
}
