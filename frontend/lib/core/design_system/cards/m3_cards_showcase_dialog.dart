import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/theme_palette_switcher.dart';
import 'tashil_card.dart';

import '../buttons/tashil_buttons.dart';
import '../dividers/tashil_dividers.dart';
import '../chips/tashil_chips.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialog_frame.dart';

/// Interactive showcase dialog displaying:
/// 1. The 3 official Google Material Design 3 card types (Elevated, Filled, Outlined).
/// 2. The 5 official M3 Elevated Card Interactive States (Hovered, Focused, Pressed, Dragged, Disabled).
class M3CardsShowcaseDialog extends StatefulWidget {
  const M3CardsShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const M3CardsShowcaseDialog(),
    );
  }

  @override
  State<M3CardsShowcaseDialog> createState() => _M3CardsShowcaseDialogState();
}

class _M3CardsShowcaseDialogState extends State<M3CardsShowcaseDialog> {
  String _selectedTab = 'outlined_states'; // Default to newly requested Outlined States

  void _notifyAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    final sampleMenuItems = [
      TashilCardMenuItem(
        value: 'edit',
        label: loc.tr('m3CardActionEdit'),
        icon: Symbols.edit_rounded,
      ),
      TashilCardMenuItem(
        value: 'share',
        label: loc.tr('m3CardActionShare'),
        icon: Symbols.share_rounded,
      ),
      TashilCardMenuItem(
        value: 'delete',
        label: loc.tr('m3CardActionDelete'),
        icon: Symbols.delete_outline_rounded,
      ),
    ];

    String dialogTitle;
    String dialogSubtitle;
    if (_selectedTab == 'outlined_states') {
      dialogTitle = loc.tr('m3OutlinedCardStatesTitle');
      dialogSubtitle = loc.tr('m3OutlinedCardStatesSubtitle');
    } else if (_selectedTab == 'elevated_states') {
      dialogTitle = loc.tr('m3ElevatedCardStatesTitle');
      dialogSubtitle = loc.tr('m3ElevatedCardStatesSubtitle');
    } else if (_selectedTab == 'types') {
      dialogTitle = loc.tr('m3CardsShowcaseTitle');
      dialogSubtitle = loc.tr('m3CardsShowcaseSubtitle');
    } else if (_selectedTab == 'text_hierarchy') {
      dialogTitle = loc.tr('m3CardTextHierarchyTitle');
      dialogSubtitle = loc.tr('m3CardTextHierarchySubtitle');
    } else {
      dialogTitle = loc.tr('m3InteractiveControlsTitle');
      dialogSubtitle = loc.tr('m3InteractiveControlsSubtitle');
    }

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return TashilDialogFrame(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 660),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Symbols.dashboard_customize_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dialogTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              dialogSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const ThemePaletteSwitcher(isCompact: true),
                      const SizedBox(width: 12),
                      IconButton.outlined(
                        icon: const Icon(Symbols.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // View Switcher Bar using TashilConnectedButtonGroup
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 0),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: TashilConnectedButtonGroup<String>(
                        height: 38,
                        selectedValue: _selectedTab,
                        onSelectionChanged: (val) => setState(() => _selectedTab = val),
                        segments: [
                          TashilConnectedButtonSegment(
                            value: 'outlined_states',
                            label: loc.tr('m3OutlinedCardStatesTab'),
                            icon: Symbols.crop_square_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'elevated_states',
                            label: loc.tr('m3CardStatesTab'),
                            icon: Symbols.layers_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'types',
                            label: loc.tr('m3CardsTypesTab'),
                            icon: Symbols.view_agenda_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'text_hierarchy',
                            label: loc.tr('m3CardTextHierarchyTab'),
                            icon: Symbols.text_fields_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'interactive_controls',
                            label: loc.tr('m3InteractiveControlsTab'),
                            icon: Symbols.touch_app_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content View
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: _selectedTab == 'outlined_states'
                          ? _buildOutlinedStatesShowcase(context, loc, theme, colorScheme)
                          : (_selectedTab == 'elevated_states'
                              ? _buildElevatedStatesShowcase(context, loc, theme, colorScheme)
                              : (_selectedTab == 'types'
                                  ? _buildCardTypesShowcase(context, loc, theme, colorScheme, sampleMenuItems)
                                  : (_selectedTab == 'text_hierarchy'
                                      ? _buildTextHierarchyShowcase(context, loc, theme, colorScheme)
                                      : _buildInteractiveControlsShowcase(context, loc, theme, colorScheme)))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Section 1: The 5 Google M3 Outlined Card Interactive States (Matching Newly Uploaded Images)
  Widget _buildOutlinedStatesShowcase(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        // 1. Hovered
        _buildStateShowcaseItem(
          context,
          number: 1,
          title: loc.tr('m3CardStateHovered'),
          subtitle: loc.tr('m3CardStateOutlinedHoveredDesc'),
          card: _buildSimulatedOutlinedCard(
            context,
            isHovered: true,
            label: 'Hovered',
          ),
        ),

        // 2. Focused
        _buildStateShowcaseItem(
          context,
          number: 2,
          title: loc.tr('m3CardStateFocused'),
          subtitle: loc.tr('m3CardStateOutlinedFocusedDesc'),
          card: _buildSimulatedOutlinedCard(
            context,
            isFocused: true,
            label: 'Focused',
          ),
        ),

        // 3. Pressed
        _buildStateShowcaseItem(
          context,
          number: 3,
          title: loc.tr('m3CardStatePressed'),
          subtitle: loc.tr('m3CardStateOutlinedPressedDesc'),
          card: _buildSimulatedOutlinedCard(
            context,
            label: 'Pressed',
          ),
        ),

        // 4. Dragged
        _buildStateShowcaseItem(
          context,
          number: 4,
          title: loc.tr('m3CardStateDragged'),
          subtitle: loc.tr('m3CardStateOutlinedDraggedDesc'),
          card: _buildSimulatedOutlinedCard(
            context,
            isDragged: true,
            label: 'Dragged',
          ),
        ),

        // 5. Disabled
        _buildStateShowcaseItem(
          context,
          number: 5,
          title: loc.tr('m3CardStateDisabled'),
          subtitle: loc.tr('m3CardStateOutlinedDisabledDesc'),
          card: _buildSimulatedOutlinedCard(
            context,
            disabled: true,
            label: 'Disabled',
          ),
        ),
      ],
    );
  }

  /// Simulated M3 Outlined Card container illustrating exact state parameters
  Widget _buildSimulatedOutlinedCard(
    BuildContext context, {
    required String label,
    bool? isHovered,
    bool? isFocused,
    bool isDragged = false,
    bool disabled = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget cardBody = Container(
      width: 175,
      height: 110,
      padding: const EdgeInsets.all(14),
      alignment: AlignmentDirectional.bottomStart,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600,
          color: disabled
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.onSurface),
      ),
    );

    return TashilCard.outlined(
      width: 175,
      height: 110,
      enabled: !disabled,
      isHovered: isHovered,
      isFocused: isFocused,
      isDragged: isDragged,
      onTap: disabled ? null : () => _notifyAction(context, '$label outlined state tapped'),
      child: cardBody,
    );
  }

  /// Section 2: The 5 Google M3 Elevated Card Interactive States
  Widget _buildElevatedStatesShowcase(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        // 1. Hovered
        _buildStateShowcaseItem(
          context,
          number: 1,
          title: loc.tr('m3CardStateHovered'),
          subtitle: loc.tr('m3CardStateHoveredDesc'),
          card: _buildSimulatedElevatedCard(
            context,
            isHovered: true,
            label: 'Hovered',
          ),
        ),

        // 2. Focused
        _buildStateShowcaseItem(
          context,
          number: 2,
          title: loc.tr('m3CardStateFocused'),
          subtitle: loc.tr('m3CardStateFocusedDesc'),
          card: _buildSimulatedElevatedCard(
            context,
            isFocused: true,
            label: 'Focused',
          ),
        ),

        // 3. Pressed
        _buildStateShowcaseItem(
          context,
          number: 3,
          title: loc.tr('m3CardStatePressed'),
          subtitle: loc.tr('m3CardStatePressedDesc'),
          card: _buildSimulatedElevatedCard(
            context,
            label: 'Pressed',
          ),
        ),

        // 4. Dragged
        _buildStateShowcaseItem(
          context,
          number: 4,
          title: loc.tr('m3CardStateDragged'),
          subtitle: loc.tr('m3CardStateDraggedDesc'),
          card: _buildSimulatedElevatedCard(
            context,
            isDragged: true,
            label: 'Dragged',
          ),
        ),

        // 5. Disabled
        _buildStateShowcaseItem(
          context,
          number: 5,
          title: loc.tr('m3CardStateDisabled'),
          subtitle: loc.tr('m3CardStateDisabledDesc'),
          card: _buildSimulatedElevatedCard(
            context,
            disabled: true,
            label: 'Disabled',
          ),
        ),
      ],
    );
  }

  /// Simulated M3 Elevated Card container illustrating exact state parameters
  Widget _buildSimulatedElevatedCard(
    BuildContext context, {
    required String label,
    bool? isHovered,
    bool? isFocused,
    bool isDragged = false,
    bool disabled = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget cardBody = Container(
      width: 175,
      height: 110,
      padding: const EdgeInsets.all(14),
      alignment: AlignmentDirectional.bottomStart,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600,
          color: disabled
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.onSurface),
      ),
    );

    return TashilCard.elevated(
      width: 175,
      height: 110,
      enabled: !disabled,
      isHovered: isHovered,
      isFocused: isFocused,
      isDragged: isDragged,
      onTap: disabled ? null : () => _notifyAction(context, '$label state tapped'),
      child: cardBody,
    );
  }

  /// Section 2: The 3 M3 Card Types
  Widget _buildCardTypesShowcase(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    List<TashilCardMenuItem> sampleMenuItems,
  ) {
    return Wrap(
      spacing: 24,
      runSpacing: 32,
      alignment: WrapAlignment.center,
      children: [
        // 1. Elevated Card
        _buildCardShowcaseItem(
          context,
          number: 1,
          title: loc.tr('m3CardTypeElevated'),
          card: TashilCard.elevated(
            width: 240,
            height: 150,
            menuItems: sampleMenuItems,
            onMenuItemSelected: (val) => _notifyAction(context, 'Elevated Card: $val'),
            onTap: () => _notifyAction(context, 'Elevated Card clicked'),
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: AlignmentDirectional.bottomStart,
              child: Text(
                'Elevated',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),

        // 2. Filled Card
        _buildCardShowcaseItem(
          context,
          number: 2,
          title: loc.tr('m3CardTypeFilled'),
          card: TashilCard.filled(
            width: 240,
            height: 150,
            menuItems: sampleMenuItems,
            onMenuItemSelected: (val) => _notifyAction(context, 'Filled Card: $val'),
            onTap: () => _notifyAction(context, 'Filled Card clicked'),
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: AlignmentDirectional.bottomStart,
              child: Text(
                'Filled',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),

        // 3. Outlined Card
        _buildCardShowcaseItem(
          context,
          number: 3,
          title: loc.tr('m3CardTypeOutlined'),
          card: TashilCard.outlined(
            width: 240,
            height: 150,
            menuItems: sampleMenuItems,
            onMenuItemSelected: (val) => _notifyAction(context, 'Outlined Card: $val'),
            onTap: () => _notifyAction(context, 'Outlined Card clicked'),
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: AlignmentDirectional.bottomStart,
              child: Text(
                'Outlined',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateShowcaseItem(
    BuildContext context, {
    required int number,
    required String title,
    required String subtitle,
    required Widget card,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Number badge on top (as in Google M3 diagram)
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        card,
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
            color: colorScheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCardShowcaseItem(
    BuildContext context, {
    required int number,
    required String title,
    required Widget card,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        card,
        const SizedBox(height: 18),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold,
            color: colorScheme.onSurface),
        ),
      ],
    );
  }

  /// Section 4: Google Material Design 3 Card Text Hierarchy Showcase
  ///
  /// Demonstrates the 3 canonical text elements according to official M3 guidelines:
  /// 1. Headline (subject of the card)
  /// 2. Subhead (smaller text element: byline, author/date, tagged location)
  /// 3. Supporting text (body content: summary, description)
  Widget _buildTextHierarchyShowcase(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Information Banner with M3 Specs
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Symbols.format_size_rounded, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('m3CardTextHierarchyTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('m3CardTextHierarchySubtitle'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Showcase Cards in Wrap
        Wrap(
          spacing: 20,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            // Card 1: Cortado iced (Headline + Supporting text + Full-width Divider)
            _buildTextHierarchyCardContainer(
              context,
              number: 1,
              title: AppLocalizations.trStatic('uiCopy038'),
              description: '${loc.tr('m3HeadlineLabel')} + ${loc.tr('m3SupportingTextLabel')}',
              card: TashilCard.outlined(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.trStatic('uiCopy038'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter my new flame: the iced cortado espresso with an equal amount of steamed milk when I want a caffeine pick-me-up or acidity of pure espresso.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const TashilDivider.cardAction(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Expand',
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.primary,
                          fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card 2: Artia (Headline + Subhead + Rating + Supporting text + Inset Divider)
            _buildTextHierarchyCardContainer(
              context,
              number: 2,
              title: 'Artia',
              description: '${loc.tr('m3HeadlineLabel')} + ${loc.tr('m3SubheadLabel')} + ${loc.tr('m3SupportingTextLabel')}',
              card: TashilCard.outlined(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artia',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$ • Woodworking, Jewelry',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(Symbols.star_rounded, color: colorScheme.tertiary, size: 16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Because of its versatility and ease of working, pine is a very popular choice for fine furniture and crafted artifacts.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TashilDivider.middleInset(
                      inset: 4.0,
                      color: colorScheme.outlineVariant,
                      height: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Symbols.chat_bubble_outline_rounded, size: 15, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                '74 comments',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Icon(Symbols.share_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card 3: Clay pot fair (Subhead byline first + Headline + Supporting text)
            _buildTextHierarchyCardContainer(
              context,
              number: 3,
              title: AppLocalizations.trStatic('uiCopy033'),
              description: 'Subhead first (Byline) + Headline + Supporting text',
              card: TashilCard.outlined(
                width: 270,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TashilCardText(
                        subheadFirst: true,
                        subheadLeading: CircleAvatar(
                          radius: 14,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            'DM',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer),
                          ),
                        ),
                        subheadText: AppLocalizations.trStatic('uiCopy039'),
                        trailing: Icon(Symbols.star_outline_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                        headlineText: AppLocalizations.trStatic('uiCopy033'),
                        supportingText: 'I think it\'s time for us to finally try that new noodle shop downtown that doesn\'t use menus. Anyone else?',
                        spacing: 6.0,
                      ),
                    ),
                    const TashilDivider.cardAction(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Symbols.thumb_up_alt_rounded, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Like',
                            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(Symbols.reply_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card 4: Tashil Real Estate Card (Headline, Subhead, Supporting text in PropTech)
            _buildTextHierarchyCardContainer(
              context,
              number: 4,
              title: AppLocalizations.trStatic('uiCopy078'),
              description: 'TashilCardText (PropTech Real Estate Standard)',
              card: TashilCard.outlined(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price & Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.trStatic('uiCopy019'),
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold,
                                  color: colorScheme.primary),
                              ),
                              Row(
                                children: [
                                  Icon(Symbols.star_rounded, color: colorScheme.tertiary, size: 15),
                                  const SizedBox(width: 2),
                                  Text('4.9', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // TashilCardText Component
                          TashilCardText(
                            headlineText: AppLocalizations.trStatic('uiCopy229'),
                            subheadText: AppLocalizations.trStatic('uiCopy124'),
                            subheadLeading: Icon(Symbols.location_on_rounded, size: 14, color: colorScheme.secondary),
                            supportingText: AppLocalizations.trStatic('uiCopy236'),
                            headlineMaxLines: 1,
                            supportingTextMaxLines: 2,
                            spacing: 4.0,
                          ),
                        ],
                      ),
                    ),

                    // Inset Divider
                    TashilDivider.middleInset(
                      inset: 4.0,
                      color: colorScheme.outlineVariant,
                      height: 1,
                    ),

                    // Specs Icons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniSpec(Symbols.bed_rounded, AppLocalizations.trStatic('uiCopy020')),
                          _buildMiniSpec(Symbols.bathtub_rounded, AppLocalizations.trStatic('uiCopy011')),
                          _buildMiniSpec(Symbols.square_foot_rounded, AppLocalizations.trStatic('uiCopy010')),
                        ],
                      ),
                    ),

                    // Full-width Divider
                    const TashilDivider.cardAction(),

                    // Action buttons with TashilConnectedButtonGroup
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: TashilConnectedButtonGroup<String>(
                        height: 32,
                        isFullWidth: true,
                        selectedValue: 'booking',
                        showCheckmark: false,
                        segments: [
                          TashilConnectedButtonSegment(
                            value: 'booking',
                            label: AppLocalizations.trStatic('uiCopy192'),
                            icon: Symbols.calendar_month_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'details',
                            label: AppLocalizations.trStatic('uiCopy172'),
                            icon: Symbols.visibility_rounded,
                          ),
                        ],
                        onSelectionChanged: (val) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniSpec(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildTextHierarchyCardContainer(
    BuildContext context, {
    required int number,
    required String title,
    required String description,
    required Widget card,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        card,
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#$number',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Section 5: Google Material Design 3 Card Interactive Controls Showcase
  ///
  /// Demonstrates the 4 canonical interactive controls per official M3 guidelines:
  /// 1. Buttons (Primary, Tonal, Outlined)
  /// 2. Icon buttons (Save, Heart, Call, Message)
  /// 3. Selection controls (Chips, checkboxes, sliders)
  /// 4. Linked text (clickable hyperlink inside supporting text)
  Widget _buildInteractiveControlsShowcase(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Information Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Symbols.touch_app_rounded, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('m3InteractiveControlsTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.tr('m3InteractiveControlsSubtitle'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 4 Key Control Badges
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildControlFeatureChip(context, Symbols.smart_button_rounded, loc.tr('m3ButtonsCardLabel'), loc.tr('m3ButtonsCardDesc')),
            _buildControlFeatureChip(context, Symbols.favorite_border_rounded, loc.tr('m3IconButtonsCardLabel'), loc.tr('m3IconButtonsCardDesc')),
            _buildControlFeatureChip(context, Symbols.check_box_rounded, loc.tr('m3SelectionControlsCardLabel'), loc.tr('m3SelectionControlsCardDesc')),
            _buildControlFeatureChip(context, Symbols.link_rounded, loc.tr('m3LinkedTextCardLabel'), loc.tr('m3LinkedTextCardDesc')),
          ],
        ),
        const SizedBox(height: 24),

        // Showcase Cards in Wrap
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            // Card 1: Official M3 Card from User Image
            _buildTextHierarchyCardContainer(
              context,
              number: 1,
              title: AppLocalizations.trStatic('uiCopy063'),
              description: 'Buttons + Icon buttons + Linked text',
              card: TashilCard.outlined(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Header with Avatar & Outlined Buttons
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(Symbols.person_rounded, size: 20, color: colorScheme.onPrimaryContainer),
                          ),
                          const Spacer(),
                          TashilButton.outlined(
                            label: 'Preferido',
                            icon: Symbols.favorite_border_rounded,
                            height: 32,
                            onPressed: () => _notifyAction(context, 'Preferido tapped'),
                          ),
                          const SizedBox(width: 8),
                          TashilButton.outlined(
                            label: 'Ayudar',
                            icon: Symbols.calendar_today_rounded,
                            height: 32,
                            onPressed: () => _notifyAction(context, 'Ayudar tapped'),
                          ),
                        ],
                      ),
                    ),

                    // Media Image with Peek
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primaryContainer, colorScheme.secondaryContainer],
                            ),
                          ),
                          child: Center(
                            child: Icon(Symbols.nature_people_rounded, size: 48, color: colorScheme.primary),
                          ),
                        ),
                      ),
                    ),

                    // Supporting text with Linked text
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: TashilCardText(
                        supportingText: AppLocalizations.trStatic('uiCopy032'),
                        linkedText: AppLocalizations.trStatic('uiCopy083'),
                        onLinkedTextTap: () => _notifyAction(context, 'Link clicked: Visite el enlace aquí'),
                        supportingTextMaxLines: 3,
                      ),
                    ),

                    const TashilDivider.cardAction(),

                    // Action Footer: Tonal Buttons on start side + Icon buttons on end side
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          TashilButton.tonal(
                            label: 'Escucha',
                            height: 34,
                            onPressed: () => _notifyAction(context, 'Escucha tapped'),
                          ),
                          const SizedBox(width: 6),
                          TashilButton.tonal(
                            label: 'Ahorrar',
                            height: 34,
                            onPressed: () => _notifyAction(context, 'Ahorrar tapped'),
                          ),
                          const Spacer(),
                          TashilIconButton.outlined(
                            icon: Symbols.phone_rounded,
                            size: 34,
                            iconSize: 16,
                            tooltip: AppLocalizations.trStatic('uiCopy071'),
                            onPressed: () => _notifyAction(context, 'Call icon tapped'),
                          ),
                          const SizedBox(width: 6),
                          TashilIconButton.outlined(
                            icon: Symbols.chat_bubble_outline_rounded,
                            size: 34,
                            iconSize: 16,
                            tooltip: 'Chat',
                            onPressed: () => _notifyAction(context, 'Message icon tapped'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card 2: Tashil PropTech Real Estate Card (All 4 Controls Integrated)
            _buildTextHierarchyCardContainer(
              context,
              number: 2,
              title: AppLocalizations.trStatic('uiCopy077'),
              description: 'Buttons + Icon buttons + Selection Chips + Linked text',
              card: TashilCard.outlined(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price & Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.trStatic('uiCopy019'),
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                                  color: colorScheme.primary),
                              ),
                              Row(
                                children: [
                                  Icon(Symbols.star_rounded, color: colorScheme.tertiary, size: 16),
                                  const SizedBox(width: 2),
                                  Text('4.9', style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // TashilCardText with Headline, Subhead, Supporting text, and Linked text
                          TashilCardText(
                            headlineText: AppLocalizations.trStatic('uiCopy231'),
                            subheadText: AppLocalizations.trStatic('uiCopy124'),
                            subheadLeading: Icon(Symbols.location_on_rounded, size: 14, color: colorScheme.secondary),
                            supportingText: AppLocalizations.trStatic('uiCopy235'),
                            linkedText: loc.tr('cardReadMoreLink'),
                            onLinkedTextTap: () => _notifyAction(context, 'Linked text tapped: ${loc.tr('cardReadMoreLink')}'),
                            headlineMaxLines: 1,
                            supportingTextMaxLines: 2,
                            spacing: 4.0,
                          ),
                          const SizedBox(height: 10),

                          // Selection controls: Amenity Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              TashilAssistChip(
                                label: AppLocalizations.trStatic('uiCopy300'),
                                icon: Symbols.weekend_rounded,
                                height: 26,
                                onPressed: () => _notifyAction(context, 'Furnished chip'),
                              ),
                              TashilAssistChip(
                                label: AppLocalizations.trStatic('uiCopy173'),
                                icon: Symbols.ac_unit_rounded,
                                height: 26,
                                onPressed: () => _notifyAction(context, 'AC chip'),
                              ),
                              TashilAssistChip(
                                label: AppLocalizations.trStatic('uiCopy293'),
                                icon: Symbols.elevator_rounded,
                                height: 26,
                                onPressed: () => _notifyAction(context, 'Elevator chip'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const TashilDivider.cardAction(),

                    // Action Footer: Buttons + Icon Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TashilConnectedButtonGroup<String>(
                              height: 34,
                              isFullWidth: true,
                              selectedValue: 'booking',
                              showCheckmark: false,
                              segments: [
                                TashilConnectedButtonSegment(
                                  value: 'booking',
                                  label: loc.tr('bookViewingShort'),
                                  icon: Symbols.calendar_month_rounded,
                                ),
                                TashilConnectedButtonSegment(
                                  value: 'details',
                                  label: loc.tr('detailsShort'),
                                  icon: Symbols.visibility_rounded,
                                ),
                              ],
                              onSelectionChanged: (val) => _notifyAction(context, 'Action: $val'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TashilIconButton.outlined(
                            icon: Symbols.phone_rounded,
                            size: 34,
                            iconSize: 16,
                            tooltip: loc.tr('callAgency'),
                            onPressed: () => _notifyAction(context, loc.tr('callAgency')),
                          ),
                          const SizedBox(width: 6),
                          TashilIconButton.outlined(
                            icon: Symbols.chat_bubble_outline_rounded,
                            size: 34,
                            iconSize: 16,
                            tooltip: loc.tr('chatAgency'),
                            onPressed: () => _notifyAction(context, loc.tr('chatAgency')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlFeatureChip(BuildContext context, IconData icon, String title, String desc) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold,
                color: colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


