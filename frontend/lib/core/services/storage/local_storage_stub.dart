import 'local_storage_service.dart';

LocalStorageEngine getLocalStorageEngine() => StubLocalStorageEngine();

class StubLocalStorageEngine implements LocalStorageEngine {
  final Map<String, String> _memory = {};

  @override
  String? getItem(String key) => _memory[key];

  @override
  void setItem(String key, String value) {
    _memory[key] = value;
  }

  @override
  void removeItem(String key) {
    _memory.remove(key);
  }

  @override
  void clear() {
    _memory.clear();
  }
}
