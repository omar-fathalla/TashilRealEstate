import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_builder_wizard_dialog.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/callable_error.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_data_service.dart';
import 'package:tashil_real_estate/features/requests/models/request_models.dart';
import 'package:tashil_real_estate/features/requests/services/requests_service.dart';
import 'package:tashil_real_estate/features/requests/widgets/request_inline_error.dart';

/// Whether the person signed in, so a lease is created on the server instead of in this browser.
bool get leasesAreServerBacked => PortfolioDataService.instance.isSignedIn;

/// Creates a lease through the `createLease` Cloud Function (TAQ-144): the same server flow the
/// tenant answers with `respondToLeaseOffer`. The dialog shows success only when the server has
/// created the lease; every refusal is shown inside the dialog as a translated message. Nothing is
/// kept in memory and no property is marked rented from here: the server does that when the
/// tenant accepts.
///
/// The tenant is picked from the people who applied for the property and were approved, because a
/// lease needs the tenant's account and there is no directory of tenant accounts to search.
class CreateLeaseDialog extends StatefulWidget {
  final List<ManagedPropertyModel>? properties;
  final ManagedPropertyModel? property;
  final PortfolioDataService? service;
  final RequestsService? requests;
  final DateTime Function()? now;

  const CreateLeaseDialog({super.key, this.properties, this.property, this.service, this.requests, this.now});

  /// Opens the dialog. Returns the new lease id, or null when nothing was created.
  static Future<String?> show(BuildContext context, {ManagedPropertyModel? property}) {
    return TashilTransitions.showM3Dialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CreateLeaseDialog(property: property),
    );
  }

  @override
  State<CreateLeaseDialog> createState() => _CreateLeaseDialogState();
}

class _CreateLeaseDialogState extends State<CreateLeaseDialog> {
  late final PortfolioDataService _service = widget.service ?? PortfolioDataService.instance;
  late final RequestsService _requests = widget.requests ?? RequestsService.instance;
  late final DateTime _today = (widget.now ?? DateTime.now)();
  late final Future<List<RentalApplicationItem>> _applicants = _loadApplicants();
  final _rent = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  // Optional terms (TAQ-164).
  final _lateFee = TextEditingController();
  final _graceDays = TextEditingController();
  final _bankName = TextEditingController();
  final _iban = TextEditingController();
  static final RegExp _ibanPattern = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$');
  final _errorKey = GlobalKey();
  ManagedPropertyModel? _property;
  RentalApplicationItem? _tenant;
  bool _saving = false;
  bool _missing = false;
  String? _error;

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _day(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  List<ManagedPropertyModel> get _units {
    final all = widget.properties ?? PropertyLifecycleService().propertiesNotifier.value;
    final country = CountryController.countryCode;
    return all.where((p) => !PropertyLifecycleService.isMockPropertyId(p.id) && p.countryCode == country).toList();
  }

  @override
  void initState() {
    super.initState();
    _start.text = _day(_today);
    _end.text = _day(DateTime(_today.year + 1, _today.month, _today.day));
    final given = widget.property;
    if (given != null) _choose(given);
  }

  @override
  void dispose() {
    _rent.dispose();
    _start.dispose();
    _end.dispose();
    _lateFee.dispose();
    _graceDays.dispose();
    _bankName.dispose();
    _iban.dispose();
    super.dispose();
  }

  Future<List<RentalApplicationItem>> _loadApplicants() async {
    final scope = await _service.scopeFor();
    if (scope == null) return const [];
    final requestScope = scope.isAgency ? RequestScope.agency(scope.value) : RequestScope.owner(scope.value);
    final all = await _requests.watchApplications(requestScope).first;
    return all.where((a) => a.status == 'approved' && a.applicantId.isNotEmpty).toList();
  }

  void _choose(ManagedPropertyModel? property) {
    setState(() {
      _property = property;
      _tenant = null;
      if (property != null) {
        final rent = property.pricePerMonth;
        _rent.text = rent == rent.roundToDouble() ? rent.toStringAsFixed(0) : rent.toString();
      }
    });
  }

  Future<void> _pick(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(_today.year - 1),
      lastDate: DateTime(_today.year + 15),
    );
    if (picked != null) setState(() => controller.text = _day(picked));
  }

  Future<void> _submit({required bool sendOffer}) async {
    final loc = AppLocalizations.of(context);
    final property = _property;
    final tenant = _tenant;
    final rent = double.tryParse(_rent.text.trim());
    final start = DateTime.tryParse(_start.text.trim());
    final end = DateTime.tryParse(_end.text.trim());
    if (property == null || tenant == null || rent == null || rent <= 0 || start == null || end == null) {
      setState(() {
        _missing = true;
        _error = null;
      });
      revealInlineError(_errorKey);
      return;
    }
    final feeText = _lateFee.text.trim();
    final graceText = _graceDays.text.trim();
    final lateFee = feeText.isEmpty ? null : double.tryParse(feeText);
    final grace = graceText.isEmpty ? null : int.tryParse(graceText);
    final iban = _iban.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final feeBad = (feeText.isNotEmpty && (lateFee == null || lateFee < 0)) || (graceText.isNotEmpty && (grace == null || grace < 0 || grace > 60));
    if (feeBad || (iban.isNotEmpty && !_ibanPattern.hasMatch(iban))) {
      setState(() {
        _missing = false;
        _error = loc.tr(feeBad ? 'ldLateFeeInvalid' : 'ldIbanInvalid');
      });
      revealInlineError(_errorKey);
      return;
    }
    if (!end.isAfter(start)) {
      setState(() {
        _missing = false;
        _error = loc.tr('ldDatesInvalid');
      });
      revealInlineError(_errorKey);
      return;
    }
    setState(() {
      _saving = true;
      _missing = false;
      _error = null;
    });
    try {
      final id = await _service.createLease(
        ownerId: _service.backend.currentUserId ?? '',
        propertyId: property.id,
        tenantId: tenant.applicantId,
        startDate: _day(start),
        endDate: _day(end),
        monthlyRent: rent,
        sendOffer: sendOffer,
        lateFeeAmount: lateFee,
        lateFeeGraceDays: grace,
        payoutBankName: _bankName.text.trim(),
        payoutIban: iban,
      );
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = loc.tr(leaseCreateErrorKey(describeCallableError(e).reason));
      });
      revealInlineError(_errorKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final units = _units;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: FutureBuilder<List<RentalApplicationItem>>(
              future: _applicants,
              builder: (context, snapshot) {
                final applicants = (snapshot.data ?? const <RentalApplicationItem>[]).where((a) => _property != null && a.listingId == _property!.id).toList();
                return Padding(
                  padding: const EdgeInsetsDirectional.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsetsDirectional.all(8),
                            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.description_rounded, color: scheme.onPrimaryContainer, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(loc.tr('ldCreateTitle'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                          TashilIconButton.close(onPressed: _saving ? null : () => Navigator.of(context).pop()),
                        ]),
                        const SizedBox(height: 16),
                        if (units.isEmpty && widget.property == null)
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(vertical: 24),
                            child: Text(loc.tr('ldNoProperties'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                          )
                        else ...[
                          DropdownButtonFormField<ManagedPropertyModel>(
                            key: ValueKey('property_${_property?.id}'),
                            initialValue: _property,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: loc.tr('ldProperty')),
                            items: [
                              for (final p in {if (widget.property != null) widget.property!, ...units})
                                DropdownMenuItem(value: p, child: Text(p.getTitle(locale.languageCode), overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: _saving ? null : _choose,
                          ),
                          const SizedBox(height: 12),
                          if (_property != null && snapshot.connectionState == ConnectionState.done && applicants.isEmpty)
                            Container(
                              padding: const EdgeInsetsDirectional.all(12),
                              decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
                              child: Text(loc.tr('ldNoApplicants'), style: TextStyle(color: scheme.onSurfaceVariant)),
                            )
                          else
                            DropdownButtonFormField<RentalApplicationItem>(
                              key: ValueKey('tenant_${_property?.id}_${_tenant?.id}'),
                              initialValue: _tenant,
                              isExpanded: true,
                              decoration: InputDecoration(labelText: loc.tr('ldTenant')),
                              items: [
                                for (final a in applicants)
                                  DropdownMenuItem(value: a, child: Text(a.applicantName.isEmpty ? a.applicantId : a.applicantName, overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: _saving || _property == null ? null : (a) => setState(() => _tenant = a),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _rent,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: loc.tr('monthlyRent'),
                              suffixText: loc.tr(CountryController.isUAE ? 'currency_ae' : 'currency_eg'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _dateField(loc, _start, loc.tr('ldStartDate'))),
                            const SizedBox(width: 12),
                            Expanded(child: _dateField(loc, _end, loc.tr('ldEndDate'))),
                          ]),
                          const SizedBox(height: 4),
                          Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              key: const ValueKey('lease_optional_terms'),
                              tilePadding: EdgeInsetsDirectional.zero,
                              childrenPadding: const EdgeInsetsDirectional.only(bottom: 8),
                              title: Text(loc.tr('ldOptionalTerms'), style: theme.textTheme.titleSmall),
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: TextField(
                                      key: const ValueKey('lease_late_fee'),
                                      controller: _lateFee,
                                      enabled: !_saving,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: loc.tr('ldLateFee'),
                                        helperText: loc.tr('ldLateFeeHelp'),
                                        suffixText: loc.tr(CountryController.isUAE ? 'currency_ae' : 'currency_eg'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      key: const ValueKey('lease_grace_days'),
                                      controller: _graceDays,
                                      enabled: !_saving,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(labelText: loc.tr('ldGraceDays'), hintText: '5'),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                TextField(
                                  key: const ValueKey('lease_payout_bank'),
                                  controller: _bankName,
                                  enabled: !_saving,
                                  decoration: InputDecoration(labelText: loc.tr('ldPayoutBank')),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  key: const ValueKey('lease_payout_iban'),
                                  controller: _iban,
                                  enabled: !_saving,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(labelText: loc.tr('ldPayoutIban')),
                                ),
                              ],
                            ),
                          ),
                          if (_missing || _error != null)
                            Padding(
                              key: _errorKey,
                              padding: const EdgeInsetsDirectional.only(top: 12),
                              child: RequestInlineError(message: _error ?? loc.tr('ldFillAll')),
                            ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              TashilButton.outlined(
                                label: loc.tr('ldSaveDraft'),
                                height: 48,
                                onPressed: _saving ? null : () => _submit(sendOffer: false),
                              ),
                              TashilButton.filled(
                                label: loc.tr('ldSendOffer'),
                                icon: Icons.send_rounded,
                                height: 48,
                                isLoading: _saving,
                                onPressed: _saving ? null : () => _submit(sendOffer: true),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _dateField(AppLocalizations loc, TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: _saving ? null : () => _pick(controller),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
      ),
    );
  }
}

/// The one place a lease is started from. Signed in, it creates the lease on the server; the
/// local document builder is only for the signed-out sample mode.
Future<void> openLeaseCreation(BuildContext context, {ManagedPropertyModel? property}) async {
  if (!leasesAreServerBacked) {
    await LeaseBuilderWizardDialog.show(context, targetProperty: property);
    return;
  }
  final loc = AppLocalizations.of(context);
  final id = await CreateLeaseDialog.show(context, property: property);
  if (id != null && context.mounted) TashilSnackBar.showSuccess(context: context, message: loc.tr('ldCreated'));
}
