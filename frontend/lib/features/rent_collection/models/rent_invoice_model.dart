class TenantInfo {
  final String name;
  final String phone;
  final String email;
  final String idNumber; // National ID (EG) or Emirates ID (AE)

  const TenantInfo({
    required this.name,
    required this.phone,
    required this.email,
    required this.idNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'idNumber': idNumber,
      };

  factory TenantInfo.fromJson(Map<String, dynamic> json) => TenantInfo(
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        idNumber: json['idNumber'] ?? '',
      );
}

class OwnerPayoutInfo {
  final String name;
  final String bankName;
  final String iban;
  final String accountNumber;
  final String walletOrVpa; // Mobile wallet number or InstaPay VPA

  const OwnerPayoutInfo({
    required this.name,
    required this.bankName,
    required this.iban,
    required this.accountNumber,
    this.walletOrVpa = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'bankName': bankName,
        'iban': iban,
        'accountNumber': accountNumber,
        'walletOrVpa': walletOrVpa,
      };

  factory OwnerPayoutInfo.fromJson(Map<String, dynamic> json) => OwnerPayoutInfo(
        name: json['name'] ?? '',
        bankName: json['bankName'] ?? '',
        iban: json['iban'] ?? '',
        accountNumber: json['accountNumber'] ?? '',
        walletOrVpa: json['walletOrVpa'] ?? '',
      );

  OwnerPayoutInfo copyWith({
    String? name,
    String? bankName,
    String? iban,
    String? accountNumber,
    String? walletOrVpa,
  }) {
    return OwnerPayoutInfo(
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      iban: iban ?? this.iban,
      accountNumber: accountNumber ?? this.accountNumber,
      walletOrVpa: walletOrVpa ?? this.walletOrVpa,
    );
  }
}

class RentInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String contractNumber;
  final String countryCode; // 'EG' or 'AE'
  final String unitTitle;
  final String unitNumber;
  final String buildingName;
  final String district;
  final TenantInfo tenant;
  final OwnerPayoutInfo owner;
  final double baseAmount;
  final DateTime dueDate;
  final int gracePeriodDays;
  final double dailyPenaltyRate; // e.g. 50 EGP/day or 100 AED/day
  final String? propertyId;
  final String? monthKey;
  final String propertyTypeCode;
  
  // Status: 'paid', 'due_soon', 'overdue'
  String status;
  
  // Payment info
  DateTime? paidAt;
  String? paymentMethod; // 'card', 'vodafone_cash', 'instapay', 'fawry', 'apple_pay', 'direct_debit', 'iban_wire'
  String? transactionReference; // Gateway Transaction ID
  
  // Split Payout info
  double platformFeePercent; // e.g. 1.5%
  String payoutStatus; // 'pending', 'transferred_to_owner', 'failed'
  String? payoutReference; // Bank Settlement ID e.g. 'PAYOUT-NBE-88219'
  DateTime? payoutSettledAt;
  
  // Reminder tracking
  int reminderCount;
  DateTime? lastReminderSentAt;
  bool legalWarningIssued;

  // Soft Delete / Trash tracking (Auto-purge after 7 days)
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? notes;

  RentInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.contractNumber,
    required this.countryCode,
    required this.unitTitle,
    required this.unitNumber,
    required this.buildingName,
    required this.district,
    required this.tenant,
    required this.owner,
    required this.baseAmount,
    required this.dueDate,
    this.gracePeriodDays = 5,
    this.dailyPenaltyRate = 50.0,
    this.propertyId,
    this.monthKey,
    this.propertyTypeCode = 'apartment',
    required this.status,
    this.paidAt,
    this.paymentMethod,
    this.transactionReference,
    this.platformFeePercent = 1.5,
    this.payoutStatus = 'pending',
    this.payoutReference,
    this.payoutSettledAt,
    this.reminderCount = 0,
    this.lastReminderSentAt,
    this.legalWarningIssued = false,
    this.isDeleted = false,
    this.deletedAt,
    this.notes,
  });

  /// Permanent deletion deadline (7 days from deletion date)
  DateTime? get permanentDeleteAt => deletedAt?.add(const Duration(days: 7));

  /// Remaining days before permanent automatic purge
  int get remainingDaysBeforePermanentDelete {
    if (deletedAt == null) return 7;
    final deadline = deletedAt!.add(const Duration(days: 7));
    final diff = deadline.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : 0;
  }

  // Calculate overdue days past grace period
  int get overdueDays {
    if (status == 'paid') return 0;
    final now = DateTime.now();
    final graceDeadline = dueDate.add(Duration(days: gracePeriodDays));
    if (now.isAfter(graceDeadline)) {
      return now.difference(graceDeadline).inDays;
    }
    return 0;
  }

  // Calculate accumulated late penalty
  double get latePenaltyAmount {
    if (overdueDays <= 0) return 0.0;
    return overdueDays * dailyPenaltyRate;
  }

  // Total invoice amount due (base + penalties)
  double get totalAmountDue => baseAmount + latePenaltyAmount;

  // Platform processing fee amount
  double get platformFeeAmount => (baseAmount * platformFeePercent) / 100.0;

  // Net amount transferred automatically to the landlord
  double get netPayoutToOwner => totalAmountDue - platformFeeAmount;

  // Check if invoice is in critical overdue stage (over 15 days)
  bool get isCriticalOverdue => overdueDays >= 15;

  RentInvoiceModel copyWith({
    double? baseAmount,
    DateTime? dueDate,
    String? status,
    DateTime? paidAt,
    String? paymentMethod,
    String? transactionReference,
    String? payoutStatus,
    String? payoutReference,
    DateTime? payoutSettledAt,
    int? reminderCount,
    DateTime? lastReminderSentAt,
    bool? legalWarningIssued,
    String? propertyId,
    String? monthKey,
    String? propertyTypeCode,
    bool? isDeleted,
    DateTime? deletedAt,
    String? notes,
    OwnerPayoutInfo? owner,
    TenantInfo? tenant,
  }) {
    return RentInvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber,
      contractNumber: contractNumber,
      countryCode: countryCode,
      unitTitle: unitTitle,
      unitNumber: unitNumber,
      buildingName: buildingName,
      district: district,
      tenant: tenant ?? this.tenant,
      owner: owner ?? this.owner,
      baseAmount: baseAmount ?? this.baseAmount,
      dueDate: dueDate ?? this.dueDate,
      gracePeriodDays: gracePeriodDays,
      dailyPenaltyRate: dailyPenaltyRate,
      propertyId: propertyId ?? this.propertyId,
      monthKey: monthKey ?? this.monthKey,
      propertyTypeCode: propertyTypeCode ?? this.propertyTypeCode,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      platformFeePercent: platformFeePercent,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      payoutReference: payoutReference ?? this.payoutReference,
      payoutSettledAt: payoutSettledAt ?? this.payoutSettledAt,
      reminderCount: reminderCount ?? this.reminderCount,
      lastReminderSentAt: lastReminderSentAt ?? this.lastReminderSentAt,
      legalWarningIssued: legalWarningIssued ?? this.legalWarningIssued,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      notes: notes ?? this.notes,
    );
  }
}
