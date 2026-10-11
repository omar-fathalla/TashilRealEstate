import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/features/vision_maintenance/widgets/ai_vision_maintenance_dialog.dart';
import '../services/property_lifecycle_service.dart';

class OwnerMaintenanceView extends StatelessWidget {
  const OwnerMaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = CountryController.isUAE;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    final targetCountry = isUAE ? 'AE' : 'EG';
    final userProps = PropertyLifecycleService().propertiesNotifier.value
        .where((p) => p.countryCode == targetCountry)
        .toList();
    final hasRealProps = userProps.any((p) => !PropertyLifecycleService.isMockPropertyId(p.id));

    // When the owner has real properties or is authenticated, purge demo mock tickets
    final List<Map<String, dynamic>> tickets = hasRealProps ? [] : (isUAE ? _ticketsUAE : _ticketsEG);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.tr('maintenanceTickets'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TashilButton(
                onPressed: () => AiVisionMaintenanceDialog.show(context),
                icon: Icons.troubleshoot_rounded,
                label: loc.tr('visionMaintenanceTitle'),
                variant: TashilButtonVariant.filled,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (tickets.isEmpty)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: TashilCard.outlined(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.tr('noMaintenanceTickets'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.tr('noMaintenanceTicketsDesc'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TashilButton(
                        onPressed: () => AiVisionMaintenanceDialog.show(context),
                        icon: Icons.add_circle_outline_rounded,
                        label: loc.tr('visionMaintenanceTitle'),
                        variant: TashilButtonVariant.tonal,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...tickets.map((t) {
              final isResolved = t['status'] == 'resolved';
              final cost = (t['cost'] as num).toDouble();
              final title = AiTranslationService.getLocalizedText(t['titles'], lang);
              final unit = AiTranslationService.getLocalizedText(t['units'], lang);

              return TashilCard.outlined(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
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
                              color: isResolved
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isResolved ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                              color: isResolved
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onTertiaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t['id'].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isResolved
                              ? colorScheme.secondaryContainer
                              : colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isResolved ? loc.tr('statusResolved') : loc.tr('statusPending'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isResolved
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.tr('maintenanceForUnit')}: $unit',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  Divider(height: 24, color: colorScheme.outlineVariant),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loc.tr('maintenanceCost')}: ${CurrencyFormatter.formatAmount(cost, langCode: lang)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (!isResolved)
                        TashilButton(
                          onPressed: () {},
                          label: loc.tr('approveMaintenance'),
                          variant: TashilButtonVariant.tonal,
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static const List<Map<String, dynamic>> _ticketsEG = [
    {
      'id': 'MNT-1021',
      'titles': {
        'ar': 'صيانة وتغيير فلتر التكييف المركزي',
        'en': 'Central AC Duct & Filter Maintenance',
        'hi': 'केंद्रीय एसी डक्ट और फिल्टर रखरखाव',
      },
      'units': {
        'ar': 'فيلا بيفرلي هيلز - الشيخ زايد',
        'en': 'Beverly Hills Villa - Sheikh Zayed',
        'hi': 'बेवर्ली हिल्स विला - शेख जायद',
      },
      'cost': 1200,
      'status': 'pending',
    },
    {
      'id': 'MNT-1018',
      'titles': {
        'ar': 'إصلاح تسريب مياه بحمام الضيوف',
        'en': 'Guest Bathroom Plumbing Leak Repair',
        'hi': 'अतिथि बाथरूम प्लंबिंग रिसाव मरम्मत',
      },
      'units': {
        'ar': 'شقة التجمع الخامس - النرجس',
        'en': '5th Settlement Apartment - El Narges',
        'hi': '5वां सेटलमेंट अपार्टमेंट - अल नरगिस',
      },
      'cost': 850,
      'status': 'resolved',
    },
  ];

  static const List<Map<String, dynamic>> _ticketsUAE = [
    {
      'id': 'MNT-AE-401',
      'titles': {
        'ar': 'صيانة دورية للمكيف المركزي وتنظيف الفلاتر',
        'en': 'HVAC Duct Cleaning & AC Filter Service',
        'hi': 'एचवीएसी डक्ट सफाई और एसी फिल्टर सेवा',
      },
      'units': {
        'ar': 'شقة مارينا كراون - دبي مارينا',
        'en': 'Marina Crown Apartment - Dubai Marina',
        'hi': 'मरीना क्राउन अपार्टमेंट - दुबई मरीना',
      },
      'cost': 450,
      'status': 'pending',
    },
  ];
}
