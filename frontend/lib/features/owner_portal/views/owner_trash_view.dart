import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';
import 'package:tashil_real_estate/features/lease_builder/services/legal_clauses_service.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';

/// Unified Material Design 3 (M3) Trash & Recycle Bin View for Owner Portal.
///
/// Central hub consolidating all soft-deleted items across:
/// 1. Rent Collection Invoices ([RentInvoiceModel])
/// 2. Lease & Tenancy Contracts ([LeaseContractModel])
///
/// Features:
/// - 7-day safety retention with automatic background purge.
/// - Segmented category filter using [TashilConnectedButtonGroup].
/// - Instant one-click restore and permanent purge actions.
/// - Empty entire trash action with confirmation.
/// - Pure trilingual parity (Arabic RTL, English LTR, Hindi LTR).
class OwnerTrashView extends StatefulWidget {
  const OwnerTrashView({super.key});

  @override
  State<OwnerTrashView> createState() => _OwnerTrashViewState();
}

class _OwnerTrashViewState extends State<OwnerTrashView> {
  String _selectedSegment = 'all'; // 'all', 'invoices', 'contracts'

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = LocaleController.languageCode;

    return ValueListenableBuilder<String>(
      valueListenable: CountryController.currentCountry,
      builder: (context, currentCountry, _) {
        final isUAE = currentCountry == 'AE';
        final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

        return ValueListenableBuilder<List<RentInvoiceModel>>(
          valueListenable: RentCollectionService().invoicesNotifier,
          builder: (context, _, __) {
            return ValueListenableBuilder<List<LeaseContractModel>>(
              valueListenable: LegalClausesService().contractsNotifier,
              builder: (context, _, __) {
                final deletedInvoices = RentCollectionService()
                    .getDeletedInvoicesForCountry(currentCountry);
                final deletedContracts = LegalClausesService()
                    .getDeletedContractsForCountry(currentCountry);
                final totalDeleted = deletedInvoices.length + deletedContracts.length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isCompact = screenWidth < 768;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 16 : 28,
                        vertical: isCompact ? 20 : 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header Toolbar: Title, Badges, and Empty Trash CTA
                          _buildHeaderToolbar(
                            context: context,
                            loc: loc,
                            colorScheme: colorScheme,
                            isCompact: isCompact,
                            currentCountry: currentCountry,
                            totalDeleted: totalDeleted,
                          ),
                          const SizedBox(height: 18),

                          // 2. 7-Day Auto-Purge Policy Banner
                          _buildPolicyBanner(
                            loc: loc,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 20),

                          // 3. Segment Filter (All, Invoices, Contracts)
                          _buildSegmentFilter(
                            loc: loc,
                            invoicesCount: deletedInvoices.length,
                            contractsCount: deletedContracts.length,
                            totalCount: totalDeleted,
                          ),
                          const SizedBox(height: 20),

                          // 4. Content Area: Items or Empty State
                          _buildContentList(
                            context: context,
                            loc: loc,
                            colorScheme: colorScheme,
                            currency: currency,
                            lang: lang,
                            deletedInvoices: deletedInvoices,
                            deletedContracts: deletedContracts,
                            isCompact: isCompact,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Top Header Toolbar with Title, Counters, and Empty Trash Button
  Widget _buildHeaderToolbar({
    required BuildContext context,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required bool isCompact,
    required String currentCountry,
    required int totalDeleted,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('trashAndDeleted'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 20 : 24,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalDeleted ${loc.tr('allTrashItems')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (totalDeleted > 0)
          TashilButton(
            variant: TashilButtonVariant.outlined,
            icon: Icons.delete_sweep_rounded,
            label: loc.tr('emptyTrashAction'),
            customColor: colorScheme.error,
            onPressed: () => _confirmEmptyAllTrash(loc, currentCountry, colorScheme),
          ),
      ],
    );
  }

  /// Informational 7-Day Safety Retention Banner
  Widget _buildPolicyBanner({
    required AppLocalizations loc,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.tr('unifiedTrashBannerDesc'),
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter Segments via TashilConnectedButtonGroup
  Widget _buildSegmentFilter({
    required AppLocalizations loc,
    required int invoicesCount,
    required int contractsCount,
    required int totalCount,
  }) {
    return TashilConnectedButtonGroup<String>(
      height: 38,
      selectedValue: _selectedSegment,
      showCheckmark: false,
      onSelectionChanged: (val) {
        setState(() {
          _selectedSegment = val;
        });
      },
      segments: [
        TashilConnectedButtonSegment(
          value: 'all',
          label: '${loc.tr('allTrashItems')} ($totalCount)',
          icon: Icons.grid_view_rounded,
        ),
        TashilConnectedButtonSegment(
          value: 'invoices',
          label: '${loc.tr('trashInvoicesSegment')} ($invoicesCount)',
          icon: Icons.receipt_long_rounded,
        ),
        TashilConnectedButtonSegment(
          value: 'contracts',
          label: '${loc.tr('trashContractsSegment')} ($contractsCount)',
          icon: Icons.description_rounded,
        ),
      ],
    );
  }

  /// Content list displaying active segment items or clean empty state
  Widget _buildContentList({
    required BuildContext context,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required String currency,
    required String lang,
    required List<RentInvoiceModel> deletedInvoices,
    required List<LeaseContractModel> deletedContracts,
    required bool isCompact,
  }) {
    final showInvoices = _selectedSegment == 'all' || _selectedSegment == 'invoices';
    final showContracts = _selectedSegment == 'all' || _selectedSegment == 'contracts';

    final filteredInvoices = showInvoices ? deletedInvoices : <RentInvoiceModel>[];
    final filteredContracts = showContracts ? deletedContracts : <LeaseContractModel>[];
    final totalVisible = filteredInvoices.length + filteredContracts.length;

    if (totalVisible == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr('emptyTrashHubTitle'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  loc.tr('emptyTrashHubDesc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 1. Deleted Contracts
        if (showContracts && filteredContracts.isNotEmpty) ...[
          for (final contract in filteredContracts) ...[
            _buildContractTrashCard(
              context: context,
              loc: loc,
              colorScheme: colorScheme,
              contract: contract,
              currency: currency,
              lang: lang,
              isCompact: isCompact,
            ),
            const SizedBox(height: 12),
          ],
        ],

        // 2. Deleted Invoices
        if (showInvoices && filteredInvoices.isNotEmpty) ...[
          for (final invoice in filteredInvoices) ...[
            _buildInvoiceTrashCard(
              context: context,
              loc: loc,
              colorScheme: colorScheme,
              invoice: invoice,
              currency: currency,
              lang: lang,
              isCompact: isCompact,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  /// Trashed Contract Card
  Widget _buildContractTrashCard({
    required BuildContext context,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required LeaseContractModel contract,
    required String currency,
    required String lang,
    required bool isCompact,
  }) {
    final daysLeft = _calculateRemainingDays(contract.deletedAt);

    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading Contract Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loc.tr('itemTypeContract'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contract.property.propertyTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCountdownBadge(colorScheme, loc, daysLeft),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tag_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          contract.contractNumber,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          contract.tenant.name,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payments_outlined, size: 13, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${CurrencyFormatter.formatPriceWithCurrency(amount: contract.financialTerms.monthlyRentEquivalent, currencyCode: currency, langCode: lang)} / ${loc.tr('month')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions: Restore & Permanent Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompact)
                TashilIconButton.tonal(
                  size: 36,
                  iconSize: 18,
                  icon: Icons.restore_from_trash_rounded,
                  tooltip: loc.tr('restoreShort'),
                  onPressed: () {
                    LegalClausesService().restoreContract(contract.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('contractRestoredSuccess')),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )
              else
                TashilButton.tonal(
                  height: 36,
                  icon: Icons.restore_from_trash_rounded,
                  label: loc.tr('restoreShort'),
                  onPressed: () {
                    LegalClausesService().restoreContract(contract.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('contractRestoredSuccess')),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              const SizedBox(width: 8),
              TashilIconButton.outlined(
                size: 36,
                iconSize: 18,
                icon: Icons.delete_forever_rounded,
                onPressed: () => _confirmPermanentlyDeleteContract(loc, contract, colorScheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Trashed Invoice Card
  Widget _buildInvoiceTrashCard({
    required BuildContext context,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required RentInvoiceModel invoice,
    required String currency,
    required String lang,
    required bool isCompact,
  }) {
    final daysLeft = _calculateRemainingDays(invoice.deletedAt);

    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading Invoice Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loc.tr('itemTypeInvoice'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        invoice.unitTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCountdownBadge(colorScheme, loc, daysLeft),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tag_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          invoice.invoiceNumber,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          invoice.tenant.name,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payments_outlined, size: 13, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          CurrencyFormatter.formatPriceWithCurrency(
                            amount: invoice.baseAmount,
                            currencyCode: currency,
                            langCode: lang,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions: Restore & Permanent Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompact)
                TashilIconButton.tonal(
                  size: 36,
                  iconSize: 18,
                  icon: Icons.restore_from_trash_rounded,
                  tooltip: loc.tr('restoreShort'),
                  onPressed: () {
                    RentCollectionService().restoreInvoice(invoice.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('invoiceRestoredSuccess')),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )
              else
                TashilButton.tonal(
                  height: 36,
                  icon: Icons.restore_from_trash_rounded,
                  label: loc.tr('restoreShort'),
                  onPressed: () {
                    RentCollectionService().restoreInvoice(invoice.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.tr('invoiceRestoredSuccess')),
                        backgroundColor: colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              const SizedBox(width: 8),
              TashilIconButton.outlined(
                size: 36,
                iconSize: 18,
                icon: Icons.delete_forever_rounded,
                onPressed: () => _confirmPermanentlyDeleteInvoice(loc, invoice, colorScheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Countdown Badge Chip
  Widget _buildCountdownBadge(ColorScheme colorScheme, AppLocalizations loc, int daysLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Text(
            '${loc.tr('remainingDaysForAutoDelete')} $daysLeft ${loc.tr('daysCountdown')}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateRemainingDays(DateTime? deletedAt) {
    if (deletedAt == null) return 7;
    final elapsedDays = DateTime.now().difference(deletedAt).inDays;
    return (7 - elapsedDays).clamp(1, 7);
  }

  Future<void> _confirmPermanentlyDeleteContract(
    AppLocalizations loc,
    LeaseContractModel contract,
    ColorScheme colorScheme,
  ) async {
    final confirmed = await TashilAlertDialog.showConfirmation(
      context: context,
      icon: Icons.delete_forever_rounded,
      title: loc.tr('confirmDeletePermanentlyTitle'),
      message: loc.tr('confirmDeleteContractPermanentlyDesc'),
      confirmLabel: loc.tr('deletePermanentlyAction'),
      cancelLabel: loc.tr('cancel'),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    LegalClausesService().permanentlyDeleteContract(contract.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.tr('contractPermanentlyDeletedSuccess')),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmPermanentlyDeleteInvoice(
    AppLocalizations loc,
    RentInvoiceModel invoice,
    ColorScheme colorScheme,
  ) async {
    final confirmed = await TashilAlertDialog.showConfirmation(
      context: context,
      icon: Icons.delete_forever_rounded,
      title: loc.tr('confirmDeletePermanentlyTitle'),
      message: loc.tr('confirmDeletePermanentlyDesc'),
      confirmLabel: loc.tr('deletePermanentlyAction'),
      cancelLabel: loc.tr('cancel'),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    RentCollectionService().permanentlyDeleteInvoice(invoice.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.tr('invoicePermanentlyDeletedSuccess')),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmEmptyAllTrash(
    AppLocalizations loc,
    String countryCode,
    ColorScheme colorScheme,
  ) async {
    final confirmed = await TashilAlertDialog.showConfirmation(
      context: context,
      icon: Icons.delete_sweep_rounded,
      title: loc.tr('confirmEmptyAllTrashTitle'),
      message: loc.tr('confirmEmptyAllTrashDesc'),
      confirmLabel: loc.tr('emptyTrashAction'),
      cancelLabel: loc.tr('cancel'),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    RentCollectionService().emptyTrash(countryCode: countryCode);
    LegalClausesService().emptyTrash(countryCode: countryCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.tr('trashEmptiedSuccess')),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
