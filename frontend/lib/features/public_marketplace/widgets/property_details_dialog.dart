import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/cards/tashil_cards.dart';
import '../../../core/design_system/carousel/tashil_carousels.dart';
import '../../../core/design_system/chips/tashil_chips.dart';
import '../../../core/design_system/dividers/tashil_dividers.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/design_system/snackbars/tashil_snackbars.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/market_display.dart';
import '../../virtual_staging/widgets/ai_virtual_staging_dialog.dart';
import '../../voice_broker/widgets/gemini_voice_broker_dialog.dart';
import '../models/property_item.dart';
import 'advertising_permit_badge.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialog_frame.dart';

class PropertyDetailsDialog extends StatefulWidget {
  final PropertyItem property;
  final bool asPage;

  const PropertyDetailsDialog({super.key, required this.property, this.asPage = false});

  static Future<void> show(BuildContext context, PropertyItem property) {
    if (MediaQuery.sizeOf(context).width < 600) {
      GoRouter.of(context).push('/listing/${property.id}');
      return Future.value();
    }
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PropertyDetailsDialog(property: property),
    );
  }

  @override
  State<PropertyDetailsDialog> createState() => _PropertyDetailsDialogState();
}

class _PropertyDetailsDialogState extends State<PropertyDetailsDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String _selectedAction = 'booking';

  void _handleActionSelected(String action) {
    setState(() => _selectedAction = action);
    if (action == 'booking') {
      _showBookingBottomSheet(context);
    } else if (action == 'staging') {
      AiVirtualStagingDialog.show(context, property: widget.property);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showBookingBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final lang = LocaleController.languageCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.tr('bookingTitle'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.property.getTitle(lang),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: loc.tr('fullName'),
                          prefixIcon: const Icon(Symbols.person_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: loc.tr('phoneWhatsapp'),
                          prefixIcon: const Icon(Symbols.phone_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TashilButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_nameController.text.trim().isEmpty ||
                                    _phoneController.text.trim().isEmpty) {
                                  TashilSnackBar.showWarning(
                                    context: context,
                                    message: loc.tr('fillAllFields'),
                                  );
                                  return;
                                }

                                final nav = Navigator.of(ctx);

                                setModalState(() => _isSubmitting = true);
                                await Future.delayed(const Duration(milliseconds: 900));
                                if (context.mounted) {
                                  setModalState(() => _isSubmitting = false);
                                  nav.pop();
                                  TashilSnackBar.showSuccess(
                                    context: context,
                                    message: loc.tr('bookingSuccess'),
                                  );
                                }
                              },
                        label: loc.tr('confirmBooking'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, currentLocale, _) {
        final loc = AppLocalizations.of(context);
        final lang = currentLocale.languageCode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final size = MediaQuery.of(context).size;
        final isMobile = size.width < 720;
        final isCompactHeight = size.height < 760;

        // Responsive carousel height to guarantee content visibility without clipping
        final double carouselHeight = isMobile
            ? 200.0
            : (isCompactHeight ? 240.0 : 280.0);

        return TashilDialogFrame(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 20.0 : 28.0),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: widget.asPage
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                  horizontal: isMobile ? 12.0 : 32.0,
                  vertical: isMobile ? 12.0 : 24.0,
                ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.asPage ? size.width : 960,
              maxHeight: widget.asPage
                  ? size.height
                  : size.height > 480
                      ? (size.height * 0.92).clamp(400.0, 840.0)
                      : size.height - 16.0,
            ),
            child: Scaffold(
              backgroundColor: theme.colorScheme.surface,
              bottomNavigationBar: Container(
                color: theme.colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TashilDivider.cardAction(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16.0 : 24.0,
                        vertical: isMobile ? 12.0 : 16.0,
                      ),
                      child: SafeArea(
                        top: false,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 640;
                            final formattedPrice = CurrencyFormatter.formatAmount(
                              MarketDisplay.rentAmount(
                                pricePerMonth: widget.property.pricePerMonth,
                                currencyCode: widget.property.currencyCode,
                              ),
                              langCode: lang,
                            );
                            final currencyStr = widget.property.currencyCode == 'AED'
                                ? loc.tr('currency_ae')
                                : loc.tr('currency_eg');

                            final priceColumn = Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr(MarketDisplay.rentLabelKey(widget.property.currencyCode)),
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2.0),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      formattedPrice,
                                      style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800,
                                        color: colorScheme.primary),
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      currencyStr,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            );

                            final isFurnished = widget.property.isFurnished;

                            final segments = [
                              TashilConnectedButtonSegment(
                                value: 'booking',
                                label: loc.tr('requestViewing'),
                                icon: Symbols.calendar_month_rounded,
                              ),
                              if (!isFurnished)
                                TashilConnectedButtonSegment(
                                  value: 'staging',
                                  label: loc.tr('virtualStagingBtn'),
                                  icon: Symbols.chair_rounded,
                                ),
                            ];

                            final Widget actionWidget;
                            if (segments.length > 1) {
                              actionWidget = TashilConnectedButtonGroup<String>(
                                height: 44.0,
                                selectedValue: _selectedAction,
                                onSelectionChanged: _handleActionSelected,
                                showCheckmark: true,
                                isFullWidth: isCompact,
                                segments: segments,
                              );
                            } else {
                              actionWidget = TashilButton(
                                height: 44.0,
                                icon: Symbols.calendar_month_rounded,
                                label: loc.tr('requestViewing'),
                                onPressed: () => _handleActionSelected('booking'),
                              );
                            }

                            if (isCompact) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  priceColumn,
                                  const SizedBox(height: 12.0),
                                  actionWidget,
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                priceColumn,
                                const SizedBox(width: 24.0),
                                Flexible(
                                  child: actionWidget,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  _buildModalHeader(context, loc, theme, colorScheme, lang, isMobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: isMobile ? 24.0 : 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image gallery with Material Design 3 Hero Carousel
                          Stack(
                            children: [
                              TashilCarousel.hero(
                                imageUrls: widget.property.imageUrls,
                                height: carouselHeight,
                                borderRadius: BorderRadius.zero,
                                showIndicator: widget.property.imageUrls.length > 1,
                                showArrows: widget.property.imageUrls.length > 1,
                              ),
                              PositionedDirectional(
                                top: 16.0,
                                start: 16.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Symbols.star_rounded, color: theme.colorScheme.tertiary, size: 16.0),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        '${widget.property.rating}',
                                        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Content Details
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.property.getTitle(lang),
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Icon(Symbols.location_on_rounded, size: 18.0, color: colorScheme.secondary),
                                              const SizedBox(width: 4.0),
                                              Expanded(
                                                child: Text(
                                                  widget.property.getLocation(lang),
                                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant,
                                                    fontWeight: FontWeight.w500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (widget.property.brokerId.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            TashilButton.tonal(
                                              height: 48,
                                              icon: Symbols.badge_rounded,
                                              label: loc.tr('viewBrokerProfile'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                context.go('/brokers/${widget.property.brokerId}');
                                              },
                                            ),
                                          ],
                                          if (widget.property.isSample)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                loc.tr('sampleListingBadge'),
                                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                      color: colorScheme.onTertiaryContainer,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          if (!widget.property.isSample &&
                                              widget.property.advertisingPermitNumber.trim().isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            AdvertisingPermitBadge(
                                              permitNumber: widget.property.advertisingPermitNumber,
                                              qrSize: 72,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20.0),

                                // Quick Specs Grid inside TashilCard.outlined
                                TashilCard.outlined(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8.0 : 16.0,
                                    vertical: isMobile ? 12.0 : 16.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildSpecItem(
                                          theme,
                                          Symbols.bed_rounded,
                                          '${widget.property.bedrooms} ${loc.tr('bedrooms')}',
                                          isMobile,
                                        ),
                                      ),
                                      const TashilVerticalDivider.inset(inset: 4.0),
                                      Expanded(
                                        child: _buildSpecItem(
                                          theme,
                                          Symbols.bathtub_rounded,
                                          '${widget.property.bathrooms} ${loc.tr('bathrooms')}',
                                          isMobile,
                                        ),
                                      ),
                                      const TashilVerticalDivider.inset(inset: 4.0),
                                      Expanded(
                                        child: _buildSpecItem(
                                          theme,
                                          Symbols.square_foot_rounded,
                                          '${MarketDisplay.areaAmount(areaSqM: widget.property.areaSqM, countryCode: widget.property.countryCode).round()} ${loc.tr(MarketDisplay.areaUnitKey(widget.property.countryCode))}',
                                          isMobile,
                                        ),
                                      ),
                                      const TashilVerticalDivider.inset(inset: 4.0),
                                      Expanded(
                                        child: _buildSpecItem(
                                          theme,
                                          Symbols.chair_rounded,
                                          widget.property.isFurnished ? loc.tr('furnished') : loc.tr('unfurnished'),
                                          isMobile,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24.0),
                                Text(
                                  loc.tr('aboutProperty'),
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  widget.property.getDescription(lang),
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.6,
                                    color: theme.colorScheme.onSurfaceVariant),
                                ),

                                if (widget.property.getAmenities(lang).isNotEmpty) ...[
                                  const SizedBox(height: 24.0),
                                  Text(
                                    loc.tr('amenities'),
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 12.0),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: widget.property.getAmenities(lang).map((amenity) {
                                      return TashilAssistChip.outlined(
                                        icon: _getAmenityIcon(amenity),
                                        label: amenity,
                                      );
                                    }).toList(),
                                  ),
                                ],

                                const SizedBox(height: 24.0),
                                Text(
                                  loc.tr('agencyBroker'),
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface),
                                ),
                                const SizedBox(height: 12.0),
                                TashilCard.outlined(
                                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                  color: theme.colorScheme.surfaceContainerLowest,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: isMobile ? 44.0 : 48.0,
                                        height: isMobile ? 44.0 : 48.0,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Symbols.apartment_rounded,
                                          color: colorScheme.onPrimaryContainer,
                                          size: isMobile ? 22.0 : 26.0,
                                        ),
                                      ),
                                      const SizedBox(width: 14.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.property.getAgencyName(lang),
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4.0),
                                            Row(
                                              children: [
                                                Icon(
                                                  Symbols.verified_rounded,
                                                  size: 15.0,
                                                  color: colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4.0),
                                                Text(
                                                  loc.tr('verifiedAgency'),
                                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant,
                                                    fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      TashilStandardButtonGroup(
                                        spacing: 6.0,
                                        children: [
                                          TashilIconButton.outlined(
                                            size: isMobile ? 36.0 : 40.0,
                                            iconSize: isMobile ? 18.0 : 20.0,
                                            icon: Symbols.phone_rounded,
                                            tooltip: loc.tr('callAgency'),
                                            onPressed: () {
                                              TashilSnackBar.showInfo(
                                                context: context,
                                                message: '${loc.tr('callingAgency')}: ${widget.property.getAgencyName(lang)}',
                                              );
                                            },
                                          ),
                                          TashilIconButton.outlined(
                                            size: isMobile ? 36.0 : 40.0,
                                            iconSize: isMobile ? 18.0 : 20.0,
                                            icon: Symbols.chat_bubble_outline_rounded,
                                            tooltip: loc.tr('chatAgency'),
                                            onPressed: () {
                                              TashilSnackBar.showInfo(
                                                context: context,
                                                message: '${loc.tr('chatAgency')}: ${widget.property.getAgencyName(lang)}',
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecItem(ThemeData theme, IconData icon, String label, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isMobile ? 18.0 : 22.0, color: theme.colorScheme.primary),
        const SizedBox(height: 6.0),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  IconData _getPropertyTypeIcon(String typeCode) {
    switch (typeCode.toLowerCase()) {
      case 'apartment':
        return Symbols.apartment_rounded;
      case 'villa':
        return Symbols.villa_rounded;
      case 'studio':
        return Symbols.meeting_room_rounded;
      case 'duplex':
        return Symbols.home_work_rounded;
      case 'chalet':
        return Symbols.beach_access_rounded;
      default:
        return Symbols.home_rounded;
    }
  }

  Widget _buildModalHeader(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ColorScheme colorScheme,
    String lang,
    bool isMobile,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsetsDirectional.only(
            start: isMobile ? 16.0 : 24.0,
            end: isMobile ? 16.0 : 24.0,
            top: 12.0,
            bottom: 12.0,
          ),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(
                  _getPropertyTypeIcon(widget.property.propertyTypeCode),
                  color: colorScheme.onSecondaryContainer,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.tr('type_${widget.property.propertyTypeCode}'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      widget.property.getLocation(lang),
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              TashilStandardButtonGroup(
                spacing: 8.0,
                children: [
                  TashilIconButton.tonal(
                    size: 48.0,
                    iconSize: 20.0,
                    icon: Symbols.mic_none_rounded,
                    tooltip: loc.tr('talkToVoiceBroker'),
                    onPressed: () => GeminiVoiceBrokerDialog.show(context, widget.property),
                  ),
                  TashilIconButton.tonal(
                    size: 48.0,
                    iconSize: 20.0,
                    icon: Symbols.share_rounded,
                    tooltip: loc.tr('share'),
                    onPressed: () {
                      TashilSnackBar.showSuccess(
                        context: context,
                        message: loc.tr('shareCopied'),
                      );
                    },
                  ),
                  TashilIconButton.close(
                    size: 48.0,
                    iconSize: 20.0,
                    tooltip: loc.tr('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const TashilDivider.fullWidth(),
      ],
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();

    // Furnished
    if (lower.contains(AppLocalizations.trStatic('uiCopy300')) || lower.contains('furnished') || lower.contains('सुसज्जित')) {
      return Symbols.chair_rounded;
    }
    // A/C
    if (lower.contains(AppLocalizations.trStatic('uiCopy173')) || lower.contains('a/c') || lower.contains('ac') || lower.contains('एसी')) {
      return Symbols.ac_unit_rounded;
    }
    // Parking
    if (lower.contains(AppLocalizations.trStatic('uiCopy314')) || lower.contains('parking') || lower.contains('جراج') || lower.contains('पार्किंग')) {
      return Symbols.local_parking_rounded;
    }
    // Security
    if (lower.contains(AppLocalizations.trStatic('uiCopy087')) || lower.contains(AppLocalizations.trStatic('uiCopy194')) || lower.contains('security') || lower.contains('सुरक्षा')) {
      return Symbols.security_rounded;
    }
    // CCTV
    if (lower.contains(AppLocalizations.trStatic('uiCopy263')) || lower.contains('cctv') || lower.contains('सीसीटीवी')) {
      return Symbols.videocam_rounded;
    }
    // Elevator
    if (lower.contains(AppLocalizations.trStatic('uiCopy293')) || lower.contains('elevator') || lower.contains('lift') || lower.contains('लिफ्ट')) {
      return Symbols.elevator_rounded;
    }
    // Pool
    if (lower.contains(AppLocalizations.trStatic('uiCopy215')) || lower.contains('pool') || lower.contains('पूल')) {
      return Symbols.pool_rounded;
    }
    // Garden / Yard
    if (lower.contains(AppLocalizations.trStatic('uiCopy193')) || lower.contains('garden') || lower.contains('बगीचा')) {
      return Symbols.yard_rounded;
    }
    // Balcony
    if (lower.contains(AppLocalizations.trStatic('uiCopy220')) || lower.contains('balcony') || lower.contains('बालकनी')) {
      return Symbols.balcony_rounded;
    }
    // Gym / Fitness
    if (lower.contains(AppLocalizations.trStatic('uiCopy190')) || lower.contains('نادي') || lower.contains('gym') || lower.contains('fitness') || lower.contains('फिटनेस')) {
      return Symbols.fitness_center_rounded;
    }
    // Sea / River / Water View
    if (lower.contains(AppLocalizations.trStatic('uiCopy157')) || lower.contains('نيل') || lower.contains('sea') || lower.contains('water') || lower.contains('समुद्र')) {
      return Symbols.water_rounded;
    }
    // Internet / Wifi
    if (lower.contains(AppLocalizations.trStatic('uiCopy101')) || lower.contains('واي فاي') || lower.contains('wifi') || lower.contains('internet') || lower.contains('इंटरनेट')) {
      return Symbols.wifi_rounded;
    }
    // Kitchen
    if (lower.contains(AppLocalizations.trStatic('uiCopy295')) || lower.contains('kitchen') || lower.contains('रसोई')) {
      return Symbols.kitchen_rounded;
    }
    // Maid's room
    if (lower.contains(AppLocalizations.trStatic('uiCopy199')) || lower.contains('maid') || lower.contains('कमरा')) {
      return Symbols.meeting_room_rounded;
    }
    // Pets
    if (lower.contains(AppLocalizations.trStatic('uiCopy198')) || lower.contains('pet') || lower.contains('पालतू')) {
      return Symbols.pets_rounded;
    }
    // Default contextual icon
    return Symbols.verified_rounded;
  }
}

