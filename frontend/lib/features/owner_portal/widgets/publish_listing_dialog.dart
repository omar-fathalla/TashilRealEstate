import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_builder_wizard_dialog.dart';

/// Modal dialog for managing property marketplace publication status and fast tenant recording.
/// Fully adheres to Material Design 3 guidelines:
/// - M3 Shaded Close Button standard ([TashilIconButton.close])
/// - M3 Connected Button Group suite ([TashilConnectedButtonGroup])
/// - High-contrast single-hue status derivations
/// - Full trilingual parity and screen reactivity via [ValueListenableBuilder]
class PublishListingDialog extends StatefulWidget {
  final ManagedPropertyModel property;
  final bool initialRentMode;

  const PublishListingDialog({
    super.key,
    required this.property,
    this.initialRentMode = false,
  });

  static void show(
    BuildContext context,
    ManagedPropertyModel property, {
    bool initialRentMode = false,
  }) {
    TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PublishListingDialog(
        property: property,
        initialRentMode: initialRentMode,
      ),
    );
  }

  @override
  State<PublishListingDialog> createState() => _PublishListingDialogState();
}

class _PublishListingDialogState extends State<PublishListingDialog> {
  final _tenantNameCtrl = TextEditingController();
  final _tenantPhoneCtrl = TextEditingController();
  late final TextEditingController _monthlyRentCtrl;
  late bool _isRentingMode;
  String _rentingAction = 'confirm';
  DateTime _leaseStartDate = DateTime.now();
  int _durationMonths = 12;
  String _firstMonthStatus = 'due'; // 'due', 'cash', 'bank_wire'

  @override
  void initState() {
    super.initState();
    _isRentingMode = widget.initialRentMode;
    _monthlyRentCtrl = TextEditingController(
      text: widget.property.pricePerMonth > 0
          ? widget.property.pricePerMonth.toStringAsFixed(0)
          : '25000',
    );
    if (widget.property.tenantName != null && widget.property.tenantName!.isNotEmpty) {
      _tenantNameCtrl.text = widget.property.tenantName!;
    }
    if (widget.property.tenantPhone != null && widget.property.tenantPhone!.isNotEmpty) {
      _tenantPhoneCtrl.text = widget.property.tenantPhone!;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!widget.initialRentMode &&
        widget.property.rentalStatus == PropertyRentalStatus.rented &&
        widget.property.leaseStartDate != null &&
        !(widget.property.leaseStartDate!.year == 2026 &&
            widget.property.leaseStartDate!.month == 1 &&
            widget.property.leaseStartDate!.day == 1)) {
      _leaseStartDate = widget.property.leaseStartDate!;
    } else {
      _leaseStartDate = today;
    }
    if (widget.property.installments.isNotEmpty) {
      _durationMonths = widget.property.installments.length;
    }
  }

  @override
  void dispose() {
    _tenantNameCtrl.dispose();
    _tenantPhoneCtrl.dispose();
    _monthlyRentCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _leaseStartDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _leaseStartDate = picked);
    }
  }

  Future<void> _handlePublish() async {
    final loc = AppLocalizations.of(context);
    await PropertyLifecycleService().publishProperty(widget.property.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    TashilSnackBar.showSuccess(
      context: context,
      message: loc.tr('propertyPublishedSuccessNotice'),
    );
  }

  Future<void> _handleUnpublish() async {
    final loc = AppLocalizations.of(context);
    await PropertyLifecycleService().unpublishProperty(widget.property.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    TashilSnackBar.showInfo(
      context: context,
      message: loc.tr('unpublishSuccessNotice'),
    );
  }

  Future<void> _handleMarkAsRented() async {
    final loc = AppLocalizations.of(context);
    if (_tenantNameCtrl.text.trim().isEmpty) {
      TashilSnackBar.showWarning(
        context: context,
        message: loc.tr('enterTenantNameWarning'),
      );
      return;
    }

    final rent = double.tryParse(_monthlyRentCtrl.text.trim()) ?? widget.property.pricePerMonth;
    final firstMonthPaid = _firstMonthStatus != 'due';
    final firstMonthPaymentMethod = _firstMonthStatus == 'due' ? null : _firstMonthStatus;

    await PropertyLifecycleService().markAsRented(
      propertyId: widget.property.id,
      tenantName: _tenantNameCtrl.text.trim(),
      tenantPhone: _tenantPhoneCtrl.text.trim().isEmpty ? '+20 100 000 0000' : _tenantPhoneCtrl.text.trim(),
      monthlyRent: rent,
      startDate: _leaseStartDate,
      durationMonths: _durationMonths,
      firstMonthPaid: firstMonthPaid,
      firstMonthPaymentMethod: firstMonthPaymentMethod,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    TashilSnackBar.showSuccess(
      context: context,
      message: loc.tr('rentedAndHiddenSuccessNotice'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lang = LocaleController.languageCode;
    final isMobile = ResponsiveLayout.isMobile(context);
    final currency = widget.property.countryCode == 'AE' ? loc.tr('currency_ae') : loc.tr('currency_eg');

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, _, __) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: colorScheme.surface,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 36,
            vertical: isMobile ? 16 : 28,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('manageListingStatusTitle'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.property.getTitle(lang),
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TashilIconButton.close(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: colorScheme.outlineVariant.withValues(alpha: 0.6)),

                  // Current Status Banner (Single-Hue High Contrast Derivation)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.property.isPublished
                          ? (isDark ? const Color(0xFF0D3322) : const Color(0xFFE6F4EA))
                          : (isDark ? const Color(0xFF282A2D) : const Color(0xFFF1F3F4)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.property.isPublished
                            ? (isDark ? const Color(0xFF34A853).withValues(alpha: 0.7) : const Color(0xFF81C995))
                            : (isDark ? const Color(0xFF5F6368) : const Color(0xFFBDC1C6)),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.property.isPublished ? Icons.check_circle_rounded : Icons.visibility_off_rounded,
                          color: widget.property.isPublished
                              ? (isDark ? const Color(0xFF81C995) : const Color(0xFF137333))
                              : (isDark ? const Color(0xFFE8EAED) : const Color(0xFF3C4043)),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.property.isPublished
                                    ? loc.tr('currentlyLiveOnMarketplace')
                                    : loc.tr('currentlyHiddenFromMarketplace'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: widget.property.isPublished
                                      ? (isDark ? const Color(0xFF81C995) : const Color(0xFF137333))
                                      : (isDark ? const Color(0xFFE8EAED) : const Color(0xFF3C4043)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.formatAmount(widget.property.pricePerMonth, langCode: lang)} $currency / ${loc.tr('perMonth')}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: widget.property.isPublished
                                      ? (isDark ? const Color(0xFF81C995).withValues(alpha: 0.85) : const Color(0xFF137333).withValues(alpha: 0.85))
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (!_isRentingMode) ...[
                    // Mode 1: Quick Publish / Unpublish Actions
                    TashilConnectedButtonGroup<String>(
                      height: 44.0,
                      isFullWidth: true,
                      selectedValue: widget.property.isPublished ? 'unpublish' : 'publish',
                      showCheckmark: false,
                      onSelectionChanged: (action) {
                        if (action == 'publish') {
                          _handlePublish();
                        } else if (action == 'unpublish') {
                          _handleUnpublish();
                        } else if (action == 'rent') {
                          setState(() => _isRentingMode = true);
                        }
                      },
                      segments: [
                        if (!widget.property.isPublished)
                          TashilConnectedButtonSegment(
                            value: 'publish',
                            label: loc.tr('publishToMarketplaceBtn'),
                            icon: Icons.rocket_launch_rounded,
                          )
                        else
                          TashilConnectedButtonSegment(
                            value: 'unpublish',
                            label: loc.tr('unpublishFromMarketplaceBtn'),
                            icon: Icons.visibility_off_rounded,
                          ),
                        TashilConnectedButtonSegment(
                          value: 'rent',
                          label: loc.tr('markAsRentedBtn'),
                          icon: Icons.vpn_key_rounded,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Mode 2: Certified Lease Wizard OR Quick Tenant Entry
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: isDark ? 0.45 : 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  color: colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loc.tr('createCertifiedLeaseBtn'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.tr('certifiedLeaseDesc'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: TashilButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                LeaseBuilderWizardDialog.show(context, targetProperty: widget.property);
                              },
                              icon: Icons.description_outlined,
                              label: loc.tr('createCertifiedLeaseBtn'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TashilDivider.withLabel(
                      label: loc.tr('or'),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      loc.tr('quickTenantLogBtn'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loc.tr('quickTenantLogDesc'),
                      style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    // 1. Tenant Full Name
                    TextField(
                      controller: _tenantNameCtrl,
                      decoration: InputDecoration(
                        labelText: loc.tr('tenantFullNameLabel'),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Tenant Phone
                    TextField(
                      controller: _tenantPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: loc.tr('tenantPhoneLabel'),
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Monthly Rent Amount & Lease Start Date
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _monthlyRentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.tr('monthlyRentAmountLabel'),
                              suffixText: currency,
                              prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.25),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.tr('leaseStartDateLabel'),
                                          style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                                        ),
                                        Text(
                                          '${_leaseStartDate.year}/${_leaseStartDate.month.toString().padLeft(2, '0')}/${_leaseStartDate.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit_calendar_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Lease Duration Selector (M3 Connected Button Group)
                    Text(
                      loc.tr('leaseDurationLabel'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    TashilConnectedButtonGroup<int>(
                      height: 40.0,
                      isFullWidth: true,
                      selectedValue: _durationMonths,
                      showCheckmark: false,
                      onSelectionChanged: (val) => setState(() => _durationMonths = val),
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 6,
                          label: loc.tr('duration6Months'),
                          icon: Icons.calendar_view_month_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 12,
                          label: loc.tr('duration12Months'),
                          icon: Icons.calendar_month_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 24,
                          label: loc.tr('duration24Months'),
                          icon: Icons.date_range_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 5. First Month Payment Status (M3 Connected Button Group)
                    Text(
                      loc.tr('firstMonthPaymentStatusLabel'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    TashilConnectedButtonGroup<String>(
                      height: 40.0,
                      isFullWidth: true,
                      selectedValue: _firstMonthStatus,
                      showCheckmark: false,
                      onSelectionChanged: (val) => setState(() => _firstMonthStatus = val),
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 'due',
                          label: loc.tr('firstMonthNotPaid'),
                          icon: Icons.pending_actions_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'cash',
                          label: loc.tr('firstMonthPaidCash'),
                          icon: Icons.payments_outlined,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'bank_wire',
                          label: loc.tr('firstMonthPaidBankWire'),
                          icon: Icons.account_balance_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Official M3 Connected Button Group for Actions Footer
                    TashilConnectedButtonGroup<String>(
                      height: 44.0,
                      isFullWidth: true,
                      selectedValue: _rentingAction,
                      showCheckmark: false,
                      onSelectionChanged: (action) {
                        setState(() => _rentingAction = action);
                        if (action == 'cancel') {
                          if (widget.initialRentMode) {
                            Navigator.of(context).pop();
                          } else {
                            setState(() => _isRentingMode = false);
                          }
                        } else if (action == 'confirm') {
                          _handleMarkAsRented();
                        }
                      },
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 'cancel',
                          label: loc.tr('cancel'),
                          icon: Icons.close_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'confirm',
                          label: loc.tr('confirm'),
                          icon: Icons.check_rounded,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
