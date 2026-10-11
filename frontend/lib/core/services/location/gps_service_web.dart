import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'gps_service.dart';

@JS('tashilGetGpsLocation')
external void _tashilGetGpsLocation(JSFunction onSuccess, JSFunction onError);

@JS('tashilOpenUrl')
external void _tashilOpenUrl(JSString url);

class PlatformGps implements GpsPlatform {
  @override
  Future<GpsPosition?> getCurrentPosition() {
    final completer = Completer<GpsPosition?>();

    void onSuccess(JSNumber lat, JSNumber lng) {
      completer.complete(GpsPosition(
        latitude: lat.toDartDouble,
        longitude: lng.toDartDouble,
      ));
    }

    void onError(JSString error) {
      debugPrint('GPS Error: ${error.toDart}');
      completer.complete(null);
    }

    try {
      _tashilGetGpsLocation(onSuccess.toJS, onError.toJS);
    } catch (e) {
      debugPrint('GPS Exception: $e');
      completer.complete(null);
    }

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }

  @override
  void openUrl(String url) {
    try {
      _tashilOpenUrl(url.toJS);
    } catch (e) {
      debugPrint('Open URL Exception: $e');
    }
  }
}

GpsPlatform getGpsPlatform() => PlatformGps();
