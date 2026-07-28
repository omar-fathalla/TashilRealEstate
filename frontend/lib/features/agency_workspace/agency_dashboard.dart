import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'views/overview_view.dart';
import 'views/properties_view.dart';
import 'views/crm_view.dart';

class AgencyDashboard extends StatefulWidget {
  const AgencyDashboard({super.key});

  @override
  State<AgencyDashboard> createState() => _AgencyDashboardState();
}

class _AgencyDashboardState extends State<AgencyDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const OverviewView(),
    const PropertiesView(),
    const CrmView(),
    const Center(child: Text('Leases Management (Coming Soon)', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(context),
      desktopBody: _buildDesktopLayout(context),
      tabletBody: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
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
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'CRM',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Leases',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: ResponsiveLayout.isDesktop(context), // Collapse on tablet
            minExtendedWidth: 260,
            backgroundColor: colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 36, color: colorScheme.primary),
                  if (ResponsiveLayout.isDesktop(context)) ...[
                    const SizedBox(height: 12),
                    Text(
                      'TashilRealEstate',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary),
                    ),
                    Text(
                      'Agency Workspace',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ResponsiveLayout.isDesktop(context) 
                ? TextButton.icon(
                    onPressed: () async {
                      await FirebaseAuthService().signOut();
                      if (context.mounted) context.go('/');
                    },
                    icon: Icon(Icons.logout, color: colorScheme.error),
                    label: Text('Logout', style: TextStyle(color: colorScheme.error)),
                  )
                : IconButton(
                    icon: Icon(Icons.logout, color: colorScheme.error),
                    onPressed: () async {
                      await FirebaseAuthService().signOut();
                      if (context.mounted) context.go('/');
                    },
                  ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment),
                label: Text('Properties'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('CRM'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: Text('Leases'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: Container(
              color: colorScheme.surface.withValues(alpha: 0.98),
              child: _views[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
