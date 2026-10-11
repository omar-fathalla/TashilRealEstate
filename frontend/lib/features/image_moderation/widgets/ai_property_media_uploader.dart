import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/image_moderation/models/image_moderation_model.dart';
import 'package:tashil_real_estate/features/image_moderation/services/ai_image_moderation_service.dart';
import 'package:tashil_real_estate/features/image_moderation/widgets/ai_image_moderator_dialog.dart';

class AiPropertyMediaUploader extends StatefulWidget {
  final ValueChanged<List<ImageModerationItem>>? onPhotosUpdated;

  const AiPropertyMediaUploader({super.key, this.onPhotosUpdated});

  @override
  State<AiPropertyMediaUploader> createState() => _AiPropertyMediaUploaderState();
}

class _AiPropertyMediaUploaderState extends State<AiPropertyMediaUploader> {
  final _service = AiImageModerationService();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ValueListenableBuilder<List<ImageModerationItem>>(
      valueListenable: _service.moderatedItemsNotifier,
      builder: (context, items, _) {
        final approvedItems = items.where((it) => it.isApproved).toList();
        final rejectedItems = items.where((it) => it.isRejected).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.tr('aiAutomatedPhotoInspection'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            loc.tr('aiComplianceGuaranteeSubtitle'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TashilButton.tonal(
                    icon: Icons.tune_rounded,
                    label: loc.tr('openAiStudioInspector'),
                    onPressed: () => AiImageModeratorDialog.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Upload Dropzone / Quick simulate
              InkWell(
                onTap: () => AiImageModeratorDialog.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 36, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        loc.tr('dragDropPropertyPhotosPrompt'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.tr('photosAutoScreenedHint'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (items.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.tr('uploadedPhotos')} (${items.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${approvedItems.length} ${loc.tr('approved')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (rejectedItems.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${rejectedItems.length} ${loc.tr('rejected')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      final isApproved = it.isApproved;

                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isApproved ? theme.colorScheme.primary : theme.colorScheme.error,
                                width: 1.5,
                              ),
                              image: it.imagePathOrUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(it.imagePathOrUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          PositionedDirectional(
                            top: 4,
                            start: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: isApproved ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isApproved ? '✓' : '✕',
                                style: TextStyle(
                                  color: isApproved ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            top: 2,
                            end: 2,
                            child: InkWell(
                              onTap: () => _service.removeItem(it.id),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: theme.colorScheme.onSurface, size: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
