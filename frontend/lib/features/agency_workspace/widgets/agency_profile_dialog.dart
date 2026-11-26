import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/agency_workspace/services/agency_identity.dart';

/// The agency account menu: who is signed in, the agency, and the account actions (TAQ-153).
/// It shows the real name, email and agency name, never placeholders, and has no counters of its
/// own: portfolio figures live in the Overview tab.
class AgencyProfileDialog extends StatelessWidget {
  final AgencyIdentity identity;
  final VoidCallback onDashboard;
  final VoidCallback onSettings;
  final VoidCallback onBrowse;
  final VoidCallback onSecurity;
  final VoidCallback onLogout;

  const AgencyProfileDialog({
    super.key,
    required this.identity,
    required this.onDashboard,
    required this.onSettings,
    required this.onBrowse,
    required this.onSecurity,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final agencyName = identity.agencyNameFor(language);
    final person = identity.personName.isEmpty ? loc.tr('agencyWorkspace') : identity.personName;
    final initials = identity.initials.isEmpty ? loc.tr('roleAgency').characters.first : identity.initials;

    return Dialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primary,
                    child: Text(
                      initials,
                      style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person,
                          key: const ValueKey('agency-profile-name'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: scheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (identity.email.isNotEmpty && identity.email != person)
                          Text(
                            identity.email,
                            key: const ValueKey('agency-profile-email'),
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          agencyName.isEmpty ? loc.tr('roleAgency') : agencyName,
                          key: const ValueKey('agency-profile-agency'),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TashilIconButton.close(
                    tooltip: loc.tr('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const TashilDivider.middleInset(),
              const SizedBox(height: 8),
              _MenuItem(icon: Icons.dashboard_outlined, title: loc.tr('dashboard'), onTap: onDashboard),
              _MenuItem(icon: Icons.tune_rounded, title: loc.tr('settings'), onTap: onSettings),
              _MenuItem(icon: Icons.travel_explore_rounded, title: loc.tr('browseAsVisitor'), onTap: onBrowse),
              if (identity.email.isNotEmpty)
                _MenuItem(icon: Icons.security_rounded, title: loc.tr('accountSecurity'), onTap: onSecurity),
              const SizedBox(height: 6),
              const TashilDivider.middleInset(),
              const SizedBox(height: 6),
              _MenuItem(icon: Icons.logout_rounded, title: loc.tr('logout'), isDestructive: true, onTap: onLogout),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({required this.icon, required this.title, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final itemColor = isDestructive ? scheme.error : scheme.onSurface;
    final iconColor = isDestructive ? scheme.error : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 19, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
                    color: itemColor,
                  ),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 16,
                color: isDestructive ? scheme.error.withAlpha(120) : scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Account security": confirms, then sends a password reset email to the signed-in account.
/// A failure is shown inside the dialog, which stays open so the person can try again.
Future<bool> showAgencyPasswordResetDialog(
  BuildContext context, {
  required String email,
  required Future<void> Function(String email) send,
}) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _PasswordResetDialog(email: email, send: send),
  );
  return sent == true;
}

class _PasswordResetDialog extends StatefulWidget {
  final String email;
  final Future<void> Function(String email) send;
  const _PasswordResetDialog({required this.email, required this.send});

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  bool _sending = false;
  bool _failed = false;

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await widget.send(widget.email);
      if (mounted) navigator.pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(loc.tr('securityResetTitle')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.tr('securityResetBody').replaceAll('{email}', widget.email)),
          if (_failed) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                loc.tr('securityResetFailed'),
                key: const ValueKey('security-reset-error'),
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TashilButton(
          label: loc.tr('cancel'),
          variant: TashilButtonVariant.text,
          height: 48,
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
        ),
        TashilButton(
          label: loc.tr('securityResetSend'),
          height: 48,
          isLoading: _sending,
          onPressed: _sending ? null : _submit,
        ),
      ],
    );
  }
}
