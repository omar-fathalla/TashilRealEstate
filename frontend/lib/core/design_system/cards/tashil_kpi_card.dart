import 'package:flutter/material.dart';
import 'tashil_card.dart';

/// Official Material Design 3 (M3) KPI Summary Metric Card for Tashil Real Estate.
///
/// Strictly mirrors the gold-standard 4-card metric layout from the Portfolio Overview:
/// - Top Row: [title] (Start / Right in RTL) + [icon] container (End / Left in RTL - 36x36dp, 10dp radius, surfaceContainerHigh)
/// - Middle: [value] (Start / Right in RTL - 22sp bold, -0.3 letterSpacing)
/// - Bottom Row: [subtitleIcon] (13dp) + [subtitle] (11.5sp medium, onSurfaceVariant)
class TashilKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final IconData subtitleIcon;
  final Color? iconColor;
  final Color? iconBgColor;
  final VoidCallback? onTap;

  const TashilKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.subtitleIcon,
    this.iconColor,
    this.iconBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final effectiveIconBgColor = iconBgColor ?? colorScheme.surfaceContainerHigh;

    return TashilCard.outlined(
      onTap: onTap,
      enableHoverAnimation: true,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: effectiveIconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(subtitleIcon, size: 13, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard M3 responsive grid container for 4 Tashil KPI metric cards:
/// - Desktop (>= 1150px): 1 row of 4 equal-width cards
/// - Tablet (650px - 1149px): 2x2 grid (2 cards per row)
/// - Mobile (< 650px): 1 column (vertical stack of 4 cards)
class TashilKpiGrid extends StatelessWidget {
  final List<Widget> cards;
  final double spacing;

  const TashilKpiGrid({
    super.key,
    required this.cards,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth;
        if (constraints.maxWidth < 650) {
          cardWidth = constraints.maxWidth;
        } else if (constraints.maxWidth < 1150) {
          cardWidth = (constraints.maxWidth - spacing) / 2;
        } else {
          cardWidth = (constraints.maxWidth - (spacing * 3)) / 4;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(
                    width: cardWidth,
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }
}
