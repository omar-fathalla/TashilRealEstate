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
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';
import 'views/tenant_home_view.dart';
import 'views/tenant_payments_view.dart';
import 'views/tenant_support_view.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const TenantHomeView(),
    const TenantPaymentsView(),
    const TenantSupportView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, country, _) {
            final loc = AppLocalizations.of(context);
            final colorScheme = Theme.of(context).colorScheme;

            Widget body = _views[_selectedIndex];

            // Constrain width on desktop
            if (!ResponsiveLayout.isMobile(context)) {
              body = Center(
                child: Container(
                  width: 860,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: body,
                ),
              );
            }

            return Scaffold(
              backgroundColor: ResponsiveLayout.isMobile(context)
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              appBar: AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person_pin_rounded, color: colorScheme.onPrimary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.tr('tenant'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                    ),
                  ],
                ),
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.travel_explore),
                  tooltip: loc.tr('browseAsVisitor'),
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  const ThemePaletteSwitcher(isCompact: true),
                  const SizedBox(width: 4),
                  const CountrySwitcher(isCompact: true, showLabel: false),
                  const SizedBox(width: 4),
                  const LanguageSwitcher(isCompact: true, showLabel: false),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: loc.tr('settings'),
                    onPressed: () => AppSettingsDialog.show(context),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.logout, color: colorScheme.error),
                    tooltip: loc.tr('logout'),
                    onPressed: () async {
                      await FirebaseAuthService().signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: body,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: loc.tr('navOverview'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.payment_outlined),
                    selectedIcon: const Icon(Icons.payment),
                    label: loc.tr('navFinancials'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.handyman_outlined),
                    selectedIcon: const Icon(Icons.handyman),
                    label: loc.tr('navMaintenance'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
