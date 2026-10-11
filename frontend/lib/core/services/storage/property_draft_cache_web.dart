import 'package:web/web.dart' as web;
import 'property_draft_cache_service.dart';

PropertyDraftCacheStorage getDraftCacheStorage() => WebPropertyDraftCacheStorage();

class WebPropertyDraftCacheStorage implements PropertyDraftCacheStorage {
  @override
  String? getItem(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void setItem(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {}
  }

  @override
  void removeItem(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }
}
