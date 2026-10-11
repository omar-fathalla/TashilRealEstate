import 'package:web/web.dart' as web;
import 'local_storage_service.dart';

LocalStorageEngine getLocalStorageEngine() => WebLocalStorageEngine();

class WebLocalStorageEngine implements LocalStorageEngine {
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

  @override
  void clear() {
    try {
      web.window.localStorage.clear();
    } catch (_) {}
  }
}
