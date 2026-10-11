import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/create_rent_invoice_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/legal_warning_notice_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/rent_receipt_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tax_invoice_viewer_dialog.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';

class OwnerFinancialsView extends StatefulWidget {
  const OwnerFinancialsView({super.key});

  @override
  State<OwnerFinancialsView> createState() => _OwnerFinancialsViewState();
}

class _OwnerFinancialsViewState extends State<OwnerFinancialsView> {
  int _masterTab = 0; // 0: Rent Invoices & Electronic Collection, 1: Arrears & Legal Notices, 2: Bank Payouts Ledger
  String _invoiceFilter = 'all'; // 'all', 'paid', 'due_soon', 'overdue'
  String? _expandedPayoutRef;
  final _searchController = TextEditingController();
  final _rentService = RentCollectionService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isMobile = ResponsiveLayout.isMobile(context);

        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, countryCode, _) {
            final isUAE = countryCode == 'AE';
            final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
            final lang = locale.languageCode;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 28,
                vertical: isMobile ? 20 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Master Segmented Navigation Bar (Official M3 Connected Button Group - Seamlessly integrated into page canvas)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TashilConnectedButtonGroup<int>(
                      height: 40.0,
                      selectedValue: _masterTab,
                      showCheckmark: false,
                      onSelectionChanged: (index) => setState(() => _masterTab = index),
                      segments: [
                        TashilConnectedButtonSegment<int>(
                          value: 0,
                          label: loc.tr('rentInvoicingAndCollectionTab'),
                          icon: Icons.receipt_long_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 1,
                          label: loc.tr('arrearsAndLegalNoticesTab'),
                          icon: Icons.gavel_rounded,
                        ),
                        TashilConnectedButtonSegment<int>(
                          value: 2,
                          label: loc.tr('recentPayouts'),
                          icon: Icons.account_balance_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab 0: Rent Invoicing & Electronic Collection Hub
                  if (_masterTab == 0)
                    _buildRentInvoicingHub(context, currency, lang, loc, isMobile, countryCode, colorScheme)

                  // Tab 1: Arrears & Legal Notices
                  else if (_masterTab == 1)
                    _buildArrearsAndLegalNotices(context, currency, lang, loc, isMobile, countryCode, colorScheme)

                  // Tab 2: Bank Payouts Ledger
                  else
                    _buildPayoutsTab(currency, lang, loc, colorScheme, countryCode),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRentInvoicingHub(
    BuildContext context,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    String currentCountry,
    ColorScheme colorScheme,
  ) {
    return ValueListenableBuilder<List<RentInvoiceModel>>(
      valueListenable: _rentService.invoicesNotifier,
      builder: (context, allInvoices, _) {
        final countryInvoices = allInvoices.where((inv) => inv.countryCode == currentCountry).toList();

        // Calculate Overview KPIs
        final totalCollected = countryInvoices
            .where((inv) => inv.status == 'paid')
            .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

        final totalPending = countryInvoices
            .where((inv) => inv.status == 'due_soon')
            .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

        final totalOverdue = countryInvoices
            .where((inv) => inv.status == 'overdue')
            .fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);

        // Apply filters & search
        final filteredInvoices = countryInvoices.where((inv) {
          if (_invoiceFilter != 'all' && inv.status != _invoiceFilter) {
            return false;
          }
          final q = _searchController.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            final matchTenant = inv.tenant.name.toLowerCase().contains(q);
            final matchUnit = inv.unitTitle.toLowerCase().contains(q) || inv.unitNumber.contains(q);
            final matchInv = inv.invoiceNumber.toLowerCase().contains(q);
            return matchTenant || matchUnit || matchInv;
          }
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header & Quick Actions Bar (Title on Start, Issue Invoice Button on End/Far Left)
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('rentInvoicingAndCollectionHub'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.tr('rentInvoicingHubSubtitle'),
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TashilButton(
                      onPressed: () => CreateRentInvoiceDialog.show(context),
                      icon: Icons.add_rounded,
                      label: loc.tr('issueNewRentInvoice'),
                      variant: TashilButtonVariant.filled,
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('rentInvoicingAndCollectionHub'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.tr('rentInvoicingHubSubtitle'),
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    TashilButton(
                      onPressed: () => CreateRentInvoiceDialog.show(context),
                      icon: Icons.add_rounded,
                      label: loc.tr('issueNewRentInvoice'),
                      variant: TashilButtonVariant.filled,
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // 4 Financial Summary KPI Cards (Official Google M3 Portfolio KPI Standard)
              _buildInvoicingKpis(
                totalCollected: totalCollected,
                totalPending: totalPending,
                totalOverdue: totalOverdue,
                totalInvoicesCount: countryInvoices.length,
                currency: currency,
                lang: lang,
                loc: loc,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 24),

              // Filter & Search Controls
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: loc.tr('searchInvoiceOrTenantPlaceholder'),
                        hintStyle: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Controls (Official M3 Connected Button Group)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TashilConnectedButtonGroup<String>(
                  height: 38.0,
                  selectedValue: _invoiceFilter,
                  showCheckmark: true,
                  onSelectionChanged: (val) => setState(() => _invoiceFilter = val),
                  segments: [
                    TashilConnectedButtonSegment<String>(
                      value: 'all',
                      label: '${loc.tr('filterAllInvoices')} (${countryInvoices.length})',
                      icon: Icons.receipt_long_rounded,
                    ),
                    TashilConnectedButtonSegment<String>(
                      value: 'paid',
                      label: '${loc.tr('statusPaidElectronically')} (${countryInvoices.where((i) => i.status == 'paid').length})',
                      icon: Icons.check_circle_rounded,
                    ),
                    TashilConnectedButtonSegment<String>(
                      value: 'due_soon',
                      label: '${loc.tr('statusPendingPayment')} (${countryInvoices.where((i) => i.status == 'due_soon').length})',
                      icon: Icons.schedule_rounded,
                    ),
                    TashilConnectedButtonSegment<String>(
                      value: 'overdue',
                      label: '${loc.tr('statusOverdue')} (${countryInvoices.where((i) => i.status == 'overdue').length})',
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Invoices List with M3 Fluid Filter Motion
              TashilCardFilterMotion<RentInvoiceModel>(
                items: filteredInvoices,
                filterKey: '$_invoiceFilter-${_searchController.text.trim()}',
                spacing: 14.0,
                emptyState: TashilCard.outlined(
                  padding: const EdgeInsets.all(36),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_outlined, size: 40, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          loc.tr('noInvoicesFound'),
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                itemBuilder: (context, invoice, index) {
                  return _buildInvoiceCard(
                    context,
                    invoice,
                    currency,
                    lang,
                    loc,
                    isMobile,
                    colorScheme,
                  );
                },
              ),
            ],
          );
        },
      );
  }

  Widget _buildInvoicingKpis({
    required double totalCollected,
    required double totalPending,
    required double totalOverdue,
    required int totalInvoicesCount,
    required String currency,
    required String lang,
    required AppLocalizations loc,
    required ColorScheme colorScheme,
  }) {
    return TashilKpiGrid(
      cards: [
        TashilKpiCard(
          title: loc.tr('totalCollectedThisMonth'),
          value: '${CurrencyFormatter.formatAmount(totalCollected, langCode: lang)} $currency',
          subtitle: loc.tr('collectedThisMonthSubtitle'),
          icon: Icons.check_circle_outline_rounded,
          subtitleIcon: Icons.verified_rounded,
          iconColor: colorScheme.secondary,
          iconBgColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('pendingReceivables'),
          value: '${CurrencyFormatter.formatAmount(totalPending, langCode: lang)} $currency',
          subtitle: loc.tr('pendingReceivablesSubtitle'),
          icon: Icons.hourglass_top_rounded,
          subtitleIcon: Icons.schedule_rounded,
          iconColor: colorScheme.tertiary,
          iconBgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('accumulatedOverdueArrears'),
          value: '${CurrencyFormatter.formatAmount(totalOverdue, langCode: lang)} $currency',
          subtitle: loc.tr('overdueArrearsSubtitle'),
          icon: Icons.warning_amber_rounded,
          subtitleIcon: Icons.notification_important_outlined,
          iconColor: colorScheme.error,
          iconBgColor: colorScheme.errorContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('totalManagedInvoices'),
          value: '$totalInvoicesCount ${loc.tr('invoicesCount')}',
          subtitle: loc.tr('managedInvoicesSubtitle'),
          icon: Icons.receipt_long_rounded,
          subtitleIcon: Icons.description_outlined,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.surfaceContainerHigh,
        ),
      ],
    );
  }


  Widget _buildInvoiceCard(
    BuildContext context,
    RentInvoiceModel invoice,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    ColorScheme colorScheme, {
    bool isArrearsView = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPaid = invoice.status == 'paid';
    final isOverdue = invoice.status == 'overdue';

    final Color statusBg;
    final Color statusFg;
    final String statusLabel;
    final IconData statusIcon;

    if (isPaid) {
      statusBg = colorScheme.secondaryContainer;
      statusFg = colorScheme.onSecondaryContainer;
      statusLabel = loc.tr('statusPaidElectronically');
      statusIcon = Icons.check_circle_rounded;
    } else if (isOverdue) {
      statusBg = colorScheme.errorContainer;
      statusFg = colorScheme.onErrorContainer;
      statusLabel = '${loc.tr('statusOverdue')} (${invoice.overdueDays} ${loc.tr('days')})';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusBg = colorScheme.primaryContainer;
      statusFg = colorScheme.onPrimaryContainer;
      statusLabel = loc.tr('statusPendingPayment');
      statusIcon = Icons.schedule_rounded;
    }

    return TashilCard.outlined(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Unit icon badge + Details + Amount & Invoice number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, size: 20, color: statusFg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${invoice.unitTitle} • ${loc.tr('unitNumber')} ${invoice.unitNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${invoice.buildingName} - ${invoice.district}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${CurrencyFormatter.formatAmount(invoice.totalAmountDue, langCode: lang)} $currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOverdue ? colorScheme.error : colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        invoice.invoiceNumber,
                        style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Metadata Details Bar: Tenant, Due Date, Late Days Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Tenant
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 15, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      invoice.tenant.name,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    ),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '(${invoice.tenant.phone})',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                // Due Date
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${loc.tr('dueDate')}: ${invoice.dueDate.year}-${invoice.dueDate.month.toString().padLeft(2, '0')}-${invoice.dueDate.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // Overdue Late Days Badge
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${loc.tr('lateDays')}: ${invoice.overdueDays} ${loc.tr('days')}',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusFg,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Official M3 Card Action Divider (DO Rule: Separating content from action footer)
          const TashilDivider.cardAction(),
          const SizedBox(height: 12),

          // 4. Pinned Actions Footer: Official M3 Connected Button Group
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TashilConnectedButtonGroup<String>(
              height: 38.0,
              selectedValue: isPaid ? 'receipt' : (isOverdue ? 'pay' : 'pay'),
              showCheckmark: false,
              onSelectionChanged: (action) {
                if (action == 'pay') {
                  TenantCheckoutDialog.show(context, invoice);
                } else if (action == 'warning') {
                  LegalWarningNoticeDialog.show(context, invoice);
                } else if (action == 'remind') {
                  RentCollectionService().sendReminder(invoice.id);
                  TashilSnackBar.showSuccess(
                    context: context,
                    message: loc.tr('reminderSentViaWhatsAppSuccess'),
                  );
                } else if (action == 'link') {
                  Clipboard.setData(ClipboardData(
                    text: 'https://tashil-realestate.web.app/#/rent-collection?invoice=${invoice.id}',
                  ));
                  TashilSnackBar.showSuccess(
                    context: context,
                    message: loc.tr('paymentLinkCopiedSuccess'),
                  );
                } else if (action == 'invoice') {
                  TaxInvoiceViewerDialog.show(context, invoice);
                } else if (action == 'receipt') {
                  RentReceiptDialog.show(context, invoice);
                }
              },
              segments: [
                if (isPaid) ...[
                  TashilConnectedButtonSegment<String>(
                    value: 'receipt',
                    label: loc.tr('viewPaymentReceipt'),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'invoice',
                    label: loc.tr('viewOfficialTaxInvoice'),
                    icon: Icons.receipt_long_outlined,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'link',
                    label: loc.tr('sendPaymentLink'),
                    icon: Icons.link_rounded,
                  ),
                ] else if (isOverdue) ...[
                  TashilConnectedButtonSegment<String>(
                    value: 'pay',
                    label: loc.tr('payNowOnline'),
                    icon: Icons.payment_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'warning',
                    label: loc.tr('issueLegalWarningNotice'),
                    icon: Icons.gavel_rounded,
                    activeColor: colorScheme.error,
                    activeForegroundColor: colorScheme.onError,
                    unselectedForegroundColor: colorScheme.error,
                    unselectedColor: colorScheme.error.withValues(
                      alpha: isDark ? 0.16 : 0.09,
                    ),
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'link',
                    label: loc.tr('sendPaymentLink'),
                    icon: Icons.link_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'invoice',
                    label: loc.tr('viewOfficialTaxInvoice'),
                    icon: Icons.receipt_long_outlined,
                  ),
                ] else ...[
                  TashilConnectedButtonSegment<String>(
                    value: 'pay',
                    label: loc.tr('payNowOnline'),
                    icon: Icons.payment_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'remind',
                    label: loc.tr('sendReminderWhatsApp'),
                    icon: Icons.send_to_mobile_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'link',
                    label: loc.tr('sendPaymentLink'),
                    icon: Icons.link_rounded,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'invoice',
                    label: loc.tr('viewOfficialTaxInvoice'),
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Arrears & Legal Notices ---
  Widget _buildArrearsAndLegalNotices(
    BuildContext context,
    String currency,
    String lang,
    AppLocalizations loc,
    bool isMobile,
    String currentCountry,
    ColorScheme colorScheme,
  ) {
    return ValueListenableBuilder<List<RentInvoiceModel>>(
      valueListenable: _rentService.invoicesNotifier,
      builder: (context, allInvoices, _) {
        final overdueInvoices = allInvoices
            .where((inv) => inv.countryCode == currentCountry && inv.status == 'overdue')
            .toList();

        final totalOverdueAmount = overdueInvoices.fold<double>(0.0, (sum, inv) => sum + inv.totalAmountDue);
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header
              Text(
                loc.tr('arrearsTrackerAndLegalNoticesTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('arrearsTrackerSubtitle'),
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Overdue Summary Alert Banner (Official M3 Outlined Card)
              TashilCard.outlined(
                padding: const EdgeInsets.all(18),
                color: colorScheme.errorContainer.withValues(alpha: isDark ? 0.22 : 0.12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.warning_rounded, color: colorScheme.error, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loc.tr('totalActiveArrears')}: ${CurrencyFormatter.formatAmount(totalOverdueAmount, langCode: lang)} $currency',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: colorScheme.onErrorContainer,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.tr('statutoryLegalNoticeAlertDesc'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onErrorContainer.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Overdue Invoices List with M3 Fluid Filter Motion
              TashilCardFilterMotion<RentInvoiceModel>(
                items: overdueInvoices,
                filterKey: 'arrears-${overdueInvoices.length}',
                spacing: 16.0,
                emptyState: TashilCard.outlined(
                  padding: const EdgeInsets.all(36),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.verified_user_rounded, size: 36, color: colorScheme.secondary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          loc.tr('zeroArrearsCongratulations'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.tr('allRentPaymentsUpToDate'),
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
                itemBuilder: (context, invoice, index) {
                  return _buildInvoiceCard(
                    context,
                    invoice,
                    currency,
                    lang,
                    loc,
                    isMobile,
                    colorScheme,
                    isArrearsView: true,
                  );
                },
              ),
            ],
          );
        },
      );
  }

  Widget _buildPayoutsTab(
    String currency,
    String lang,
    AppLocalizations loc,
    ColorScheme colorScheme,
    String countryCode,
  ) {
    final realPayouts = PropertyLifecycleService().getRealPayouts(countryCode: countryCode);
    final properties = PropertyLifecycleService().propertiesNotifier.value.where((p) => p.countryCode == countryCode).toList();
    final payouts = realPayouts.isNotEmpty
        ? realPayouts
        : (properties.isEmpty ? (countryCode == 'AE' ? _payoutsUAE : _payoutsEG) : <Map<String, dynamic>>[]);

    if (payouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_outlined, size: 28, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                loc.tr('noRecentPayoutsTitle'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  loc.tr('noRecentPayoutsDesc'),
                  style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.tr('recentPayouts'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
            ),
            Text(
              loc.tr('clickToViewMonthDetails'),
              style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...payouts.map((p) {
          final amount = (p['amount'] as num).toDouble();
          final title = AiTranslationService.getLocalizedText(p['titles'], lang);
          final date = AiTranslationService.getLocalizedText(p['dates'], lang);
          final ref = p['ref'] as String? ?? 'REF-000000';
          final bankName = _getLocalizedBankName(ref, lang);
          final isExpanded = _expandedPayoutRef == ref;
          final invoiceNo = 'INV-${ref.replaceAll(RegExp(r'[^0-9]'), '')}';
          final grossAmount = amount * 1.12;
          final managementFee = amount * 0.12;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpanded ? colorScheme.primary : colorScheme.outlineVariant,
                width: isExpanded ? 1.5 : 1.0,
              ),
              boxShadow: isExpanded
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedPayoutRef = isExpanded ? null : ref;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Header Row (Always visible)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isExpanded ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  color: isExpanded ? colorScheme.onPrimary : colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$date • $bankName • Ref: $ref',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+ ${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc.tr('payoutCompleted'),
                                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isExpanded ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Animated In-Place Details (Visible when expanded)
                    if (isExpanded) ...[
                      const SizedBox(height: 14),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: 14),

                      // Status Chips / Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMonthChip(
                            icon: Icons.verified_rounded,
                            label: loc.tr('settlementCompleted'),
                            color: colorScheme.primary,
                            bgColor: colorScheme.primaryContainer,
                          ),
                          _buildMonthChip(
                            icon: Icons.account_balance_wallet_rounded,
                            label: loc.tr('bankTransferDeposit'),
                            color: colorScheme.secondary,
                            bgColor: colorScheme.secondaryContainer,
                          ),
                          _buildMonthChip(
                            icon: Icons.account_balance_rounded,
                            label: bankName,
                            color: colorScheme.tertiary,
                            bgColor: colorScheme.tertiaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Detailed Meta Items Table
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            // Bank Reference Number with Copy Action
                            Row(
                              children: [
                                Icon(Icons.tag_rounded, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('bankReferenceNumber')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ref,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TashilIconButton.standard(
                                  icon: Icons.copy_rounded,
                                  tooltip: loc.tr('copyRefSuccess'),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: ref));
                                    TashilSnackBar.showSuccess(
                                      context: context,
                                      message: '${loc.tr('copyRefSuccess')}: $ref',
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 10),
                            // Receiving Bank Account
                            Row(
                              children: [
                                Icon(Icons.account_balance_outlined, size: 16, color: colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('transferredToAccount')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    bankName,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 10),
                            // Linked Tax Invoice
                            Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 16, color: colorScheme.tertiary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('linkedTaxInvoice')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    invoiceNo,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 10),
                            // Linked Unit & Tenant
                            Row(
                              children: [
                                Icon(Icons.apartment_rounded, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${loc.tr('linkedUnitAndTenant')}:',
                                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Financial Breakdown Tile
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${loc.tr('grossRentalCollected')}: + ${CurrencyFormatter.formatAmount(grossAmount, langCode: lang)} $currency',
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${loc.tr('managementFeeDeduction')}: - ${CurrencyFormatter.formatAmount(managementFee, langCode: lang)} $currency',
                              style: TextStyle(fontSize: 11, color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action Toolbar with TashilConnectedButtonGroup
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TashilConnectedButtonGroup<String>(
                          selectedValue: null,
                          onSelectionChanged: (action) {
                            if (action == 'downloadReceipt') {
                              TashilSnackBar.showSuccess(
                                context: context,
                                message: '${loc.tr('downloadTransferReceipt')} ($ref)',
                              );
                            } else if (action == 'shareNotice') {
                              final shareText = '$title\n${loc.tr('bankReferenceNumber')}: $ref\n${loc.tr('transferredToAccount')}: $bankName\n${loc.tr('netSettledAmount')}: ${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency\n$date';
                              Clipboard.setData(ClipboardData(text: shareText));
                              TashilSnackBar.showSuccess(
                                context: context,
                                message: loc.tr('transferNoticeCopied'),
                              );
                            } else if (action == 'copyRef') {
                              Clipboard.setData(ClipboardData(text: ref));
                              TashilSnackBar.showSuccess(
                                context: context,
                                message: '${loc.tr('copyRefSuccess')}: $ref',
                              );
                            }
                          },
                          segments: [
                            TashilConnectedButtonSegment<String>(
                              value: 'downloadReceipt',
                              label: loc.tr('downloadTransferReceipt'),
                              icon: Icons.download_rounded,
                            ),
                            TashilConnectedButtonSegment<String>(
                              value: 'shareNotice',
                              label: loc.tr('shareTransferNotice'),
                              icon: Icons.share_rounded,
                            ),
                            TashilConnectedButtonSegment<String>(
                              value: 'copyRef',
                              label: loc.tr('copyRef'),
                              icon: Icons.copy_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _getLocalizedBankName(String ref, String lang) {
    if (ref.startsWith('CIB')) {
      if (lang == 'ar') return 'البنك التجاري الدولي';
      if (lang == 'hi') return 'कमर्शियल इंटरनेशनल बैंक';
      return 'Commercial International Bank';
    } else if (ref.startsWith('HSBC')) {
      if (lang == 'ar') return 'بنك إتش إس بي سي الشرق الأوسط';
      if (lang == 'hi') return 'एचएसबीसी बैंक मिडिल ईस्ट';
      return 'HSBC Bank Middle East';
    } else if (ref.startsWith('QNB')) {
      if (lang == 'ar') return 'بنك قطر الوطني الأهلي';
      if (lang == 'hi') return 'क्यूएनबी अहली';
      return 'QNB Alahli';
    } else if (ref.startsWith('ENBD')) {
      if (lang == 'ar') return 'بنك الإمارات دبي الوطني';
      if (lang == 'hi') return 'अमीरात एनबीडी';
      return 'Emirates NBD';
    } else if (ref.startsWith('ADCB')) {
      if (lang == 'ar') return 'بنك أبوظبي التجاري';
      if (lang == 'hi') return 'अबू धाबी कमर्शियल बैंक';
      return 'Abu Dhabi Commercial Bank';
    } else {
      if (lang == 'ar') return 'بنك أبوظبي الأول';
      if (lang == 'hi') return 'फर्स्ट अबू धाबी बैंक';
      return 'First Abu Dhabi Bank';
    }
  }

  static const List<Map<String, dynamic>> _payoutsEG = [
    {
      'titles': {
        'ar': 'إيداع إيجار - شقة التجمع الخامس النرجس',
        'en': 'Rent Deposit - 5th Settlement Apartment (El Narges)',
        'hi': 'किराया जमा - 5वां सेटलमेंट अपार्टमेंट (अल नरगिस)',
      },
      'dates': {
        'ar': '25 نوفمبر 2026',
        'en': 'Nov 25, 2026',
        'hi': '25 नवंबर 2026',
      },
      'ref': 'CIB-EG-998124',
      'amount': 26000,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - فيلا بيفرلي هيلز زايد',
        'en': 'Rent Deposit - Beverly Hills Villa (Zayed)',
        'hi': 'किराया जमा - बेवर्ली हिल्स विला (जायद)',
      },
      'dates': {
        'ar': '20 نوفمبر 2026',
        'en': 'Nov 20, 2026',
        'hi': '20 नवंबर 2026',
      },
      'ref': 'HSBC-EG-997102',
      'amount': 55000,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - شقة جاردن سيتي النيل',
        'en': 'Rent Deposit - Garden City Nile Apartment',
        'hi': 'किराया जमा - गार्डन सिटी نائل अपार्टमेंट',
      },
      'dates': {
        'ar': '15 نوفمبر 2026',
        'en': 'Nov 15, 2026',
        'hi': '15 नवंबर 2026',
      },
      'ref': 'QNB-EG-996410',
      'amount': 35000,
    },
  ];

  static const List<Map<String, dynamic>> _payoutsUAE = [
    {
      'titles': {
        'ar': 'إيداع إيجار - شقة دبي مارينا كراون',
        'en': 'Rent Deposit - Dubai Marina Crown Apartment',
        'hi': 'किराया जमा - दुबई मरीना क्राउन अपार्टमेंट',
      },
      'dates': {
        'ar': '25 نوفمبر 2026',
        'en': 'Nov 25, 2026',
        'hi': '25 नवंबर 2026',
      },
      'ref': 'ENBD-AE-44109',
      'amount': 16500,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - بنتهاوس داون تاون برج خليفة',
        'en': 'Rent Deposit - Downtown Burj Khalifa Penthouse',
        'hi': 'किराया जमा - डाउनटाउन बुर्ज खलीफा पेंटहाउस',
      },
      'dates': {
        'ar': '20 نوفمبر 2026',
        'en': 'Nov 20, 2026',
        'hi': '20 नवंबर 2026',
      },
      'ref': 'ADCB-AE-43981',
      'amount': 32000,
    },
    {
      'titles': {
        'ar': 'إيداع إيجار - فيلا نخلة جميرا',
        'en': 'Rent Deposit - Palm Jumeirah Villa',
        'hi': 'किराया जमा - पाम जुमेराह विला',
      },
      'dates': {
        'ar': '10 نوفمبر 2026',
        'en': 'Nov 10, 2026',
        'hi': '10 नवंबर 2026',
      },
      'ref': 'FAB-AE-99210',
      'amount': 75000,
    },
  ];
}
