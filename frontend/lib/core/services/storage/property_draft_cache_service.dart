import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/features/fast_onboarding/models/property_onboarding_model.dart';
import 'property_draft_cache_stub.dart'
    if (dart.library.js_interop) 'property_draft_cache_web.dart';

abstract class PropertyDraftCacheStorage {
  void setItem(String key, String value);
  String? getItem(String key);
  void removeItem(String key);
}

class PropertyDraftCacheService {
  static final PropertyDraftCacheService _instance = PropertyDraftCacheService._internal();
  factory PropertyDraftCacheService() => _instance;
  PropertyDraftCacheService._internal() {
    _storage = getDraftCacheStorage();
  }

  static const String _draftKey = 'tashil_pending_property_draft_v1';
  late final PropertyDraftCacheStorage _storage;

  /// Saves the active onboarding draft into local storage/cache
  Future<void> saveDraft(FastPropertyDraft draft) async {
    try {
      final jsonStr = jsonEncode(draft.toJson());
      _storage.setItem(_draftKey, jsonStr);
      debugPrint('✅ Property draft cached successfully (${jsonStr.length} chars)');
    } catch (e) {
      debugPrint('⚠️ Error saving property draft to cache: $e');
    }
  }

  /// Retrieves the cached onboarding draft if present, or null
  FastPropertyDraft? getDraft() {
    try {
      final jsonStr = _storage.getItem(_draftKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return FastPropertyDraft.fromJson(decoded);
      } else if (decoded is Map) {
        return FastPropertyDraft.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('⚠️ Error retrieving property draft from cache: $e');
    }
    return null;
  }

  /// Checks if a valid cached draft exists
  bool hasDraft() {
    try {
      final jsonStr = _storage.getItem(_draftKey);
      return jsonStr != null && jsonStr.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Clears the cached draft after successful publishing
  Future<void> clearDraft() async {
    try {
      _storage.removeItem(_draftKey);
      debugPrint('🗑️ Property draft cache cleared.');
    } catch (e) {
      debugPrint('⚠️ Error clearing property draft cache: $e');
    }
  }
}
