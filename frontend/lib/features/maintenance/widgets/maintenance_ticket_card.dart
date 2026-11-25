import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/design_system/cards/tashil_cards.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/maintenance_ticket.dart';

class MaintenanceStatusChip extends StatelessWidget {
  final String status;
  const MaintenanceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      'resolved' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      'in_progress' => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      'escalated' => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(loc.tr('mtStatus_$status'), style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

Uint8List? _decodeDataUri(String uri) {
  final comma = uri.indexOf(',');
  if (!uri.startsWith('data:image/') || comma < 0) return null;
  try {
    return base64Decode(uri.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

/// One request: title, status, category, optional description, resolution note and inline photos.
class MaintenanceTicketCard extends StatelessWidget {
  final MaintenanceTicket ticket;
  final bool showTenant;
  final Widget? actions;

  const MaintenanceTicketCard({super.key, required this.ticket, this.showTenant = false, this.actions});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = [
      loc.tr('mtCat_${ticket.category}'),
      if (ticket.propertyTitle.isNotEmpty) ticket.propertyTitle,
      if (showTenant && ticket.tenantName.isNotEmpty) ticket.tenantName,
    ].join(' · ');
    final created = ticket.createdAt;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: TashilCard.outlined(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(ticket.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                MaintenanceStatusChip(status: ticket.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            if (ticket.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(ticket.description, style: theme.textTheme.bodyMedium),
            ],
            if (ticket.photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final photo in ticket.photos)
                    if (_decodeDataUri(photo) case final bytes?)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover, cacheWidth: 144),
                      ),
                ],
              ),
            ],
            if (ticket.resolutionNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${loc.tr('mtNote')}: ${ticket.resolutionNote}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            if (created != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(created.toIso8601String().substring(0, 10), style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ],
            if (actions != null) ...[const SizedBox(height: 12), actions!],
          ],
        ),
      ),
    );
  }
}
