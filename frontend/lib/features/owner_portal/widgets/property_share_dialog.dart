import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/owner_portal/widgets/marketplace_visitor_preview_dialog.dart';
import 'package:tashil_real_estate/features/public_marketplace/models/property_item.dart';
import 'package:tashil_real_estate/features/public_marketplace/repositories/property_repository.dart';

/// Official Material Design 3 Universal Property Share & Link Generation Dialog.
///
/// Enables owners and visitors to generate and copy a unique direct link to their property,
/// and share it directly across WhatsApp, Facebook, and Messenger.
class PropertyShareDialog extends StatefulWidget {
  final String id;
  final String imageUrl;
  final double pricePerMonth;
  final String Function(String lang) titleGetter;
  final String Function(String lang) locationGetter;
  final String? countryCode;

  const PropertyShareDialog({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.pricePerMonth,
    required this.titleGetter,
    required this.locationGetter,
    this.countryCode,
  });

  /// Factory helper for ManagedPropertyModel (Owner Portal)
  static Future<void> show(BuildContext context, ManagedPropertyModel property) {
    return TashilTransitions.showM3Dialog(
      context: context,
      builder: (_) => PropertyShareDialog(
        id: property.id,
        imageUrl: property.image,
        pricePerMonth: property.pricePerMonth,
        titleGetter: (lang) => property.getTitle(lang),
        locationGetter: (lang) => property.getLocation(lang),
        countryCode: property.countryCode,
      ),
    );
  }

  /// Factory helper for PropertyItem (Public Marketplace)
  static Future<void> showForMarketplace(BuildContext context, PropertyItem property) {
    return TashilTransitions.showM3Dialog(
      context: context,
      builder: (_) => PropertyShareDialog(
        id: property.id,
        imageUrl: property.imageUrls.isNotEmpty ? property.imageUrls.first : '',
        pricePerMonth: property.pricePerMonth,
        titleGetter: (lang) => property.getTitle(lang),
        locationGetter: (lang) => property.getLocation(lang),
        countryCode: property.countryCode,
      ),
    );
  }

  @override
  State<PropertyShareDialog> createState() => _PropertyShareDialogState();
}

class _PropertyShareDialogState extends State<PropertyShareDialog> {
  bool _isCopied = false;
  String _selectedFooterAction = 'preview';

  String get _propertyUrl {
    // Generates the official direct marketplace deep-link
    return 'https://tashil.estate/property/${widget.id}';
  }

  Future<void> _copyToClipboard(AppLocalizations loc) async {
    final successMessage = loc.tr('linkCopiedSuccess');
    await Clipboard.setData(ClipboardData(text: _propertyUrl));
    if (!mounted) return;

    setState(() {
      _isCopied = true;
    });

    TashilSnackBar.showSuccess(
      context: context,
      message: successMessage,
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  Future<void> _launchShareUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareOnWhatsApp(AppLocalizations loc, String lang) {
    final title = widget.titleGetter(lang);
    final location = widget.locationGetter(lang);
    final isUAE = (widget.countryCode == 'AE') || CountryController.isUAE;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');
    final formattedPrice = CurrencyFormatter.formatAmount(widget.pricePerMonth, langCode: lang);

    final message = '${loc.tr('shareTextPrompt')}:\n$title ($location)\n$formattedPrice $currency / ${loc.tr('perMonth')}\n$_propertyUrl';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    _launchShareUrl(url);
  }

  void _shareOnFacebook() {
    final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_propertyUrl)}';
    _launchShareUrl(url);
  }

  void _shareOnMessenger() {
    final url = 'https://www.messenger.com/t/?link=${Uri.encodeComponent(_propertyUrl)}';
    _launchShareUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = LocaleController.languageCode;
    final isUAE = (widget.countryCode == 'AE') || CountryController.isUAE;
    final currency = isUAE ? loc.tr('currency_ae') : loc.tr('currency_eg');

    final title = widget.titleGetter(lang);
    final location = widget.locationGetter(lang);

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.share_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('sharePropertyTitle'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loc.tr('sharePropertySubtitle'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _M3AnimatedCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Property Quick Preview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.imageUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 58,
                          height: 58,
                          color: colorScheme.surfaceContainerHigh,
                          child: Icon(Icons.apartment_rounded, color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            location,
                            style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${CurrencyFormatter.formatAmount(widget.pricePerMonth, langCode: lang)} $currency / ${loc.tr('perMonth')}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Direct Link Generation Container
              Text(
                loc.tr('directUnitLink'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsetsDirectional.only(start: 12, top: 6, bottom: 6, end: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _propertyUrl,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TashilButton(
                      onPressed: () => _copyToClipboard(loc),
                      icon: _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                      label: _isCopied ? loc.tr('confirm') : loc.tr('copyLink'),
                      height: 36,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Social Sharing Channels
              Text(
                loc.tr('shareOptions'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // WhatsApp
                  Expanded(
                    child: _M3SocialChannelTile(
                      label: loc.tr('shareWhatsApp'),
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => _shareOnWhatsApp(loc, lang),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Facebook
                  Expanded(
                    child: _M3SocialChannelTile(
                      label: loc.tr('shareFacebook'),
                      icon: Icons.public_rounded,
                      onTap: _shareOnFacebook,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Messenger
                  Expanded(
                    child: _M3SocialChannelTile(
                      label: loc.tr('shareMessenger'),
                      icon: Icons.forum_outlined,
                      onTap: _shareOnMessenger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bottom Actions: M3 Connected Button Group
              TashilConnectedButtonGroup<String>(
                height: 44.0,
                isFullWidth: true,
                selectedValue: _selectedFooterAction,
                showCheckmark: false,
                onSelectionChanged: (action) {
                  setState(() => _selectedFooterAction = action);
                  if (action == 'preview') {
                    Navigator.of(context).pop();
                    final repoProp = PropertyRepository().getPropertyById(widget.id);
                    if (repoProp != null) {
                      MarketplaceVisitorPreviewDialog.show(context, repoProp);
                    }
                  } else if (action == 'cancel') {
                    Navigator.of(context).pop();
                  }
                },
                segments: [
                  TashilConnectedButtonSegment<String>(
                    value: 'preview',
                    label: loc.tr('preview'),
                    icon: Icons.visibility_outlined,
                  ),
                  TashilConnectedButtonSegment<String>(
                    value: 'cancel',
                    label: loc.tr('cancel'),
                    icon: Icons.close_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated M3 Outlined Close Button with hover rotation and scale.
class _M3AnimatedCloseButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _M3AnimatedCloseButton({required this.onPressed});

  @override
  State<_M3AnimatedCloseButton> createState() => _M3AnimatedCloseButtonState();
}

class _M3AnimatedCloseButtonState extends State<_M3AnimatedCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedRotation(
          turns: _isHovered ? 0.25 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: TashilIconButton.outlined(
            icon: Icons.close_rounded,
            size: 36,
            iconSize: 18,
            onPressed: widget.onPressed,
          ),
        ),
      ),
    );
  }
}

/// Official M3 Social Sharing Channel Tile.
///
/// Fully theme-derived: all colors, borders, shadows, and hover state layers
/// adapt to the active ThemePalette without relying on external brand colors.
class _M3SocialChannelTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _M3SocialChannelTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_M3SocialChannelTile> createState() => _M3SocialChannelTileState();
}

class _M3SocialChannelTileState extends State<_M3SocialChannelTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = colorScheme.primary;
    final bgColor = _isHovered
        ? primary.withValues(alpha: isDark ? 0.14 : 0.08)
        : colorScheme.surfaceContainerLow;
    final borderColor = _isHovered
        ? primary.withValues(alpha: isDark ? 0.55 : 0.45)
        : colorScheme.outlineVariant.withValues(alpha: 0.8);
    final fgColor = _isHovered ? primary : colorScheme.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.20 : 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: primary.withValues(alpha: 0.12),
            highlightColor: primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Icon(widget.icon, color: primary, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
