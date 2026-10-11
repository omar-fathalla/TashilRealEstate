import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Predefined standard size tokens for M3 Loading Indicators:
/// https://m3.material.io/components/loading-indicator/specs
enum TashilLoadingSize {
  /// Small (24dp): Ideal for buttons, assist chips, and inline list items.
  small(24.0),

  /// Medium (48dp): Standard M3 size for cards, modal dialogs, and pull-to-refresh.
  medium(48.0),

  /// Large (72dp): Prominent size for full-page loading, splash, and AI processing.
  large(72.0);

  final double dimension;
  const TashilLoadingSize(this.dimension);
}

/// Official Google Material Design 3 Expressive Loading Indicator Component.
///
/// Implements the M3 Expressive update:
/// - https://m3.material.io/components/loading-indicator/overview
/// - https://m3.material.io/components/loading-indicator/specs
/// - https://m3.material.io/components/loading-indicator/guidelines
///
/// Features:
/// 1. Replaces legacy indeterminate circular progress rings with an expressive,
///    organic morphing shape (Circle -> Squircle -> 4-petal Clover -> Rhombus).
/// 2. Smooth rotation and breathing scale motion physics.
/// 3. Strict M3 size hierarchy: Small (24dp), Medium (48dp), Large (72dp).
/// 4. Optional floating container variant with M3 Level 2 elevation (Pull-to-refresh).
class TashilLoadingIndicator extends StatefulWidget {
  /// Dimension of the loading indicator in dp.
  final double size;

  /// Primary color of the morphing shape. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Secondary color accent for multi-color morphing (optional).
  final Color? accentColor;

  /// Whether to embed the indicator inside a floating M3 elevated container.
  final bool hasContainer;

  /// Container background color if [hasContainer] is true.
  final Color? containerColor;

  /// Elevation of the container if [hasContainer] is true.
  final double containerElevation;

  /// Optional semantic label for accessibility / screen readers.
  final String? semanticLabel;

  const TashilLoadingIndicator({
    super.key,
    this.size = 48.0,
    this.color,
    this.accentColor,
    this.hasContainer = false,
    this.containerColor,
    this.containerElevation = 2.0,
    this.semanticLabel,
  });

  /// Small variant (24dp) - For buttons, chips, and compact controls.
  const TashilLoadingIndicator.small({
    super.key,
    this.color,
    this.accentColor,
    this.hasContainer = false,
    this.containerColor,
    this.containerElevation = 2.0,
    this.semanticLabel,
  }) : size = 24.0;

  /// Medium variant (48dp) - Standard M3 size for cards, sections, and dialogs.
  const TashilLoadingIndicator.medium({
    super.key,
    this.color,
    this.accentColor,
    this.hasContainer = false,
    this.containerColor,
    this.containerElevation = 2.0,
    this.semanticLabel,
  }) : size = 48.0;

  /// Large variant (72dp) - For page-level hydration and AI reasoning tasks.
  const TashilLoadingIndicator.large({
    super.key,
    this.color,
    this.accentColor,
    this.hasContainer = false,
    this.containerColor,
    this.containerElevation = 2.0,
    this.semanticLabel,
  }) : size = 72.0;

  /// Centered full-page loader with an optional localized supporting message.
  static Widget fullPage({
    Key? key,
    String? message,
    Color? color,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TashilLoadingIndicator.large(color: color),
            if (message != null) ...[
              const SizedBox(height: 20.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  State<TashilLoadingIndicator> createState() => _TashilLoadingIndicatorState();
}

class _TashilLoadingIndicatorState extends State<TashilLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous 2200ms morphing cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = widget.color ?? colorScheme.primary;
    final effectiveAccent = widget.accentColor ?? colorScheme.secondary;

    final indicatorCore = Semantics(
      label: widget.semanticLabel ?? 'Loading',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // Smooth rotation
            final angle = t * 2 * math.pi;
            // Gentle breathing scale: 0.94 -> 1.06
            final pulseScale = 1.0 + 0.06 * math.sin(t * 4 * math.pi);

            return Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: pulseScale,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _M3ExpressiveMorphPainter(
                    progress: t,
                    color: effectiveColor,
                    accentColor: effectiveAccent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (!widget.hasContainer) {
      return indicatorCore;
    }

    // Container variant (Pull-to-refresh / floating indicator pill)
    final containerSize = widget.size + (widget.size < 40 ? 16.0 : 24.0);
    return Material(
      elevation: widget.containerElevation,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      color: widget.containerColor ?? colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(containerSize / 2),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Container(
        width: containerSize,
        height: containerSize,
        alignment: Alignment.center,
        child: indicatorCore,
      ),
    );
  }
}

/// Precise CustomPainter rendering the M3 Expressive Morphing Organic Geometry.
///
/// Morphs continuously across 4 key geometric states:
/// 1. Circle / Rounded Pill ($t = 0.00$)
/// 2. Squircle / Superellipse ($t = 0.25$)
/// 3. 4-Petal Clover / Flower with rounded lobes ($t = 0.50$)
/// 4. Convex Rounded Rhombus ($t = 0.75$)
class _M3ExpressiveMorphPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accentColor;

  _M3ExpressiveMorphPainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.46;

    // Modulate clover amplitude: 0.0 (circle) -> 0.22 (4-lobed clover) -> 0.08 (squircle)
    final amplitude = 0.16 * math.sin(progress * 2 * math.pi).abs() +
        0.06 * math.cos(progress * 4 * math.pi).abs();

    final path = Path();
    const pointCount = 120; // High fidelity curve approximation

    for (int i = 0; i <= pointCount; i++) {
      final theta = (i / pointCount) * 2 * math.pi;

      // 4-fold harmonic modulation equation
      final r = maxRadius * (1.0 - amplitude * math.cos(4 * theta));

      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill with rich M3 primary tone
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);

    // Dynamic subtle organic center highlight (matching M3 tonal palette)
    final innerRadius = maxRadius * (0.24 + 0.06 * math.sin(progress * 4 * math.pi));
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accentColor.withValues(alpha: 0.35)
      ..isAntiAlias = true;

    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _M3ExpressiveMorphPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor;
  }
}
