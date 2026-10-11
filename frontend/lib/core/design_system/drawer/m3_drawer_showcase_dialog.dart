import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'tashil_navigation_drawer.dart';

/// Interactive Showcase and Verification Dialog for Google Material Design 3 Navigation Drawer.
///
/// Demonstrates:
/// 1. The 4 official M3 state layers: Enabled, Hovered, Focused, Pressed.
/// 2. Stadium Pill shape (28dp radius) and 56dp height.
/// 3. Collapsed Rail mode (76dp) vs Expanded mode (270dp).
/// 4. M3 numeric badges and section headers.
class M3DrawerShowcaseDialog extends StatefulWidget {
  const M3DrawerShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const M3DrawerShowcaseDialog(),
    );
  }

  @override
  State<M3DrawerShowcaseDialog> createState() => _M3DrawerShowcaseDialogState();
}

class _M3DrawerShowcaseDialogState extends State<M3DrawerShowcaseDialog> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Icon(
                      Icons.menu_open_rounded,
                      color: colorScheme.onSecondaryContainer,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('m3DrawerShowcase'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          loc.tr('m3DrawerSubtitle'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Collapse / Expand toggle button in showcase
                  TashilButton.tonal(
                    icon: _isCollapsed ? Icons.open_in_full_rounded : Icons.close_fullscreen_rounded,
                    label: _isCollapsed ? loc.tr('expandedMode') : loc.tr('collapsedMode'),
                    onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  ),
                  const SizedBox(width: 8.0),
                  TashilIconButton.standard(
                    icon: Icons.close_rounded,
                    size: 38.0,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const TashilDivider.fullWidth(),
              const SizedBox(height: 16.0),

              // 2. Interactive Split Area: Left/Start = Live Drawer Preview; Right/End = Specifications & State Layers
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. Live Drawer Preview
                    Container(
                      width: _isCollapsed ? 84.0 : 270.0,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: TashilNavigationDrawer.standard(
                        isCollapsed: _isCollapsed,
                        expandedWidth: 270.0,
                        collapsedWidth: 84.0,
                        header: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isCollapsed ? 8.0 : 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: _isCollapsed
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.spaceBetween,
                            children: [
                              if (!_isCollapsed)
                                Text(
                                  loc.tr('menu'),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              TashilIconButton.standard(
                                icon: _isCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                                size: 34.0,
                                iconSize: 18.0,
                                onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                              ),
                            ],
                          ),
                        ),
                        destinations: [
                          TashilDrawerDestination(
                            icon: Icons.dashboard_outlined,
                            selectedIcon: Icons.dashboard_rounded,
                            label: loc.tr('portfolioOverview'),
                            isSelected: _selectedIndex == 0,
                            isCollapsed: _isCollapsed,
                            onTap: () => setState(() => _selectedIndex = 0),
                          ),
                          TashilDrawerDestination(
                            icon: Icons.apartment_outlined,
                            selectedIcon: Icons.apartment_rounded,
                            label: loc.tr('myProperties'),
                            badgeCount: '5',
                            isSelected: _selectedIndex == 1,
                            isCollapsed: _isCollapsed,
                            onTap: () => setState(() => _selectedIndex = 1),
                          ),
                          TashilDrawerDestination(
                            icon: Icons.account_balance_wallet_outlined,
                            selectedIcon: Icons.account_balance_wallet_rounded,
                            label: loc.tr('financialsAndPayouts'),
                            isSelected: _selectedIndex == 2,
                            isCollapsed: _isCollapsed,
                            onTap: () => setState(() => _selectedIndex = 2),
                          ),
                          TashilDrawerDestination(
                            icon: Icons.build_outlined,
                            selectedIcon: Icons.build_rounded,
                            label: loc.tr('maintenanceTickets'),
                            badgeCount: '1',
                            isSelected: _selectedIndex == 3,
                            isCollapsed: _isCollapsed,
                            onTap: () => setState(() => _selectedIndex = 3),
                          ),
                          TashilDrawerSectionHeader(
                            title: loc.tr('settings'),
                            isCollapsed: _isCollapsed,
                          ),
                          TashilDrawerDestination(
                            icon: Icons.tune_rounded,
                            label: loc.tr('settings'),
                            isSelected: _selectedIndex == 4,
                            isCollapsed: _isCollapsed,
                            onTap: () => setState(() => _selectedIndex = 4),
                          ),
                        ],
                        footer: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TashilDivider.middleInset(height: 16.0),
                            TashilDrawerProfileTile(
                              initials: 'AF',
                              displayName: loc.tr('ownerProfile'),
                              roleSubtitle: loc.tr('ownerRoleTitle'),
                              isCollapsed: _isCollapsed,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),

                    // B. Specifications & 4 State Layers Cards
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Dimensions Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.straighten_rounded, size: 20.0, color: colorScheme.primary),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Text(
                                      loc.tr('navDrawerSpecsInfo'),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),

                            // 2. Interactive State Layers
                            Text(
                              'Material Design 3 State Layers',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 10.0),

                            _buildStateLayerCard(
                              context,
                              stateNumber: '1',
                              stateName: loc.tr('stateEnabled'),
                              description: 'Resting state: Inactive transparent, Active secondaryContainer (56dp, 28dp pill)',
                              isSelected: true,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 8.0),
                            _buildStateLayerCard(
                              context,
                              stateNumber: '2',
                              stateName: loc.tr('stateHovered'),
                              description: 'Pointer hover: 8% overlay state layer on container',
                              isSelected: false,
                              isHoverSimulated: true,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 8.0),
                            _buildStateLayerCard(
                              context,
                              stateNumber: '3',
                              stateName: loc.tr('stateFocused'),
                              description: 'Accessibility focus: 10% focus overlay + subtle border ring',
                              isSelected: false,
                              isFocusSimulated: true,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 8.0),
                            _buildStateLayerCard(
                              context,
                              stateNumber: '4',
                              stateName: loc.tr('statePressed'),
                              description: 'Click/Touch down: 10% pressed overlay + M3 ink ripple splash',
                              isSelected: false,
                              isPressedSimulated: true,
                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateLayerCard(
    BuildContext context, {
    required String stateNumber,
    required String stateName,
    required String description,
    required bool isSelected,
    bool isHoverSimulated = false,
    bool isFocusSimulated = false,
    bool isPressedSimulated = false,
    required ColorScheme colorScheme,
  }) {
    Color containerColor = Colors.transparent;
    Color contentColor = colorScheme.onSurfaceVariant;

    if (isSelected) {
      containerColor = colorScheme.secondaryContainer;
      contentColor = colorScheme.onSecondaryContainer;
    } else if (isHoverSimulated) {
      containerColor = colorScheme.onSurface.withAlpha((255 * 0.08).round());
      contentColor = colorScheme.onSurface;
    } else if (isFocusSimulated) {
      containerColor = colorScheme.onSurface.withAlpha((255 * 0.10).round());
      contentColor = colorScheme.onSurface;
    } else if (isPressedSimulated) {
      containerColor = colorScheme.onSurface.withAlpha((255 * 0.12).round());
      contentColor = colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12.0,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: Text(
              stateNumber,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stateName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          // Sample pill preview of this state
          Container(
            height: 42.0,
            width: 120.0,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(21.0),
              border: isFocusSimulated
                  ? Border.all(color: colorScheme.primary.withAlpha(160), width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 18.0, color: contentColor),
                const SizedBox(width: 6.0),
                Flexible(
                  child: Text(
                    stateName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: contentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
