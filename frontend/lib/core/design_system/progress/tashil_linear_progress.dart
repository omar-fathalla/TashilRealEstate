import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tashil_progress_types.dart';

/// Official Google Material Design 3 Expressive Linear Progress Indicator.
///
/// Conforms to:
/// - https://m3.material.io/components/progress-indicators/overview
/// - https://m3.material.io/components/progress-indicators/specs
///
/// Features:
/// 1. Dual Shapes: [TashilProgressShape.flat] and [TashilProgressShape.wavy].
/// 2. Determinate (progress 0.0 to 1.0) and Indeterminate (continuous wave/motion).
/// 3. Official M3 Stop Indicator (4dp circular dot at 100% boundary).
/// 4. Official M3 Stop Gap (4dp gap between active progress and inactive track).
/// 5. 100% RTL and LTR Directionality aware.
/// 6. Configurable track thickness (default 4dp) and optional 4dp container insets.
class TashilLinearProgressIndicator extends StatefulWidget {
  /// Progress value between 0.0 and 1.0. If null, renders in indeterminate mode.
  final double? value;

  /// Shape of the progress track: [TashilProgressShape.flat] or [TashilProgressShape.wavy].
  final TashilProgressShape shape;

  /// Track thickness in dp. Defaults to [TashilProgressTokens.defaultTrackThickness] (4dp).
  final double thickness;

  /// Color of the active indicator. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Color of the inactive track. Defaults to [ColorScheme.secondaryContainer].
  final Color? trackColor;

  /// Color of the stop indicator dot. Defaults to [color] or [ColorScheme.primary].
  final Color? stopIndicatorColor;

  /// Whether to show the 4dp destination stop dot at the end of the track. Defaults to true.
  final bool showStopIndicator;

  /// Whether to apply the M3 4dp directional edge inset from the container/screen. Defaults to true.
  final bool useContainerInset;

  /// Semantic label for accessibility.
  final String? semanticsLabel;

  /// Semantic value for accessibility.
  final String? semanticsValue;

  const TashilLinearProgressIndicator({
    super.key,
    this.value,
    this.shape = TashilProgressShape.wavy,
    this.thickness = TashilProgressTokens.defaultTrackThickness,
    this.color,
    this.trackColor,
    this.stopIndicatorColor,
    this.showStopIndicator = true,
    this.useContainerInset = true,
    this.semanticsLabel,
    this.semanticsValue,
  });

  /// Convenience constructor for standard flat M3 linear progress.
  const TashilLinearProgressIndicator.flat({
    super.key,
    this.value,
    this.thickness = TashilProgressTokens.defaultTrackThickness,
    this.color,
    this.trackColor,
    this.stopIndicatorColor,
    this.showStopIndicator = true,
    this.useContainerInset = true,
    this.semanticsLabel,
    this.semanticsValue,
  }) : shape = TashilProgressShape.flat;

  /// Convenience constructor for M3 Expressive wavy linear progress.
  const TashilLinearProgressIndicator.wavy({
    super.key,
    this.value,
    this.thickness = TashilProgressTokens.defaultTrackThickness,
    this.color,
    this.trackColor,
    this.stopIndicatorColor,
    this.showStopIndicator = true,
    this.useContainerInset = true,
    this.semanticsLabel,
    this.semanticsValue,
  }) : shape = TashilProgressShape.wavy;

  @override
  State<TashilLinearProgressIndicator> createState() => _TashilLinearProgressIndicatorState();
}

class _TashilLinearProgressIndicatorState extends State<TashilLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.value == null) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TashilLinearProgressIndicator oldWidget) {
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final effectiveColor = widget.color ?? colorScheme.primary;
    final effectiveTrackColor = widget.trackColor ?? colorScheme.secondaryContainer;
    final effectiveStopColor = widget.stopIndicatorColor ?? effectiveColor;

    final containerHeight = widget.shape == TashilProgressShape.wavy
        ? math.max(16.0, widget.thickness + 2 * TashilProgressTokens.amplitude + 4.0)
        : math.max(widget.thickness, 4.0);

    Widget indicator = AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(double.infinity, containerHeight),
          painter: _LinearProgressPainter(
            value: widget.value,
            animationProgress: _animController.value,
            shape: widget.shape,
            thickness: widget.thickness,
            color: effectiveColor,
            trackColor: effectiveTrackColor,
            stopIndicatorColor: effectiveStopColor,
            showStopIndicator: widget.showStopIndicator,
            isRtl: isRtl,
          ),
        );
      },
    );

    if (widget.useContainerInset) {
      indicator = Padding(
        padding: const EdgeInsets.symmetric(horizontal: TashilProgressTokens.containerInset),
        child: indicator,
      );
    }

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue ?? (widget.value != null ? '${(widget.value! * 100).round()}%' : null),
      child: indicator,
    );
  }
}

class _LinearProgressPainter extends CustomPainter {
  final double? value;
  final double animationProgress;
  final TashilProgressShape shape;
  final double thickness;
  final Color color;
  final Color trackColor;
  final Color stopIndicatorColor;
  final bool showStopIndicator;
  final bool isRtl;

  _LinearProgressPainter({
    required this.value,
    required this.animationProgress,
    required this.shape,
    required this.thickness,
    required this.color,
    required this.trackColor,
    required this.stopIndicatorColor,
    required this.showStopIndicator,
    required this.isRtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final totalWidth = size.width;
    if (totalWidth <= 0) return;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stopDotPaint = Paint()
      ..color = stopIndicatorColor
      ..style = PaintingStyle.fill;

    // The start position in physical canvas coordinates
    final double startX = isRtl ? totalWidth : 0.0;

    // Draw Stop Indicator Dot (at 100% position)
    final double stopDotRadius = TashilProgressTokens.stopIndicatorSize / 2;
    final double stopDotCenterX = isRtl ? stopDotRadius : totalWidth - stopDotRadius;

    // Remaining available length for track excluding stop dot and gap
    final double stopOffset = showStopIndicator ? (TashilProgressTokens.stopIndicatorSize + TashilProgressTokens.stopGap) : 0.0;
    final double usableWidth = math.max(0.0, totalWidth - stopOffset);

    // --- INDETERMINATE MODE ---
    if (value == null) {
      if (shape == TashilProgressShape.flat) {
        // Standard M3 flat sliding pulse
        canvas.drawLine(
          Offset(isRtl ? stopOffset : 0, centerY),
          Offset(isRtl ? totalWidth : usableWidth, centerY),
          trackPaint,
        );

        if (showStopIndicator) {
          canvas.drawCircle(Offset(stopDotCenterX, centerY), stopDotRadius, stopDotPaint);
        }

        final headRatio = (animationProgress * 1.5).clamp(0.0, 1.0);
        final tailRatio = ((animationProgress * 1.5) - 0.5).clamp(0.0, 1.0);

        final activeStartX = isRtl ? (totalWidth - tailRatio * usableWidth) : (tailRatio * usableWidth);
        final activeEndX = isRtl ? (totalWidth - headRatio * usableWidth) : (headRatio * usableWidth);

        if ((activeEndX - activeStartX).abs() > 2) {
          canvas.drawLine(Offset(activeStartX, centerY), Offset(activeEndX, centerY), activePaint);
        }
      } else {
        // M3 Expressive Wavy Indeterminate:
        // A single, continuous line spanning the entire width in activePaint (primary color),
        // with a calm sinusoidal wave packet rippling through it smoothly.
        // No secondary faded line behind it, no cutoff, perfectly solid line from start to finish.
        final double lineLength = usableWidth;
        final double packetWidth = math.min(100.0, lineLength * 0.42);

        // Eased progress for natural, calm physical acceleration and deceleration
        final double progress = animationProgress;
        final double eased = Curves.easeInOutCubic.transform(progress);
        final double packetCenter = (eased * (lineLength + packetWidth * 1.6)) - (packetWidth * 0.8);
        final double wavelength = TashilProgressTokens.wavelength;
        final double amplitude = TashilProgressTokens.amplitude;
        final double phase = progress * 3 * math.pi;

        final wavePath = Path();
        bool started = false;
        const double step = 1.5;

        for (double d = 0; d <= lineLength; d += step) {
          final dist = (d - packetCenter).abs();
          double currentAmp = 0.0;
          if (dist < packetWidth / 2) {
            // Raised-cosine bell envelope for seamless transition into the solid line
            final envelope = 0.5 * (1.0 + math.cos(2 * math.pi * dist / packetWidth));
            currentAmp = amplitude * envelope;
          }

          final x = isRtl ? (totalWidth - d) : d;
          final y = centerY + (currentAmp == 0.0 ? 0.0 : currentAmp * math.sin(((d - packetCenter) / wavelength) * 2 * math.pi - phase));

          if (!started) {
            wavePath.moveTo(x, y);
            started = true;
          } else {
            wavePath.lineTo(x, y);
          }
        }

        // Ensure path reaches the exact end of the line
        final finalX = isRtl ? (totalWidth - lineLength) : lineLength;
        wavePath.lineTo(finalX, centerY);

        canvas.drawPath(wavePath, activePaint);
      }
      return;
    }

    // --- DETERMINATE MODE ---
    final double clampedVal = value!.clamp(0.0, 1.0);
    final double activeLength = clampedVal * usableWidth;

    // 1. Draw Inactive Track
    final double trackStartDist = activeLength + (clampedVal > 0 && clampedVal < 1.0 ? TashilProgressTokens.stopGap : 0.0);
    if (trackStartDist < usableWidth) {
      final double inactiveStartX = isRtl ? (totalWidth - trackStartDist) : trackStartDist;
      final double inactiveEndX = isRtl ? (totalWidth - usableWidth) : usableWidth;
      if ((inactiveEndX - inactiveStartX).abs() > 1.0) {
        canvas.drawLine(Offset(inactiveStartX, centerY), Offset(inactiveEndX, centerY), trackPaint);
      }
    }

    // 2. Draw Stop Indicator Dot (if not fully reached)
    if (showStopIndicator) {
      canvas.drawCircle(Offset(stopDotCenterX, centerY), stopDotRadius, stopDotPaint);
    }

    // 3. Draw Active Indicator
    if (activeLength <= 0.0) return;

    if (shape == TashilProgressShape.flat) {
      final double activeEndX = isRtl ? (totalWidth - activeLength) : activeLength;
      canvas.drawLine(Offset(startX, centerY), Offset(activeEndX, centerY), activePaint);
    } else {
      // M3 Expressive Wavy Determinate
      final wavePath = Path();
      final double wavelength = TashilProgressTokens.wavelength;
      final double amplitude = TashilProgressTokens.amplitude;

      bool started = false;
      const double step = 2.0;

      for (double d = 0; d <= activeLength; d += step) {
        // Taper down amplitude at the very tip for a clean finish
        final tipDistance = activeLength - d;
        final tipTaper = (tipDistance / 8.0).clamp(0.0, 1.0);
        final currentAmp = amplitude * tipTaper;

        final x = isRtl ? (totalWidth - d) : d;
        final y = centerY + currentAmp * math.sin(2 * math.pi * d / wavelength);

        if (!started) {
          wavePath.moveTo(x, y);
          started = true;
        } else {
          wavePath.lineTo(x, y);
        }
      }

      // Ensure tip ends at activeLength
      final finalX = isRtl ? (totalWidth - activeLength) : activeLength;
      wavePath.lineTo(finalX, centerY);

      canvas.drawPath(wavePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinearProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.shape != shape ||
        oldDelegate.thickness != thickness ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.stopIndicatorColor != stopIndicatorColor ||
        oldDelegate.showStopIndicator != showStopIndicator ||
        oldDelegate.isRtl != isRtl;
  }
}
