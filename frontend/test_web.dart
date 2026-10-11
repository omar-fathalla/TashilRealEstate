import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('tashilSpeechStart')
external bool tashilSpeechStart(JSString lang);

@JS('tashilSpeechStop')
external JSString tashilSpeechStop();

@JS('tashilSpeechIsSupported')
external bool tashilSpeechIsSupported();

@JS('tashilSpeechSetCallbacks')
external void tashilSpeechSetCallbacks(
  JSFunction onResult,
  JSFunction onError,
  JSFunction onEnd,
);

void test() {
  void onResult(JSString transcript) {
    debugPrint(transcript.toDart);
  }

  void onError(JSString error) {
    debugPrint(error.toDart);
  }

  void onEnd(JSString finalTranscript) {
    debugPrint(finalTranscript.toDart);
  }

  tashilSpeechSetCallbacks(
    onResult.toJS,
    onError.toJS,
    onEnd.toJS,
  );
}

void main() {}
