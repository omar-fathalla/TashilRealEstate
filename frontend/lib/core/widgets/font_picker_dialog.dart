import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/theme/font_theme_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';

/// Official Material Design 3 Font Picker Dialog for Tashil Real Estate.
///
/// Provides a dedicated, beautifully categorized selection experience for all
/// 12 certified Google Fonts, replacing cluttered inline grids with an interactive,
/// live-preview modal dialog conforming to M3 Expressive guidelines.
class FontPickerDialog extends StatefulWidget {
  const FontPickerDialog({super.key});

  /// Displays the font picker dialog centered on desktop/tablet or as a bottom sheet on mobile.
  static Future<void> show(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const FontPickerDialog(),
      );
    }

    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: FontPickerDialog(),
      ),
    );
  }

  @override
  State<FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<FontPickerDialog> {
  FontCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;
    final currentLang = loc.locale.languageCode;

    final dialogContent = Container(
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.90 : 660,
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
          // 1. M3 Header with Google Icon & Shaded Close Button
          _buildHeader(context, loc, colorScheme),

          // 2. Category Filter Bar (TashilConnectedButtonGroup)
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              16,
              isMobile ? 16 : 24,
              8,
            ),
            child: _buildCategoryFilter(loc, colorScheme, isMobile),
          ),

          // 3. Scrollable List of Font Cards with Live Previews
          Flexible(
            child: ValueListenableBuilder<AppFontTheme>(
              valueListenable: FontThemeController.instance.currentFont,
              builder: (context, activeFont, _) {
                final filteredFonts = _selectedCategory == null
                    ? AppFontTheme.values
                    : AppFontTheme.values
                        .where((f) => f.category == _selectedCategory)
                        .toList();

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 12,
                  ),
                  itemCount: filteredFonts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final font = filteredFonts[index];
                    final isSelected = font == activeFont;
                    return _buildFontCard(
                      context,
                      font,
                      isSelected,
                      currentLang,
                      loc,
                      colorScheme,
                    );
                  },
                );
              },
            ),
          ),

          // 4. Pinned Action Footer
          _buildFooter(context, loc, colorScheme, isMobile),
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
              Icons.format_size_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.tr('fontSelectionTitle'),
                  style: TextStyle(
                    fontSize: 16,
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
          TashilIconButton.close(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(AppLocalizations loc, ColorScheme colorScheme, bool isMobile) {
    return TashilConnectedButtonGroup<FontCategory?>(
      height: 42,
      isFullWidth: true,
      selectedValue: _selectedCategory,
      onSelectionChanged: (cat) {
        setState(() {
          _selectedCategory = cat;
        });
      },
      segments: [
        TashilConnectedButtonSegment(
          value: null,
          label: loc.tr('fontCategoryAll'),
          icon: Icons.apps_rounded,
        ),
        TashilConnectedButtonSegment(
          value: FontCategory.modern,
          label: loc.tr('fontCategoryModern'),
          icon: Icons.auto_awesome_rounded,
        ),
        TashilConnectedButtonSegment(
          value: FontCategory.headlines,
          label: loc.tr('fontCategoryHeadlines'),
          icon: Icons.title_rounded,
        ),
        TashilConnectedButtonSegment(
          value: FontCategory.classic,
          label: loc.tr('fontCategoryClassic'),
          icon: Icons.menu_book_rounded,
        ),
      ],
    );
  }

  Widget _buildFontCard(
    BuildContext context,
    AppFontTheme font,
    bool isSelected,
    String currentLang,
    AppLocalizations loc,
    ColorScheme colorScheme,
  ) {
    String categoryName;
    switch (font.category) {
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FontThemeController.instance.setFont(font);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withAlpha(45)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withAlpha(100),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Font Name, Category Pill, Radio/Check Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.text_fields_rounded,
                      size: 16,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            font.getLocalizedName(currentLang),
                            style: font.getTextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Live Font Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(60),
                  ),
                ),
                child: Text(
                  loc.tr('fontPreviewSample'),
                  style: font.getTextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                loc.tr(font.descriptionKey),
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
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations loc,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<AppFontTheme>(
            valueListenable: FontThemeController.instance.currentFont,
            builder: (context, activeFont, _) {
              return Text(
                '${loc.tr('currentActiveFont')}: ${activeFont.getLocalizedName(loc.locale.languageCode).split(' ').first}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          TashilButton(
            label: loc.tr('applyFont'),
            icon: Icons.check_rounded,
            height: 38,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
