import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/responsive_layout.dart';
import '../views/ai_engine_hub_view.dart';

/// Modal dialog wrapper for AiEngineHubView with M3 shaded close button and responsive sizing.
class AiEngineHubDialog extends StatelessWidget {
  const AiEngineHubDialog({super.key});

  static Future<void> show(BuildContext context) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AiEngineHubDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 10 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 1250,
        height: isMobile ? MediaQuery.of(context).size.height * 0.92 : 820,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header Bar with Shaded Close Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: colorScheme.surfaceContainerLowest,
              child: Row(
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
                        child: Icon(Icons.smart_toy_rounded, color: colorScheme.onPrimaryContainer, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('aiEngineHubTitle'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            loc.tr('superAdminWorkspaceTitle'),
                            style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TashilIconButton.close(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Embedded AI Engine Hub View
            const Expanded(
              child: AiEngineHubView(),
            ),
          ],
        ),
      ),
    );
  }
}
