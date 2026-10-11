import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/audio/audio_feedback_service.dart';

/// Handle shape for Tashil Material Design 3 Slider.
enum TashilSliderHandleType {
  /// Official M3 Expressive vertical pill bar (4dp width x 44dp height).
  verticalBar,

  /// Standard round thumb (20dp diameter).
  round,
}

/// Official Google Material Design 3 (M3) Expressive Slider Component.
/// Conforms to:
/// - https://m3.material.io/components/sliders/guidelines
/// - https://m3.material.io/components/sliders/specs
///
/// Features:
/// 1. Expressive 16dp track height with full stadium rounded ends.
/// 2. Signature slim 2dp Stop Gap between active track, handle, and inactive track.
/// 3. M3 Expressive Vertical Bar Handle (4dp width x 26dp height) or Round thumb.
/// 4. Interactive State Layers (Hover 8%, Pressed/Drag 16% circular aura).
/// 5. Animated Floating Value Indicator Balloon with `Curves.easeOutBack` spring motion.
/// 6. Single Stop Indicator dot at the terminal end (smooth continuous surface without dotted noise).
/// 7. 100% Directionality Awareness: Pure RTL for Arabic, LTR for English/Hindi.
/// 8. Tap-to-seek with smooth cubic interpolation and tactile audio feedback ("تن.. تن").
class TashilSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final TashilSliderHandleType handleType;
  final double trackHeight;
  final double gap;
  final double height;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;
  final String Function(double value)? valueLabelFormatter;
  final bool showValueIndicator;
  final bool showDivisionTicks;
  final bool enabled;

  const TashilSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.handleType = TashilSliderHandleType.verticalBar,
    this.trackHeight = 16.0,
    this.gap = 2.0,
    this.height = 40.0,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.valueLabelFormatter,
    this.showValueIndicator = true,
    this.showDivisionTicks = false,
    this.enabled = true,
  }) : assert(min <= max, 'min must be less than or equal to max');

  @override
  State<TashilSlider> createState() => _TashilSliderState();
}

class _TashilSliderState extends State<TashilSlider> with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _indicatorOverlay;

  late AnimationController _balloonAnimController;
  late Animation<double> _balloonScaleAnim;
  late Animation<double> _balloonFadeAnim;

  AnimationController? _tapAnimController;
  Animation<double>? _tapAnim;

  bool _isDragging = false;
  bool _isHovered = false;

  final ValueNotifier<double> _currentValueNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<Offset> _handleGlobalPosNotifier = ValueNotifier<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();
    _currentValueNotifier.value = widget.value;

    _balloonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );

    _balloonScaleAnim = CurvedAnimation(
      parent: _balloonAnimController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _balloonFadeAnim = CurvedAnimation(
      parent: _balloonAnimController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(covariant TashilSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.value != oldWidget.value) {
      _currentValueNotifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _removeIndicatorOverlay();
    _balloonAnimController.dispose();
    _tapAnimController?.dispose();
    _currentValueNotifier.dispose();
    _handleGlobalPosNotifier.dispose();
    super.dispose();
  }

  void _showIndicatorOverlay(BuildContext context) {
    if (!widget.showValueIndicator || !widget.enabled) return;
    if (_indicatorOverlay != null) {
      _balloonAnimController.forward();
      return;
    }

    final overlayState = Overlay.maybeOf(context, rootOverlay: false) ?? Overlay.of(context);

    _indicatorOverlay = OverlayEntry(
      builder: (ctx) {
        return ValueListenableBuilder<Offset>(
          valueListenable: _handleGlobalPosNotifier,
          builder: (context, handlePos, _) {
            return ValueListenableBuilder<double>(
              valueListenable: _currentValueNotifier,
              builder: (context, val, _) {
                final label = widget.valueLabelFormatter != null
                    ? widget.valueLabelFormatter!(val)
                    : (widget.divisions != null ? val.round().toString() : val.toStringAsFixed(1));

                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

                return Positioned(
                  left: handlePos.dx,
                  top: handlePos.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 22.0),
                      child: AnimatedBuilder(
                        animation: _balloonAnimController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _balloonFadeAnim.value,
                            child: Transform.scale(
                              scale: _balloonScaleAnim.value,
                              alignment: Alignment.bottomCenter,
                              child: child,
                            ),
                          );
                        },
                        child: _ValueIndicatorBubble(
                          label: label,
                          backgroundColor: colorScheme.inverseSurface,
                          textColor: colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    overlayState.insert(_indicatorOverlay!);
    _balloonAnimController.forward();
  }

  void _hideIndicatorOverlay() {
    if (_indicatorOverlay == null) return;
    _balloonAnimController.reverse().then((_) {
      if (!_isDragging && !_isHovered) {
        _removeIndicatorOverlay();
      }
    });
  }

  void _removeIndicatorOverlay() {
    _indicatorOverlay?.remove();
    _indicatorOverlay = null;
  }

  double _clampAndSnap(double val) {
    var clamped = val.clamp(widget.min, widget.max);
    if (widget.divisions != null && widget.divisions! > 0) {
      final stepSize = (widget.max - widget.min) / widget.divisions!;
      final steps = ((clamped - widget.min) / stepSize).round();
      clamped = widget.min + steps * stepSize;
    }
    return clamped;
  }

  void _updateValueFromPosition(double localX, double trackWidth, bool isRTL) {
    if (trackWidth <= 0) return;
    double fraction = localX / trackWidth;
    fraction = fraction.clamp(0.0, 1.0);

    // In RTL, 0.0 fraction is on the RIGHT, 1.0 fraction is on the LEFT
    final effectiveFraction = isRTL ? (1.0 - fraction) : fraction;
    final rawVal = widget.min + effectiveFraction * (widget.max - widget.min);
    final finalVal = _clampAndSnap(rawVal);

    if (finalVal != _currentValueNotifier.value) {
      _currentValueNotifier.value = finalVal;
      widget.onChanged?.call(finalVal);
      HapticFeedback.selectionClick();
      final fraction = (widget.max > widget.min)
          ? (finalVal - widget.min) / (widget.max - widget.min)
          : 0.0;
      TashilAudioFeedback.playSliderTick(fraction: fraction);
    }
  }

  void _updateHandlePosition(RenderBox box, double thumbFraction, bool isRTL) {
    final size = box.size;
    final handleWidth = widget.handleType == TashilSliderHandleType.verticalBar ? 3.5 : 20.0;
    final availableWidth = math.max(0.0, size.width - handleWidth);

    final effectiveFraction = isRTL ? (1.0 - thumbFraction) : thumbFraction;
    final thumbX = (handleWidth / 2) + effectiveFraction * availableWidth;
    final thumbY = size.height / 2;

    final globalPos = box.localToGlobal(Offset(thumbX, thumbY));
    _handleGlobalPosNotifier.value = globalPos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final activeColor = widget.activeTrackColor ?? colorScheme.primary;
    final inactiveColor = widget.inactiveTrackColor ?? colorScheme.secondaryContainer;
    final thumbColor = widget.thumbColor ?? colorScheme.primary;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (!widget.enabled) return;
          setState(() => _isHovered = true);
          _showIndicatorOverlay(context);
        },
        onExit: (_) {
          if (!widget.enabled) return;
          setState(() => _isHovered = false);
          if (!_isDragging) _hideIndicatorOverlay();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            if (!widget.enabled) return;
            _tapAnimController?.stop();
            setState(() => _isDragging = true);
            widget.onChangeStart?.call(_currentValueNotifier.value);
            _showIndicatorOverlay(context);

            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              _updateValueFromPosition(details.localPosition.dx, box.size.width, isRTL);
              final fraction = (widget.max > widget.min)
                  ? (_currentValueNotifier.value - widget.min) / (widget.max - widget.min)
                  : 0.0;
              _updateHandlePosition(box, fraction, isRTL);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (!widget.enabled) return;
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              _updateValueFromPosition(details.localPosition.dx, box.size.width, isRTL);
              final fraction = (widget.max > widget.min)
                  ? (_currentValueNotifier.value - widget.min) / (widget.max - widget.min)
                  : 0.0;
              _updateHandlePosition(box, fraction, isRTL);
            }
          },
          onHorizontalDragEnd: (_) {
            if (!widget.enabled) return;
            setState(() => _isDragging = false);
            widget.onChangeEnd?.call(_currentValueNotifier.value);
            if (!_isHovered) _hideIndicatorOverlay();
          },
          onHorizontalDragCancel: () {
            if (!widget.enabled) return;
            setState(() => _isDragging = false);
            if (!_isHovered) _hideIndicatorOverlay();
          },
          onTapDown: (details) {
            if (!widget.enabled) return;
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;

            final targetX = details.localPosition.dx;
            final trackWidth = box.size.width;
            if (trackWidth <= 0) return;

            double fraction = (targetX / trackWidth).clamp(0.0, 1.0);
            final effectiveFraction = isRTL ? (1.0 - fraction) : fraction;
            final targetVal = _clampAndSnap(widget.min + effectiveFraction * (widget.max - widget.min));

            _tapAnimController?.dispose();
            _tapAnimController = AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 160),
            );

            final startVal = _currentValueNotifier.value;
            _tapAnim = Tween<double>(begin: startVal, end: targetVal).animate(
              CurvedAnimation(parent: _tapAnimController!, curve: Curves.easeOutCubic),
            )..addListener(() {
                _currentValueNotifier.value = _tapAnim!.value;
                widget.onChanged?.call(_tapAnim!.value);
                final curFrac = (widget.max > widget.min)
                    ? (_tapAnim!.value - widget.min) / (widget.max - widget.min)
                    : 0.0;
                _updateHandlePosition(box, curFrac, isRTL);
              });

            _showIndicatorOverlay(context);
            _tapAnimController!.forward().then((_) {
              widget.onChangeEnd?.call(_currentValueNotifier.value);
              if (!_isDragging && !_isHovered) _hideIndicatorOverlay();
            });
            HapticFeedback.selectionClick();
            TashilAudioFeedback.playStepTick(stepRatio: fraction);
          },
          child: ValueListenableBuilder<double>(
            valueListenable: _currentValueNotifier,
            builder: (context, currentValue, _) {
              final fraction = (widget.max > widget.min)
                  ? ((currentValue - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0)
                  : 0.0;

              // Schedule handle pos update after frame render
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    _updateHandlePosition(box, fraction, isRTL);
                  }
                }
              });

              return SizedBox(
                height: widget.height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TashilSliderPainter(
                    fraction: fraction,
                    isRTL: isRTL,
                    handleType: widget.handleType,
                    trackHeight: widget.trackHeight,
                    gap: widget.gap,
                    activeTrackColor: activeColor,
                    inactiveTrackColor: inactiveColor,
                    thumbColor: thumbColor,
                    isHovered: _isHovered,
                    isDragging: _isDragging,
                    enabled: widget.enabled,
                    divisions: widget.divisions,
                    showDivisionTicks: widget.showDivisionTicks,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the M3 Expressive Track, slim 2dp Gap, and sleek Vertical Bar Handle.
class _TashilSliderPainter extends CustomPainter {
  final double fraction;
  final bool isRTL;
  final TashilSliderHandleType handleType;
  final double trackHeight;
  final double gap;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;
  final bool isHovered;
  final bool isDragging;
  final bool enabled;
  final int? divisions;
  final bool showDivisionTicks;

  _TashilSliderPainter({
    required this.fraction,
    required this.isRTL,
    required this.handleType,
    required this.trackHeight,
    required this.gap,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.thumbColor,
    required this.isHovered,
    required this.isDragging,
    required this.enabled,
    this.divisions,
    this.showDivisionTicks = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final handleWidth = handleType == TashilSliderHandleType.verticalBar ? 3.5 : 20.0;
    final handleHeight = handleType == TashilSliderHandleType.verticalBar
        ? math.min(trackHeight + 8.0, size.height - 4.0)
        : math.min(20.0, math.max(12.0, size.height - 4.0));
    final handleRadius = handleType == TashilSliderHandleType.verticalBar ? 2.0 : 10.0;

    final availableTrackWidth = math.max(0.0, size.width - handleWidth);
    final effectiveFraction = isRTL ? (1.0 - fraction) : fraction;
    final thumbCenterX = (handleWidth / 2) + effectiveFraction * availableTrackWidth;
    final centerY = size.height / 2;

    final trackRadius = Radius.circular(trackHeight / 2);

    final activePaint = Paint()
      ..color = enabled ? activeTrackColor : activeTrackColor.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = enabled ? inactiveTrackColor : inactiveTrackColor.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;

    final stopDotPaint = Paint()
      ..color = enabled ? activeTrackColor.withValues(alpha: 0.40) : Colors.transparent
      ..style = PaintingStyle.fill;

    final trackTop = centerY - trackHeight / 2;
    final trackBottom = centerY + trackHeight / 2;

    // Calculate Active & Inactive Track Segments with 6dp Gap
    if (!isRTL) {
      // -------------------------------------------------------------------
      // LTR Mode: Active fills from 0 to thumb (left), Inactive from thumb to width (right)
      // -------------------------------------------------------------------
      final activeEnd = thumbCenterX - (handleWidth / 2) - gap;
      final inactiveStart = thumbCenterX + (handleWidth / 2) + gap;

      // Draw Active Track (Left segment)
      if (activeEnd > 0) {
        final activeRect = RRect.fromLTRBAndCorners(
          0.0,
          trackTop,
          activeEnd,
          trackBottom,
          topLeft: trackRadius,
          bottomLeft: trackRadius,
          topRight: Radius.circular(math.min(trackHeight / 2, gap)),
          bottomRight: Radius.circular(math.min(trackHeight / 2, gap)),
        );
        canvas.drawRRect(activeRect, activePaint);
      }

      // Draw Inactive Track (Right segment)
      if (inactiveStart < size.width) {
        final inactiveRect = RRect.fromLTRBAndCorners(
          inactiveStart,
          trackTop,
          size.width,
          trackBottom,
          topLeft: Radius.circular(math.min(trackHeight / 2, gap)),
          bottomLeft: Radius.circular(math.min(trackHeight / 2, gap)),
          topRight: trackRadius,
          bottomRight: trackRadius,
        );
        canvas.drawRRect(inactiveRect, inactivePaint);

        // M3 End Stop Indicator Dot (on right end of inactive track)
        final stopDotX = size.width - (trackHeight / 2);
        if (stopDotX > inactiveStart + 4) {
          canvas.drawCircle(Offset(stopDotX, centerY), 2.0, stopDotPaint);
        }
      }
    } else {
      // -------------------------------------------------------------------
      // RTL Mode: Active fills from thumb to width (right), Inactive from 0 to thumb (left)
      // -------------------------------------------------------------------
      final inactiveEnd = thumbCenterX - (handleWidth / 2) - gap;
      final activeStart = thumbCenterX + (handleWidth / 2) + gap;

      // Draw Inactive Track (Left segment in RTL)
      if (inactiveEnd > 0) {
        final inactiveRect = RRect.fromLTRBAndCorners(
          0.0,
          trackTop,
          inactiveEnd,
          trackBottom,
          topLeft: trackRadius,
          bottomLeft: trackRadius,
          topRight: Radius.circular(math.min(trackHeight / 2, gap)),
          bottomRight: Radius.circular(math.min(trackHeight / 2, gap)),
        );
        canvas.drawRRect(inactiveRect, inactivePaint);

        // M3 End Stop Indicator Dot (on left end of inactive track in RTL)
        final stopDotX = trackHeight / 2;
        if (stopDotX < inactiveEnd - 4) {
          canvas.drawCircle(Offset(stopDotX, centerY), 2.0, stopDotPaint);
        }
      }

      // Draw Active Track (Right segment in RTL)
      if (activeStart < size.width) {
        final activeRect = RRect.fromLTRBAndCorners(
          activeStart,
          trackTop,
          size.width,
          trackBottom,
          topLeft: Radius.circular(math.min(trackHeight / 2, gap)),
          bottomLeft: Radius.circular(math.min(trackHeight / 2, gap)),
          topRight: trackRadius,
          bottomRight: trackRadius,
        );
        canvas.drawRRect(activeRect, activePaint);
      }
    }

    // Draw Discrete division tick dots if explicitly specified
    if (showDivisionTicks && divisions != null && divisions! > 1) {
      final tickPaint = Paint()
        ..color = activeTrackColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;

      for (int i = 1; i < divisions!; i++) {
        final tickFrac = i / divisions!;
        final tickEffective = isRTL ? (1.0 - tickFrac) : tickFrac;
        final tickX = (handleWidth / 2) + tickEffective * availableTrackWidth;

        // Only draw tick mark if it's not inside the handle gap
        if ((tickX - thumbCenterX).abs() > (handleWidth / 2 + gap)) {
          canvas.drawCircle(Offset(tickX, centerY), 1.5, tickPaint);
        }
      }
    }

    // Draw State Layer Aura (Hover 40dp / Pressed 44dp)
    if (enabled && (isDragging || isHovered)) {
      final auraSize = isDragging ? math.min(44.0, size.height) : math.min(40.0, size.height * 0.9);
      final auraOpacity = isDragging ? 0.16 : 0.08;
      final auraPaint = Paint()
        ..color = thumbColor.withValues(alpha: auraOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(thumbCenterX, centerY), width: auraSize, height: auraSize),
          Radius.circular(auraSize / 2),
        ),
        auraPaint,
      );
    }

    // Draw M3 Handle (Vertical Bar or Round)
    final handlePaint = Paint()
      ..color = enabled ? thumbColor : thumbColor.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;

    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(thumbCenterX, centerY),
        width: handleWidth,
        height: handleHeight,
      ),
      Radius.circular(handleRadius),
    );

    // Subtle drop shadow for the handle in active mode
    if (enabled) {
      canvas.drawRRect(
        handleRect.shift(const Offset(0, 1.5)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }

    canvas.drawRRect(handleRect, handlePaint);
  }

  @override
  bool shouldRepaint(covariant _TashilSliderPainter oldDelegate) {
    return fraction != oldDelegate.fraction ||
        isRTL != oldDelegate.isRTL ||
        isHovered != oldDelegate.isHovered ||
        isDragging != oldDelegate.isDragging ||
        enabled != oldDelegate.enabled ||
        gap != oldDelegate.gap ||
        trackHeight != oldDelegate.trackHeight ||
        showDivisionTicks != oldDelegate.showDivisionTicks ||
        activeTrackColor != oldDelegate.activeTrackColor ||
        inactiveTrackColor != oldDelegate.inactiveTrackColor ||
        thumbColor != oldDelegate.thumbColor;
  }
}

/// Floating Value Indicator Balloon with pointer tip.
class _ValueIndicatorBubble extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _ValueIndicatorBubble({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(color: backgroundColor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(bottom: 6), // space for the bottom pointer
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Custom painter for the balloon background with a bottom triangle tip.
class _BubblePainter extends CustomPainter {
  final Color color;

  _BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    const radius = 16.0;
    const tipHeight = 5.0;
    const tipWidth = 10.0;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - tipHeight),
      const Radius.circular(radius),
    );

    final path = Path()..addRRect(bodyRect);

    // Add pointer triangle at bottom center
    final centerX = size.width / 2;
    final bottomY = size.height - tipHeight;

    path.moveTo(centerX - tipWidth / 2, bottomY);
    path.lineTo(centerX, size.height);
    path.lineTo(centerX + tipWidth / 2, bottomY);
    path.close();

    // Draw shadow
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    // Draw bubble body
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => color != oldDelegate.color;
}
