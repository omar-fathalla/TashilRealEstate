import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/callable_error.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/owner_portal/services/lease_payment_service.dart';

/// Records a cash or bank-transfer rent payment on one of the owner's (or agency's) active leases
/// through the `recordManualPayment` Cloud Function (TAQ-16). The server checks the lease, the
/// amount and the month, issues the receipt and notifies the tenant; this dialog writes nothing.
class RecordManualPaymentDialog extends StatefulWidget {
  final String? propertyId;
  final String? period;
  final void Function(String method, String reference)? onRecorded;
  final LeasePaymentService? service;
  final DateTime Function()? now;

  const RecordManualPaymentDialog({super.key, this.propertyId, this.period, this.onRecorded, this.service, this.now});

  static Future<void> show(
    BuildContext context, {
    String? propertyId,
    String? period,
    void Function(String method, String reference)? onRecorded,
  }) {
    return TashilTransitions.showM3Dialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RecordManualPaymentDialog(propertyId: propertyId, period: period, onRecorded: onRecorded),
    );
  }

  @override
  State<RecordManualPaymentDialog> createState() => _RecordManualPaymentDialogState();
}

class _RecordManualPaymentDialogState extends State<RecordManualPaymentDialog> {
  late final LeasePaymentService _service = widget.service ?? LeasePaymentService.instance;
  late final Future<List<PayableLease>> _leases = _service.activeLeases();
  late final DateTime _today = (widget.now ?? DateTime.now)();
  late final TextEditingController _amount = TextEditingController();
  late final TextEditingController _period = TextEditingController(text: widget.period ?? _month(_today));
  late final TextEditingController _paidOn = TextEditingController(text: _day(_today));
  final _reference = TextEditingController();
  PayableLease? _lease;
  String _method = 'cash';
  bool _saving = false;
  bool _missing = false;
  CallableErrorInfo? _error;

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _month(DateTime d) => '${d.year}-${_two(d.month)}';
  static String _day(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  @override
  void dispose() {
    _amount.dispose();
    _period.dispose();
    _paidOn.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _choose(PayableLease? lease) {
    setState(() {
      _lease = lease;
      if (lease != null) {
        _amount.text = lease.monthlyRent == lease.monthlyRent.roundToDouble() ? lease.monthlyRent.toStringAsFixed(0) : lease.monthlyRent.toString();
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _today,
      firstDate: DateTime(_today.year - 2),
      lastDate: _today,
    );
    if (picked != null) setState(() => _paidOn.text = _day(picked));
  }

  Future<void> _save() async {
    final lease = _lease;
    final amount = double.tryParse(_amount.text.trim());
    if (lease == null || amount == null || amount <= 0 || _reference.text.trim().isEmpty || _period.text.trim().isEmpty || _paidOn.text.trim().isEmpty) {
      setState(() => _missing = true);
      return;
    }
    setState(() {
      _saving = true;
      _missing = false;
      _error = null;
    });
    try {
      await _service.recordManualPayment(
        lease: lease,
        method: _method,
        reference: _reference.text,
        paidOn: _paidOn.text.trim(),
        period: _period.text.trim(),
        amount: amount,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = describeCallableError(e);
        });
      }
      return;
    }
    widget.onRecorded?.call(_method, _reference.text.trim());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: FutureBuilder<List<PayableLease>>(
              future: _leases,
              builder: (context, snapshot) {
                final leases = snapshot.data ?? const <PayableLease>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsetsDirectional.all(48), child: Center(child: CircularProgressIndicator()));
                }
                if (_lease == null && leases.isNotEmpty && !_missing) {
                  final byProperty = widget.propertyId == null ? <PayableLease>[] : leases.where((l) => l.propertyId == widget.propertyId).toList();
                  final first = byProperty.isNotEmpty ? byProperty.first : (leases.length == 1 ? leases.first : null);
                  if (first != null) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _choose(first) : null);
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsetsDirectional.all(8),
                            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.receipt_long_rounded, color: scheme.onPrimaryContainer, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(loc.tr('mpTitle'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: loc.tr('close'),
                            onPressed: _saving ? null : () => Navigator.of(context).pop(),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        if (leases.isEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(vertical: 24),
                            child: Text(loc.tr('mpNoActiveLeases'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                          )
                        else ...[
                          DropdownButtonFormField<PayableLease>(
                            key: ValueKey(_lease?.id),
                            initialValue: _lease,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: loc.tr('mpLease')),
                            items: [for (final l in leases) DropdownMenuItem(value: l, child: Text(l.label.isEmpty ? l.id : l.label, overflow: TextOverflow.ellipsis))],
                            onChanged: _saving ? null : _choose,
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: TextField(
                                controller: _amount,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: loc.tr('mpAmount'),
                                  suffixText: _lease == null ? null : loc.tr(_lease!.currencyCode == 'EGP' ? 'currency_eg' : 'currency_ae'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: TextField(controller: _period, decoration: InputDecoration(labelText: loc.tr('mpPeriod'), hintText: 'YYYY-MM'))),
                          ]),
                          if (_lease != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 4),
                              child: Text(
                                '${loc.tr('mpRentDue')}: ${CurrencyFormatter.formatAmount(_lease!.monthlyRent, langCode: locale.languageCode)}',
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(loc.tr('mpMethod'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: _methodCard(context, 'cash', loc.tr('mpMethod_cash'), Icons.payments_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _methodCard(context, 'bank_transfer', loc.tr('mpMethod_bank_transfer'), Icons.account_balance_rounded)),
                          ]),
                          const SizedBox(height: 12),
                          TextField(controller: _reference, maxLength: 100, decoration: InputDecoration(labelText: loc.tr('mpReference'))),
                          TextField(
                            controller: _paidOn,
                            decoration: InputDecoration(
                              labelText: loc.tr('mpPaidOn'),
                              hintText: 'YYYY-MM-DD',
                              suffixIcon: IconButton(icon: const Icon(Icons.calendar_today_rounded, size: 18), onPressed: _pickDate),
                            ),
                          ),
                          if (_missing)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 8),
                              child: Text(loc.tr('mpFillAll'), style: TextStyle(color: scheme.error)),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 8),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(loc.tr('mpErr_${_error!.code}') == 'mpErr_${_error!.code}' ? loc.tr('mpErr_unknown') : loc.tr('mpErr_${_error!.code}'), style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold)),
                                if (_error!.message.isNotEmpty) Text(_error!.message, style: TextStyle(color: scheme.error, fontSize: 12)),
                              ]),
                            ),
                          const SizedBox(height: 16),
                          TashilButton(label: loc.tr('mpConfirm'), icon: Icons.check_circle_rounded, isLoading: _saving, onPressed: _saving ? null : _save, height: 48),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _methodCard(BuildContext context, String key, String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _method == key;
    return InkWell(
      onTap: _saving ? null : () => setState(() => _method = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 1.5 : 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: selected ? scheme.onPrimary : scheme.onSurface)),
        ]),
      ),
    );
  }
}
