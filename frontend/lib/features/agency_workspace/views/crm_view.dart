import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';

class CrmView extends StatelessWidget {
  const CrmView({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('crmPipeline'),
              style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildKanbanColumn(context, loc.tr('crmNewLeads'), colorScheme.primary, 3, loc, colorScheme),
                  _buildKanbanColumn(context, loc.tr('crmContacted'), colorScheme.tertiary, 2, loc, colorScheme),
                  _buildKanbanColumn(context, loc.tr('crmViewingScheduled'), colorScheme.secondary, 4, loc, colorScheme),
                  _buildKanbanColumn(context, loc.tr('crmNegotiation'), colorScheme.primary, 1, loc, colorScheme),
                  _buildKanbanColumn(context, loc.tr('crmClosedWon'), colorScheme.secondary, 5, loc, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    String title,
    Color color,
    int itemCount,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 300,
      margin: const EdgeInsetsDirectional.only(end: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$itemCount', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return TashilCard.outlined(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: colorScheme.surfaceContainerLowest,
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${loc.tr('leadClientName')} #${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.tr('interestedInRentalUnit'),
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            loc.tr('twoDaysAgo'),
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
