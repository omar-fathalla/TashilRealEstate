import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/rent_receipt_dialog.dart';

class TenantCheckoutDialog extends StatefulWidget {
  final RentInvoiceModel invoice;

  const TenantCheckoutDialog({super.key, required this.invoice});

  static void show(BuildContext context, RentInvoiceModel invoice) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TenantCheckoutDialog(invoice: invoice),
    );
  }

  @override
  State<TenantCheckoutDialog> createState() => _TenantCheckoutDialogState();
}

class _TenantCheckoutDialogState extends State<TenantCheckoutDialog> {
  late String _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _autoDebitEnabled = true;

  // Form controllers
  final _cardNumberCtrl = TextEditingController(text: '4111 2222 3333 4444');
  final _cardExpiryCtrl = TextEditingController(text: '12/28');
  final _cardCvvCtrl = TextEditingController(text: '883');
  final _walletPhoneCtrl = TextEditingController(text: '01012345678');
  final _instaPayVpaCtrl = TextEditingController(text: 'tenant@instapay');

  @override
  void initState() {
    super.initState();
    final isUAE = widget.invoice.countryCode == 'AE';
    _selectedPaymentMethod = isUAE ? 'apple_pay' : 'card';
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    _walletPhoneCtrl.dispose();
    _instaPayVpaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      final methodPrefix = _selectedPaymentMethod.toUpperCase();
      final randomSuffix = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      final txnRef = 'TXN-$methodPrefix-$randomSuffix';

      final paidInvoice = await RentCollectionService().payInvoice(
        invoiceId: widget.invoice.id,
        paymentMethod: _selectedPaymentMethod,
        transactionReference: txnRef,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();

      // Show official digital receipt
      RentReceiptDialog.show(context, paidInvoice);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = widget.invoice.countryCode == 'AE';
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 660,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.payment_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('automatedRentCheckoutTitle'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${loc.tr('invoiceNo')}: ${widget.invoice.invoiceNumber}',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TashilIconButton.close(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Invoice Amount Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('totalDueToPay'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.formatAmount(widget.invoice.totalAmountDue, langCode: lang)} $currency',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.invoice.latePenaltyAmount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+ ${CurrencyFormatter.formatAmount(widget.invoice.latePenaltyAmount, langCode: lang)} $currency (${loc.tr('accumulatedLateFee')})',
                              style: TextStyle(
                                color: theme.colorScheme.errorContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          loc.tr('leasedUnit'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.invoice.unitNumber,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.invoice.buildingName,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Method Selector
              Text(
                loc.tr('selectPaymentMethod'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              if (isUAE)
                _buildUaePaymentOptions(loc)
              else
                _buildEgyptPaymentOptions(loc),

              const SizedBox(height: 18),

              // Selected Method Input Card
              _buildMethodInputFields(loc, isUAE),
              const SizedBox(height: 18),

              // Split Payout Guarantee Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sync_alt_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('instantSplitPayoutGuaranteeTitle'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${loc.tr('netTransferredToOwner')}: ${CurrencyFormatter.formatAmount(widget.invoice.netPayoutToOwner, langCode: lang)} $currency (${widget.invoice.owner.name})',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Auto-Debit Recurring Toggle
              TashilSwitchListTile(
                value: _autoDebitEnabled,
                onChanged: (val) => setState(() => _autoDebitEnabled = val),
                title: Text(loc.tr('enableAutoDebitMonthly'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                subtitle: Text(loc.tr('enableAutoDebitSubtitle'), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              // Pay Now CTA Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TashilButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  icon: Icons.check_circle_rounded,
                  label: '${loc.tr('confirmAndPay')} ${CurrencyFormatter.formatAmount(widget.invoice.totalAmountDue, langCode: lang)} $currency',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Egypt Payment Methods ---
  Widget _buildEgyptPaymentOptions(AppLocalizations loc) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPaymentOptionChip('google_pay', loc.tr('paymentMethodGooglePay'), Icons.account_balance_wallet_rounded),
        _buildPaymentOptionChip('apple_pay', loc.tr('paymentMethodApplePay'), Icons.apple_rounded),
        _buildPaymentOptionChip('card', loc.tr('paymentMethodCard'), Icons.credit_card_rounded),
        _buildPaymentOptionChip('instapay', loc.tr('paymentMethodInstaPay'), Icons.bolt_rounded),
        _buildPaymentOptionChip('vodafone_cash', loc.tr('paymentMethodVodafoneCash'), Icons.phone_android_rounded),
        _buildPaymentOptionChip('fawry', loc.tr('paymentMethodFawry'), Icons.storefront_rounded),
      ],
    );
  }

  // --- UAE Payment Methods ---
  Widget _buildUaePaymentOptions(AppLocalizations loc) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPaymentOptionChip('apple_pay', loc.tr('paymentMethodApplePay'), Icons.apple_rounded),
        _buildPaymentOptionChip('google_pay', loc.tr('paymentMethodGooglePay'), Icons.account_balance_wallet_rounded),
        _buildPaymentOptionChip('card', loc.tr('paymentMethodCard'), Icons.credit_card_rounded),
        _buildPaymentOptionChip('direct_debit', loc.tr('paymentMethodDirectDebit'), Icons.account_balance_rounded),
        _buildPaymentOptionChip('iban_wire', loc.tr('paymentMethodIbanWire'), Icons.send_rounded),
      ],
    );
  }

  Widget _buildPaymentOptionChip(String methodKey, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == methodKey;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = methodKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodInputFields(AppLocalizations loc, bool isUAE) {
    final theme = Theme.of(context);
    if (_selectedPaymentMethod == 'card') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              TextField(
                controller: _cardNumberCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: loc.tr('cardNumberLabel'),
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 18),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardExpiryCtrl,
                      keyboardType: TextInputType.datetime,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.tr('cardExpiryLabel'),
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cardCvvCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      obscureText: true,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 16),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedPaymentMethod == 'vodafone_cash') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _walletPhoneCtrl,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              labelText: loc.tr('mobileWalletNumberLabel'),
              prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      );
    }

    if (_selectedPaymentMethod == 'instapay') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _instaPayVpaCtrl,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              labelText: loc.tr('instapayVpaLabel'),
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      );
    }

    if (_selectedPaymentMethod == 'fawry') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.tr('fawryCodeInstruction'), style: TextStyle(fontSize: 12, color: theme.colorScheme.onTertiaryContainer)),
            const SizedBox(height: 6),
            Text(
              'FWRY-9823-4412',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedPaymentMethod == 'google_pay') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  loc.tr('googlePayOneClickHint'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fingerprint_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  loc.tr('googlePayBiometricSecurityBadge'),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_selectedPaymentMethod == 'apple_pay') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple_rounded, color: theme.colorScheme.onSurface, size: 24),
                const SizedBox(width: 8),
                Text(
                  loc.tr('applePayOneClickHint'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  loc.tr('applePayFaceIdSecurityBadge'),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_selectedPaymentMethod == 'direct_debit') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.tr('uaeddsDirectDebitHint'), style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(
              'Account IBAN: ...${widget.invoice.owner.iban.substring(widget.invoice.owner.iban.length > 8 ? widget.invoice.owner.iban.length - 8 : 0)}',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
