import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/theme_palette_switcher.dart';
import 'tashil_card.dart';

import '../buttons/tashil_buttons.dart';
import '../dividers/tashil_dividers.dart';
import '../chips/tashil_chips.dart';

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
        icon: Icons.edit_outlined,
      ),
      TashilCardMenuItem(
        value: 'share',
        label: loc.tr('m3CardActionShare'),
        icon: Icons.share_outlined,
      ),
      TashilCardMenuItem(
        value: 'delete',
        label: loc.tr('m3CardActionDelete'),
        icon: Icons.delete_outline_rounded,
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
        return Dialog(
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
                        child: Icon(Icons.dashboard_customize_rounded, color: colorScheme.primary, size: 22),
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
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // View Switcher Bar using TashilConnectedButtonGroup
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                            icon: Icons.crop_square_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'elevated_states',
                            label: loc.tr('m3CardStatesTab'),
                            icon: Icons.layers_outlined,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'types',
                            label: loc.tr('m3CardsTypesTab'),
                            icon: Icons.view_agenda_outlined,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'text_hierarchy',
                            label: loc.tr('m3CardTextHierarchyTab'),
                            icon: Icons.text_fields_rounded,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'interactive_controls',
                            label: loc.tr('m3InteractiveControlsTab'),
                            icon: Icons.touch_app_rounded,
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
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: disabled
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.onSurface,
        ),
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
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: disabled
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.onSurface,
        ),
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
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        card,
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
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
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
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
                child: Icon(Icons.format_size_rounded, color: colorScheme.primary, size: 24),
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
              title: 'Cortado iced',
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
                            'Cortado iced',
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
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
                              (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
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
                              Icon(Icons.chat_bubble_outline_rounded, size: 15, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(
                                '74 comments',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.share_outlined, size: 16, color: colorScheme.onSurfaceVariant),
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
              title: 'Clay pot fair on Saturday?',
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
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        subheadText: 'Daniel Maas • Yesterday',
                        trailing: Icon(Icons.star_outline_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                        headlineText: 'Clay pot fair on Saturday?',
                        supportingText: 'I think it\'s time for us to finally try that new noodle shop downtown that doesn\'t use menus. Anyone else?',
                        spacing: 6.0,
                      ),
                    ),
                    const TashilDivider.cardAction(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_alt_outlined, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Like',
                            style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(Icons.reply_rounded, size: 18, color: colorScheme.onSurfaceVariant),
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
              title: 'Tashil Property Card',
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
                                '28,000 ج.م / شهر',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                  const SizedBox(width: 2),
                                  Text('4.9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // TashilCardText Component
                          TashilCardText(
                            headlineText: 'شقة فاخرة بإطلالة على التسعين',
                            subheadText: 'التجمع الخامس، القاهرة الجديدة',
                            subheadLeading: Icon(Icons.location_on_outlined, size: 14, color: colorScheme.secondary),
                            supportingText: 'شقة مودرن بتشطيب ألترا سوبر لوكس، مفروشة بالكامل وجاهزة للسكن الفوري قريبة من الخدمات.',
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
                          _buildMiniSpec(Icons.bed_outlined, '3 غرف'),
                          _buildMiniSpec(Icons.bathtub_outlined, '2 حمام'),
                          _buildMiniSpec(Icons.square_foot_outlined, '185 م²'),
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
                        segments: const [
                          TashilConnectedButtonSegment(
                            value: 'booking',
                            label: 'حجز',
                            icon: Icons.calendar_month_outlined,
                          ),
                          TashilConnectedButtonSegment(
                            value: 'details',
                            label: 'تفاصيل',
                            icon: Icons.visibility_outlined,
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
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey[700])),
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
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
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
                child: Icon(Icons.touch_app_rounded, color: colorScheme.primary, size: 24),
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
            _buildControlFeatureChip(context, Icons.smart_button_rounded, loc.tr('m3ButtonsCardLabel'), loc.tr('m3ButtonsCardDesc')),
            _buildControlFeatureChip(context, Icons.favorite_border_rounded, loc.tr('m3IconButtonsCardLabel'), loc.tr('m3IconButtonsCardDesc')),
            _buildControlFeatureChip(context, Icons.check_box_outlined, loc.tr('m3SelectionControlsCardLabel'), loc.tr('m3SelectionControlsCardDesc')),
            _buildControlFeatureChip(context, Icons.link_rounded, loc.tr('m3LinkedTextCardLabel'), loc.tr('m3LinkedTextCardDesc')),
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
              title: 'M3 Canonical Reference',
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
                            child: Icon(Icons.person, size: 20, color: colorScheme.onPrimaryContainer),
                          ),
                          const Spacer(),
                          TashilButton.outlined(
                            label: 'Preferido',
                            icon: Icons.favorite_border,
                            height: 32,
                            onPressed: () => _notifyAction(context, 'Preferido tapped'),
                          ),
                          const SizedBox(width: 8),
                          TashilButton.outlined(
                            label: 'Ayudar',
                            icon: Icons.calendar_today_outlined,
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
                            child: Icon(Icons.nature_people_rounded, size: 48, color: colorScheme.primary),
                          ),
                        ),
                      ),
                    ),

                    // Supporting text with Linked text
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: TashilCardText(
                        supportingText: 'Caminante, son tus huellas el camino y nada más; se hace camino al andar.',
                        linkedText: 'Visite el enlace aquí.',
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
                            icon: Icons.phone_outlined,
                            size: 34,
                            iconSize: 16,
                            tooltip: 'Phone Call',
                            onPressed: () => _notifyAction(context, 'Call icon tapped'),
                          ),
                          const SizedBox(width: 6),
                          TashilIconButton.outlined(
                            icon: Icons.chat_bubble_outline_rounded,
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
              title: 'Tashil PropTech Standard',
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
                                '28,000 ج.م / شهر',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 2),
                                  Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // TashilCardText with Headline, Subhead, Supporting text, and Linked text
                          TashilCardText(
                            headlineText: 'شقة فاخرة بشارع التسعين',
                            subheadText: 'التجمع الخامس، القاهرة الجديدة',
                            subheadLeading: Icon(Icons.location_on_outlined, size: 14, color: colorScheme.secondary),
                            supportingText: 'شقة مودرن بتشطيب ألترا سوبر لوكس مفروشة بالكامل.',
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
                                label: 'مفروش',
                                icon: Icons.weekend_outlined,
                                height: 26,
                                onPressed: () => _notifyAction(context, 'Furnished chip'),
                              ),
                              TashilAssistChip(
                                label: 'تكييف',
                                icon: Icons.ac_unit_outlined,
                                height: 26,
                                onPressed: () => _notifyAction(context, 'AC chip'),
                              ),
                              TashilAssistChip(
                                label: 'مصعد',
                                icon: Icons.elevator_outlined,
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
                                  icon: Icons.calendar_month_outlined,
                                ),
                                TashilConnectedButtonSegment(
                                  value: 'details',
                                  label: loc.tr('detailsShort'),
                                  icon: Icons.visibility_outlined,
                                ),
                              ],
                              onSelectionChanged: (val) => _notifyAction(context, 'Action: $val'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TashilIconButton.outlined(
                            icon: Icons.phone_outlined,
                            size: 34,
                            iconSize: 16,
                            tooltip: loc.tr('callAgency'),
                            onPressed: () => _notifyAction(context, loc.tr('callAgency')),
                          ),
                          const SizedBox(width: 6),
                          TashilIconButton.outlined(
                            icon: Icons.chat_bubble_outline_rounded,
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
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


