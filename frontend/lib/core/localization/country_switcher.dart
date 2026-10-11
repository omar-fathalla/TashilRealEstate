import 'package:flutter/material.dart';
import 'country_controller.dart';
import 'app_localizations.dart';

class CountrySwitcher extends StatelessWidget {
  final bool isCompact;
  final bool showLabel;

  const CountrySwitcher({super.key, this.isCompact = false, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: CountryController.currentCountry,
      builder: (context, currentCountry, child) {
        return Theme(
          data: theme.copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              color: colorScheme.surface,
              elevation: 4,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: PopupMenuButton<String>(
            tooltip: '${loc.tr('country')} / Country',
            offset: const Offset(0, 44),
            onSelected: (code) => CountryController.setCountry(code),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            itemBuilder: (context) => [
              _buildMenuItem(
                context,
                code: 'EG',
                flag: '🇪🇬',
                title: loc.tr('country_eg'),
                subtitle: 'Egypt (EGP)',
                isSelected: currentCountry == 'EG',
              ),
              _buildMenuItem(
                context,
                code: 'AE',
                flag: '🇦🇪',
                title: loc.tr('country_ae'),
                subtitle: 'UAE (AED)',
                isSelected: currentCountry == 'AE',
              ),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: isCompact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentCountry == 'EG' ? '🇪🇬' : '🇦🇪',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    Text(
                      currentCountry == 'EG' ? loc.tr('country_eg') : loc.tr('country_ae'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required String code,
    required String flag,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuItem<String>(
      value: code,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(flag, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          if (isSelected)
            Icon(
              Icons.check_rounded,
              size: 18,
              color: colorScheme.primary,
            )
          else
            const SizedBox(width: 18),
        ],
      ),
    );
  }
}
