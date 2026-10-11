import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/smart_valuation/smart_valuation_dialog.dart';

class SmartValuationScreen extends StatelessWidget {
  const SmartValuationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/valuation'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: const SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SmartValuationDialog(),
            ),
          ),
        ),
      ),
    );
  }
}
