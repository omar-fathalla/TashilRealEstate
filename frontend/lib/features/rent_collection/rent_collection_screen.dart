import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/rent_collection/views/rent_collection_view.dart';

class RentCollectionScreen extends StatelessWidget {
  const RentCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/rent-collection'),
          body: const SafeArea(
            child: RentCollectionView(showBackButton: true),
          ),
        );
      },
    );
  }
}
