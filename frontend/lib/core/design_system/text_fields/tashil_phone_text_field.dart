import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/app_localizations.dart';
import '../buttons/tashil_buttons.dart';
import 'tashil_text_field.dart';

/// Official Material Design 3 Phone Input Field with integrated country selector
/// and unified trailing OTP action button conforming to M3 Text Field specs.
class TashilPhoneTextField extends StatefulWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final bool isPhoneVerified;
  final bool isSendingOtp;
  final VoidCallback? onSendOtp;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final TashilTextFieldVariant variant;
  final bool enabled;
  final Key? textFieldKey;
  final Widget? suffix;

  const TashilPhoneTextField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.isPhoneVerified = false,
    this.isSendingOtp = false,
    this.onSendOtp,
    this.onChanged,
    this.labelText,
    this.helperText,
    this.errorText,
    this.variant = TashilTextFieldVariant.outlined,
    this.enabled = true,
    this.textFieldKey,
    this.suffix,
  });

  @override
  State<TashilPhoneTextField> createState() => _TashilPhoneTextFieldState();
}

class _TashilPhoneTextFieldState extends State<TashilPhoneTextField> {
  late FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isFocused = _focusNode.hasFocus;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final defaultOutlineColor = colorScheme.outlineVariant;
    final hoverOutlineColor = colorScheme.onSurfaceVariant;
    final focusedOutlineColor = colorScheme.primary;
    final errorOutlineColor = colorScheme.error;

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

    final Color fillColor = widget.variant == TashilTextFieldVariant.filled
        ? (isFocused
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65))
        : Colors.transparent;

    final effectiveRadius = BorderRadius.circular(12.0);
    final hasNumber = widget.controller.text.trim().isNotEmpty;

    // Integrated Prefix: Leading Phone Icon + Country Code Dropdown + Divider
    final prefixWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 12),
        Icon(
          Icons.phone_outlined,
          size: 20,
          color: hasError
              ? colorScheme.error
              : (isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.countryCode,
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            items: const [
              DropdownMenuItem(
                value: '+20',
                child: Text('🇪🇬 +20', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              DropdownMenuItem(
                value: '+971',
                child: Text('🇦🇪 +971', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
            onChanged: widget.enabled
                ? (val) {
                    if (val != null) widget.onCountryCodeChanged(val);
                  }
                : null,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 24,
          child: VerticalDivider(
            width: 12,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );

    // Suffix: Custom suffix or subtle verified icon
    Widget? suffixWidget = widget.suffix;
    if (suffixWidget == null && widget.isPhoneVerified && hasNumber) {
      suffixWidget = const Padding(
        padding: EdgeInsetsDirectional.only(end: 12.0),
        child: Icon(Icons.check_circle_rounded, size: 20, color: Colors.green),
      );
    } else if (suffixWidget == null && hasNumber && widget.onSendOtp != null) {
      suffixWidget = Padding(
        padding: const EdgeInsetsDirectional.only(end: 6.0),
        child: SizedBox(
          height: 36,
          child: TashilButton.tonal(
            onPressed: widget.isSendingOtp ? null : widget.onSendOtp,
            isLoading: widget.isSendingOtp,
            icon: Icons.sms_outlined,
            label: loc.tr('sendOtp'),
            height: 36,
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TextFormField(
        key: widget.textFieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        enabled: widget.enabled,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        onChanged: widget.onChanged,
        style: TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: widget.enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        decoration: InputDecoration(
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          filled: true,
          fillColor: fillColor,
          labelText: widget.labelText ?? loc.tr('phoneNumberLabel'),
          hintText: widget.countryCode == '+20' ? '010xxxxxxxx' : '050xxxxxxx',
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
            letterSpacing: 0.5,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          prefixIcon: prefixWidget,
          prefixIconConstraints: const BoxConstraints(minHeight: 56),
          suffixIcon: suffixWidget,
          suffixIconConstraints: const BoxConstraints(minHeight: 56),
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
