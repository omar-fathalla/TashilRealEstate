import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../document_ocr/widgets/ai_document_ocr_modal.dart';
import '../../legal_ai_advisor/widgets/ai_legal_clause_advisor_dialog.dart';
import '../../public_marketplace/models/property_item.dart';
import '../../semantic_search/widgets/visual_search_modal.dart';
import '../../virtual_staging/widgets/ai_virtual_staging_dialog.dart';
import '../../vision_maintenance/widgets/ai_vision_maintenance_dialog.dart';
import '../../voice_broker/widgets/gemini_voice_broker_dialog.dart';
import '../../ai_engine_hub/models/ai_model_definition.dart';
import '../../ai_engine_hub/services/ai_engine_config_controller.dart';
import '../../ai_engine_hub/widgets/ai_engine_hub_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';

class GoogleAiArchitectureHubDialog extends StatelessWidget {
  const GoogleAiArchitectureHubDialog({super.key});

  static Future<void> show(BuildContext context) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const GoogleAiArchitectureHubDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1100,
        height: 780,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // Header
            _buildHeader(context, loc),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 16),

            // 3-Tier Architecture Diagram
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Tier 1: Flutter UI Layer (Frontend)
                    _buildTierContainer(
                      context: context,
                      title: AppLocalizations.trStatic('uiCopy048'),
                      badge: 'Client-Side Web & Mobile',
                      accentColor: theme.colorScheme.primary,
                      child: _buildFrontendTier(context, loc, lang),
                    ),
                    const SizedBox(height: 16),

                    // Connection Connectors Downward Arrow
                    Icon(Symbols.arrow_downward_rounded, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(height: 16),

                    // Tier 2: Firebase & Google Cloud Backend
                    _buildTierContainer(
                      context: context,
                      title: AppLocalizations.trStatic('uiCopy045'),
                      badge: 'Serverless Cloud Infrastructure',
                      accentColor: theme.colorScheme.secondary,
                      child: _buildBackendTier(context, loc),
                    ),
                    const SizedBox(height: 16),

                    // Connection Connectors Downward Arrow
                    Icon(Symbols.arrow_downward_rounded, color: theme.colorScheme.tertiary, size: 24),
                    const SizedBox(height: 16),

                    // Tier 3: Google AI & Gemini Services
                    _buildTierContainer(
                      context: context,
                      title: AppLocalizations.trStatic('uiCopy054'),
                      badge: 'Generative Intelligence Engine',
                      accentColor: theme.colorScheme.tertiary,
                      child: _buildAiServicesTier(context, loc),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Icon(Symbols.hub_rounded, color: theme.colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      loc.tr('architectureHubTitle'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Live Multi-Cloud Mesh',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('architectureHubSubtitle'),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TashilButton.filled(
          icon: Symbols.tune_rounded,
          label: loc.tr('switchAiModelsBtn'),
          onPressed: () => AiEngineHubDialog.show(context),
        ),
        const SizedBox(width: 8),
        TashilIconButton.close(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTierContainer({
    required BuildContext context,
    required String title,
    required String badge,
    required Color accentColor,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                  color: accentColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildFrontendTier(BuildContext context, AppLocalizations loc, String lang) {
    final theme = Theme.of(context);
    final country = CountryController.countryCode;
    final defaultProperty = PropertyItem.sampleProperties.first;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildNodeChip(
          context: context,
          icon: Symbols.search_rounded,
          title: AppLocalizations.trStatic('uiCopy080'),
          subtitle: AppLocalizations.trStatic('uiCopy047'),
          accentColor: theme.colorScheme.primary,
          onTap: () => VisualSearchModal.show(context, countryCode: country),
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.document_scanner_rounded,
          title: AppLocalizations.trStatic('uiCopy041'),
          subtitle: AppLocalizations.trStatic('uiCopy068'),
          accentColor: theme.colorScheme.primary,
          onTap: () => AiDocumentOcrModal.show(context, countryCode: country),
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.chair_rounded,
          title: AppLocalizations.trStatic('uiCopy030'),
          subtitle: AppLocalizations.trStatic('uiCopy056'),
          accentColor: theme.colorScheme.primary,
          onTap: () => AiVirtualStagingDialog.show(context),
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.troubleshoot_rounded,
          title: AppLocalizations.trStatic('uiCopy082'),
          subtitle: AppLocalizations.trStatic('uiCopy050'),
          accentColor: theme.colorScheme.primary,
          onTap: () => AiVisionMaintenanceDialog.show(context),
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.mic_rounded,
          title: AppLocalizations.trStatic('uiCopy053'),
          subtitle: AppLocalizations.trStatic('uiCopy067'),
          accentColor: theme.colorScheme.primary,
          onTap: () => GeminiVoiceBrokerDialog.show(context, defaultProperty),
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.gavel_rounded,
          title: AppLocalizations.trStatic('uiCopy057'),
          subtitle: AppLocalizations.trStatic('uiCopy052'),
          accentColor: theme.colorScheme.primary,
          onTap: () => AiLegalClauseAdvisorDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildBackendTier(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildNodeChip(
          context: context,
          icon: Symbols.lock_outline_rounded,
          title: AppLocalizations.trStatic('uiCopy046'),
          subtitle: AppLocalizations.trStatic('uiCopy066'),
          accentColor: theme.colorScheme.secondary,
          onTap: () {},
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.storage_rounded,
          title: AppLocalizations.trStatic('uiCopy035'),
          subtitle: AppLocalizations.trStatic('uiCopy081'),
          accentColor: theme.colorScheme.secondary,
          onTap: () {},
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.cloud_upload_rounded,
          title: AppLocalizations.trStatic('uiCopy037'),
          subtitle: AppLocalizations.trStatic('uiCopy065'),
          accentColor: theme.colorScheme.secondary,
          onTap: () {},
        ),
        _buildNodeChip(
          context: context,
          icon: Symbols.functions_rounded,
          title: AppLocalizations.trStatic('uiCopy036'),
          subtitle: AppLocalizations.trStatic('uiCopy075'),
          accentColor: theme.colorScheme.secondary,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAiServicesTier(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final country = CountryController.countryCode;
    final defaultProperty = PropertyItem.sampleProperties.first;
    final controller = AiEngineConfigController();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final legalModel = controller.getActiveModel(AiServiceType.legalAdvisor);
        final ingestionModel = controller.getActiveModel(AiServiceType.propertyIngestion);
        final stagingModel = controller.getActiveModel(AiServiceType.virtualStaging);
        final searchModel = controller.getActiveModel(AiServiceType.semanticSearch);
        final valuationModel = controller.getActiveModel(AiServiceType.smartValuation);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${loc.tr('allEnginesOperational')} • ${controller.categories.length} ${loc.tr('activeAiEnginesCount')}',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                TashilButton.tonal(
                  icon: Symbols.swap_horiz_rounded,
                  label: loc.tr('switchActiveModelsTierBtn'),
                  onPressed: () => AiEngineHubDialog.show(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildNodeChip(
                  context: context,
                  icon: Symbols.mic_external_on_rounded,
                  title: ingestionModel.name,
                  subtitle: AppLocalizations.trStatic('uiCopy084'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiEngineHubDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Symbols.balance_rounded,
                  title: legalModel.name,
                  subtitle: AppLocalizations.trStatic('uiCopy058'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiLegalClauseAdvisorDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Symbols.price_check_rounded,
                  title: valuationModel.name,
                  subtitle: AppLocalizations.trStatic('uiCopy072'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiEngineHubDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Symbols.travel_explore_rounded,
                  title: searchModel.name,
                  subtitle: AppLocalizations.trStatic('uiCopy074'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiEngineHubDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Symbols.auto_awesome_rounded,
                  title: stagingModel.name,
                  subtitle: AppLocalizations.trStatic('uiCopy073'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiVirtualStagingDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Symbols.description_rounded,
                  title: AppLocalizations.trStatic('uiCopy034'),
                  subtitle: AppLocalizations.trStatic('uiCopy055'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiDocumentOcrModal.show(context, countryCode: country),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Symbols.remove_red_eye_rounded,
                  title: AppLocalizations.trStatic('uiCopy050'),
                  subtitle: AppLocalizations.trStatic('uiCopy040'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiVisionMaintenanceDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Symbols.graphic_eq_rounded,
                  title: AppLocalizations.trStatic('uiCopy051'),
                  subtitle: AppLocalizations.trStatic('uiCopy059'),
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => GeminiVoiceBrokerDialog.show(context, defaultProperty),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNodeChip({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Symbols.open_in_new_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
