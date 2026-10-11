import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../public_marketplace/models/property_item.dart';
import '../../public_marketplace/widgets/property_card.dart';
import '../../public_marketplace/widgets/property_details_dialog.dart';

/// Modal dialog that presents an exact, live simulation of how the property
/// card appears to visitors in the Tashil Public Marketplace.
class MarketplaceVisitorPreviewDialog extends StatefulWidget {
  final PropertyItem property;

  const MarketplaceVisitorPreviewDialog({
    super.key,
    required this.property,
  });

  static Future<void> show(BuildContext context, PropertyItem property) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MarketplaceVisitorPreviewDialog(property: property),
    );
  }

  @override
  State<MarketplaceVisitorPreviewDialog> createState() => _MarketplaceVisitorPreviewDialogState();
}

class _MarketplaceVisitorPreviewDialogState extends State<MarketplaceVisitorPreviewDialog> {
  String _selectedAction = 'marketplace';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, _, __) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 36,
            vertical: isMobile ? 16 : 28,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 820),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.tr('previewModalTitle'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    loc.tr('previewModalSubtitle'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TashilIconButton.close(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Divider(height: 20, color: theme.colorScheme.outlineVariant),

                  // Hint Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: theme.colorScheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.tr('previewInteractiveHint'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Marketplace Card Preview Container
                  Flexible(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: PropertyCard(property: widget.property),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Action Buttons - Official M3 Connected Button Group
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TashilConnectedButtonGroup<String>(
                      height: 42.0,
                      isFullWidth: isMobile,
                      selectedValue: _selectedAction,
                      showCheckmark: false,
                      onSelectionChanged: (action) {
                        setState(() => _selectedAction = action);
                        if (action == 'cancel') {
                          Navigator.of(context).pop();
                        } else if (action == 'details') {
                          PropertyDetailsDialog.show(context, widget.property);
                        } else if (action == 'marketplace') {
                          Navigator.of(context).pop();
                          context.go('/');
                        }
                      },
                      segments: [
                        TashilConnectedButtonSegment(
                          value: 'cancel',
                          label: loc.tr('cancelBtn'),
                          icon: Icons.close_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'details',
                          label: loc.tr('openFullDetailsBtn'),
                          icon: Icons.open_in_new_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: 'marketplace',
                          label: loc.tr('goToMarketplaceBtn'),
                          icon: Icons.storefront_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

