import 'property_draft_cache_service.dart';

PropertyDraftCacheStorage getDraftCacheStorage() => StubPropertyDraftCacheStorage();

class StubPropertyDraftCacheStorage implements PropertyDraftCacheStorage {
  final Map<String, String> _memoryMap = {};

  @override
  String? getItem(String key) => _memoryMap[key];

  @override
  void setItem(String key, String value) {
    _memoryMap[key] = value;
  }

  @override
  void removeItem(String key) {
    _memoryMap.remove(key);
  }
}
