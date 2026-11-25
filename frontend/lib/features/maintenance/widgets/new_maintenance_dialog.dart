import 'package:flutter/material.dart';

import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/services/media/media_picker_service.dart';
import '../models/maintenance_ticket.dart';
import '../services/maintenance_service.dart';

/// Photos are stored inline in the request document, so each one stays small.
const maxPhotoChars = 300000;
const maxPhotos = 3;

/// A tenant's new maintenance request (TAQ-111). It attaches itself to the tenant's active lease.
class NewMaintenanceDialog extends StatefulWidget {
  final MaintenanceService? service;
  final Future<List<String>> Function()? pickPhotos;

  const NewMaintenanceDialog({super.key, this.service, this.pickPhotos});

  static Future<bool?> show(BuildContext context, {MaintenanceService? service}) {
    return showDialog<bool>(context: context, builder: (_) => NewMaintenanceDialog(service: service));
  }

  @override
  State<NewMaintenanceDialog> createState() => _NewMaintenanceDialogState();
}

class _NewMaintenanceDialogState extends State<NewMaintenanceDialog> {
  late final MaintenanceService _service = widget.service ?? MaintenanceService.instance;
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _category = 'other';
  final List<String> _photos = [];
  bool _sending = false;
  bool _missingTitle = false;
  bool _photoTooLarge = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final picked = await (widget.pickPhotos ?? MediaPickerService().pickImages)();
    var tooLarge = false;
    setState(() {
      for (final photo in picked) {
        if (_photos.length >= maxPhotos) break;
        if (photo.length > maxPhotoChars) {
          tooLarge = true;
          continue;
        }
        _photos.add(photo);
      }
      _photoTooLarge = tooLarge;
    });
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty) {
      setState(() => _missingTitle = true);
      return;
    }
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _missingTitle = false;
    });
    try {
      await _service.create(
        title: _title.text,
        description: _description.text,
        category: _category,
        photos: _photos,
      );
      if (!mounted) return;
      navigator.pop(true);
    } on NoActiveLeaseException {
      if (mounted) {
        setState(() => _sending = false);
        TashilSnackBar.showError(context: context, message: loc.tr('mtNoActiveLease'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        TashilSnackBar.showError(context: context, message: loc.tr('mtSendFailed'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(loc.tr('mtNewRequest')),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _title,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: loc.tr('mtTitleLabel'),
                      errorText: _missingTitle ? loc.tr('fillAllFields') : null,
                    ),
                  ),
                  TextField(
                    controller: _description,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: InputDecoration(labelText: loc.tr('mtDescriptionLabel')),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(labelText: loc.tr('mtCategoryLabel')),
                    items: [
                      for (final c in maintenanceCategories) DropdownMenuItem(value: c, child: Text(loc.tr('mtCat_$c'))),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? 'other'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TashilButton(
                        label: loc.tr('mtAddPhotos'),
                        icon: Icons.add_a_photo_outlined,
                        variant: TashilButtonVariant.tonal,
                        onPressed: _photos.length >= maxPhotos ? null : _addPhotos,
                      ),
                      const SizedBox(width: 12),
                      Text('${_photos.length}/$maxPhotos'),
                    ],
                  ),
                  if (_photoTooLarge)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 8),
                      child: Text(loc.tr('mtPhotoTooLarge'), style: TextStyle(color: scheme.error)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TashilButton(label: loc.tr('cancel'), variant: TashilButtonVariant.text, onPressed: _sending ? null : () => Navigator.of(context).pop(false)),
            TashilButton(label: loc.tr('mtSubmit'), isLoading: _sending, onPressed: _sending ? null : _submit),
          ],
        );
      },
    );
  }
}
