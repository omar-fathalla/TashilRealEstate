import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/market_index/views/market_index_view.dart';

class MarketIndexScreen extends StatelessWidget {
  const MarketIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/market-index'),
      body: const SafeArea(
        child: MarketIndexView(),
      ),
    );
  }
}
