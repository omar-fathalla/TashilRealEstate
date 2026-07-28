import 'package:flutter/material.dart';

class OwnerOverviewView extends StatelessWidget {
  const OwnerOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Overview',
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
                width: isMobile ? double.infinity : 300,
                child: _buildKpiCard(context, 'Total Units', '5', Icons.apartment, colorScheme.primary)
              ),
              SizedBox(
                width: isMobile ? double.infinity : 300,
                child: _buildKpiCard(context, 'Monthly Revenue', '75,000 EGP', Icons.payments, Colors.orange.shade700)
              ),
              SizedBox(
                width: isMobile ? double.infinity : 300,
                child: _buildKpiCard(context, 'Vacant Units', '1', Icons.door_front_door, colorScheme.error)
              ),
            ],
          ),
        ],
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
