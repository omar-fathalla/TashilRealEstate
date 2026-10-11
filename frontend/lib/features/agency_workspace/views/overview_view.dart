import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;
          final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
          final padding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                _buildHeader(context, loc, colorScheme, isMobile),
                SizedBox(height: isMobile ? 20 : 28),

                // Responsive KPI Grid
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isMobile ? 2.4 : (isTablet ? 2.0 : 1.6),
                  children: [
                    _buildKpiCard(
                      context,
                      title: loc.tr('monthlyRevenue'),
                      value: '450,000 ${loc.tr('currency')}',
                      badgeText: loc.tr('growthRate'),
                      badgeColor: colorScheme.tertiary,
                      icon: Icons.account_balance_wallet_outlined,
                      accentColor: colorScheme.tertiary,
                    ),
                    _buildKpiCard(
                      context,
                      title: loc.tr('activeLeases'),
                      value: '85',
                      badgeText: loc.tr('occupancyRate'),
                      badgeColor: colorScheme.secondary,
                      icon: Icons.assignment_outlined,
                      accentColor: colorScheme.secondary,
                    ),
                    _buildKpiCard(
                      context,
                      title: loc.tr('totalProperties'),
                      value: '120',
                      badgeText: loc.tr('collectionRate'),
                      badgeColor: colorScheme.primary,
                      icon: Icons.apartment_outlined,
                      accentColor: colorScheme.primary,
                    ),
                    _buildKpiCard(
                      context,
                      title: loc.tr('pendingMaintenance'),
                      value: '3',
                      badgeText: loc.tr('urgentTickets'),
                      badgeColor: colorScheme.error,
                      icon: Icons.handyman_outlined,
                      accentColor: colorScheme.error,
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 28 : 36),

                // Recent Activities Card Section
                _buildRecentActivities(context, loc, colorScheme, isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr('dashboardOverview'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.tr('dashboardSubtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('dashboardOverview'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.tr('dashboardSubtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.tr('addNewProperty'))),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text(loc.tr('addNewProperty')),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    final theme = Theme.of(context);

    final activities = [
      {
        'title': loc.tr('activity1Title'),
        'time': loc.tr('activity1Time'),
        'icon': Icons.verified_outlined,
        'color': colorScheme.primary,
      },
      {
        'title': loc.tr('activity2Title'),
        'time': loc.tr('activity2Time'),
        'icon': Icons.handyman_outlined,
        'color': colorScheme.error,
      },
      {
        'title': loc.tr('activity3Title'),
        'time': loc.tr('activity3Time'),
        'icon': Icons.payments_outlined,
        'color': colorScheme.secondary,
      },
      {
        'title': loc.tr('activity4Title'),
        'time': loc.tr('activity4Time'),
        'icon': Icons.add_home_work_outlined,
        'color': colorScheme.secondary,
      },
      {
        'title': loc.tr('activity5Title'),
        'time': loc.tr('activity5Time'),
        'icon': Icons.autorenew_outlined,
        'color': colorScheme.tertiary,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.tr('recentActivities'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(loc.tr('viewAll')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TashilDivider.fullWidth(),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const TashilDivider.inset(startIndent: 56),
            itemBuilder: (context, index) {
              final item = activities[index];
              final iconColor = item['color'] as Color;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: iconColor, size: 20),
                ),
                title: Text(
                  item['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    item['time'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: colorScheme.outline,
                ),
                onTap: () {},
              );
            },
          ),
        ],
      ),
    );
  }
}
