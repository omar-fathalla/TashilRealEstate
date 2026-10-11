import 'audio_feedback_stub.dart'
    if (dart.library.js_interop) 'audio_feedback_web.dart';

/// Central Audio & Tactile Feedback Service for Tashil Real Estate.
///
/// Features:
/// 1. Instant zero-latency synthesis via browser Web Audio API on web.
/// 2. Haptic selection click fallback on mobile/desktop.
/// 3. Pitch modulation ("تن.. تن") scaling harmonically with price and volume.
/// 4. Intelligent rate throttling to keep dragging smooth without acoustic clutter.
class TashilAudioFeedback {
  static final AudioFeedbackPlatform _platform = AudioFeedbackPlatform();
  static int _lastPlayTimestamp = 0;

  TashilAudioFeedback._();

  /// Plays a subtle, pleasant slider tick ("تن.. تن") modulated by the current slider [fraction] (0.0 to 1.0).
  /// As the value increases, the pitch rises harmonically from 650Hz to 1150Hz.
  static void playSliderTick({double fraction = 0.5, bool throttle = true}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Throttle to at most one tick per 32ms during rapid drag motions
    if (throttle && (now - _lastPlayTimestamp < 32)) {
      return;
    }
    _lastPlayTimestamp = now;

    final clampedFrac = fraction.clamp(0.0, 1.0);
    final frequency = 650.0 + (clampedFrac * 500.0); // 650Hz to 1150Hz pleasant range
    _platform.playTick(frequency: frequency, volume: 0.05);
  }

  /// Plays a discrete step snap tick.
  static void playStepTick({double stepRatio = 0.5}) {
    final frequency = 700.0 + (stepRatio.clamp(0.0, 1.0) * 450.0);
    _platform.playTick(frequency: frequency, volume: 0.07);
  }
}
