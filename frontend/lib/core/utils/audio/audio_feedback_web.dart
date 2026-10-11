import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Web implementation of high-performance zero-latency audio synthesis using Web Audio API.
class AudioFeedbackPlatform {
  web.AudioContext? _audioContext;

  void playTick({double frequency = 800.0, double volume = 0.06}) {
    // 1. Also trigger haptic feedback if supported by browser/device
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    // 2. Synthesize crisp tactile "pip" / "tick" sound via Web Audio Oscillator
    try {
      _audioContext ??= web.AudioContext();
      final ctx = _audioContext!;

      // Resume context if suspended by browser autoplay policy
      if (ctx.state == 'suspended') {
        ctx.resume();
      }

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      // Triangle wave gives a warm, wooden, tactile mechanical click
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(frequency, ctx.currentTime);

      // Fast exponential decay (30ms click duration)
      gain.gain.setValueAtTime(volume, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.030);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start();
      osc.stop(ctx.currentTime + 0.030);
    } catch (_) {
      // Gracefully silent if Web Audio is restricted
    }
  }
}
