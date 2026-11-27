import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/features/agency_mandates/widgets/mandate_panels.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/empty_state/tashil_empty_state.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/image_utils.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/fast_onboarding/widgets/fast_property_onboarding_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/agency_workspace/agency_staff_scope.dart';

/// The agency's properties (TAQ-143): the units the signed-in agency admin registered, with their
/// real rented or vacant status. Starter samples are never shown, and a card opens the unit for editing.
/// For an AgencyAgent the dashboard passes the agency's listings instead, read-only (TAQ-194).
class PropertiesView extends StatelessWidget {
  final ValueListenable<List<ManagedPropertyModel>>? properties;
  final ValueListenable<bool>? hydrating;
  final VoidCallback? onAdd;
  final void Function(ManagedPropertyModel property)? onOpen;

  const PropertiesView({super.key, this.properties, this.hydrating, this.onAdd, this.onOpen});

  void _add(BuildContext context) => onAdd != null ? onAdd!() : FastPropertyOnboardingDialog.show(context);

  void _open(BuildContext context, ManagedPropertyModel p) {
    // TAQ-169: an agent cannot edit listings.
    if (AgencyStaffScope.isAgentOf(context)) return;
    if (onOpen != null) {
      onOpen!(p);
      return;
    }
    FastPropertyOnboardingDialog.show(context, initialDraft: p.toDraft(), existingPropertyId: p.id);
  }

  @override
  Widget build(BuildContext context) {
    final service = PropertyLifecycleService();
    final source = properties ?? service.propertiesNotifier;
    final busy = hydrating ?? service.isHydratingNotifier;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: CountryController.currentCountry,
        builder: (context, country, __) => ListenableBuilder(
          listenable: Listenable.merge([source, busy]),
          builder: (context, ___) {
            final units = source.value.where((p) => !PropertyLifecycleService.isMockPropertyId(p.id) && p.countryCode == country).toList();
            return _scaffold(context, units, busy.value);
          },
        ),
      ),
    );
  }

  Widget _scaffold(BuildContext context, List<ManagedPropertyModel> units, bool loading) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAgent = AgencyStaffScope.isAgentOf(context);
    Widget body;
    if (loading && units.isEmpty) {
      body = const Center(child: TashilLoadingIndicator());
    } else if (units.isEmpty) {
      body = TashilEmptyState(
        icon: Icons.apartment_rounded,
        title: loc.tr('agPropsEmptyTitle'),
        message: loc.tr('agPropsEmptyMessage'),
        primaryActionLabel: isAgent ? null : loc.tr('addProperty'),
        primaryActionIcon: isAgent ? null : Icons.add,
        onPrimaryAction: isAgent ? null : () => _add(context),
      );
    } else {
      body = GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isMobile ? 400 : 340,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: isMobile ? 1.0 : 0.88,
        ),
        itemCount: units.length,
        itemBuilder: (context, index) => _PropertyTile(property: units[index], onTap: () => _open(context, units[index])),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: units.isEmpty || isAgent
          ? null
          : TashilExtendedFloatingActionButton(
              onPressed: () => _add(context),
              icon: Icons.add,
              label: loc.tr('addProperty'),
            ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('navProperties'),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            // Other owners' properties this agency is invited to or manages (TAQ-149).
            // Mandates are the AgencyAdmin's decisions (TAQ-169).
            if (!isAgent)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: const SingleChildScrollView(child: AgencyMandatesPanel()),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _PropertyTile extends StatelessWidget {
  final ManagedPropertyModel property;
  final VoidCallback onTap;

  const _PropertyTile({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final lang = LocaleController.languageCode;
    final rented = property.isOccupied;
    final price = CurrencyFormatter.formatPriceWithCurrency(
      amount: property.pricePerMonth,
      currencyCode: property.currencyCode,
      langCode: lang,
    );
    final title = property.getTitle(lang);
    final location = property.getLocation(lang);
    final image = property.imageUrls.isNotEmpty ? property.imageUrls.first : property.image;

    return TashilCard.outlined(
      color: colorScheme.surfaceContainerLowest,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: image.isEmpty
                  ? Icon(Icons.apartment_rounded, size: 40, color: colorScheme.onSurfaceVariant)
                  : ImageUtils.cachedImage(imageUrl: image, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rented ? colorScheme.secondaryContainer : colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rented ? loc.tr('statusRented') : loc.tr('statusVacant'),
                          style: TextStyle(
                            color: rented ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: Text(
                            price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
