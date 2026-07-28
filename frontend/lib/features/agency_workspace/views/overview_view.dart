import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 32),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 250,
                  child: _buildKpiCard(context, 'Total Properties', '120', Icons.domain, colorScheme.primary)
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 250,
                  child: _buildKpiCard(context, 'Active Leases', '85', Icons.description, colorScheme.secondary)
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 250,
                  child: _buildKpiCard(context, 'Monthly Revenue', '450k EGP', Icons.payments, Colors.orange.shade700)
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 250,
                  child: _buildKpiCard(context, 'Pending Maintenance', '3', Icons.build, colorScheme.error)
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.notifications, color: colorScheme.onPrimaryContainer, size: 20),
                    ),
                    title: Text('Activity Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('2 hours ago', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
