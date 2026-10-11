import 'dart:async';
import 'media_picker_stub.dart'
    if (dart.library.js_interop) 'media_picker_web.dart';

abstract class MediaPickerPlatform {
  Future<List<String>> pickImages();
}

class MediaPickerService {
  static final MediaPickerService _instance = MediaPickerService._internal();
  factory MediaPickerService() => _instance;
  MediaPickerService._internal() {
    _platform = getMediaPickerPlatform();
  }

  late final MediaPickerPlatform _platform;

  Future<List<String>> pickImages() => _platform.pickImages();
}
