import 'gps_service.dart';

class PlatformGps implements GpsPlatform {
  @override
  Future<GpsPosition?> getCurrentPosition() async => null;

  @override
  void openUrl(String url) {}
}

GpsPlatform getGpsPlatform() => PlatformGps();
