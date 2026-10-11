import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/views/financial_kpi_dashboard_view.dart';

class FinancialKpiScreen extends StatefulWidget {
  final FinancialPortalRole? initialRole;

  const FinancialKpiScreen({super.key, this.initialRole});

  @override
  State<FinancialKpiScreen> createState() => _FinancialKpiScreenState();
}

class _FinancialKpiScreenState extends State<FinancialKpiScreen> {
  late FinancialPortalRole _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole ?? FinancialPortalRole.owner;
    _resolveUserRole();
  }

  Future<void> _resolveUserRole() async {
    if (widget.initialRole != null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final roleStr = await FirestoreService().getUserRole(user.uid);
      if (mounted && roleStr != null) {
        setState(() {
          if (roleStr == 'SuperAdmin') {
            _currentRole = FinancialPortalRole.superAdmin;
          } else if (roleStr == 'AgencyAdmin') {
            _currentRole = FinancialPortalRole.agency;
          } else {
            _currentRole = FinancialPortalRole.owner;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, countryCode, _) {
            return Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/financial-dashboard'),
              body: FinancialKpiDashboardView(role: _currentRole),
            );
          },
        );
      },
    );
  }
}
