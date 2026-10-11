import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/signature_pad_dialog.dart';

class LeaseDocumentView extends StatefulWidget {
  final LeaseContractModel contract;
  final Function(LeaseContractModel updatedContract)? onContractUpdated;

  const LeaseDocumentView({
    super.key,
    required this.contract,
    this.onContractUpdated,
  });

  @override
  State<LeaseDocumentView> createState() => _LeaseDocumentViewState();
}

class _LeaseDocumentViewState extends State<LeaseDocumentView> {
  late LeaseContractModel _contract;

  @override
  void initState() {
    super.initState();
    _contract = widget.contract;
  }

  Future<void> _signAs(String role) async {
    final party = role == 'lessor' ? _contract.lessor : _contract.tenant;
    final signature = await SignaturePadDialog.show(
      context,
      signerName: party.name,
      signerRole: role,
      nationalIdOrEmiratesId: party.nationalIdOrEmiratesId,
      contractNumber: _contract.contractNumber,
      countryCode: _contract.countryCode,
    );

    if (signature != null) {
      setState(() {
        if (role == 'lessor') {
          _contract = _contract.copyWith(
            lessorSignature: signature,
            status: _contract.tenantSignature != null ? 'active' : 'pending_signatures',
          );
        } else {
          _contract = _contract.copyWith(
            tenantSignature: signature,
            status: _contract.lessorSignature != null ? 'active' : 'pending_signatures',
          );
        }
      });
      widget.onContractUpdated?.call(_contract);

      if (mounted) {
        TashilSnackBar.showSuccess(
          context: context,
          message: AppLocalizations.of(context).tr('signatureSavedSuccessfully'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;
    final isUAE = _contract.countryCode == 'AE';

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                children: [
                  // Action Toolbar (Print / Share / Sign Status)
                  _buildActionBar(context, loc, isMobile),
                  const SizedBox(height: 16),

                  // Official Legal Certificate Paper
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isMobile ? 18 : 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Official Document Header
                        _buildOfficialHeader(context, loc, isUAE),
                        Divider(height: 36, thickness: 1.5, color: theme.colorScheme.outlineVariant),

                        // Metadata Overview (Contract No, Dates, Registration)
                        _buildMetaTable(loc, isUAE, lang),
                        const SizedBox(height: 24),

                        // Section 1: Parties Information
                        _buildSectionTitle(loc.tr('contractPartiesSection'), Icons.groups_rounded),
                        const SizedBox(height: 12),
                        _buildPartiesGrid(loc, isUAE, isMobile),
                        const SizedBox(height: 24),

                        // Section 2: Leased Property Specifications
                        _buildSectionTitle(loc.tr('leasedPropertySection'), Icons.apartment_rounded),
                        const SizedBox(height: 12),
                        _buildPropertyDetails(loc, isUAE, isMobile),
                        const SizedBox(height: 24),

                        // Section 3: Financial & Payment Terms
                        _buildSectionTitle(loc.tr('financialTermsSection'), Icons.account_balance_wallet_rounded),
                        const SizedBox(height: 12),
                        _buildFinancialTermsTable(loc, isUAE, lang),
                        const SizedBox(height: 24),

                        // Section 4: Cheques Schedule (If UAE / Post-dated cheques)
                        if (_contract.financialTerms.cheques.isNotEmpty) ...[
                          _buildSectionTitle(loc.tr('chequesScheduleSection'), Icons.payments_rounded),
                          const SizedBox(height: 12),
                          _buildChequesList(loc, lang),
                          const SizedBox(height: 24),
                        ],

                        // Section 5: Legal Articles & Conditions
                        _buildSectionTitle(loc.tr('legalArticlesSection'), Icons.gavel_rounded),
                        const SizedBox(height: 12),
                        _buildClausesList(lang),
                        const SizedBox(height: 32),

                        // Section 6: Digital Signatures & Certificates
                        _buildSectionTitle(loc.tr('eSignaturesSection'), Icons.verified_rounded),
                        const SizedBox(height: 16),
                        _buildSignaturesBlock(context, loc, isMobile, lang),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBar(BuildContext context, AppLocalizations loc, bool isMobile) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _contract.isFullySigned
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _contract.isFullySigned ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                      color: _contract.isFullySigned ? theme.colorScheme.tertiary : theme.colorScheme.secondary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _contract.isFullySigned ? loc.tr('contractActiveSigned') : loc.tr('pendingSignatures'),
                      style: TextStyle(
                        color: _contract.isFullySigned ? theme.colorScheme.tertiary : theme.colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  _contract.contractNumber,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          TashilConnectedButtonGroup<String>(
            selectedValue: null,
            onSelectionChanged: (val) {
              if (val == 'exportPdf') {
                TashilSnackBar.showInfo(
                  context: context,
                  message: loc.tr('downloadPdfNotice'),
                );
              } else if (val == 'signTenant') {
                _signAs('tenant');
              } else if (val == 'signLessor') {
                _signAs('lessor');
              }
            },
            segments: [
              TashilConnectedButtonSegment<String>(
                value: 'exportPdf',
                label: loc.tr('exportPdf'),
                icon: Icons.picture_as_pdf_rounded,
              ),
              if (_contract.tenantSignature == null)
                TashilConnectedButtonSegment<String>(
                  value: 'signTenant',
                  label: loc.tr('signAsTenant'),
                  icon: Icons.draw_rounded,
                ),
              if (_contract.lessorSignature == null)
                TashilConnectedButtonSegment<String>(
                  value: 'signLessor',
                  label: loc.tr('signAsLessor'),
                  icon: Icons.draw_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialHeader(BuildContext context, AppLocalizations loc, bool isUAE) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Emblem / Logo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUAE ? loc.tr('uaeGovHeader') : loc.tr('egGovHeader'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  isUAE ? loc.tr('dubaiLandDept') : loc.tr('egyptMinistryJustice'),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
                ),
              ],
            ),
            // Verified Digital Document Stamp
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.tr('verifiedDigitalLease'),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      Text(
                        'ID: ${_contract.id}',
                        style: TextStyle(fontSize: 9, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          isUAE ? loc.tr('uaeTenancyContractTitle') : loc.tr('egTenancyContractTitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isUAE ? loc.tr('uaeLawReference') : loc.tr('egLawReference'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMetaTable(AppLocalizations loc, bool isUAE, String lang) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 16,
        runSpacing: 12,
        children: [
          _buildMetaItem(loc.tr('contractNumber'), _contract.contractNumber, isLtr: true),
          _buildMetaItem(
            loc.tr('leaseStartDate'),
            '${_contract.startDate.year}/${_contract.startDate.month.toString().padLeft(2, '0')}/${_contract.startDate.day.toString().padLeft(2, '0')}',
            isLtr: true,
          ),
          _buildMetaItem(
            loc.tr('leaseEndDate'),
            '${_contract.endDate.year}/${_contract.endDate.month.toString().padLeft(2, '0')}/${_contract.endDate.day.toString().padLeft(2, '0')}',
            isLtr: true,
          ),
          _buildMetaItem(loc.tr('leaseDuration'), '${_contract.durationInMonths} ${loc.tr('months')}', isLtr: true),
          if (_contract.registeredRegistryId != null)
            _buildMetaItem(isUAE ? loc.tr('ejariNo') : loc.tr('realEstateRegistryNo'), _contract.registeredRegistryId!, isLtr: true),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, {bool isLtr = false}) {
    final theme = Theme.of(context);
    final displayValue = isLtr ? '\u200E$value' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Directionality(
          textDirection: isLtr ? TextDirection.ltr : Directionality.of(context),
          child: Text(displayValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildPartiesGrid(AppLocalizations loc, bool isUAE, bool isMobile) {
    return Column(
      children: [
        _buildPartyCard(
          roleTitle: loc.tr('lessorFirstParty'),
          party: _contract.lessor,
          loc: loc,
          isUAE: isUAE,
          isLessor: true,
        ),
        const SizedBox(height: 14),
        _buildPartyCard(
          roleTitle: loc.tr('tenantSecondParty'),
          party: _contract.tenant,
          loc: loc,
          isUAE: isUAE,
          isLessor: false,
        ),
      ],
    );
  }

  Widget _buildPartyCard({
    required String roleTitle,
    required ContractParty party,
    required AppLocalizations loc,
    required bool isUAE,
    required bool isLessor,
  }) {
    final theme = Theme.of(context);
    final roleColor = isLessor ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isLessor
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isLessor ? Icons.business_center_rounded : Icons.person_rounded,
                      size: 20,
                      color: roleColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: roleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        party.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      loc.tr('identityVerified'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 580;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWide) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildPartyInfoItem(
                            icon: Icons.badge_outlined,
                            label: isUAE ? loc.tr('emiratesId') : loc.tr('nationalId'),
                            value: party.nationalIdOrEmiratesId,
                            isLtr: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPartyInfoItem(
                            icon: Icons.flag_outlined,
                            label: loc.tr('nationality'),
                            value: party.nationality,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPartyInfoItem(
                            icon: Icons.phone_outlined,
                            label: loc.tr('phone'),
                            value: party.phone,
                            isLtr: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPartyInfoItem(
                            icon: Icons.email_outlined,
                            label: loc.tr('email'),
                            value: party.email,
                            isLtr: true,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildPartyInfoItem(
                      icon: Icons.badge_outlined,
                      label: isUAE ? loc.tr('emiratesId') : loc.tr('nationalId'),
                      value: party.nationalIdOrEmiratesId,
                      isLtr: true,
                    ),
                    const SizedBox(height: 8),
                    _buildPartyInfoItem(
                      icon: Icons.flag_outlined,
                      label: loc.tr('nationality'),
                      value: party.nationality,
                    ),
                    const SizedBox(height: 8),
                    _buildPartyInfoItem(
                      icon: Icons.phone_outlined,
                      label: loc.tr('phone'),
                      value: party.phone,
                      isLtr: true,
                    ),
                    const SizedBox(height: 8),
                    _buildPartyInfoItem(
                      icon: Icons.email_outlined,
                      label: loc.tr('email'),
                      value: party.email,
                      isLtr: true,
                    ),
                  ],
                  if (party.passportNumber != null && party.passportNumber!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPartyInfoItem(
                      icon: Icons.menu_book_outlined,
                      label: loc.tr('passportNo'),
                      value: party.passportNumber!,
                      isLtr: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildPartyInfoItem(
                    icon: Icons.location_on_outlined,
                    label: loc.tr('address'),
                    value: party.address,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartyInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isLtr = false,
  }) {
    final theme = Theme.of(context);
    final displayValue = isLtr ? '\u200E$value' : value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Directionality(
            textDirection: isLtr ? TextDirection.ltr : Directionality.of(context),
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isLtr ? FontWeight.w600 : FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyDetails(AppLocalizations loc, bool isUAE, bool isMobile) {
    final theme = Theme.of(context);
    final p = _contract.property;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.propertyTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _buildPropInfoField(loc.tr('unitNumber'), p.unitNumber, isLtr: true),
              _buildPropInfoField(loc.tr('buildingName'), p.buildingName),
              _buildPropInfoField(loc.tr('districtCity'), '${p.district}, ${p.city}'),
              _buildPropInfoField(loc.tr('areaSqm'), '${p.areaSqm} ${loc.tr('sqm')}', isLtr: true),
              if (p.floorNumber != null) _buildPropInfoField(loc.tr('floorNumber'), p.floorNumber!),
              if (isUAE && p.makaniNumber != null) _buildPropInfoField(loc.tr('makaniNumber'), p.makaniNumber!, isLtr: true),
              if (isUAE && p.dewaPremiseNumber != null) _buildPropInfoField(loc.tr('dewaPremiseNo'), p.dewaPremiseNumber!, isLtr: true),
              if (p.titleDeedNumber != null) _buildPropInfoField(loc.tr('titleDeedNumber'), p.titleDeedNumber!, isLtr: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropInfoField(String label, String value, {bool isLtr = false}) {
    final theme = Theme.of(context);
    final displayValue = isLtr ? '\u200E$value' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        Directionality(
          textDirection: isLtr ? TextDirection.ltr : Directionality.of(context),
          child: Text(displayValue, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        ),
      ],
    );
  }

  Widget _buildFinancialTermsTable(AppLocalizations loc, bool isUAE, String lang) {
    final theme = Theme.of(context);
    final f = _contract.financialTerms;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: [
          _buildPropInfoField(
            loc.tr('totalRentValue'),
            '${CurrencyFormatter.formatAmount(f.totalRentAmount, langCode: lang)} $currency',
            isLtr: true,
          ),
          _buildPropInfoField(
            loc.tr('monthlyEquivalent'),
            '${CurrencyFormatter.formatAmount(f.monthlyRentEquivalent, langCode: lang)} $currency / ${loc.tr('month')}',
            isLtr: true,
          ),
          _buildPropInfoField(loc.tr('paymentFrequency'), loc.tr('freq_${f.paymentFrequency}')),
          _buildPropInfoField(
            loc.tr('numberOfPdcCheques'),
            '${f.numberOfCheques} ${loc.tr(f.numberOfCheques == 1 ? 'cheque' : 'cheques')}',
            isLtr: true,
          ),
          _buildPropInfoField(
            loc.tr('securityDepositAmount'),
            '${CurrencyFormatter.formatAmount(f.securityDeposit, langCode: lang)} $currency',
            isLtr: true,
          ),
          _buildPropInfoField(
            loc.tr('annualEscalationRate'),
            '${f.annualIncreasePercentage}% ${isUAE ? "(${loc.tr('reraIndexed')})" : "(${loc.tr('agreedRate')})"}',
            isLtr: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChequesList(AppLocalizations loc, String lang) {
    final theme = Theme.of(context);
    final cheques = _contract.financialTerms.cheques;
    final currency = _contract.countryCode == 'AE' ? loc.tr('currency_ae') : loc.tr('currency_eg');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cheques.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant),
        itemBuilder: (context, index) {
          final c = cheques[index];
          final isCleared = c.status == 'cleared';

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: isCleared ? theme.colorScheme.tertiaryContainer : theme.colorScheme.primaryContainer,
              child: Text('${index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCleared ? theme.colorScheme.tertiary : theme.colorScheme.primary)),
            ),
            title: Row(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(c.chequeNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)),
                ),
                const SizedBox(width: 8),
                Text('(${c.bankName})', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            subtitle: Row(
              children: [
                Text('${loc.tr('dueDate')}: ', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${c.dueDate.year}/${c.dueDate.month.toString().padLeft(2, '0')}/${c.dueDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            trailing: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${CurrencyFormatter.formatAmount(c.amount, langCode: lang)} $currency',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClausesList(String lang) {
    final theme = Theme.of(context);
    final enabledClauses = _contract.clauses.where((c) => c.isEnabled).toList();

    return Column(
      children: enabledClauses.map((clause) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      clause.getLocalizedTitle(lang),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  if (clause.lawReference != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        clause.lawReference!,
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                clause.getLocalizedBody(lang),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSignaturesBlock(BuildContext context, AppLocalizations loc, bool isMobile, String lang) {
    final theme = Theme.of(context);
    return isMobile
        ? Column(
            children: [
              _buildSignatureStamp(context, loc, _contract.lessorSignature, _contract.lessor.name, 'lessor', theme.colorScheme.primary),
              const SizedBox(height: 16),
              _buildSignatureStamp(context, loc, _contract.tenantSignature, _contract.tenant.name, 'tenant', theme.colorScheme.secondary),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSignatureStamp(context, loc, _contract.lessorSignature, _contract.lessor.name, 'lessor', theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSignatureStamp(context, loc, _contract.tenantSignature, _contract.tenant.name, 'tenant', theme.colorScheme.secondary),
              ),
            ],
          );
  }

  Widget _buildSignatureStamp(
    BuildContext context,
    AppLocalizations loc,
    DigitalSignature? signature,
    String partyName,
    String role,
    Color roleColor,
  ) {
    final theme = Theme.of(context);
    final isLessor = role == 'lessor';
    final roleLabel = isLessor ? loc.tr('lessorFirstParty') : loc.tr('tenantSecondParty');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: signature != null ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: signature != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLessor ? Icons.business_center_rounded : Icons.person_rounded,
                      size: 16,
                      color: roleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: roleColor),
                    ),
                  ],
                ),
                if (signature != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 13, color: theme.colorScheme.onPrimaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          loc.tr('digitallySigned'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          loc.tr('pendingSignatures'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            partyName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Symmetrical signature drawing or M3 action button container (76dp fixed height)
          Container(
            height: 76,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                style: BorderStyle.solid,
              ),
            ),
            child: signature != null
                ? (signature.signatureStrokePoints != null && signature.signatureStrokePoints!.isNotEmpty
                    ? CustomPaint(
                        painter: _MiniSignaturePainter(
                          signature.signatureStrokePoints!,
                          theme.colorScheme.primary,
                        ),
                      )
                    : Center(
                        child: Text(
                          '✍️ ${signature.signerName}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ))
                : Center(
                    child: TashilButton.filled(
                      onPressed: () => _signAs(role),
                      icon: Icons.draw_rounded,
                      label: loc.tr('clickToSign'),
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Audit Metadata / Status lines (Symmetric 2 lines in both cards!)
          if (signature != null) ...[
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '\u200E${loc.tr('signedOn')}: ${signature.signedAt.year}/${signature.signedAt.month.toString().padLeft(2, '0')}/${signature.signedAt.day.toString().padLeft(2, '0')} ${signature.signedAt.hour.toString().padLeft(2, '0')}:${signature.signedAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.fingerprint_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '\u200E${loc.tr('hash')}: ${signature.verificationHash}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${loc.tr('verificationStatus')}: ${loc.tr('awaitingVerification')}',
                    style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lock_clock_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${loc.tr('digitalValidation')}: ${loc.tr('readyForSigning')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniSignaturePainter extends CustomPainter {
  final List<List<double>> strokes;
  final Color strokeColor;

  _MiniSignaturePainter(this.strokes, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      // Normalize to fit container width/height
      final scaleX = size.width / 400.0;
      final scaleY = size.height / 180.0;

      path.moveTo(stroke[0] * scaleX, stroke[1] * scaleY);
      for (int i = 2; i < stroke.length; i += 2) {
        path.lineTo(stroke[i] * scaleX, stroke[i + 1] * scaleY);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSignaturePainter oldDelegate) => false;
}
