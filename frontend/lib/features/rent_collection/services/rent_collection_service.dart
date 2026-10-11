import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/services/storage/local_storage_service.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';

/// Central Real-Time Rent Collection & Automated Payout Service.
///
/// Fully synchronized with [PropertyLifecycleService]:
/// 1. Dynamic invoice generation from live rented properties and installments.
/// 2. Bidirectional payment execution: paying an invoice updates the property installment.
/// 3. Recording manual installment payments in Owner Portal reflects immediately here.
/// 4. Lease termination gracefully archives paid invoices and closes unaccrued invoices.
/// 5. Persistent soft-delete (Trash) and permanent delete states across browser reloads.
class RentCollectionService {
  static final RentCollectionService _instance = RentCollectionService._internal();
  factory RentCollectionService() => _instance;

  RentCollectionService._internal() {
    _loadPersistedDeletedState();
    _initSampleInvoices();
    PropertyLifecycleService().propertiesNotifier.addListener(syncFromProperties);
    syncFromProperties();
  }

  late final ValueNotifier<List<RentInvoiceModel>> invoicesNotifier;
  final Map<String, DateTime> _softDeletedInvoices = {};
  final Set<String> _permanentlyDeletedInvoices = {};

  static const String _softDeletedKey = 'tashil_soft_deleted_invoices_v1';
  static const String _permanentlyDeletedKey = 'tashil_permanently_deleted_invoices_v1';

  bool _isSyncing = false;
  bool _isPurging = false;

  void _loadPersistedDeletedState() {
    final softMap = LocalStorageService().getStringMap(_softDeletedKey);
    if (softMap != null) {
      _softDeletedInvoices.clear();
      softMap.forEach((id, dtStr) {
        final parsed = DateTime.tryParse(dtStr);
        if (parsed != null) {
          _softDeletedInvoices[id] = parsed;
        }
      });
    }

    final permList = LocalStorageService().getStringList(_permanentlyDeletedKey);
    if (permList != null) {
      _permanentlyDeletedInvoices.clear();
      _permanentlyDeletedInvoices.addAll(permList);
    }
  }

  void _savePersistedDeletedState() {
    final map = _softDeletedInvoices.map((k, v) => MapEntry(k, v.toIso8601String()));
    LocalStorageService().setStringMap(_softDeletedKey, map);
    LocalStorageService().setStringList(_permanentlyDeletedKey, _permanentlyDeletedInvoices.toList());
  }

  void _initSampleInvoices() {
    invoicesNotifier = ValueNotifier<List<RentInvoiceModel>>(_generateSampleInvoices());
  }

  /// Reset invoices to defaults and re-sync (useful for test isolation)
  void resetToDefaults() {
    _softDeletedInvoices.clear();
    _permanentlyDeletedInvoices.clear();
    _savePersistedDeletedState();
    invoicesNotifier.value = _generateSampleInvoices();
    syncFromProperties();
  }

  List<RentInvoiceModel> _generateSampleInvoices() {
    final now = DateTime.now();

    final rawSamples = <RentInvoiceModel>[
      // --- Egypt Invoices (EGP) ---
      // 1. Paid Invoice with Instant Payout to Owner Bank Account
      RentInvoiceModel(
        id: 'inv_eg_001',
        invoiceNumber: 'INV-EG-2026-0801',
        contractNumber: 'EG-2026-CAI-8821',
        countryCode: 'EG',
        unitTitle: 'شقة فاخرة بإطلالة مفتوحة',
        unitNumber: '402',
        buildingName: 'برج الياسمين',
        district: 'القاهرة الجديدة',
        propertyId: 'prop-eg-101',
        monthKey: '2026-01',
        tenant: const TenantInfo(
          name: 'أحمد محمود القاضي',
          phone: '+201012345678',
          email: 'ahmed.kadi@gmail.com',
          idNumber: '29201011234567',
        ),
        owner: const OwnerPayoutInfo(
          name: 'م. عمر طارق فتح الله',
          bankName: 'البنك الأهلي المصري (NBE)',
          iban: 'EG380003000012345678901234567',
          accountNumber: '1234567890',
          walletOrVpa: 'omar.fathalla@instapay',
        ),
        baseAmount: 25000.0,
        dueDate: now.subtract(const Duration(days: 15)),
        gracePeriodDays: 5,
        dailyPenaltyRate: 50.0,
        status: 'paid',
        paidAt: now.subtract(const Duration(days: 14)),
        paymentMethod: 'card',
        transactionReference: 'PAY-MEEZA-994821',
        platformFeePercent: 1.5,
        payoutStatus: 'transferred_to_owner',
        payoutReference: 'SETTLE-NBE-882194',
        payoutSettledAt: now.subtract(const Duration(days: 14)),
        reminderCount: 0,
      ),

      // 2. Overdue Invoice with Late Penalties & Reminders (Egypt)
      RentInvoiceModel(
        id: 'inv_eg_002',
        invoiceNumber: 'INV-EG-2026-0802',
        contractNumber: 'EG-2026-ZAYED-1104',
        countryCode: 'EG',
        unitTitle: 'فيلا مستقلة بحمام سباحة',
        unitNumber: 'Villa 12',
        buildingName: 'كمبوند الربوة',
        district: 'الشيخ زايد',
        propertyId: 'prop-eg-102',
        monthKey: '2026-03',
        tenant: const TenantInfo(
          name: 'سارة خالد الدسوقي',
          phone: '+201123456789',
          email: 'sara.desouky@yahoo.com',
          idNumber: '29505051234568',
        ),
        owner: const OwnerPayoutInfo(
          name: 'م. عمر طارق فتح الله',
          bankName: 'البنك التجاري الدولي (CIB)',
          iban: 'EG450002000098765432109876543',
          accountNumber: '9876543210',
          walletOrVpa: '01099887766',
        ),
        baseAmount: 60000.0,
        dueDate: now.subtract(const Duration(days: 22)),
        gracePeriodDays: 5,
        dailyPenaltyRate: 100.0,
        status: 'overdue',
        platformFeePercent: 1.5,
        payoutStatus: 'pending',
        reminderCount: 3,
        lastReminderSentAt: now.subtract(const Duration(days: 2)),
        legalWarningIssued: true,
      ),

      // 3. Due Soon Invoice (Egypt)
      RentInvoiceModel(
        id: 'inv_eg_003',
        invoiceNumber: 'INV-EG-2026-0901',
        contractNumber: 'EG-2026-OCT-3391',
        countryCode: 'EG',
        unitTitle: 'دوبلكس حديث بحديقة خاصة',
        unitNumber: 'D-101',
        buildingName: 'كمبوند بالم هيلز',
        district: 'السادس من أكتوبر',
        propertyId: 'prop-eg-103',
        monthKey: '2026-04',
        tenant: const TenantInfo(
          name: 'كريم عصام الشناوي',
          phone: '+201234567890',
          email: 'karim.chennawy@gmail.com',
          idNumber: '28803031234569',
        ),
        owner: const OwnerPayoutInfo(
          name: 'شركة الأفق للاستثمار العقاري',
          bankName: 'بنك مصر (Banque Misr)',
          iban: 'EG120004000044556677889900112',
          accountNumber: '4455667788',
          walletOrVpa: 'alofok@instapay',
        ),
        baseAmount: 32000.0,
        dueDate: now.add(const Duration(days: 3)),
        gracePeriodDays: 5,
        dailyPenaltyRate: 60.0,
        status: 'due_soon',
        platformFeePercent: 1.5,
        payoutStatus: 'pending',
        reminderCount: 1,
        lastReminderSentAt: now.subtract(const Duration(days: 1)),
      ),

      // --- UAE Invoices (AED) ---
      // 4. Paid Invoice with Instant Payout to Landlord (UAE)
      RentInvoiceModel(
        id: 'inv_ae_001',
        invoiceNumber: 'INV-AE-2026-0801',
        contractNumber: 'AE-2026-DXB-9021',
        countryCode: 'AE',
        unitTitle: 'Luxury 2BR Apartment with Marina View',
        unitNumber: 'Unit 2204',
        buildingName: 'Marina Gate 2',
        district: 'Dubai Marina',
        propertyId: 'prop-ae-101',
        monthKey: '2026-01',
        tenant: const TenantInfo(
          name: 'James Arthur Wilson',
          phone: '+971501234567',
          email: 'james.wilson@dubai.ae',
          idNumber: '784-1990-1234567-1',
        ),
        owner: const OwnerPayoutInfo(
          name: 'عبدالله راشد النعيمي',
          bankName: 'Emirates NBD',
          iban: 'AE250260001234567890123',
          accountNumber: '1023456789',
          walletOrVpa: 'abdullah.nuaimi@enbd',
        ),
        baseAmount: 18000.0,
        dueDate: now.subtract(const Duration(days: 10)),
        gracePeriodDays: 7,
        dailyPenaltyRate: 150.0,
        status: 'paid',
        paidAt: now.subtract(const Duration(days: 9)),
        paymentMethod: 'apple_pay',
        transactionReference: 'TXN-APPLEPAY-771829',
        platformFeePercent: 1.5,
        payoutStatus: 'transferred_to_owner',
        payoutReference: 'SETTLE-ENBD-991204',
        payoutSettledAt: now.subtract(const Duration(days: 9)),
        reminderCount: 0,
      ),

      // 5. Overdue Invoice with Late Penalties (UAE)
      RentInvoiceModel(
        id: 'inv_ae_002',
        invoiceNumber: 'INV-AE-2026-0802',
        contractNumber: 'AE-2026-DOWNTOWN-4412',
        countryCode: 'AE',
        unitTitle: 'Executive 1BR Suite near Burj Khalifa',
        unitNumber: 'Suite 1805',
        buildingName: 'The Address Downtown',
        district: 'Downtown Dubai',
        propertyId: 'prop-ae-102',
        monthKey: '2026-03',
        tenant: const TenantInfo(
          name: 'Vikram Rajesh Sharma',
          phone: '+971559876543',
          email: 'vikram.sharma@techdxb.com',
          idNumber: '784-1988-7654321-2',
        ),
        owner: const OwnerPayoutInfo(
          name: 'فاطمة سلطان المزروعي',
          bankName: 'Abu Dhabi Commercial Bank (ADCB)',
          iban: 'AE610210009876543210987',
          accountNumber: '2098765432',
          walletOrVpa: 'fatima.mazrouei@adcb',
        ),
        baseAmount: 14500.0,
        dueDate: now.subtract(const Duration(days: 20)),
        gracePeriodDays: 5,
        dailyPenaltyRate: 100.0,
        status: 'overdue',
        platformFeePercent: 1.5,
        payoutStatus: 'pending',
        reminderCount: 2,
        lastReminderSentAt: now.subtract(const Duration(days: 3)),
        legalWarningIssued: false,
      ),

      // 6. Due Soon Invoice (UAE)
      RentInvoiceModel(
        id: 'inv_ae_003',
        invoiceNumber: 'INV-AE-2026-0901',
        contractNumber: 'AE-2026-JBR-5510',
        countryCode: 'AE',
        unitTitle: 'Beachfront 3BR Penthouse',
        unitNumber: 'Penthouse 45',
        buildingName: 'Rimal 1',
        district: 'Jumeirah Beach Residence (JBR)',
        propertyId: 'prop-ae-103',
        monthKey: '2026-04',
        tenant: const TenantInfo(
          name: 'Elena Rostova',
          phone: '+971521122334',
          email: 'elena.rostova@consult.ae',
          idNumber: '784-1994-3344556-3',
        ),
        owner: const OwnerPayoutInfo(
          name: 'عبدالله راشد النعيمي',
          bankName: 'First Abu Dhabi Bank (FAB)',
          iban: 'AE400330005544332211009',
          accountNumber: '3055443322',
          walletOrVpa: 'abdullah.nuaimi@fab',
        ),
        baseAmount: 35000.0,
        dueDate: now.add(const Duration(days: 4)),
        gracePeriodDays: 5,
        dailyPenaltyRate: 200.0,
        status: 'due_soon',
        platformFeePercent: 1.5,
        payoutStatus: 'pending',
        reminderCount: 0,
      ),
    ];

    final result = <RentInvoiceModel>[];
    for (final raw in rawSamples) {
      if (_permanentlyDeletedInvoices.contains(raw.id)) continue;
      if (_softDeletedInvoices.containsKey(raw.id)) {
        result.add(raw.copyWith(
          isDeleted: true,
          deletedAt: _softDeletedInvoices[raw.id],
        ));
      } else {
        result.add(raw);
      }
    }
    return result;
  }

  /// Synchronize invoices dynamically with live properties from [PropertyLifecycleService].
  ///
  /// Maps all rented properties and their installments directly into live rent invoices.
  void syncFromProperties() {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      purgeExpiredDeletedInvoices();
      final properties = PropertyLifecycleService().propertiesNotifier.value;
      final currentInvoices = List<RentInvoiceModel>.from(invoicesNotifier.value);
      final now = DateTime.now();

    final hasRealProps = properties.any((p) => !PropertyLifecycleService.isMockPropertyId(p.id));
    final validPropIds = properties.map((p) => p.id).toSet();

    // If real properties exist, completely purge mock starter invoices (Ahmed El Kadi, Sara Desouky, etc.)
    if (hasRealProps) {
      currentInvoices.removeWhere((inv) =>
          inv.propertyId == null ||
          !validPropIds.contains(inv.propertyId) ||
          PropertyLifecycleService.isMockPropertyId(inv.propertyId!) ||
          inv.id.startsWith('inv_eg_00') ||
          inv.id.startsWith('inv_ae_00'));
    }

    // Purge permanently deleted invoices from memory
    currentInvoices.removeWhere((inv) =>
        _permanentlyDeletedInvoices.contains(inv.id) ||
        (inv.propertyId != null &&
            inv.monthKey != null &&
            _permanentlyDeletedInvoices.contains('${inv.propertyId}_${inv.monthKey}')));

    // Ensure soft-deleted state from persistence is reflected on current in-memory invoices
    for (int i = 0; i < currentInvoices.length; i++) {
      final inv = currentInvoices[i];
      final key = (inv.propertyId != null && inv.monthKey != null) ? '${inv.propertyId}_${inv.monthKey}' : null;
      if (_softDeletedInvoices.containsKey(inv.id) || (key != null && _softDeletedInvoices.containsKey(key))) {
        final delAt = _softDeletedInvoices[inv.id] ?? (key != null ? _softDeletedInvoices[key] : null);
        if (!inv.isDeleted || inv.deletedAt == null) {
          currentInvoices[i] = inv.copyWith(isDeleted: true, deletedAt: delAt ?? DateTime.now());
        }
      }
    }

    // Index existing invoices by propertyId_monthKey and id
    final Map<String, int> existingMap = {};
    for (int i = 0; i < currentInvoices.length; i++) {
      final inv = currentInvoices[i];
      if (inv.propertyId != null && inv.monthKey != null) {
        existingMap['${inv.propertyId}_${inv.monthKey}'] = i;
      }
      existingMap[inv.id] = i;
    }

    for (final prop in properties) {
      // If a property was vacated / lease ended, remove its unpaid invoices
      if (!prop.isOccupied && prop.installments.isEmpty) {
        currentInvoices.removeWhere(
          (inv) => inv.propertyId == prop.id && inv.status != 'paid',
        );
        continue;
      }

      // Collect all relevant installments: active installments + archived paid installments
      final allInstallments = <MonthlyInstallment>[
        ...prop.installments,
        ...prop.archivedInstallments.where((i) => i.isPaid),
      ];

      for (final inst in allInstallments) {
        final key = '${prop.id}_${inst.monthKey}';
        final invId = 'inv_${prop.id}_${inst.monthKey}';

        // 1. Skip permanently deleted invoices
        if (_permanentlyDeletedInvoices.contains(invId) || _permanentlyDeletedInvoices.contains(key)) {
          continue;
        }

        // 2. Check if soft-deleted in persisted state
        final isSoftDeleted = _softDeletedInvoices.containsKey(invId) || _softDeletedInvoices.containsKey(key);
        final deletedAt = isSoftDeleted ? (_softDeletedInvoices[invId] ?? _softDeletedInvoices[key]) : null;

        final isPaid = inst.isPaid;
        final isOverdue = inst.status == InstallmentPaymentStatus.overdue;

        String invoiceStatus;
        if (isPaid) {
          invoiceStatus = 'paid';
        } else if (isOverdue) {
          invoiceStatus = 'overdue';
        } else {
          invoiceStatus = 'due_soon';
        }

        final district = prop.locations['ar'] ?? prop.locations['en'] ?? 'المنطقة';
        final unitTitle = prop.titles['ar'] ?? prop.titles['en'] ?? 'وحدة عقارية';
        final tenantName = prop.tenantName ?? 'المستأجر الحالي';
        final tenantPhone = prop.tenantPhone ?? '+201000000000';
        final cleanPropId = prop.id.replaceAll('prop-', '').replaceAll('-', '');

        if (existingMap.containsKey(key)) {
          final idx = existingMap[key]!;
          final existing = currentInvoices[idx];
          currentInvoices[idx] = existing.copyWith(
            baseAmount: inst.amount,
            status: invoiceStatus,
            paidAt: isPaid ? (inst.paidAt ?? existing.paidAt ?? now) : null,
            paymentMethod: inst.paymentMethod ?? existing.paymentMethod,
            transactionReference: inst.transactionRef ?? existing.transactionReference,
            payoutStatus: isPaid ? 'transferred_to_owner' : 'pending',
            payoutReference: isPaid
                ? (existing.payoutReference ?? (inst.transactionRef != null ? 'SETTLE-${inst.transactionRef}' : 'SETTLE-NBE-882194'))
                : null,
            payoutSettledAt: isPaid ? (inst.paidAt ?? existing.payoutSettledAt ?? now) : null,
            isDeleted: isSoftDeleted || existing.isDeleted,
            deletedAt: deletedAt ?? existing.deletedAt,
          );
        } else {
          // Generate new invoice for this property installment
          final monthNum = inst.monthKey.replaceAll('-', '');
          final invNumber = 'INV-${prop.countryCode}-$monthNum-$cleanPropId';
          final contractNumber = '${prop.countryCode}-2026-${prop.cityCode.toUpperCase()}-${cleanPropId.length > 4 ? cleanPropId.substring(cleanPropId.length - 4) : cleanPropId}';

          final newInvoice = RentInvoiceModel(
            id: invId,
            invoiceNumber: invNumber,
            contractNumber: contractNumber,
            countryCode: prop.countryCode,
            unitTitle: unitTitle,
            unitNumber: prop.unitNumber,
            buildingName: prop.buildingName,
            district: district,
            propertyId: prop.id,
            monthKey: inst.monthKey,
            tenant: TenantInfo(
              name: tenantName,
              phone: tenantPhone,
              email: '${tenantName.split(" ").first.toLowerCase()}@gmail.com',
              idNumber: prop.countryCode == 'AE' ? '784-1990-1234567-1' : '29201011234567',
            ),
            owner: OwnerPayoutInfo(
              name: 'م. عمر طارق فتح الله',
              bankName: prop.countryCode == 'AE' ? 'Emirates NBD' : 'البنك الأهلي المصري (NBE)',
              iban: prop.countryCode == 'AE' ? 'AE250260001234567890123' : 'EG380003000012345678901234567',
              accountNumber: '1234567890',
              walletOrVpa: prop.countryCode == 'AE' ? 'omar.fathalla@enbd' : 'omar.fathalla@instapay',
            ),
            baseAmount: inst.amount,
            dueDate: inst.dueDate,
            gracePeriodDays: 5,
            dailyPenaltyRate: prop.countryCode == 'AE' ? 100.0 : 50.0,
            status: invoiceStatus,
            paidAt: isPaid ? (inst.paidAt ?? now) : null,
            paymentMethod: isPaid ? (inst.paymentMethod ?? 'card') : null,
            transactionReference: isPaid ? (inst.transactionRef ?? 'PAY-MEEZA-994821') : null,
            platformFeePercent: 1.5,
            payoutStatus: isPaid ? 'transferred_to_owner' : 'pending',
            payoutReference: isPaid ? (inst.transactionRef != null ? 'SETTLE-${inst.transactionRef}' : 'SETTLE-NBE-882194') : null,
            payoutSettledAt: isPaid ? (inst.paidAt ?? now) : null,
            isDeleted: isSoftDeleted,
            deletedAt: deletedAt,
          );

          currentInvoices.add(newInvoice);
          existingMap[key] = currentInvoices.length - 1;
        }
      }
    }

    invoicesNotifier.value = currentInvoices;
    } finally {
      _isSyncing = false;
    }
  }

  /// Returns active (non-deleted) invoices for the specified country
  List<RentInvoiceModel> getInvoicesForCountry(String countryCode) {
    return invoicesNotifier.value
        .where((inv) => !inv.isDeleted && inv.countryCode == countryCode)
        .toList();
  }

  /// Returns soft-deleted invoices in trash for the specified country
  List<RentInvoiceModel> getDeletedInvoicesForCountry(String countryCode) {
    return invoicesNotifier.value
        .where((inv) => inv.isDeleted && inv.countryCode == countryCode)
        .toList();
  }

  /// Soft delete an invoice: moves it to trash for 7 days
  void softDeleteInvoice(String invoiceId) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final index = updatedList.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      final current = updatedList[index];
      final now = DateTime.now();

      _softDeletedInvoices[invoiceId] = now;
      if (current.propertyId != null && current.monthKey != null) {
        _softDeletedInvoices['${current.propertyId}_${current.monthKey}'] = now;
      }
      _permanentlyDeletedInvoices.remove(invoiceId);
      if (current.propertyId != null && current.monthKey != null) {
        _permanentlyDeletedInvoices.remove('${current.propertyId}_${current.monthKey}');
      }
      _savePersistedDeletedState();

      updatedList[index] = current.copyWith(
        isDeleted: true,
        deletedAt: now,
      );
      invoicesNotifier.value = updatedList;
    }
  }

  /// Restore an invoice from trash back to active collection
  void restoreInvoice(String invoiceId) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final index = updatedList.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      final current = updatedList[index];

      _softDeletedInvoices.remove(invoiceId);
      if (current.propertyId != null && current.monthKey != null) {
        _softDeletedInvoices.remove('${current.propertyId}_${current.monthKey}');
      }
      _permanentlyDeletedInvoices.remove(invoiceId);
      if (current.propertyId != null && current.monthKey != null) {
        _permanentlyDeletedInvoices.remove('${current.propertyId}_${current.monthKey}');
      }
      _savePersistedDeletedState();

      updatedList[index] = current.copyWith(
        isDeleted: false,
        deletedAt: null,
      );
      invoicesNotifier.value = updatedList;
    }
  }

  /// Permanently delete an invoice from the system
  void permanentlyDeleteInvoice(String invoiceId) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final index = updatedList.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      final invoice = updatedList[index];

      _softDeletedInvoices.remove(invoiceId);
      _permanentlyDeletedInvoices.add(invoiceId);
      if (invoice.propertyId != null && invoice.monthKey != null) {
        _softDeletedInvoices.remove('${invoice.propertyId}_${invoice.monthKey}');
        _permanentlyDeletedInvoices.add('${invoice.propertyId}_${invoice.monthKey}');
      }
      _savePersistedDeletedState();

      updatedList.removeAt(index);
      invoicesNotifier.value = updatedList;

      // Also clean up linked property installment and persist to Firestore
      if (invoice.propertyId != null && invoice.monthKey != null) {
        PropertyLifecycleService().removeInstallmentForProperty(
          propertyId: invoice.propertyId!,
          monthKey: invoice.monthKey!,
        );
      }
    }
  }

  /// Empty all deleted invoices in trash for a given country (or all)
  void emptyTrash({String? countryCode}) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final toRemove = updatedList
        .where((inv) => inv.isDeleted && (countryCode == null || inv.countryCode == countryCode))
        .toList();

    for (final inv in toRemove) {
      _softDeletedInvoices.remove(inv.id);
      _permanentlyDeletedInvoices.add(inv.id);
      if (inv.propertyId != null && inv.monthKey != null) {
        _softDeletedInvoices.remove('${inv.propertyId}_${inv.monthKey}');
        _permanentlyDeletedInvoices.add('${inv.propertyId}_${inv.monthKey}');
        PropertyLifecycleService().removeInstallmentForProperty(
          propertyId: inv.propertyId!,
          monthKey: inv.monthKey!,
        );
      }
    }
    _savePersistedDeletedState();

    updatedList.removeWhere(
        (inv) => inv.isDeleted && (countryCode == null || inv.countryCode == countryCode));
    invoicesNotifier.value = updatedList;
  }

  /// Automatically purges invoices that have been in trash for >= 7 days
  void purgeExpiredDeletedInvoices() {
    if (_isPurging) return;
    _isPurging = true;
    try {
      final now = DateTime.now();
      final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
      final expired = updatedList.where((inv) {
        if (!inv.isDeleted || inv.deletedAt == null) return false;
        return now.difference(inv.deletedAt!).inDays >= 7;
      }).toList();

      if (expired.isNotEmpty) {
        for (final inv in expired) {
          _softDeletedInvoices.remove(inv.id);
          _permanentlyDeletedInvoices.add(inv.id);
          if (inv.propertyId != null && inv.monthKey != null) {
            _softDeletedInvoices.remove('${inv.propertyId}_${inv.monthKey}');
            _permanentlyDeletedInvoices.add('${inv.propertyId}_${inv.monthKey}');
            PropertyLifecycleService().removeInstallmentForProperty(
              propertyId: inv.propertyId!,
              monthKey: inv.monthKey!,
            );
          }
        }
        _savePersistedDeletedState();

        updatedList.removeWhere((inv) => expired.any((e) => e.id == inv.id));
        invoicesNotifier.value = updatedList;
      }
    } finally {
      _isPurging = false;
    }
  }

  /// Update invoice details (base rent amount, due date, notes)
  void updateInvoice({
    required String invoiceId,
    double? baseAmount,
    DateTime? dueDate,
    String? notes,
  }) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final index = updatedList.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      final current = updatedList[index];
      final updated = current.copyWith(
        baseAmount: baseAmount,
        dueDate: dueDate,
        notes: notes,
      );
      updatedList[index] = updated;
      invoicesNotifier.value = updatedList;

      // Sync updated installment amount / due date with PropertyLifecycleService
      if (current.propertyId != null && current.monthKey != null) {
        PropertyLifecycleService().addOrUpdateInstallmentForProperty(
          propertyId: current.propertyId!,
          monthKey: current.monthKey!,
          dueDate: dueDate ?? current.dueDate,
          amount: baseAmount ?? current.baseAmount,
        );
      }
    }
  }

  RentInvoiceModel? getInvoiceById(String id) {
    try {
      return invoicesNotifier.value.firstWhere((inv) => inv.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Execute payment & automated split payout.
  ///
  /// Synchronizes directly with [PropertyLifecycleService] if linked to a property installment.
  Future<RentInvoiceModel> payInvoice({
    required String invoiceId,
    required String paymentMethod,
    required String transactionReference,
  }) async {
    // Simulate gateway processing
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final index = updatedList.indexWhere((inv) => inv.id == invoiceId);

    if (index == -1) {
      throw Exception('Invoice not found: $invoiceId');
    }

    final current = updatedList[index];
    final isUAE = current.countryCode == 'AE';
    final bankPrefix = isUAE ? 'SETTLE-ENBD' : 'SETTLE-NBE';
    final randomSuffix = (100000 + (now.millisecondsSinceEpoch % 900000)).toString();
    final payoutRef = '$bankPrefix-$randomSuffix';

    final paidInvoice = current.copyWith(
      status: 'paid',
      paidAt: now,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      payoutStatus: 'transferred_to_owner',
      payoutReference: payoutRef,
      payoutSettledAt: now,
    );

    updatedList[index] = paidInvoice;
    invoicesNotifier.value = updatedList;

    // Two-way synchronization: update the property installment in PropertyLifecycleService
    if (current.propertyId != null && current.monthKey != null) {
      InstallmentPaymentStatus instStatus;
      if (paymentMethod.contains('cash')) {
        instStatus = InstallmentPaymentStatus.paidCash;
      } else if (paymentMethod.contains('wire') || paymentMethod.contains('bank')) {
        instStatus = InstallmentPaymentStatus.paidBankWire;
      } else {
        instStatus = InstallmentPaymentStatus.paidOnline;
      }

      await PropertyLifecycleService().recordInstallmentPayment(
        propertyId: current.propertyId!,
        monthKey: current.monthKey!,
        status: instStatus,
        paymentMethod: paymentMethod,
        notes: 'سداد عبر بوابة تحصيل الإيجار - مرجع $transactionReference',
      );
    }

    return paidInvoice;
  }

  // Send intelligent reminder (WhatsApp / SMS / Email)
  void sendReminder(String invoiceId) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final index = updatedList.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      final current = updatedList[index];
      updatedList[index] = current.copyWith(
        reminderCount: current.reminderCount + 1,
        lastReminderSentAt: DateTime.now(),
      );
      invoicesNotifier.value = updatedList;
    }
  }

  // Issue formal legal notice for eviction / RDC filing
  void issueLegalNotice(String invoiceId) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    final index = updatedList.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      final current = updatedList[index];
      updatedList[index] = current.copyWith(
        legalWarningIssued: true,
        reminderCount: current.reminderCount + 1,
        lastReminderSentAt: DateTime.now(),
      );
      invoicesNotifier.value = updatedList;
    }
  }

  /// Create and register a new rent invoice
  void addInvoice(RentInvoiceModel invoice) {
    final updatedList = List<RentInvoiceModel>.from(invoicesNotifier.value);
    updatedList.insert(0, invoice);
    invoicesNotifier.value = updatedList;

    // If attached to a property, ensure the installment exists in PropertyLifecycleService
    if (invoice.propertyId != null && invoice.monthKey != null) {
      PropertyLifecycleService().addOrUpdateInstallmentForProperty(
        propertyId: invoice.propertyId!,
        monthKey: invoice.monthKey!,
        dueDate: invoice.dueDate,
        amount: invoice.baseAmount,
      );
    }
  }
}
