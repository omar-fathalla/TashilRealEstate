import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/font_theme_controller.dart';
import 'package:tashil_real_estate/core/theme/theme_palette_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/lists/m3_lists_showcase_dialog.dart';
import 'package:tashil_real_estate/core/design_system/loading/m3_loading_showcase_dialog.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/widgets/font_picker_dialog.dart';
import 'package:tashil_real_estate/features/ai_engine_hub/widgets/ai_engine_hub_dialog.dart';

/// Minimalist, Icon-First Material Design 3 Settings Dialog for Tashil Real Estate.
/// Integrates Country, Language, Dark Mode, Color Themes, and Font Themes with zero clutter.
class AppSettingsDialog extends StatelessWidget {
  const AppSettingsDialog({super.key});

  /// Displays the dialog centered on desktop or as a bottom sheet on mobile.
  static Future<void> show(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AppSettingsDialog(),
      );
    }

    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: AppSettingsDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;
    final currentLang = loc.locale.languageCode;

    final dialogContent = Container(
      constraints: BoxConstraints(
        maxWidth: 760,
        maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.90 : 640,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isMobile ? 80 : 40),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header Bar with M3 Shaded Close Button
          _buildHeader(context, loc, colorScheme),

          // 2. Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Quick Icon Controls (Country, Language, Dark Mode)
                  _buildQuickControlsBar(context, loc, colorScheme, isMobile),

                  const SizedBox(height: 20),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 20),

                  // Section 2: لوحة الألوان (Color Palette)
                  _buildColorPaletteSection(context, loc, colorScheme, currentLang),

                  const SizedBox(height: 20),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 20),

                  // Section 3: الخطوط (Typography Card with Modal Picker Trigger)
                  _buildFontSection(context, loc, colorScheme, currentLang, isMobile),

                  const SizedBox(height: 20),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 20),

                  // Section 4: معايير تصميم M3 والقوائم (Design System Standards & Lists)
                  _buildDesignStandardsSection(context, loc, colorScheme, isMobile),

                  const SizedBox(height: 20),
                  const TashilDivider.middleInset(),
                  const SizedBox(height: 20),

                  // Section 5: محركات ونماذج الذكاء الاصطناعي (AI Models & Engine Hub)
                  _buildAiEngineSection(context, loc, colorScheme, isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return isMobile
        ? ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: dialogContent,
          )
        : dialogContent;
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            loc.tr('settings'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // M3 Shaded Close Button standard
          TashilIconButton.close(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Icon-first controls for Country, Language & Dark Mode using official M3 TashilConnectedButtonGroup
  Widget _buildQuickControlsBar(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Country & Currency Selector (Google Icons Only)
                ValueListenableBuilder<String>(
                  valueListenable: CountryController.currentCountry,
                  builder: (context, currentCountry, _) {
                    return SizedBox(
                      width: isNarrow ? (constraints.maxWidth > 340 ? constraints.maxWidth : null) : null,
                      child: TashilConnectedButtonGroup<String>(
                        height: 40,
                        selectedValue: currentCountry,
                        onSelectionChanged: (countryCode) {
                          CountryController.setCountry(countryCode);
                        },
                        segments: [
                          TashilConnectedButtonSegment(
                            value: 'EG',
                            label: '${loc.tr('country_eg')} (${loc.tr('currency_eg')})',
                            icon: Icons.flag_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'AE',
                            label: '${loc.tr('country_ae')} (${loc.tr('currency_ae')})',
                            icon: Icons.flag_rounded,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 2. Language Selector (Google Icons Only)
                ValueListenableBuilder<Locale>(
                  valueListenable: LocaleController.currentLocale,
                  builder: (context, currentLocale, _) {
                    final lang = currentLocale.languageCode;
                    return SizedBox(
                      width: isNarrow ? (constraints.maxWidth > 340 ? constraints.maxWidth : null) : null,
                      child: TashilConnectedButtonGroup<String>(
                        height: 40,
                        selectedValue: lang,
                        onSelectionChanged: (selectedLang) {
                          LocaleController.setLanguage(selectedLang);
                        },
                        segments: const [
                          TashilConnectedButtonSegment(
                            value: 'ar',
                            label: 'عربي',
                            icon: Icons.translate_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'en',
                            label: 'EN',
                            icon: Icons.translate_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'hi',
                            label: 'हिं',
                            icon: Icons.translate_rounded,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 3. Dark/Light Mode Toggle (Google Icons Only)
                ValueListenableBuilder<bool>(
                  valueListenable: ThemePaletteController.instance.isDarkMode,
                  builder: (context, isDark, _) {
                    return TashilConnectedButtonGroup<bool>(
                      height: 40,
                      selectedValue: isDark,
                      onSelectionChanged: (newVal) {
                        if (newVal != isDark) {
                          ThemePaletteController.instance.toggleDarkMode();
                        }
                      },
                      segments: [
                        TashilConnectedButtonSegment(
                          value: false,
                          label: loc.tr('lightMode'),
                          icon: Icons.light_mode_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: true,
                          label: loc.tr('darkMode'),
                          icon: Icons.dark_mode_rounded,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Section 2: لوحة الألوان (Pure Color Circles, Dynamic Seed Derivation, M3 Hover Engine)
  Widget _buildColorPaletteSection(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    String currentLang,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.palette_rounded, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('colorThemesTitle'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    loc.tr('colorThemesSubtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pure Color Circles with Default Blue and M3 Primary Hover Derivation
        ValueListenableBuilder<M3ThemePalette>(
          valueListenable: ThemePaletteController.instance.currentPalette,
          builder: (context, activePalette, _) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: M3ThemePalette.values.map((palette) {
                  final isSelected = palette == activePalette;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 14),
                    child: Tooltip(
                      message: palette.getLocalizedName(currentLang),
                      child: _PaletteCircleItem(
                        palette: palette,
                        isSelected: isSelected,
                        colorScheme: colorScheme,
                        onTap: () {
                          ThemePaletteController.instance.setPalette(palette);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Section 3: الخطوط (Modern Typography Card with Dedicated Modal Dialog Picker)
  Widget _buildFontSection(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    String currentLang,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.font_download_rounded, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.tr('fontThemesTitle'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    loc.tr('fontSelectionSubtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Dedicated direct icon button to trigger font modal
            Tooltip(
              message: loc.tr('changeFont'),
              child: TashilIconButton.tonal(
                icon: Icons.tune_rounded,
                size: 36,
                iconSize: 18,
                onPressed: () => FontPickerDialog.show(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Interactive Active Font Card conforming to M3 Card guidelines
        ValueListenableBuilder<AppFontTheme>(
          valueListenable: FontThemeController.instance.currentFont,
          builder: (context, activeFont, _) {
            String categoryName;
            switch (activeFont.category) {
              case FontCategory.modern:
                categoryName = loc.tr('fontCategoryModern');
                break;
              case FontCategory.headlines:
                categoryName = loc.tr('fontCategoryHeadlines');
                break;
              case FontCategory.classic:
                categoryName = loc.tr('fontCategoryClassic');
                break;
            }

            return TashilCard.outlined(
              enableHoverAnimation: true,
              onTap: () => FontPickerDialog.show(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.text_fields_rounded,
                            size: 22,
                            color: colorScheme.onPrimaryContainer,
                          ),
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
                                      activeFont.getLocalizedName(currentLang),
                                      style: activeFont.getTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.tr(activeFont.descriptionKey),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        isMobile
                            ? Icon(Icons.chevron_right_rounded, color: colorScheme.primary)
                            : TashilButton.tonal(
                                label: loc.tr('changeFont'),
                                icon: Icons.tune_rounded,
                                height: 36,
                                onPressed: () => FontPickerDialog.show(context),
                              ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Live rendered sample text in this active font
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(70),
                        ),
                      ),
                      child: Text(
                        loc.tr('fontPreviewSample'),
                        style: activeFont.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Section 4: M3 Design System Standards & Official Lists Suite
  Widget _buildDesignStandardsSection(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              loc.tr('m3DesignSystemTab'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TashilCard.outlined(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('m3DesignSystemTabDesc'),
                style: TextStyle(
                  fontSize: 12.5,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                loc.tr('m3MotionPreferenceTitle'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.tr('m3MotionPreferenceDesc'),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<TashilPageTransitionType>(
                valueListenable: MotionPreferenceController.currentTransition,
                builder: (context, activeMotion, _) {
                  return TashilConnectedButtonGroup<TashilPageTransitionType>(
                    selectedValue: activeMotion,
                    onSelectionChanged: (val) {
                      MotionPreferenceController.setTransition(val);
                    },
                    segments: [
                      TashilConnectedButtonSegment(
                        value: TashilPageTransitionType.fadeThrough,
                        label: loc.tr('m3MotionFadeThrough'),
                        icon: Icons.auto_awesome_motion_rounded,
                      ),
                      TashilConnectedButtonSegment(
                        value: TashilPageTransitionType.sharedAxisX,
                        label: loc.tr('m3MotionSharedAxisX'),
                        icon: Icons.swap_horiz_rounded,
                      ),
                      TashilConnectedButtonSegment(
                        value: TashilPageTransitionType.sharedAxisZ,
                        label: loc.tr('m3MotionSharedAxisZ'),
                        icon: Icons.zoom_in_map_rounded,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TashilButton.tonal(
                    label: loc.tr('m3MotionSuiteButton'),
                    icon: Icons.animation_rounded,
                    height: 36,
                    onPressed: () => M3MotionShowcaseDialog.show(context),
                  ),
                  TashilButton.tonal(
                    label: loc.tr('m3ListsSuiteTitle'),
                    icon: Icons.format_list_bulleted_rounded,
                    height: 36,
                    onPressed: () => M3ListsShowcaseDialog.show(context),
                  ),
                  TashilButton.tonal(
                    label: loc.tr('m3LoadingIndicatorTitle'),
                    icon: Icons.refresh_rounded,
                    height: 36,
                    onPressed: () => M3LoadingShowcaseDialog.show(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiEngineSection(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.smart_toy_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      loc.tr('appSettingsAiEngineSectionTitle'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Gemini 3.8 & 2.5 Active',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TashilCard.outlined(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.tr('appSettingsAiEngineSectionDesc'),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                          Flexible(
                            child: Text(
                              loc.tr('allEnginesOperational'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TashilButton.filled(
                      icon: Icons.tune_rounded,
                      label: loc.tr('openAiEngineHubBtn'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        AiEngineHubDialog.show(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaletteCircleItem extends StatefulWidget {
  final M3ThemePalette palette;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PaletteCircleItem({
    required this.palette,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_PaletteCircleItem> createState() => _PaletteCircleItemState();
}

class _PaletteCircleItemState extends State<_PaletteCircleItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.palette.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isSelected
                    ? (isDark ? Colors.white : widget.colorScheme.onSurface)
                    : (_isHovered
                        ? widget.palette.color.withAlpha(180)
                        : Colors.transparent),
                width: widget.isSelected ? 3.0 : (_isHovered ? 2.0 : 0.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.palette.color.withAlpha(widget.isSelected ? 160 : (_isHovered ? 100 : 50)),
                  blurRadius: widget.isSelected ? 10 : (_isHovered ? 8 : 4),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: widget.isSelected
                ? const Center(
                    child: Icon(Icons.check_rounded, size: 20, color: Colors.white),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
