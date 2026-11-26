import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../models/request_models.dart';
import '../services/requests_service.dart';
import 'request_inline_error.dart';

/// The visitor's form for asking to view a listing or to rent it (TAQ-112). Sending needs a
/// signed-in account and goes through the server; success is shown only after the server accepted it.
/// Every error is shown inside the sheet (TAQ-132): a snackbar on the root messenger would be
/// drawn under it. The sheet stays open with what was typed, and sending is possible again.
class RequestListingSheet extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  final RequestsService? service;

  const RequestListingSheet({
    super.key,
    required this.listingId,
    required this.listingTitle,
    this.service,
  });

  static Future<void> show(
    BuildContext context, {
    required String listingId,
    required String listingTitle,
    RequestsService? service,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => RequestListingSheet(listingId: listingId, listingTitle: listingTitle, service: service),
    );
  }

  @override
  State<RequestListingSheet> createState() => _RequestListingSheetState();
}

class _RequestListingSheetState extends State<RequestListingSheet> {
  late final RequestsService _service = widget.service ?? RequestsService.instance;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _errorKey = GlobalKey();
  bool _sending = false;

  /// The localization key of the error shown above the buttons, or null.
  String? _error;
  bool _nameMissing = false;
  bool _phoneMissing = false;

  bool get _contactError => _error == 'rqContactInMessage';

  void _fail(String key) {
    setState(() {
      _sending = false;
      _error = key;
    });
    revealInlineError(_errorKey);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send({required bool apply}) async {
    final loc = AppLocalizations.of(context);
    if (!_service.isSignedIn) {
      _fail('rqSignInRequired');
      return;
    }
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() {
        _nameMissing = name.isEmpty;
        _phoneMissing = phone.isEmpty;
      });
      _fail('fillAllFields');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
      _nameMissing = false;
      _phoneMissing = false;
    });
    try {
      if (apply) {
        await _service.applyForRental(listingId: widget.listingId, name: name, phone: phone, message: _note.text.trim());
      } else {
        await _service.requestViewing(listingId: widget.listingId, name: name, phone: phone, message: _note.text.trim());
      }
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(loc.tr(apply ? 'rqApplicationSent' : 'rqViewingSent'))));
    } catch (e) {
      if (mounted) _fail(requestErrorKey(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final signedIn = _service.isSignedIn;
        // The keyboard inset pads the outside of the scroll view, so the scroll area ends above the
        // keyboard and an error can be scrolled into view on a small screen.
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.tr('bookingTitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.listingTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (!signedIn) ...[
                    Text(loc.tr('rqSignInRequired'), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TashilButton(
                      label: loc.tr('rqSignInAction'),
                      icon: Icons.login_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/login');
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: loc.tr('fullName'),
                        errorText: _nameMissing ? loc.tr('fillAllFields') : null,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: loc.tr('phoneWhatsapp'),
                        errorText: _phoneMissing ? loc.tr('fillAllFields') : null,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      maxLines: 2,
                      maxLength: 500,
                      onChanged: (_) {
                        if (_contactError) setState(() => _error = null);
                      },
                      decoration: InputDecoration(
                        labelText: loc.tr('rqNoteOptional'),
                        errorText: _contactError ? loc.tr('rqContactInMessageField') : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_error != null) ...[
                      RequestInlineError(key: _errorKey, message: loc.tr(_error!)),
                      const SizedBox(height: 12),
                    ],
                    TashilButton(
                      label: loc.tr('rqSendViewing'),
                      icon: Icons.calendar_month_outlined,
                      isLoading: _sending,
                      onPressed: _sending ? null : () => _send(apply: false),
                    ),
                    const SizedBox(height: 8),
                    TashilButton(
                      label: loc.tr('rqApplyToRent'),
                      icon: Icons.assignment_outlined,
                      variant: TashilButtonVariant.outlined,
                      onPressed: _sending ? null : () => _send(apply: true),
                    ),
                  ],
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}
