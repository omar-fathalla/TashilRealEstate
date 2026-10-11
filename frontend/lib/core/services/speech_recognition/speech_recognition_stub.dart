import 'speech_recognition_service.dart';

class PlatformSpeechRecognition implements SpeechRecognitionPlatform {
  @override
  bool isSupported() => false;

  @override
  void setCallbacks({
    required void Function(String transcript) onResult,
    required void Function(String error) onError,
    required void Function(String finalTranscript) onEnd,
  }) {}

  @override
  bool start(String lang) => false;

  @override
  String stop() => '';
}

SpeechRecognitionPlatform getSpeechRecognitionPlatform() => PlatformSpeechRecognition();
