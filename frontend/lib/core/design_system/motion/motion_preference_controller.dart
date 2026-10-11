import 'package:flutter/material.dart';
import 'tashil_motion.dart';

/// Official Material Design 3 (M3) Motion Preference Controller.
///
/// Manages the active page transition personality across the Tashil ecosystem:
/// - [TashilPageTransitionType.fadeThrough]: Google M3 Default for top-level navigation.
/// - [TashilPageTransitionType.sharedAxisX]: RTL-aware horizontal slide and fade.
/// - [TashilPageTransitionType.sharedAxisZ]: Depth zoom scale and fade.
class MotionPreferenceController {
  MotionPreferenceController._();

  /// Global reactive notifier for the active transition type.
  static final ValueNotifier<TashilPageTransitionType> currentTransition =
      ValueNotifier<TashilPageTransitionType>(TashilPageTransitionType.fadeThrough);

  /// Sets the preferred transition type.
  static void setTransition(TashilPageTransitionType type) {
    currentTransition.value = type;
  }
}
