library;

/// Material Design 3 Expressive Progress Indicators tokens & type definitions.
/// Conforms to:
/// - https://m3.material.io/components/progress-indicators/overview
/// - https://m3.material.io/components/progress-indicators/specs

/// Shape variant for M3 Progress Indicators.
enum TashilProgressShape {
  /// Standard straight track with rounded pill end caps.
  flat,

  /// Google M3 Expressive sinusoidal undulating wave track.
  wavy,
}

/// Standard size tokens for M3 Circular Progress Indicators:
/// 40dp, 44dp, 48dp (default/standard), 52dp.
enum TashilCircularProgressSize {
  /// Small (40dp): For compact avatar/button badges.
  small(40.0, 3.5),

  /// Medium (44dp): For standard list tiles and cards.
  medium(44.0, 4.0),

  /// Standard (48dp): Default M3 size for forms, dialogs, and sections.
  standard(48.0, 4.0),

  /// Large (52dp): Prominent size for media upload and splash.
  large(52.0, 4.8);

  /// Diameter dimension in dp.
  final double dimension;

  /// Default stroke thickness in dp.
  final double strokeWidth;

  const TashilCircularProgressSize(this.dimension, this.strokeWidth);
}

/// Core Material Design 3 Progress Indicator Constants
class TashilProgressTokens {
  TashilProgressTokens._();

  /// Default track thickness (4dp per Google M3 specs).
  static const double defaultTrackThickness = 4.0;

  /// Stop indicator diameter (4dp circular dot at 100% position).
  static const double stopIndicatorSize = 4.0;

  /// Safety gap separating active indicator from inactive track / stop dot (4dp).
  static const double stopGap = 4.0;

  /// Default directional container inset from edges (4dp per Google M3 specs).
  static const double containerInset = 4.0;

  /// Sinusoidal wave wavelength (distance between two adjacent peaks: 30dp).
  static const double wavelength = 30.0;

  /// Sinusoidal wave amplitude (height of peak from centerline: 5.5dp).
  static const double amplitude = 5.5;
}

