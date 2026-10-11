import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/lease_builder/views/leases_management_view.dart';

class LeaseBuilderScreen extends StatelessWidget {
  const LeaseBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/lease-builder'),
          body: const SafeArea(
            child: LeasesManagementView(),
          ),
        );
      },
    );
  }
}
