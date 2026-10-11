import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../semantic_search/models/semantic_search_result_model.dart';
import '../../virtual_staging/widgets/ai_virtual_staging_dialog.dart';
import '../../voice_broker/widgets/gemini_voice_broker_dialog.dart';
import '../../../core/design_system/cards/tashil_cards.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../owner_portal/widgets/property_share_dialog.dart';
import '../models/property_item.dart';
import 'property_details_dialog.dart';
import '../../../core/design_system/carousel/tashil_carousels.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';

class PropertyCard extends StatefulWidget {
  final PropertyItem property;
  final SemanticSearchResultItem? semanticResult;

  const PropertyCard({
    super.key,
    required this.property,
    this.semanticResult,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isFavorite = false;
  String _selectedAction = 'details';

  void _openDetails(BuildContext context) {
    TashilTransitions.showContainerTransformDialog(
      context: context,
      builder: (context) => PropertyDetailsDialog(property: widget.property),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lang = LocaleController.languageCode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TashilCard.outlined(
      enableHoverAnimation: true,
      hoverElevation: 1.0,
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openDetails(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.hasBoundedHeight;

          final contentWidgets = <Widget>[
            // Price Row with Payment Icon and Rating Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payments_outlined, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${CurrencyFormatter.formatAmount(widget.property.pricePerMonth, langCode: lang)} ',
                            style: TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: '${widget.property.currencyCode == 'AED' ? loc.tr('currency_ae') : loc.tr('currency_eg')} / ${loc.tr('perMonth')}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.property.rating}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Official Google M3 Card Text Hierarchy with Linked Text:
            TashilCardText(
              headlineText: widget.property.getTitle(lang),
              subheadText: widget.property.getLocation(lang),
              subheadLeading: Icon(Icons.location_on_outlined, size: 14, color: colorScheme.secondary),
              supportingText: widget.property.getDescription(lang).replaceAll('\n', ' ').trim(),
              linkedText: loc.tr('cardReadMoreLink'),
              onLinkedTextTap: () => _openDetails(context),
              headlineMaxLines: 1,
              supportingTextMaxLines: 1,
              spacing: 3.5,
            ),
            const SizedBox(height: 6),
            // M3 Rule 2: Use inset dividers to separate related content inside a card
            TashilDivider.middleInset(
              inset: 4.0,
              color: colorScheme.outlineVariant,
              height: 1,
            ),
            const SizedBox(height: 6),

            // Specs Icons (Bedrooms, Bathrooms, Area, Furnished)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFeatureIcon(Icons.bed_outlined, '${widget.property.bedrooms} ${loc.tr('bedrooms')}'),
                _buildFeatureIcon(Icons.bathtub_outlined, '${widget.property.bathrooms} ${loc.tr('bathrooms')}'),
                _buildFeatureIcon(Icons.square_foot_outlined, '${widget.property.areaSqM.toInt()} ${loc.tr('sqm')}'),
                _buildFeatureIcon(
                  widget.property.isFurnished ? Icons.weekend_outlined : Icons.chair_outlined,
                  widget.property.isFurnished ? loc.tr('furnished') : loc.tr('unfurnished'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Agency / Broker row with dedicated M3 business icon
            Row(
              children: [
                Icon(Icons.business_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.property.getAgencyName(lang),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (widget.semanticResult != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 13, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.semanticResult!.getMatchReason(lang),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ];

          // Official Google M3 Card Actions: Buttons + Icon Buttons
          final actionButtonsWidget = Row(
            children: [
              Expanded(
                child: TashilConnectedButtonGroup<String>(
                  height: 38.0,
                  isFullWidth: true,
                  selectedValue: _selectedAction,
                  showCheckmark: false,
                  onSelectionChanged: (action) {
                    setState(() => _selectedAction = action);
                    _openDetails(context);
                  },
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
                ),
              ),
              const SizedBox(width: 8),
              // Icon buttons per Google M3 card interactive controls: Phone & Message
              TashilIconButton.outlined(
                icon: Icons.phone_outlined,
                size: 38.0,
                iconSize: 18.0,
                tooltip: loc.tr('callAgency'),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${loc.tr('callingAgency')}: ${widget.property.agencyPhone}'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              TashilIconButton.outlined(
                icon: Icons.chat_bubble_outline_rounded,
                size: 38.0,
                iconSize: 18.0,
                tooltip: loc.tr('chatAgency'),
                onPressed: () => _openDetails(context),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Official Google M3 Card Top Header (Virtual Staging, Gemini Live, Favorite, More Options)
              _buildTopHeader(context, loc, colorScheme),

              // 2. Property Image with Category Tag & M3 Carousel
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  children: [
                    TashilCarousel.hero(
                      imageUrls: widget.property.imageUrls,
                      height: double.infinity,
                      borderRadius: BorderRadius.zero,
                      showIndicator: widget.property.imageUrls.length > 1,
                      showArrows: widget.property.imageUrls.length > 1,
                      onTap: () => _openDetails(context),
                    ),
                    // Property Category Tag ("شاليه" / "شقة" / "فيلا") at Top-Start
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apartment_rounded, size: 12, color: colorScheme.onPrimary),
                            const SizedBox(width: 4),
                            Text(
                              loc.tr('type_${widget.property.propertyTypeCode}'),
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.property.isFeatured)
                      PositionedDirectional(
                        top: 10,
                        end: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: colorScheme.onTertiaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                loc.tr('featured'),
                                style: TextStyle(
                                  color: colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.semanticResult != null)
                      PositionedDirectional(
                        bottom: 10,
                        start: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 12, color: colorScheme.onSecondaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                '${(widget.semanticResult!.similarityScore * 100).toInt()}% ${loc.tr('semanticMatchBadge')}',
                                style: TextStyle(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 3. Property Content Area with 16dp left/right padding per M3 Card Measurements
              if (isBounded)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 4.0),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: contentWidgets,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: contentWidgets,
                  ),
                ),

              // 4. Official Google M3 Rule 1: Use full-width dividers for card action footers
              // Runs 100% full width from edge to edge touching the card borders
              const TashilDivider.cardAction(),

              // 5. Pinned Action Buttons Footer - Guaranteed 100% Visible & Fully Padded
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 14.0, 12.0),
                child: actionButtonsWidget,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Official Google M3 Card Top Header
  ///
  /// Consolidates Virtual Staging and Gemini Live action pills on the start side,
  /// with Favorite and Settings/More Options quick controls on the end side.
  Widget _buildTopHeader(BuildContext context, AppLocalizations loc, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 8.0, 8.0),
      child: Row(
        children: [
          // 1. Interactive AI Feature Badges (Virtual Staging & Gemini Live)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderActionPill(
                    icon: Icons.chair_rounded,
                    label: loc.tr('virtualStaging'),
                    backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.55),
                    foregroundColor: colorScheme.onSecondaryContainer,
                    borderColor: colorScheme.secondary.withValues(alpha: 0.25),
                    onTap: () {
                      AiVirtualStagingDialog.show(context, property: widget.property);
                    },
                  ),
                  const SizedBox(width: 6),
                  _HeaderActionPill(
                    icon: Icons.mic_rounded,
                    label: 'Gemini Live',
                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
                    foregroundColor: colorScheme.onPrimaryContainer,
                    borderColor: colorScheme.primary.withValues(alpha: 0.25),
                    onTap: () {
                      GeminiVoiceBrokerDialog.show(context, widget.property);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 2. Trailing Quick Controls (Favorite & Settings/More Options)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: _isFavorite ? Colors.red : colorScheme.onSurfaceVariant,
                tooltip: loc.tr('favorite'),
                onTap: () => setState(() => _isFavorite = !_isFavorite),
              ),
              const SizedBox(width: 2),
              _HeaderIconButton(
                icon: Icons.more_vert_rounded,
                iconColor: colorScheme.onSurfaceVariant,
                tooltip: loc.tr('shareAndOptions'),
                onTap: () => PropertyShareDialog.showForMarketplace(context, widget.property),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Interactive M3 Header Action Pill for AI Features.
class _HeaderActionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _HeaderActionPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_HeaderActionPill> createState() => _HeaderActionPillState();
}

class _HeaderActionPillState extends State<_HeaderActionPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -1.0 : 0.0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.backgroundColor.withValues(alpha: 0.9)
              : widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? widget.foregroundColor : widget.borderColor,
            width: 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.foregroundColor.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 13, color: widget.foregroundColor),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.foregroundColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive M3 Circular Header Icon Button.
class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: Icon(
                widget.icon,
                size: 17,
                color: widget.iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
