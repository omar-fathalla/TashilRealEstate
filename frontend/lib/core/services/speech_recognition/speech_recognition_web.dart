import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'speech_recognition_service.dart';

@JS('tashilSpeechIsSupported')
external bool _tashilSpeechIsSupported();

@JS('tashilSpeechStart')
external bool _tashilSpeechStart(JSString lang);

@JS('tashilSpeechStop')
external JSString _tashilSpeechStop();

@JS('tashilSpeechSetCallbacks')
external void _tashilSpeechSetCallbacks(
  JSFunction? onResult,
  JSFunction? onError,
  JSFunction? onEnd,
);

class PlatformSpeechRecognition implements SpeechRecognitionPlatform {
  @override
  bool isSupported() {
    try {
      return _tashilSpeechIsSupported();
    } catch (e) {
      debugPrint('Speech check error: $e');
      return false;
    }
  }

  @override
  void setCallbacks({
    required void Function(String transcript) onResult,
    required void Function(String error) onError,
    required void Function(String finalTranscript) onEnd,
  }) {
    try {
      void handleResult(JSString text) {
        onResult(text.toDart);
      }

      void handleError(JSString err) {
        onError(err.toDart);
      }

      void handleEnd(JSString text) {
        onEnd(text.toDart);
      }

      _tashilSpeechSetCallbacks(
        handleResult.toJS,
        handleError.toJS,
        handleEnd.toJS,
      );
    } catch (e) {
      debugPrint('Set speech callbacks error: $e');
    }
  }

  @override
  bool start(String lang) {
    try {
      return _tashilSpeechStart(lang.toJS);
    } catch (e) {
      debugPrint('Speech start error: $e');
      return false;
    }
  }

  @override
  String stop() {
    try {
      return _tashilSpeechStop().toDart;
    } catch (e) {
      debugPrint('Speech stop error: $e');
      return '';
    }
  }
}

SpeechRecognitionPlatform getSpeechRecognitionPlatform() => PlatformSpeechRecognition();
