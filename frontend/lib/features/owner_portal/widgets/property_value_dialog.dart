import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

/// Saves a property value, or clears it with null.
typedef PropertyValueSaver = Future<void> Function(String propertyId, double? value);

/// Lets the owner enter what a property is worth (TAQ-164). Optional and private: it is kept in
/// the owner's own tree, never on the public listing, and only feeds the gross yield figure.
class PropertyValueDialog extends StatefulWidget {
  final ManagedPropertyModel property;
  final PropertyValueSaver? save;

  const PropertyValueDialog({super.key, required this.property, this.save});

  static Future<void> show(BuildContext context, ManagedPropertyModel property, {PropertyValueSaver? save}) {
    return showDialog<void>(
      context: context,
      builder: (_) => PropertyValueDialog(property: property, save: save),
    );
  }

  /// The value typed in: null for an empty field, NaN when it is not a usable amount.
  static double? parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[,\s]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || !value.isFinite || value <= 0 || value > 1e12) return double.nan;
    return value;
  }

  @override
  State<PropertyValueDialog> createState() => _PropertyValueDialogState();
}

class _PropertyValueDialogState extends State<PropertyValueDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.property.propertyValue;
    _controller = TextEditingController(text: current == null ? '' : current.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(double? value) async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await (widget.save ?? PropertyLifecycleService().setPropertyValue)(widget.property.id, value);
      if (!mounted) return;
      Navigator.of(context).pop();
      TashilSnackBar.showSuccess(context: context, message: loc.tr('pvSaved'));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = loc.tr('pvSaveFailed');
      });
    }
  }

  void _save() {
    final loc = AppLocalizations.of(context);
    final value = PropertyValueDialog.parse(_controller.text);
    if (value != null && value.isNaN) {
      setState(() => _error = loc.tr('pvInvalid'));
      return;
    }
    _submit(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currency = widget.property.countryCode == 'AE' ? loc.tr('currency_ae') : loc.tr('currency_eg');
    return AlertDialog(
      title: Text(loc.tr('pvTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.tr('pvHelp'), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('property_value_field'),
            controller: _controller,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
            decoration: InputDecoration(
              labelText: loc.tr('pvField'),
              suffixText: currency,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        if (widget.property.propertyValue != null)
          TextButton(
            key: const ValueKey('property_value_clear'),
            onPressed: _saving ? null : () => _submit(null),
            child: Text(loc.tr('pvClear')),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(loc.tr('cancel')),
        ),
        FilledButton(
          key: const ValueKey('property_value_save'),
          onPressed: _saving ? null : _save,
          child: Text(loc.tr('save')),
        ),
      ],
    );
  }
}
