import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_storage_stub.dart'
    if (dart.library.js_interop) 'local_storage_web.dart';

abstract class LocalStorageEngine {
  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);
  void clear();
}

/// Central Platform-Resilient Local Storage Service for Tashil Real Estate.
///
/// Provides persistent caching for:
/// 1. Soft-deleted and permanently-deleted invoices & contracts across browser reloads.
/// 2. User-custom created invoices & contracts.
/// 3. Offline UI state and recovery.
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  LocalStorageService._internal() {
    _engine = getLocalStorageEngine();
  }

  late final LocalStorageEngine _engine;

  String? getString(String key) {
    try {
      return _engine.getItem(key);
    } catch (e) {
      debugPrint('⚠️ LocalStorageService.getString error: $e');
      return null;
    }
  }

  void setString(String key, String value) {
    try {
      _engine.setItem(key, value);
    } catch (e) {
      debugPrint('⚠️ LocalStorageService.setString error: $e');
    }
  }

  void remove(String key) {
    try {
      _engine.removeItem(key);
    } catch (e) {
      debugPrint('⚠️ LocalStorageService.remove error: $e');
    }
  }

  Map<String, String>? getStringMap(String key) {
    try {
      final raw = getString(key);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (e) {
      debugPrint('⚠️ LocalStorageService.getStringMap error: $e');
    }
    return null;
  }

  void setStringMap(String key, Map<String, String> map) {
    try {
      setString(key, jsonEncode(map));
    } catch (e) {
      debugPrint('⚠️ LocalStorageService.setStringMap error: $e');
    }
  }

  List<String>? getStringList(String key) {
    try {
      final raw = getString(key);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('⚠️ LocalStorageService.getStringList error: $e');
    }
    return null;
  }

  void setStringList(String key, List<String> list) {
    try {
      setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ LocalStorageService.setStringList error: $e');
    }
  }
}
