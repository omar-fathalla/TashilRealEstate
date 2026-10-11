import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/rent_collection/models/rent_invoice_model.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';

class _RegisteredUnitOption {
  final String id;
  final String title;
  final String unitNumber;
  final String buildingName;
  final String district;
  final String contractNumber;
  final double baseRent;
  final double dailyPenalty;
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final String tenantId;
  final String countryCode;

  const _RegisteredUnitOption({
    required this.id,
    required this.title,
    required this.unitNumber,
    required this.buildingName,
    required this.district,
    required this.contractNumber,
    required this.baseRent,
    required this.dailyPenalty,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.tenantId,
    required this.countryCode,
  });
}

class CreateRentInvoiceDialog extends StatefulWidget {
  const CreateRentInvoiceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CreateRentInvoiceDialog(),
    );
  }

  @override
  State<CreateRentInvoiceDialog> createState() => _CreateRentInvoiceDialogState();
}

class _CreateRentInvoiceDialogState extends State<CreateRentInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = RentCollectionService();

  late final List<_RegisteredUnitOption> _unitOptions;
  late String _selectedUnitId;

  late final TextEditingController _unitTitleCtrl;
  late final TextEditingController _unitNumberCtrl;
  late final TextEditingController _buildingNameCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _tenantNameCtrl;
  late final TextEditingController _tenantPhoneCtrl;
  late final TextEditingController _tenantEmailCtrl;
  late final TextEditingController _tenantIdCtrl;
  late final TextEditingController _baseRentCtrl;
  late final TextEditingController _penaltyRateCtrl;
  late final TextEditingController _contractNumberCtrl;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 5));
  int _graceDays = 5;

  List<_RegisteredUnitOption> _buildUnitOptions(bool isUAE) {
    final options = <_RegisteredUnitOption>[];
    final targetCode = isUAE ? 'AE' : 'EG';

    // 1. Standard registered unit templates (preserves baseline defaults and test expectations)
    final templateList = isUAE
        ? [
            const _RegisteredUnitOption(
              id: 'unit_ae_1',
              title: 'Luxury Marina View 2BR',
              unitNumber: '1402',
              buildingName: 'Marina Heights',
              district: 'دبي مارينا',
              contractNumber: 'AE-2026-DXB-9042',
              baseRent: 12000,
              dailyPenalty: 150,
              tenantName: 'Alexander Wright',
              tenantPhone: '+971501234567',
              tenantEmail: 'alex.wright@email.ae',
              tenantId: '784-1992-1234567-1',
              countryCode: 'AE',
            ),
            const _RegisteredUnitOption(
              id: 'unit_ae_2',
              title: 'Luxury 2BR Apartment with Marina View',
              unitNumber: 'Unit 2204',
              buildingName: 'Marina Gate 2',
              district: 'دبي مارينا',
              contractNumber: 'AE-2026-DXB-9021',
              baseRent: 18000,
              dailyPenalty: 150,
              tenantName: 'James Arthur Wilson',
              tenantPhone: '+971501234567',
              tenantEmail: 'james.wilson@dubai.ae',
              tenantId: '784-1990-1234567-1',
              countryCode: 'AE',
            ),
            const _RegisteredUnitOption(
              id: 'unit_ae_3',
              title: 'Executive 1BR Suite near Burj Khalifa',
              unitNumber: 'Suite 1805',
              buildingName: 'The Address Downtown',
              district: 'وسط مدينة دبي',
              contractNumber: 'AE-2026-DOWNTOWN-4412',
              baseRent: 14500,
              dailyPenalty: 100,
              tenantName: 'Vikram Rajesh Sharma',
              tenantPhone: '+971559876543',
              tenantEmail: 'vikram.sharma@techdxb.com',
              tenantId: '784-1988-7654321-2',
              countryCode: 'AE',
            ),
            const _RegisteredUnitOption(
              id: 'unit_ae_4',
              title: 'Beachfront 3BR Penthouse',
              unitNumber: 'Penthouse 45',
              buildingName: 'Rimal 1',
              district: 'جميرا بيتش ريزيدنس (JBR)',
              contractNumber: 'AE-2026-JBR-5510',
              baseRent: 24000,
              dailyPenalty: 200,
              tenantName: 'Elena Rostova',
              tenantPhone: '+971521122334',
              tenantEmail: 'elena.rostova@consult.ae',
              tenantId: '784-1994-3344556-3',
              countryCode: 'AE',
            ),
          ]
        : [
            const _RegisteredUnitOption(
              id: 'unit_eg_1',
              title: 'شقة فاخرة بالتجمع الخامس',
              unitNumber: '302',
              buildingName: 'عمارة النرجس 88',
              district: 'القاهرة الجديدة',
              contractNumber: 'EG-2026-CAI-7719',
              baseRent: 22000,
              dailyPenalty: 50,
              tenantName: 'محمود عبدالحميد السعدني',
              tenantPhone: '+201098765432',
              tenantEmail: 'm.elsadani@gmail.com',
              tenantId: '29004051234567',
              countryCode: 'EG',
            ),
            const _RegisteredUnitOption(
              id: 'unit_eg_2',
              title: 'فيلا مستقلة بحمام سباحة',
              unitNumber: 'Villa 12',
              buildingName: 'كمبوند الربوة',
              district: 'الشيخ زايد',
              contractNumber: 'EG-2026-ZAYED-1104',
              baseRent: 55000,
              dailyPenalty: 100,
              tenantName: 'سارة خالد الدسوقي',
              tenantPhone: '+201123456789',
              tenantEmail: 'sara.desouky@gmail.com',
              tenantId: '29505051234568',
              countryCode: 'EG',
            ),
            const _RegisteredUnitOption(
              id: 'unit_eg_3',
              title: 'دوبلكس حديث بحديقة خاصة',
              unitNumber: 'D-101',
              buildingName: 'كمبوند بالم هيلز',
              district: 'السادس من أكتوبر',
              contractNumber: 'EG-2026-OCT-3391',
              baseRent: 32000,
              dailyPenalty: 60,
              tenantName: 'كريم عصام الشناوي',
              tenantPhone: '+201234567890',
              tenantEmail: 'karim.chennawy@gmail.com',
              tenantId: '28803031234569',
              countryCode: 'EG',
            ),
            const _RegisteredUnitOption(
              id: 'unit_eg_4',
              title: 'شقة مطلة على النيل - جاردن سيتي',
              unitNumber: '701',
              buildingName: 'برج النيل بلازا',
              district: 'جاردن سيتي',
              contractNumber: 'EG-2026-CAI-3301',
              baseRent: 21000,
              dailyPenalty: 50,
              tenantName: 'أحمد محمود القاضي',
              tenantPhone: '+201012345678',
              tenantEmail: 'ahmed.kadi@gmail.com',
              tenantId: '29201011234567',
              countryCode: 'EG',
            ),
            const _RegisteredUnitOption(
              id: 'unit_eg_5',
              title: 'شاليه بحري صف أول - أمواج',
              unitNumber: '104',
              buildingName: 'قرية أمواج',
              district: 'الساحل الشمالي',
              contractNumber: 'EG-2026-SAH-5502',
              baseRent: 25000,
              dailyPenalty: 75,
              tenantName: 'عمر فاروق الشريف',
              tenantPhone: '+201009871234',
              tenantEmail: 'omar.elcherif@gmail.com',
              tenantId: '28907101234560',
              countryCode: 'EG',
            ),
          ];

    options.addAll(templateList);

    // 2. Incorporate live real properties from PropertyLifecycleService
    try {
      final managedProps = PropertyLifecycleService().propertiesNotifier.value;
      for (final p in managedProps) {
        if (p.countryCode == targetCode) {
          final title = p.getTitle('ar').isNotEmpty ? p.getTitle('ar') : p.getTitle('en');
          final cleanCity = p.cityCode.toUpperCase().replaceAll('_', '');
          final cleanPropId = p.id.replaceAll('prop-', '').replaceAll('-', '');
          final contractNumber = '${p.countryCode}-2026-$cleanCity-${cleanPropId.length > 4 ? cleanPropId.substring(cleanPropId.length - 4) : cleanPropId}';

          if (!options.any((o) => o.id == p.id || o.title == title)) {
            options.add(_RegisteredUnitOption(
              id: p.id,
              title: title,
              unitNumber: p.unitNumber,
              buildingName: p.buildingName,
              district: p.getLocation('ar'),
              contractNumber: contractNumber,
              baseRent: p.pricePerMonth,
              dailyPenalty: isUAE ? 100 : 50,
              tenantName: p.tenantName ?? (isUAE ? 'John Doe' : 'عميل مسجل'),
              tenantPhone: p.tenantPhone ?? (isUAE ? '+971500000000' : '+201000000000'),
              tenantEmail: isUAE ? 'tenant@example.ae' : 'tenant@example.eg',
              tenantId: isUAE ? '784-1990-0000000-0' : '29000000000000',
              countryCode: targetCode,
            ));
          }
        }
      }
    } catch (_) {}

    return options;
  }

  void _onSelectUnit(String unitId) {
    final unit = _unitOptions.firstWhere(
      (u) => u.id == unitId,
      orElse: () => _unitOptions.first,
    );
    setState(() {
      _selectedUnitId = unit.id;
      _unitTitleCtrl.text = unit.title;
      _unitNumberCtrl.text = unit.unitNumber;
      _buildingNameCtrl.text = unit.buildingName;
      _districtCtrl.text = unit.district;
      _contractNumberCtrl.text = unit.contractNumber;
      _baseRentCtrl.text = unit.baseRent.toStringAsFixed(0);
      _penaltyRateCtrl.text = unit.dailyPenalty.toStringAsFixed(0);
      _tenantNameCtrl.text = unit.tenantName;
      _tenantPhoneCtrl.text = unit.tenantPhone;
      _tenantEmailCtrl.text = unit.tenantEmail;
      _tenantIdCtrl.text = unit.tenantId;
    });
  }

  @override
  void initState() {
    super.initState();
    final isUAE = CountryController.isUAE;
    _unitOptions = _buildUnitOptions(isUAE);
    _selectedUnitId = _unitOptions.first.id;
    final initial = _unitOptions.first;

    _unitTitleCtrl = TextEditingController(text: initial.title);
    _unitNumberCtrl = TextEditingController(text: initial.unitNumber);
    _buildingNameCtrl = TextEditingController(text: initial.buildingName);
    _districtCtrl = TextEditingController(text: initial.district);
    _tenantNameCtrl = TextEditingController(text: initial.tenantName);
    _tenantPhoneCtrl = TextEditingController(text: initial.tenantPhone);
    _tenantEmailCtrl = TextEditingController(text: initial.tenantEmail);
    _tenantIdCtrl = TextEditingController(text: initial.tenantId);
    _baseRentCtrl = TextEditingController(text: initial.baseRent.toStringAsFixed(0));
    _penaltyRateCtrl = TextEditingController(text: initial.dailyPenalty.toStringAsFixed(0));
    _contractNumberCtrl = TextEditingController(text: initial.contractNumber);
  }

  @override
  void dispose() {
    _unitTitleCtrl.dispose();
    _unitNumberCtrl.dispose();
    _buildingNameCtrl.dispose();
    _districtCtrl.dispose();
    _tenantNameCtrl.dispose();
    _tenantPhoneCtrl.dispose();
    _tenantEmailCtrl.dispose();
    _tenantIdCtrl.dispose();
    _baseRentCtrl.dispose();
    _penaltyRateCtrl.dispose();
    _contractNumberCtrl.dispose();
    super.dispose();
  }

  void _submitInvoice() {
    if (!_formKey.currentState!.validate()) return;

    final isUAE = CountryController.isUAE;
    final now = DateTime.now();
    final randomSuffix = (1000 + (now.millisecondsSinceEpoch % 9000)).toString();
    final prefix = isUAE ? 'INV-AE-2026' : 'INV-EG-2026';
    final invId = 'inv_${isUAE ? "ae" : "eg"}_$randomSuffix';
    final invNumber = '$prefix-$randomSuffix';

    final baseAmount = double.tryParse(_baseRentCtrl.text) ?? (isUAE ? 10000.0 : 20000.0);
    final penaltyRate = double.tryParse(_penaltyRateCtrl.text) ?? (isUAE ? 100.0 : 50.0);

    final selectedUnit = _unitOptions.firstWhere(
      (u) => u.id == _selectedUnitId,
      orElse: () => _unitOptions.first,
    );

    final newInvoice = RentInvoiceModel(
      id: invId,
      invoiceNumber: invNumber,
      contractNumber: _contractNumberCtrl.text.trim(),
      countryCode: isUAE ? 'AE' : 'EG',
      unitTitle: _unitTitleCtrl.text.trim(),
      unitNumber: _unitNumberCtrl.text.trim(),
      buildingName: _buildingNameCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      propertyId: selectedUnit.id,
      monthKey: '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}',
      tenant: TenantInfo(
        name: _tenantNameCtrl.text.trim(),
        phone: _tenantPhoneCtrl.text.trim(),
        email: _tenantEmailCtrl.text.trim(),
        idNumber: _tenantIdCtrl.text.trim(),
      ),
      owner: OwnerPayoutInfo(
        name: isUAE ? 'عبدالله راشد النعيمي' : 'م. عمر طارق فتح الله',
        bankName: isUAE ? 'Emirates NBD' : 'البنك الأهلي المصري (NBE)',
        iban: isUAE ? 'AE400330005544332211009' : 'EG380003000012345678901234567',
        accountNumber: '10994821',
        walletOrVpa: isUAE ? 'abdullah@enbd' : 'omar.fathalla@instapay',
      ),
      baseAmount: baseAmount,
      dueDate: _dueDate,
      gracePeriodDays: _graceDays,
      dailyPenaltyRate: penaltyRate,
      status: 'due_soon',
      platformFeePercent: 1.5,
      payoutStatus: 'pending',
    );

    _service.addInvoice(newInvoice);

    final theme = Theme.of(context);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).tr('invoiceCreatedSuccess')),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = CountryController.isUAE;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 36,
        vertical: isMobile ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr('createNewRentInvoice'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  loc.tr('issueElectronicTaxInvoiceDesc'),
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TashilIconButton.close(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(height: 24, color: theme.colorScheme.outlineVariant),

                // Form Fields (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Property Unit & Contract Info
                        _buildSectionHeader(loc.tr('unitAndContractInfo'), Icons.apartment_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TashilDropdownMenu<String>(
                                value: _selectedUnitId,
                                labelText: loc.tr('propertyTitle'),
                                prefixIcon: Icons.apartment_rounded,
                                items: _unitOptions.map((unit) {
                                  return TashilDropdownMenuItem<String>(
                                    value: unit.id,
                                    label: unit.title,
                                    supportingText: '${unit.buildingName} - ${unit.unitNumber} (${unit.district})',
                                    icon: Icons.apartment_rounded,
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    _onSelectUnit(val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _contractNumberCtrl,
                                label: loc.tr('contractNumber'),
                                isNumber: true,
                                validator: (v) => v!.isEmpty ? loc.tr('requiredField') : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _unitNumberCtrl,
                                label: loc.tr('unitNumber'),
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _buildingNameCtrl,
                                label: loc.tr('buildingName'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _districtCtrl,
                                label: loc.tr('district'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Tenant Details
                        _buildSectionHeader(loc.tr('tenantDetailsTitle'), Icons.person_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _tenantNameCtrl,
                                label: loc.tr('tenantFullName'),
                                validator: (v) => v!.isEmpty ? loc.tr('requiredField') : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _tenantPhoneCtrl,
                                label: loc.tr('tenantPhoneNumber'),
                                isPhone: true,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v!.isEmpty ? loc.tr('requiredField') : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _tenantEmailCtrl,
                                label: loc.tr('tenantEmail'),
                                isEmail: true,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _tenantIdCtrl,
                                label: isUAE ? 'Emirates ID' : 'الرقم القومي',
                                isNumber: true,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Financials & Due Dates
                        _buildSectionHeader(loc.tr('financialTermsTitle'), Icons.payments_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _baseRentCtrl,
                                label: '${loc.tr('monthlyRentAmount')} ($currency)',
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? loc.tr('requiredField') : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _penaltyRateCtrl,
                                label: '${loc.tr('dailyPenaltyRate')} ($currency/${loc.tr('day')})',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Due Date & Grace Period Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _dueDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() => _dueDate = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(loc.tr('dueDate'), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                                          ),
                                        ],
                                      ),
                                      Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TashilDropdownMenu<int>(
                                value: _graceDays,
                                labelText: loc.tr('gracePeriod'),
                                prefixIcon: Icons.timelapse_rounded,
                                items: [
                                  TashilDropdownMenuItem<int>(
                                    value: 0,
                                    label: loc.tr('gracePeriodZero'),
                                    icon: Icons.timer_off_outlined,
                                  ),
                                  TashilDropdownMenuItem<int>(
                                    value: 3,
                                    label: loc.tr('gracePeriodOption').replaceAll('{days}', '3'),
                                    icon: Icons.hourglass_top_rounded,
                                  ),
                                  TashilDropdownMenuItem<int>(
                                    value: 5,
                                    label: loc.tr('gracePeriodOption').replaceAll('{days}', '5'),
                                    icon: Icons.hourglass_top_rounded,
                                  ),
                                  TashilDropdownMenuItem<int>(
                                    value: 7,
                                    label: loc.tr('gracePeriodOption').replaceAll('{days}', '7'),
                                    icon: Icons.hourglass_top_rounded,
                                  ),
                                  TashilDropdownMenuItem<int>(
                                    value: 10,
                                    label: loc.tr('gracePeriodOption').replaceAll('{days}', '10'),
                                    icon: Icons.hourglass_top_rounded,
                                  ),
                                  TashilDropdownMenuItem<int>(
                                    value: 14,
                                    label: loc.tr('gracePeriodOption').replaceAll('{days}', '14'),
                                    icon: Icons.hourglass_top_rounded,
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _graceDays = v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                TashilButton(
                  onPressed: _submitInvoice,
                  icon: Icons.verified_outlined,
                  label: loc.tr('issueAndSendInvoiceBtn'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isNumber = false,
    bool isPhone = false,
    bool isEmail = false,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isLtr = isNumber ||
        isPhone ||
        isEmail ||
        keyboardType == TextInputType.number ||
        keyboardType == TextInputType.phone ||
        keyboardType == TextInputType.emailAddress;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: isLtr ? TextDirection.ltr : null,
      textAlign: isLtr ? TextAlign.left : TextAlign.start,
      style: TextStyle(
        fontSize: 13,
        color: theme.colorScheme.onSurface,
        fontWeight: isLtr ? FontWeight.w600 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
