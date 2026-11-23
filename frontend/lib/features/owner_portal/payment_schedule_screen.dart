import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/empty_state/tashil_empty_state.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/country_switcher.dart';
import 'package:tashil_real_estate/core/localization/language_switcher.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_switcher.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/monthly_payment_schedule_dialog.dart';

class PaymentScheduleScreen extends StatelessWidget {
  const PaymentScheduleScreen({super.key, this.propertyId});

  /// Property to show, from the `property` query parameter. When it is null an occupied
  /// property of the selected country is used; when it names no known property an empty
  /// state is shown.
  final String? propertyId;

  /// The property to show, or null when the list is empty or [propertyId] matches nothing.
  static ManagedPropertyModel? resolveProperty(
    List<ManagedPropertyModel> properties,
    String countryCode, {
    String? propertyId,
  }) {
    if (properties.isEmpty) return null;
    if (propertyId != null && propertyId.isNotEmpty) {
      for (final p in properties) {
        if (p.id == propertyId) return p;
      }
      return null;
    }
    for (final p in properties) {
      if (p.countryCode == countryCode && p.isOccupied) return p;
    }
    return properties.first;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, currentCountry, _) {
            return ValueListenableBuilder<List<ManagedPropertyModel>>(
              valueListenable: PropertyLifecycleService().propertiesNotifier,
              builder: (context, properties, _) {
                final targetCountry = currentCountry == 'AE' ? 'AE' : 'EG';
                final property = resolveProperty(properties, targetCountry, propertyId: propertyId);
                final isMissingId = propertyId != null && propertyId!.isNotEmpty;

                return Scaffold(
                  backgroundColor: theme.colorScheme.surface,
                  appBar: AppBar(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    titleSpacing: isMobile ? 10 : 16,
                    automaticallyImplyLeading: false,
                    centerTitle: false,
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            loc.tr('monthlyPaymentLedgerTitle'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 16, color: theme.colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      const ThemePaletteSwitcher(isCompact: true),
                      const SizedBox(width: 4),
                      CountrySwitcher(isCompact: true, showLabel: !isMobile),
                      const SizedBox(width: 4),
                      LanguageSwitcher(isCompact: true, showLabel: !isMobile),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurface),
                        tooltip: loc.tr('exploreUnits'),
                        onPressed: () => context.go('/owner'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: property == null
                      ? TashilEmptyState(
                          icon: isMissingId ? Icons.search_off_rounded : Icons.apartment_rounded,
                          title: loc.tr(isMissingId ? 'schedulePropertyNotFoundTitle' : 'scheduleEmptyTitle'),
                          message: loc.tr(isMissingId ? 'schedulePropertyNotFoundMessage' : 'scheduleEmptyMessage'),
                          primaryActionLabel: loc.tr(isMissingId ? 'backToDashboard' : 'addProperty'),
                          primaryActionIcon: isMissingId ? Icons.dashboard_outlined : Icons.add_home_work_outlined,
                          onPrimaryAction: () => context.go(isMissingId ? '/owner' : '/fast-onboarding'),
                          secondaryActionLabel: isMissingId ? null : loc.tr('backToDashboard'),
                          onSecondaryAction: isMissingId ? null : () => context.go('/owner'),
                        )
                      : Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 12 : 24),
                            child: MonthlyPaymentScheduleDialog(property: property),
                          ),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }
}
