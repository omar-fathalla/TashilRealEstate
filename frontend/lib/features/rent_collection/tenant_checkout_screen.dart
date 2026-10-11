import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/country_switcher.dart';
import 'package:tashil_real_estate/core/localization/language_switcher.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/core/widgets/theme_palette_switcher.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';

class TenantCheckoutScreen extends StatelessWidget {
  const TenantCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, countryCode, _) {
            final loc = AppLocalizations.of(context);
            final invoices = RentCollectionService().invoicesNotifier.value;
            final invoice = invoices.firstWhere(
              (inv) => inv.countryCode == countryCode,
              orElse: () => invoices.first,
            );

            return Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: AppBar(
                backgroundColor: colorScheme.surfaceContainerLowest,
                foregroundColor: colorScheme.onSurface,
                titleSpacing: isMobile ? 10 : 16,
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.flash_on_rounded, color: colorScheme.onPrimary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        loc.tr('instantCheckoutDemoBtn'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 16, color: colorScheme.onSurface),
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
                    icon: Icon(Icons.home_outlined, color: colorScheme.onSurface),
                    tooltip: loc.tr('exploreUnits'),
                    onPressed: () => context.go('/'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  child: TenantCheckoutDialog(invoice: invoice),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
