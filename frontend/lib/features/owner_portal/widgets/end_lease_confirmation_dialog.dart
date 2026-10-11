import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

/// Official Material Design 3 Confirmation Dialog for Lease Termination and Market Re-listing.
///
/// Provides a clear, unambiguous overview of:
/// 1. 100% Financial Ledger preservation (Zero Data Loss guarantee).
/// 2. Future unaccrued installment cancellation.
/// 3. Tenant disassociation with historical record preservation.
/// 4. Re-listing on public marketplace vs saving as private draft for maintenance.
class EndLeaseConfirmationDialog extends StatefulWidget {
  final ManagedPropertyModel property;

  const EndLeaseConfirmationDialog({
    super.key,
    required this.property,
  });

  /// Displays the M3 End Lease Confirmation Dialog.
  /// Returns `true` if lease termination was confirmed and executed, `false` or `null` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required ManagedPropertyModel property,
  }) {
    return TashilTransitions.showM3Dialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EndLeaseConfirmationDialog(property: property),
    );
  }

  @override
  State<EndLeaseConfirmationDialog> createState() => _EndLeaseConfirmationDialogState();
}

class _EndLeaseConfirmationDialogState extends State<EndLeaseConfirmationDialog> {
  bool _republishImmediately = true;
  bool _isProcessing = false;

  Future<void> _handleConfirmTermination(AppLocalizations loc) async {
    setState(() => _isProcessing = true);

    try {
      await PropertyLifecycleService().endLeaseAndRePublish(
        propertyId: widget.property.id,
        republishToMarketplace: _republishImmediately,
      );

      if (!mounted) return;

      final successMsg = _republishImmediately
          ? loc.tr('leaseEndedAndRepublishedNotification')
          : loc.tr('leaseEndedAsDraftNotification');

      TashilSnackBar.showSuccess(
        context: context,
        message: successMsg,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      TashilSnackBar.showError(
        context: context,
        message: 'حدث خطأ أثناء إنهاء العقد: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, currentLocale, _) {
        final lang = currentLocale.languageCode;
        final isMobile = ResponsiveLayout.isMobile(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = isMobile ? screenWidth * 0.94 : 580.0;
        final currency = widget.property.currencyCode == 'EGP'
            ? (lang == 'ar' ? 'ج.م' : (lang == 'hi' ? 'ईजीपी' : 'EGP'))
            : (lang == 'ar' ? 'د.إ' : (lang == 'hi' ? 'एईडी' : 'AED'));

        final propTitle = widget.property.titles[lang] ?? widget.property.titles['ar'] ?? '';
        final paidCount = widget.property.paidMonthsCount;
        final totalPaid = widget.property.totalCollectedRevenue;

        return Dialog(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 6,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 24,
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. M3 Header
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.assignment_return_rounded,
                          color: theme.colorScheme.onErrorContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('endLeaseConfirmTitle'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              propTitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TashilIconButton.close(
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),

                const TashilDivider.fullWidth(),

                // 2. Scrollable Content Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Property & Tenant Summary Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  widget.property.image,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.apartment_rounded, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.property.tenantName != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.person_rounded, size: 14, color: theme.colorScheme.primary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${loc.tr('currentTenantName')}: ${widget.property.tenantName}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Row(
                                      children: [
                                        Icon(Icons.payments_rounded, size: 14, color: theme.colorScheme.secondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${CurrencyFormatter.formatAmount(totalPaid, langCode: lang)} $currency ($paidCount ${loc.tr('monthsPaidOutOf12')})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Section Explanation Heading
                        Text(
                          loc.tr('endLeaseConfirmSubtitle'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Consequence Item 1: Financial Ledger Preserved (Green/Verified)
                        _buildConsequenceCard(
                          context,
                          icon: Icons.verified_user_rounded,
                          iconColor: const Color(0xFF10B981),
                          containerBg: const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                          title: loc.tr('consequenceFinancialPreservedTitle'),
                          description: loc.tr('consequenceFinancialPreservedDesc'),
                        ),

                        const SizedBox(height: 10),

                        // Consequence Item 2: Remaining Future Installments Closed
                        _buildConsequenceCard(
                          context,
                          icon: Icons.event_busy_rounded,
                          iconColor: theme.colorScheme.primary,
                          containerBg: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                          borderColor: theme.colorScheme.primary.withValues(alpha: 0.20),
                          title: loc.tr('consequenceFutureClosedTitle'),
                          description: loc.tr('consequenceFutureClosedDesc'),
                        ),

                        const SizedBox(height: 10),

                        // Consequence Item 3: Tenant Clearance & Historical Archiving
                        _buildConsequenceCard(
                          context,
                          icon: Icons.person_pin_rounded,
                          iconColor: theme.colorScheme.secondary,
                          containerBg: theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
                          borderColor: theme.colorScheme.secondary.withValues(alpha: 0.20),
                          title: loc.tr('consequenceTenantDisassociatedTitle'),
                          description: loc.tr('consequenceTenantDisassociatedDesc'),
                        ),

                        const SizedBox(height: 10),

                        // Consequence Item 4: Marketplace Live or Draft
                        _buildConsequenceCard(
                          context,
                          icon: Icons.storefront_rounded,
                          iconColor: theme.colorScheme.tertiary,
                          containerBg: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.25),
                          borderColor: theme.colorScheme.tertiary.withValues(alpha: 0.20),
                          title: loc.tr('consequenceMarketplaceLiveTitle'),
                          description: loc.tr('consequenceMarketplaceLiveDesc'),
                        ),

                        const SizedBox(height: 14),

                        // Handover & Utility Clearance Notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.key_rounded, size: 18, color: Colors.amber),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.tr('handoverClearanceNoticeTitle'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      loc.tr('handoverClearanceNoticeDesc'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.4,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Smart Toggle: Re-publish immediately vs Save as Draft
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _republishImmediately ? Icons.public_rounded : Icons.construction_rounded,
                                size: 20,
                                color: _republishImmediately
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _republishImmediately
                                          ? loc.tr('republishImmediateOption')
                                          : loc.tr('saveAsDraftOption'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TashilSwitch(
                                value: _republishImmediately,
                                onChanged: (val) {
                                  setState(() => _republishImmediately = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const TashilDivider.cardAction(),

                // 3. Pinned Action Buttons Footer
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        TashilButton.tonal(
                          label: loc.tr('cancelAndKeepLeaseBtn'),
                          icon: Icons.arrow_back_rounded,
                          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                        ),
                        TashilButton.filled(
                          label: loc.tr('confirmTerminationActionBtn'),
                          icon: Icons.check_circle_rounded,
                          onPressed: _isProcessing ? null : () => _handleConfirmTermination(loc),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsequenceCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color containerBg,
    required Color borderColor,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
