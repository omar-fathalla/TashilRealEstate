import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';

/// Session consent before photos, voice, or document images are sent to AI.
///
/// The flag starts false. Callers must not tell the server the user agreed
/// until [ensure] returns true.
class AiProcessingConsent {
  AiProcessingConsent._();

  static bool granted = false;

  static Future<bool> ensure(BuildContext context) async {
    if (granted) return true;
    if (!context.mounted) return false;
    final loc = AppLocalizations.of(context);
    final accepted = await TashilAlertDialog.showConfirmation(
      context: context,
      title: loc.tr('aiProcessingConsentTitle'),
      message: loc.tr('aiProcessingConsentBody'),
      confirmLabel: loc.tr('aiProcessingConsentAccept'),
      cancelLabel: loc.tr('aiProcessingConsentDecline'),
      icon: Symbols.privacy_tip_rounded,
    );
    granted = accepted;
    return granted;
  }
}
