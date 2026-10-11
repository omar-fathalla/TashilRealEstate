import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/sliders/tashil_slider.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/document_ocr/models/document_ocr_result_model.dart';
import 'package:tashil_real_estate/features/document_ocr/widgets/ai_document_ocr_modal.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';
import 'package:tashil_real_estate/features/lease_builder/services/legal_clauses_service.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_document_view.dart';
import 'package:tashil_real_estate/features/legal_ai_advisor/widgets/ai_legal_clause_advisor_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';

class LeaseBuilderWizardDialog extends StatefulWidget {
  final LeaseContractModel? initialContract;
  final ManagedPropertyModel? targetProperty;
  final Function(LeaseContractModel contract)? onContractCreated;

  const LeaseBuilderWizardDialog({
    super.key,
    this.initialContract,
    this.targetProperty,
    this.onContractCreated,
  });

  static Future<LeaseContractModel?> show(
    BuildContext context, {
    LeaseContractModel? initialContract,
    ManagedPropertyModel? targetProperty,
    Function(LeaseContractModel contract)? onContractCreated,
  }) {
    return TashilTransitions.showM3Dialog<LeaseContractModel>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LeaseBuilderWizardDialog(
        initialContract: initialContract,
        targetProperty: targetProperty,
        onContractCreated: onContractCreated,
      ),
    );
  }

  @override
  State<LeaseBuilderWizardDialog> createState() => _LeaseBuilderWizardDialogState();
}

class _LeaseBuilderWizardDialogState extends State<LeaseBuilderWizardDialog> {
  int _currentStep = 0; // 0: Parties, 1: Property, 2: Financial, 3: Legal Clauses, 4: Preview/Sign

  // Country State
  late String _countryCode;

  // Step 1: Parties Controllers
  final _lessorNameCtrl = TextEditingController(text: 'م. عمر طارق فتح الله');
  final _lessorIdCtrl = TextEditingController(text: '29304150102432');
  final _lessorPhoneCtrl = TextEditingController(text: '+201002345678');
  final _lessorEmailCtrl = TextEditingController(text: 'omar.fathalla@tashil.com');
  final _lessorAddressCtrl = TextEditingController(text: 'التجمع الخامس، القاهرة');

  final _tenantNameCtrl = TextEditingController(text: 'كريم عادل الشناوي');
  final _tenantIdCtrl = TextEditingController(text: '29508120104567');
  final _tenantPhoneCtrl = TextEditingController(text: '+201145678901');
  final _tenantEmailCtrl = TextEditingController(text: 'karim.shenawy@gmail.com');
  final _tenantAddressCtrl = TextEditingController(text: 'مدينة نصر، القاهرة');

  // Step 2: Property Controllers
  final _propTitleCtrl = TextEditingController(text: 'شقة فاخرة مطابقة للمواصفات');
  final _unitNumberCtrl = TextEditingController(text: '502');
  final _buildingNameCtrl = TextEditingController(text: 'برج الأندلس');
  final _districtCtrl = TextEditingController(text: 'التجمع الخامس');
  final _cityCtrl = TextEditingController(text: 'القاهرة');
  final _areaCtrl = TextEditingController(text: '150');
  final _floorCtrl = TextEditingController(text: 'الخامس');
  final _makaniCtrl = TextEditingController(text: '31422 78901');
  final _dewaCtrl = TextEditingController(text: '20984711');
  final _titleDeedCtrl = TextEditingController(text: 'TD-2026-004128');

  // Step 3: Financial Terms Controllers
  final _rentAmountCtrl = TextEditingController(text: '25000');
  String _paymentFrequency = 'monthly';
  int _numberOfCheques = 12;
  final _depositCtrl = TextEditingController(text: '50000');
  double _annualIncreasePct = 10.0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  // Step 4: Clauses List
  late List<LegalClause> _clauses;

  // Signatures
  DigitalSignature? _lessorSignature;
  DigitalSignature? _tenantSignature;

  @override
  void initState() {
    super.initState();
    if (widget.initialContract != null) {
      final c = widget.initialContract!;
      _countryCode = c.countryCode;
      _lessorNameCtrl.text = c.lessor.name;
      _lessorIdCtrl.text = c.lessor.nationalIdOrEmiratesId;
      _lessorPhoneCtrl.text = c.lessor.phone;
      _lessorEmailCtrl.text = c.lessor.email;
      _lessorAddressCtrl.text = c.lessor.address;

      _tenantNameCtrl.text = c.tenant.name;
      _tenantIdCtrl.text = c.tenant.nationalIdOrEmiratesId;
      _tenantPhoneCtrl.text = c.tenant.phone;
      _tenantEmailCtrl.text = c.tenant.email;
      _tenantAddressCtrl.text = c.tenant.address;

      _propTitleCtrl.text = c.property.propertyTitle;
      _unitNumberCtrl.text = c.property.unitNumber;
      _buildingNameCtrl.text = c.property.buildingName;
      _districtCtrl.text = c.property.district;
      _cityCtrl.text = c.property.city;
      _areaCtrl.text = c.property.areaSqm.toString();
      _floorCtrl.text = c.property.floorNumber ?? '';
      _makaniCtrl.text = c.property.makaniNumber ?? '';
      _dewaCtrl.text = c.property.dewaPremiseNumber ?? '';
      _titleDeedCtrl.text = c.property.titleDeedNumber ?? '';

      _rentAmountCtrl.text = c.financialTerms.totalRentAmount.toInt().toString();
      _paymentFrequency = c.financialTerms.paymentFrequency;
      _numberOfCheques = c.financialTerms.numberOfCheques;
      _depositCtrl.text = c.financialTerms.securityDeposit.toInt().toString();
      _annualIncreasePct = c.financialTerms.annualIncreasePercentage;
      _startDate = c.startDate;
      _endDate = c.endDate;

      _clauses = List.from(c.clauses);
      _lessorSignature = c.lessorSignature;
      _tenantSignature = c.tenantSignature;
    } else {
      _countryCode = widget.targetProperty?.countryCode ?? CountryController.countryCode;
      _initDefaultsForCountry(_countryCode);
    }
  }

  void _initDefaultsForCountry(String country) {
    if (country == 'AE') {
      _lessorNameCtrl.text = 'عبدالله راشد النعيمي';
      _lessorIdCtrl.text = '784-1985-1234567-1';
      _lessorPhoneCtrl.text = '+971501234567';
      _lessorEmailCtrl.text = 'abdullah.nuaimi@tashil.ae';
      _lessorAddressCtrl.text = 'نخلة جميرا، دبي';

      _tenantNameCtrl.text = 'Sarah Jennifer Parker';
      _tenantIdCtrl.text = '784-1992-9876543-2';
      _tenantPhoneCtrl.text = '+971559876543';
      _tenantEmailCtrl.text = 'sarah.parker@techcorp.ae';
      _tenantAddressCtrl.text = 'دبي مارينا، دبي';

      _propTitleCtrl.text = 'شقة راقية بإطلالة على مارينا دبي';
      _unitNumberCtrl.text = '1402';
      _buildingNameCtrl.text = 'Marina Gate 1';
      _districtCtrl.text = 'دبي مارينا';
      _cityCtrl.text = 'دبي';
      _areaCtrl.text = '130';
      _floorCtrl.text = '14';

      _rentAmountCtrl.text = '120000';
      _paymentFrequency = 'quarterly';
      _numberOfCheques = 4;
      _depositCtrl.text = '12000';
      _annualIncreasePct = 0.0;
    } else {
      _lessorNameCtrl.text = 'م. عمر طارق فتح الله';
      _lessorIdCtrl.text = '29304150102432';
      _lessorPhoneCtrl.text = '+201002345678';
      _lessorEmailCtrl.text = 'omar.fathalla@tashil.com';
      _lessorAddressCtrl.text = 'التجمع الخامس، القاهرة';

      _tenantNameCtrl.text = 'كريم عادل الشناوي';
      _tenantIdCtrl.text = '29508120104567';
      _tenantPhoneCtrl.text = '+201145678901';
      _tenantEmailCtrl.text = 'karim.shenawy@gmail.com';
      _tenantAddressCtrl.text = 'مدينة نصر، القاهرة';

      _propTitleCtrl.text = 'شقة فاخرة مطابقة للمواصفات';
      _unitNumberCtrl.text = '502';
      _buildingNameCtrl.text = 'برج الأندلس';
      _districtCtrl.text = 'التجمع الخامس';
      _cityCtrl.text = 'القاهرة';
      _areaCtrl.text = '150';
      _floorCtrl.text = 'الخامس';

      _rentAmountCtrl.text = '25000';
      _paymentFrequency = 'monthly';
      _numberOfCheques = 12;
      _depositCtrl.text = '50000';
      _annualIncreasePct = 10.0;
    }

    if (widget.targetProperty != null) {
      final p = widget.targetProperty!;
      _propTitleCtrl.text = p.getTitle(LocaleController.languageCode);
      _unitNumberCtrl.text = p.unitNumber;
      _buildingNameCtrl.text = p.buildingName;
      _districtCtrl.text = p.getLocation(LocaleController.languageCode);
      _cityCtrl.text = p.cityCode == 'CAI' ? 'القاهرة' : (p.cityCode == 'DXB' ? 'دبي' : p.cityCode);
      _areaCtrl.text = p.areaSqM.toInt().toString();
      _rentAmountCtrl.text = (p.pricePerMonth * 12).toInt().toString();
      _depositCtrl.text = (p.pricePerMonth * 2).toInt().toString();
    }

    _clauses = LegalClausesService.getStandardClauses(country);
  }

  void _onCountryChanged(String newCountry) {
    setState(() {
      _countryCode = newCountry;
      _initDefaultsForCountry(newCountry);
    });
  }

  Future<void> _openOcrExtractor(String targetParty) async {
    DocumentOcrType docType = DocumentOcrType.egyptianNationalId;
    if (targetParty == 'property') {
      docType = DocumentOcrType.titleDeed;
    } else if (targetParty == 'contract') {
      docType = DocumentOcrType.leaseAgreement;
    } else if (_countryCode == 'AE') {
      docType = DocumentOcrType.emiratesId;
    }

    final result = await AiDocumentOcrModal.show(
      context,
      countryCode: _countryCode,
      targetParty: targetParty,
      docType: docType,
    );

    if (result != null && mounted) {
      final loc = AppLocalizations.of(context);
      setState(() {
        if (targetParty == 'lessor') {
          _lessorNameCtrl.text = result.fullNameAr.isNotEmpty ? result.fullNameAr : result.fullNameEn;
          _lessorIdCtrl.text = result.idNumber;
          _lessorAddressCtrl.text = result.address;
          if (result.phoneNumber != null) _lessorPhoneCtrl.text = result.phoneNumber!;
          if (result.email != null) _lessorEmailCtrl.text = result.email!;
        } else if (targetParty == 'tenant') {
          _tenantNameCtrl.text = result.fullNameAr.isNotEmpty ? result.fullNameAr : result.fullNameEn;
          _tenantIdCtrl.text = result.idNumber;
          _tenantAddressCtrl.text = result.address;
          if (result.phoneNumber != null) _tenantPhoneCtrl.text = result.phoneNumber!;
          if (result.email != null) _tenantEmailCtrl.text = result.email!;
        } else if (targetParty == 'property') {
          if (result.propertyTitle != null) _propTitleCtrl.text = result.propertyTitle!;
          if (result.unitNumber != null) _unitNumberCtrl.text = result.unitNumber!;
          if (result.buildingName != null) _buildingNameCtrl.text = result.buildingName!;
          if (result.district != null) _districtCtrl.text = result.district!;
          if (result.city != null) _cityCtrl.text = result.city!;
          if (result.areaSqm != null) _areaCtrl.text = '${result.areaSqm!.toInt()}';
          if (result.floor != null) _floorCtrl.text = result.floor!;
          if (result.makaniNumber != null) _makaniCtrl.text = result.makaniNumber!;
          if (result.dewaNumber != null) _dewaCtrl.text = result.dewaNumber!;
          if (result.titleDeedNumber != null) _titleDeedCtrl.text = result.titleDeedNumber!;
          if (result.annualRent != null) _rentAmountCtrl.text = '${result.annualRent!.toInt()}';
          if (result.securityDeposit != null) _depositCtrl.text = '${result.securityDeposit!.toInt()}';
          if (result.chequesCount != null) _numberOfCheques = result.chequesCount!;
        }
      });

      TashilSnackBar.showSuccess(
        context: context,
        message: loc.tr('autofilledSuccessNotice'),
      );
    }
  }

  LeaseContractModel _buildContractModel() {
    final rent = double.tryParse(_rentAmountCtrl.text) ?? 25000;
    final isAE = _countryCode == 'AE';
    final currency = isAE ? 'AED' : 'EGP';
    final deposit = double.tryParse(_depositCtrl.text) ?? (isAE ? rent * 0.05 : rent * 2);

    final monthlyRent = _paymentFrequency == 'monthly'
        ? rent
        : (_paymentFrequency == 'annual' ? rent / 12 : rent / 4);

    // Generate PDC Cheques if UAE
    final cheques = <ChequeDetail>[];
    if (isAE && _numberOfCheques > 0) {
      final perCheque = rent / _numberOfCheques;
      final monthsInterval = (12 / _numberOfCheques).round();
      for (int i = 0; i < _numberOfCheques; i++) {
        cheques.add(
          ChequeDetail(
            chequeNumber: 'CHQ-${8000 + i + 1}',
            bankName: 'Emirates NBD',
            dueDate: _startDate.add(Duration(days: i * monthsInterval * 30)),
            amount: perCheque,
            status: i == 0 ? 'cleared' : 'pending',
          ),
        );
      }
    }

    final randNum = Random().nextInt(9000) + 1000;
    final isEdit = widget.initialContract != null;
    final contractId = isEdit ? widget.initialContract!.id : 'lease_${DateTime.now().millisecondsSinceEpoch}';
    final contractNum = isEdit ? widget.initialContract!.contractNumber : (isAE ? 'AE-DXB-EJARI-$randNum' : 'EG-2026-CAI-$randNum');
    final createdAt = isEdit ? widget.initialContract!.createdAt : DateTime.now();
    final registryId = isEdit ? widget.initialContract!.registeredRegistryId : (isAE ? 'Ejari No: 2026-$randNum-DXB' : 'توثيق شهر عقاري: $randNum/2026');

    return LeaseContractModel(
      id: contractId,
      contractNumber: contractNum,
      countryCode: _countryCode,
      status: (_lessorSignature != null && _tenantSignature != null)
          ? 'active'
          : (_lessorSignature != null || _tenantSignature != null ? 'pending_signatures' : 'draft'),
      startDate: _startDate,
      endDate: _endDate,
      lessor: ContractParty(
        name: _lessorNameCtrl.text.trim(),
        nationalIdOrEmiratesId: _lessorIdCtrl.text.trim(),
        nationality: isEdit ? widget.initialContract!.lessor.nationality : (isAE ? 'إماراتي' : 'مصري'),
        phone: _lessorPhoneCtrl.text.trim(),
        email: _lessorEmailCtrl.text.trim(),
        address: _lessorAddressCtrl.text.trim(),
        isLessor: true,
      ),
      tenant: ContractParty(
        name: _tenantNameCtrl.text.trim(),
        nationalIdOrEmiratesId: _tenantIdCtrl.text.trim(),
        nationality: isEdit ? widget.initialContract!.tenant.nationality : (isAE ? 'بريطاني' : 'مصري'),
        phone: _tenantPhoneCtrl.text.trim(),
        email: _tenantEmailCtrl.text.trim(),
        address: _tenantAddressCtrl.text.trim(),
        isLessor: false,
      ),
      property: LeasePropertySpec(
        propertyTitle: _propTitleCtrl.text.trim(),
        unitNumber: _unitNumberCtrl.text.trim(),
        buildingName: _buildingNameCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        countryCode: _countryCode,
        areaSqm: int.tryParse(_areaCtrl.text) ?? 140,
        propertyType: isEdit ? widget.initialContract!.property.propertyType : 'apartment',
        floorNumber: _floorCtrl.text.trim(),
        makaniNumber: isAE ? _makaniCtrl.text.trim() : null,
        dewaPremiseNumber: isAE ? _dewaCtrl.text.trim() : null,
        titleDeedNumber: _titleDeedCtrl.text.trim(),
      ),
      financialTerms: FinancialTerms(
        totalRentAmount: rent,
        monthlyRentEquivalent: monthlyRent,
        currencyCode: currency,
        paymentFrequency: _paymentFrequency,
        numberOfCheques: _numberOfCheques,
        securityDeposit: deposit,
        annualIncreasePercentage: _annualIncreasePct,
        cheques: cheques.isNotEmpty ? cheques : (isEdit ? widget.initialContract!.financialTerms.cheques : const []),
      ),
      clauses: _clauses,
      lessorSignature: _lessorSignature,
      tenantSignature: _tenantSignature,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      registeredRegistryId: registryId,
      isDeleted: isEdit ? widget.initialContract!.isDeleted : false,
      deletedAt: isEdit ? widget.initialContract!.deletedAt : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        return Dialog.fullscreen(
          backgroundColor: theme.colorScheme.surface,
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 1,
              automaticallyImplyLeading: false,
              title: isMobile
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.description_rounded, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.initialContract != null ? loc.tr('editContractBtn') : loc.tr('digitalLeaseBuilder'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
              actions: [
                // Country Switcher (Official M3 TashilConnectedButtonGroup)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: TashilConnectedButtonGroup<String>(
                    height: 38,
                    selectedValue: _countryCode,
                    onSelectionChanged: (selected) => _onCountryChanged(selected),
                    segments: [
                      TashilConnectedButtonSegment(
                        value: 'EG',
                        label: loc.tr('country_eg'),
                        icon: Icons.flag_rounded,
                      ),
                      TashilConnectedButtonSegment(
                        value: 'AE',
                        label: loc.tr('country_ae'),
                        icon: Icons.flag_rounded,
                      ),
                    ],
                  ),
                ),
                // Shaded Close Button (Official M3 TashilIconButton.close)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: TashilIconButton.close(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Mobile Dedicated Title Bar (prevents header overflow and provides breathing space)
                if (isMobile) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.description_rounded, color: theme.colorScheme.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.tr('digitalLeaseBuilder'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Step Indicator Tracker (M3 Expressive Connected Stepper)
                _buildStepTracker(loc, isMobile),
                const TashilDivider.fullWidth(),

                // Active Step Content
                Expanded(
                  child: _buildCurrentStepContent(context, loc, isMobile),
                ),

                // Bottom Navigation Footer
                _buildBottomNavFooter(loc, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepTracker(AppLocalizations loc, bool isMobile) {
    final theme = Theme.of(context);
    final steps = [
      loc.tr('stepParties'),
      loc.tr('stepProperty'),
      loc.tr('stepFinancials'),
      loc.tr('stepClauses'),
      loc.tr('stepPreviewSign'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(steps.length, (index) {
              final isActive = index == _currentStep;
              final isDone = index < _currentStep;

              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _currentStep = index),
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : (isActive ? 14 : 10),
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : (isDone
                                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isActive
                              ? theme.colorScheme.primary
                              : (isDone
                                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? theme.colorScheme.onPrimary
                                  : (isDone
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHighest),
                            ),
                            alignment: Alignment.center,
                            child: isDone
                                ? Icon(Icons.check_rounded, size: 14, color: theme.colorScheme.onPrimary)
                                : Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                steps[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive
                                      ? theme.colorScheme.onPrimary
                                      : (isDone
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context, AppLocalizations loc, bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Parties(loc, isMobile);
      case 1:
        return _buildStep2Property(loc, isMobile);
      case 2:
        return _buildStep3Financials(loc, isMobile);
      case 3:
        return _buildStep4Clauses(loc, isMobile);
      case 4:
        return LeaseDocumentView(
          contract: _buildContractModel(),
          onContractUpdated: (updated) {
            setState(() {
              _lessorSignature = updated.lessorSignature;
              _tenantSignature = updated.tenantSignature;
            });
          },
        );
      default:
        return const SizedBox();
    }
  }

  // --- Step 1: Parties ---
  Widget _buildStep1Parties(AppLocalizations loc, bool isMobile) {
    final isAE = _countryCode == 'AE';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepBanner(
                loc.tr('step1Title'),
                isAE ? loc.tr('step1Subtitle_ae') : loc.tr('step1Subtitle_eg'),
                Icons.groups_rounded,
              ),
              const SizedBox(height: 24),

              // Lessor (First Party) - Responsive Layout for Mobile
              if (isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('lessorFirstParty'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    TashilButton.tonal(
                      onPressed: () => _openOcrExtractor('lessor'),
                      icon: Icons.document_scanner_rounded,
                      label: loc.tr('scanLessorIdBtn'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        loc.tr('lessorFirstParty'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TashilButton.tonal(
                      onPressed: () => _openOcrExtractor('lessor'),
                      icon: Icons.document_scanner_rounded,
                      label: loc.tr('scanLessorIdBtn'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _buildTextField(_lessorNameCtrl, loc.tr('lessorFullName'), Icons.person_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _lessorIdCtrl,
                      isAE ? loc.tr('emiratesId') : loc.tr('nationalId'),
                      Icons.badge_rounded,
                      isCode: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _lessorPhoneCtrl,
                      loc.tr('phone'),
                      Icons.phone_rounded,
                      isPhone: true,
                      hintText: '+20 100 000 0000',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _lessorEmailCtrl,
                      loc.tr('email'),
                      Icons.email_rounded,
                      isEmail: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _lessorAddressCtrl,
                      loc.tr('address'),
                      Icons.home_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tenant (Second Party) - Responsive Layout for Mobile
              if (isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('tenantSecondParty'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.secondary),
                    ),
                    const SizedBox(height: 8),
                    TashilButton.tonal(
                      onPressed: () => _openOcrExtractor('tenant'),
                      icon: Icons.document_scanner_rounded,
                      label: loc.tr('scanTenantIdBtn'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        loc.tr('tenantSecondParty'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TashilButton.tonal(
                      onPressed: () => _openOcrExtractor('tenant'),
                      icon: Icons.document_scanner_rounded,
                      label: loc.tr('scanTenantIdBtn'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _buildTextField(_tenantNameCtrl, loc.tr('tenantFullName'), Icons.person_outline_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _tenantIdCtrl,
                      isAE ? loc.tr('emiratesId') : loc.tr('nationalId'),
                      Icons.badge_rounded,
                      isCode: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _tenantPhoneCtrl,
                      loc.tr('phone'),
                      Icons.phone_rounded,
                      isPhone: true,
                      hintText: '+20 100 000 0000',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _tenantEmailCtrl,
                      loc.tr('email'),
                      Icons.email_rounded,
                      isEmail: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _tenantAddressCtrl,
                      loc.tr('address'),
                      Icons.home_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 2: Property ---
  Widget _buildStep2Property(AppLocalizations loc, bool isMobile) {
    final isAE = _countryCode == 'AE';
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepBanner(
                loc.tr('step2Title'),
                isAE ? loc.tr('step2Subtitle_ae') : loc.tr('step2Subtitle_eg'),
                Icons.apartment_rounded,
              ),
              const SizedBox(height: 16),

              if (isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAE ? loc.tr('unitAndTitleDeed_ae') : loc.tr('unitAndOwnershipDoc_eg'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    TashilButton.tonal(
                      onPressed: () => _openOcrExtractor('property'),
                      icon: Icons.document_scanner_rounded,
                      label: loc.tr('scanTitleDeedBtn'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isAE ? loc.tr('unitAndTitleDeed_ae') : loc.tr('unitAndOwnershipDoc_eg'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TashilButton.tonal(
                      onPressed: () => _openOcrExtractor('property'),
                      icon: Icons.document_scanner_rounded,
                      label: loc.tr('scanTitleDeedBtn'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              _buildTextField(_propTitleCtrl, loc.tr('propertyTitleField'), Icons.home_work_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _unitNumberCtrl,
                      loc.tr('unitNumber'),
                      Icons.door_front_door_rounded,
                      isCode: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _buildingNameCtrl,
                      loc.tr('buildingName'),
                      Icons.business_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _districtCtrl,
                      loc.tr('districtCity'),
                      Icons.map_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _cityCtrl,
                      loc.tr('city'),
                      Icons.location_city_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _areaCtrl,
                      loc.tr('areaSqm'),
                      Icons.square_foot_rounded,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _floorCtrl,
                      loc.tr('floorNumber'),
                      Icons.stairs_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Country Specific Legal Numbers
              if (isAE) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _makaniCtrl,
                        loc.tr('makaniNumber'),
                        Icons.pin_drop_rounded,
                        isCode: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _dewaCtrl,
                        loc.tr('dewaPremiseNo'),
                        Icons.electric_bolt_rounded,
                        isCode: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              _buildTextField(
                _titleDeedCtrl,
                isAE ? loc.tr('titleDeedNumber') : loc.tr('ownershipDocNumber'),
                Icons.receipt_long_rounded,
                isCode: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 3: Financials ---
  Widget _buildStep3Financials(AppLocalizations loc, bool isMobile) {
    final isAE = _countryCode == 'AE';
    final currency = isAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepBanner(
                loc.tr('step3Title'),
                isAE ? loc.tr('step3Subtitle_ae') : loc.tr('step3Subtitle_eg'),
                Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 24),

              // Rent Amount & Security Deposit
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _rentAmountCtrl,
                      '${loc.tr('totalRentValue')} ($currency)',
                      Icons.payments_rounded,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _depositCtrl,
                      '${loc.tr('securityDepositAmount')} ($currency)',
                      Icons.shield_rounded,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Payment Frequency (TashilConnectedButtonGroup)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('paymentFrequency'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TashilConnectedButtonGroup<String>(
                      height: 42,
                      selectedValue: _paymentFrequency,
                      onSelectionChanged: (val) {
                        setState(() {
                          _paymentFrequency = val;
                          if (val == 'monthly') _numberOfCheques = 12;
                          if (val == 'quarterly') _numberOfCheques = 4;
                          if (val == 'semi_annual') _numberOfCheques = 2;
                          if (val == 'annual') _numberOfCheques = 1;
                        });
                      },
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 'monthly',
                          label: loc.tr('freq_monthly'),
                          icon: Icons.calendar_month_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'quarterly',
                          label: loc.tr('freq_quarterly'),
                          icon: Icons.date_range_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'semi_annual',
                          label: loc.tr('freq_semi_annual'),
                          icon: Icons.event_repeat_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'annual',
                          label: loc.tr('freq_annual'),
                          icon: Icons.event_available_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Number of Cheques (TashilConnectedButtonGroup)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('numberOfPdcCheques'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TashilConnectedButtonGroup<int>(
                      height: 40,
                      selectedValue: _numberOfCheques,
                      onSelectionChanged: (val) => setState(() => _numberOfCheques = val),
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 1,
                          label: '1',
                          icon: Icons.receipt_long_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 2,
                          label: '2',
                          icon: Icons.receipt_long_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 4,
                          label: '4',
                          icon: Icons.receipt_long_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 6,
                          label: '6',
                          icon: Icons.receipt_long_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 12,
                          label: '12',
                          icon: Icons.receipt_long_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Lease Dates (LTR-aware) - Responsive Column on Mobile, Row on Desktop
              if (isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('leaseStartDate'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            _endDate = picked.add(const Duration(days: 365));
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '${_startDate.year}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.tr('leaseEndDate'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_available_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '${_endDate.year}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('leaseStartDate'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDate = picked;
                                  _endDate = picked.add(const Duration(days: 365));
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        '${_startDate.year}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('leaseEndDate'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.event_available_rounded, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        '${_endDate.year}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Annual Rent Escalation (Official M3 TashilSlider)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('annualEscalationRate'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${_annualIncreasePct.toInt()}%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TashilSlider(
                    value: _annualIncreasePct,
                    min: 0.0,
                    max: 20.0,
                    divisions: 20,
                    trackHeight: 16.0,
                    handleType: TashilSliderHandleType.verticalBar,
                    valueLabelFormatter: (val) => '${val.toInt()}%',
                    onChanged: (val) => setState(() => _annualIncreasePct = val),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAE ? loc.tr('reraEscalationHint') : loc.tr('egEscalationHint'),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 4: Legal Clauses ---
  Widget _buildStep4Clauses(AppLocalizations loc, [bool isMobile = false]) {
    final lang = LocaleController.languageCode;
    final isAE = _countryCode == 'AE';
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepBanner(
                loc.tr('step4Title'),
                isAE ? loc.tr('step4Subtitle_ae') : loc.tr('step4Subtitle_eg'),
                Icons.gavel_rounded,
              ),
              const SizedBox(height: 20),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _clauses.length,
                itemBuilder: (context, index) {
                  final clause = _clauses[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: clause.isEnabled ? theme.colorScheme.surfaceContainer : theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: clause.isEnabled
                            ? theme.colorScheme.outlineVariant
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: TashilSwitchListTile(
                      value: clause.isEnabled,
                      enabled: !clause.isMandatory,
                      onChanged: (val) {
                        setState(() {
                          _clauses[index] = clause.copyWith(isEnabled: val);
                        });
                      },
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              clause.getLocalizedTitle(lang),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: clause.isEnabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (clause.isMandatory) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                              ),
                              child: Text(
                                loc.tr('mandatoryClause'),
                                style: TextStyle(color: theme.colorScheme.error, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          clause.getLocalizedBody(lang),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: clause.isEnabled
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // AI Legal Clause Advisor CTA (3-Tier Layout on Mobile: Line 1 Title+Icon, Line 2 Subtitle, Line 3 Action Button)
              Container(
                padding: EdgeInsets.all(isMobile ? 14 : 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line 1: Header Row with Icon and Title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loc.tr('legalAiAdvisorTitle'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Line 2: Descriptive Subtitle
                          Text(
                            loc.tr('legalAiAdvisorSubtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Line 3: Full-Width Action Button
                          SizedBox(
                            width: double.infinity,
                            child: TashilButton(
                              onPressed: () => _openAiClauseAdvisor(context, loc),
                              icon: Icons.auto_awesome_rounded,
                              label: loc.tr('auditClauseWithAiBtn'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr('legalAiAdvisorTitle'),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc.tr('legalAiAdvisorSubtitle'),
                                  style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          TashilButton(
                            onPressed: () => _openAiClauseAdvisor(context, loc),
                            icon: Icons.auto_awesome_rounded,
                            label: loc.tr('auditClauseWithAiBtn'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiClauseAdvisor(BuildContext context, AppLocalizations loc) {
    AiLegalClauseAdvisorDialog.show(
      context,
      onClauseApplied: (newClauseBody) {
        setState(() {
          _clauses.add(
            LegalClause(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              titleAr: loc.tr('aiAuditedClause'),
              titleEn: loc.tr('aiAuditedClause'),
              titleHi: loc.tr('aiAuditedClause'),
              bodyAr: newClauseBody,
              bodyEn: newClauseBody,
              bodyHi: newClauseBody,
              isMandatory: false,
              isEnabled: true,
            ),
          );
        });
      },
    );
  }

  Widget _buildStepBanner(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isPhone = false,
    bool isCode = false,
    bool isEmail = false,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    final isLtr = isNumber || isPhone || isCode || isEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isPhone
              ? TextInputType.phone
              : (isNumber
                  ? TextInputType.number
                  : (isEmail ? TextInputType.emailAddress : TextInputType.text)),
          textDirection: isLtr ? TextDirection.ltr : null,
          textAlign: isLtr ? TextAlign.left : TextAlign.start,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isLtr ? FontWeight.w600 : FontWeight.normal,
            color: theme.colorScheme.onSurface,
            letterSpacing: isCode ? 0.6 : (isPhone ? 0.4 : 0.0),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.primary),
            hintText: hintText,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavFooter(AppLocalizations loc, [bool isMobile = false]) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TashilDivider.cardAction(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  flex: isMobile ? 1 : 0,
                  child: TashilButton.outlined(
                    onPressed: () => setState(() => _currentStep--),
                    icon: Icons.arrow_back_rounded,
                    label: loc.tr('previousStep'),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 10),
              Expanded(
                flex: isMobile ? 1 : 0,
                child: _currentStep < 4
                    ? TashilButton(
                        onPressed: () => setState(() => _currentStep++),
                        icon: Icons.arrow_forward_rounded,
                        label: loc.tr('nextStep'),
                      )
                    : TashilButton(
                        onPressed: () async {
                          final contract = _buildContractModel();
                          if (widget.targetProperty != null) {
                            final duration = ((contract.endDate.difference(contract.startDate).inDays) / 30).round();
                            await PropertyLifecycleService().markAsRented(
                              propertyId: widget.targetProperty!.id,
                              tenantName: contract.tenant.name,
                              tenantPhone: contract.tenant.phone,
                              monthlyRent: contract.financialTerms.monthlyRentEquivalent,
                              startDate: contract.startDate,
                              endDate: contract.endDate,
                              durationMonths: duration > 0 ? duration : 12,
                              firstMonthPaid: false,
                            );
                          }
                          LegalClausesService().addOrUpdateContract(contract);
                          widget.onContractCreated?.call(contract);
                          if (!mounted) return;
                          Navigator.of(context).pop(contract);
                        },
                        icon: Icons.check_circle_rounded,
                        label: widget.initialContract != null
                            ? loc.tr('saveChangesAction')
                            : loc.tr('finishAndSaveLease'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
