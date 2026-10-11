import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_fab.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';

class TenantSupportView extends StatelessWidget {
  const TenantSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final lang = LocaleController.languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: TashilFloatingActionButton(
        icon: Icons.add,
        tooltip: loc.tr('maintenanceTickets'),
        onPressed: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('maintenanceTickets'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildTicketCard(
                    context,
                    title: AiTranslationService.getLocalizedText({
                      'ar': 'صيانة وتغيير فلتر التكييف المركزي',
                      'en': 'Central AC Duct & Filter Maintenance',
                      'hi': 'केंद्रीय एसी डक्ट और फिल्टर रखरखाव',
                    }, lang),
                    description: AiTranslationService.getLocalizedText({
                      'ar': 'التكييف في غرفة المعيشة لا يبرد بالشكل المطلوب ويصدر هواء دافئاً',
                      'en': 'Living room air conditioner is blowing warm air and needs refrigerant refill.',
                      'hi': 'लिविंग रूम का एसी गर्म हवा फेंक रहा है और इसे जांच की आवश्यकता है।',
                    }, lang),
                    status: loc.tr('statusPending'),
                    date: '2026-10-25',
                    isResolved: false,
                  ),
                  const SizedBox(height: 12),
                  _buildTicketCard(
                    context,
                    title: AiTranslationService.getLocalizedText({
                      'ar': 'إصلاح تسريب مياه بحمام الضيوف',
                      'en': 'Guest Bathroom Plumbing Leak Repair',
                      'hi': 'अतिथि बाथरूम प्लंबिंग रिसाव मरम्मत',
                    }, lang),
                    description: AiTranslationService.getLocalizedText({
                      'ar': 'تم إصلاح الصمام الرئيسي واستبدال الوصلات المرنة بنجاح',
                      'en': 'Main pressure valve repaired and flexible hoses successfully replaced.',
                      'hi': 'मुख्य दबाव वाल्व की मरम्मत की गई और लचीले पाइप सफलतापूर्वक बदले गए।',
                    }, lang),
                    status: loc.tr('statusResolved'),
                    date: '2026-10-18',
                    isResolved: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context, {
    required String title,
    required String description,
    required String status,
    required String date,
    bool isResolved = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TashilCard.outlined(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isResolved ? colorScheme.primary : colorScheme.secondary,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isResolved ? colorScheme.primary : colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(date, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
