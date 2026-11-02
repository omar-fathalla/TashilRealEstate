import 'package:flutter/material.dart';
import 'tashil_navigation_bar.dart';

/// Interactive Showcase Dialog for Material Design 3 Navigation Bar & Badges.
class M3NavigationBarShowcaseDialog extends StatefulWidget {
  const M3NavigationBarShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const M3NavigationBarShowcaseDialog(),
    );
  }

  @override
  State<M3NavigationBarShowcaseDialog> createState() =>
      _M3NavigationBarShowcaseDialogState();
}

class _M3NavigationBarShowcaseDialogState
    extends State<M3NavigationBarShowcaseDialog> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'M3 Navigation Bar & Badges',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              '80dp height, Level 0 elevation, 64x32dp active indicator pill, and M3 Badges anchored to upper-trailing edges.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24.0),

            // Demo Navigation Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: TashilNavigationBar(
                destinations: [
                  TashilNavigationDestination(
                    icon: Icons.add_home_work_outlined,
                    selectedIcon: Icons.add_home_work_rounded,
                    label: 'رفع العقار',
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  TashilNavigationDestination(
                    icon: Icons.auto_awesome_outlined,
                    selectedIcon: Icons.auto_awesome_rounded,
                    label: 'التقييم',
                    badgeLabel: 'AI',
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  TashilNavigationDestination(
                    icon: Icons.analytics_outlined,
                    selectedIcon: Icons.analytics_rounded,
                    label: 'عقار ماب',
                    hasBadgeDot: true,
                    isSelected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  TashilNavigationDestination(
                    icon: Icons.tune_outlined,
                    selectedIcon: Icons.tune_rounded,
                    label: 'الإعدادات',
                    isSelected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
