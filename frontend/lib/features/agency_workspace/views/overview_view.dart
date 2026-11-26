import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/empty_state/tashil_empty_state.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_controller.dart';
import 'package:tashil_real_estate/features/portfolio/services/portfolio_stats.dart';

IconData activityIcon(ActivityKind kind) {
  switch (kind) {
    case ActivityKind.leaseDraft:
      return Icons.edit_note_outlined;
    case ActivityKind.leaseOffered:
      return Icons.send_outlined;
    case ActivityKind.leaseActive:
      return Icons.verified_outlined;
    case ActivityKind.leaseRejected:
      return Icons.cancel_outlined;
    case ActivityKind.leaseEnded:
      return Icons.event_busy_outlined;
    case ActivityKind.maintenance:
      return Icons.handyman_outlined;
    case ActivityKind.payment:
      return Icons.payments_outlined;
    case ActivityKind.viewing:
      return Icons.event_available_outlined;
    case ActivityKind.application:
      return Icons.assignment_ind_outlined;
  }
}

/// "5 minutes ago" style label from the dictionary, falling back to the date after a week.
String relativeTimeLabel(AppLocalizations loc, DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return loc.tr('timeJustNow');
  if (diff.inMinutes < 60) return loc.tr('timeMinutesAgo').replaceAll('{n}', '${diff.inMinutes}');
  if (diff.inHours < 24) return loc.tr('timeHoursAgo').replaceAll('{n}', '${diff.inHours}');
  if (diff.inDays < 7) return loc.tr('timeDaysAgo').replaceAll('{n}', '${diff.inDays}');
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

/// The agency overview: every number and every feed line comes from the agency's own records
/// (TAQ-143). Nothing is a placeholder; with no data the page shows zeros and a real empty state.
class OverviewView extends StatelessWidget {
  final PortfolioController controller;
  final ValueListenable<List<ManagedPropertyModel>>? properties;
  final void Function(int tab)? onNavigate;
  final VoidCallback? onAddProperty;
  final DateTime Function()? clock;

  const OverviewView({
    super.key,
    required this.controller,
    this.properties,
    this.onNavigate,
    this.onAddProperty,
    this.clock,
  });

  ValueListenable<List<ManagedPropertyModel>> get _properties => properties ?? PropertyLifecycleService().propertiesNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: CountryController.currentCountry,
        builder: (context, country, __) => ListenableBuilder(
          listenable: Listenable.merge([controller, _properties]),
          builder: (context, ___) => _body(context, country),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, String country) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final snapshot = controller.snapshot;
    final real = _properties.value.where((p) => !PropertyLifecycleService.isMockPropertyId(p.id)).toList();
    final now = (clock ?? DateTime.now)();
    final stats = PortfolioStats.compute(snapshot, real, countryCode: country, now: now);

    Widget content;
    if (snapshot.isLoading) {
      content = const Center(child: TashilLoadingIndicator());
    } else if (snapshot.load == PortfolioLoad.error) {
      content = TashilEmptyState(
        icon: Icons.cloud_off_outlined,
        title: loc.tr('ovLoadFailedTitle'),
        message: loc.tr('ovLoadFailedMessage'),
        primaryActionLabel: loc.tr('ovRetry'),
        primaryActionIcon: Icons.refresh_rounded,
        onPrimaryAction: controller.start,
      );
    } else if (snapshot.load == PortfolioLoad.noAgency) {
      content = TashilEmptyState(
        icon: Icons.business_outlined,
        title: loc.tr('ovNoAgencyTitle'),
        message: loc.tr('ovNoAgencyMessage'),
      );
    } else {
      content = _loaded(context, loc, colorScheme, stats, now);
    }

    return Scaffold(backgroundColor: Colors.transparent, body: content);
  }

  Widget _loaded(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, PortfolioStats stats, DateTime now) {
    final lang = LocaleController.languageCode;
    String money(double v) => CurrencyFormatter.formatPriceWithCurrency(amount: v, currencyCode: stats.currencyCode, langCode: lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1100;
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
        final padding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);

        final collection = stats.collectionPercent;
        final occupancy = stats.occupancyPercent;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, loc, colorScheme, isMobile),
              SizedBox(height: isMobile ? 20 : 28),
              GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isMobile ? 2.4 : (isTablet ? 2.0 : 1.6),
                children: [
                  _KpiCard(
                    title: loc.tr('ovCollectedThisMonth'),
                    value: money(stats.collectedThisMonth),
                    badgeText: collection == null ? loc.tr('ovNoRentDue') : loc.tr('ovCollectedPercent').replaceAll('{n}', '$collection'),
                    badgeColor: colorScheme.tertiary,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => onNavigate?.call(AgencyTab.rentCollection),
                  ),
                  _KpiCard(
                    title: loc.tr('activeLeases'),
                    value: '${stats.activeLeases}',
                    badgeText: loc.tr('ovOffersPending').replaceAll('{n}', '${stats.pendingOffers}'),
                    badgeColor: colorScheme.secondary,
                    icon: Icons.assignment_outlined,
                    onTap: () => onNavigate?.call(AgencyTab.leases),
                  ),
                  _KpiCard(
                    title: loc.tr('totalProperties'),
                    value: '${stats.properties}',
                    badgeText: occupancy == null ? loc.tr('ovNoUnits') : loc.tr('ovOccupiedPercent').replaceAll('{n}', '$occupancy'),
                    badgeColor: colorScheme.primary,
                    icon: Icons.apartment_outlined,
                    onTap: () => onNavigate?.call(AgencyTab.properties),
                  ),
                  _KpiCard(
                    title: loc.tr('pendingMaintenance'),
                    value: '${stats.openMaintenance}',
                    badgeText: stats.escalatedMaintenance == 0
                        ? loc.tr('ovNoneUrgent')
                        : loc.tr('ovUrgentCount').replaceAll('{n}', '${stats.escalatedMaintenance}'),
                    badgeColor: colorScheme.error,
                    icon: Icons.handyman_outlined,
                    onTap: () => onNavigate?.call(AgencyTab.maintenance),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 28 : 36),
              _buildRecentActivities(context, loc, colorScheme, isMobile, stats, now),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc, ColorScheme colorScheme, bool isMobile) {
    final titleStyle = (isMobile ? Theme.of(context).textTheme.headlineSmall : Theme.of(context).textTheme.headlineMedium)
        ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary);
    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.tr('dashboardOverview'), style: titleStyle),
        const SizedBox(height: 4),
        Text(
          loc.tr('dashboardSubtitle'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
    final add = TashilButton.filled(
      label: loc.tr('addNewProperty'),
      icon: Icons.add,
      height: 48,
      onPressed: onAddProperty,
    );
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titles, const SizedBox(height: 12), add],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Expanded(child: titles), add],
    );
  }

  Widget _buildRecentActivities(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
    PortfolioStats stats,
    DateTime now,
  ) {
    final theme = Theme.of(context);
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
              Expanded(
                child: Text(
                  loc.tr('recentActivities'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ),
              if (stats.activity.isNotEmpty)
                TashilButton.text(
                  label: loc.tr('viewAll'),
                  height: 48,
                  onPressed: () => onNavigate?.call(AgencyTab.requests),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const TashilDivider.fullWidth(),
          const SizedBox(height: 8),
          if (stats.activity.isEmpty)
            TashilEmptyState(
              icon: Icons.history_rounded,
              title: loc.tr('ovNoActivityTitle'),
              message: loc.tr('ovNoActivityMessage'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.activity.length,
              separatorBuilder: (context, index) => const TashilDivider.inset(startIndent: 56),
              itemBuilder: (context, index) {
                final event = stats.activity[index];
                var title = loc.tr(event.titleKey);
                event.params.forEach((k, v) => title = title.replaceAll('{$k}', v));
                final color = event.kind == ActivityKind.maintenance ? colorScheme.error : colorScheme.primary;
                return Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    minVerticalPadding: 8,
                    contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 4, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(activityIcon(event.kind), color: color, size: 20),
                    ),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        relativeTimeLabel(loc, event.time, now),
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
                    onTap: () => onNavigate?.call(event.targetTab),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
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
                    decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: badgeColor, size: 20),
                  ),
                  Flexible(
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(start: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600),
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
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
