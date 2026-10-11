import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/audio/audio_feedback_service.dart';

/// Official Google Material Design 3 (M3) Switch Component.
///
/// Conforms strictly to:
/// - https://m3.material.io/components/switch/specs
/// - https://m3.material.io/components/switch/guidelines
///
/// Specification Attributes:
/// 1. Track:
///    - Width: 52.0dp
///    - Height: 32.0dp
///    - Outline width: 2.0dp (unselected)
///    - Shape: Full stadium capsule (16.0dp radius)
///    - Selected fill: colorScheme.primary
///    - Unselected fill: colorScheme.surfaceContainerHighest with 2.0dp outline border
/// 2. Handle (formerly "thumb"):
///    - Unselected size (without icon): 16.0dp x 16.0dp
///    - Unselected size (with icon): 24.0dp x 24.0dp
///    - Selected size: 24.0dp x 24.0dp
///    - Pressed / Dragging size: 28.0dp x 28.0dp
///    - Selected fill: colorScheme.onPrimary
///    - Unselected fill: colorScheme.outline
/// 3. Embedded Icon:
///    - Size: 16.0dp
///    - Default selected icon: [Icons.check_rounded] in colorScheme.primary
///    - Configurable for: selected-only (M3 default), both, or none
/// 4. State Layer & Interaction:
///    - 40.0dp state layer aura centered on the handle
///    - Smooth 250ms easeInOutCubic transition with morphing handle & icon scale
///    - 48.0dp accessible touch target
///    - 100% Directionality Awareness (RTL for Arabic, LTR for English/Hindi)
///    - Tactile audio & haptic feedback on toggle
class TashilSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showIcon;
  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;
  final Color? activeIconColor;
  final Color? inactiveIconColor;
  final bool enabled;

  const TashilSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.showIcon = true,
    this.selectedIcon = Icons.check_rounded,
    this.unselectedIcon,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.activeThumbColor,
    this.inactiveThumbColor,
    this.activeIconColor,
    this.inactiveIconColor,
    this.enabled = true,
  });

  /// Convenience factory for a clean switch without handle icons.
  const factory TashilSwitch.noIcon({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled,
  }) = _TashilSwitchNoIcon;

  @override
  State<TashilSwitch> createState() => _TashilSwitchState();
}

class _TashilSwitchNoIcon extends TashilSwitch {
  const _TashilSwitchNoIcon({
    super.key,
    required super.value,
    required super.onChanged,
    super.enabled = true,
  }) : super(showIcon: false, selectedIcon: null, unselectedIcon: null);
}

class _TashilSwitchState extends State<TashilSwitch>
    with SingleTickerProviderStateMixin {
  // Official M3 Dimensions
  static const double kTrackWidth = 52.0;
  static const double kTrackHeight = 32.0;
  static const double kUnselectedHandleSize = 16.0;
  static const double kSelectedHandleSize = 24.0;
  static const double kPressedHandleSize = 28.0;
  static const double kStateLayerSize = 40.0;
  static const double kTouchTargetSize = 48.0;
  static const double kIconSize = 16.0;
  static const double kOutlineWidth = 2.0;

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.value ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant TashilSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onChanged == null) return;
    final newValue = !widget.value;
    HapticFeedback.lightImpact();
    TashilAudioFeedback.playStepTick(stepRatio: newValue ? 1.0 : 0.4);
    widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isInteractive = widget.enabled && widget.onChanged != null;

    return MouseRegion(
      cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (isInteractive && mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isInteractive && mounted) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (_) {
          if (isInteractive && mounted) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isInteractive && mounted) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isInteractive && mounted) setState(() => _isPressed = false);
        },
        onHorizontalDragStart: (_) {
          if (isInteractive && mounted) setState(() => _isPressed = true);
        },
        onHorizontalDragUpdate: (details) {
          if (!isInteractive) return;
          final double delta = details.primaryDelta ?? 0.0;
          final double progressDelta = (isRtl ? -delta : delta) / (kTrackWidth - kSelectedHandleSize);
          _controller.value = (_controller.value + progressDelta).clamp(0.0, 1.0);
        },
        onHorizontalDragEnd: (details) {
          if (!isInteractive) return;
          setState(() => _isPressed = false);
          final bool newValue = _controller.value >= 0.5;
          if (newValue != widget.value) {
            HapticFeedback.lightImpact();
            TashilAudioFeedback.playStepTick(stepRatio: newValue ? 1.0 : 0.4);
            widget.onChanged!(newValue);
          } else {
            if (widget.value) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          }
        },
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kTouchTargetSize,
            minHeight: kTouchTargetSize,
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final double t = _animation.value;

                // Color Tokens Calculation per M3 Specifications
                final Color selectedTrackColor = widget.activeTrackColor ??
                    (widget.enabled
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.12));

                final Color unselectedTrackColor = widget.inactiveTrackColor ??
                    (widget.enabled
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.12));

                final Color trackColor = Color.lerp(
                  unselectedTrackColor,
                  selectedTrackColor,
                  t,
                )!;

                final Color outlineColor = widget.enabled
                    ? colorScheme.outline
                    : colorScheme.onSurface.withValues(alpha: 0.12);

                final Color selectedHandleColor = widget.activeThumbColor ??
                    (widget.enabled
                        ? colorScheme.onPrimary
                        : colorScheme.surface);

                final Color unselectedHandleColor = widget.inactiveThumbColor ??
                    (widget.enabled
                        ? colorScheme.outline
                        : colorScheme.onSurface.withValues(alpha: 0.38));

                final Color handleColor = Color.lerp(
                  unselectedHandleColor,
                  selectedHandleColor,
                  t,
                )!;

                // Border lerp: 2dp outline when unselected -> 0dp when selected
                final double borderWidth = lerpDouble(kOutlineWidth, 0.0, t)!;

                // Handle size lerp:
                // Base unselected size is 16dp (or 24dp if unselected icon is shown)
                final double unselectedBaseSize = (widget.showIcon && widget.unselectedIcon != null)
                    ? kSelectedHandleSize
                    : kUnselectedHandleSize;
                double targetHandleSize = lerpDouble(unselectedBaseSize, kSelectedHandleSize, t)!;
                if (_isPressed && widget.enabled) {
                  targetHandleSize = kPressedHandleSize;
                }

                // Center position calculation:
                // When unselected (t = 0), center is at 16.0dp from track start.
                // When selected (t = 1), center is at 36.0dp from track start (52.0 - 16.0).
                final double handleCenterStart = lerpDouble(16.0, 36.0, t)!;

                // RTL Inversion: in RTL, start is right, so handle moves from right to left
                final double visualCenterX = isRtl
                    ? (kTrackWidth - handleCenterStart)
                    : handleCenterStart;

                final double handleLeft = visualCenterX - (targetHandleSize / 2);
                final double handleTop = (kTrackHeight - targetHandleSize) / 2;

                // State layer aura color
                final Color stateLayerColor = t > 0.5
                    ? colorScheme.primary.withValues(alpha: _isPressed ? 0.12 : 0.08)
                    : colorScheme.onSurface.withValues(alpha: _isPressed ? 0.12 : 0.08);

                return SizedBox(
                  width: kTrackWidth,
                  height: kTrackHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Track Container
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: trackColor,
                            borderRadius: BorderRadius.circular(kTrackHeight / 2),
                            border: borderWidth > 0.01
                                ? Border.all(
                                    color: outlineColor,
                                    width: borderWidth,
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // 2. State Layer Aura (Hover / Pressed 40dp circle)
                      if ((_isHovered || _isPressed) && widget.enabled)
                        Positioned(
                          left: visualCenterX - (kStateLayerSize / 2),
                          top: (kTrackHeight - kStateLayerSize) / 2,
                          child: IgnorePointer(
                            child: Container(
                              width: kStateLayerSize,
                              height: kStateLayerSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: stateLayerColor,
                              ),
                            ),
                          ),
                        ),

                      // 3. Floating Morphing Handle (Thumb) with Icon
                      Positioned(
                        left: handleLeft,
                        top: handleTop,
                        child: Container(
                          width: targetHandleSize,
                          height: targetHandleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: handleColor,
                            boxShadow: t > 0.5 && widget.enabled
                                ? [
                                    BoxShadow(
                                      color: colorScheme.shadow.withValues(alpha: 0.15),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: _buildHandleIcon(
                              t,
                              colorScheme,
                              targetHandleSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildHandleIcon(double t, ColorScheme colorScheme, double currentHandleSize) {
    if (!widget.showIcon) return null;

    final Color selectedIconColor = widget.activeIconColor ??
        (widget.enabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38));

    final Color unselectedIconColor = widget.inactiveIconColor ??
        (widget.enabled ? colorScheme.surfaceContainerHighest : colorScheme.onSurface.withValues(alpha: 0.38));

    if (t > 0.4 && widget.selectedIcon != null) {
      // Selected Icon (Checkmark) with scale and fade animation
      final double iconScale = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
      return Transform.scale(
        scale: iconScale,
        child: Opacity(
          opacity: iconScale,
          child: Icon(
            widget.selectedIcon,
            size: kIconSize,
            color: selectedIconColor,
          ),
        ),
      );
    } else if (t <= 0.4 && widget.unselectedIcon != null) {
      // Unselected Icon
      final double iconScale = ((0.4 - t) / 0.4).clamp(0.0, 1.0);
      return Transform.scale(
        scale: iconScale,
        child: Opacity(
          opacity: iconScale,
          child: Icon(
            widget.unselectedIcon,
            size: kIconSize,
            color: unselectedIconColor,
          ),
        ),
      );
    }

    return null;
  }
}

/// Official Material Design 3 (M3) Switch List Tile.
///
/// Integrates [TashilSwitch] into an accessible, responsive M3 list tile row.
/// Entire row is interactive and taps to toggle the switch smoothly.
class TashilSwitchListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  final bool showIcon;
  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final bool enabled;

  const TashilSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.contentPadding = const EdgeInsetsDirectional.symmetric(horizontal: 16.0, vertical: 8.0),
    this.showIcon = true,
    this.selectedIcon = Icons.check_rounded,
    this.unselectedIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = enabled && onChanged != null;

    return InkWell(
      onTap: isInteractive ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            if (secondary != null) ...[
              secondary!,
              const SizedBox(width: 16.0),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: theme.textTheme.bodyLarge?.copyWith(
                          color: enabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          fontWeight: FontWeight.w500,
                        ) ??
                        const TextStyle(),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2.0),
                    DefaultTextStyle(
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: enabled
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          ) ??
                          const TextStyle(),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            TashilSwitch(
              value: value,
              onChanged: onChanged,
              showIcon: showIcon,
              selectedIcon: selectedIcon,
              unselectedIcon: unselectedIcon,
              enabled: enabled,
            ),
          ],
        ),
      ),
    );
  }
}
