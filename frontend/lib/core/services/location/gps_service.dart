import 'dart:async';
import 'gps_service_stub.dart'
    if (dart.library.js_interop) 'gps_service_web.dart';

class GpsPosition {
  final double latitude;
  final double longitude;

  const GpsPosition({required this.latitude, required this.longitude});
}

abstract class GpsPlatform {
  Future<GpsPosition?> getCurrentPosition();
  void openUrl(String url);
}

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal() {
    _platform = getGpsPlatform();
  }

  late final GpsPlatform _platform;

  Future<GpsPosition?> getCurrentPosition() => _platform.getCurrentPosition();
  void openUrl(String url) => _platform.openUrl(url);
}
