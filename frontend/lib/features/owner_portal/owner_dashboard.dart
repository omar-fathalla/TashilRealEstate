import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'views/owner_overview_view.dart';
import 'views/owner_financials_view.dart';
import 'views/owner_maintenance_view.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const OwnerOverviewView(),
    const OwnerFinancialsView(),
    const OwnerMaintenanceView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(context),
      desktopBody: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Portal', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.error),
            onPressed: () async {
              await FirebaseAuthService().signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Financials',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Maintenance',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text('Owner Portal', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: colorScheme.error),
              onPressed: () async {
                await FirebaseAuthService().signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ],
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Financials'),
              Tab(icon: Icon(Icons.build), text: 'Maintenance'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OwnerOverviewView(),
            OwnerFinancialsView(),
            OwnerMaintenanceView(),
          ],
        ),
      ),
    );
  }
}
