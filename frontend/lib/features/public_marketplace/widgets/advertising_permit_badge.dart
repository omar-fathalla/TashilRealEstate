import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';

/// Permit number and Madmoun-style QR shown on a public listing.
class AdvertisingPermitBadge extends StatelessWidget {
  final String permitNumber;
  final double qrSize;

  const AdvertisingPermitBadge({
    super.key,
    required this.permitNumber,
    this.qrSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = permitNumber.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final qr = SizedBox(
      width: qrSize,
      height: qrSize,
      child: QrImageView(
        data: trimmed,
        version: QrVersions.auto,
        size: qrSize,
        padding: EdgeInsets.zero,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: colorScheme.onSurface,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: colorScheme.onSurface,
        ),
      ),
    );
    final caption = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr('adPermitNumberLabel'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          trimmed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        qr,
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: caption,
        ),
      ],
    );
  }
}
