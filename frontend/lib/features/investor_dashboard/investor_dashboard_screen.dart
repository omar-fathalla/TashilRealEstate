import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/investor_dashboard/views/investor_dashboard_view.dart';

class InvestorDashboardScreen extends StatelessWidget {
  const InvestorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/investor-dashboard'),
          body: const SafeArea(
            child: InvestorDashboardView(),
          ),
        );
      },
    );
  }
}
