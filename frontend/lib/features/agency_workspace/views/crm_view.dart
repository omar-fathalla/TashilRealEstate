import 'package:flutter/material.dart';

class CrmView extends StatelessWidget {
  const CrmView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CRM Pipeline',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildKanbanColumn(context, 'New Leads', colorScheme.primary, 3),
                  _buildKanbanColumn(context, 'Contacted', Colors.orange.shade600, 2),
                  _buildKanbanColumn(context, 'Viewing Scheduled', Colors.purple.shade500, 4),
                  _buildKanbanColumn(context, 'Negotiation', Colors.teal.shade600, 1),
                  _buildKanbanColumn(context, 'Closed Won', Colors.green.shade600, 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String title, Color color, int itemCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text('$itemCount', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lead Name', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Interested in Villa', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('2 days ago', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
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
