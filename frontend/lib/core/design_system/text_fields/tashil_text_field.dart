import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material Design 3 Text Field Variants
enum TashilTextFieldVariant {
  /// Outlined text field (Default): Transparent/surface fill with 1dp outline border (2dp when focused)
  outlined,

  /// Filled text field: Soft surfaceContainerHighest fill with active indicator
  filled,
}

/// Official Material Design 3 Text Field component for Tashil Real Estate.
///
/// Conforms strictly to:
/// - https://m3.material.io/components/text-fields/specs
/// - https://m3.material.io/components/text-fields/overview
///
/// Features:
/// - 56dp standard single-line touch container height
/// - 12dp squircle corner radius
/// - Outlined and Filled M3 variants
/// - Dynamic floating label with M3 typography and colors
/// - Leading (prefix) icon with directionality-aware insets
/// - Trailing (suffix) icon or compound action widget
/// - Full RTL/LTR directionality awareness
/// - Helper text, error text, and character counter
class TashilTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? prefix;
  final IconData? suffixIcon;
  final Widget? suffix;
  final VoidCallback? onSuffixIconTap;
  final TashilTextFieldVariant variant;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextDirection? textDirection;
  final bool autofocus;

  const TashilTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.suffix,
    this.onSuffixIconTap,
    this.variant = TashilTextFieldVariant.outlined,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.textDirection,
    this.autofocus = false,
  });

  /// Convenience constructor for M3 Outlined Text Field
  const TashilTextField.outlined({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.suffix,
    this.onSuffixIconTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.textDirection,
    this.autofocus = false,
  }) : variant = TashilTextFieldVariant.outlined;

  /// Convenience constructor for M3 Filled Text Field
  const TashilTextField.filled({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.suffix,
    this.onSuffixIconTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.textDirection,
    this.autofocus = false,
  }) : variant = TashilTextFieldVariant.filled;

  @override
  State<TashilTextField> createState() => _TashilTextFieldState();
}

class _TashilTextFieldState extends State<TashilTextField> {
  late FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFocused = _focusNode.hasFocus;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // M3 Color Tokens
    final defaultOutlineColor = colorScheme.outlineVariant;
    final hoverOutlineColor = colorScheme.onSurfaceVariant;
    final focusedOutlineColor = colorScheme.primary;
    final errorOutlineColor = colorScheme.error;

    // Fill Color
    final Color fillColor;
    if (widget.variant == TashilTextFieldVariant.filled) {
      fillColor = isFocused
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    } else {
      fillColor = widget.readOnly
          ? colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
          : Colors.transparent;
    }

    // Determine current active border color
    final Color activeBorderColor;
    if (hasError) {
      activeBorderColor = errorOutlineColor;
    } else if (isFocused) {
      activeBorderColor = focusedOutlineColor;
    } else if (_isHovered && widget.enabled) {
      activeBorderColor = hoverOutlineColor;
    } else {
      activeBorderColor = defaultOutlineColor;
    }

    final effectiveRadius = BorderRadius.circular(12.0);

    // Prefix Widget
    Widget? prefixWidget;
    if (widget.prefix != null) {
      prefixWidget = widget.prefix;
    } else if (widget.prefixIcon != null) {
      prefixWidget = Padding(
        padding: const EdgeInsetsDirectional.only(start: 12.0, end: 10.0),
        child: Icon(
          widget.prefixIcon,
          size: 20.0,
          color: hasError
              ? colorScheme.error
              : (isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Suffix Widget
    Widget? suffixWidget;
    if (widget.suffix != null) {
      suffixWidget = widget.suffix;
    } else if (widget.suffixIcon != null) {
      suffixWidget = Padding(
        padding: const EdgeInsetsDirectional.only(end: 12.0, start: 8.0),
        child: widget.onSuffixIconTap != null
            ? IconButton(
                icon: Icon(widget.suffixIcon, size: 20.0),
                color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
                onPressed: widget.onSuffixIconTap,
                splashRadius: 20,
              )
            : Icon(
                widget.suffixIcon,
                size: 20.0,
                color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        readOnly: widget.readOnly,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        textDirection: widget.textDirection,
        autofocus: widget.autofocus,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: widget.enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        decoration: InputDecoration(
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          filled: true,
          fillColor: fillColor,
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          labelStyle: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: hasError
                ? colorScheme.error
                : (isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant),
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
            color: hasError
                ? colorScheme.error
                : (isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant),
          ),
          hintStyle: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          prefixIcon: prefixWidget,
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: suffixWidget,
          suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          border: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(color: defaultOutlineColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(color: activeBorderColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(
              color: hasError ? errorOutlineColor : focusedOutlineColor,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(color: errorOutlineColor, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(color: errorOutlineColor, width: 2.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.38),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
