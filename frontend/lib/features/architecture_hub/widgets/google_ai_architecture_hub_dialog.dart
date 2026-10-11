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
                      title: 'Flutter UI Layer (Frontend)',
                      badge: 'Client-Side Web & Mobile',
                      accentColor: theme.colorScheme.primary,
                      child: _buildFrontendTier(context, loc, lang),
                    ),
                    const SizedBox(height: 16),

                    // Connection Connectors Downward Arrow
                    Icon(Icons.arrow_downward_rounded, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(height: 16),

                    // Tier 2: Firebase & Google Cloud Backend
                    _buildTierContainer(
                      context: context,
                      title: 'Firebase & Google Cloud Backend',
                      badge: 'Serverless Cloud Infrastructure',
                      accentColor: theme.colorScheme.secondary,
                      child: _buildBackendTier(context, loc),
                    ),
                    const SizedBox(height: 16),

                    // Connection Connectors Downward Arrow
                    Icon(Icons.arrow_downward_rounded, color: theme.colorScheme.tertiary, size: 24),
                    const SizedBox(height: 16),

                    // Tier 3: Google AI & Gemini Services
                    _buildTierContainer(
                      context: context,
                      title: 'Google AI & Gemini Services',
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
          child: Icon(Icons.hub_rounded, color: theme.colorScheme.primary, size: 24),
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
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
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
                      style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('architectureHubSubtitle'),
                style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TashilButton.filled(
          icon: Icons.tune_rounded,
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
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
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
          icon: Icons.search_rounded,
          title: 'Vector & Image Semantic Search',
          subtitle: 'Firestore Vector Embeddings',
          accentColor: theme.colorScheme.primary,
          onTap: () => VisualSearchModal.show(context, countryCode: country),
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.document_scanner_rounded,
          title: 'Document AI Auto-Fill',
          subtitle: 'OCR & ID Extractor',
          accentColor: theme.colorScheme.primary,
          onTap: () => AiDocumentOcrModal.show(context, countryCode: country),
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.chair_rounded,
          title: 'AI Virtual Staging',
          subtitle: 'Imagen 3 Generative Engine',
          accentColor: theme.colorScheme.primary,
          onTap: () => AiVirtualStagingDialog.show(context),
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.troubleshoot_rounded,
          title: 'Vision Maintenance Diagnosis',
          subtitle: 'Gemini 2.0 Flash Vision',
          accentColor: theme.colorScheme.primary,
          onTap: () => AiVisionMaintenanceDialog.show(context),
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.mic_rounded,
          title: 'Gemini Live Voice Broker',
          subtitle: 'Multimodal Audio Streaming',
          accentColor: theme.colorScheme.primary,
          onTap: () => GeminiVoiceBrokerDialog.show(context, defaultProperty),
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.gavel_rounded,
          title: 'Legal Reasoning & RAG',
          subtitle: 'Gemini 2.0 Pro Legal Audit',
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
          icon: Icons.lock_outline_rounded,
          title: 'Firebase Auth',
          subtitle: 'Multi-Tenant RBAC Gateway',
          accentColor: theme.colorScheme.secondary,
          onTap: () {},
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.storage_rounded,
          title: 'Cloud Firestore',
          subtitle: 'Vector Embeddings & Live Messaging',
          accentColor: theme.colorScheme.secondary,
          onTap: () {},
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.cloud_upload_outlined,
          title: 'Cloud Storage',
          subtitle: 'Media, Leases & Identity PDFs',
          accentColor: theme.colorScheme.secondary,
          onTap: () {},
        ),
        _buildNodeChip(
          context: context,
          icon: Icons.functions_rounded,
          title: 'Cloud Functions Gen 2',
          subtitle: 'Serverless Event Mesh & AI Bridges',
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
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${loc.tr('allEnginesOperational')} • ${controller.categories.length} ${loc.tr('activeAiEnginesCount')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TashilButton.tonal(
                  icon: Icons.swap_horiz_rounded,
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
                  icon: Icons.mic_external_on_rounded,
                  title: ingestionModel.name,
                  subtitle: 'Voice & Property Ingestion',
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiEngineHubDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Icons.balance_rounded,
                  title: legalModel.name,
                  subtitle: 'Legal Reasoning & Tenancy RAG',
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiLegalClauseAdvisorDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Icons.price_check_rounded,
                  title: valuationModel.name,
                  subtitle: 'Rental Valuation & Comps',
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiEngineHubDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Icons.travel_explore_rounded,
                  title: searchModel.name,
                  subtitle: 'Semantic Vector Embeddings',
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiEngineHubDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Icons.auto_awesome,
                  title: stagingModel.name,
                  subtitle: 'Room-Preserving Virtual Staging',
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiVirtualStagingDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Icons.description_rounded,
                  title: 'Cloud Document AI',
                  subtitle: 'ID Extraction & Fraud Analysis',
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiDocumentOcrModal.show(context, countryCode: country),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Icons.remove_red_eye_rounded,
                  title: 'Gemini 2.0 Flash Vision',
                  subtitle: 'Defect Analysis & Struct JSON',
                  accentColor: theme.colorScheme.tertiary,
                  onTap: () => AiVisionMaintenanceDialog.show(context),
                ),
                _buildNodeChip(
                  context: context,
                  icon: Icons.graphic_eq_rounded,
                  title: 'Gemini 2.0 Multimodal Live',
                  subtitle: 'Low-Latency WebRTC Voice API',
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
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
