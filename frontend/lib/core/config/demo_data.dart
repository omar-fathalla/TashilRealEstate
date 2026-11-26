/// Compile-time gate for demo-only UI such as the quick demo-account sign-in buttons.
///
/// Production builds leave this false. Local demos pass `--dart-define=DEMO_DATA=true`,
/// optionally with `--dart-define=DEMO_PASSWORD=...` so the buttons can sign in directly.
/// Passwords never live in source; without DEMO_PASSWORD the buttons only prefill the email. The
/// accounts are the per-role test set on `@test.tashilaqar.com` (docs/DEV_ENVIRONMENT.md), each with
/// its own password, so a single DEMO_PASSWORD only fits a project where they share one.
class DemoData {
  static const String accountDomain = 'test.tashilaqar.com';

  /// The accounts the demo buttons use: the email local part and the role it signs in as.
  static const List<DemoAccount> accounts = [
    DemoAccount('owner', 'Owner'),
    DemoAccount('agency', 'AgencyAdmin'),
    DemoAccount('tenant', 'Tenant'),
    DemoAccount('superadmin', 'SuperAdmin'),
  ];

  static const bool enabled = bool.fromEnvironment('DEMO_DATA', defaultValue: false);
  static const String password = String.fromEnvironment('DEMO_PASSWORD');
}

class DemoAccount {
  final String localPart;
  final String role;
  const DemoAccount(this.localPart, this.role);

  String get email => '$localPart@${DemoData.accountDomain}';
}
