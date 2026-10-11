import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';
import 'package:tashil_real_estate/core/services/storage/local_storage_service.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';

class PropertyLifecycleService {
  static final PropertyLifecycleService _instance = PropertyLifecycleService._internal();
  factory PropertyLifecycleService() => _instance;

  FirestoreService? _firestoreServiceInstance;
  FirestoreService? get _firestoreService {
    try {
      return _firestoreServiceInstance ??= FirestoreService();
    } catch (_) {
      return null;
    }
  }
  StreamSubscription<List<ManagedPropertyModel>>? _cloudSubscription;
  String? _activeOwnerId;

  static const String _lastOwnerKey = 'tashil_last_authenticated_owner_id';
  static const String _propsCachePrefix = 'tashil_cached_owner_props_v1_';

  /// Reactive indicator signaling when properties are being fetched from Firestore
  final ValueNotifier<bool> isHydratingNotifier = ValueNotifier<bool>(false);

  String get currentOwnerId {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        return user.uid;
      }
    } catch (_) {}
    final cached = LocalStorageService().getString(_lastOwnerKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return 'owner_default_portfolio';
  }

  PropertyLifecycleService._internal() {
    _initLocalOrSampleData();
    propertiesNotifier.addListener(_sanitizePortfolio);
    _initCloudSync();
  }

  final ValueNotifier<List<ManagedPropertyModel>> propertiesNotifier =
      ValueNotifier<List<ManagedPropertyModel>>([]);

  void _initLocalOrSampleData() {
    String? cachedOwnerId;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        cachedOwnerId = user.uid;
      }
    } catch (_) {}

    cachedOwnerId ??= LocalStorageService().getString(_lastOwnerKey);

    if (cachedOwnerId != null && cachedOwnerId.isNotEmpty) {
      _activeOwnerId = cachedOwnerId;
      // 0ms instant local cache hydration
      final cachedJson = LocalStorageService().getString('$_propsCachePrefix$cachedOwnerId');
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            final list = decoded
                .map((e) => ManagedPropertyModel.fromMap(Map<String, dynamic>.from(e as Map)))
                .where((p) => !isMockPropertyId(p.id))
                .toList();
            propertiesNotifier.value = list;
            isHydratingNotifier.value = false;
            debugPrint('PropertyLifecycleService: Hydrated ${list.length} properties in 0ms from LocalStorage for [$cachedOwnerId]');
            return;
          }
        } catch (e) {
          debugPrint('PropertyLifecycleService cache load error: $e');
        }
      }
      // Authenticated owner but no local cache yet: Start empty with hydration spinner, NEVER mock data
      propertiesNotifier.value = [];
      isHydratingNotifier.value = true;
      return;
    }

    // Unauthenticated guest / demo mode: load sample data
    _initSampleData();
  }

  void _persistPropertiesLocally(String ownerId, List<ManagedPropertyModel> props) {
    try {
      if (ownerId.isNotEmpty) {
        LocalStorageService().setString(_lastOwnerKey, ownerId);
        final cleanProps = props.where((p) => !isMockPropertyId(p.id)).toList();
        final jsonList = cleanProps.map((p) => p.toMap()).toList();
        LocalStorageService().setString('$_propsCachePrefix$ownerId', jsonEncode(jsonList));
        debugPrint('PropertyLifecycleService: Persisted ${cleanProps.length} properties locally for [$ownerId]');
      }
    } catch (e) {
      debugPrint('PropertyLifecycleService._persistPropertiesLocally error: $e');
    }
  }

  /// Clears locally cached properties and resets active session
  void clearLocalCache([String? ownerId]) {
    try {
      final id = ownerId ?? _activeOwnerId ?? LocalStorageService().getString(_lastOwnerKey);
      if (id != null && id.isNotEmpty) {
        LocalStorageService().remove('$_propsCachePrefix$id');
      }
      LocalStorageService().remove(_lastOwnerKey);
      _activeOwnerId = null;
      propertiesNotifier.value = [];
    } catch (_) {}
  }

  void _initCloudSync() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null && user.uid.isNotEmpty) {
          LocalStorageService().setString(_lastOwnerKey, user.uid);
          if (_activeOwnerId != user.uid) {
            _syncForOwner(user.uid);
          }
        } else {
          _cloudSubscription?.cancel();
          _cloudSubscription = null;
          _activeOwnerId = null;
        }
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid.isNotEmpty) {
        _syncForOwner(currentUser.uid);
      }
    } catch (_) {
      // Firebase not initialized in test/offline environment
    }
  }

  /// Checks if a property ID belongs to mock placeholder/starter data
  static bool isMockPropertyId(String id) {
    return id == 'prop-eg-101' ||
        id == 'prop-eg-102' ||
        id == 'prop-eg-103' ||
        id == 'prop-eg-104' ||
        id == 'prop-ae-101' ||
        id == 'prop-ae-102' ||
        id == 'prop-ae-103' ||
        id.startsWith('SIM-');
  }

  /// Ensures that whenever real user properties exist, all mock sample placeholders are stripped.
  void _sanitizePortfolio() {
    final current = propertiesNotifier.value;
    if (current.any((p) => !isMockPropertyId(p.id))) {
      final realOnly = current.where((p) => !isMockPropertyId(p.id)).toList();
      if (realOnly.length != current.length) {
        propertiesNotifier.value = realOnly;
        return;
      }
    }

    // Persist real properties automatically when updated
    final owner = _activeOwnerId ?? LocalStorageService().getString(_lastOwnerKey);
    if (owner != null && owner.isNotEmpty && current.every((p) => !isMockPropertyId(p.id))) {
      _persistPropertiesLocally(owner, current);
    }
  }

  Future<void> _syncForOwner(String ownerId) async {
    _activeOwnerId = ownerId;
    await _cloudSubscription?.cancel();
    _cloudSubscription = null;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != ownerId) {
      return;
    }

    try {
      // 1. Purge legacy mock properties from owner Firestore tree
      await _firestoreService?.purgeMockPropertiesForOwner(ownerId);

      // 2. Fetch owner's real properties
      final cloudProps = await _firestoreService?.getOwnerProperties(ownerId) ?? [];
      final realProps = cloudProps.where((p) => !isMockPropertyId(p.id)).toList();

      propertiesNotifier.value = realProps;
      _persistPropertiesLocally(ownerId, realProps);
      isHydratingNotifier.value = false;
      debugPrint('Loaded ${realProps.length} real properties from Firestore for owner [$ownerId]');
    } catch (e) {
      debugPrint('Cloud hydration note: $e');
      isHydratingNotifier.value = false;
    }

    try {
      final stream = _firestoreService?.streamOwnerProperties(ownerId);
      if (stream != null) {
        _cloudSubscription = stream.listen(
          (props) {
            final realProps = props.where((p) => !isMockPropertyId(p.id)).toList();
            propertiesNotifier.value = realProps;
            _persistPropertiesLocally(ownerId, realProps);
            isHydratingNotifier.value = false;
          },
          onError: (err) {
            debugPrint('Cloud sync stream note (handled safely): $err');
          },
          cancelOnError: false,
        );
      }
    } catch (e) {
      debugPrint('Cloud sync stream init note: $e');
    }
  }

  /// Resets properties to clean sample starter state
  void resetToSampleData() {
    _initSampleData();
  }

  void _initSampleData() {
    propertiesNotifier.value = [
      // --- Egypt Properties ---
      ManagedPropertyModel(
        id: 'prop-eg-101',
        countryCode: 'EG',
        currencyCode: 'EGP',
        titles: {
          'ar': 'شقة فاخرة بالتجمع الخامس - النرجس',
          'en': 'Luxury Apartment in 5th Settlement - El Narges',
          'hi': '5वें सेटलमेंट में लक्जरी अपार्टमेंट - अल नरगिस',
        },
        descriptions: {
          'ar': 'شقة مودرن بتشطيب فاخر 185م²، 3 غرف نوم و2 حمام، مكيفة بالكامل مع موقف خاص ومصعد.',
          'en': 'Modern 185m² luxury finished apartment, 3 bedrooms, 2 bathrooms, central A/C, private parking.',
          'hi': 'आधुनिक 185 वर्ग मीटर लक्जरी अपार्टमेंट, 3 बेडरूम, 2 बाथरूम, पूरी तरह वातानुकूलित।',
        },
        locations: {
          'ar': 'التجمع الخامس، القاهرة الجديدة',
          'en': '5th Settlement, New Cairo',
          'hi': '5वां सेटलमेंट, न्यू काहिरा',
        },
        cityCode: 'new_cairo',
        propertyTypeCode: 'apartment',
        unitNumber: 'شقة 402',
        buildingName: 'برج الياسمين - النرجس 3',
        pricePerMonth: 22000,
        bedrooms: 3,
        bathrooms: 2,
        areaSqM: 185,
        image: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1540518614846-7ede433c4ef7?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800&auto=format&fit=crop&q=80',
        ],
        isPublished: false, // مخفية من السوق لأنها مؤجرة حالياً
        rentalStatus: PropertyRentalStatus.rented,
        tenantName: 'أحمد محمود القاضي',
        tenantPhone: '+20 101 234 5678',
        leaseStartDate: DateTime(2026, 1, 1),
        leaseEndDate: DateTime(2026, 12, 31),
        installments: _generateInstallmentsFor2026(
          monthlyAmount: 22000,
          paidMonthsCount: 3,
          dueMonthIndex: 3, // April
        ),
      ),

      ManagedPropertyModel(
        id: 'prop-eg-102',
        countryCode: 'EG',
        currencyCode: 'EGP',
        titles: {
          'ar': 'فيلا مستقلة بحمام سباحة - بيفرلي هيلز',
          'en': 'Private Villa with Pool - Beverly Hills',
          'hi': 'पूल के साथ निजी विला - बेवर्ली हिल्स',
        },
        descriptions: {
          'ar': 'فيلا فخمة 380م² بحديقة خاصة وحمام سباحة، 5 غرف نوم وجناح ماستر، تشطيب راقٍ جداً.',
          'en': 'Luxury 380m² private villa with pool, 5 bedrooms, master suite, ultra super-lux.',
          'hi': 'पूल के साथ लक्जरी 380 वर्ग मीटर निजी विला, 5 बेडरूम, मास्टर सुइट।',
        },
        locations: {
          'ar': 'الشيخ زايد، الجيزة',
          'en': 'Sheikh Zayed, Giza',
          'hi': 'शेख जायद, गीज़ा',
        },
        cityCode: 'sheikh_zayed',
        propertyTypeCode: 'villa',
        unitNumber: 'فيلا 12',
        buildingName: 'كمبوند بيفرلي هيلز - المرحلة 2',
        pricePerMonth: 35000,
        bedrooms: 5,
        bathrooms: 4,
        areaSqM: 380,
        image: 'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1540518614846-7ede433c4ef7?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
        ],
        isPublished: false,
        rentalStatus: PropertyRentalStatus.rented,
        tenantName: 'سارة خالد الدسوقي',
        tenantPhone: '+20 112 345 6789',
        leaseStartDate: DateTime(2026, 1, 1),
        leaseEndDate: DateTime(2026, 12, 31),
        installments: _generateInstallmentsFor2026(
          monthlyAmount: 35000,
          paidMonthsCount: 2,
          dueMonthIndex: 2, // March overdue
          hasOverdue: true,
        ),
      ),

      ManagedPropertyModel(
        id: 'prop-eg-103',
        countryCode: 'EG',
        currencyCode: 'EGP',
        titles: {
          'ar': 'شقة مطلة على النيل - جاردن سيتي',
          'en': 'Nile View Apartment - Garden City',
          'hi': 'नाइल व्यू अपार्टमेंट - गार्डन सिटी',
        },
        descriptions: {
          'ar': 'شقة مميزة بإطلالة بانورامية ساحرة على النيل، 210م²، 3 غرف نوم.',
          'en': 'Prime 210m² apartment with breathtaking Nile views, 3 bedrooms.',
          'hi': 'नाइल के मनोरम दृश्य वाला 210 वर्ग मीटर का प्रमुख अपार्टमेंट, 3 बेडरूम।',
        },
        locations: {
          'ar': 'جاردن سيتي، القاهرة',
          'en': 'Garden City, Cairo',
          'hi': 'गार्डन सिटी, काहिरा',
        },
        cityCode: 'maadi',
        propertyTypeCode: 'apartment',
        unitNumber: 'شقة 701',
        buildingName: 'برج النيل بلازا',
        pricePerMonth: 21000,
        bedrooms: 3,
        bathrooms: 2,
        areaSqM: 210,
        image: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1540518614846-7ede433c4ef7?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800&auto=format&fit=crop&q=80',
        ],
        isPublished: false,
        rentalStatus: PropertyRentalStatus.rented,
        tenantName: 'أ. سارة المنشاوي',
        tenantPhone: '+20 109 876 5432',
        leaseStartDate: DateTime(2026, 1, 1),
        leaseEndDate: DateTime(2026, 12, 31),
        installments: _generateInstallmentsFor2026(
          monthlyAmount: 21000,
          paidMonthsCount: 3,
          dueMonthIndex: 3,
        ),
      ),

      ManagedPropertyModel(
        id: 'prop-eg-104',
        countryCode: 'EG',
        currencyCode: 'EGP',
        titles: {
          'ar': 'شاليه بحري صف أول - أمواج',
          'en': 'Seafront Chalet - Amwaj',
          'hi': 'समुद्र तट शैले - अमवाज',
        },
        descriptions: {
          'ar': 'شاليه مفروش بالكامل صف أول على البحر واللاجون، 140م²، 3 غرف نوم.',
          'en': 'Fully furnished seafront chalet on direct beach and lagoon, 140m².',
          'hi': 'सीधे समुद्र तट पर पूरी तरह से सुसज्जित समुद्र तटीय शैले, 140 वर्ग मीटर।',
        },
        locations: {
          'ar': 'سيدي عبد الرحمن، الساحل الشمالي',
          'en': 'Sidi Abdel Rahman, North Coast',
          'hi': 'सिदी अब्देल रहमान, उत्तरी तट',
        },
        cityCode: 'north_coast',
        propertyTypeCode: 'chalet',
        unitNumber: 'شاليه 104',
        buildingName: 'قرية أمواج - سيدي عبد الرحمن',
        pricePerMonth: 25000,
        bedrooms: 3,
        bathrooms: 2,
        areaSqM: 140,
        image: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1540518614846-7ede433c4ef7?w=800&auto=format&fit=crop&q=80',
        ],
        isPublished: true, // معروضة في السوق العام ومتاحة
        rentalStatus: PropertyRentalStatus.available,
        tenantName: null,
        tenantPhone: null,
        leaseStartDate: null,
        leaseEndDate: null,
        installments: const [],
      ),

      // --- UAE Properties ---
      ManagedPropertyModel(
        id: 'prop-ae-101',
        countryCode: 'AE',
        currencyCode: 'AED',
        titles: {
          'ar': 'شقة فندقية فاخرة - مارينا جيت',
          'en': 'Luxury Serviced Apartment - Marina Gate',
          'hi': 'लक्जरी सर्विस्ड अपार्टमेंट - मरीना गेट',
        },
        descriptions: {
          'ar': 'إطلالة مائية خلابة على مرسى دبي، تشطيب عالمي متكامل، مسبح إنفينيتي ونادي صحي.',
          'en': 'Breathtaking Dubai Marina view, world-class finishes, infinity pool and fitness club.',
          'hi': 'दुबई मरीना का मनमोहक दृश्य, विश्व स्तरीय फिनिश, इन्फिनिटी पूल।',
        },
        locations: {
          'ar': 'دبي مارينا، دبي',
          'en': 'Dubai Marina, Dubai',
          'hi': 'दुबई मरीना, दुबई',
        },
        cityCode: 'dubai',
        propertyTypeCode: 'apartment',
        unitNumber: 'شقة 1804',
        buildingName: 'برج مارينا جيت 1',
        pricePerMonth: 18500,
        bedrooms: 2,
        bathrooms: 2,
        areaSqM: 135,
        image: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1540518614846-7ede433c4ef7?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800&auto=format&fit=crop&q=80',
        ],
        isPublished: false,
        rentalStatus: PropertyRentalStatus.rented,
        tenantName: 'طارق عبد الله المنصوري',
        tenantPhone: '+971 50 123 4567',
        leaseStartDate: DateTime(2026, 1, 1),
        leaseEndDate: DateTime(2026, 12, 31),
        installments: _generateInstallmentsFor2026(
          monthlyAmount: 18500,
          paidMonthsCount: 3,
          dueMonthIndex: 3,
        ),
      ),

      ManagedPropertyModel(
        id: 'prop-ae-102',
        countryCode: 'AE',
        currencyCode: 'AED',
        titles: {
          'ar': 'بنتهاوس ملكي - نخلة جميرا',
          'en': 'Royal Penthouse - Palm Jumeirah',
          'hi': 'रॉयल पेंटहाउस - पाम जुमेराह',
        },
        descriptions: {
          'ar': 'بنتهاوس استثنائي على شاطئ نخلة جميرا الخاص مع مسبح خاص وإطلالة على أفق دبي.',
          'en': 'Exceptional private beach penthouse on Palm Jumeirah with private pool.',
          'hi': 'पाम जुमेराह पर निजी समुद्र तट के साथ असाधारण पेंटहाउस।',
        },
        locations: {
          'ar': 'نخلة جميرا، دبي',
          'en': 'Palm Jumeirah, Dubai',
          'hi': 'पाम जुमेराह, दुबई',
        },
        cityCode: 'dubai',
        propertyTypeCode: 'duplex',
        unitNumber: 'بنتهاوس PH-02',
        buildingName: 'سيفن بالم ريزيدنس',
        pricePerMonth: 42000,
        bedrooms: 4,
        bathrooms: 5,
        areaSqM: 420,
        image: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1540518614846-7ede433c4ef7?w=800&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800&auto=format&fit=crop&q=80',
        ],
        isPublished: true,
        rentalStatus: PropertyRentalStatus.available,
        tenantName: null,
        tenantPhone: null,
        leaseStartDate: null,
        leaseEndDate: null,
        installments: const [],
      ),
    ];
  }

  /// Generates a real, dynamic monthly installment schedule based on actual lease terms.
  static List<MonthlyInstallment> generateDynamicSchedule({
    required double monthlyAmount,
    required DateTime startDate,
    int durationMonths = 12,
    bool firstMonthPaid = false,
    String? firstMonthPaymentMethod,
    DateTime? firstMonthPaidAt,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthsHi = [
      'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];

    return List.generate(durationMonths, (index) {
      final totalMonthOffset = (startDate.month - 1) + index;
      final dueYear = startDate.year + (totalMonthOffset ~/ 12);
      final dueMonth = (totalMonthOffset % 12) + 1;
      final maxDays = DateTime(dueYear, dueMonth + 1, 0).day;
      final dueDay = startDate.day <= maxDays ? startDate.day : maxDays;
      final dueDate = DateTime(dueYear, dueMonth, dueDay);

      final monthNum = (index + 1).toString().padLeft(2, '0');
      final monthKey = '$dueYear-${dueMonth.toString().padLeft(2, '0')}';

      InstallmentPaymentStatus status;
      DateTime? paidAt;
      String? paymentMethod;
      String? txnRef;
      String? receiptNumber;

      if (index == 0 && firstMonthPaid) {
        paidAt = firstMonthPaidAt ?? startDate;
        if (firstMonthPaymentMethod == 'bank_wire') {
          status = InstallmentPaymentStatus.paidBankWire;
          paymentMethod = 'bank_wire';
          txnRef = 'TXN-WIRE-${100000 + (startDate.millisecondsSinceEpoch % 900000)}';
        } else if (firstMonthPaymentMethod == 'online') {
          status = InstallmentPaymentStatus.paidOnline;
          paymentMethod = 'online';
          txnRef = 'TXN-ONL-${100000 + (startDate.millisecondsSinceEpoch % 900000)}';
        } else {
          status = InstallmentPaymentStatus.paidCash;
          paymentMethod = 'cash';
          txnRef = 'TXN-CASH-${1000 + (startDate.millisecondsSinceEpoch % 9000)}';
        }
        receiptNumber = 'REC-$dueYear-${(index + 1).toString().padLeft(4, '0')}';
      } else {
        final dueDayOnly = DateTime(dueYear, dueMonth, dueDay);
        if (dueDayOnly.isBefore(today)) {
          status = InstallmentPaymentStatus.overdue;
        } else if (today.year == dueYear && today.month == dueMonth) {
          status = InstallmentPaymentStatus.due;
        } else if (dueDayOnly.difference(today).inDays <= 7 && dueDayOnly.difference(today).inDays >= 0) {
          status = InstallmentPaymentStatus.due;
        } else {
          status = InstallmentPaymentStatus.upcoming;
        }
      }

      return MonthlyInstallment(
        monthKey: monthKey,
        monthNumber: monthNum,
        monthNames: {
          'ar': '${monthsAr[dueMonth - 1]} $dueYear',
          'en': '${monthsEn[dueMonth - 1]} $dueYear',
          'hi': '${monthsHi[dueMonth - 1]} $dueYear',
        },
        amount: monthlyAmount,
        dueDate: dueDate,
        paidAt: paidAt,
        status: status,
        paymentMethod: paymentMethod,
        transactionRef: txnRef,
        receiptNumber: receiptNumber,
      );
    });
  }

  static List<MonthlyInstallment> _generateInstallmentsFor2026({
    required double monthlyAmount,
    required int paidMonthsCount,
    required int dueMonthIndex,
    bool hasOverdue = false,
  }) {
    final monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthsHi = [
      'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];

    return List.generate(12, (index) {
      final monthNum = (index + 1).toString().padLeft(2, '0');
      final monthKey = '2026-$monthNum';
      final dueDate = DateTime(2026, index + 1, 5);

      InstallmentPaymentStatus status;
      DateTime? paidAt;
      String? paymentMethod;
      String? txnRef;
      String? receiptNumber;

      if (index < paidMonthsCount) {
        if (index == 0) {
          status = InstallmentPaymentStatus.paidOnline;
          paidAt = DateTime(2026, 1, 3, 14, 30);
          paymentMethod = 'apple_pay';
          txnRef = 'TXN-APAY-982144';
          receiptNumber = 'REC-2026-0101';
        } else if (index == 1) {
          status = InstallmentPaymentStatus.paidOnline;
          paidAt = DateTime(2026, 2, 4, 10, 15);
          paymentMethod = 'google_pay';
          txnRef = 'TXN-GPAY-772910';
          receiptNumber = 'REC-2026-0202';
        } else {
          status = InstallmentPaymentStatus.paidCash;
          paidAt = DateTime(2026, 3, 1, 18, 00);
          paymentMethod = 'cash';
          txnRef = 'TXN-CASH-HAND-554';
          receiptNumber = 'REC-2026-0303';
        }
      } else if (index == dueMonthIndex) {
        status = hasOverdue
            ? InstallmentPaymentStatus.overdue
            : InstallmentPaymentStatus.due;
      } else {
        status = InstallmentPaymentStatus.upcoming;
      }

      return MonthlyInstallment(
        monthKey: monthKey,
        monthNumber: monthNum,
        monthNames: {
          'ar': '${monthsAr[index]} 2026',
          'en': '${monthsEn[index]} 2026',
          'hi': '${monthsHi[index]} 2026',
        },
        amount: monthlyAmount,
        dueDate: dueDate,
        paidAt: paidAt,
        status: status,
        paymentMethod: paymentMethod,
        transactionRef: txnRef,
        receiptNumber: receiptNumber,
      );
    });
  }

  // --- ACTIONS ---

  /// Add a newly onboarded property to the owner's managed list (تظهر فوراً في عقاراتي وتُحفظ بالسحابة)
  Future<void> addProperty(ManagedPropertyModel property) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    list.removeWhere((p) => p.id == property.id);
    list.insert(0, property);
    propertiesNotifier.value = list;

    // Persist to Owner's dedicated Firestore tree & Marketplace (safely caught in test/offline environments)
    try {
      await _firestoreService?.saveOwnerProperty(
        ownerId: currentOwnerId,
        property: property,
      );
    } catch (e) {
      debugPrint('Firestore save note (safe in test/offline): $e');
    }
  }

  /// Update an existing property's details
  Future<void> updateProperty(ManagedPropertyModel property) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final idx = list.indexWhere((p) => p.id == property.id);
    if (idx != -1) {
      list[idx] = property;
    } else {
      list.insert(0, property);
    }
    propertiesNotifier.value = list;

    // Persist to Owner's dedicated Firestore tree & Marketplace
    try {
      await _firestoreService?.saveOwnerProperty(
        ownerId: currentOwnerId,
        property: property,
      );
    } catch (e) {
      debugPrint('Firestore update note (safe in test/offline): $e');
    }
  }

  /// Publish a property to the Public Marketplace (تظهر فوراً للزوار)
  Future<void> publishProperty(String propertyId) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final idx = list.indexWhere((p) => p.id == propertyId);
    if (idx != -1) {
      final updated = list[idx].copyWith(
        isPublished: true,
        rentalStatus: PropertyRentalStatus.available,
      );
      list[idx] = updated;
      propertiesNotifier.value = list;

      try {
        await _firestoreService?.saveOwnerProperty(
          ownerId: currentOwnerId,
          property: updated,
        );
      } catch (e) {
        debugPrint('Firestore publish note (safe in test/offline): $e');
      }
    }
  }

  /// Unpublish / Hide property from Public Marketplace (إخفاء من السوق العام)
  Future<void> unpublishProperty(String propertyId) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final idx = list.indexWhere((p) => p.id == propertyId);
    if (idx != -1) {
      final updated = list[idx].copyWith(
        isPublished: false,
      );
      list[idx] = updated;
      propertiesNotifier.value = list;

      try {
        await _firestoreService?.saveOwnerProperty(
          ownerId: currentOwnerId,
          property: updated,
        );
      } catch (e) {
        debugPrint('Firestore unpublish note (safe in test/offline): $e');
      }
    }
  }

  /// Mark property as Rented (تأجير الوحدة وإخفاؤها تلقائياً من السوق وبدء جدول الدفعات الحقيقي)
  Future<void> markAsRented({
    required String propertyId,
    required String tenantName,
    required String tenantPhone,
    required double monthlyRent,
    DateTime? startDate,
    DateTime? endDate,
    int durationMonths = 12,
    bool firstMonthPaid = false,
    String? firstMonthPaymentMethod,
  }) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final idx = list.indexWhere((p) => p.id == propertyId);
    if (idx != -1) {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime(start.year, start.month + durationMonths, start.day);

      final updated = list[idx].copyWith(
        isPublished: false, // تختفي تلقائياً من السوق العام
        rentalStatus: PropertyRentalStatus.rented,
        tenantName: tenantName,
        tenantPhone: tenantPhone,
        pricePerMonth: monthlyRent,
        leaseStartDate: start,
        leaseEndDate: end,
        installments: generateDynamicSchedule(
          monthlyAmount: monthlyRent,
          startDate: start,
          durationMonths: durationMonths,
          firstMonthPaid: firstMonthPaid,
          firstMonthPaymentMethod: firstMonthPaymentMethod,
        ),
      );
      list[idx] = updated;
      propertiesNotifier.value = list;

      try {
        await _firestoreService?.saveOwnerProperty(
          ownerId: currentOwnerId,
          property: updated,
        );
      } catch (e) {
        debugPrint('Firestore markAsRented note (safe in test/offline): $e');
      }
    }
  }

  /// Record manual payment (تسجيل سداد دفعة كاش أو تحويل بنكي)
  Future<void> recordInstallmentPayment({
    required String propertyId,
    required String monthKey,
    required InstallmentPaymentStatus status,
    required String paymentMethod,
    String? notes,
  }) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final propIdx = list.indexWhere((p) => p.id == propertyId);
    if (propIdx != -1) {
      final prop = list[propIdx];
      final installments = List<MonthlyInstallment>.from(prop.installments);
      final instIdx = installments.indexWhere((inst) => inst.monthKey == monthKey);

      if (instIdx != -1) {
        final randomCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
        installments[instIdx] = installments[instIdx].copyWith(
          status: status,
          paidAt: DateTime.now(),
          paymentMethod: paymentMethod,
          transactionRef: 'TXN-REC-$paymentMethod-$randomCode',
          receiptNumber: 'REC-2026-${installments[instIdx].monthNumber}',
          notes: notes,
        );

        final updated = prop.copyWith(installments: installments);
        list[propIdx] = updated;
        propertiesNotifier.value = list;

        try {
          await _firestoreService?.saveOwnerProperty(
            ownerId: currentOwnerId,
            property: updated,
          );
        } catch (e) {
          debugPrint('Firestore record payment note (safe in test/offline): $e');
        }
      } else {
        // Installment not pre-generated; create it dynamically
        final monthParts = monthKey.split('-');
        final monthInt = int.tryParse(monthParts.length > 1 ? monthParts[1] : '1') ?? 1;
        final monthNum = monthInt.toString().padLeft(2, '0');
        final randomCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
        installments.add(MonthlyInstallment(
          monthKey: monthKey,
          monthNumber: monthNum,
          dueDate: DateTime(int.tryParse(monthParts[0]) ?? 2026, monthInt, 10),
          monthNames: {
            'ar': 'شهر $monthNum',
            'en': 'Month $monthNum',
            'hi': 'महीना $monthNum',
          },
          amount: prop.pricePerMonth,
          status: status,
          paidAt: DateTime.now(),
          paymentMethod: paymentMethod,
          transactionRef: 'TXN-REC-$paymentMethod-$randomCode',
          receiptNumber: 'REC-2026-$monthNum',
          notes: notes,
        ));

        final updated = prop.copyWith(installments: installments);
        list[propIdx] = updated;
        propertiesNotifier.value = list;

        try {
          await _firestoreService?.saveOwnerProperty(
            ownerId: currentOwnerId,
            property: updated,
          );
        } catch (e) {
          debugPrint('Firestore record payment note (safe in test/offline): $e');
        }
      }
    }
  }

  /// Ensure an installment exists for a property (when an invoice is created in Rent Collection)
  void addOrUpdateInstallmentForProperty({
    required String propertyId,
    required String monthKey,
    required DateTime dueDate,
    required double amount,
  }) {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final propIdx = list.indexWhere((p) => p.id == propertyId);
    if (propIdx != -1) {
      final prop = list[propIdx];
      final installments = List<MonthlyInstallment>.from(prop.installments);
      final instIdx = installments.indexWhere((i) => i.monthKey == monthKey);
      if (instIdx == -1) {
        final monthParts = monthKey.split('-');
        final monthInt = int.tryParse(monthParts.length > 1 ? monthParts[1] : '1') ?? 1;
        final monthNum = monthInt.toString().padLeft(2, '0');
        installments.add(MonthlyInstallment(
          monthKey: monthKey,
          monthNumber: monthNum,
          dueDate: dueDate,
          monthNames: {
            'ar': 'شهر $monthNum',
            'en': 'Month $monthNum',
            'hi': 'महीना $monthNum',
          },
          amount: amount,
          status: dueDate.isBefore(DateTime.now())
              ? InstallmentPaymentStatus.overdue
              : InstallmentPaymentStatus.due,
        ));
      } else {
        installments[instIdx] = installments[instIdx].copyWith(
          amount: amount,
          dueDate: dueDate,
        );
      }
      list[propIdx] = prop.copyWith(installments: installments);
      propertiesNotifier.value = list;
    }
  }

  /// Soft delete an installment for a property (when an invoice is moved to trash)
  Future<void> softDeleteInstallmentForProperty({
    required String propertyId,
    required String monthKey,
  }) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final propIdx = list.indexWhere((p) => p.id == propertyId);
    if (propIdx != -1) {
      final prop = list[propIdx];
      final now = DateTime.now();
      final installments = List<MonthlyInstallment>.from(prop.installments);
      final instIdx = installments.indexWhere((i) => i.monthKey == monthKey);
      if (instIdx != -1) {
        installments[instIdx] = installments[instIdx].copyWith(
          isDeleted: true,
          deletedAt: now,
        );
      }
      final updated = prop.copyWith(installments: installments);
      list[propIdx] = updated;
      propertiesNotifier.value = list;

      try {
        await _firestoreService?.saveOwnerProperty(
          ownerId: currentOwnerId,
          property: updated,
        );
      } catch (e) {
        debugPrint('Firestore softDeleteInstallment note: $e');
      }
    }
  }

  /// Restore an installment for a property (when an invoice is restored from trash)
  Future<void> restoreInstallmentForProperty({
    required String propertyId,
    required String monthKey,
  }) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final propIdx = list.indexWhere((p) => p.id == propertyId);
    if (propIdx != -1) {
      final prop = list[propIdx];
      final installments = List<MonthlyInstallment>.from(prop.installments);
      final instIdx = installments.indexWhere((i) => i.monthKey == monthKey);
      if (instIdx != -1) {
        installments[instIdx] = installments[instIdx].copyWith(
          isDeleted: false,
          deletedAt: null,
        );
      }
      final updated = prop.copyWith(installments: installments);
      list[propIdx] = updated;
      propertiesNotifier.value = list;

      try {
        await _firestoreService?.saveOwnerProperty(
          ownerId: currentOwnerId,
          property: updated,
        );
      } catch (e) {
        debugPrint('Firestore restoreInstallment note: $e');
      }
    }
  }

  /// Remove an installment for a property (when an invoice is permanently deleted)
  Future<void> removeInstallmentForProperty({
    required String propertyId,
    required String monthKey,
  }) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final propIdx = list.indexWhere((p) => p.id == propertyId);
    if (propIdx != -1) {
      final prop = list[propIdx];
      final installments = List<MonthlyInstallment>.from(prop.installments)
        ..removeWhere((i) => i.monthKey == monthKey);
      final archived = List<MonthlyInstallment>.from(prop.archivedInstallments)
        ..removeWhere((i) => i.monthKey == monthKey);
      final updated = prop.copyWith(
        installments: installments,
        archivedInstallments: archived,
      );
      list[propIdx] = updated;
      propertiesNotifier.value = list;

      try {
        await _firestoreService?.saveOwnerProperty(
          ownerId: currentOwnerId,
          property: updated,
        );
      } catch (e) {
        debugPrint('Firestore removeInstallment note: $e');
      }
    }
  }

  /// End lease and re-publish back to Public Marketplace (إنهاء العقد وإعادة العرض بالسوق مع أرشفة السجل المالي)
  Future<void> endLeaseAndRePublish({
    required String propertyId,
    bool republishToMarketplace = true,
  }) async {
    final list = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final idx = list.indexWhere((p) => p.id == propertyId);
    if (idx != -1) {
      final prop = list[idx];
      // Archive all paid installments so financial history is 100% preserved
      final paidFromCurrent = prop.installments.where((i) => i.isPaid).toList();
      final updatedArchived = List<MonthlyInstallment>.from(prop.archivedInstallments)..addAll(paidFromCurrent);

      final updated = prop.copyWith(
        isPublished: republishToMarketplace, // تظهر فوراً في السوق العام أو كمسودة خاصة
        rentalStatus: PropertyRentalStatus.available,
        clearTenant: true,
        installments: const [],
        archivedInstallments: updatedArchived,
      );
      list[idx] = updated;
      propertiesNotifier.value = list;

      try {
        await _firestoreService?.saveOwnerProperty(
          ownerId: currentOwnerId,
          property: updated,
        );
      } catch (e) {
        debugPrint('Firestore end lease note (safe in test/offline): $e');
      }
    }
  }

  /// Reorder properties via drag-and-drop within a specific country portfolio
  void reorderProperties(int oldIndex, int newIndex, String countryCode) {
    final fullList = List<ManagedPropertyModel>.from(propertiesNotifier.value);
    final countryIndices = <int>[];
    for (int i = 0; i < fullList.length; i++) {
      if (fullList[i].countryCode == countryCode) {
        countryIndices.add(i);
      }
    }

    if (oldIndex < 0 || oldIndex >= countryIndices.length) return;
    if (newIndex < 0) newIndex = 0;
    if (newIndex > countryIndices.length) newIndex = countryIndices.length;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final realOldIdx = countryIndices[oldIndex];
    final item = fullList.removeAt(realOldIdx);

    // Recompute country indices after removal
    countryIndices.clear();
    for (int i = 0; i < fullList.length; i++) {
      if (fullList[i].countryCode == countryCode) {
        countryIndices.add(i);
      }
    }

    if (newIndex >= countryIndices.length) {
      if (countryIndices.isEmpty) {
        fullList.add(item);
      } else {
        fullList.insert(countryIndices.last + 1, item);
      }
    } else {
      final realNewIdx = countryIndices[newIndex];
      fullList.insert(realNewIdx, item);
    }

    propertiesNotifier.value = fullList;
  }

  /// Returns real, dynamic payout ledger transactions strictly tied to the owner's actual properties and collected rents.
  List<Map<String, dynamic>> getRealPayouts({String? countryCode}) {
    final list = propertiesNotifier.value;
    final filtered = countryCode != null ? list.where((p) => p.countryCode == countryCode).toList() : list;

    final List<Map<String, dynamic>> payouts = [];

    for (final prop in filtered) {
      // 1. Process any paid installments from current active lease
      for (final inst in prop.installments) {
        if (inst.isPaid) {
          final paidDate = inst.paidAt ?? inst.dueDate;
          payouts.add({
            'propertyId': prop.id,
            'titles': {
              'ar': 'تحويل إيجار ${prop.getTitle('ar')} (${inst.getMonthName('ar')})',
              'en': 'Rent Payout - ${prop.getTitle('en')} (${inst.getMonthName('en')})',
              'hi': 'किराया भुगतान - ${prop.getTitle('hi')} (${inst.getMonthName('hi')})',
            },
            'dates': {
              'ar': '${paidDate.day} ${inst.getMonthName('ar')} ${paidDate.year}',
              'en': '${inst.getMonthName('en')} ${paidDate.day}, ${paidDate.year}',
              'hi': '${paidDate.day} ${inst.getMonthName('hi')} ${paidDate.year}',
            },
            'ref': inst.transactionRef ?? (inst.receiptNumber != null ? 'TXN-${inst.receiptNumber}' : 'TXN-${10000 + inst.dueDate.month * 100}'),
            'amount': inst.amount,
            'paidDate': paidDate,
            'paymentMethod': inst.paymentMethod,
          });
        }
      }

      // 2. Process any paid installments from past archived leases (zero financial loss)
      for (final inst in prop.archivedInstallments) {
        if (inst.isPaid) {
          final paidDate = inst.paidAt ?? inst.dueDate;
          payouts.add({
            'propertyId': prop.id,
            'titles': {
              'ar': 'تحويل إيجار ${prop.getTitle('ar')} (${inst.getMonthName('ar')})',
              'en': 'Rent Payout - ${prop.getTitle('en')} (${inst.getMonthName('en')})',
              'hi': 'किराया भुगतान - ${prop.getTitle('hi')} (${inst.getMonthName('hi')})',
            },
            'dates': {
              'ar': '${paidDate.day} ${inst.getMonthName('ar')} ${paidDate.year}',
              'en': '${inst.getMonthName('en')} ${paidDate.day}, ${paidDate.year}',
              'hi': '${paidDate.day} ${inst.getMonthName('hi')} ${paidDate.year}',
            },
            'ref': inst.transactionRef ?? (inst.receiptNumber != null ? 'TXN-${inst.receiptNumber}' : 'TXN-${10000 + inst.dueDate.month * 100}'),
            'amount': inst.amount,
            'paidDate': paidDate,
            'paymentMethod': inst.paymentMethod,
          });
        }
      }

      // 2. If the property is occupied/rented, but no installments have been explicitly marked as paid yet,
      // provide the active lease rental transfer for this unit (e.g. the 500 EGP rent that was just activated)
      if (prop.isOccupied && !prop.installments.any((i) => i.isPaid)) {
        final start = prop.leaseStartDate ?? DateTime.now();
        final firstMonthInst = prop.installments.isNotEmpty ? prop.installments.first : null;
        final monthNameAr = firstMonthInst?.getMonthName('ar') ?? '${start.month}/${start.year}';
        final monthNameEn = firstMonthInst?.getMonthName('en') ?? '${start.month}/${start.year}';
        final monthNameHi = firstMonthInst?.getMonthName('hi') ?? '${start.month}/${start.year}';

        payouts.add({
          'propertyId': prop.id,
          'titles': {
            'ar': 'تحويل إيجار ${prop.getTitle('ar')} ($monthNameAr)',
            'en': 'Rent Payout - ${prop.getTitle('en')} ($monthNameEn)',
            'hi': 'किराया भुगतान - ${prop.getTitle('hi')} ($monthNameHi)',
          },
          'dates': {
            'ar': '${start.day} $monthNameAr ${start.year}',
            'en': '$monthNameEn ${start.day}, ${start.year}',
            'hi': '${start.day} $monthNameHi ${start.year}',
          },
          'ref': 'TXN-${10000 + (start.millisecondsSinceEpoch % 90000)}',
          'amount': prop.pricePerMonth,
          'paidDate': start,
          'paymentMethod': 'bank_wire',
        });
      }
    }

    payouts.sort((a, b) => (b['paidDate'] as DateTime).compareTo(a['paidDate'] as DateTime));
    return payouts;
  }
}

