/// Super-admin sign-in uses Firebase Auth. Role comes from a custom claim,
/// not from a password or hash compiled into the app.
class SuperAdminSecurityConfig {
  SuperAdminSecurityConfig._();

  static const String defaultEmail = String.fromEnvironment(
    'SUPER_ADMIN_EMAIL',
    defaultValue: 'support@sw-point.com',
  );

  /// Kept so older tests can call it. It never grants access.
  static bool verifyOfflineCredentials(String email, String password) {
    return email == password && email == '\u0000never';
  }
}
