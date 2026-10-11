import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/media/media_picker_service.dart';
import 'package:tashil_real_estate/core/utils/image_utils.dart';

class PropertyMediaGalleryUploader extends StatefulWidget {
  final List<String> photoUrls;
  final ValueChanged<List<String>> onPhotosChanged;
  final int maxPhotos;

  const PropertyMediaGalleryUploader({
    super.key,
    required this.photoUrls,
    required this.onPhotosChanged,
    this.maxPhotos = 10,
  });

  @override
  State<PropertyMediaGalleryUploader> createState() => _PropertyMediaGalleryUploaderState();
}

class _PropertyMediaGalleryUploaderState extends State<PropertyMediaGalleryUploader> {
  final MediaPickerService _mediaPicker = MediaPickerService();
  bool _isUploading = false;

  Future<void> _pickFromDevice() async {
    if (widget.photoUrls.length >= widget.maxPhotos) return;
    try {
      setState(() => _isUploading = true);
      final pickedUrls = await _mediaPicker.pickImages();
      if (pickedUrls.isNotEmpty) {
        final newUrls = List<String>.from(widget.photoUrls);
        for (final url in pickedUrls) {
          if (!newUrls.contains(url) && newUrls.length < widget.maxPhotos) {
            newUrls.add(url);
          }
        }
        widget.onPhotosChanged(newUrls);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAddUrlDialog(AppLocalizations loc) {
    if (widget.photoUrls.length >= widget.maxPhotos) return;
    final controller = TextEditingController();
    TashilAlertDialog.show(
      context: context,
      iconData: Icons.add_link_rounded,
      title: loc.tr('enterImageUrlDialogTitle'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: loc.tr('imageUrlInputHint'),
          prefixIcon: const Icon(Icons.link_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.url,
      ),
      actions: [
        TashilButton.text(
          onPressed: () => Navigator.of(context).pop(),
          label: loc.tr('cancelBtn'),
        ),
        TashilButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty && !widget.photoUrls.contains(text) && widget.photoUrls.length < widget.maxPhotos) {
              final updated = List<String>.from(widget.photoUrls)..add(text);
              widget.onPhotosChanged(updated);
            }
            Navigator.of(context).pop();
          },
          label: loc.tr('confirmAddBtn'),
        ),
      ],
    );
  }

  void _removePhoto(int index) {
    final updated = List<String>.from(widget.photoUrls)..removeAt(index);
    widget.onPhotosChanged(updated);
  }

  void _setAsCover(int index) {
    if (index == 0 || index >= widget.photoUrls.length) return;
    final updated = List<String>.from(widget.photoUrls);
    final item = updated.removeAt(index);
    updated.insert(0, item);
    widget.onPhotosChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = widget.photoUrls.length;
    final isMinMet = count >= 3;
    final isMaxReached = count >= widget.maxPhotos;

    Color badgeBg;
    Color badgeBorder;
    Color badgeFg;
    String badgeText;

    if (!isMinMet) {
      badgeBg = theme.colorScheme.errorContainer;
      badgeBorder = theme.colorScheme.error.withValues(alpha: 0.5);
      badgeFg = theme.colorScheme.onErrorContainer;
      badgeText = '$count / 3 ${loc.tr('photosNeedMoreBadge')}';
    } else if (isMaxReached) {
      badgeBg = theme.colorScheme.secondaryContainer;
      badgeBorder = theme.colorScheme.secondary.withValues(alpha: 0.5);
      badgeFg = theme.colorScheme.onSecondaryContainer;
      badgeText = loc.tr('maxPhotosReachedBadge');
    } else {
      badgeBg = theme.colorScheme.primaryContainer;
      badgeBorder = theme.colorScheme.primary.withValues(alpha: 0.5);
      badgeFg = theme.colorScheme.onPrimaryContainer;
      badgeText = '$count / ${widget.maxPhotos} ${loc.tr('photosReadyBadge')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMinMet ? theme.colorScheme.outlineVariant : theme.colorScheme.error,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final chipWidget = TashilAssistChip(
                label: badgeText,
                icon: isMinMet ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                variant: TashilChipVariant.tonal,
                backgroundColor: badgeBg,
                foregroundColor: badgeFg,
                borderColor: badgeBorder,
                height: 30.0,
                borderRadius: 8.0,
              )
                  .animate(key: ValueKey(count))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.0, 1.0),
                    duration: 250.ms,
                    curve: Curves.easeOutBack,
                  );

              final infoRow = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMinMet ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMinMet ? Icons.photo_library_rounded : Icons.add_photo_alternate_rounded,
                      size: 20,
                      color: isMinMet ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer,
                    ),
                  )
                      .animate(target: isMinMet ? 1 : 0)
                      .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 250.ms),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('uploadPhotosTitle'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.tr('uploadPhotosSubtitle'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoRow,
                    const SizedBox(height: 10),
                    chipWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: infoRow),
                  const SizedBox(width: 8),
                  chipWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Upload Actions Toolbar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TashilButton.tonal(
                onPressed: (_isUploading || isMaxReached) ? null : _pickFromDevice,
                icon: Icons.file_upload_outlined,
                label: loc.tr('uploadFromDeviceBtn'),
              ),
              TashilButton.outlined(
                onPressed: isMaxReached ? null : () => _showAddUrlDialog(loc),
                icon: Icons.add_link_rounded,
                label: loc.tr('addPhotoByUrlBtn'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Gallery View
          if (widget.photoUrls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text(
                    loc.tr('minPhotosNotice'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms)
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final url = widget.photoUrls[index];
                  final isCover = index == 0;

                  return _buildPhotoCard(
                    url: url,
                    index: index,
                    isCover: isCover,
                    loc: loc,
                    theme: theme,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String url,
    required int index,
    required bool isCover,
    required AppLocalizations loc,
    required ThemeData theme,
  }) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isCover
                ? theme.colorScheme.tertiary.withValues(alpha: 0.25)
                : theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isCover ? theme.colorScheme.tertiary : theme.colorScheme.outlineVariant,
          width: isCover ? 2.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Image Display
            Positioned.fill(
              child: ImageUtils.cachedImage(
                imageUrl: url,
                fit: BoxFit.cover,
                cacheWidth: url.startsWith('data:') ? null : 400,
                cacheHeight: url.startsWith('data:') ? null : 300,
              ),
            ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 44,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Index / Cover Badge
            PositionedDirectional(
              top: 8,
              end: 8,
              child: isCover
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: theme.colorScheme.onTertiary),
                          const SizedBox(width: 3),
                          Text(
                            loc.tr('coverPhotoBadge'),
                            style: TextStyle(
                              color: theme.colorScheme.onTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 2200.ms, color: Colors.white38)
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),

            // Delete Button (M3 Shaded Close Standard)
            PositionedDirectional(
              top: 6,
              start: 6,
              child: Tooltip(
                message: loc.tr('deletePhotoTooltip'),
                child: InkWell(
                  onTap: () => _removePhoto(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.close_rounded, size: 14, color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),

            // Make Cover Button (if not already cover)
            if (!isCover)
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: SizedBox(
                  height: 26,
                  child: TashilButton.tonal(
                    onPressed: () => _setAsCover(index),
                    label: loc.tr('setAsCoverTooltip'),
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 40).ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
