import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';

import '../models/tenant_models.dart';
import '../services/tenant_lease_service.dart';

/// Reminders, receipts and lease offers sent to the tenant, with a read state.
class TenantNotificationsView extends StatefulWidget {
  final TenantLeaseService? service;
  const TenantNotificationsView({super.key, this.service});

  @override
  State<TenantNotificationsView> createState() => _TenantNotificationsViewState();
}

class _TenantNotificationsViewState extends State<TenantNotificationsView> {
  late final TenantLeaseService _service = widget.service ?? TenantLeaseService.instance;
  late final Stream<List<TenantNotification>> _stream = _service.watchNotifications();

  Future<void> _markRead(TenantNotification item) async {
    if (item.read) return;
    try {
      await _service.markRead(item.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final lang = locale.languageCode;
        return StreamBuilder<List<TenantNotification>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? const <TenantNotification>[];
            final unread = items.where((n) => !n.read).length;
            return ListView(
              padding: const EdgeInsetsDirectional.all(24),
              children: [
                Row(
                  children: [
                    Expanded(child: Text(loc.tr('tnNotifications'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                    if (unread > 0)
                      TashilButton(label: loc.tr('tnMarkAllRead'), icon: Icons.done_all_rounded, variant: TashilButtonVariant.tonal, onPressed: () => _service.markAllRead(items)),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.all(32),
                    child: Center(child: Text(loc.tr('tnNoNotifications'), style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
                  )
                else
                  for (final n in items)
                    Padding(
                      key: ValueKey(n.id),
                      padding: const EdgeInsetsDirectional.only(bottom: 8),
                      child: TashilCard.outlined(
                        padding: const EdgeInsetsDirectional.all(14),
                        onTap: () => _markRead(n),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded, color: n.read ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.titleFor(lang), style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(n.bodyFor(lang), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (!n.read) Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}
