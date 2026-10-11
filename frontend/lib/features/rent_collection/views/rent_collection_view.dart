import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/create_rent_invoice_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/legal_warning_notice_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/rent_receipt_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tax_invoice_viewer_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';

/// Redesigned Material Design 3 Rent Collection & Automated Payouts View.
///
/// Fully adheres to the 5 Core Repository Standards:
/// 1. Trilingual Architecture (Arabic RTL Cairo, English LTR Inter, Hindi LTR Noto Sans) with zero language mixing.
/// 2. Dynamic Primary-Derived Hover Engine ([M3HoverColorScheme]).
/// 3. Official M3 Button Taxonomy & Connected Button Group ([TashilConnectedButtonGroup]).
/// 4. M3 Cards ([TashilCard.outlined] / [TashilCard.elevated]) with [TashilDivider.cardAction()] separating content from pinned action footer.
/// 5. Fully responsive layout across mobile, tablet, and desktop with zero overflow errors.
/// 6. Google M3 Motion & Transitions ([TashilMotionEasing], [TashilMotionDuration]).
class RentCollectionView extends StatefulWidget {
  final VoidCallback? onBack;
  final bool? showBackButton;
  final bool showTrashButtonInHeader;

  const RentCollectionView({
    super.key,
    this.onBack,
    this.showBackButton,
    this.showTrashButtonInHeader = false,
  });

  @override
  State<RentCollectionView> createState() => _RentCollectionViewState();
}

class _RentCollectionViewState extends State<RentCollectionView> {
  final _service = RentCollectionService();
  String _selectedFilter = 'all'; // 'all', 'paid', 'due_soon', 'overdue'
  String _viewMode = 'table'; // 'table' (default) or 'cards'
  bool _isTrashView = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncInvoices();
    PropertyLifecycleService().propertiesNotifier.addListener(_syncInvoices);
  }

  void _syncInvoices() {
    _service.syncFromProperties();
  }

  @override
  void dispose() {
    PropertyLifecycleService().propertiesNotifier.removeListener(_syncInvoices);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<String>(
      valueListenable: CountryController.currentCountry,
      builder: (context, countryCode, _) {
        final isUAE = countryCode == 'AE';
        final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
        final lang = LocaleController.languageCode;

        return ValueListenableBuilder<List<RentInvoiceModel>>(
          valueListenable: _service.invoicesNotifier,
          builder: (context, allInvoices, _) {
            // Filter by active country (Zero Country Leakage) and non-deleted
            final activeInvoices = allInvoices
                .where((inv) => !inv.isDeleted && inv.countryCode == countryCode)
                .toList();
            final deletedInvoices = allInvoices
                .where((inv) => inv.isDeleted && inv.countryCode == countryCode)
                .toList();

            final countryInvoices = activeInvoices;
            final deletedCount = deletedInvoices.length;

            // Counts for Connected Button Group segments
            final paidCount = countryInvoices.where((inv) => inv.status == 'paid').length;
            final dueSoonCount = countryInvoices.where((inv) => inv.status == 'due_soon').length;
            final overdueCount = countryInvoices.where((inv) => inv.status == 'overdue').length;

            // Financial KPIs
            final totalCollected = countryInvoices
                .where((inv) => inv.status == 'paid')
                .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

            final totalDueSoon = countryInvoices
                .where((inv) => inv.status == 'due_soon')
                .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

            final totalArrears = countryInvoices
                .where((inv) => inv.status == 'overdue')
                .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

            final netTransferredToOwners = countryInvoices
                .where((inv) => inv.status == 'paid' && inv.payoutStatus == 'transferred_to_owner')
                .fold<double>(0.0, (sum, inv) => sum + inv.netPayoutToOwner);

            // Filter by status & search
            final filteredInvoices = countryInvoices.where((inv) {
              if (_selectedFilter != 'all' && inv.status != _selectedFilter) return false;
              if (_searchCtrl.text.isNotEmpty) {
                final query = _searchCtrl.text.toLowerCase().trim();
                final matchNum = inv.invoiceNumber.toLowerCase().contains(query);
                final matchTenant = inv.tenant.name.toLowerCase().contains(query);
                final matchUnit = inv.unitNumber.toLowerCase().contains(query);
                final matchBuilding = inv.buildingName.toLowerCase().contains(query);
                if (!matchNum && !matchTenant && !matchUnit && !matchBuilding) return false;
              }
              return true;
            }).toList();

            return ValueListenableBuilder<Locale>(
              valueListenable: LocaleController.currentLocale,
              builder: (context, locale, _) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: PopScope(
                    canPop: true,
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) return;
                      _handleBack(context);
                    },
                    child: SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = constraints.maxWidth;
                          final isCompact = screenWidth < 768;

                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 16 : 28,
                              vertical: isCompact ? 20 : 28,
                            ),
                            child: _isTrashView
                                ? _buildTrashView(
                                    context: context,
                                    loc: loc,
                                    deletedInvoices: deletedInvoices,
                                    currency: currency,
                                    lang: lang,
                                    countryCode: countryCode,
                                    isCompact: isCompact,
                                    colorScheme: colorScheme,
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Header Section
                                      _buildHeader(
                                        context: context,
                                        loc: loc,
                                        isUAE: isUAE,
                                        isCompact: isCompact,
                                        deletedCount: deletedCount,
                                        colorScheme: colorScheme,
                                      ),
                                      const SizedBox(height: 24),

                                      // 2. M3 KPI Cards Grid
                                      _buildKpisGrid(
                                        loc: loc,
                                        totalCollected: totalCollected,
                                        totalDueSoon: totalDueSoon,
                                        totalArrears: totalArrears,
                                        netTransferred: netTransferredToOwners,
                                        currency: currency,
                                        lang: lang,
                                        colorScheme: colorScheme,
                                      ),
                                      const SizedBox(height: 24),

                                      // 3. Search and Connected Button Group Filter Bar
                                      _buildSearchAndFilterBar(
                                        loc: loc,
                                        screenWidth: screenWidth,
                                        colorScheme: colorScheme,
                                        allCount: countryInvoices.length,
                                        paidCount: paidCount,
                                        dueSoonCount: dueSoonCount,
                                        overdueCount: overdueCount,
                                      ),
                                      const SizedBox(height: 20),

                                      // 4. Invoices Display: M3 Table View (Default requested by user) or Fluid Motion Cards
                                      if (_viewMode == 'table')
                                        _buildInvoicesTable(
                                          context: context,
                                          loc: loc,
                                          invoices: filteredInvoices,
                                          currency: currency,
                                          lang: lang,
                                          screenWidth: screenWidth,
                                          colorScheme: colorScheme,
                                        )
                                      else
                                        TashilCardFilterMotion<RentInvoiceModel>(
                                          items: filteredInvoices,
                                          filterKey: '$_selectedFilter-${_searchCtrl.text.trim()}',
                                          spacing: 16.0,
                                          emptyState: _buildEmptyState(loc, colorScheme),
                                          itemBuilder: (context, inv, index) {
                                            return _buildInvoiceCard(
                                              context: context,
                                              loc: loc,
                                              inv: inv,
                                              currency: currency,
                                              lang: lang,
                                              screenWidth: screenWidth,
                                              colorScheme: colorScheme,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleBack(BuildContext context) {
    if (_isTrashView) {
      setState(() => _isTrashView = false);
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/investor-dashboard');
  }

  // --- 1. Header ---
  Widget _buildHeader({
    required BuildContext context,
    required AppLocalizations loc,
    required bool isUAE,
    required bool isCompact,
    required int deletedCount,
    required ColorScheme colorScheme,
  }) {
    final showBack = widget.showBackButton ??
        (Navigator.of(context).canPop() || Navigator.of(context, rootNavigator: true).canPop());
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final backButton = showBack
        ? TashilButton.tonal(
            onPressed: () => _handleBack(context),
            icon: isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            label: loc.tr('back'),
          )
        : null;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr('rentCollectionTitle'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 20 : 24,
            color: colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isUAE ? loc.tr('rentCollectionSubtitle_ae') : loc.tr('rentCollectionSubtitle_eg'),
          style: TextStyle(
            fontSize: isCompact ? 12 : 13,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );

    final showTrash = widget.showTrashButtonInHeader;

    final actionsBlock = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showTrash)
          TashilButton.tonal(
            onPressed: () => setState(() => _isTrashView = true),
            icon: Icons.auto_delete_outlined,
            label: '${loc.tr('deletedInvoicesTitle')}${deletedCount > 0 ? ' ($deletedCount)' : ''}',
          ),
        TashilButton(
          onPressed: () => CreateRentInvoiceDialog.show(context),
          icon: Icons.add_rounded,
          label: loc.tr('generateInvoiceBtn'),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backButton != null) ...[
            backButton,
            const SizedBox(height: 12),
          ],
          titleBlock,
          const SizedBox(height: 14),
          actionsBlock,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (backButton != null) ...[
                backButton,
                const SizedBox(width: 16),
              ],
              Expanded(child: titleBlock),
            ],
          ),
        ),
        const SizedBox(width: 16),
        actionsBlock,
      ],
    );
  }

  // --- 2. M3 KPI Cards Grid ---
  Widget _buildKpisGrid({
    required AppLocalizations loc,
    required double totalCollected,
    required double totalDueSoon,
    required double totalArrears,
    required double netTransferred,
    required String currency,
    required String lang,
    required ColorScheme colorScheme,
  }) {
    return TashilKpiGrid(
      cards: [
        TashilKpiCard(
          title: loc.tr('totalRentCollected'),
          value: '${CurrencyFormatter.formatAmount(totalCollected, langCode: lang)} $currency',
          subtitle: loc.tr('totalRentCollectedSubtitle'),
          icon: Icons.savings_rounded,
          subtitleIcon: Icons.check_circle_outline_rounded,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.surfaceContainerHigh,
        ),
        TashilKpiCard(
          title: loc.tr('dueSoonRent'),
          value: '${CurrencyFormatter.formatAmount(totalDueSoon, langCode: lang)} $currency',
          subtitle: loc.tr('dueSoonRentSubtitle'),
          icon: Icons.schedule_rounded,
          subtitleIcon: Icons.hourglass_bottom_rounded,
          iconColor: colorScheme.tertiary,
          iconBgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('overdueArrearsAndPenalties'),
          value: '${CurrencyFormatter.formatAmount(totalArrears, langCode: lang)} $currency',
          subtitle: loc.tr('overduePenaltiesSubtitle'),
          icon: Icons.warning_amber_rounded,
          subtitleIcon: Icons.notification_important_outlined,
          iconColor: colorScheme.error,
          iconBgColor: colorScheme.errorContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('netTransferredToOwnersKpi'),
          value: '${CurrencyFormatter.formatAmount(netTransferred, langCode: lang)} $currency',
          subtitle: loc.tr('netTransferredSubtitle'),
          icon: Icons.account_balance_rounded,
          subtitleIcon: Icons.verified_rounded,
          iconColor: colorScheme.secondary,
          iconBgColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  // --- 3. Search and Connected Button Group Filter Bar ---
  Widget _buildSearchAndFilterBar({
    required AppLocalizations loc,
    required double screenWidth,
    required ColorScheme colorScheme,
    required int allCount,
    required int paidCount,
    required int dueSoonCount,
    required int overdueCount,
  }) {
    final searchWidget = Container(
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: loc.tr('searchInvoicesPlaceholder'),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            TashilIconButton.close(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
              size: 28,
            ),
        ],
      ),
    );

    final connectedGroupWidget = TashilConnectedButtonGroup<String>(
      height: 44,
      selectedValue: _selectedFilter,
      onSelectionChanged: (val) => setState(() => _selectedFilter = val),
      segments: [
        TashilConnectedButtonSegment(
          value: 'all',
          label: loc.tr('filterAllInvoices'),
          icon: Icons.receipt_long_rounded,
          badge: '$allCount',
        ),
        TashilConnectedButtonSegment(
          value: 'paid',
          label: loc.tr('filterPaidInvoices'),
          icon: Icons.check_circle_rounded,
          badge: '$paidCount',
        ),
        TashilConnectedButtonSegment(
          value: 'due_soon',
          label: loc.tr('filterDueSoonInvoices'),
          icon: Icons.schedule_rounded,
          badge: '$dueSoonCount',
        ),
        TashilConnectedButtonSegment(
          value: 'overdue',
          label: loc.tr('filterOverdueInvoices'),
          icon: Icons.error_outline_rounded,
          badge: '$overdueCount',
        ),
      ],
    );

    final viewModeWidget = TashilConnectedButtonGroup<String>(
      height: 44,
      selectedValue: _viewMode,
      onSelectionChanged: (val) => setState(() => _viewMode = val),
      segments: [
        TashilConnectedButtonSegment(
          value: 'table',
          label: loc.tr('viewModeTable'),
          icon: Icons.table_chart_rounded,
        ),
        TashilConnectedButtonSegment(
          value: 'cards',
          label: loc.tr('viewModeCards'),
          icon: Icons.grid_view_rounded,
        ),
      ],
    );

    // Responsive arrangement
    if (screenWidth < 1180) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchWidget,
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: connectedGroupWidget,
              ),
              viewModeWidget,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: searchWidget,
        ),
        const SizedBox(width: 14),
        connectedGroupWidget,
        const SizedBox(width: 14),
        viewModeWidget,
      ],
    );
  }

  // --- 4. Invoice Card (M3 Outlined with Pinned Action Footer) ---
  Widget _buildInvoiceCard({
    required BuildContext context,
    required AppLocalizations loc,
    required RentInvoiceModel inv,
    required String currency,
    required String lang,
    required double screenWidth,
    required ColorScheme colorScheme,
  }) {
    final isPaid = inv.status == 'paid';
    final isOverdue = inv.status == 'overdue';

    Color statusBg = colorScheme.tertiaryContainer;
    Color statusText = colorScheme.onTertiaryContainer;
    IconData statusIcon = Icons.schedule_rounded;
    String statusLabel = loc.tr('statusDueSoon');

    if (isPaid) {
      statusBg = colorScheme.primaryContainer;
      statusText = colorScheme.onPrimaryContainer;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = loc.tr('statusPaid');
    } else if (isOverdue) {
      statusBg = colorScheme.errorContainer;
      statusText = colorScheme.onErrorContainer;
      statusIcon = Icons.error_rounded;
      statusLabel = '${loc.tr('statusOverdue')} (${inv.overdueDays} ${loc.tr('days')})';
    }

    final isMobile = screenWidth < 680;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TashilCard.outlined(
      enableHoverAnimation: true,
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      onTap: () => _showInvoiceDetailsDialog(
        context: context,
        loc: loc,
        inv: inv,
        currency: currency,
        lang: lang,
        colorScheme: colorScheme,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status & Invoice Number
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusText),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusText,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        inv.invoiceNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TashilIconButton.tonal(
                      icon: Icons.edit_outlined,
                      size: 28,
                      iconSize: 14,
                      tooltip: loc.tr('editInvoiceAction'),
                      onPressed: () => _showEditInvoiceDialog(
                        context: context,
                        loc: loc,
                        inv: inv,
                        currency: currency,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TashilIconButton.tonal(
                      icon: Icons.delete_outline_rounded,
                      size: 28,
                      iconSize: 14,
                      tooltip: loc.tr('moveToTrashAction'),
                      color: colorScheme.error,
                      backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.2),
                      onPressed: () => _confirmMoveToTrash(
                        context: context,
                        loc: loc,
                        inv: inv,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Row 2: Responsive Unit Specs & Tenant Details Grid
          _buildDetailsGrid(
            loc: loc,
            inv: inv,
            currency: currency,
            lang: lang,
            screenWidth: screenWidth,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),

          // Payout & Reminders Status Line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? Icons.account_balance_wallet_rounded : Icons.pending_actions_rounded,
                        size: 16,
                        color: isPaid ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isPaid
                              ? '${loc.tr('payoutTransferredToOwner')}: ${CurrencyFormatter.formatAmount(inv.netPayoutToOwner, langCode: lang)} $currency'
                              : '${loc.tr('scheduledPayoutToOwner')}: ${CurrencyFormatter.formatAmount(inv.netPayoutToOwner, langCode: lang)} $currency',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isPaid ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (inv.reminderCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${loc.tr('remindersSentCount')}: ${inv.reminderCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Official M3 Card Action Divider (DO Rule: Separating non-interactive content from action footer)
          const TashilDivider.cardAction(),
          const SizedBox(height: 12),

          // Row 3: Pinned Action Buttons Footer (Official M3 Connected Button Group)
          TashilConnectedButtonGroup<String>(
            height: 38.0,
            selectedValue: isPaid ? 'receipt' : 'pay',
            showCheckmark: false,
            onSelectionChanged: (action) {
              if (action == 'pay') {
                TenantCheckoutDialog.show(context, inv);
              } else if (action == 'remind') {
                _confirmSendWhatsAppReminder(
                  context: context,
                  loc: loc,
                  inv: inv,
                  colorScheme: colorScheme,
                  currency: currency,
                  lang: lang,
                );
              } else if (action == 'warning') {
                LegalWarningNoticeDialog.show(context, inv);
              } else if (action == 'receipt') {
                RentReceiptDialog.show(context, inv);
              } else if (action == 'invoice') {
                TaxInvoiceViewerDialog.show(context, inv);
              }
            },
            segments: [
              if (isPaid) ...[
                TashilConnectedButtonSegment(
                  value: 'receipt',
                  label: loc.tr('viewOfficialReceipt'),
                  icon: Icons.receipt_long_rounded,
                ),
                TashilConnectedButtonSegment(
                  value: 'invoice',
                  label: loc.tr('linkedTaxInvoice'),
                  icon: Icons.description_outlined,
                ),
              ] else ...[
                TashilConnectedButtonSegment(
                  value: 'pay',
                  label: loc.tr('payRentNowAction'),
                  icon: Icons.payment_rounded,
                ),
                TashilConnectedButtonSegment(
                  value: 'remind',
                  label: loc.tr('sendReminderWhatsApp'),
                  icon: Icons.send_to_mobile_rounded,
                ),
                if (isOverdue) ...[
                  TashilConnectedButtonSegment(
                    value: 'warning',
                    label: loc.tr('issueLegalWarningAction'),
                    icon: Icons.gavel_rounded,
                    activeColor: colorScheme.error,
                    activeForegroundColor: colorScheme.onError,
                    unselectedForegroundColor: colorScheme.error,
                    unselectedColor: colorScheme.error.withValues(
                      alpha: isDark ? 0.16 : 0.09,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Card Details Grid with calibrated breakpoints ---
  Widget _buildDetailsGrid({
    required AppLocalizations loc,
    required RentInvoiceModel inv,
    required String currency,
    required String lang,
    required double screenWidth,
    required ColorScheme colorScheme,
  }) {
    final unitItem = _buildCardDetailItem(
      label: loc.tr('unit'),
      value: '${inv.unitTitle} (${inv.unitNumber})',
      icon: Icons.apartment_rounded,
      colorScheme: colorScheme,
    );

    final tenantItem = _buildCardDetailItem(
      label: loc.tr('tenant'),
      value: inv.tenant.name,
      subtitle: inv.tenant.phone,
      icon: Icons.person_outline_rounded,
      colorScheme: colorScheme,
    );

    final landlordItem = _buildCardDetailItem(
      label: loc.tr('landlord'),
      value: inv.owner.name,
      subtitle: inv.owner.bankName,
      icon: Icons.account_balance_outlined,
      colorScheme: colorScheme,
    );

    final totalRentItem = _buildCardDetailItem(
      label: loc.tr('totalRentValue'),
      value: '${CurrencyFormatter.formatAmount(inv.totalAmountDue, langCode: lang)} $currency',
      icon: Icons.payments_outlined,
      colorScheme: colorScheme,
      isHighlight: true,
    );

    if (screenWidth < 640) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          unitItem,
          const SizedBox(height: 8),
          tenantItem,
          const SizedBox(height: 8),
          landlordItem,
          const SizedBox(height: 8),
          totalRentItem,
        ],
      );
    } else if (screenWidth < 980) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: unitItem),
              const SizedBox(width: 12),
              Expanded(child: tenantItem),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: landlordItem),
              const SizedBox(width: 12),
              Expanded(child: totalRentItem),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: unitItem),
        const SizedBox(width: 12),
        Expanded(child: tenantItem),
        const SizedBox(width: 12),
        Expanded(child: landlordItem),
        const SizedBox(width: 12),
        Expanded(child: totalRentItem),
      ],
    );
  }

  Widget _buildCardDetailItem({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required ColorScheme colorScheme,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isHighlight
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isHighlight ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isHighlight ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations loc, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.tr('noInvoicesFound'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.tr('noInvoicesSubtitle'),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Property Type Badge with semantic icon and high contrast styling
  Widget _buildPropertyTypeBadge({
    required String typeCode,
    required AppLocalizations loc,
    required bool isDark,
  }) {
    final lower = typeCode.toLowerCase().trim();
    final isVilla = lower.contains('villa') || lower.contains('فيلا');
    final isOffice = lower.contains('office') || lower.contains('مكتب');
    final isCommercial = lower.contains('commercial') || lower.contains('تجاري');
    final isChalet = lower.contains('chalet') || lower.contains('شاليه');
    final isDuplex = lower.contains('duplex') || lower.contains('دوبلكس');
    final isStudio = lower.contains('studio') || lower.contains('استوديو') || lower.contains('استديو');

    Color bg;
    Color border;
    Color text;
    String label;
    IconData icon;

    if (isVilla) {
      bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5);
      border = isDark ? const Color(0xFF10B981).withValues(alpha: 0.70) : const Color(0xFFA7F3D0);
      text = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
      label = loc.tr('propTypeVilla');
      icon = Icons.villa_rounded;
    } else if (isOffice) {
      bg = isDark ? const Color(0xFF134E4A).withValues(alpha: 0.35) : const Color(0xFFF0FDFA);
      border = isDark ? const Color(0xFF14B8A6).withValues(alpha: 0.70) : const Color(0xFF99F6E4);
      text = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
      label = loc.tr('propTypeOffice');
      icon = Icons.business_center_rounded;
    } else if (isCommercial) {
      bg = isDark ? const Color(0xFF701A75).withValues(alpha: 0.35) : const Color(0xFFFDF4FF);
      border = isDark ? const Color(0xFFD946EF).withValues(alpha: 0.70) : const Color(0xFFF5D0FE);
      text = isDark ? const Color(0xFFF0ABFC) : const Color(0xFFA21CAF);
      label = loc.tr('propTypeCommercial');
      icon = Icons.storefront_rounded;
    } else if (isChalet) {
      bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB);
      border = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.70) : const Color(0xFFFDE68A);
      text = isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
      label = loc.tr('propTypeChalet');
      icon = Icons.beach_access_rounded;
    } else if (isDuplex) {
      bg = isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFEEF2FF);
      border = isDark ? const Color(0xFF6366F1).withValues(alpha: 0.70) : const Color(0xFFC7D2FE);
      text = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
      label = loc.tr('propTypeDuplex');
      icon = Icons.holiday_village_rounded;
    } else if (isStudio) {
      bg = isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.35) : const Color(0xFFF5F3FF);
      border = isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.70) : const Color(0xFFDDD6FE);
      text = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9);
      label = loc.tr('propTypeStudio');
      icon = Icons.single_bed_rounded;
    } else {
      bg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF);
      border = isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.70) : const Color(0xFFBFDBFE);
      text = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
      label = loc.tr('propTypeApartment');
      icon = Icons.apartment_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// M3 Connected Action Button Group for Table Rows (Details | Edit | Delete)
  Widget _buildInvoiceActionsConnectedGroup({
    required BuildContext context,
    required RentInvoiceModel inv,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required String currency,
    required String lang,
  }) {
    final outerRadius = BorderRadius.circular(20);

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: outerRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Details Action Pill
          _TableConnectedActionIconPill(
            icon: Icons.visibility_outlined,
            tooltip: loc.tr('viewDetailsBtn'),
            foregroundColor: colorScheme.onSurface,
            size: 31.0,
            onTap: () => _showInvoiceDetailsDialog(
              context: context,
              loc: loc,
              inv: inv,
              currency: currency,
              lang: lang,
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(width: 4.0),
          // 2. Edit Action Pill
          _TableConnectedActionIconPill(
            icon: Icons.edit_outlined,
            tooltip: loc.tr('editInvoiceAction'),
            foregroundColor: colorScheme.onSurface,
            size: 31.0,
            onTap: () => _showEditInvoiceDialog(
              context: context,
              loc: loc,
              inv: inv,
              currency: currency,
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(width: 4.0),
          // 3. Move to Trash Action Pill
          _TableConnectedActionIconPill(
            icon: Icons.delete_outline_rounded,
            tooltip: loc.tr('moveToTrashAction'),
            foregroundColor: colorScheme.error,
            hoverColor: colorScheme.error,
            size: 31.0,
            onTap: () => _confirmMoveToTrash(
              context: context,
              loc: loc,
              inv: inv,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  /// M3 Connected Button Group for Payment & Reminder (Pay + WhatsApp Reminder / Official Receipt)
  Widget _buildPaymentReminderConnectedGroup({
    required BuildContext context,
    required RentInvoiceModel inv,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
    required bool isPaid,
    required bool isOverdue,
    required String currency,
    required String lang,
  }) {
    final outerRadius = BorderRadius.circular(20);

    if (isPaid) {
      return Container(
        height: 38,
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: outerRadius,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        child: _TableConnectedActionPill(
          icon: Icons.receipt_long_rounded,
          label: loc.tr('viewOfficialReceipt'),
          isFilled: true,
          filledColor: colorScheme.secondaryContainer,
          filledTextColor: colorScheme.onSecondaryContainer,
          height: 31.0,
          onTap: () => RentReceiptDialog.show(context, inv),
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: outerRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Pay Pill (Filled Primary stadium capsule matching Connected Button Group)
          _TableConnectedActionPill(
            icon: Icons.payment_rounded,
            label: loc.tr('payRentNowAction'),
            isFilled: true,
            filledColor: colorScheme.primary,
            filledTextColor: colorScheme.onPrimary,
            height: 31.0,
            onTap: () => TenantCheckoutDialog.show(context, inv),
          ),
          const SizedBox(width: 5.0),
          // 2. Remind WhatsApp Pill (Shaded stadium capsule with confirmation dialog)
          _TableConnectedActionPill(
            icon: Icons.send_to_mobile_rounded,
            label: loc.tr('sendReminderWhatsApp'),
            isFilled: false,
            height: 31.0,
            onTap: () => _confirmSendWhatsAppReminder(
              context: context,
              loc: loc,
              inv: inv,
              colorScheme: colorScheme,
              currency: currency,
              lang: lang,
            ),
          ),
          if (isOverdue) ...[
            const SizedBox(width: 5.0),
            // 3. Legal Warning Pill
            _TableConnectedActionPill(
              icon: Icons.gavel_rounded,
              label: loc.tr('issueLegalWarningAction'),
              isFilled: true,
              filledColor: colorScheme.errorContainer,
              filledTextColor: colorScheme.onErrorContainer,
              height: 31.0,
              onTap: () => LegalWarningNoticeDialog.show(context, inv),
            ),
          ],
        ],
      ),
    );
  }

  // --- 5. High-Density M3 Invoices Table ---
  Widget _buildInvoicesTable({
    required BuildContext context,
    required AppLocalizations loc,
    required List<RentInvoiceModel> invoices,
    required String currency,
    required String lang,
    required double screenWidth,
    required ColorScheme colorScheme,
  }) {
    if (invoices.isEmpty) {
      return _buildEmptyState(loc, colorScheme);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TashilCard.outlined(
      borderRadius: BorderRadius.circular(14),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      loc.tr('navCollection'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${invoices.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const TashilDivider.fullWidth(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: screenWidth < 1180 ? 1180 : screenWidth - 56,
              ),
              child: DataTable(
                headingRowHeight: 50,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 74,
                horizontalMargin: 18,
                columnSpacing: 18,
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderUnitAndInvoice'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderTenant'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('landlord'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderDueDate'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderAmount'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderPaymentStatus'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderPayout'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderPaymentAndReminder'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      loc.tr('tableHeaderActions'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    ),
                  ),
                ],
                rows: invoices.map((inv) {
                  final isPaid = inv.status == 'paid';
                  final isOverdue = inv.status == 'overdue';

                  Color statusBg = colorScheme.tertiaryContainer;
                  Color statusText = colorScheme.onTertiaryContainer;
                  IconData statusIcon = Icons.schedule_rounded;
                  String statusLabel = loc.tr('statusDueSoon');

                  if (isPaid) {
                    statusBg = colorScheme.primaryContainer;
                    statusText = colorScheme.onPrimaryContainer;
                    statusIcon = Icons.check_circle_rounded;
                    statusLabel = loc.tr('statusPaid');
                  } else if (isOverdue) {
                    statusBg = colorScheme.errorContainer;
                    statusText = colorScheme.onErrorContainer;
                    statusIcon = Icons.error_rounded;
                    statusLabel = '${loc.tr('statusOverdue')} (${inv.overdueDays} ${loc.tr('days')})';
                  }

                  return DataRow(
                    onSelectChanged: (_) => _showInvoiceDetailsDialog(
                      context: context,
                      loc: loc,
                      inv: inv,
                      currency: currency,
                      lang: lang,
                      colorScheme: colorScheme,
                    ),
                    cells: [
                      // 1. Unit Type Chip + Location Badge & Invoice Number
                      DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Property Type Chip (e.g. شقة سكنية)
                                  _buildPropertyTypeBadge(
                                    typeCode: inv.propertyTypeCode,
                                    loc: loc,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  // Location with Icon (e.g. حي الجمرك - بحري، الإسكندرية)
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 180),
                                    child: Text(
                                      inv.district.isNotEmpty ? inv.district : inv.buildingName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tag_rounded, size: 12, color: colorScheme.primary.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    inv.invoiceNumber,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  if (inv.unitNumber.isNotEmpty)
                                    Text(
                                      ' • ${inv.unitNumber}',
                                      style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 2. Tenant
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.tenant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            Text(
                              inv.tenant.phone,
                              style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      // 3. Landlord / Owner
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.owner.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            Text(
                              inv.owner.bankName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      // 4. Due Date
                      DataCell(
                        Text(
                          '${inv.dueDate.year}-${inv.dueDate.month.toString().padLeft(2, '0')}-${inv.dueDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                        ),
                      ),
                      // 5. Total Amount
                      DataCell(
                        Text(
                          '${CurrencyFormatter.formatAmount(inv.totalAmountDue, langCode: lang)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // 6. Status Chip
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusText),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 7. Payout Status
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              inv.payoutStatus == 'transferred_to_owner'
                                  ? Icons.account_balance_rounded
                                  : Icons.history_toggle_off_rounded,
                              size: 14,
                              color: inv.payoutStatus == 'transferred_to_owner'
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              inv.payoutStatus == 'transferred_to_owner'
                                  ? '${CurrencyFormatter.formatAmount(inv.netPayoutToOwner, langCode: lang)} $currency'
                                  : loc.tr('scheduledPayoutToOwner'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: inv.payoutStatus == 'transferred_to_owner'
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 8. Payment & Reminder Cell
                      DataCell(
                        _buildPaymentReminderConnectedGroup(
                          context: context,
                          inv: inv,
                          loc: loc,
                          colorScheme: colorScheme,
                          isPaid: isPaid,
                          isOverdue: isOverdue,
                          currency: currency,
                          lang: lang,
                        ),
                      ),
                      // 9. Actions Cell (Details | Edit | Delete)
                      DataCell(
                        _buildInvoiceActionsConnectedGroup(
                          context: context,
                          inv: inv,
                          loc: loc,
                          colorScheme: colorScheme,
                          currency: currency,
                          lang: lang,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Comprehensive M3 Invoice Details Modal ---
  void _showInvoiceDetailsDialog({
    required BuildContext context,
    required AppLocalizations loc,
    required RentInvoiceModel inv,
    required String currency,
    required String lang,
    required ColorScheme colorScheme,
  }) {
    final isPaid = inv.status == 'paid';
    final isOverdue = inv.status == 'overdue';

    Color statusBg = colorScheme.tertiaryContainer;
    Color statusText = colorScheme.onTertiaryContainer;
    IconData statusIcon = Icons.schedule_rounded;
    String statusLabel = loc.tr('statusDueSoon');

    if (isPaid) {
      statusBg = colorScheme.primaryContainer;
      statusText = colorScheme.onPrimaryContainer;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = loc.tr('statusPaid');
    } else if (isOverdue) {
      statusBg = colorScheme.errorContainer;
      statusText = colorScheme.onErrorContainer;
      statusIcon = Icons.error_rounded;
      statusLabel = '${loc.tr('statusOverdue')} (${inv.overdueDays} ${loc.tr('days')})';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Invoice No + Status + Shaded Close X
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inv.invoiceNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${loc.tr('tableHeaderDueDate')}: ${inv.dueDate.year}-${inv.dueDate.month.toString().padLeft(2, '0')}-${inv.dueDate.day.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 14, color: statusText),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(color: statusText, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TashilIconButton.close(
                              size: 32,
                              iconSize: 16,
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TashilDivider.fullWidth(),
                    const SizedBox(height: 16),

                    // Section 1: Financial Breakdown
                    Text(
                      loc.tr('financialBreakdownTitle'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _buildModalRow(
                            label: loc.tr('baseRentAmount'),
                            value: '${CurrencyFormatter.formatAmount(inv.baseAmount, langCode: lang)} $currency',
                            colorScheme: colorScheme,
                          ),
                          if (inv.latePenaltyAmount > 0) ...[
                            const SizedBox(height: 8),
                            _buildModalRow(
                              label: loc.tr('delayPenalties'),
                              value: '+ ${CurrencyFormatter.formatAmount(inv.latePenaltyAmount, langCode: lang)} $currency',
                              valueColor: colorScheme.error,
                              colorScheme: colorScheme,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildModalRow(
                            label: loc.tr('platformFees'),
                            value: '- ${CurrencyFormatter.formatAmount(inv.platformFeeAmount, langCode: lang)} $currency',
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 10),
                          TashilDivider.fullWidth(),
                          const SizedBox(height: 10),
                          _buildModalRow(
                            label: loc.tr('netBankPayout'),
                            value: '${CurrencyFormatter.formatAmount(inv.netPayoutToOwner, langCode: lang)} $currency',
                            isBold: true,
                            valueColor: colorScheme.primary,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 8),
                          _buildModalRow(
                            label: loc.tr('tableHeaderPayout'),
                            value: inv.payoutStatus == 'transferred_to_owner'
                                ? loc.tr('payoutTransferredToOwner')
                                : loc.tr('scheduledPayoutToOwner'),
                            valueColor: inv.payoutStatus == 'transferred_to_owner'
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Property & Contract Info
                    Text(
                      loc.tr('tableHeaderUnit'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.apartment_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${inv.unitTitle} (${inv.unitNumber})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(inv.buildingName, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Tenant Info
                    Text(
                      loc.tr('tableHeaderTenant'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inv.tenant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${inv.tenant.phone} • ${loc.tr('nationalId')}: ${inv.tenant.idNumber}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TashilDivider.cardAction(),
                    const SizedBox(height: 14),

                    // Action Buttons Footer
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (isPaid) ...[
                          TashilButton(
                            variant: TashilButtonVariant.filled,
                            icon: Icons.receipt_rounded,
                            label: loc.tr('viewOfficialReceipt'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              RentReceiptDialog.show(context, inv);
                            },
                          ),
                          TashilButton(
                            variant: TashilButtonVariant.outlined,
                            icon: Icons.description_outlined,
                            label: loc.tr('linkedTaxInvoice'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              TaxInvoiceViewerDialog.show(context, inv);
                            },
                          ),
                        ] else ...[
                          TashilButton(
                            variant: TashilButtonVariant.filled,
                            icon: Icons.payment_rounded,
                            label: loc.tr('payRentNowAction'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              TenantCheckoutDialog.show(context, inv);
                            },
                          ),
                          TashilButton(
                            variant: TashilButtonVariant.tonal,
                            icon: Icons.send_to_mobile_rounded,
                            label: loc.tr('sendReminderWhatsApp'),
                            onPressed: () => _confirmSendWhatsAppReminder(
                              context: context,
                              loc: loc,
                              inv: inv,
                              colorScheme: colorScheme,
                              currency: currency,
                              lang: lang,
                            ),
                          ),
                          if (isOverdue)
                            TashilButton(
                              variant: TashilButtonVariant.tonal,
                              icon: Icons.gavel_rounded,
                              label: loc.tr('issueLegalWarningAction'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                LegalWarningNoticeDialog.show(context, inv);
                              },
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalRow({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13.5 : 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // --- 7. Dedicated Trash / Recycle Bin View (المحذوفات) ---
  Widget _buildTrashView({
    required BuildContext context,
    required AppLocalizations loc,
    required List<RentInvoiceModel> deletedInvoices,
    required String currency,
    required String lang,
    required String countryCode,
    required bool isCompact,
    required ColorScheme colorScheme,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trash Header with Back Button + Title + Empty Trash Action
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TashilButton.tonal(
                  onPressed: () => setState(() => _isTrashView = false),
                  icon: isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  label: loc.tr('backToActiveInvoices'),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_delete_outlined, color: colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('deletedInvoicesTitle'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 20 : 24,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deletedInvoices.length} ${loc.tr('filterAllInvoices')}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            if (deletedInvoices.isNotEmpty)
              TashilButton(
                variant: TashilButtonVariant.outlined,
                icon: Icons.delete_sweep_rounded,
                label: loc.tr('emptyTrashAction'),
                onPressed: () => _confirmEmptyTrash(context, loc, countryCode, colorScheme),
              ),
          ],
        ),
        const SizedBox(height: 18),

        // Informational 7-Day Auto-Purge Policy Banner
        Container(
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
                  loc.tr('deletedInvoicesDesc'),
                  style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // List / Empty State
        if (deletedInvoices.isEmpty)
          Center(
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
                    child: Icon(Icons.delete_sweep_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.tr('noDeletedInvoicesTitle'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tr('noDeletedInvoicesDesc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  TashilButton.tonal(
                    icon: isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                    label: loc.tr('backToActiveInvoices'),
                    onPressed: () => setState(() => _isTrashView = false),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deletedInvoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final inv = deletedInvoices[index];
              return TashilCard.outlined(
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  inv.unitTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Countdown Chip
                              Container(
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
                                      '${loc.tr('remainingDaysForAutoDelete')} ${inv.remainingDaysBeforePermanentDelete} ${loc.tr('daysCountdown')}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${inv.invoiceNumber} • ${inv.tenant.name} • ${CurrencyFormatter.formatAmount(inv.totalAmountDue, langCode: lang)} $currency',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TashilButton(
                          variant: TashilButtonVariant.filled,
                          height: 34.0,
                          icon: Icons.restore_rounded,
                          label: loc.tr('restoreShort'),
                          onPressed: () {
                            _service.restoreInvoice(inv.id);
                            TashilSnackBar.showSuccess(
                              context: context,
                              message: loc.tr('invoiceRestoredSuccess'),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        TashilIconButton.tonal(
                          icon: Icons.delete_forever_rounded,
                          size: 34,
                          iconSize: 16,
                          tooltip: loc.tr('deletePermanentlyAction'),
                          color: colorScheme.error,
                          backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.2),
                          onPressed: () => _confirmPermanentlyDelete(context, loc, inv, colorScheme),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- 8. Edit Invoice Dialog ---
  void _showEditInvoiceDialog({
    required BuildContext context,
    required AppLocalizations loc,
    required RentInvoiceModel inv,
    required String currency,
    required ColorScheme colorScheme,
  }) {
    final amountController = TextEditingController(text: inv.baseAmount.toStringAsFixed(0));
    final notesController = TextEditingController(text: inv.notes ?? '');
    DateTime selectedDueDate = inv.dueDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.edit_note_rounded, color: colorScheme.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('editInvoiceTitle'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    inv.invoiceNumber,
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          TashilIconButton.close(
                            size: 32,
                            iconSize: 16,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TashilDivider.fullWidth(),
                      const SizedBox(height: 16),

                      // Base Rent Amount Field
                      Text(
                        loc.tr('baseRentAmount'),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: currency,
                          prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Due Date Picker Field
                      Text(
                        loc.tr('tableHeaderDueDate'),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDueDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${selectedDueDate.year}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              Icon(Icons.edit_calendar_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes Field
                      Text(
                        loc.tr('invoiceNotes'),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: loc.tr('invoiceNotesOptional'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TashilDivider.cardAction(),
                      const SizedBox(height: 14),

                      // Footer Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TashilButton.text(
                            label: loc.tr('cancel'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const SizedBox(width: 8),
                          TashilButton(
                            variant: TashilButtonVariant.filled,
                            icon: Icons.check_rounded,
                            label: loc.tr('saveChangesAction'),
                            onPressed: () {
                              final amount = double.tryParse(amountController.text.trim()) ?? inv.baseAmount;
                              _service.updateInvoice(
                                invoiceId: inv.id,
                                baseAmount: amount,
                                dueDate: selectedDueDate,
                                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              );
                              Navigator.pop(ctx);
                              TashilSnackBar.showSuccess(
                                context: context,
                                message: loc.tr('invoiceUpdatedSuccess'),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 9. Confirmation Dialogs ---

  /// Official M3 Connected Button Group for Dialog Action Footers (Cancel + Confirm/Delete)
  Widget _buildDialogConnectedActionGroup({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String cancelLabel,
    required String confirmLabel,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    IconData? confirmIcon,
    Color? confirmColor,
    Color? confirmTextColor,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TableConnectedActionPill(
            label: cancelLabel,
            height: 33.0,
            isFilled: false,
            onTap: onCancel,
          ),
          const SizedBox(width: 4.0),
          _TableConnectedActionPill(
            icon: confirmIcon,
            label: confirmLabel,
            height: 33.0,
            isFilled: true,
            filledColor: confirmColor ?? colorScheme.primary,
            filledTextColor: confirmTextColor ?? colorScheme.onPrimary,
            onTap: onConfirm,
          ),
        ],
      ),
    );
  }

  void _confirmMoveToTrash({
    required BuildContext context,
    required AppLocalizations loc,
    required RentInvoiceModel inv,
    required ColorScheme colorScheme,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return TashilAlertDialog(
          title: loc.tr('confirmMoveToTrashTitle'),
          contentText: loc.tr('confirmMoveToTrashDesc'),
          iconData: Icons.delete_outline_rounded,
          actions: [
            _buildDialogConnectedActionGroup(
              context: context,
              colorScheme: colorScheme,
              cancelLabel: loc.tr('cancel'),
              confirmLabel: loc.tr('deleteAction'),
              confirmIcon: Icons.delete_rounded,
              confirmColor: colorScheme.error,
              confirmTextColor: colorScheme.onError,
              onCancel: () => Navigator.pop(ctx),
              onConfirm: () {
                Navigator.pop(ctx);
                _service.softDeleteInvoice(inv.id);
                TashilSnackBar.show(
                  context: context,
                  message: loc.tr('invoiceMovedToTrashSuccess'),
                  action: TashilSnackBarAction(
                    label: loc.tr('restoreShort'),
                    onPressed: () => _service.restoreInvoice(inv.id),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmPermanentlyDelete(
    BuildContext context,
    AppLocalizations loc,
    RentInvoiceModel inv,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return TashilAlertDialog(
          title: loc.tr('confirmDeletePermanentlyTitle'),
          contentText: loc.tr('confirmDeletePermanentlyDesc'),
          iconData: Icons.warning_amber_rounded,
          actions: [
            _buildDialogConnectedActionGroup(
              context: context,
              colorScheme: colorScheme,
              cancelLabel: loc.tr('cancel'),
              confirmLabel: loc.tr('deletePermanentlyAction'),
              confirmIcon: Icons.delete_forever_rounded,
              confirmColor: colorScheme.error,
              confirmTextColor: colorScheme.onError,
              onCancel: () => Navigator.pop(ctx),
              onConfirm: () {
                Navigator.pop(ctx);
                _service.permanentlyDeleteInvoice(inv.id);
                TashilSnackBar.showSuccess(
                  context: context,
                  message: loc.tr('invoicePermanentlyDeletedSuccess'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmSendWhatsAppReminder({
    required BuildContext context,
    required AppLocalizations loc,
    required RentInvoiceModel inv,
    required ColorScheme colorScheme,
    required String currency,
    required String lang,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return TashilAlertDialog(
          title: loc.tr('confirmSendReminderTitle'),
          iconData: Icons.send_to_mobile_rounded,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('confirmSendReminderDesc'),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inv.tenant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          inv.tenant.phone,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const TashilDivider.fullWidth(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              loc.tr('tableHeaderAmount'),
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        Text(
                          '${CurrencyFormatter.formatAmount(inv.totalAmountDue, langCode: lang)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            _buildDialogConnectedActionGroup(
              context: context,
              colorScheme: colorScheme,
              cancelLabel: loc.tr('cancel'),
              confirmLabel: loc.tr('sendReminderAction'),
              confirmIcon: Icons.send_rounded,
              confirmColor: colorScheme.primary,
              confirmTextColor: colorScheme.onPrimary,
              onCancel: () => Navigator.pop(ctx),
              onConfirm: () {
                Navigator.pop(ctx);
                RentCollectionService().sendReminder(inv.id);
                TashilSnackBar.showSuccess(
                  context: context,
                  message: loc.tr('reminderSentViaWhatsAppSuccess'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmEmptyTrash(
    BuildContext context,
    AppLocalizations loc,
    String countryCode,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return TashilAlertDialog(
          title: loc.tr('emptyTrashAction'),
          contentText: loc.tr('emptyTrashConfirmDesc'),
          iconData: Icons.delete_sweep_rounded,
          actions: [
            TashilButton.text(
              label: loc.tr('cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            TashilButton(
              variant: TashilButtonVariant.filled,
              icon: Icons.delete_sweep_rounded,
              label: loc.tr('emptyTrashAction'),
              onPressed: () {
                Navigator.pop(ctx);
                _service.emptyTrash(countryCode: countryCode);
                TashilSnackBar.showSuccess(
                  context: context,
                  message: loc.tr('trashEmptiedSuccess'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Official M3 Table Action Pill for connected button groups
class _TableConnectedActionPill extends StatefulWidget {
  final IconData? icon;
  final String label;
  final bool isFilled;
  final Color? filledColor;
  final Color? filledTextColor;
  final VoidCallback onTap;
  final double height;

  const _TableConnectedActionPill({
    this.icon,
    required this.label,
    required this.onTap,
    this.isFilled = false,
    this.filledColor,
    this.filledTextColor,
    this.height = 31.0,
  });

  @override
  State<_TableConnectedActionPill> createState() => _TableConnectedActionPillState();
}

class _TableConnectedActionPillState extends State<_TableConnectedActionPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseFilledBg = widget.filledColor ?? colorScheme.primary;
    final baseFilledFg = widget.filledTextColor ?? colorScheme.onPrimary;

    final hoveredFilledBg = isDark
        ? (Color.lerp(baseFilledBg, Colors.white, 0.12) ?? baseFilledBg)
        : (Color.lerp(baseFilledBg, Colors.black, 0.10) ?? baseFilledBg);

    final restingUnselectedBg =
        colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.70 : 0.85);

    final hoveredUnselectedBg = Color.alphaBlend(
      (widget.filledColor ?? colorScheme.primary).withValues(alpha: isDark ? 0.22 : 0.14),
      restingUnselectedBg,
    );

    final bg = widget.isFilled
        ? (_isHovered ? hoveredFilledBg : baseFilledBg)
        : (_isHovered ? hoveredUnselectedBg : restingUnselectedBg);

    final fg = widget.isFilled ? baseFilledFg : colorScheme.onSurface;

    final border = widget.isFilled
        ? null
        : Border.all(
            color: _isHovered
                ? (widget.filledColor ?? colorScheme.primary).withValues(alpha: isDark ? 0.50 : 0.40)
                : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.40 : 0.50),
            width: 1.0,
          );

    final shadow = widget.isFilled
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.20 : 0.12),
              blurRadius: _isHovered ? 4.0 : 2.5,
              offset: Offset(0, _isHovered ? 2.0 : 1.0),
            ),
          ]
        : null;

    final radius = BorderRadius.circular(widget.height / 2);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: widget.height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: border,
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 14, color: fg),
                    const SizedBox(width: 5.0),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: widget.isFilled ? FontWeight.bold : FontWeight.w600,
                      color: fg,
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

/// Official M3 Table Action Icon Pill for connected button groups
class _TableConnectedActionIconPill extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color? foregroundColor;
  final Color? hoverColor;
  final VoidCallback onTap;
  final double size;

  const _TableConnectedActionIconPill({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.foregroundColor,
    this.hoverColor,
    this.size = 31.0,
  });

  @override
  State<_TableConnectedActionIconPill> createState() => _TableConnectedActionIconPillState();
}

class _TableConnectedActionIconPillState extends State<_TableConnectedActionIconPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fg = widget.foregroundColor ?? colorScheme.onSurface;
    final hoverTint = widget.hoverColor ?? fg;

    final bg = _isHovered
        ? hoverTint.withValues(alpha: isDark ? 0.20 : 0.12)
        : colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.60 : 0.75);

    final border = Border.all(
      color: _isHovered
          ? hoverTint.withValues(alpha: isDark ? 0.50 : 0.40)
          : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.45),
      width: 1.0,
    );

    final radius = BorderRadius.circular(widget.size / 2);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: border,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onTap,
              child: Center(
                child: Icon(widget.icon, size: 15, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


