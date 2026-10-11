import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tashil_progress_types.dart';

/// Official Google Material Design 3 Expressive Circular Progress Indicator.
///
/// Conforms to:
/// - https://m3.material.io/components/progress-indicators/overview
/// - https://m3.material.io/components/progress-indicators/specs
///
/// Features:
/// 1. Dual Shapes: [TashilProgressShape.flat] and [TashilProgressShape.wavy].
/// 2. Determinate (0.0 to 1.0) and Indeterminate (continuous rotation).
/// 3. Official M3 Sizes: Small (40dp), Medium (44dp), Standard (48dp), Large (52dp).
/// 4. Official M3 Stop Indicator (4dp circular dot at 100% position).
/// 5. Directionality and accessibility aware.
class TashilCircularProgressIndicator extends StatefulWidget {
  /// Progress value between 0.0 and 1.0. If null, renders in indeterminate mode.
  final double? value;

  /// Shape of the active indicator: [TashilProgressShape.flat] or [TashilProgressShape.wavy].
  final TashilProgressShape shape;

  /// Size token for predefined M3 dimensions (40, 44, 48, 52dp).
  final TashilCircularProgressSize sizeToken;

  /// Explicit custom diameter in dp. Overrides [sizeToken] if specified.
  final double? size;

  /// Stroke width in dp. Defaults to token stroke width.
  final double? strokeWidth;

  /// Active indicator color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Inactive track ring color. Defaults to [ColorScheme.secondaryContainer].
  final Color? trackColor;

  /// Stop indicator dot color. Defaults to [color] or [ColorScheme.primary].
  final Color? stopIndicatorColor;

  /// Whether to show the 4dp destination stop dot. Defaults to true.
  final bool showStopIndicator;

  /// Semantic label for accessibility.
  final String? semanticsLabel;

  /// Semantic value for accessibility.
  final String? semanticsValue;

  const TashilCircularProgressIndicator({
    super.key,
    this.value,
    this.shape = TashilProgressShape.wavy,
    this.sizeToken = TashilCircularProgressSize.standard,
    this.size,
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.stopIndicatorColor,
    this.showStopIndicator = true,
    this.semanticsLabel,
    this.semanticsValue,
  });

  /// Convenience constructor for small 40dp circular progress indicator.
  const TashilCircularProgressIndicator.small({
    super.key,
    this.value,
    this.shape = TashilProgressShape.wavy,
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.stopIndicatorColor,
    this.showStopIndicator = true,
    this.semanticsLabel,
    this.semanticsValue,
  })  : sizeToken = TashilCircularProgressSize.small,
        size = 40.0;

  /// Convenience constructor for standard 48dp circular progress indicator.
  const TashilCircularProgressIndicator.standard({
    super.key,
    this.value,
    this.shape = TashilProgressShape.wavy,
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.stopIndicatorColor,
    this.showStopIndicator = true,
    this.semanticsLabel,
    this.semanticsValue,
  })  : sizeToken = TashilCircularProgressSize.standard,
        size = 48.0;

  /// Convenience constructor for flat circular progress indicator.
  const TashilCircularProgressIndicator.flat({
    super.key,
    this.value,
    this.sizeToken = TashilCircularProgressSize.standard,
    this.size,
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.stopIndicatorColor,
    this.showStopIndicator = true,
    this.semanticsLabel,
    this.semanticsValue,
  }) : shape = TashilProgressShape.flat;

  @override
  State<TashilCircularProgressIndicator> createState() => _TashilCircularProgressIndicatorState();
}

class _TashilCircularProgressIndicatorState extends State<TashilCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.value == null) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TashilCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_animController.isAnimating) {
      _animController.repeat();
    } else if (widget.value != null && _animController.isAnimating) {
      _animController.stop();
    }
  }

  bool get isIndeterminate => widget.value == null;

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dimension = widget.size ?? widget.sizeToken.dimension;
    final stroke = widget.strokeWidth ?? widget.sizeToken.strokeWidth;

    final effectiveColor = widget.color ?? colorScheme.primary;
    final effectiveTrackColor = widget.trackColor ?? colorScheme.secondaryContainer;
    final effectiveStopColor = widget.stopIndicatorColor ?? effectiveColor;

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue ?? (widget.value != null ? '${(widget.value! * 100).round()}%' : null),
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              size: Size(dimension, dimension),
              painter: _CircularProgressPainter(
                value: widget.value,
                animationProgress: _animController.value,
                shape: widget.shape,
                strokeWidth: stroke,
                color: effectiveColor,
                trackColor: effectiveTrackColor,
                stopIndicatorColor: effectiveStopColor,
                showStopIndicator: widget.showStopIndicator,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double? value;
  final double animationProgress;
  final TashilProgressShape shape;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Color stopIndicatorColor;
  final bool showStopIndicator;

  _CircularProgressPainter({
    required this.value,
    required this.animationProgress,
    required this.shape,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    required this.stopIndicatorColor,
    required this.showStopIndicator,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxWaveExtra = shape == TashilProgressShape.wavy ? 2.5 : 0.0;
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2) - maxWaveExtra;
    if (radius <= 0) return;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stopDotPaint = Paint()
      ..color = stopIndicatorColor
      ..style = PaintingStyle.fill;

    const startAngle = -math.pi / 2; // 12 o'clock start position

    // 1. Draw Background Inactive Circular Track
    canvas.drawCircle(center, radius, trackPaint);

    // Stop Indicator Dot at 12 o'clock position
    final double stopDotRadius = TashilProgressTokens.stopIndicatorSize / 2;
    final stopDotOffset = Offset(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );

    // --- INDETERMINATE MODE ---
    if (value == null) {
      if (showStopIndicator) {
        canvas.drawCircle(stopDotOffset, stopDotRadius, stopDotPaint);
      }

      final rotation = animationProgress * 2 * math.pi;
      final sweepAngle = (0.3 + 0.45 * math.sin(animationProgress * math.pi)).clamp(0.2, 0.8) * 2 * math.pi;

      if (shape == TashilProgressShape.flat) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + rotation,
          sweepAngle,
          false,
          activePaint,
        );
      } else {
        // M3 Expressive Wavy Circular Indeterminate
        final wavePath = Path();
        const int waveSegments = 8; // Number of undulating crests around circle
        final currentStart = startAngle + rotation;
        final currentEnd = currentStart + sweepAngle;
        const double step = 0.05;

        bool started = false;
        for (double a = currentStart; a <= currentEnd; a += step) {
          final r = radius + 2.2 * math.sin(waveSegments * (a - rotation));
          final x = center.dx + r * math.cos(a);
          final y = center.dy + r * math.sin(a);
          if (!started) {
            wavePath.moveTo(x, y);
            started = true;
          } else {
            wavePath.lineTo(x, y);
          }
        }
        canvas.drawPath(wavePath, activePaint);
      }
      return;
    }

    // --- DETERMINATE MODE ---
    final double clampedVal = value!.clamp(0.0, 1.0);

    // Draw Stop Indicator Dot if not 100% complete
    if (showStopIndicator && clampedVal < 0.98) {
      canvas.drawCircle(stopDotOffset, stopDotRadius, stopDotPaint);
    }

    if (clampedVal <= 0.0) return;

    final sweepAngle = clampedVal * 2 * math.pi;

    if (shape == TashilProgressShape.flat) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    } else {
      // M3 Expressive Wavy Circular Determinate
      final wavePath = Path();
      const int waveSegments = 8;
      final currentEnd = startAngle + sweepAngle;
      const double step = 0.05;

      bool started = false;
      for (double a = startAngle; a <= currentEnd; a += step) {
        // Smoothly taper amplitude at start and tip
        final progressRatio = (a - startAngle) / sweepAngle;
        final edgeTaper = math.sin(progressRatio * math.pi).clamp(0.0, 1.0);
        final r = radius + 2.2 * edgeTaper * math.sin(waveSegments * (a - startAngle));
        final x = center.dx + r * math.cos(a);
        final y = center.dy + r * math.sin(a);

        if (!started) {
          wavePath.moveTo(x, y);
          started = true;
        } else {
          wavePath.lineTo(x, y);
        }
      }
      canvas.drawPath(wavePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.shape != shape ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.stopIndicatorColor != stopIndicatorColor ||
        oldDelegate.showStopIndicator != showStopIndicator;
  }
}
