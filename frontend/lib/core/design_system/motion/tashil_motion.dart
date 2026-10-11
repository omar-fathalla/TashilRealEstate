import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

export 'm3_motion_showcase_dialog.dart';
export 'tashil_card_filter_motion.dart';
export 'motion_preference_controller.dart';


/// Official Google Material Design 3 (M3) Easing Curves.
///
/// Conforms strictly to:
/// - https://m3.material.io/styles/motion/easing-and-duration/tokens-specs
/// - https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration
class TashilMotionEasing {
  TashilMotionEasing._();

  // --------------------------------------------------------------------------
  // Emphasized Family (Signature M3 Expressive Curves)
  // --------------------------------------------------------------------------

  /// Signature M3 Emphasized curve for elements that **begin and end on screen**.
  /// Spec: `cubic-bezier(0.2, 0.0, 0.0, 1.0)`
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Emphasized Decelerate curve for elements that **enter the screen** (dialogs, sheets, menus).
  /// Starts at peak velocity and gracefully decelerates.
  /// Spec: `cubic-bezier(0.05, 0.7, 0.1, 1.0)`
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized Accelerate curve for elements that **exit the screen** (dismissal, closing).
  /// Starts slowly and accelerates rapidly out of view.
  /// Spec: `cubic-bezier(0.3, 0.0, 0.8, 0.15)`
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  // --------------------------------------------------------------------------
  // Standard Family (Functional & Utility Curves)
  // --------------------------------------------------------------------------

  /// Standard curve for on-screen utility transitions and micro-interactions.
  /// Spec: `cubic-bezier(0.2, 0.0, 0.0, 1.0)`
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Standard Decelerate curve for small elements entering screen bounds (e.g. tooltips).
  /// Spec: `cubic-bezier(0.0, 0.0, 0.2, 1.0)`
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Standard Accelerate curve for small elements exiting screen bounds.
  /// Spec: `cubic-bezier(0.4, 0.0, 1.0, 1.0)`
  static const Curve standardAccelerate = Cubic(0.4, 0.0, 1.0, 1.0);

  // --------------------------------------------------------------------------
  // Linear (Restricted)
  // --------------------------------------------------------------------------

  /// Linear curve reserved strictly for infinite spinning progress indicators.
  /// Never use for spatial motion or sizing.
  static const Curve linear = Curves.linear;
}

/// Official Google Material Design 3 (M3) Duration Tokens.
///
/// 16 distinct tokens organized into 4 semantic tiers.
/// Conforms strictly to:
/// - https://m3.material.io/styles/motion/easing-and-duration/tokens-specs
class TashilMotionDuration {
  TashilMotionDuration._();

  // Short Tier (Micro-interactions & Fast Exits)
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);

  // Medium Tier (Small Surfaces & Standard Entrances)
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);

  // Long Tier (Hero Transitions & Large Surfaces)
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);

  // Extra-Long Tier (Onboarding & Complex Brand Moments)
  static const Duration extraLong1 = Duration(milliseconds: 700);
  static const Duration extraLong2 = Duration(milliseconds: 800);
  static const Duration extraLong3 = Duration(milliseconds: 900);
  static const Duration extraLong4 = Duration(milliseconds: 1000);
}

/// Official Google Material Design 3 (M3) Motion Physics Springs.
///
/// Implements interruptible, gesture-aware spring dynamics based on mass, stiffness,
/// and damping ratio (\zeta).
/// Conforms strictly to:
/// - https://m3.material.io/styles/motion/overview/specs (Motion physics system)
class TashilMotionSpring {
  TashilMotionSpring._();

  /// Standard critically damped spring (\zeta = 1.0).
  /// Reaches target position quickly without any overshoot or oscillation.
  static const SpringDescription standard = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 34.64, // 2 * sqrt(1.0 * 300.0) -> zeta = 1.0
  );

  /// Alias for standard critically damped spring.
  static const SpringDescription criticallyDamped = standard;

  /// Expressive underdamped spring (\zeta \approx 0.76).
  /// Features a controlled, delightful overshoot for tactile feedback on gestures and presses.
  static const SpringDescription expressiveBouncy = SpringDescription(
    mass: 1.0,
    stiffness: 320.0,
    damping: 27.15, // zeta = 27.15 / (2 * sqrt(320)) approx 0.76
  );

  /// Gentle critically damped spring (\zeta = 1.0).
  /// Softer stiffness for relaxed, spacious transitions.
  static const SpringDescription gentle = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 26.83, // 2 * sqrt(1.0 * 180.0) -> zeta = 1.0
  );
}

/// Official Google Material Design 3 (M3) Web & Cross-Platform Spring-to-Curve Conversions.
///
/// Converts physics spring tokens (mass, stiffness, damping) into precise cubic-bezier curves
/// and standard durations for high-performance cross-platform web rendering.
/// Conforms strictly to:
/// - https://m3.material.io/styles/motion/overview/specs (Web: Convert springs to curves)
class TashilMotionWebCurves {
  TashilMotionWebCurves._();

  // --------------------------------------------------------------------------
  // Spatial Spring Conversions (Movement in space, resize, expanding containers)
  // --------------------------------------------------------------------------

  /// Expressive fast spatial spring conversion:
  /// Curve: `cubic-bezier(0.14, 1.41, 0.71, 0.99)`, Duration: 264ms
  /// Features a controlled tactile bounce for card hovers, quick snaps, and responsive gestures.
  static const Curve expressiveFastSpatial = Cubic(0.14, 1.41, 0.71, 0.99);
  static const Duration expressiveFastSpatialDuration = Duration(milliseconds: 264);

  /// Expressive default spatial spring conversion:
  /// Curve: `cubic-bezier(0.18, 1.13, 0.52, 1.00)`, Duration: 500ms
  /// For container transform expansions (e.g. card expanding to details modal).
  static const Curve expressiveDefaultSpatial = Cubic(0.18, 1.13, 0.52, 1.00);
  static const Duration expressiveDefaultSpatialDuration = Duration(milliseconds: 500);

  /// Expressive slow spatial spring conversion:
  /// Curve: `cubic-bezier(0.14, 1.00, 0.32, 0.99)`, Duration: 620ms
  static const Curve expressiveSlowSpatial = Cubic(0.14, 1.00, 0.32, 0.99);
  static const Duration expressiveSlowSpatialDuration = Duration(milliseconds: 620);

  /// Standard fast spatial spring conversion:
  /// Curve: `cubic-bezier(0.20, 1.04, 0.54, 1.00)`, Duration: 290ms
  static const Curve standardFastSpatial = Cubic(0.20, 1.04, 0.54, 1.00);
  static const Duration standardFastSpatialDuration = Duration(milliseconds: 290);

  /// Standard default spatial spring conversion:
  /// Curve: `cubic-bezier(0.20, 1.00, 0.40, 1.00)`, Duration: 500ms
  static const Curve standardDefaultSpatial = Cubic(0.20, 1.00, 0.40, 1.00);
  static const Duration standardDefaultSpatialDuration = Duration(milliseconds: 500);

  /// Standard slow spatial spring conversion:
  /// Curve: `cubic-bezier(0.19, 1.00, 0.28, 1.00)`, Duration: 740ms
  static const Curve standardSlowSpatial = Cubic(0.19, 1.00, 0.28, 1.00);
  static const Duration standardSlowSpatialDuration = Duration(milliseconds: 740);

  // --------------------------------------------------------------------------
  // Effects Spring Conversions (In-place visual changes: color, opacity, elevation)
  // --------------------------------------------------------------------------

  /// Expressive fast effects spring conversion:
  /// Curve: `cubic-bezier(0.00, 0.79, 0.63, 1.00)`, Duration: 150ms
  static const Curve expressiveFastEffects = Cubic(0.00, 0.79, 0.63, 1.00);
  static const Duration expressiveFastEffectsDuration = Duration(milliseconds: 150);

  /// Expressive default effects spring conversion:
  /// Curve: `cubic-bezier(0.10, 0.90, 0.51, 1.00)`, Duration: 200ms
  static const Curve expressiveDefaultEffects = Cubic(0.10, 0.90, 0.51, 1.00);
  static const Duration expressiveDefaultEffectsDuration = Duration(milliseconds: 200);

  /// Expressive slow effects spring conversion:
  /// Curve: `cubic-bezier(0.10, 0.96, 0.44, 1.00)`, Duration: 350ms
  static const Curve expressiveSlowEffects = Cubic(0.10, 0.96, 0.44, 1.00);
  static const Duration expressiveSlowEffectsDuration = Duration(milliseconds: 350);

  /// Standard fast effects spring conversion:
  /// Curve: `cubic-bezier(0.00, 0.74, 0.54, 1.00)`, Duration: 150ms
  static const Curve standardFastEffects = Cubic(0.00, 0.74, 0.54, 1.00);
  static const Duration standardFastEffectsDuration = Duration(milliseconds: 150);

  /// Standard default effects spring conversion:
  /// Curve: `cubic-bezier(0.00, 0.90, 0.51, 1.00)`, Duration: 200ms
  static const Curve standardDefaultEffects = Cubic(0.00, 0.90, 0.51, 1.00);
  static const Duration standardDefaultEffectsDuration = Duration(milliseconds: 200);

  /// Standard slow effects spring conversion:
  /// Curve: `cubic-bezier(0.10, 0.96, 0.44, 1.00)`, Duration: 350ms
  static const Curve standardSlowEffects = Cubic(0.10, 0.96, 0.44, 1.00);
  static const Duration standardSlowEffectsDuration = Duration(milliseconds: 350);
}

/// Shared Axis Transition Axis dimension.
enum TashilSharedAxisType {
  /// Horizontal slide & fade (Forward/Backward navigation, wizard steps).
  x,

  /// Vertical slide & fade (Search expansion, vertical steppers).
  y,

  /// Depth scale & fade (Folder drill-downs, settings parent-to-child).
  z,
}

/// Official Google Material Design 3 (M3) Transitions Suite.
///
/// Implements the 4 canonical M3 transition patterns:
/// 1. Container Transform
/// 2. Shared Axis (X, Y, Z)
/// 3. Fade Through
/// 4. Fade
class TashilTransitions {
  TashilTransitions._();

  /// Pattern 1: Container Transform Page Route.
  ///
  /// Expands a compact container into a full-screen view or modal with matched
  /// elevation and squircle border radius.
  static PageRouteBuilder<T> containerTransform<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = TashilMotionDuration.long2,
    Duration reverseDuration = TashilMotionDuration.short4,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: TashilMotionEasing.emphasizedDecelerate,
          reverseCurve: TashilMotionEasing.emphasizedAccelerate,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Pattern 2: Shared Axis Page Route.
  ///
  /// Seamlessly slides and fades elements sharing a spatial navigation path.
  /// Fully RTL-aware on the X-axis for Arabic language.
  static PageRouteBuilder<T> sharedAxis<T>({
    required Widget page,
    required BuildContext context,
    TashilSharedAxisType axis = TashilSharedAxisType.x,
    bool isForward = true,
    RouteSettings? settings,
    Duration duration = TashilMotionDuration.medium2,
    Duration reverseDuration = TashilMotionDuration.short4,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: TashilMotionEasing.emphasizedDecelerate,
          reverseCurve: TashilMotionEasing.emphasizedAccelerate,
        );

        switch (axis) {
          case TashilSharedAxisType.x:
            // RTL-aware horizontal offset:
            // In LTR: forward slides from right (dx: 1.0 -> 0.0)
            // In RTL: forward slides from left (dx: -1.0 -> 0.0)
            final double startX = (isRtl ? -1.0 : 1.0) * (isForward ? 0.30 : -0.30);
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(startX, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );

          case TashilSharedAxisType.y:
            final double startY = isForward ? 0.25 : -0.25;
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, startY),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );

          case TashilSharedAxisType.z:
            final double startScale = isForward ? 0.88 : 1.12;
            return ScaleTransition(
              scale: Tween<double>(
                begin: startScale,
                end: 1.0,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
        }
      },
    );
  }

  /// Pattern 3: Fade Through Transition.
  ///
  /// For top-level navigation changes (e.g. Bottom Navigation, Navigation Rail switches).
  /// Outgoing view fades out, while incoming view fades in and subtly scales up from 92% to 100%.
  static PageRouteBuilder<T> fadeThrough<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = TashilMotionDuration.medium2,
    Duration reverseDuration = TashilMotionDuration.short4,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in from 35% to 100% of duration
        final fadeInAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1.0, curve: TashilMotionEasing.standardDecelerate),
        );

        // Scale from 92% to 100%
        final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.35, 1.0, curve: TashilMotionEasing.standardDecelerate),
          ),
        );

        return FadeTransition(
          opacity: fadeInAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Pattern 4: Simple Fade Transition.
  ///
  /// For transient elements entering or exiting within screen bounds (dialogs, tooltips, scrims).
  static PageRouteBuilder<T> fade<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = TashilMotionDuration.short4,
    Duration reverseDuration = TashilMotionDuration.short4,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: TashilMotionEasing.emphasizedDecelerate,
            reverseCurve: TashilMotionEasing.emphasizedAccelerate,
          ),
          child: child,
        );
      },
    );
  }

  /// Opens a modal dialog using Google M3 Container Transform animation.
  ///
  /// Expands smoothly from a compact container with [TashilMotionWebCurves.expressiveDefaultSpatial]
  /// (500ms entrance) and faster exit law [TashilMotionDuration.short4] (200ms exit).
  static Future<T?> showContainerTransformDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? 'Dismiss',
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.54),
      transitionDuration: TashilMotionWebCurves.expressiveDefaultSpatialDuration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: TashilMotionWebCurves.expressiveDefaultSpatial,
          reverseCurve: TashilMotionEasing.emphasizedAccelerate,
        );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: TashilMotionWebCurves.expressiveFastEffects,
          reverseCurve: TashilMotionEasing.emphasizedAccelerate,
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Official Google Material Design 3 (M3) Dialog & Form Transition.
  ///
  /// Conforms strictly to M3 Dialog Motion specifications:
  /// - 400ms entrance with [TashilMotionEasing.emphasizedDecelerate] (`cubic-bezier(0.05, 0.7, 0.1, 1.0)`).
  /// - Faster Exit Law: 200ms exit with [TashilMotionEasing.emphasizedAccelerate] (`cubic-bezier(0.3, 0.0, 0.8, 0.15)`).
  /// - Smooth scaling (starts at 0.90 on entrance, dismisses smoothly to 0.95 on exit).
  /// - Soft dynamic backdrop scrim blur and fade.
  static Future<T?> showM3Dialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    Duration duration = TashilMotionDuration.medium4,
    Duration reverseDuration = TashilMotionDuration.short4,
    double beginScale = 0.90,
  }) {
    return Navigator.of(context, rootNavigator: true).push<T>(
      _M3DialogRoute<T>(
        pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel ?? 'Dismiss',
        barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.45),
        transitionDuration: duration,
        reverseTransitionDuration: reverseDuration,
        transitionBuilder: (ctx, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: TashilMotionEasing.emphasizedDecelerate,
            reverseCurve: TashilMotionEasing.emphasizedAccelerate,
          );

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: TashilMotionWebCurves.expressiveFastEffects,
            reverseCurve: TashilMotionEasing.emphasizedAccelerate,
          );

          final blurSigma = (4.0 * curvedAnimation.value).clamp(0.001, 4.0);

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: beginScale, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Official M3 Dialog Route with strict Google Faster Exit Law.
class _M3DialogRoute<T> extends RawDialogRoute<T> {
  _M3DialogRoute({
    required super.pageBuilder,
    super.barrierDismissible = true,
    super.barrierLabel,
    super.barrierColor,
    required super.transitionDuration,
    required Duration reverseTransitionDuration,
    super.transitionBuilder,
    super.settings,
    super.anchorPoint,
  }) : _reverseTransitionDuration = reverseTransitionDuration;

  final Duration _reverseTransitionDuration;

  @override
  Duration get reverseTransitionDuration => _reverseTransitionDuration;
}

/// Official Material Design 3 (M3) Page Transition Archetype.
enum TashilPageTransitionType {
  /// Official Google M3 Fade Through: Canonical standard for Navigation Rail & Bottom Bar.
  /// Outgoing view fades out in first 35%; incoming view scales 92% -> 100% and fades in.
  fadeThrough,

  /// Official Google M3 Shared Axis X: RTL-aware horizontal slide and fade.
  /// Inverts horizontally between Arabic (RTL) and English/Hindi (LTR).
  sharedAxisX,

  /// Official Google M3 Shared Axis Z: Depth perspective scale zoom and soft fade.
  sharedAxisZ,
}

/// Official Google Material Design 3 (M3) Page Transition Switcher.
///
/// Smoothly animates transitions between top-level pages (Navigation Rail, Bottom Bar, Drawer).
/// Seamlessly supports [TashilPageTransitionType.fadeThrough], [TashilPageTransitionType.sharedAxisX],
/// and [TashilPageTransitionType.sharedAxisZ] with pure RTL/LTR awareness.
class TashilPageTransitionSwitcher extends StatelessWidget {
  final Widget child;
  final TashilPageTransitionType transitionType;
  final Duration duration;
  final Duration reverseDuration;
  final bool isForward;
  final bool isRtl;

  const TashilPageTransitionSwitcher({
    super.key,
    required this.child,
    this.transitionType = TashilPageTransitionType.fadeThrough,
    this.duration = TashilMotionDuration.medium2, // 300ms
    this.reverseDuration = TashilMotionDuration.short4, // 200ms
    this.isForward = true,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget childWidget, Animation<double> animation) {
        final isIncoming = childWidget.key == child.key;

        switch (transitionType) {
          case TashilPageTransitionType.fadeThrough:
            // Google M3 Fade Through Specification:
            // Incoming: fades in from 35% to 100%, scales from 0.92 to 1.0.
            // Outgoing: fades out during first 35% (which is animation from 1.0 down to 0.65).
            if (isIncoming) {
              final fadeIn = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.35, 1.0, curve: TashilMotionEasing.emphasizedDecelerate),
              );
              final scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(fadeIn);

              return FadeTransition(
                opacity: fadeIn,
                child: ScaleTransition(
                  scale: scaleIn,
                  child: childWidget,
                ),
              );
            } else {
              final fadeOut = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.65, 1.0, curve: TashilMotionEasing.emphasizedAccelerate),
              );

              return FadeTransition(
                opacity: fadeOut,
                child: childWidget,
              );
            }

          case TashilPageTransitionType.sharedAxisX:
            // Google M3 Shared Axis X Specification:
            // RTL-aware horizontal slide and fade.
            final double dirFactor = isRtl ? -1.0 : 1.0;
            final double offsetFactor = isForward ? 0.20 : -0.20;

            if (isIncoming) {
              final inAnimation = CurvedAnimation(
                parent: animation,
                curve: TashilMotionEasing.emphasizedDecelerate,
              );
              final slideIn = Tween<Offset>(
                begin: Offset(dirFactor * offsetFactor, 0.0),
                end: Offset.zero,
              ).animate(inAnimation);

              return SlideTransition(
                position: slideIn,
                child: FadeTransition(
                  opacity: inAnimation,
                  child: childWidget,
                ),
              );
            } else {
              final outAnimation = CurvedAnimation(
                parent: animation,
                curve: TashilMotionEasing.emphasizedAccelerate,
              );
              final slideOut = Tween<Offset>(
                begin: Offset(-dirFactor * offsetFactor, 0.0),
                end: Offset.zero,
              ).animate(outAnimation);

              return SlideTransition(
                position: slideOut,
                child: FadeTransition(
                  opacity: outAnimation,
                  child: childWidget,
                ),
              );
            }

          case TashilPageTransitionType.sharedAxisZ:
            // Google M3 Shared Axis Z Specification:
            // Depth scale zoom and fade.
            if (isIncoming) {
              final inAnimation = CurvedAnimation(
                parent: animation,
                curve: TashilMotionEasing.emphasizedDecelerate,
              );
              final scaleIn = Tween<double>(begin: 0.90, end: 1.0).animate(inAnimation);

              return FadeTransition(
                opacity: inAnimation,
                child: ScaleTransition(
                  scale: scaleIn,
                  child: childWidget,
                ),
              );
            } else {
              final outAnimation = CurvedAnimation(
                parent: animation,
                curve: TashilMotionEasing.emphasizedAccelerate,
              );
              final scaleOut = Tween<double>(begin: 1.08, end: 1.0).animate(outAnimation);

              return FadeTransition(
                opacity: outAnimation,
                child: ScaleTransition(
                  scale: scaleOut,
                  child: childWidget,
                ),
              );
            }
        }
      },
      child: child,
    );
  }
}


/// Official Google Material Design 3 (M3) Staggered Entrance Animation Widget.
///
/// Smoothly cascades list and grid items into view with an indexed time delay,
/// expressive spatial slide-up, and graceful fade-in.
class TashilStaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayStep;
  final Duration duration;
  final double slideOffset;

  const TashilStaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delayStep = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 320),
    this.slideOffset = 20.0,
  });

  @override
  State<TashilStaggeredEntrance> createState() => _TashilStaggeredEntranceState();
}

class _TashilStaggeredEntranceState extends State<TashilStaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: TashilMotionEasing.emphasizedDecelerate,
    );

    _slideAnimation = Tween<double>(begin: widget.slideOffset, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: TashilMotionWebCurves.expressiveFastSpatial,
      ),
    );

    final delayMs = (widget.index * widget.delayStep.inMilliseconds).clamp(0, 300);
    if (delayMs == 0) {
      _controller.forward();
    } else {
      _timer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

