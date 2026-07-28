import 'package:flutter/material.dart';

class TenantPaymentsView extends StatelessWidget {
  const TenantPaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                final isPaid = index > 0; // First item mock as overdue
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isPaid ? Colors.green.shade50 : colorScheme.errorContainer,
                      child: Icon(
                        isPaid ? Icons.check : Icons.warning_amber,
                        color: isPaid ? Colors.green.shade700 : colorScheme.error,
                      ),
                    ),
                    title: const Text('October Rent', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('15,000 EGP'),
                    trailing: Chip(
                      label: Text(
                        isPaid ? 'Paid' : 'Overdue',
                        style: TextStyle(
                          color: isPaid ? Colors.green.shade700 : colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: isPaid ? Colors.green.shade50 : colorScheme.errorContainer,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
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
