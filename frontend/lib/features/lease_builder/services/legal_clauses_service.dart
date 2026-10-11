import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/services/storage/local_storage_service.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

class LegalClausesService {
  static final LegalClausesService _instance = LegalClausesService._internal();
  factory LegalClausesService() => _instance;

  LegalClausesService._internal() {
    _loadPersistedDeletedState();
    _initContracts();
    PropertyLifecycleService().propertiesNotifier.addListener(syncFromProperties);
    syncFromProperties();
  }

  late final ValueNotifier<List<LeaseContractModel>> contractsNotifier;
  final List<LeaseContractModel> _customContracts = [];
  final Set<String> _softDeletedContractIds = {};
  final Map<String, DateTime> _deletedTimestamps = {};
  final Set<String> _permanentlyDeletedContractIds = {};

  static const String _softDeletedContractsKey = 'tashil_soft_deleted_contracts_v1';
  static const String _permanentlyDeletedContractsKey = 'tashil_permanently_deleted_contracts_v1';

  bool _isSyncing = false;
  bool _isPurging = false;

  void _loadPersistedDeletedState() {
    final softMap = LocalStorageService().getStringMap(_softDeletedContractsKey);
    if (softMap != null) {
      _softDeletedContractIds.clear();
      _deletedTimestamps.clear();
      softMap.forEach((id, dtStr) {
        _softDeletedContractIds.add(id);
        final parsed = DateTime.tryParse(dtStr);
        if (parsed != null) {
          _deletedTimestamps[id] = parsed;
        }
      });
    }

    final permList = LocalStorageService().getStringList(_permanentlyDeletedContractsKey);
    if (permList != null) {
      _permanentlyDeletedContractIds.clear();
      _permanentlyDeletedContractIds.addAll(permList);
    }
  }

  void _savePersistedDeletedState() {
    final map = _deletedTimestamps.map((k, v) => MapEntry(k, v.toIso8601String()));
    LocalStorageService().setStringMap(_softDeletedContractsKey, map);
    LocalStorageService().setStringList(_permanentlyDeletedContractsKey, _permanentlyDeletedContractIds.toList());
  }

  void _initContracts() {
    contractsNotifier = ValueNotifier<List<LeaseContractModel>>([]);
  }

  /// Reset contracts to defaults and re-sync (useful for test isolation)
  void resetToDefaults() {
    _customContracts.clear();
    _softDeletedContractIds.clear();
    _deletedTimestamps.clear();
    _permanentlyDeletedContractIds.clear();
    _savePersistedDeletedState();
    syncFromProperties();
  }

  /// Synchronizes contracts from properties and custom contracts
  void syncFromProperties() {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final properties = PropertyLifecycleService().propertiesNotifier.value;
      final derived = getContractsForProperties(properties);

      final result = <LeaseContractModel>[];
      final seenIds = <String>{};

      // 1. Custom / user-created / edited contracts
      for (final custom in _customContracts) {
        if (_permanentlyDeletedContractIds.contains(custom.id)) continue;
        seenIds.add(custom.id);
        final isDeleted = _softDeletedContractIds.contains(custom.id);
        result.add(custom.copyWith(
          isDeleted: isDeleted,
          deletedAt: isDeleted ? (_deletedTimestamps[custom.id] ?? DateTime.now()) : null,
        ));
      }

      // 2. Derived contracts from properties
      for (final contract in derived) {
        if (_permanentlyDeletedContractIds.contains(contract.id)) continue;
        if (!seenIds.contains(contract.id)) {
          seenIds.add(contract.id);
          final isDeleted = _softDeletedContractIds.contains(contract.id);
          result.add(contract.copyWith(
            isDeleted: isDeleted,
            deletedAt: isDeleted ? (_deletedTimestamps[contract.id] ?? DateTime.now()) : null,
          ));
        }
      }

      // 3. In guest mode without properties or contracts, add sample contracts
      final hasRealProps = properties.any((p) => !PropertyLifecycleService.isMockPropertyId(p.id));
      final cachedOwnerId = LocalStorageService().getString('tashil_last_authenticated_owner_id');
      final hasAuthUser = cachedOwnerId != null && cachedOwnerId.isNotEmpty;
      if (result.isEmpty && !hasRealProps && !hasAuthUser) {
        for (final sample in getSampleContracts()) {
          if (_permanentlyDeletedContractIds.contains(sample.id)) continue;
          if (!seenIds.contains(sample.id)) {
            seenIds.add(sample.id);
            final isDeleted = _softDeletedContractIds.contains(sample.id);
            result.add(sample.copyWith(
              isDeleted: isDeleted,
              deletedAt: isDeleted ? (_deletedTimestamps[sample.id] ?? DateTime.now()) : null,
            ));
          }
        }
      }

      contractsNotifier.value = result;
      purgeExpiredDeletedContracts();
    } finally {
      _isSyncing = false;
    }
  }

  /// Returns active (non-deleted) contracts for a country
  List<LeaseContractModel> getActiveContractsForCountry(String countryCode) {
    return contractsNotifier.value
        .where((c) => !c.isDeleted && c.countryCode == countryCode)
        .toList();
  }

  /// Returns soft-deleted contracts in trash for a country
  List<LeaseContractModel> getDeletedContractsForCountry(String countryCode) {
    return contractsNotifier.value
        .where((c) => c.isDeleted && c.countryCode == countryCode)
        .toList();
  }

  /// Add or update a contract (e.g. from LeaseBuilderWizardDialog edit or create)
  void addOrUpdateContract(LeaseContractModel contract) {
    final idx = _customContracts.indexWhere((c) => c.id == contract.id);
    if (idx != -1) {
      _customContracts[idx] = contract;
    } else {
      _customContracts.insert(0, contract);
    }
    syncFromProperties();
  }

  /// Soft delete a contract: marks it as deleted and records timestamp
  void softDeleteContract(String contractId) {
    _softDeletedContractIds.add(contractId);
    _deletedTimestamps[contractId] = DateTime.now();
    _permanentlyDeletedContractIds.remove(contractId);
    _savePersistedDeletedState();
    syncFromProperties();
  }

  /// Restore a contract from trash back to active
  void restoreContract(String contractId) {
    _softDeletedContractIds.remove(contractId);
    _deletedTimestamps.remove(contractId);
    _permanentlyDeletedContractIds.remove(contractId);
    _savePersistedDeletedState();
    syncFromProperties();
  }

  /// Permanently delete a contract
  void permanentlyDeleteContract(String contractId) {
    _softDeletedContractIds.remove(contractId);
    _deletedTimestamps.remove(contractId);
    _permanentlyDeletedContractIds.add(contractId);
    _savePersistedDeletedState();
    _customContracts.removeWhere((c) => c.id == contractId);
    final updated = List<LeaseContractModel>.from(contractsNotifier.value);
    updated.removeWhere((c) => c.id == contractId);
    contractsNotifier.value = updated;
  }

  /// Empty all soft-deleted contracts from trash
  void emptyTrash({String? countryCode}) {
    final toDelete = contractsNotifier.value
        .where((c) => c.isDeleted && (countryCode == null || c.countryCode == countryCode))
        .map((c) => c.id)
        .toList();

    for (final id in toDelete) {
      _softDeletedContractIds.remove(id);
      _deletedTimestamps.remove(id);
      _permanentlyDeletedContractIds.add(id);
      _customContracts.removeWhere((c) => c.id == id);
    }
    _savePersistedDeletedState();

    final updated = List<LeaseContractModel>.from(contractsNotifier.value);
    updated.removeWhere((c) => c.isDeleted && (countryCode == null || c.countryCode == countryCode));
    contractsNotifier.value = updated;
  }

  /// Automatically purges contracts in trash >= 7 days
  void purgeExpiredDeletedContracts() {
    if (_isPurging) return;
    _isPurging = true;
    try {
      final now = DateTime.now();
      final expiredIds = <String>[];
      for (final entry in _deletedTimestamps.entries) {
        if (now.difference(entry.value).inDays >= 7) {
          expiredIds.add(entry.key);
        }
      }
      for (final id in expiredIds) {
        permanentlyDeleteContract(id);
      }
    } finally {
      _isPurging = false;
    }
  }
  static List<LegalClause> getStandardClauses(String countryCode) {
    if (countryCode == 'AE') {
      return _getUaeStandardClauses();
    }
    return _getEgyptStandardClauses();
  }

  static List<LegalClause> _getEgyptStandardClauses() {
    return [
      const LegalClause(
        id: 'eg_purpose_and_delivery',
        titleAr: 'البند الأول: الغرض من الإيجار وتسليم العين',
        titleEn: 'Article 1: Tenancy Purpose and Property Delivery',
        titleHi: 'अनुच्छेद 1: किराये का उद्देश्य और संपत्ति की सुपुर्दगी',
        bodyAr: 'أجر المؤجر للمستأجر العين الموضحة بصدر هذا العقد بغرض السكن العائلي فقط، وقد عاينها المستأجر المعاينة التامة النافية للجهالة وتسلمها بحالة ممتازة وصالحة للغرض المخصص لها.',
        bodyEn: 'The Lessor leases to the Tenant the premises described herein for private residential purpose only. The Tenant has thoroughly inspected the premises and accepted delivery in excellent condition.',
        bodyHi: 'पट्टादाता पट्टेदार को केवल निजी आवासीय उद्देश्य के लिए परिसर पट्टे पर देता है। पट्टेदार ने परिसर का निरीक्षण किया है और इसे उत्कृष्ट स्थिति में स्वीकार किया है।',
        isMandatory: true,
        lawReference: 'القانون المدني المصري رقم 4 لسنة 1996',
      ),
      const LegalClause(
        id: 'eg_rent_and_payment',
        titleAr: 'البند الثاني: القيمة الإيجارية ومواعيد السداد',
        titleEn: 'Article 2: Rent Value and Payment Schedule',
        titleHi: 'अनुच्छेद 2: किराया मूल्य और भुगतान अनुसूची',
        bodyAr: 'يلتزم المستأجر بسداد القيمة الإيجارية المتفق عليها مقدماً في موعد أقصاه اليوم الخامس من كل شهر تعاقدي، ولا تبرأ ذمة المستأجر إلا بإيصال كتابي أو تحويل بنكي معتمد.',
        bodyEn: 'The Tenant agrees to pay the agreed rental value in advance no later than the 5th day of each calendar month against an official written receipt or verified bank transfer.',
        bodyHi: 'पट्टेदार प्रत्येक महीने के 5वें दिन तक अग्रिम रूप से सहमत किराया राशि का भुगतान करने के लिए सहमत होता है।',
        isMandatory: true,
        lawReference: 'المادة 586 من القانون المدني المصري',
      ),
      const LegalClause(
        id: 'eg_automatic_eviction',
        titleAr: 'البند الثالث: انتهاء العقد والإخلاء التلقائي',
        titleEn: 'Article 3: Expiration and Automatic Eviction',
        titleHi: 'अनुच्छेद 3: समाप्ति और स्वतः निष्कासन',
        bodyAr: 'ينتهي هذا العقد بانتهاء مدته المحددة تلقائياً دون حاجة إلى تنبيه أو إنذار أو أي إجراء قضائي، ويلتزم المستأجر بتسليم العين خالية، وإلا التزم بسداد تعويض اتفاقي مضاعف عن كل يوم تأخير.',
        bodyEn: 'This lease terminates automatically upon expiry of its term without notice or judicial decree. The Tenant must vacate immediately or pay stipulated daily compensation for each day of delay.',
        bodyHi: 'यह पट्टा बिना किसी नोटिस के अपनी अवधि समाप्त होने पर स्वतः समाप्त हो जाता है।',
        isMandatory: true,
        lawReference: 'القانون رقم 4 لسنة 1996 وتعديلاته',
      ),
      const LegalClause(
        id: 'eg_security_deposit',
        titleAr: 'البند الرابع: مبلغ التأمين النقدي',
        titleEn: 'Article 4: Refundable Security Deposit',
        titleHi: 'अनुच्छेद 4: वापसी योग्य सुरक्षा जमा',
        bodyAr: 'سدد المستأجر للمؤجر مبلغ تأمين نقدي يُرد إليه عند انتهاء العقد وتسليم العين بالحالة التي كانت عليها بعد سداد كافة الفواتير واستهلاكات المرافق.',
        bodyEn: 'The Tenant has deposited a refundable cash security deposit with the Lessor to be returned upon checkout after settling all utility bills and ensuring property integrity.',
        bodyHi: 'पट्टेदार ने सभी बिलों के निपटान के बाद पट्टादाता के पास वापसी योग्य सुरक्षा जमा राशि जमा की है।',
        isMandatory: true,
      ),
      const LegalClause(
        id: 'eg_no_sublease',
        titleAr: 'البند الخامس: حظر التأجير من الباطن أو التنازل',
        titleEn: 'Article 5: Prohibition of Subleasing or Assignment',
        titleHi: 'अनुच्छेद 5: उप-किरायेदारी या हस्तांतरण का निषेध',
        bodyAr: 'يحظر على المستأجر كلياً التنازل عن الإيجار أو تأجير العين من الباطن كلياً أو جزئياً للغير دون موافقة كتابية صريحة ومسبقة من المؤجر.',
        bodyEn: 'The Tenant is strictly prohibited from subleasing, assigning, or transferring the tenancy rights in whole or in part without the prior written consent of the Lessor.',
        bodyHi: 'पट्टेदार को पट्टादाता की पूर्व लिखित सहमति के बिना संपत्ति को उप-किराये पर देने की सख्त मनाही है।',
        isMandatory: true,
        lawReference: 'المادة 593 من القانون المدني المصري',
      ),
      const LegalClause(
        id: 'eg_utilities_and_maintenance',
        titleAr: 'البند السادس: فواتير المرافق ومصروفات الحراسة',
        titleEn: 'Article 6: Utility Bills and Common Area Expenses',
        titleHi: 'अनुच्छेद 6: उपयोगिता बिल और सामान्य क्षेत्र खर्च',
        bodyAr: 'يلتزم المستأجر بسداد فواتير استهلاك الكهرباء والمياه والغاز الخاصة بالعين المؤجرة، بالإضافة إلى حصته في مصروفات صيانة العمارة والحراسة وتشغيل المصعد بانتظام.',
        bodyEn: 'The Tenant is responsible for electricity, water, and gas consumption bills for the leased unit, as well as regular building maintenance, elevator, and security shares.',
        bodyHi: 'पट्टेदार बिजली, पानी, गैस के बिल और भवन रखरखाव शुल्क के भुगतान के लिए उत्तरदायी है।',
        isMandatory: false,
      ),
      const LegalClause(
        id: 'eg_executive_formula',
        titleAr: 'البند السابع: التوثيق بالصيغة التنفيذية بالشهر العقاري',
        titleEn: 'Article 7: Executive Formula Registry Authentication',
        titleHi: 'अनुच्छेद 7: रियल एस्टेट रजिस्ट्री प्रमाणीकरण',
        bodyAr: 'اتفق الطرفان على إمكانية إثبات تاريخ هذا العقد والتصديق على توقيعاته وتذييله بالصيغة التنفيذية بمكتب الشهر العقاري المختص عملاً بأحكام القانون رقم 137 لسنة 2006 ليكون سنداً تنفيذياً واجب النفاذ.',
        bodyEn: 'The parties agree to register this lease with the official Real Estate Registry and endorse it with an executive formula pursuant to Law 137 of 2006 to serve as an enforceable writ.',
        bodyHi: 'दोनों पक्ष कानून 137/2006 के तहत रियल एस्टेट रजिस्ट्री में इस अनुबंध को पंजीकृत करने के लिए सहमत हैं।',
        isMandatory: false,
        lawReference: 'القانون رقم 137 لسنة 2006',
      ),
      const LegalClause(
        id: 'eg_jurisdiction',
        titleAr: 'البند الثامن: الاختصاص القضائي ومحل الإقامة المختار',
        titleEn: 'Article 8: Legal Jurisdiction and Domicile',
        titleHi: 'अनुच्छेद 8: कानूनी क्षेत्राधिकार',
        bodyAr: 'تختص محكمة الأمور المستعجلة والمحكمة الابتدائية الواقع في دائرتها العقار بنظر أي نزاع قد ينشأ عن تفسير أو تنفيذ هذا العقد.',
        bodyEn: 'The Summary Court and Court of First Instance in whose jurisdiction the real estate is situated shall have exclusive jurisdiction over any dispute arising herefrom.',
        bodyHi: 'संपत्ति के क्षेत्राधिकार की अदालत इस अनुबंध से उत्पन्न विवादों के लिए सक्षम होगी।',
        isMandatory: true,
      ),
    ];
  }

  static List<LegalClause> _getUaeStandardClauses() {
    return [
      const LegalClause(
        id: 'ae_ejari_registration',
        titleAr: 'البند الأول: التسجيل الإلزامي في نظام إيجاري (Ejari)',
        titleEn: 'Article 1: Mandatory Ejari Registration',
        titleHi: 'अनुच्छेद 1: अनिवार्य इजारी (Ejari) पंजीकरण',
        bodyAr: 'يخضع هذا العقد لأحكام القانون رقم 26 لسنة 2007 وتعديلاته بالقانون رقم 33 لسنة 2008 بشأن تنظيم العلاقة بين مؤجري ومستأجري العقارات بدبي، ويلتزم الطرفان بتسجيل هذا العقد في نظام إيجاري (Ejari) المعتمد.',
        bodyEn: 'This tenancy contract is governed by Law No. 26 of 2007 and Law No. 33 of 2008 in Dubai. Both parties agree to register this contract in the official Ejari system.',
        bodyHi: 'यह पट्टा अनुबंध दुबई कानून 26/2007 और 33/2008 द्वारा शासित है। दोनों पक्ष आधिकारिक इजारी प्रणाली में पंजीकरण करने के लिए सहमत हैं।',
        isMandatory: true,
        lawReference: 'قانون دبي رقم 26 لسنة 2007 وقانون رقم 33 لسنة 2008',
      ),
      const LegalClause(
        id: 'ae_cheque_payments',
        titleAr: 'البند الثاني: جدول الشيكات المصرفية المؤجلة (PDC)',
        titleEn: 'Article 2: Post-Dated Cheques (PDC) Schedule',
        titleHi: 'अनुच्छेद 2: पोस्ट-डेटेड चेक (PDC) अनुसूची',
        bodyAr: 'يلتزم المستأجر بتقديم الشيكات المصرفية المؤجلة المتفق عليها عند توقيع العقد، وفي حال ارتجاع أي شيك لأي سبب، يلتزم المستأجر بسداد قيمته فوراً بالإضافة إلى غرامة إدارية قدرها 500 درهم.',
        bodyEn: 'The Tenant shall issue the agreed post-dated cheques (PDC) upon signing. In the event of a bounced cheque, the Tenant must settle the amount immediately plus a 500 AED administrative fee.',
        bodyHi: 'पट्टेदार हस्ताक्षर पर सहमत पोस्ट-डेटेड चेक जारी करेगा। चेक बाउंस होने पर पट्टेदार तुरंत राशि और 500 AED शुल्क का भुगतान करेगा।',
        isMandatory: true,
        lawReference: 'مصرف الإمارات المركزي وقوانين المعاملات التجارية',
      ),
      const LegalClause(
        id: 'ae_security_deposit',
        titleAr: 'البند الثالث: مبلغ تأمين الإيجار (Security Deposit)',
        titleEn: 'Article 3: Security Deposit and Handover Protocol',
        titleHi: 'अनुच्छेद 3: सुरक्षा जमा और हैंडओवर प्रोटोकॉल',
        bodyAr: 'يسدد المستأجر مبلغ تأمين قدره 5% للوحدات غير المفروشة أو 10% للوحدات المفروشة، ويكون مسترد بالكامل عند انتهاء العقد بعد تفتيش العقار وتسوية فواتير هيئة كهرباء ومياه دبي (DEWA).',
        bodyEn: 'The Tenant pays a security deposit (5% unfurnished / 10% furnished), refundable upon lease expiry following successful move-out inspection and DEWA final bill clearance.',
        bodyHi: 'पट्टेदार 5% (असुसज्जित) या 10% (सुसज्जित) सुरक्षा जमा राशि का भुगतान करेगा, जो डीवा बिल निपटान के बाद वापस की जाएगी।',
        isMandatory: true,
      ),
      const LegalClause(
        id: 'ae_90_day_notice',
        titleAr: 'البند الرابع: إشعار الـ 90 يوماً قبل انتهاء العقد',
        titleEn: 'Article 4: Statutory 90-Day Notice Period',
        titleHi: 'अनुच्छेद 4: 90 दिन की वैधानिक नोटिस अवधि',
        bodyAr: 'يلتزم أي من الطرفين بإخطار الطرف الآخر كتابياً برغبته في تعديل أي من شروط العقد أو عدم التجديد قبل 90 يوماً على الأقل من تاريخ انتهاء مدة الإيجار الحالية وفقاً لقانون الإيجارات.',
        bodyEn: 'Either party wishing to amend tenancy terms or not renew the lease must give at least 90 days written notice prior to the expiration date pursuant to Law 33 of 2008.',
        bodyHi: 'यदि कोई पक्ष शर्तों में बदलाव या नवीनीकरण नहीं चाहता है, तो उसे समाप्ति से कम से कम 90 दिन पहले लिखित नोटिस देना होगा।',
        isMandatory: true,
        lawReference: 'المادة 14 من قانون دبي رقم 33 لسنة 2008',
      ),
      const LegalClause(
        id: 'ae_rera_index',
        titleAr: 'البند الخامس: الالتزام بحاسبة مؤشر ريرا لزيادة الإيجار',
        titleEn: 'Article 5: Compliance with RERA Rental Index',
        titleHi: 'अनुच्छेद 5: रेरा (RERA) किराया सूचकांक का अनुपालन',
        bodyAr: 'تخضع أي زيادة إيجارية عند التجديد لمعايير حاسبة مؤشر الإيجارات الصادر عن مؤسسة التنظيم العقاري (RERA) في دبي، ولا يجوز فرض أي زيادة غير متوافقة مع المؤشر.',
        bodyEn: 'Any rental increase upon renewal shall strictly conform to the RERA Rental Calculator guidelines issued by Dubai Land Department (DLD).',
        bodyHi: 'नवीनीकरण पर कोई भी किराया वृद्धि दुबई भूमि विभाग (DLD) के रेरा किराया कैलकुलेटर के अनुसार होगी।',
        isMandatory: true,
        lawReference: 'مرسوم إيجارات دبي رقم 43 لسنة 2013',
      ),
      const LegalClause(
        id: 'ae_sublease_and_occupancy',
        titleAr: 'البند السادس: حظر التأجير من الباطن وإشغال الوحدة',
        titleEn: 'Article 6: Subleasing Ban and Permitted Occupancy',
        titleHi: 'अनुच्छेद 6: उप-किरायेदारी प्रतिबंध और अनुमत उपयोग',
        bodyAr: 'يحظر على المستأجر تأجير الوحدة من الباطن أو التنازل عنها لأي طرف ثالث دون موافقة خطية صريحة من المالك، ويقتصر السكن على المستأجر وأفراد عائلته المصرح لهم.',
        bodyEn: 'The Tenant shall not sublease or assign the property without express written consent from the Landlord. Occupancy is limited to the Tenant and immediate family.',
        bodyHi: 'पट्टेदार मकान मालिक की लिखित सहमति के बिना संपत्ति को उप-किराये पर नहीं देगा।',
        isMandatory: true,
      ),
      const LegalClause(
        id: 'ae_maintenance_scope',
        titleAr: 'البند السابع: حدود مسؤولية الصيانة الدورية والجسيمة',
        titleEn: 'Article 7: Maintenance Scope (Minor vs Major)',
        titleHi: 'अनुच्छेद 7: रखरखाव का दायरा (मामूली बनाम बड़ा)',
        bodyAr: 'يتحمل المستأجر تكاليف الصيانة الدورية الطفيفة التي تقل عن 500 درهم للواقعة الواحدة، بينما يتحمل المالك الصيانة الهيكلية والجسيمة والأعطال الناتجة عن الاستهلاك الطبيعي.',
        bodyEn: 'The Tenant is responsible for minor routine repairs under 500 AED per incident, while the Landlord is liable for major structural repairs and MEP systems replacement.',
        bodyHi: 'पट्टेदार 500 AED से कम के मामूली रखरखाव के लिए उत्तरदायी है, जबकि मकान मालिक बड़े संरचनात्मक रखरखाव के लिए जिम्मेदार है।',
        isMandatory: false,
      ),
      const LegalClause(
        id: 'ae_rdc_disputes',
        titleAr: 'البند الثامن: فض المنازعات عبر مركز RDC',
        titleEn: 'Article 8: Dispute Resolution via RDC',
        titleHi: 'अनुच्छेद 8: आरडीसी (RDC) के माध्यम से विवाद समाधान',
        bodyAr: 'يختص مركز فض المنازعات الإيجارية (Rental Dispute Settlement Centre - RDC) في دبي بنظر وفصل أي نزاع ينشأ بين الطرفين بخصوص هذا العقد.',
        bodyEn: 'The Rental Dispute Settlement Centre (RDC) in Dubai shall have exclusive authority to resolve any dispute arising from the interpretation or enforcement of this contract.',
        bodyHi: 'दुबई का रेंटल डिस्प्यूट सेंटर (RDC) इस अनुबंध से उत्पन्न विवादों को सुलझाने के लिए अधिकृत होगा।',
        isMandatory: true,
        lawReference: 'مرسوم دبي رقم 26 لسنة 2013 بشأن مركز فض المنازعات الإيجارية',
      ),
    ];
  }

  static List<LeaseContractModel> getSampleContracts() {
    return [
      LeaseContractModel(
        id: 'lease_eg_101',
        contractNumber: 'EG-2026-CAI-8821',
        countryCode: 'EG',
        status: 'active',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2027, 1, 1),
        lessor: const ContractParty(
          name: 'م. عمر طارق فتح الله',
          nationalIdOrEmiratesId: '29304150102432',
          nationality: 'مصري',
          phone: '+201002345678',
          email: 'omar.fathalla@tashil.com',
          address: 'التجمع الخامس، القاهرة الجديدة',
          isLessor: true,
        ),
        tenant: const ContractParty(
          name: 'أحمد محمود القاضي',
          nationalIdOrEmiratesId: '29811200105678',
          nationality: 'مصري',
          phone: '+201124567890',
          email: 'ahmed.kadi@gmail.com',
          address: 'المعادي، القاهرة',
          isLessor: false,
        ),
        property: const LeasePropertySpec(
          propertyTitle: 'شقة فاخرة بإطلالة على الحديقة',
          unitNumber: '402',
          buildingName: 'برج الياسمين',
          district: 'التجمع الخامس',
          city: 'القاهرة',
          countryCode: 'EG',
          areaSqm: 165,
          propertyType: 'apartment',
          floorNumber: 'الرابع',
        ),
        financialTerms: const FinancialTerms(
          totalRentAmount: 300000,
          monthlyRentEquivalent: 25000,
          currencyCode: 'EGP',
          paymentFrequency: 'monthly',
          numberOfCheques: 12,
          securityDeposit: 50000,
          annualIncreasePercentage: 10.0,
        ),
        clauses: _getEgyptStandardClauses(),
        lessorSignature: DigitalSignature(
          signerName: 'م. عمر طارق فتح الله',
          signerRole: 'lessor',
          nationalIdOrEmiratesId: '29304150102432',
          signedAt: DateTime(2026, 1, 1, 10, 30),
          ipAddress: '197.34.12.89',
          verificationHash: 'EG-SEC-SHA256-789a8c2f1e00',
          certificateId: 'CERT-EG-99821',
        ),
        tenantSignature: DigitalSignature(
          signerName: 'أحمد محمود القاضي',
          signerRole: 'tenant',
          nationalIdOrEmiratesId: '29811200105678',
          signedAt: DateTime(2026, 1, 1, 11, 15),
          ipAddress: '197.34.12.92',
          verificationHash: 'EG-SEC-SHA256-b771e89f02c4',
          certificateId: 'CERT-EG-99822',
        ),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        registeredRegistryId: 'شهر عقاري قيد رقم: 4432/2026',
      ),
      LeaseContractModel(
        id: 'lease_ae_202',
        contractNumber: 'AE-DXB-EJARI-94021',
        countryCode: 'AE',
        status: 'active',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2027, 2, 1),
        lessor: const ContractParty(
          name: 'عبدالله راشد النعيمي',
          nationalIdOrEmiratesId: '784-1985-1234567-1',
          nationality: 'إماراتي',
          phone: '+971501234567',
          email: 'abdullah.nuaimi@tashil.ae',
          address: 'نخلة جميرا، دبي',
          isLessor: true,
        ),
        tenant: const ContractParty(
          name: 'David Christopher Miller',
          nationalIdOrEmiratesId: '784-1990-7654321-2',
          passportNumber: 'GB987654321',
          nationality: 'بريطاني',
          phone: '+971559876543',
          email: 'david.miller@techcorp.co.uk',
          address: 'دبي مارينا، دبي',
          isLessor: false,
        ),
        property: const LeasePropertySpec(
          propertyTitle: 'بنتهاوس بانورامي في دبي مارينا',
          unitNumber: '2804',
          buildingName: 'Marina Gate 2',
          district: 'دبي مارينا',
          city: 'دبي',
          countryCode: 'AE',
          areaSqm: 240,
          propertyType: 'penthouse',
          makaniNumber: '31422 78901',
          dewaPremiseNumber: '20984711',
          titleDeedNumber: 'TD-2024-009182',
          floorNumber: '28',
        ),
        financialTerms: FinancialTerms(
          totalRentAmount: 180000,
          monthlyRentEquivalent: 15000,
          currencyCode: 'AED',
          paymentFrequency: 'quarterly',
          numberOfCheques: 4,
          securityDeposit: 18000,
          annualIncreasePercentage: 0.0,
          isVatApplicable: false,
          cheques: [
            ChequeDetail(
              chequeNumber: 'CHQ-8801',
              bankName: 'Emirates NBD',
              dueDate: DateTime(2026, 2, 1),
              amount: 45000,
              status: 'cleared',
            ),
            ChequeDetail(
              chequeNumber: 'CHQ-8802',
              bankName: 'Emirates NBD',
              dueDate: DateTime(2026, 5, 1),
              amount: 45000,
              status: 'cleared',
            ),
            ChequeDetail(
              chequeNumber: 'CHQ-8803',
              bankName: 'Emirates NBD',
              dueDate: DateTime(2026, 8, 1),
              amount: 45000,
              status: 'pending',
            ),
            ChequeDetail(
              chequeNumber: 'CHQ-8804',
              bankName: 'Emirates NBD',
              dueDate: DateTime(2026, 11, 1),
              amount: 45000,
              status: 'pending',
            ),
          ],
        ),
        clauses: _getUaeStandardClauses(),
        lessorSignature: DigitalSignature(
          signerName: 'عبدالله راشد النعيمي',
          signerRole: 'lessor',
          nationalIdOrEmiratesId: '784-1985-1234567-1',
          signedAt: DateTime(2026, 1, 28, 14, 20),
          ipAddress: '185.120.44.10',
          verificationHash: 'AE-DLD-SHA256-44a1e99c0012',
          certificateId: 'CERT-AE-EJARI-8102',
        ),
        tenantSignature: DigitalSignature(
          signerName: 'David Christopher Miller',
          signerRole: 'tenant',
          nationalIdOrEmiratesId: '784-1990-7654321-2',
          signedAt: DateTime(2026, 1, 29, 9, 45),
          ipAddress: '185.120.44.55',
          verificationHash: 'AE-DLD-SHA256-88b901fc2371',
          certificateId: 'CERT-AE-EJARI-8103',
        ),
        createdAt: DateTime(2026, 1, 28),
        updatedAt: DateTime(2026, 1, 29),
        registeredRegistryId: 'Ejari ID: 2026-9041288-DXB',
      ),
      LeaseContractModel(
        id: 'lease_eg_pending',
        contractNumber: 'EG-2026-ZAYED-1104',
        countryCode: 'EG',
        status: 'pending_signatures',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2027, 9, 1),
        lessor: const ContractParty(
          name: 'م. عمر طارق فتح الله',
          nationalIdOrEmiratesId: '29304150102432',
          nationality: 'مصري',
          phone: '+201002345678',
          email: 'omar.fathalla@tashil.com',
          address: 'الشيخ زايد، الجيزة',
          isLessor: true,
        ),
        tenant: const ContractParty(
          name: 'سارة خالد الدسوقي',
          nationalIdOrEmiratesId: '29906180108922',
          nationality: 'مصرية',
          phone: '+201209876543',
          email: 'sara.desouky@yahoo.com',
          address: 'الدقي، الجيزة',
          isLessor: false,
        ),
        property: const LeasePropertySpec(
          propertyTitle: 'فيلا مستقلة بكمبوند الياسمين',
          unitNumber: 'Villa 12',
          buildingName: 'كمبوند الربوة',
          district: 'الشيخ زايد',
          city: 'الجيزة',
          countryCode: 'EG',
          areaSqm: 380,
          propertyType: 'villa',
        ),
        financialTerms: const FinancialTerms(
          totalRentAmount: 720000,
          monthlyRentEquivalent: 60000,
          currencyCode: 'EGP',
          paymentFrequency: 'quarterly',
          numberOfCheques: 4,
          securityDeposit: 120000,
          annualIncreasePercentage: 10.0,
        ),
        clauses: _getEgyptStandardClauses(),
        lessorSignature: DigitalSignature(
          signerName: 'م. عمر طارق فتح الله',
          signerRole: 'lessor',
          nationalIdOrEmiratesId: '29304150102432',
          signedAt: DateTime(2026, 8, 28, 16, 0),
          ipAddress: '197.34.12.89',
          verificationHash: 'EG-SEC-SHA256-11f84aa90123',
          certificateId: 'CERT-EG-99901',
        ),
        tenantSignature: null, // Waiting for tenant signature
        createdAt: DateTime(2026, 8, 28),
        updatedAt: DateTime(2026, 8, 28),
      ),
    ];
  }

  /// Derives live lease contracts strictly tied to the owner's actual rented properties.
  static List<LeaseContractModel> getContractsForProperties(List<ManagedPropertyModel> properties) {
    final hasRealProps = properties.any((p) => !PropertyLifecycleService.isMockPropertyId(p.id));

    // Filter to rented properties that have an active tenant assigned
    final rentedProps = properties.where((p) {
      if (hasRealProps && PropertyLifecycleService.isMockPropertyId(p.id)) return false;
      return p.rentalStatus == PropertyRentalStatus.rented && p.tenantName != null && p.tenantName!.isNotEmpty;
    }).toList();

    return rentedProps.map((prop) {
      final isUAE = prop.countryCode == 'AE';
      final cleanCity = prop.cityCode.toUpperCase().replaceAll('_', '');
      final cleanId = prop.id.replaceAll('prop-', '').replaceAll('-', '');
      final shortId = cleanId.length > 4 ? cleanId.substring(cleanId.length - 4) : cleanId;
      final contractNo = '${prop.countryCode}-2026-$cleanCity-$shortId';
      final rentAmount = prop.pricePerMonth > 0 ? prop.pricePerMonth : (isUAE ? 12000.0 : 20000.0);
      final startDate = prop.leaseStartDate ?? DateTime(2026, 1, 1);
      final endDate = prop.leaseEndDate ?? DateTime(2026, 12, 31);
      final district = prop.getLocation('ar');
      final title = prop.getTitle('ar');

      return LeaseContractModel(
        id: 'lease_${prop.id}',
        contractNumber: contractNo,
        countryCode: prop.countryCode,
        status: 'active',
        startDate: startDate,
        endDate: endDate,
        lessor: ContractParty(
          name: isUAE ? 'عبدالله راشد النعيمي' : 'م. عمر طارق فتح الله',
          nationalIdOrEmiratesId: isUAE ? '784-1985-1234567-1' : '29304150102432',
          nationality: isUAE ? 'إماراتي' : 'مصري',
          phone: isUAE ? '+971501234567' : '+201002345678',
          email: isUAE ? 'abdullah@tashil.ae' : 'omar.fathalla@tashil.com',
          address: district,
          isLessor: true,
        ),
        tenant: ContractParty(
          name: prop.tenantName!,
          nationalIdOrEmiratesId: isUAE ? '784-1990-1234567-1' : '29201011234567',
          nationality: isUAE ? 'إماراتي' : 'مصري',
          phone: prop.tenantPhone ?? (isUAE ? '+971500000000' : '+201000000000'),
          email: '${prop.tenantName!.split(" ").first.toLowerCase()}@gmail.com',
          address: district,
          isLessor: false,
        ),
        property: LeasePropertySpec(
          propertyTitle: title,
          unitNumber: prop.unitNumber,
          buildingName: prop.buildingName,
          district: district,
          city: prop.cityCode,
          countryCode: prop.countryCode,
          areaSqm: prop.areaSqM.toInt(),
          propertyType: prop.propertyTypeCode,
        ),
        financialTerms: FinancialTerms(
          totalRentAmount: rentAmount * 12,
          monthlyRentEquivalent: rentAmount,
          currencyCode: prop.currencyCode,
          paymentFrequency: 'monthly',
          numberOfCheques: 12,
          securityDeposit: rentAmount * 2,
          annualIncreasePercentage: isUAE ? 5.0 : 10.0,
        ),
        clauses: isUAE ? _getUaeStandardClauses() : _getEgyptStandardClauses(),
        lessorSignature: DigitalSignature(
          signerName: isUAE ? 'عبدالله راشد النعيمي' : 'م. عمر طارق فتح الله',
          signerRole: 'lessor',
          nationalIdOrEmiratesId: isUAE ? '784-1985-1234567-1' : '29304150102432',
          signedAt: startDate,
          ipAddress: '197.34.12.89',
          verificationHash: '${prop.countryCode}-SEC-SHA256-$shortId',
          certificateId: 'CERT-${prop.countryCode}-$shortId',
        ),
        tenantSignature: DigitalSignature(
          signerName: prop.tenantName!,
          signerRole: 'tenant',
          nationalIdOrEmiratesId: isUAE ? '784-1990-1234567-1' : '29201011234567',
          signedAt: startDate.add(const Duration(hours: 2)),
          ipAddress: '197.34.12.92',
          verificationHash: '${prop.countryCode}-SEC-SHA256-T$shortId',
          certificateId: 'CERT-${prop.countryCode}-T$shortId',
        ),
        createdAt: startDate,
        updatedAt: startDate,
        registeredRegistryId: isUAE
            ? 'Ejari ID: 2026-$shortId-DXB'
            : 'شهر عقاري قيد رقم: 4432/2026',
      );
    }).toList();
  }
}
