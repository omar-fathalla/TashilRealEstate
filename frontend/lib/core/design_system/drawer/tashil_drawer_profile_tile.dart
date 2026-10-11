import 'package:flutter/material.dart';
import '../../utils/user_avatar_utils.dart';

/// Official Material Design 3 (M3) Drawer Profile Tile.
///
/// Implements Google Material Design 3 surface card for authenticated user identity:
/// - Container: `surfaceContainerHigh` with 1px `outlineVariant` border.
/// - Shape: Squircle / rounded 16dp.
/// - Avatar: 36dp circular avatar with `primaryContainer` / `onPrimaryContainer`.
/// - Content: User display name (`labelLarge` bold) and role subtitle (`bodySmall`).
/// - Trailing: M3 `unfold_more_rounded` popup menu trigger.
/// - Collapsed Rail Mode: Compact avatar-only pill with tooltip and centered alignment.
class TashilDrawerProfileTile extends StatefulWidget {
  final String initials;
  final String displayName;
  final String roleSubtitle;
  final VoidCallback onTap;
  final bool isCollapsed;
  final String? tooltip;
  final String? photoUrl;

  const TashilDrawerProfileTile({
    super.key,
    required this.initials,
    required this.displayName,
    required this.roleSubtitle,
    required this.onTap,
    this.isCollapsed = false,
    this.tooltip,
    this.photoUrl,
  });

  @override
  State<TashilDrawerProfileTile> createState() => _TashilDrawerProfileTileState();
}

class _TashilDrawerProfileTileState extends State<TashilDrawerProfileTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(16.0);

    final avatar = UserAvatarUtils.buildAvatar(
      context: context,
      photoUrl: widget.photoUrl,
      displayName: widget.displayName,
      fallbackInitials: widget.initials,
      radius: widget.isCollapsed ? 18.0 : 19.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showExpanded = !widget.isCollapsed && constraints.maxWidth >= 140.0;

        if (!showExpanded) {
          return Tooltip(
            message: widget.tooltip ?? widget.displayName,
            preferBelow: false,
            verticalOffset: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: avatar,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: borderRadius,
              onHover: (hovered) => setState(() => _isHovered = hovered),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: _isHovered
                        ? colorScheme.primary.withAlpha(100)
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.displayName,
                            style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1.0),
                          Text(
                            widget.roleSubtitle,
                            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                              fontSize: 11.0,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 18.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
