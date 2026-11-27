/// Compile-time switches for screens that are not backed by real data yet.
///
/// Production builds leave every flag false. A local build can turn one on with
/// `--dart-define=NAME=true` to work on the screen.
class FeatureFlags {
  /// The agency workspace's CRM board and Investor dashboard are mockups with fixed sample
  /// data (TAQ-152), so they stay hidden until they read real records.
  static const bool agencyMockTabs = bool.fromEnvironment('AGENCY_MOCK_TABS', defaultValue: false);
}
