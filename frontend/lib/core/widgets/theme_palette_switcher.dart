import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';

/// An elegant Material Design 3 Palette & Dark Mode Switcher.
/// Allows selecting any of the 5 official M3 seed colors and toggling Light/Dark modes.
class ThemePaletteSwitcher extends StatelessWidget {
  final bool isCompact;

  const ThemePaletteSwitcher({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ThemePaletteController.instance;
    final lang = LocaleController.languageCode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<M3ThemePalette>(
      valueListenable: controller.currentPalette,
      builder: (context, activePalette, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: controller.isDarkMode,
          builder: (context, isDark, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Five M3 Seed Color Dots. With 48dp targets (TAQ-159) five dots need ~240dp,
                  // so a compact switcher on a phone-width screen folds them into one 48dp menu.
                  if (isCompact &&
                      MediaQuery.sizeOf(context).width < _compactMenuBreakpoint)
                    _buildPaletteMenu(
                      context,
                      activePalette: activePalette,
                      lang: lang,
                      onSelected: controller.setPalette,
                    )
                  else
                    for (final palette in M3ThemePalette.values) ...[
                      _buildColorDot(
                        context,
                        palette: palette,
                        isSelected: palette == activePalette,
                        lang: lang,
                        onTap: () => controller.setPalette(palette),
                      ),
                    ],

                  // Divider
                  Container(
                    height: 18,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: colorScheme.outlineVariant,
                  ),

                  // 2. Dark / Light Mode Toggle Button
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    // TAQ-159: M3 minimum touch target (48dp), the icon stays 18.
                    constraints: const BoxConstraints(
                      minWidth: kMinInteractiveDimension,
                      minHeight: kMinInteractiveDimension,
                    ),
                    tooltip: isDark
                        ? 'الوضع النهاري (Light)'
                        : 'الوضع الليلي (Dark)',
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_outlined,
                      color: isDark
                          ? Colors.amber[300]
                          : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => controller.toggleDarkMode(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static const double _compactMenuBreakpoint = 600;

  Widget _buildPaletteMenu(
    BuildContext context, {
    required M3ThemePalette activePalette,
    required String lang,
    required ValueChanged<M3ThemePalette> onSelected,
  }) {
    return PopupMenuButton<M3ThemePalette>(
      key: const ValueKey('theme-palette-menu'),
      tooltip: activePalette.getLocalizedName(lang),
      initialValue: activePalette,
      onSelected: onSelected,
      constraints: const BoxConstraints(minWidth: 160),
      itemBuilder: (context) => [
        for (final palette in M3ThemePalette.values)
          PopupMenuItem<M3ThemePalette>(
            value: palette,
            child: Row(
              children: [
                Icon(Icons.circle, size: 18, color: palette.color),
                const SizedBox(width: 12),
                Expanded(child: Text(palette.getLocalizedName(lang))),
                if (palette == activePalette)
                  const Icon(Icons.check_rounded, size: 18),
              ],
            ),
          ),
      ],
      child: SizedBox(
        width: kMinInteractiveDimension,
        height: kMinInteractiveDimension,
        child: Center(
          child: Icon(Icons.circle, size: 22, color: activePalette.color),
        ),
      ),
    );
  }

  Widget _buildColorDot(
    BuildContext context, {
    required M3ThemePalette palette,
    required bool isSelected,
    required String lang,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: palette.getLocalizedName(lang),
      // TAQ-159: the swatch stays 24dp, but the tap target (and its semantics node) is 48x48.
      child: Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: kMinInteractiveDimension,
            height: kMinInteractiveDimension,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: palette.color, width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: palette.color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
