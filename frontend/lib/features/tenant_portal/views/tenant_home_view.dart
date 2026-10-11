import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/rent_collection/services/rent_collection_service.dart';
import 'package:tashil_real_estate/features/rent_collection/widgets/tenant_checkout_dialog.dart';

class TenantHomeView extends StatelessWidget {
  const TenantHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = CountryController.isUAE;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final lang = LocaleController.languageCode;

    final rentAmount = isUAE ? 8500.0 : 18000.0;
    final propertyTitle = isUAE
        ? {
            'ar': 'شقة مارينا كراون - دبي مارينا',
            'en': 'Marina Crown Apartment - Dubai Marina',
            'hi': 'मरीना क्राउन अपार्टमेंट - दुबई मरीना',
          }
        : {
            'ar': 'فيلا بيفرلي هيلز - الشيخ زايد',
            'en': 'Beverly Hills Villa - Sheikh Zayed',
            'hi': 'बेवर्ली हिल्स विला - शेख जायद',
          };

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AiTranslationService.getLocalizedText({
                      'ar': 'مرحباً، كريم سامي',
                      'en': 'Welcome, Karim Sami',
                      'hi': 'स्वागत है, करीम सामी',
                    }, lang),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    loc.tr('tenant'),
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // Next Rent Due Hero Card
          TashilCard.filled(
            color: colorScheme.primaryContainer.withValues(alpha: 0.6),
            padding: EdgeInsets.all(isMobile ? 18.0 : 28.0),
            child: Column(
              children: [
                Icon(Icons.event_note_rounded, size: isMobile ? 36 : 44, color: colorScheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text(
                  loc.tr('monthlyRent'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${CurrencyFormatter.formatAmount(rentAmount, langCode: lang)} $currency',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2026-11-01',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 20),
                SizedBox(
                  width: double.infinity,
                  child: TashilButton(
                    onPressed: () {
                      final invoices = RentCollectionService().invoicesNotifier.value;
                      if (invoices.isNotEmpty) {
                        TenantCheckoutDialog.show(context, invoices.first);
                      }
                    },
                    icon: Icons.credit_card_rounded,
                    label: loc.tr('payNowOnline'),
                    height: 48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Lease Details
          Text(
            loc.tr('stepProperty'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          TashilCard.outlined(
            padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  loc.tr('unit'),
                  AiTranslationService.getLocalizedText(propertyTitle, lang),
                ),
                Divider(color: colorScheme.outlineVariant, height: 20),
                _buildDetailRow(
                  context,
                  loc.tr('leasePeriod'),
                  '2026-01-01 -> 2027-12-31',
                ),
                Divider(color: colorScheme.outlineVariant, height: 20),
                _buildDetailRow(
                  context,
                  loc.tr('statusActive'),
                  loc.tr('statusActive'),
                  valueColor: colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
