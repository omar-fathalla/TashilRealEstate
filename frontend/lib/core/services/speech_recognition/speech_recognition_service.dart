import 'speech_recognition_stub.dart'
    if (dart.library.js_interop) 'speech_recognition_web.dart';

abstract class SpeechRecognitionPlatform {
  bool isSupported();
  void setCallbacks({
    required void Function(String transcript) onResult,
    required void Function(String error) onError,
    required void Function(String finalTranscript) onEnd,
  });
  bool start(String lang);
  String stop();
}

class SpeechRecognitionService {
  static final SpeechRecognitionService _instance = SpeechRecognitionService._internal();
  factory SpeechRecognitionService() => _instance;

  SpeechRecognitionService._internal() {
    _platform = getSpeechRecognitionPlatform();
  }

  late final SpeechRecognitionPlatform _platform;

  bool get isSupported => _platform.isSupported();

  void setCallbacks({
    required void Function(String transcript) onResult,
    required void Function(String error) onError,
    required void Function(String finalTranscript) onEnd,
  }) {
    _platform.setCallbacks(
      onResult: onResult,
      onError: onError,
      onEnd: onEnd,
    );
  }

  bool startListening({required String languageCode, required String countryCode}) {
    String lang = 'ar-EG';
    if (languageCode == 'en') {
      lang = 'en-US';
    } else if (languageCode == 'hi') {
      lang = 'hi-IN';
    } else {
      lang = countryCode == 'AE' ? 'ar-AE' : 'ar-EG';
    }
    return _platform.start(lang);
  }

  String stopListening() {
    return _platform.stop();
  }
}
