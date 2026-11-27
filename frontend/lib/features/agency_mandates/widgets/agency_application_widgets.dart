import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/agency_mandates/models/mandate_models.dart';
import 'package:tashil_real_estate/features/agency_mandates/services/mandate_service.dart';
import 'package:tashil_real_estate/features/agency_mandates/widgets/mandate_stream.dart';
import 'package:tashil_real_estate/features/agency_mandates/widgets/mandate_panels.dart';

/// Apply to become an agency (TAQ-149). Shows the current application's status, and the form when
/// there is none or the last one was rejected. A SuperAdmin reviews it.
class AgencyApplicationDialog extends StatefulWidget {
  final MandateService? service;

  const AgencyApplicationDialog({super.key, this.service});

  static Future<void> show(BuildContext context, {MandateService? service}) =>
      showDialog<void>(context: context, builder: (_) => AgencyApplicationDialog(service: service));

  @override
  State<AgencyApplicationDialog> createState() => _AgencyApplicationDialogState();
}

class _AgencyApplicationDialogState extends State<AgencyApplicationDialog> {
  late final MandateService _service = widget.service ?? MandateService.instance;
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _orn = TextEditingController();
  final _licence = TextEditingController();
  final _phone = TextEditingController();
  String _country = 'AE';
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_name, _city, _orn, _licence, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final ok = await runMandateCall(
      context,
      () => _service.applyForAgency(
        name: _name.text,
        countryCode: _country,
        phone: _phone.text,
        city: _city.text,
        orn: _orn.text,
        licenceNumber: _licence.text,
      ),
      'aaSubmitted',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) Navigator.of(context).pop();
  }

  Widget _field(String key, TextEditingController c, String labelKey, AppLocalizations loc, {TextInputType? type}) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 12),
        child: TextField(
          key: ValueKey(key),
          controller: c,
          enabled: !_sending,
          keyboardType: type,
          decoration: InputDecoration(labelText: loc.tr(labelKey), border: const OutlineInputBorder(), isDense: true),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final uid = _service.backend.currentUserId;
    return AlertDialog(
      title: Text(loc.tr('aaTitle')),
      content: SizedBox(
        width: 420,
        child: uid == null
            ? Text(loc.tr('mdFailed'))
            : MandateStream<AgencyApplicationItem?>(
                cacheKey: uid,
                open: () => _service.backend.watchApplication(uid),
                builder: (context, snapshot) {
                  final current = snapshot.data;
                  if (current != null && (current.status == 'pending' || current.status == 'approved')) {
                    return Text(
                      loc.tr(current.status == 'pending' ? 'aaPendingStatus' : 'aaApprovedStatus'),
                      key: const ValueKey('agency_application_status'),
                    );
                  }
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (current != null && current.status == 'rejected')
                          Padding(
                            padding: const EdgeInsetsDirectional.only(bottom: 12),
                            child: Text(
                              [loc.tr('aaRejectedStatus'), if (current.reviewNote.isNotEmpty) current.reviewNote].join(' '),
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        Text(loc.tr('aaHelp'), style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        _field('aa_name', _name, 'aaName', loc),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('aa_country'),
                            initialValue: _country,
                            decoration: InputDecoration(labelText: loc.tr('aaCountry'), border: const OutlineInputBorder(), isDense: true),
                            items: [
                              DropdownMenuItem(value: 'AE', child: Text(loc.tr('country_ae'))),
                              DropdownMenuItem(value: 'EG', child: Text(loc.tr('country_eg'))),
                            ],
                            onChanged: _sending ? null : (v) => setState(() => _country = v ?? 'AE'),
                          ),
                        ),
                        _field('aa_city', _city, 'aaCity', loc),
                        _field('aa_orn', _orn, 'aaOrn', loc),
                        _field('aa_licence', _licence, 'aaLicence', loc),
                        _field('aa_phone', _phone, 'aaPhone', loc, type: TextInputType.phone),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(loc.tr('cancel'))),
        if (uid != null)
          MandateStream<AgencyApplicationItem?>(
            cacheKey: uid,
            open: () => _service.backend.watchApplication(uid),
            builder: (context, snapshot) {
              final status = snapshot.data?.status;
              if (status == 'pending' || status == 'approved') return const SizedBox.shrink();
              return FilledButton(
                key: const ValueKey('aa_submit'),
                onPressed: _sending ? null : _submit,
                child: Text(loc.tr('aaSubmit')),
              );
            },
          ),
      ],
    );
  }
}

/// SuperAdmin: pending agency applications, to approve or reject (TAQ-149). Shows nothing when
/// there are none or they cannot be read.
class AgencyApplicationsReviewPanel extends StatelessWidget {
  final MandateService? service;

  const AgencyApplicationsReviewPanel({super.key, this.service});

  Future<void> _reject(BuildContext context, MandateService svc, AgencyApplicationItem a) async {
    final loc = AppLocalizations.of(context);
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('aaReject')),
        content: TextField(
          key: const ValueKey('aa_reject_note'),
          controller: note,
          maxLength: 500,
          decoration: InputDecoration(labelText: loc.tr('aaRejectNote'), border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(loc.tr('cancel'))),
          FilledButton(key: const ValueKey('aa_reject_confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: Text(loc.tr('aaReject'))),
        ],
      ),
    );
    // Not disposed here: the dialog's field may still be animating out.
    final text = note.text;
    if (ok == true && context.mounted) {
      await runMandateCall(context, () => svc.review(a.uid, approve: false, note: text), 'aaRejectedDone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = service ?? MandateService.instance;
    final loc = AppLocalizations.of(context);
    return MandateStream<List<AgencyApplicationItem>>(
      cacheKey: svc,
      open: svc.backend.watchPendingApplications,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AgencyApplicationItem>[];
        if (snapshot.hasError || items.isEmpty) return const SizedBox.shrink();
        return Card(
          key: const ValueKey('agency_applications_panel'),
          margin: const EdgeInsetsDirectional.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${loc.tr('aaReviewTitle')} (${items.length})', style: Theme.of(context).textTheme.titleMedium),
                for (final a in items)
                  ListTile(
                    contentPadding: EdgeInsetsDirectional.zero,
                    title: Text(a.name),
                    subtitle: Text([
                      loc.tr(a.countryCode == 'EG' ? 'country_eg' : 'country_ae'),
                      if (a.city.isNotEmpty) a.city,
                      if (a.orn.isNotEmpty) '${loc.tr('aaOrn')} ${a.orn}',
                      if (a.licenceNumber.isNotEmpty) a.licenceNumber,
                      a.phone,
                    ].join(' · ')),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          key: ValueKey('aa_reject_${a.uid}'),
                          onPressed: () => _reject(context, svc, a),
                          child: Text(loc.tr('aaReject')),
                        ),
                        FilledButton(
                          key: ValueKey('aa_approve_${a.uid}'),
                          onPressed: () => runMandateCall(context, () => svc.review(a.uid, approve: true), 'aaApprovedDone'),
                          child: Text(loc.tr('aaApprove')),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
