/// Compile-time gate for demo-only UI such as the quick demo-account sign-in buttons.
///
/// Production builds leave this false. Local demos pass `--dart-define=DEMO_DATA=true`,
/// optionally with `--dart-define=DEMO_PASSWORD=...` so the buttons can sign in directly.
/// Passwords never live in source; without DEMO_PASSWORD the buttons only prefill the email.
class DemoData {
  static const bool enabled = bool.fromEnvironment('DEMO_DATA', defaultValue: false);
  static const String password = String.fromEnvironment('DEMO_PASSWORD');
}
