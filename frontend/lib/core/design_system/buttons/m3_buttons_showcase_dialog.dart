import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'tashil_button.dart';
import 'tashil_toggle_button.dart';
import 'tashil_icon_button.dart';
import 'tashil_toggle_icon_button.dart';
import 'tashil_split_button.dart';
import 'tashil_button_group.dart';
import 'tashil_fab.dart';
import 'tashil_fab_menu.dart';

/// Interactive showcase dialog displaying all 10 official Google Material Design 3
/// button types in a side-by-side grid, numbered 1 to 10 matching the official M3 reference.
class M3ButtonsShowcaseDialog extends StatefulWidget {
  const M3ButtonsShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const M3ButtonsShowcaseDialog(),
    );
  }

  @override
  State<M3ButtonsShowcaseDialog> createState() => _M3ButtonsShowcaseDialogState();
}

class _M3ButtonsShowcaseDialogState extends State<M3ButtonsShowcaseDialog> {
  // Interactive State Tracking
  bool _toggleBtn2Selected = true;
  bool _toggleIconBtn4Selected = true;
  String _selectedSegment7 = 'first';

  void _notifyAction(String message) {
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

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Dialog Header
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
                        child: Icon(Icons.touch_app_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('m3ButtonShowcaseTitle'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              loc.tr('m3ButtonShowcaseSubtitle'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 2. Interactive Buttons Canvas
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Row 1: Item 1, Item 2, Item 3, Item 4
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.spaceAround,
                          children: [
                            _buildShowcaseCard(
                              number: 1,
                              title: loc.tr('m3BtnType1'),
                              child: TashilButton(
                                icon: Icons.edit_outlined,
                                label: loc.tr('m3BtnDefaultAction'),
                                onPressed: () => _notifyAction('Button (1) Clicked'),
                              ),
                            ),
                            _buildShowcaseCard(
                              number: 2,
                              title: loc.tr('m3BtnType2'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TashilToggleButton(
                                    isSelected: !_toggleBtn2Selected,
                                    label: loc.tr('m3BtnUnselected'),
                                    onSelectedChanged: (val) =>
                                        setState(() => _toggleBtn2Selected = !val),
                                  ),
                                  const SizedBox(width: 8),
                                  TashilToggleButton(
                                    isSelected: _toggleBtn2Selected,
                                    label: loc.tr('m3BtnSelected'),
                                    onSelectedChanged: (val) =>
                                        setState(() => _toggleBtn2Selected = val),
                                  ),
                                ],
                              ),
                            ),
                            _buildShowcaseCard(
                              number: 3,
                              title: loc.tr('m3BtnType3'),
                              child: TashilIconButton.tonal(
                                icon: Icons.settings_rounded,
                                onPressed: () => _notifyAction('Icon Button (3) Clicked'),
                              ),
                            ),
                            _buildShowcaseCard(
                              number: 4,
                              title: loc.tr('m3BtnType4'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TashilToggleIconButton(
                                    isSelected: !_toggleIconBtn4Selected,
                                    icon: Icons.settings_outlined,
                                    selectedIcon: Icons.settings_rounded,
                                    onSelectedChanged: (val) =>
                                        setState(() => _toggleIconBtn4Selected = !val),
                                  ),
                                  const SizedBox(width: 8),
                                  TashilToggleIconButton(
                                    isSelected: _toggleIconBtn4Selected,
                                    icon: Icons.settings_outlined,
                                    selectedIcon: Icons.settings_rounded,
                                    selectedBackgroundColor: colorScheme.secondaryContainer,
                                    selectedIconColor: colorScheme.onSecondaryContainer,
                                    onSelectedChanged: (val) =>
                                        setState(() => _toggleIconBtn4Selected = val),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Row 2: Item 5, Item 6, Item 7
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.spaceAround,
                          children: [
                            _buildShowcaseCard(
                              number: 5,
                              title: loc.tr('m3BtnType5'),
                              child: TashilSplitButton<String>(
                                icon: Icons.edit_outlined,
                                label: loc.tr('m3BtnSplitPrimaryAction'),
                                onPressed: () => _notifyAction('Split Button Primary Clicked'),
                                onItemSelected: (val) =>
                                    _notifyAction('Split Option Selected: $val'),
                                items: [
                                  TashilSplitButtonItem(
                                    value: 'draft',
                                    label: loc.tr('m3BtnSplitOption1'),
                                    icon: Icons.save_outlined,
                                  ),
                                  TashilSplitButtonItem(
                                    value: 'export',
                                    label: loc.tr('m3BtnSplitOption2'),
                                    icon: Icons.picture_as_pdf_outlined,
                                  ),
                                  TashilSplitButtonItem(
                                    value: 'share',
                                    label: loc.tr('m3BtnSplitOption3'),
                                    icon: Icons.share_outlined,
                                  ),
                                ],
                              ),
                            ),
                            _buildShowcaseCard(
                              number: 6,
                              title: loc.tr('m3BtnType6'),
                              child: TashilStandardButtonGroup(
                                children: [
                                  TashilIconButton.tonal(
                                    icon: Icons.edit_outlined,
                                    onPressed: () => _notifyAction('Group Icon 1 Clicked'),
                                  ),
                                  TashilButton(
                                    label: loc.tr('m3BtnDefaultAction'),
                                    onPressed: () => _notifyAction('Group Button Clicked'),
                                  ),
                                  TashilIconButton.tonal(
                                    icon: Icons.edit_outlined,
                                    onPressed: () => _notifyAction('Group Icon 2 Clicked'),
                                  ),
                                ],
                              ),
                            ),
                            _buildShowcaseCard(
                              number: 7,
                              title: loc.tr('m3BtnType7'),
                              child: TashilConnectedButtonGroup<String>(
                                selectedValue: _selectedSegment7,
                                onSelectionChanged: (val) =>
                                    setState(() => _selectedSegment7 = val),
                                segments: [
                                  TashilConnectedButtonSegment(
                                    value: 'first',
                                    label: loc.tr('m3BtnFirstAction'),
                                    icon: Icons.star_rounded,
                                  ),
                                  TashilConnectedButtonSegment(
                                    value: 'second',
                                    label: loc.tr('m3BtnSecondAction'),
                                    icon: Icons.star_border_rounded,
                                  ),
                                  TashilConnectedButtonSegment(
                                    value: 'third',
                                    label: loc.tr('m3BtnThirdAction'),
                                    icon: Icons.star_border_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Row 3: Item 8, Item 9, Item 10
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.spaceAround,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            _buildShowcaseCard(
                              number: 8,
                              title: loc.tr('m3BtnType8'),
                              child: TashilFloatingActionButton(
                                icon: Icons.edit_outlined,
                                onPressed: () => _notifyAction('FAB (8) Clicked'),
                              ),
                            ),
                            _buildShowcaseCard(
                              number: 9,
                              title: loc.tr('m3BtnType9'),
                              child: TashilExtendedFloatingActionButton(
                                icon: Icons.edit_outlined,
                                label: loc.tr('m3BtnDefaultAction'),
                                onPressed: () => _notifyAction('Extended FAB (9) Clicked'),
                              ),
                            ),
                            _buildShowcaseCard(
                              number: 10,
                              title: loc.tr('m3BtnType10'),
                              child: SizedBox(
                                height: 210,
                                width: 170,
                                child: Align(
                                  alignment: AlignmentDirectional.bottomEnd,
                                  child: TashilFabMenu(
                                    items: [
                                      TashilFabMenuItem(
                                        label: loc.tr('m3BtnFirstAction'),
                                        icon: Icons.star_rounded,
                                        onPressed: () => _notifyAction('Menu 1: First Clicked'),
                                      ),
                                      TashilFabMenuItem(
                                        label: loc.tr('m3BtnSecondAction'),
                                        icon: Icons.star_rounded,
                                        onPressed: () => _notifyAction('Menu 2: Second Clicked'),
                                      ),
                                      TashilFabMenuItem(
                                        label: loc.tr('m3BtnThirdAction'),
                                        icon: Icons.star_rounded,
                                        onPressed: () => _notifyAction('Menu 3: Third Clicked'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildShowcaseCard({
    required int number,
    required String title,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          constraints: const BoxConstraints(minWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Number Badge Matching Image
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        );
      },
    );
  }
}
