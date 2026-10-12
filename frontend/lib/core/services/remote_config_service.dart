import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Centralized Enterprise Firebase Remote Config Service for Tashil Real Estate.
/// Allows dynamic, real-time modification of operational parameters, financial rates,
/// feature flags, and localized promotional announcements without rebuilding the app.
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  /// Default configuration values ensuring graceful offline fallback
  static const Map<String, dynamic> _defaults = {
    'platform_fee_percent': 2.5,
    'vat_rate_eg': 0.14,
    'vat_rate_ae': 0.05,
    'max_search_price_eg': 100000.0,
    'max_search_price_ae': 50000.0,
    'enable_legal_ai': true,
    'enable_virtual_staging': true,
    'enable_ai_valuation': true,
    'emergency_maintenance_phone_eg': '+20 100 000 0000',
    'emergency_maintenance_phone_ae': '+971 4 000 0000',
    'announcement_banner_ar': 'عقارات موثقة ومفحوصة بالكامل للإيجار في مصر والإمارات',
    'announcement_banner_en': 'Verified & fully inspected rental properties across Egypt & UAE',
    'announcement_banner_hi': 'मिस्र और यूएई में किराए के लिए सत्यापित संपत्तियां',
  };

  /// Initializes Remote Config and activates fetched parameters
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      await _remoteConfig!.setDefaults(_defaults);
      await _remoteConfig!.fetchAndActivate();
      _isInitialized = true;
      debugPrint('✅ Firebase Remote Config initialized and activated.');
    } catch (e) {
      debugPrint('ℹ️ Remote Config initialized with default offline fallbacks: $e');
      _isInitialized = true;
    }
  }

  // --- Getters for Dynamic Financial & Operational Parameters ---

  double get platformFeePercent {
    if (_remoteConfig == null) return _defaults['platform_fee_percent'] as double;
    return _remoteConfig!.getDouble('platform_fee_percent');
  }

  double get platformFeePercentage => platformFeePercent;

  double get minSearchPrice => 3000.0;

  double get maxSearchPrice => getMaxSearchPrice('EG');

  double getVatRate(String countryCode) {
    if (countryCode == 'AE') {
      return _remoteConfig?.getDouble('vat_rate_ae') ?? (_defaults['vat_rate_ae'] as double);
    }
    return _remoteConfig?.getDouble('vat_rate_eg') ?? (_defaults['vat_rate_eg'] as double);
  }

  double getMaxSearchPrice(String countryCode) {
    if (countryCode == 'AE') {
      return _remoteConfig?.getDouble('max_search_price_ae') ?? (_defaults['max_search_price_ae'] as double);
    }
    return _remoteConfig?.getDouble('max_search_price_eg') ?? (_defaults['max_search_price_eg'] as double);
  }

  /// Manually syncs and activates parameters from Cloud
  Future<bool> syncFromCloud() async {
    try {
      if (_remoteConfig != null) {
        return await _remoteConfig!.fetchAndActivate();
      }
      return true;
    } catch (e) {
      debugPrint('[RemoteConfigService] Sync notice: $e');
      return false;
    }
  }

  // --- Feature Flags ---

  bool get isLegalAiEnabled {
    if (_remoteConfig == null) return _defaults['enable_legal_ai'] as bool;
    return _remoteConfig!.getBool('enable_legal_ai');
  }

  bool get isVirtualStagingEnabled {
    if (_remoteConfig == null) return _defaults['enable_virtual_staging'] as bool;
    return _remoteConfig!.getBool('enable_virtual_staging');
  }

  bool get isAiValuationEnabled {
    if (_remoteConfig == null) return _defaults['enable_ai_valuation'] as bool;
    return _remoteConfig!.getBool('enable_ai_valuation');
  }

  // --- Localized Announcements & Emergency Support ---

  String getAnnouncement(String langCode) {
    if (_remoteConfig == null) {
      return _defaults['announcement_banner_$langCode'] ?? _defaults['announcement_banner_ar'] as String;
    }
    final val = _remoteConfig!.getString('announcement_banner_$langCode');
    if (val.trim().isNotEmpty) return val;
    return _remoteConfig!.getString('announcement_banner_ar');
  }

  String getEmergencyPhone(String countryCode) {
    if (countryCode == 'AE') {
      return _remoteConfig?.getString('emergency_maintenance_phone_ae') ?? (_defaults['emergency_maintenance_phone_ae'] as String);
    }
    return _remoteConfig?.getString('emergency_maintenance_phone_eg') ?? (_defaults['emergency_maintenance_phone_eg'] as String);
  }
}
