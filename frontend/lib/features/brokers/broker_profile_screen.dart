import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/layout/m3_layout.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/brokers/broker_repository.dart';
import 'package:tashil_real_estate/features/brokers/models/broker_profile.dart';
import 'package:tashil_real_estate/features/public_marketplace/repositories/property_repository.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_symbols_icons/symbols.dart';

class BrokerProfileScreen extends StatelessWidget {
  final String brokerId;

  const BrokerProfileScreen({super.key, required this.brokerId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final broker = BrokerRepository().byId(brokerId);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Symbols.arrow_forward_rounded
                : Symbols.arrow_back_rounded,
          ),
          tooltip: loc.tr('back'),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(loc.tr('brokerProfileTitle')),
      ),
      body: broker == null
          ? Center(child: Text(loc.tr('brokerNotFound')))
          : _BrokerBody(broker: broker),
    );
  }
}

class _BrokerBody extends StatelessWidget {
  final BrokerProfile broker;

  const _BrokerBody({required this.broker});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lang = LocaleController.languageCode;
    final width = MediaQuery.sizeOf(context).width;
    final size = M3Layout.windowSizeClassFromWidth(width);
    final padding = size == M3WindowSizeClass.compact ? 16.0 : 24.0;
    final listings = PropertyRepository()
        .getPropertiesByCountry('AE')
        .followedBy(PropertyRepository().getPropertiesByCountry('EG'))
        .where((item) => item.brokerId == broker.id)
        .toList();
    final columns = width >= 1200 ? 3 : width >= 840 ? 2 : 1;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: EdgeInsetsDirectional.all(padding),
          children: [
            if (width >= 840)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Photo(url: broker.photoUrl, name: broker.name(lang)),
                  const SizedBox(width: 24),
                  Expanded(child: _Identity(broker: broker, loc: loc, lang: lang)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _Photo(url: broker.photoUrl, name: broker.name(lang), compact: true),
                  ),
                  const SizedBox(height: 16),
                  _Identity(broker: broker, loc: loc, lang: lang),
                ],
              ),
            const SizedBox(height: 24),
            Text(loc.tr('brokerActiveListings'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (listings.isEmpty)
              Text(loc.tr('noResultsTitle'), style: Theme.of(context).textTheme.bodyMedium)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listings.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: columns == 1 ? 0.72 : 0.68,
                ),
                itemBuilder: (context, index) => PropertyCard(property: listings[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String url;
  final String name;
  final bool compact;

  const _Photo({required this.url, required this.name, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final side = compact ? 96.0 : 160.0;
    final child = url.isEmpty
        ? Icon(Symbols.person_rounded, size: compact ? 48 : 72, color: scheme.onPrimaryContainer)
        : Image.network(url, fit: BoxFit.cover, width: side, height: side);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: side,
        height: side,
        color: scheme.primaryContainer,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final BrokerProfile broker;
  final AppLocalizations loc;
  final String lang;

  const _Identity({required this.broker, required this.loc, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TashilCard.filled(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(broker.name(lang), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(broker.agencyName(lang), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text('${loc.tr('brokerRegistrationNumberLabel')}: ${broker.brokerRegistrationNumber}'),
            const SizedBox(height: 4),
            Text('${loc.tr('officeRegistrationNumberLabel')}: ${broker.officeRegistrationNumber}'),
            const SizedBox(height: 12),
            Text(loc.tr('brokerLanguagesLabel'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final language in broker.languages)
                  TashilAssistChip.outlined(
                    label: language,
                    height: 48,
                    foregroundColor: scheme.onSurfaceVariant,
                    backgroundColor: scheme.surfaceContainerLow,
                    borderColor: scheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TashilButton(
                    icon: Symbols.call_rounded,
                    label: loc.tr('brokerCall'),
                    onPressed: () => launchUrl(Uri.parse('tel:${broker.phone}')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TashilButton.tonal(
                    icon: Symbols.chat_rounded,
                    label: loc.tr('brokerWhatsApp'),
                    onPressed: () {
                      final digits = broker.whatsApp.replaceAll(RegExp(r'[^0-9]'), '');
                      launchUrl(Uri.parse('https://wa.me/$digits'));
                    },
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
