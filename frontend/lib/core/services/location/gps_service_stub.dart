import 'package:url_launcher/url_launcher.dart';
import 'gps_service.dart';

class PlatformGps implements GpsPlatform {
  @override
  Future<GpsPosition?> getCurrentPosition() async => null;

  @override
  void openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fallback to platform default if external app mode fails
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
    }
  }
}

GpsPlatform getGpsPlatform() => PlatformGps();
