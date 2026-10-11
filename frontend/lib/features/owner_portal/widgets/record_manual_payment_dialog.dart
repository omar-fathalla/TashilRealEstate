import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

class RecordManualPaymentDialog extends StatefulWidget {
  final ManagedPropertyModel property;
  final MonthlyInstallment installment;

  const RecordManualPaymentDialog({
    super.key,
    required this.property,
    required this.installment,
  });

  static void show(
    BuildContext context, {
    required ManagedPropertyModel property,
    required MonthlyInstallment installment,
  }) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RecordManualPaymentDialog(
        property: property,
        installment: installment,
      ),
    );
  }

  @override
  State<RecordManualPaymentDialog> createState() => _RecordManualPaymentDialogState();
}

class _RecordManualPaymentDialogState extends State<RecordManualPaymentDialog> {
  String _selectedMethod = 'cash';
  final _notesCtrl = TextEditingController(text: 'تم الاستلام نقداً بموجب إيصال استلام رسمي');
  bool _isSaving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    setState(() => _isSaving = true);

    InstallmentPaymentStatus status;
    if (_selectedMethod == 'cash') {
      status = InstallmentPaymentStatus.paidCash;
    } else if (_selectedMethod == 'bank_wire') {
      status = InstallmentPaymentStatus.paidBankWire;
    } else {
      status = InstallmentPaymentStatus.paidOnline;
    }

    await PropertyLifecycleService().recordInstallmentPayment(
      propertyId: widget.property.id,
      monthKey: widget.installment.monthKey,
      status: status,
      paymentMethod: _selectedMethod,
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    final theme = Theme.of(context);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.colorScheme.primary,
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.onPrimary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم تسجيل سداد دفعة شهر ${widget.installment.getMonthName(LocaleController.languageCode)} بنجاح',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = LocaleController.languageCode;
    final isMobile = ResponsiveLayout.isMobile(context);
    final currency = widget.property.countryCode == 'AE' ? loc.tr('currency_ae') : loc.tr('currency_eg');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.tr('recordManualPaymentTitle'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${widget.installment.getMonthName(lang)} - ${widget.property.unitNumber}',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Amount Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.tr('installmentAmountLabel'),
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${CurrencyFormatter.formatAmount(widget.installment.amount, langCode: lang)} $currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Payment Method Picker
              Text(
                loc.tr('receivedViaPaymentMethod'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 10),

              // Symmetrical 3-column payment method options
              Row(
                children: [
                  Expanded(
                    child: _buildMethodCard(
                      context: context,
                      key: 'cash',
                      label: loc.tr('paymentMethodCashHand'),
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMethodCard(
                      context: context,
                      key: 'bank_wire',
                      label: loc.tr('paymentMethodIbanWire'),
                      icon: Icons.account_balance_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMethodCard(
                      context: context,
                      key: 'instapay',
                      label: loc.tr('paymentMethodInstaPay'),
                      icon: Icons.bolt_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Notes Field
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: loc.tr('paymentReceiptNotesLabel'),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 22),

              // Confirm CTA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TashilButton(
                  onPressed: _isSaving ? null : _savePayment,
                  icon: Icons.check_circle_rounded,
                  label: loc.tr('confirmRecordInstallmentBtn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required String key,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedMethod == key;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = key),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
