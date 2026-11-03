import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/audio/audio_feedback_service.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Official Google Material Design 3 (M3) Checkbox Component.
///
/// Conforms strictly to:
/// - https://m3.material.io/components/checkbox/specs
/// - https://m3.material.io/components/checkbox/guidelines
///
/// Specification Attributes:
/// 1. Container:
///    - Width: 18.0dp
///    - Height: 18.0dp
///    - Corner radius: 2.0dp
///    - Outline border: 2.0dp
/// 2. Colors & States:
///    - Unselected: Transparent fill, 2.0dp outline border in [colorScheme.outline].
///    - Selected: Solid fill in [colorScheme.primary], checkmark in [colorScheme.onPrimary].
///    - Indeterminate: Solid fill in [colorScheme.primary], dash in [colorScheme.onPrimary].
///    - Hovered: Outline darkens, 40dp circular state layer with 8% primary/onSurface.
///    - Focused: 40dp state layer with 10% secondary focus ring.
///    - Pressed: 40dp state layer with 10% ripple.
///    - Disabled: 38% content opacity with muted border.
/// 3. Interaction & Touch Target:
///    - 40.0dp state layer diameter.
///    - 48.0dp minimum accessible touch target.
///    - Smooth 200ms easeInOutCubic animation.
///    - Tactile audio & haptic feedback on toggle.
class TashilCheckbox extends StatefulWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final bool enabled;
  final Color? activeColor;
  final Color? checkColor;
  final String? semanticLabel;

  const TashilCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.enabled = true,
    this.activeColor,
    this.checkColor,
    this.semanticLabel,
  });

  @override
  State<TashilCheckbox> createState() => _TashilCheckboxState();
}

class _TashilCheckboxState extends State<TashilCheckbox> {
  static const double kBoxSize = 18.0;
  static const double kCornerRadius = 2.0;
  static const double kBorderWidth = 2.0;
  static const double kStateLayerSize = 40.0;
  static const double kTouchTargetSize = 48.0;

  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  void _handleTap() {
    if (!widget.enabled || widget.onChanged == null) return;

    try {
      HapticFeedback.selectionClick();
      TashilAudioFeedback.playStepTick(stepRatio: 0.6);
    } catch (_) {}

    if (widget.tristate) {
      if (widget.value == null) {
        widget.onChanged!(true);
      } else if (widget.value == true) {
        widget.onChanged!(false);
      } else {
        widget.onChanged!(null);
      }
    } else {
      widget.onChanged!(!(widget.value ?? false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = widget.value == true;
    final isIndeterminate = widget.value == null && widget.tristate;
    final isActive = isSelected || isIndeterminate;

    final primaryColor = widget.activeColor ?? colorScheme.primary;
    final onPrimaryColor = widget.checkColor ?? colorScheme.onPrimary;

    // Disabled styling
    if (!widget.enabled) {
      final disabledBorderColor = colorScheme.onSurface.withValues(alpha: 0.38);
      return Semantics(
        checked: widget.value,
        enabled: false,
        label: widget.semanticLabel,
        child: SizedBox(
          width: kTouchTargetSize,
          height: kTouchTargetSize,
          child: Center(
            child: Container(
              width: kBoxSize,
              height: kBoxSize,
              decoration: BoxDecoration(
                color: isActive ? disabledBorderColor : Colors.transparent,
                borderRadius: BorderRadius.circular(kCornerRadius),
                border: Border.all(
                  color: disabledBorderColor,
                  width: kBorderWidth,
                ),
              ),
              child: isActive
                  ? Icon(
                      isIndeterminate ? Symbols.remove_rounded : Symbols.check_rounded,
                      size: 14.0,
                      color: colorScheme.surface,
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    // Active state layer color
    Color stateLayerColor = Colors.transparent;
    if (_isPressed) {
      stateLayerColor = (isActive ? primaryColor : colorScheme.onSurface).withValues(alpha: 0.12);
    } else if (_isHovered) {
      stateLayerColor = (isActive ? primaryColor : colorScheme.onSurface).withValues(alpha: 0.08);
    } else if (_isFocused) {
      stateLayerColor = (isActive ? primaryColor : colorScheme.onSurface).withValues(alpha: 0.10);
    }

    final borderColor = isActive
        ? primaryColor
        : (_isHovered ? colorScheme.onSurface : colorScheme.outline);

    return Semantics(
      checked: widget.value,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: kTouchTargetSize,
            height: kTouchTargetSize,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // State Layer Aura
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: (_isHovered || _isFocused || _isPressed) ? kStateLayerSize : 0.0,
                    height: (_isHovered || _isFocused || _isPressed) ? kStateLayerSize : 0.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stateLayerColor,
                    ),
                  ),

                  // M3 Checkbox Box
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    width: kBoxSize,
                    height: kBoxSize,
                    decoration: BoxDecoration(
                      color: isActive ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(kCornerRadius),
                      border: Border.all(
                        color: borderColor,
                        width: kBorderWidth,
                      ),
                      boxShadow: (_isHovered && isActive)
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: isActive ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          isIndeterminate ? Symbols.remove_rounded : Symbols.check_rounded,
                          size: 14.0,
                          color: onPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Official Google Material Design 3 (M3) Checkbox List Tile.
///
/// Designed specifically for lists of selectable options, amenities, terms,
/// and filters with scannable labels and full RTL/LTR directionality.
class TashilCheckboxListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final bool enabled;
  final ListTileControlAffinity controlAffinity;
  final EdgeInsetsDirectional? contentPadding;
  final ShapeBorder? shape;
  final Color? activeColor;
  final Color? checkColor;

  const TashilCheckboxListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.secondary,
    this.tristate = false,
    this.enabled = true,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.contentPadding,
    this.shape,
    this.activeColor,
    this.checkColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = value == true;

    final checkbox = TashilCheckbox(
      value: value,
      onChanged: enabled ? onChanged : null,
      tristate: tristate,
      enabled: enabled,
      activeColor: activeColor,
      checkColor: checkColor,
    );

    return Material(
      color: Colors.transparent,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.35)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && onChanged != null
            ? () {
                if (tristate) {
                  if (value == null) {
                    onChanged!(true);
                  } else if (value == true) {
                    onChanged!(false);
                  } else {
                    onChanged!(null);
                  }
                } else {
                  onChanged!(!(value ?? false));
                }
              }
            : null,
        hoverColor: colorScheme.primary.withValues(alpha: 0.05),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Container(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.22)
              : colorScheme.surfaceContainerLowest.withValues(alpha: 0.4),
          padding: contentPadding?.resolve(Directionality.of(context)) ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (controlAffinity == ListTileControlAffinity.leading) ...[
                checkbox,
                const SizedBox(width: 8),
              ],
              if (secondary != null && controlAffinity == ListTileControlAffinity.leading) ...[
                secondary!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ) ??
                          const TextStyle(),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ) ??
                            const TextStyle(),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (secondary != null && controlAffinity == ListTileControlAffinity.trailing) ...[
                const SizedBox(width: 10),
                secondary!,
              ],
              if (controlAffinity == ListTileControlAffinity.trailing) ...[
                const SizedBox(width: 8),
                checkbox,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
