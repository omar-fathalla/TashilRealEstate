import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/utils/image_utils.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';
import 'package:tashil_real_estate/features/investor_dashboard/widgets/investment_simulator_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/services/property_lifecycle_service.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/monthly_payment_schedule_dialog.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';

class OwnerOverviewView extends StatefulWidget {
  const OwnerOverviewView({super.key});

  @override
  State<OwnerOverviewView> createState() => _OwnerOverviewViewState();
}

class _OwnerOverviewViewState extends State<OwnerOverviewView> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = CountryController.isUAE;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    return ValueListenableBuilder<List<ManagedPropertyModel>>(
      valueListenable: PropertyLifecycleService().propertiesNotifier,
      builder: (context, allManagedProps, _) {
        final targetCountry = isUAE ? 'AE' : 'EG';
        final properties = allManagedProps
            .where((p) => p.countryCode == targetCountry)
            .toList();

        final int totalUnits = properties.isNotEmpty ? properties.length : (isUAE ? 3 : 4);
        final int occupiedUnits = properties.isNotEmpty
            ? properties.where((p) => p.isOccupied).length
            : (isUAE ? 2 : 3);
        final int vacantUnits = properties.isNotEmpty
            ? properties.where((p) => !p.isOccupied).length
            : 1;
        final double totalRevenue = properties.isNotEmpty
            ? properties.where((p) => p.isOccupied).fold<double>(0.0, (sum, p) => sum + p.pricePerMonth)
            : (isUAE ? 38500.0 : 78000.0);
        final int occupancyRate = totalUnits > 0
            ? ((occupiedUnits / totalUnits) * 100).toInt()
            : 80;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Welcome & Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('portfolioOverview'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.tr('ownerSubtitle'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            loc.tr('ownerRoleTitle'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TashilButton.tonal(
                      icon: Icons.file_download_outlined,
                      label: loc.tr('exportStatement'),
                      height: 38,
                      onPressed: () {
                        TashilSnackBar.showSuccess(
                          context: context,
                          message: loc.tr('statementExportedNotice'),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // AI Smart Valuation Hero Banner
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      Color.lerp(colorScheme.primary, Colors.black, 0.22) ?? colorScheme.primary,
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header: Icon + Title + Gemini Flash Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          loc.tr('aiValuationBannerTitle'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Gemini Flash',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action Buttons (Responsive: Vertical column on mobile, horizontal on desktop)
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TashilButton.elevated(
                            onPressed: () => SmartValuationDialog.show(context),
                            icon: Icons.auto_awesome_rounded,
                            label: loc.tr('calculateFairRent'),
                            height: 40,
                          ),
                          const SizedBox(height: 10),
                          TashilButton.tonal(
                            onPressed: () => InvestmentSimulatorDialog.show(context),
                            icon: Icons.calculate_rounded,
                            label: loc.tr('investmentSimulatorTitle'),
                            height: 40,
                          ),
                          const SizedBox(height: 10),
                          TashilButton.outlined(
                            onPressed: () => context.go('/market-index'),
                            icon: Icons.analytics_rounded,
                            label: CountryController.isUAE ? loc.tr('dxbMarketIndexTitle') : loc.tr('aqarmapIndexTitle'),
                            customColor: Colors.white,
                            height: 40,
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TashilButton.elevated(
                            onPressed: () => SmartValuationDialog.show(context),
                            icon: Icons.auto_awesome_rounded,
                            label: loc.tr('calculateFairRent'),
                            height: 38,
                          ),
                          TashilButton.tonal(
                            onPressed: () => InvestmentSimulatorDialog.show(context),
                            icon: Icons.calculate_rounded,
                            label: loc.tr('investmentSimulatorTitle'),
                            height: 38,
                          ),
                          TashilButton.outlined(
                            onPressed: () => context.go('/market-index'),
                            icon: Icons.analytics_rounded,
                            label: CountryController.isUAE ? loc.tr('dxbMarketIndexTitle') : loc.tr('aqarmapIndexTitle'),
                            customColor: Colors.white,
                            height: 38,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Explanatory Text under the buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.tr('aiValuationBannerDesc'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.90),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4 KPI Metric Cards (Adaptive for Mobile 1, Tablet 2, Desktop 4)
              Builder(
                builder: (context) {
                  final locations = properties.map((p) => p.getLocation(lang)).where((l) => l.isNotEmpty).toSet().toList();
                  final String totalUnitsSubtitle = locations.isNotEmpty
                      ? locations.take(2).join('، ')
                      : (isUAE ? loc.tr('ownerLoc_dubai_abudhabi') : loc.tr('ownerLoc_cairo_zayed'));

                  final vacantLocations = properties.where((p) => !p.isOccupied).map((p) => p.getLocation(lang)).where((l) => l.isNotEmpty).toSet().toList();
                  final String vacantSubtitle = properties.isNotEmpty
                      ? (vacantUnits == 0
                          ? loc.tr('allUnitsOccupied')
                          : (vacantLocations.isNotEmpty
                              ? vacantLocations.take(2).join('، ')
                              : (isUAE ? loc.tr('ownerLoc_dubai_marina') : loc.tr('ownerLoc_north_coast'))))
                      : (isUAE ? loc.tr('ownerLoc_dubai_marina') : loc.tr('ownerLoc_north_coast'));

                  final String revenueSubtitle = occupiedUnits > 0
                      ? loc.tr('payoutCompleted')
                      : loc.tr('noCollectedRevenue');

                  return TashilKpiGrid(
                    cards: [
                      TashilKpiCard(
                        title: loc.tr('totalUnits'),
                        value: '$totalUnits',
                        subtitle: totalUnitsSubtitle,
                        icon: Icons.apartment_rounded,
                        subtitleIcon: Icons.location_on_outlined,
                        iconColor: colorScheme.primary,
                        iconBgColor: colorScheme.surfaceContainerHigh,
                      ),
                      TashilKpiCard(
                        title: loc.tr('occupiedUnits'),
                        value: '$occupiedUnits',
                        subtitle: '$occupancyRate% ${loc.tr('occupancyRateSubtitle')}',
                        icon: Icons.check_circle_outline_rounded,
                        subtitleIcon: Icons.trending_up_rounded,
                        iconColor: colorScheme.primary,
                        iconBgColor: colorScheme.surfaceContainerHigh,
                      ),
                      TashilKpiCard(
                        title: loc.tr('vacantUnits'),
                        value: '$vacantUnits',
                        subtitle: vacantSubtitle,
                        icon: Icons.door_front_door_outlined,
                        subtitleIcon: Icons.location_on_outlined,
                        iconColor: colorScheme.primary,
                        iconBgColor: colorScheme.surfaceContainerHigh,
                      ),
                      TashilKpiCard(
                        title: loc.tr('monthlyRevenue'),
                        value: '${CurrencyFormatter.formatAmount(totalRevenue, langCode: lang)} $currency',
                        subtitle: revenueSubtitle,
                        icon: Icons.payments_outlined,
                        subtitleIcon: Icons.verified_rounded,
                        iconColor: colorScheme.primary,
                        iconBgColor: colorScheme.surfaceContainerHigh,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Properties Performance Section
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Text(
                          loc.tr('myProperties'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TashilConnectedButtonGroup<String>(
                          selectedValue: _selectedStatus,
                          onSelectionChanged: (val) {
                            setState(() => _selectedStatus = val);
                          },
                          segments: [
                            TashilConnectedButtonSegment(
                              value: 'all',
                              label: loc.tr('filterAllUnits'),
                              icon: Icons.grid_view_rounded,
                            ),
                            TashilConnectedButtonSegment(
                              value: 'occupied',
                              label: loc.tr('statusOccupied'),
                              icon: Icons.check_circle_rounded,
                            ),
                            TashilConnectedButtonSegment(
                              value: 'vacant',
                              label: loc.tr('statusVacant'),
                              icon: Icons.door_front_door_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TashilDivider.fullWidth(),
                    const SizedBox(height: 16),

                    // Units List with animated transition
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Column(
                        key: ValueKey<String>(_selectedStatus),
                        children: _buildOwnerUnitsList(context, loc, properties, isUAE, lang, currency, colorScheme),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Recent Payouts Table
              _buildRecentPayoutsCard(context, loc, isUAE, lang, currency, colorScheme, properties),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOwnerUnitsList(
    BuildContext context,
    AppLocalizations loc,
    List<ManagedPropertyModel> properties,
    bool isUAE,
    String lang,
    String currency,
    ColorScheme colorScheme,
  ) {
    if (properties.isNotEmpty) {
      final filtered = _selectedStatus == 'all'
          ? properties
          : properties.where((p) => _selectedStatus == 'occupied' ? p.isOccupied : !p.isOccupied).toList();

      return filtered.map((p) {
        final isOccupied = p.isOccupied;
        final price = p.pricePerMonth;
        final title = p.getTitle(lang);
        final location = p.getLocation(lang);
        final tenant = p.tenantName ?? (isOccupied ? loc.tr('potentialTenant') : '-');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 74,
                  height: 58,
                  child: ImageUtils.cachedImage(
                    imageUrl: p.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          location,
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                        if (isOccupied && tenant.isNotEmpty && tenant != '-') ...[
                          Text(' • ', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          Icon(Icons.person_outline_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              tenant,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${CurrencyFormatter.formatAmount(price, langCode: lang)} $currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOccupied ? colorScheme.secondaryContainer : colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOccupied ? Icons.check_rounded : Icons.door_front_door_rounded,
                              size: 12,
                              color: isOccupied ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOccupied ? loc.tr('statusOccupied') : loc.tr('statusVacant'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOccupied ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TashilIconButton.tonal(
                        tooltip: loc.tr('monthlyInstallmentLedgerBtn'),
                        icon: Icons.calendar_month_rounded,
                        size: 34,
                        iconSize: 16,
                        onPressed: () {
                          MonthlyPaymentScheduleDialog.show(context, p);
                          TashilSnackBar.showInfo(
                            context: context,
                            message: '${loc.tr('monthlyInstallmentLedgerBtn')} - $title',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList();
    }
    final units = isUAE ? _sampleUAEUnits : _sampleEGUnits;
    final filtered = _selectedStatus == 'all'
        ? units
        : units.where((u) => u['status'] == _selectedStatus).toList();

    return filtered.map((u) {
      final isOccupied = u['status'] == 'occupied';
      final price = (u['price'] as num).toDouble();
      final title = AiTranslationService.getLocalizedText(u['titles'], lang);
      final location = AiTranslationService.getLocalizedText(u['locations'], lang);
      final tenant = AiTranslationService.getLocalizedText(u['tenants'], lang);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 74,
                height: 58,
                child: ImageUtils.cachedImage(
                  imageUrl: u['image'].toString(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        location,
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      if (isOccupied && tenant.isNotEmpty && tenant != '-') ...[
                        Text(' • ', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        Icon(Icons.person_outline_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            tenant,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${CurrencyFormatter.formatAmount(price, langCode: lang)} $currency',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOccupied ? colorScheme.secondaryContainer : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOccupied ? Icons.check_rounded : Icons.door_front_door_rounded,
                            size: 12,
                            color: isOccupied ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOccupied ? loc.tr('statusOccupied') : loc.tr('statusVacant'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOccupied ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TashilIconButton.tonal(
                      tooltip: loc.tr('monthlyInstallmentLedgerBtn'),
                      icon: Icons.calendar_month_rounded,
                      size: 34,
                      iconSize: 16,
                      onPressed: () {
                        final properties = PropertyLifecycleService().propertiesNotifier.value;
                        final prop = properties.firstWhere(
                          (p) => p.countryCode == (isUAE ? 'AE' : 'EG') && (isOccupied ? p.isOccupied : true),
                          orElse: () => properties.first,
                        );
                        MonthlyPaymentScheduleDialog.show(context, prop);
                        TashilSnackBar.showInfo(
                          context: context,
                          message: '${loc.tr('monthlyInstallmentLedgerBtn')} - $title',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRecentPayoutsCard(
    BuildContext context,
    AppLocalizations loc,
    bool isUAE,
    String lang,
    String currency,
    ColorScheme colorScheme,
    List<ManagedPropertyModel> properties,
  ) {
    final realPayouts = PropertyLifecycleService().getRealPayouts(countryCode: isUAE ? 'AE' : 'EG');
    final payouts = realPayouts.isNotEmpty
        ? realPayouts
        : (properties.isEmpty ? (isUAE ? _sampleUAEPayouts : _sampleEGPayouts) : <Map<String, dynamic>>[]);

    final shouldShowEmptyState = payouts.isEmpty;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.account_balance_rounded, color: colorScheme.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.tr('recentPayouts'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              TashilButton.tonal(
                height: 36,
                icon: Icons.receipt_long_rounded,
                label: loc.tr('exportStatement'),
                onPressed: () {
                  if (shouldShowEmptyState) {
                    TashilSnackBar.showInfo(
                      context: context,
                      message: loc.tr('noRecentPayoutsTitle'),
                    );
                  } else {
                    TashilSnackBar.showSuccess(
                      context: context,
                      message: loc.tr('statementExportedNotice'),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TashilDivider.fullWidth(),
          const SizedBox(height: 8),
          if (shouldShowEmptyState)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 26,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      loc.tr('noRecentPayoutsTitle'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Text(
                        loc.tr('noRecentPayoutsDesc'),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...payouts.map((p) {
            final amount = (p['amount'] as num).toDouble();
            final title = AiTranslationService.getLocalizedText(p['titles'], lang);
            final date = AiTranslationService.getLocalizedText(p['dates'], lang);

            return InkWell(
              onTap: () {
                TashilSnackBar.showSuccess(
                  context: context,
                  message: '${loc.tr('transferReceiptNotice')} (${p['ref']})',
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_downward_rounded, color: colorScheme.onSecondaryContainer, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$date • Ref: ${p['ref']}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+ ${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _sampleEGUnits = [
    {
      'titles': {
        'ar': 'شقة فاخرة بالتجمع الخامس - النرجس',
        'en': 'Luxury Apartment in 5th Settlement - El Narges',
        'hi': '5वें सेटलमेंट में लक्जरी अपार्टमेंट - अल नरगिस',
      },
      'locations': {
        'ar': 'القاهرة الجديدة',
        'en': 'New Cairo',
        'hi': 'न्यू काहिरा',
      },
      'tenants': {
        'ar': 'م. كريم سامي',
        'en': 'Eng. Karim Samy',
        'hi': 'इंजीनियर करीम सामी',
      },
      'price': 22000,
      'status': 'occupied',
      'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600&auto=format&fit=crop&q=80',
    },
    {
      'titles': {
        'ar': 'فيلا مستقلة - بيفرلي هيلز',
        'en': 'Private Villa - Beverly Hills',
        'hi': 'निजी विला - बेवर्ली हिल्स',
      },
      'locations': {
        'ar': 'الشيخ زايد',
        'en': 'Sheikh Zayed',
        'hi': 'शेख जायद',
      },
      'tenants': {
        'ar': 'د. حسام عادل',
        'en': 'Dr. Hossam Adel',
        'hi': 'डॉ. होसम एडेल',
      },
      'price': 35000,
      'status': 'occupied',
      'image': 'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=600&auto=format&fit=crop&q=80',
    },
    {
      'titles': {
        'ar': 'شقة مطلة على النيل - جاردن سيتي',
        'en': 'Nile View Apartment - Garden City',
        'hi': 'नाइल व्यू अपार्टमेंट - गार्डन सिटी',
      },
      'locations': {
        'ar': 'القاهرة',
        'en': 'Cairo',
        'hi': 'काहिरा',
      },
      'tenants': {
        'ar': 'أ. سارة المنشاوي',
        'en': 'Ms. Sarah El Minshawi',
        'hi': 'सुश्री सारा एल मिनशावी',
      },
      'price': 21000,
      'status': 'occupied',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600&auto=format&fit=crop&q=80',
    },
    {
      'titles': {
        'ar': 'شاليه بحري صف أول - أمواج',
        'en': 'Seafront Chalet - Amwaj',
        'hi': 'समुद्र तट शैले - अमवाज',
      },
      'locations': {
        'ar': 'الساحل الشمالي',
        'en': 'North Coast',
        'hi': 'उत्तरी तट',
      },
      'tenants': {
        'ar': '-',
        'en': '-',
        'hi': '-',
      },
      'price': 25000,
      'status': 'vacant',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&auto=format&fit=crop&q=80',
    },
  ];

  static const List<Map<String, dynamic>> _sampleUAEUnits = [
    {
      'titles': {
        'ar': 'شقة بريميوم بإطلالة بحرية - برج مارينا كراون',
        'en': 'Premium Sea View Apartment - Marina Crown Tower',
        'hi': 'प्रीमियम सी व्यू अपार्टमेंट - मरीना क्राउन टॉवर',
      },
      'locations': {
        'ar': 'دبي مارينا',
        'en': 'Dubai Marina',
        'hi': 'दुबई मरीना',
      },
      'tenants': {
        'ar': 'جون ديفيس',
        'en': 'John Davis',
        'hi': 'जॉन डेविस',
      },
      'price': 14500,
      'status': 'occupied',
      'image': 'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?w=600&auto=format&fit=crop&q=80',
    },
    {
      'titles': {
        'ar': 'بنتهاوس فاخر - برج خليفة ديستريكت',
        'en': 'Luxury Penthouse - Burj Khalifa District',
        'hi': 'लक्जरी पेंटहाउस - बुर्ज खलीफा जिला',
      },
      'locations': {
        'ar': 'داون تاون دبي',
        'en': 'Downtown Dubai',
        'hi': 'डाउनटाउन दुबई',
      },
      'tenants': {
        'ar': 'راجيش شارما',
        'en': 'Rajesh Sharma',
        'hi': 'राजेश शर्मा',
      },
      'price': 24000,
      'status': 'occupied',
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&auto=format&fit=crop&q=80',
    },
    {
      'titles': {
        'ar': 'فيلا شاطئية - نخلة جميرا',
        'en': 'Beachfront Luxury Villa - Palm Jumeirah',
        'hi': 'समुद्र तट विला - पाम जुमेराह',
      },
      'locations': {
        'ar': 'نخلة جميرا',
        'en': 'Palm Jumeirah',
        'hi': 'पाम जुमेराह',
      },
      'tenants': {
        'ar': '-',
        'en': '-',
        'hi': '-',
      },
      'price': 35000,
      'status': 'vacant',
      'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&auto=format&fit=crop&q=80',
    },
  ];

  static const List<Map<String, dynamic>> _sampleEGPayouts = [
    {
      'titles': {
        'ar': 'تحويل إيجار شقة التجمع الخامس (نوفمبر 2026)',
        'en': 'Rent Payout - 5th Settlement Apartment (Nov 2026)',
        'hi': 'किराया भुगतान - 5वां सेटलमेंट अपार्टमेंट (नवंबर 2026)',
      },
      'dates': {
        'ar': '25 نوفمبر 2026',
        'en': 'Nov 25, 2026',
        'hi': '25 नवंबर 2026',
      },
      'ref': 'TXN-98402',
      'amount': 22000,
    },
    {
      'titles': {
        'ar': 'تحويل إيجار فيلا بيفرلي هيلز (نوفمبر 2026)',
        'en': 'Rent Payout - Beverly Hills Villa (Nov 2026)',
        'hi': 'किराया भुगतान - बेवर्ली हिल्स विला (नवंबर 2026)',
      },
      'dates': {
        'ar': '20 نوفمبر 2026',
        'en': 'Nov 20, 2026',
        'hi': '20 नवंबर 2026',
      },
      'ref': 'TXN-98319',
      'amount': 35000,
    },
    {
      'titles': {
        'ar': 'تحويل إيجار شقة جاردن سيتي (نوفمبر 2026)',
        'en': 'Rent Payout - Garden City Apartment (Nov 2026)',
        'hi': 'किराया भुगतान - गार्डन सिटी अपार्टमेंट (नवंबर 2026)',
      },
      'dates': {
        'ar': '15 نوفمبر 2026',
        'en': 'Nov 15, 2026',
        'hi': '15 नवंबर 2026',
      },
      'ref': 'TXN-98104',
      'amount': 21000,
    },
  ];

  static const List<Map<String, dynamic>> _sampleUAEPayouts = [
    {
      'titles': {
        'ar': 'إيداع بنكي - إيجار دبي مارينا (نوفمبر 2026)',
        'en': 'Bank Deposit - Dubai Marina Rent (Nov 2026)',
        'hi': 'बैंक जमा - दुबई मरीना किराया (नवंबर 2026)',
      },
      'dates': {
        'ar': '25 نوفمبر 2026',
        'en': 'Nov 25, 2026',
        'hi': '25 नवंबर 2026',
      },
      'ref': 'DXB-55102',
      'amount': 14500,
    },
    {
      'titles': {
        'ar': 'إيداع بنكي - إيجار داون تاون برج خليفة (نوفمبر 2026)',
        'en': 'Bank Deposit - Downtown Burj Khalifa Rent (Nov 2026)',
        'hi': 'बैंक जमा - डाउनटाउन बुर्ज खलीफा किराया (नवंबर 2026)',
      },
      'dates': {
        'ar': '20 نوفمبر 2026',
        'en': 'Nov 20, 2026',
        'hi': '20 नवंबर 2026',
      },
      'ref': 'DXB-54988',
      'amount': 24000,
    },
  ];
}
