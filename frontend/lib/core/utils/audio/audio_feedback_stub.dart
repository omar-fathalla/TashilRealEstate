import 'package:flutter/services.dart';

/// Non-web fallback implementation of audio and haptic feedback.
class AudioFeedbackPlatform {
  void playTick({double frequency = 800.0, double volume = 0.06}) {
    // In native mobile/desktop platforms, selectionClick provides the tactile tick.
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
