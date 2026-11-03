/// Compile-time gate for sample listings and sample brokers.
///
/// Production builds leave this false. Local demos and screenshots pass
/// `--dart-define=DEMO_DATA=true`.
class DemoData {
  static const bool enabled = bool.fromEnvironment('DEMO_DATA', defaultValue: false);
}
