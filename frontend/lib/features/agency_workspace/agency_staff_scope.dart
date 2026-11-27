import 'package:flutter/widgets.dart';

/// Tells the agency workspace views whether the signed-in user is an AgencyAgent (TAQ-169).
/// Agents see the agency's work but not the AgencyAdmin-only controls: financials, the team,
/// adding listings, deciding applications, creating leases, recording payments, legal notices
/// and permanent deletes. The server refuses those calls anyway; this only hides them.
class AgencyStaffScope extends InheritedWidget {
  final bool isAgent;

  const AgencyStaffScope({super.key, required this.isAgent, required super.child});

  /// False outside the agency workspace, so owner and admin screens are unchanged.
  static bool isAgentOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AgencyStaffScope>()?.isAgent ?? false;

  @override
  bool updateShouldNotify(AgencyStaffScope oldWidget) => oldWidget.isAgent != isAgent;
}
