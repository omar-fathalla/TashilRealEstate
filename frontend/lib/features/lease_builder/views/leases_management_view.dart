import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';
import 'package:tashil_real_estate/features/lease_builder/services/legal_clauses_service.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_builder_wizard_dialog.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_document_view.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/signature_pad_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

/// Material Design 3 (M3) Leases & Contracts Management View.
/// Conforms to:
/// 1. Google M3 Connected Button Group for filters.
/// 2. Dynamic Primary-Derived Hover Engine ([M3HoverColorScheme]).
/// 3. M3 Card Taxonomy ([TashilCard.outlined] for contracts, [TashilCard.elevated] for KPIs).
/// 4. Strict Single-Icon Rule (Zero emoji in buttons).
/// 5. Google M3 Motion & Transitions ([AnimatedSwitcher] with M3 tokens).
/// 6. Trilingual Purity & Parity (Arabic RTL, English LTR, Hindi LTR).
/// 7. 100% Responsiveness across Mobile, Tablet, and Desktop.
class LeasesManagementView extends StatefulWidget {
  const LeasesManagementView({super.key});

  @override
  State<LeasesManagementView> createState() => _LeasesManagementViewState();
}

class _LeasesManagementViewState extends State<LeasesManagementView> {
  late List<LeaseContractModel> _contracts;
  String _selectedFilter = 'all'; // 'all', 'active', 'pending_signatures'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncContracts();
    LegalClausesService().contractsNotifier.addListener(_syncContracts);
    PropertyLifecycleService().propertiesNotifier.addListener(_syncContracts);
  }

  @override
  void dispose() {
    LegalClausesService().contractsNotifier.removeListener(_syncContracts);
    PropertyLifecycleService().propertiesNotifier.removeListener(_syncContracts);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _syncContracts() {
    final all = LegalClausesService().contractsNotifier.value;
    if (mounted) {
      setState(() {
        _contracts = all;
      });
    } else {
      _contracts = all;
    }
  }

  void _openLeaseBuilder() async {
    final created = await LeaseBuilderWizardDialog.show(context);
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tr('contractCreatedSuccess')),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editContract(LeaseContractModel contract) async {
    final updated = await LeaseBuilderWizardDialog.show(
      context,
      initialContract: contract,
    );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tr('contractUpdatedSuccess')),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDeleteContract(LeaseContractModel contract) async {
    final loc = AppLocalizations.of(context);

    final confirmed = await TashilAlertDialog.showConfirmation(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: loc.tr('confirmDeleteContractTitle'),
      message: loc.tr('confirmDeleteContractDesc'),
      confirmLabel: loc.tr('deleteContractBtn'),
      cancelLabel: loc.tr('cancel'),
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final theme = Theme.of(context);
      LegalClausesService().softDeleteContract(contract.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.tr('contractMovedToTrashSuccess')),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: loc.tr('restoreShort'),
            textColor: theme.colorScheme.onPrimary,
            onPressed: () {
              LegalClausesService().restoreContract(contract.id);
            },
          ),
        ),
      );
    }
  }

  void _viewContractDocument(LeaseContractModel contract) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            contract.contractNumber,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.colorScheme.surface,
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: TashilIconButton.close(
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
        body: LeaseDocumentView(
          contract: contract,
          onContractUpdated: (updated) {
            LegalClausesService().addOrUpdateContract(updated);
          },
        ),
      ),
    );
  }

  void _quickSign(LeaseContractModel contract) async {
    final role = contract.lessorSignature == null ? 'lessor' : 'tenant';
    final party = role == 'lessor' ? contract.lessor : contract.tenant;

    final signature = await SignaturePadDialog.show(
      context,
      signerName: party.name,
      signerRole: role,
      nationalIdOrEmiratesId: party.nationalIdOrEmiratesId,
      contractNumber: contract.contractNumber,
      countryCode: contract.countryCode,
    );

    if (signature != null) {
      final updated = role == 'lessor'
          ? contract.copyWith(
              lessorSignature: signature,
              status: contract.tenantSignature != null ? 'active' : 'pending_signatures',
            )
          : contract.copyWith(
              tenantSignature: signature,
              status: contract.lessorSignature != null ? 'active' : 'pending_signatures',
            );
      LegalClausesService().addOrUpdateContract(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tr('signatureSavedSuccessfully')),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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

        // Filter contracts by country and exclude soft-deleted
        final countryContracts = _contracts
            .where((c) => !c.isDeleted && c.countryCode == currentCountry)
            .toList();

        // Calculate counts
        final totalCountryLeases = countryContracts.length;
        final activeLeases = countryContracts.where((c) => c.status == 'active').length;
        final pendingLeases = countryContracts.where((c) => c.status == 'pending_signatures').length;
        final totalMonthlyYield = countryContracts
            .where((c) => c.status == 'active')
            .fold<double>(0.0, (sum, c) => sum + c.financialTerms.monthlyRentEquivalent);

        // Filter by search & status
        final filteredContracts = countryContracts.where((c) {
          if (_selectedFilter != 'all' && c.status != _selectedFilter) return false;
          if (_searchCtrl.text.isNotEmpty) {
            final query = _searchCtrl.text.toLowerCase().trim();
            final matchNumber = c.contractNumber.toLowerCase().contains(query);
            final matchTenant = c.tenant.name.toLowerCase().contains(query);
            final matchLessor = c.lessor.name.toLowerCase().contains(query);
            final matchBuilding = c.property.buildingName.toLowerCase().contains(query);
            final matchUnit = c.property.unitNumber.toLowerCase().contains(query);
            if (!matchNumber && !matchTenant && !matchLessor && !matchBuilding && !matchUnit) return false;
          }
          return true;
        }).toList();

        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.currentLocale,
          builder: (context, locale, _) {
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
                      // 1. Header Section
                      _buildHeader(
                        loc: loc,
                        isUAE: isUAE,
                        isCompact: isCompact,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 24),

                      // 2. M3 KPI Cards Grid
                      _buildKpiSection(
                        loc: loc,
                        total: totalCountryLeases,
                        active: activeLeases,
                        pending: pendingLeases,
                        monthlyYield: totalMonthlyYield,
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
                        allCount: totalCountryLeases,
                        activeCount: activeLeases,
                        pendingCount: pendingLeases,
                      ),
                      const SizedBox(height: 20),

                      // 4. Contracts List with M3 Motion & Transitions
                      AnimatedSwitcher(
                        duration: TashilMotionDuration.medium2,
                        switchInCurve: TashilMotionEasing.emphasizedDecelerate,
                        switchOutCurve: TashilMotionEasing.emphasizedAccelerate,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: filteredContracts.isEmpty
                            ? KeyedSubtree(
                                key: const ValueKey('empty_state'),
                                child: _buildEmptyState(loc, colorScheme),
                              )
                            : KeyedSubtree(
                                key: ValueKey('list_${_selectedFilter}_${_searchCtrl.text}_${filteredContracts.length}'),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredContracts.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final contract = filteredContracts[index];
                                    return _buildLeaseCard(
                                      context: context,
                                      loc: loc,
                                      contract: contract,
                                      currency: currency,
                                      lang: lang,
                                      screenWidth: screenWidth,
                                      isUAE: isUAE,
                                      colorScheme: colorScheme,
                                    );
                                  },
                                ),
                              ),
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
  }

  // --- 1. Header Section ---
  Widget _buildHeader({
    required AppLocalizations loc,
    required bool isUAE,
    required bool isCompact,
    required ColorScheme colorScheme,
  }) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.tr('leasesManagementTitle'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 20 : 24,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isUAE ? loc.tr('leasesSubtitle_ae') : loc.tr('leasesSubtitle_eg'),
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );

    final actionButton = TashilButton(
      onPressed: _openLeaseBuilder,
      icon: Icons.add_rounded,
      label: loc.tr('createNewLease'),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 14),
          actionButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        actionButton,
      ],
    );
  }

  // --- 2. M3 KPI Cards Grid ---
  Widget _buildKpiSection({
    required AppLocalizations loc,
    required int total,
    required int active,
    required int pending,
    required double monthlyYield,
    required String currency,
    required String lang,
    required ColorScheme colorScheme,
  }) {
    return TashilKpiGrid(
      cards: [
        TashilKpiCard(
          title: loc.tr('totalLeasesCount'),
          value: '$total',
          subtitle: loc.tr('totalLeasesSubtitle'),
          icon: Icons.description_rounded,
          subtitleIcon: Icons.folder_shared_outlined,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.surfaceContainerHigh,
        ),
        TashilKpiCard(
          title: loc.tr('activeLeasesCount'),
          value: '$active',
          subtitle: loc.tr('activeLeasesSubtitle'),
          icon: Icons.check_circle_rounded,
          subtitleIcon: Icons.verified_rounded,
          iconColor: colorScheme.tertiary,
          iconBgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('pendingSignaturesCount'),
          value: '$pending',
          subtitle: loc.tr('pendingSignaturesSubtitle'),
          icon: Icons.draw_rounded,
          subtitleIcon: Icons.pending_actions_rounded,
          iconColor: colorScheme.secondary,
          iconBgColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        ),
        TashilKpiCard(
          title: loc.tr('monthlyRentalYield'),
          value: '${CurrencyFormatter.formatAmount(monthlyYield, langCode: lang)} $currency',
          subtitle: loc.tr('monthlyYieldSubtitle'),
          icon: Icons.account_balance_wallet_rounded,
          subtitleIcon: Icons.trending_up_rounded,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.surfaceContainerHigh,
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
    required int activeCount,
    required int pendingCount,
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
                hintText: loc.tr('searchLeasesPlaceholder'),
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
          label: loc.tr('filterAllLeases'),
          icon: Icons.all_inbox_rounded,
          badge: '$allCount',
        ),
        TashilConnectedButtonSegment(
          value: 'active',
          label: loc.tr('filterActiveLeases'),
          icon: Icons.check_circle_rounded,
          badge: '$activeCount',
        ),
        TashilConnectedButtonSegment(
          value: 'pending_signatures',
          label: loc.tr('filterPendingSignatures'),
          icon: Icons.pending_actions_rounded,
          badge: '$pendingCount',
        ),
      ],
    );

    if (screenWidth < 980) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchWidget,
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: connectedGroupWidget,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: searchWidget,
        ),
        const SizedBox(width: 14),
        connectedGroupWidget,
      ],
    );
  }

  // --- 4. Contract Card ---
  Widget _buildLeaseCard({
    required BuildContext context,
    required AppLocalizations loc,
    required LeaseContractModel contract,
    required String currency,
    required String lang,
    required double screenWidth,
    required bool isUAE,
    required ColorScheme colorScheme,
  }) {
    final isActive = contract.status == 'active';
    final hasPendingSign = contract.status == 'pending_signatures';

    Color statusBg = colorScheme.surfaceContainer;
    Color statusText = colorScheme.onSurfaceVariant;
    IconData statusIcon = Icons.edit_note_rounded;
    String statusLabel = loc.tr('statusDraft');

    if (isActive) {
      statusBg = colorScheme.tertiaryContainer;
      statusText = colorScheme.onTertiaryContainer;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = loc.tr('statusActive');
    } else if (hasPendingSign) {
      statusBg = colorScheme.secondaryContainer;
      statusText = colorScheme.onSecondaryContainer;
      statusIcon = Icons.pending_actions_rounded;
      statusLabel = loc.tr('statusPendingSign');
    }

    final isMobile = screenWidth < 680;

    return TashilCard.outlined(
      enableHoverAnimation: true,
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Header (Contract Number, Registry ID, Status Badge)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contract.contractNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (contract.registeredRegistryId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contract.registeredRegistryId!.contains(':')
                            ? contract.registeredRegistryId!
                            : '${isUAE ? loc.tr('ejariNo') : loc.tr('realEstateRegistryNo')}: ${contract.registeredRegistryId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                      style: TextStyle(
                        color: statusText,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Responsive Unit Specs & Lease Terms Grid
          _buildDetailsGrid(
            loc: loc,
            contract: contract,
            currency: currency,
            lang: lang,
            screenWidth: screenWidth,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 14),

          // Row 3: Signatures Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildSignPill(
                      label: loc.tr('lessorSign'),
                      isSigned: contract.lessorSignature != null,
                      colorScheme: colorScheme,
                    ),
                    _buildSignPill(
                      label: loc.tr('tenantSign'),
                      isSigned: contract.tenantSignature != null,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                if (contract.isFullySigned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.tr('verifiedOwner'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Official M3 Card Action Divider (DO Rule: Separating details from action footer)
          const TashilDivider.cardAction(),
          const SizedBox(height: 12),

          // Row 4: Pinned Action Buttons Footer with TashilConnectedButtonGroup
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: TashilConnectedButtonGroup<String>(
                height: 38,
                selectedValue: 'view',
                showCheckmark: false,
                onSelectionChanged: (action) {
                  if (action == 'sign') {
                    _quickSign(contract);
                  } else if (action == 'view') {
                    _viewContractDocument(contract);
                  } else if (action == 'edit') {
                    _editContract(contract);
                  } else if (action == 'delete') {
                    _confirmDeleteContract(contract);
                  }
                },
                segments: [
                  if (!contract.isFullySigned)
                    TashilConnectedButtonSegment(
                      value: 'sign',
                      label: loc.tr('quickSign'),
                      icon: Icons.draw_rounded,
                    ),
                  TashilConnectedButtonSegment(
                    value: 'view',
                    label: loc.tr('viewOfficialContract'),
                    icon: Icons.visibility_rounded,
                  ),
                  TashilConnectedButtonSegment(
                    value: 'edit',
                    label: loc.tr('editContractBtn'),
                    icon: Icons.edit_outlined,
                  ),
                  TashilConnectedButtonSegment(
                    value: 'delete',
                    label: loc.tr('deleteContractBtn'),
                    icon: Icons.delete_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Responsive Details Grid
  Widget _buildDetailsGrid({
    required AppLocalizations loc,
    required LeaseContractModel contract,
    required String currency,
    required String lang,
    required double screenWidth,
    required ColorScheme colorScheme,
  }) {
    final unitItem = _buildDetailCell(
      icon: Icons.apartment_rounded,
      label: loc.tr('unit'),
      value: '${contract.property.unitNumber} - ${contract.property.buildingName}',
      colorScheme: colorScheme,
    );

    final tenantItem = _buildDetailCell(
      icon: Icons.person_outline_rounded,
      label: loc.tr('tenant'),
      value: contract.tenant.name,
      colorScheme: colorScheme,
    );

    final lessorItem = _buildDetailCell(
      icon: Icons.business_center_outlined,
      label: loc.tr('lessor'),
      value: contract.lessor.name,
      colorScheme: colorScheme,
    );

    final rentItem = _buildDetailCell(
      icon: Icons.payments_outlined,
      label: loc.tr('monthlyRent'),
      value: '${CurrencyFormatter.formatAmount(contract.financialTerms.monthlyRentEquivalent, langCode: lang)} $currency',
      colorScheme: colorScheme,
      isHighlighted: true,
    );

    final periodItem = _buildDetailCell(
      icon: Icons.calendar_month_outlined,
      label: loc.tr('leasePeriod'),
      value: '${contract.startDate.year}/${contract.startDate.month} - ${contract.endDate.year}/${contract.endDate.month} (${contract.durationInMonths} ${loc.tr('months')})',
      colorScheme: colorScheme,
    );

    // Desktop: 5 items in a row
    if (screenWidth >= 1080) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: unitItem),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: tenantItem),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: lessorItem),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: rentItem),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: periodItem),
        ],
      );
    }

    // Tablet: 2 rows (3 items, then 2 items)
    if (screenWidth >= 640) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: unitItem),
              const SizedBox(width: 12),
              Expanded(child: tenantItem),
              const SizedBox(width: 12),
              Expanded(child: lessorItem),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: rentItem),
              const SizedBox(width: 12),
              Expanded(child: periodItem),
            ],
          ),
        ],
      );
    }

    // Mobile: 2 items per row, last item full width
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: unitItem),
            const SizedBox(width: 10),
            Expanded(child: tenantItem),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: lessorItem),
            const SizedBox(width: 10),
            Expanded(child: rentItem),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: periodItem),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCell({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withAlpha(120),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isHighlighted ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignPill({
    required String label,
    required bool isSigned,
    required ColorScheme colorScheme,
  }) {
    final bg = isSigned ? colorScheme.tertiaryContainer : colorScheme.surfaceContainer;
    final fg = isSigned ? colorScheme.onTertiaryContainer : colorScheme.onSurfaceVariant;
    final icon = isSigned ? Icons.check_circle_rounded : Icons.pending_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined, size: 48, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              loc.tr('noLeasesFound'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              loc.tr('noLeasesSubtitle'),
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TashilButton(
              onPressed: _openLeaseBuilder,
              icon: Icons.add_rounded,
              label: loc.tr('createNewLease'),
            ),
          ],
        ),
      ),
    );
  }
}


